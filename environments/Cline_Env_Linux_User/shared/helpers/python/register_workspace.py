#!/usr/bin/env python3
"""Registriert externe Arbeitsordner zentral unter workspaces/<hash>."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import platform
from datetime import datetime, timezone
from pathlib import Path

SCHEMA_VERSION = 1


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def current_user() -> str:
    return os.environ.get("USERNAME") or os.environ.get("USER") or "unknown"


def normalized_path(path: Path) -> str:
    text = str(path.resolve(strict=False))
    return os.path.normcase(text) if os.name == "nt" else text


def write_text(path: Path, text: str) -> None:
    path.write_text(text, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Externen Arbeitsordner zentral registrieren")
    parser.add_argument("--root", required=True, help="AIRGAP_CLINE_HOME")
    parser.add_argument("--target", required=True, help="Externer Arbeitsordner")
    parser.add_argument("--alias", default="", help="Optionaler Anzeigename")
    parser.add_argument("--dry-run", action="store_true", help="Nur geplante Aenderungen ausgeben")
    args = parser.parse_args()

    root = Path(args.root).resolve(strict=False)
    target = Path(args.target).resolve(strict=False)
    if not root.exists():
        raise SystemExit(f"AIRGAP_CLINE_HOME existiert nicht: {root}")
    if not target.exists() or not target.is_dir():
        raise SystemExit(f"Zielordner existiert nicht oder ist kein Ordner: {target}")

    normalized = normalized_path(target)
    digest = hashlib.sha256(normalized.encode("utf-8")).hexdigest()[:24]
    workspace = root / "workspaces" / digest
    manifest_path = workspace / "WORKSPACE.json"
    created_at = now()

    if manifest_path.exists():
        existing = json.loads(manifest_path.read_text(encoding="utf-8"))
        existing_normalized = existing.get("normalizedPath")
        if existing_normalized and existing_normalized != normalized:
            raise SystemExit(f"Workspace-Hash-Kollision: {manifest_path}")
        created_at = existing.get("createdAt") or created_at

    data = {
        "schemaVersion": SCHEMA_VERSION,
        "hash": digest,
        "originalPath": str(Path(args.target)),
        "targetPath": str(target),
        "normalizedPath": normalized,
        "alias": args.alias,
        "createdAt": created_at,
        "updatedAt": now(),
        "createdBy": current_user(),
        "host": platform.node() or "unknown",
        "platform": platform.system() or "unknown",
        "helperOutput": "helper-output",
    }

    if args.dry_run:
        print(json.dumps({"dryRun": True, "workspacePath": str(workspace), "manifest": data}, indent=2))
        return 0

    (workspace / "helper-output").mkdir(parents=True, exist_ok=True)
    write_text(manifest_path, json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    notes = workspace / "NOTIZEN.md"
    if not notes.exists():
        write_text(notes, "# Notizen\n\n")
    overrides = workspace / "RULE_OVERRIDES.md"
    if not overrides.exists():
        write_text(overrides, "# Optionale arbeitsordnerspezifische Hinweise\n\n")
    print(str(workspace))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())