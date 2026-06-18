#!/bin/sh
set -eu
ROOT_PATH=""
ACTION=""
WORKSPACE=""
TYPE="fact"
TEXT=""
PROPOSAL=""
AGENT_ID=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) shift; ROOT_PATH=$1 ;;
    --action) shift; ACTION=$1 ;;
    --workspace) shift; WORKSPACE=$1 ;;
    --type) shift; TYPE=$1 ;;
    --text) shift; TEXT=$1 ;;
    --proposal) shift; PROPOSAL=$1 ;;
    --agent-id) shift; AGENT_ID=$1 ;;
    *) if [ -z "$ACTION" ]; then ACTION=$1; elif [ -z "$WORKSPACE" ]; then WORKSPACE=$1; else TEXT=$1; fi ;;
  esac
  shift
done
if [ -z "$ROOT_PATH" ]; then
  SCRIPT_DIR=$(dirname "$0")
  ROOT_PATH=$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)
fi
if [ -z "$ACTION" ] || [ -z "$WORKSPACE" ]; then
  echo "Nutzung: update-airgap-memory.sh --action <init|read|propose|apply|render|validate> --workspace <hash|pfad>" >&2
  exit 1
fi
if command -v python3 >/dev/null 2>&1; then
  PY=python3
else
  echo "python3 wurde nicht gefunden." >&2
  exit 1
fi
set -- "$ROOT_PATH/shared/helpers/python/memory_update.py" --root "$ROOT_PATH" "$ACTION" --workspace "$WORKSPACE"
if [ "$ACTION" = "propose" ]; then
  set -- "$@" --type "$TYPE" --text "$TEXT"
fi
if [ "$ACTION" = "apply" ]; then
  set -- "$@" --proposal "$PROPOSAL"
fi
if [ -n "$AGENT_ID" ]; then
  set -- "$@" --agent-id "$AGENT_ID"
fi
exec "$PY" "$@"