#!/usr/bin/env python3
"""Registriert externe Arbeitsordner zentral unter workspaces/<hash>."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from datetime import datetime, timezone
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description="Externen Arbeitsordner registrieren")
    parser.add_argument("--root", required=True, help="AIRGAP_CLINE_HOME")
    parser.add_argument("--target", required=True, help="Externer Arbeitsordner")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    target = Path(args.target).resolve()
    digest = hashlib.sha256(str(target).encode("utf-8")).hexdigest()[:24]
    workspace = root / "workspaces" / digest
    (workspace / "helper-output").mkdir(parents=True, exist_ok=True)

    data = {
        "targetPath": str(target),
        "hash": digest,
        "createdAt": datetime.now(timezone.utc).isoformat(),
        "createdBy": os.environ.get("USERNAME") or os.environ.get("USER") or "unknown",
    }
    (workspace / "WORKSPACE.json").write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    (workspace / "NOTIZEN.md").write_text("# Notizen\n\n", encoding="utf-8")
    (workspace / "RULE_OVERRIDES.md").write_text("# Optionale arbeitsordnerspezifische Hinweise\n\n", encoding="utf-8")
    print(str(workspace))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())