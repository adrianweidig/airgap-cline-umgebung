#!/bin/sh
set -eu
ROOT_PATH=""
TARGET_PATH=""
ALIAS=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) ROOT_PATH="$2"; shift 2 ;;
    --target) TARGET_PATH="$2"; shift 2 ;;
    --alias) ALIAS="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -z "$ROOT_PATH" ]; then ROOT_PATH=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd); fi
PYTHON=$(command -v python3 || command -v python || true)
if [ -z "$PYTHON" ]; then echo "Python was not found." >&2; exit 1; fi
exec "$PYTHON" "$ROOT_PATH/shared/helpers/python/register_workspace.py" --root "$ROOT_PATH" --target "$TARGET_PATH" --alias "$ALIAS"
