#!/bin/sh
set -eu
ROOT_PATH="${1:-}"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -z "$ROOT_PATH" ]; then ROOT_PATH=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd); fi
for rel in START_HERE.md AGENTS.md ENVIRONMENT.md MANIFEST.json bootstrap/FIRST_READ.md; do
  [ -f "$ROOT_PATH/$rel" ] || { echo "Missing required file: $rel" >&2; exit 1; }
done
echo "Environment valid: $ROOT_PATH"
