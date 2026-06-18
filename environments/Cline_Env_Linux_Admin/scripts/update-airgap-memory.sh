#!/bin/sh
set -eu
ROOT_PATH=""
ACTION=""
WORKSPACE=""
TYPE="fact"
TEXT=""
PROPOSAL=""
AGENT_ID="agent"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) ROOT_PATH="$2"; shift 2 ;;
    --action) ACTION="$2"; shift 2 ;;
    --workspace) WORKSPACE="$2"; shift 2 ;;
    --type) TYPE="$2"; shift 2 ;;
    --text) TEXT="$2"; shift 2 ;;
    --proposal) PROPOSAL="$2"; shift 2 ;;
    --agent-id) AGENT_ID="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -z "$ROOT_PATH" ]; then ROOT_PATH=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd); fi
PYTHON=$(command -v python3 || command -v python || true)
if [ -z "$PYTHON" ]; then echo "Python was not found." >&2; exit 1; fi
set -- "$ROOT_PATH/shared/helpers/python/memory_update.py" --root "$ROOT_PATH" "$ACTION" --workspace "$WORKSPACE" --agent-id "$AGENT_ID"
if [ "$ACTION" = "propose" ]; then set -- "$@" --type "$TYPE" --text "$TEXT"; fi
if [ "$ACTION" = "apply" ]; then set -- "$@" --proposal "$PROPOSAL"; fi
exec "$PYTHON" "$@"
