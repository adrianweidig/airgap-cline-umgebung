#!/bin/sh
set -eu
if [ "$#" -lt 1 ]; then
  echo "Nutzung: register-external-workspace.sh <zielpfad> [root]" >&2
  exit 1
fi
TARGET_PATH=$1
ROOT_PATH=${2:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}
if command -v python3 >/dev/null 2>&1; then
  python3 "$ROOT_PATH/shared/helpers/python/register_workspace.py" --root "$ROOT_PATH" --target "$TARGET_PATH"
else
  echo "python3 wurde nicht gefunden." >&2
  exit 1
fi