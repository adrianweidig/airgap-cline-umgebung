#!/bin/sh
set -eu
ROOT_PATH=${1:-}
if [ -z "$ROOT_PATH" ]; then
  SCRIPT_DIR=$(dirname "$0")
  ROOT_PATH=$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)
fi
for item in START_HIER.md AGENTS.md ENVIRONMENT.md MANIFEST.json shared/rules shared/workflows shared/skills shared/helpers/python/register_workspace.py shared/helpers/python/guard_owner.py; do
  if [ ! -e "$ROOT_PATH/$item" ]; then
    echo "Fehlender Bestandteil: $item" >&2
    exit 1
  fi
done
find "$ROOT_PATH" \( -name '*.exe' -o -name '*.msi' -o -name '*.vsix' -o -name '*.7z' -o -name '*.zip' -o -name '*.gguf' -o -name '*.safetensors' -o -name '*.onnx' \) -print | while IFS= read -r bad; do
  echo "Verbotene Datei in Umgebung: $bad" >&2
  exit 1
done
echo "Umgebung valide: $ROOT_PATH"