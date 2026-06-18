#!/bin/sh
set -eu
if [ "$#" -lt 1 ]; then
  echo "Nutzung: guard-owner.sh <OWNER.json> [root]" >&2
  exit 1
fi
OWNER_PATH=$1
ROOT_PATH=${2:-}
if [ -z "$ROOT_PATH" ]; then
  SCRIPT_DIR=$(dirname "$0")
  ROOT_PATH=$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)
fi
if command -v python3 >/dev/null 2>&1; then
  python3 "$ROOT_PATH/shared/helpers/python/guard_owner.py" --owner "$OWNER_PATH" --explain
else
  echo "python3 wurde nicht gefunden." >&2
  exit 1
fi