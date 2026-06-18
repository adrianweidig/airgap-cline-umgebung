#!/usr/bin/env python3
"""Manage coordinated workspace memory for Air-Gap Cline environments."""
from __future__ import annotations
import argparse, hashlib, json, time
from datetime import datetime, timezone
from pathlib import Path

TARGET = {"fact": "facts", "decision": "decisions", "active": "active", "next": "next", "do_not": "doNot", "question": "openQuestions", "read_first": "readFirst"}
PREFIX = {"fact": "F", "decision": "D", "active": "A", "next": "N", "do_not": "X", "question": "Q", "read_first": "R"}
SECTIONS = ["readFirst", "facts", "decisions", "active", "next", "doNot", "openQuestions"]

def now() -> str:
    return datetime.now(timezone.utc).isoformat()

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else ""

def memory_dir(root: Path, workspace_hash: str) -> Path:
    workspace = root / "workspaces" / workspace_hash
    if not workspace.is_dir():
        raise SystemExit(f"Workspace does not exist: {workspace}")
    path = workspace / "memory"
    (path / "inbox").mkdir(parents=True, exist_ok=True)
    (path / "locks").mkdir(exist_ok=True)
    return path

def default_state(workspace_hash: str, agent_id: str) -> dict:
    stamp = now()
    return {
        "schemaVersion": 1,
        "scope": "workspace",
        "workspaceHash": workspace_hash,
        "revision": 0,
        "updatedAt": stamp,
        "updatedBy": agent_id,
        "readFirst": [{"id": "R-0001", "text": "Do not store secrets, raw logs, chat transcripts, or chain-of-thought in memory.", "createdAt": stamp, "createdBy": agent_id}],
        "facts": [],
        "decisions": [],
        "active": [],
        "next": [],
        "doNot": [{"id": "X-0001", "text": "Do not create persistent Cline or memory files in target repositories unless the user explicitly requests it.", "createdAt": stamp, "createdBy": agent_id}],
        "openQuestions": [],
    }

def load_state(path: Path, workspace_hash: str, agent_id: str) -> dict:
    file_path = path / "MEMORY.json"
    if file_path.exists():
        return json.loads(file_path.read_text(encoding="utf-8"))
    return default_state(workspace_hash, agent_id)

def write_json(path: Path, data: dict) -> None:
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    tmp.replace(path)

def section(title: str, items: list[dict], empty: str) -> list[str]:
    lines = [f"## {title}"]
    if items:
        lines.extend(f"- {item['id']}: {item['text']}" for item in items)
    else:
        lines.append(f"- {empty}")
    lines.append("")
    return lines

def render(path: Path, state: dict) -> None:
    lines = [
        "# Memory",
        "",
        "schema: airgap-memory/v1",
        f"scope: {state['scope']}",
        f"workspace_hash: {state['workspaceHash']}",
        f"revision: {state['revision']}",
        f"updated_at: {state['updatedAt']}",
        f"updated_by: {state['updatedBy']}",
        "",
    ]
    lines += section("READ_FIRST", state.get("readFirst", []), "No additional read-first items.")
    lines += section("FACTS", state.get("facts", []), "No durable facts recorded.")
    lines += section("DECISIONS", state.get("decisions", []), "No durable decisions recorded.")
    lines += section("ACTIVE", state.get("active", []), "No active focus recorded.")
    lines += section("NEXT", state.get("next", []), "No next steps recorded.")
    lines += section("DO_NOT", state.get("doNot", []), "No additional prohibitions recorded.")
    lines += section("OPEN_QUESTIONS", state.get("openQuestions", []), "No open questions recorded.")
    (path / "MEMORY.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
    (path / "ACTIVE.md").write_text("\n".join(section("ACTIVE", state.get("active", []), "No active focus recorded.")), encoding="utf-8")
    (path / "DECISIONS.md").write_text("\n".join(section("DECISIONS", state.get("decisions", []), "No durable decisions recorded.")), encoding="utf-8")
    (path / "PROGRESS.md").write_text("\n".join(section("NEXT", state.get("next", []), "No next steps recorded.")), encoding="utf-8")
    write_json(path / "INDEX.json", {"schemaVersion": 1, "revision": state["revision"], "updatedAt": state["updatedAt"], "files": ["MEMORY.md", "MEMORY.json", "ACTIVE.md", "DECISIONS.md", "PROGRESS.md", "EVENTS.jsonl"]})

def append_event(path: Path, event: dict) -> None:
    with (path / "EVENTS.jsonl").open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(event, sort_keys=True) + "\n")

