#!/usr/bin/env python3
"""Koordiniertes Workspace-Memory fuer Air-Gap-Cline-Umgebungen."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import sys
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path

SCHEMA_VERSION = 1
SECTION_MAP = {
    "read_first": ("readFirst", "R", "READ_FIRST"),
    "fact": ("facts", "F", "FACTS"),
    "decision": ("decisions", "D", "DECISIONS"),
    "active": ("active", "A", "ACTIVE"),
    "next": ("next", "N", "NEXT"),
    "do_not": ("doNot", "X", "DO_NOT"),
    "open_question": ("openQuestions", "Q", "OPEN_QUESTIONS"),
}


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def current_user() -> str:
    return os.environ.get("USERNAME") or os.environ.get("USER") or "unknown"


def atomic_write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + f".tmp-{os.getpid()}-{uuid.uuid4().hex[:8]}")
    tmp.write_text(text, encoding="utf-8")
    tmp.replace(path)


def sha256_file(path: Path) -> str:
    if not path.exists():
        return ""
    return hashlib.sha256(path.read_bytes()).hexdigest()


def workspace_dir(root: Path, ref: str) -> Path:
    candidate = Path(ref)
    if candidate.exists() and (candidate / "WORKSPACE.json").exists():
        return candidate.resolve(strict=False)
    return (root / "workspaces" / ref).resolve(strict=False)


def memory_dir(workspace: Path) -> Path:
    return workspace / "memory"


def load_workspace_hash(workspace: Path) -> str:
    manifest = workspace / "WORKSPACE.json"
    if manifest.exists():
        data = json.loads(manifest.read_text(encoding="utf-8-sig"))
        return str(data.get("hash") or workspace.name)
    return workspace.name


def default_memory(workspace_hash: str, user: str) -> dict:
    stamp = now()
    return {
        "schemaVersion": SCHEMA_VERSION,
        "scope": "workspace",
        "workspaceHash": workspace_hash,
        "revision": 0,
        "updatedAt": stamp,
        "updatedBy": user,
        "sections": {
            "readFirst": [{"id": "R-0001", "text": "Keine Secrets, Rohlogs, Chatverlaeufe oder Chain-of-Thought in Memory schreiben.", "createdAt": stamp, "createdBy": user}],
            "facts": [],
            "decisions": [],
            "active": [],
            "next": [],
            "doNot": [{"id": "X-0001", "text": "Keine dauerhaften Cline- oder Memory-Dateien in Zielrepos anlegen, ausser der Nutzer verlangt es ausdruecklich.", "createdAt": stamp, "createdBy": user}],
            "openQuestions": [],
        },
    }


def load_memory(mem_dir: Path) -> dict:
    path = mem_dir / "MEMORY.json"
    if not path.exists():
        raise SystemExit(f"MEMORY.json fehlt: {path}")
    return json.loads(path.read_text(encoding="utf-8-sig"))


def save_json(path: Path, data: dict) -> None:
    atomic_write(path, json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def render_memory_md(data: dict) -> str:
    lines = [
        "---",
        "schema: airgap-memory/v1",
        "scope: workspace",
        f"workspace_hash: {data['workspaceHash']}",
        f"revision: {data['revision']}",
        f"updated_at: {data['updatedAt']}",
        f"updated_by: {data['updatedBy']}",
        "---",
        "# MEMORY",
        "",
    ]
    sections = data["sections"]
    for _, (key, _, title) in SECTION_MAP.items():
        lines.append(f"## {title}")
        entries = sections.get(key, [])
        if entries:
            for entry in entries:
                text = str(entry["text"]).replace("\n", " ").strip()
                lines.append(f"- {entry['id']} {text}")
        else:
            lines.append("- none")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def render_detail_files(mem_dir: Path, data: dict) -> None:
    sections = data["sections"]
    active = "\n".join(f"- {e['id']} {e['text']}" for e in sections.get("active", [])) or "- none"
    decisions = "\n".join(f"- {e['id']} {e['text']}" for e in sections.get("decisions", [])) or "- none"
    next_items = "\n".join(f"- {e['id']} {e['text']}" for e in sections.get("next", [])) or "- none"
    questions = "\n".join(f"- {e['id']} {e['text']}" for e in sections.get("openQuestions", [])) or "- none"
    atomic_write(mem_dir / "ACTIVE.md", f"# Active\n\n{active}\n")
    atomic_write(mem_dir / "DECISIONS.md", f"# Decisions\n\n{decisions}\n")
    atomic_write(mem_dir / "PROGRESS.md", f"# Progress\n\n## Next\n{next_items}\n\n## Open Questions\n{questions}\n")
    index = {
        "schemaVersion": 1,
        "scope": "workspace-memory-index",
        "workspaceHash": data["workspaceHash"],
        "revision": data["revision"],
        "files": {
            "memory": "MEMORY.md",
            "canonical": "MEMORY.json",
            "active": "ACTIVE.md",
            "decisions": "DECISIONS.md",
            "progress": "PROGRESS.md",
            "events": "EVENTS.jsonl",
            "inbox": "inbox/",
            "locks": "locks/",
        },
    }
    save_json(mem_dir / "INDEX.json", index)


def render_all(mem_dir: Path, data: dict) -> None:
    save_json(mem_dir / "MEMORY.json", data)
    atomic_write(mem_dir / "MEMORY.md", render_memory_md(data))
    render_detail_files(mem_dir, data)


def append_event(mem_dir: Path, event_type: str, data: dict, details: dict | None = None) -> None:
    event = {
        "schemaVersion": 1,
        "eventId": uuid.uuid4().hex,
        "eventType": event_type,
        "workspaceHash": data["workspaceHash"],
        "revision": data["revision"],
        "createdAt": now(),
        "createdBy": current_user(),
        "details": details or {},
    }
    with (mem_dir / "EVENTS.jsonl").open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(event, ensure_ascii=False) + "\n")


def acquire_lock(mem_dir: Path, holder: str, ttl: int = 120) -> Path:
    locks = mem_dir / "locks"
    locks.mkdir(parents=True, exist_ok=True)
    lock = locks / "LOCK.json"
    current = int(time.time())
    if lock.exists():
        try:
            data = json.loads(lock.read_text(encoding="utf-8"))
            if int(data.get("expiresEpoch", 0)) > current:
                raise SystemExit(f"Memory ist gesperrt durch {data.get('holder')}: {lock}")
        except json.JSONDecodeError:
            pass
    payload = {"schemaVersion": 1, "holder": holder, "createdAt": now(), "expiresEpoch": current + ttl}
    atomic_write(lock, json.dumps(payload, indent=2) + "\n")
    return lock


def release_lock(lock: Path) -> None:
    try:
        lock.unlink()
    except FileNotFoundError:
        pass


def init_memory(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve(strict=False)
    workspace = workspace_dir(root, args.workspace)
    if not workspace.exists():
        raise SystemExit(f"Workspace existiert nicht: {workspace}")
    mem_dir = memory_dir(workspace)
    mem_dir.mkdir(parents=True, exist_ok=True)
    for sub in ("inbox", "locks", "applied"):
        (mem_dir / sub).mkdir(exist_ok=True)
    if (mem_dir / "MEMORY.json").exists() and not args.force:
        data = load_memory(mem_dir)
    else:
        data = default_memory(load_workspace_hash(workspace), args.agent_id or current_user())
    if not args.dry_run:
        render_all(mem_dir, data)
        events = mem_dir / "EVENTS.jsonl"
        if not events.exists():
            events.write_text("", encoding="utf-8")
        append_event(mem_dir, "init", data)
    print(str(mem_dir))
    return 0


def read_memory(args: argparse.Namespace) -> int:
    mem = memory_dir(workspace_dir(Path(args.root).resolve(strict=False), args.workspace)) / "MEMORY.md"
    if not mem.exists():
        raise SystemExit(f"MEMORY.md fehlt: {mem}")
    print(mem.read_text(encoding="utf-8"))
    return 0


def next_id(data: dict, section_key: str, prefix: str) -> str:
    max_id = 0
    for entry in data["sections"].get(section_key, []):
        match = re.match(r"^[A-Z]-(\d{4,})$", str(entry.get("id", "")))
        if match:
            max_id = max(max_id, int(match.group(1)))
    return f"{prefix}-{max_id + 1:04d}"


def proposal_text(path: Path, metadata: dict, text: str) -> str:
    return "---\n" + json.dumps(metadata, indent=2, ensure_ascii=False) + "\n---\n" + text.strip() + "\n"


def parse_proposal(path: Path) -> tuple[dict, str]:
    content = path.read_text(encoding="utf-8-sig")
    if not content.startswith("---\n"):
        raise SystemExit(f"Ungueltiger Memory-Vorschlag: {path}")
    _, rest = content.split("---\n", 1)
    meta_text, body = rest.split("\n---\n", 1)
    return json.loads(meta_text), body.strip()


def propose_memory(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve(strict=False)
    workspace = workspace_dir(root, args.workspace)
    mem_dir = memory_dir(workspace)
    if not (mem_dir / "MEMORY.json").exists():
        init_args = argparse.Namespace(root=str(root), workspace=args.workspace, agent_id=args.agent_id, force=False, dry_run=False)
        init_memory(init_args)
    current_sha = sha256_file(mem_dir / "MEMORY.json")
    proposal_id = f"{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}-{uuid.uuid4().hex[:8]}"
    metadata = {
        "schemaVersion": 1,
        "proposalId": proposal_id,
        "workspaceHash": load_workspace_hash(workspace),
        "type": args.type,
        "parentSha256": args.parent_sha256 or current_sha,
        "agentId": args.agent_id or current_user(),
        "createdAt": now(),
        "createdBy": current_user(),
    }
    target = mem_dir / "inbox" / f"{proposal_id}.memory.md"
    atomic_write(target, proposal_text(target, metadata, args.text))
    print(str(target))
    return 0


def apply_memory(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve(strict=False)
    workspace = workspace_dir(root, args.workspace)
    mem_dir = memory_dir(workspace)
    data = load_memory(mem_dir)
    proposal = Path(args.proposal).resolve(strict=False)
    metadata, body = parse_proposal(proposal)
    current_sha = sha256_file(mem_dir / "MEMORY.json")
    if metadata.get("parentSha256") and metadata["parentSha256"] != current_sha:
        print(f"Konflikt: parentSha256 passt nicht. Vorschlag bleibt in inbox: {proposal}")
        return 2
    section_key, prefix, _ = SECTION_MAP[metadata["type"]]
    lock = acquire_lock(mem_dir, args.agent_id or current_user())
    try:
        data = load_memory(mem_dir)
        entry = {
            "id": next_id(data, section_key, prefix),
            "text": body.replace("\n", " ").strip(),
            "createdAt": now(),
            "createdBy": metadata.get("agentId") or current_user(),
        }
        data["sections"][section_key].append(entry)
        data["revision"] = int(data.get("revision", 0)) + 1
        data["updatedAt"] = now()
        data["updatedBy"] = args.agent_id or current_user()
        render_all(mem_dir, data)
        append_event(mem_dir, "apply", data, {"proposalId": metadata.get("proposalId"), "entryId": entry["id"], "type": metadata["type"]})
        applied = mem_dir / "applied" / proposal.name
        applied.parent.mkdir(exist_ok=True)
        shutil.move(str(proposal), str(applied))
    finally:
        release_lock(lock)
    print(entry["id"])
    return 0


def render_memory(args: argparse.Namespace) -> int:
    mem_dir = memory_dir(workspace_dir(Path(args.root).resolve(strict=False), args.workspace))
    data = load_memory(mem_dir)
    render_all(mem_dir, data)
    print(str(mem_dir / "MEMORY.md"))
    return 0


def validate_memory(args: argparse.Namespace) -> int:
    mem_dir = memory_dir(workspace_dir(Path(args.root).resolve(strict=False), args.workspace))
    required = ["MEMORY.json", "MEMORY.md", "ACTIVE.md", "DECISIONS.md", "PROGRESS.md", "INDEX.json", "EVENTS.jsonl"]
    missing = [name for name in required if not (mem_dir / name).exists()]
    if missing:
        raise SystemExit("Fehlende Memory-Dateien: " + ", ".join(missing))
    data = load_memory(mem_dir)
    for key, _, _ in SECTION_MAP.values():
        if key not in data.get("sections", {}):
            raise SystemExit(f"Fehlender Memory-Abschnitt: {key}")
    print("Memory valide: " + str(mem_dir))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Koordiniertes Air-Gap-Cline-Memory")
    parser.add_argument("--root", required=True, help="AIRGAP_CLINE_HOME")
    sub = parser.add_subparsers(dest="command", required=True)
    p_init = sub.add_parser("init")
    p_init.add_argument("--workspace", required=True)
    p_init.add_argument("--agent-id", default="")
    p_init.add_argument("--force", action="store_true")
    p_init.add_argument("--dry-run", action="store_true")
    p_init.set_defaults(func=init_memory)
    p_read = sub.add_parser("read")
    p_read.add_argument("--workspace", required=True)
    p_read.set_defaults(func=read_memory)
    p_prop = sub.add_parser("propose")
    p_prop.add_argument("--workspace", required=True)
    p_prop.add_argument("--type", required=True, choices=sorted(SECTION_MAP.keys()))
    p_prop.add_argument("--text", required=True)
    p_prop.add_argument("--agent-id", default="")
    p_prop.add_argument("--parent-sha256", default="")
    p_prop.set_defaults(func=propose_memory)
    p_apply = sub.add_parser("apply")
    p_apply.add_argument("--workspace", required=True)
    p_apply.add_argument("--proposal", required=True)
    p_apply.add_argument("--agent-id", default="")
    p_apply.set_defaults(func=apply_memory)
    p_render = sub.add_parser("render")
    p_render.add_argument("--workspace", required=True)
    p_render.set_defaults(func=render_memory)
    p_validate = sub.add_parser("validate")
    p_validate.add_argument("--workspace", required=True)
    p_validate.set_defaults(func=validate_memory)
    args = parser.parse_args()
    return int(args.func(args))


if __name__ == "__main__":
    raise SystemExit(main())