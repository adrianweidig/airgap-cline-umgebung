#!/usr/bin/env python3
"""Register external workspaces centrally under workspaces/<hash>."""
from __future__ import annotations
import argparse, hashlib, json, os, socket
from datetime import datetime, timezone
from pathlib import Path

def now() -> str:
    return datetime.now(timezone.utc).isoformat()

def write_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    tmp.replace(path)

def main() -> int:
    parser = argparse.ArgumentParser(description="Register an external workspace in the central Air-Gap environment")
    parser.add_argument("--root", required=True)
    parser.add_argument("--target", required=True)
    parser.add_argument("--alias", default="")
    args = parser.parse_args()
    root = Path(args.root).expanduser().resolve()
    target = Path(args.target).expanduser().resolve()
    if not root.is_dir():
        raise SystemExit(f"AIRGAP_CLINE_HOME does not exist: {root}")
    if not target.is_dir():
        raise SystemExit(f"Target workspace does not exist or is not a directory: {target}")
    normalized = str(target)
    digest = hashlib.sha256(normalized.encode("utf-8")).hexdigest()[:24]
    workspace_dir = root / "workspaces" / digest
    workspace_dir.mkdir(parents=True, exist_ok=True)
    workspace_file = workspace_dir / "WORKSPACE.json"
    if workspace_file.exists():
        current = json.loads(workspace_file.read_text(encoding="utf-8"))
        if current.get("normalizedPath") and current["normalizedPath"] != normalized:
            raise SystemExit(f"Workspace hash collision for {digest}")
        created_at = current.get("createdAt", now())
    else:
        created_at = now()
    write_json(workspace_file, {
        "schemaVersion": 2,
        "hash": digest,
        "originalPath": args.target,
        "normalizedPath": normalized,
        "alias": args.alias,
        "host": socket.gethostname(),
        "user": os.environ.get("USERNAME") or os.environ.get("USER") or "unknown",
        "createdAt": created_at,
        "updatedAt": now(),
    })
    defaults = {
        "NOTES.md": "# Notes\n\n- No notes recorded yet.\n",
        "RULE_OVERRIDES.md": "# Rule Overrides\n\n- No overrides recorded.\n",
    }
    for name, content in defaults.items():
        file_path = workspace_dir / name
        if not file_path.exists():
            file_path.write_text(content, encoding="utf-8")
    (workspace_dir / "helper-output").mkdir(exist_ok=True)
    (workspace_dir / "memory").mkdir(exist_ok=True)
    print(digest)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