def next_id(state: dict, item_type: str) -> str:
    section_name = TARGET[item_type]
    prefix = PREFIX[item_type]
    used = []
    for item in state.get(section_name, []):
        value = str(item.get("id", ""))
        if value.startswith(prefix + "-"):
            try:
                used.append(int(value.split("-", 1)[1]))
            except ValueError:
                pass
    return f"{prefix}-{(max(used) if used else 0) + 1:04d}"

def action_init(args) -> None:
    path = memory_dir(args.root, args.workspace)
    state = load_state(path, args.workspace, args.agent_id)
    write_json(path / "MEMORY.json", state)
    render(path, state)
    append_event(path, {"type": "init", "at": now(), "agentId": args.agent_id, "revision": state["revision"]})
    print(path / "MEMORY.md")

def action_read(args) -> None:
    path = memory_dir(args.root, args.workspace)
    if not (path / "MEMORY.md").exists():
        action_init(args)
    print((path / "MEMORY.md").read_text(encoding="utf-8"))

def action_propose(args) -> None:
    path = memory_dir(args.root, args.workspace)
    state = load_state(path, args.workspace, args.agent_id)
    write_json(path / "MEMORY.json", state)
    render(path, state)
    proposal = {"schemaVersion": 1, "workspaceHash": args.workspace, "type": args.type, "text": args.text.strip(), "agentId": args.agent_id, "createdAt": now(), "parentRevision": state.get("revision", 0), "parentSha256": sha(path / "MEMORY.json")}
    target = path / "inbox" / f"{int(time.time())}-{args.agent_id}-{args.type}.memory.json"
    write_json(target, proposal)
    append_event(path, {"type": "propose", "at": now(), "agentId": args.agent_id, "proposal": str(target)})
    print(target)

def action_apply(args) -> None:
    path = memory_dir(args.root, args.workspace)
    state = load_state(path, args.workspace, args.agent_id)
    proposal = Path(args.proposal)
    data = json.loads(proposal.read_text(encoding="utf-8"))
    if data.get("parentSha256") and data["parentSha256"] != sha(path / "MEMORY.json"):
        print(f"Conflict: parentSha256 does not match. Proposal remains in inbox: {proposal}")
        return
    item_type = data["type"]
    target_section = TARGET[item_type]
    item = {"id": next_id(state, item_type), "text": data["text"], "createdAt": now(), "createdBy": data.get("agentId", args.agent_id)}
    state.setdefault(target_section, []).append(item)
    state["revision"] = int(state.get("revision", 0)) + 1
    state["updatedAt"] = now()
    state["updatedBy"] = args.agent_id
    write_json(path / "MEMORY.json", state)
    render(path, state)
    append_event(path, {"type": "apply", "at": now(), "agentId": args.agent_id, "itemId": item["id"], "revision": state["revision"]})
    print(item["id"])

def action_validate(args) -> None:
    path = memory_dir(args.root, args.workspace)
    state = load_state(path, args.workspace, args.agent_id)
    missing = [name for name in ["MEMORY.md", "MEMORY.json", "ACTIVE.md", "DECISIONS.md", "PROGRESS.md"] if not (path / name).exists()]
    if missing:
        raise SystemExit(f"Missing memory files: {', '.join(missing)}")
    for key in SECTIONS:
        if key not in state:
            raise SystemExit(f"Missing memory section: {key}")
    print("memory valid")

def main() -> int:
    parser = argparse.ArgumentParser(description="Manage coordinated Air-Gap workspace memory")
    parser.add_argument("--root", required=True, type=Path)
    sub = parser.add_subparsers(dest="action", required=True)
    for action in ["init", "read", "validate"]:
        child = sub.add_parser(action)
        child.add_argument("--workspace", required=True)
        child.add_argument("--agent-id", default="agent")
    child = sub.add_parser("propose")
    child.add_argument("--workspace", required=True)
    child.add_argument("--type", required=True, choices=sorted(TARGET))
    child.add_argument("--text", required=True)
    child.add_argument("--agent-id", default="agent")
    child = sub.add_parser("apply")
    child.add_argument("--workspace", required=True)
    child.add_argument("--proposal", required=True)
    child.add_argument("--agent-id", default="agent")
    args = parser.parse_args()
    args.root = args.root.expanduser().resolve()
    globals()[f"action_{args.action}"](args)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
