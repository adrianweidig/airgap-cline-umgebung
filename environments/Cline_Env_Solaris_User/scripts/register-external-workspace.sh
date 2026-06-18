#!/bin/sh
set -eu
DRY_RUN=""
ALIAS_VALUE=""
TARGET_PATH=""
ROOT_PATH=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN="--dry-run" ;;
    --alias) shift; ALIAS_VALUE=$1 ;;
    --root) shift; ROOT_PATH=$1 ;;
    *) TARGET_PATH=$1 ;;
  esac
  shift
done
if [ -z "$TARGET_PATH" ]; then
  echo "Nutzung: register-external-workspace.sh <zielpfad> [--alias name] [--root root] [--dry-run]" >&2
  exit 1
fi
if [ -z "$ROOT_PATH" ]; then
  SCRIPT_DIR=$(dirname "$0")
  ROOT_PATH=$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)
fi
if command -v python3 >/dev/null 2>&1; then
  python3 "$ROOT_PATH/shared/helpers/python/register_workspace.py" --root "$ROOT_PATH" --target "$TARGET_PATH" --alias "$ALIAS_VALUE" $DRY_RUN
else
  echo "python3 wurde nicht gefunden." >&2
  exit 1
fi