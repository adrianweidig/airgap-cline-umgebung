#!/usr/bin/env python3
"""Check OWNER.json before writing to user or agent folders."""
from __future__ import annotations
import argparse, json, os, socket
from pathlib import Path

def current_identity() -> dict:
    return {
        "user": os.environ.get("USERNAME") or os.environ.get("USER") or "unknown",
        "domain": os.environ.get("USERDOMAIN", ""),
        "host": socket.gethostname(),
    }

def main() -> int:
    parser = argparse.ArgumentParser(description="Validate OWNER.json for the current user")
    parser.add_argument("--owner", required=True)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    path = Path(args.owner)
    if not path.is_file():
        raise SystemExit(f"OWNER.json not found: {path}")
    owner = json.loads(path.read_text(encoding="utf-8"))
    ident = current_identity()
    allowed = owner.get("user") == ident["user"]
    if owner.get("domain"):
        allowed = allowed and owner["domain"] == ident["domain"]
    if owner.get("host"):
        allowed = allowed and owner["host"] == ident["host"]
    print(json.dumps({"allowed": allowed, "owner": owner, "current": ident}, indent=2, sort_keys=True))
    if args.write and not allowed:
        raise SystemExit("Current identity may not write to this owner folder")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
