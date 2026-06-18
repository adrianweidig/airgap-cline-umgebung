#!/usr/bin/env python3
"""Prueft OWNER.json vor Schreibzugriffen auf Nutzer- oder Agentenordner."""

from __future__ import annotations

import argparse
import json
import os
import platform
from pathlib import Path


def current_username() -> str:
    return os.environ.get("USERNAME") or os.environ.get("USER") or "unknown"


def current_domain() -> str:
    return os.environ.get("USERDOMAIN") or platform.node() or "unknown"


def main() -> int:
    parser = argparse.ArgumentParser(description="OWNER.json pruefen")
    parser.add_argument("--owner", required=True, help="Pfad zu OWNER.json")
    parser.add_argument("--explain", action="store_true", help="JSON-Ergebnis ausgeben")
    args = parser.parse_args()

    owner_path = Path(args.owner)
    if not owner_path.exists():
        print(f"OWNER.json fehlt: {owner_path}")
        return 3

    owner = json.loads(owner_path.read_text(encoding="utf-8"))
    expected_user = owner.get("username")
    expected_domain = owner.get("domain") or owner.get("host")
    user_ok = expected_user == current_username()
    domain_ok = not expected_domain or expected_domain in {current_domain(), platform.node()}
    ok = bool(user_ok and domain_ok)
    result = {
        "ok": ok,
        "ownerPath": str(owner_path),
        "expectedUser": expected_user,
        "actualUser": current_username(),
        "expectedDomainOrHost": expected_domain,
        "actualDomainOrHost": current_domain(),
    }
    if args.explain or not ok:
        print(json.dumps(result, indent=2))
    return 0 if ok else 2


if __name__ == "__main__":
    raise SystemExit(main())