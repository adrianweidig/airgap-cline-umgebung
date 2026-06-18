#!/bin/sh
set -eu
OWNER_PATH=""
WRITE=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --owner) OWNER_PATH="$2"; shift 2 ;;
    --write) WRITE=1; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_PATH=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
PYTHON=$(command -v python3 || command -v python || true)
if [ -z "$PYTHON" ]; then echo "Python was not found." >&2; exit 1; fi
if [ "$WRITE" -eq 1 ]; then exec "$PYTHON" "$ROOT_PATH/shared/helpers/python/guard_owner.py" --owner "$OWNER_PATH" --write; fi
exec "$PYTHON" "$ROOT_PATH/shared/helpers/python/guard_owner.py" --owner "$OWNER_PATH"
