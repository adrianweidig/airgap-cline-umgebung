#!/bin/sh
set -eu
ROOT_PATH=""
AGENT_ID="default-agent"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) ROOT_PATH="$2"; shift 2 ;;
    --agent-id) AGENT_ID="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -z "$ROOT_PATH" ]; then ROOT_PATH=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd); fi
USER_NAME="${USER:-unknown}"
HOST_NAME=$(hostname 2>/dev/null || uname -n)
OWNER_NAME=$(printf '%s_%s' "$HOST_NAME" "$USER_NAME" | sed 's/[^A-Za-z0-9_.-]/_/g')
SAFE_AGENT=$(printf '%s' "$AGENT_ID" | sed 's/[^A-Za-z0-9_.-]/_/g')
FAMILY=$(basename "$ROOT_PATH" | awk -F_ '{print tolower($3)}')
case "$FAMILY" in mac) FAMILY="mac" ;; linux) FAMILY="linux" ;; solaris) FAMILY="solaris" ;; *) FAMILY="posix" ;; esac
USER_ROOT="$ROOT_PATH/users/$FAMILY/$OWNER_NAME"
AGENT_ROOT="$USER_ROOT/agents/$SAFE_AGENT"
mkdir -p "$USER_ROOT/agents" "$USER_ROOT/scratch" "$USER_ROOT/notes" "$USER_ROOT/logs" "$USER_ROOT/outbox" "$USER_ROOT/memory" "$AGENT_ROOT/memory" "$AGENT_ROOT/outbox/memory-proposals"
cat > "$USER_ROOT/OWNER.json" <<EOF
{"schemaVersion":1,"platform":"$FAMILY","user":"$USER_NAME","host":"$HOST_NAME"}
EOF
cat > "$USER_ROOT/ALWAYS_READ.md" <<EOF
# Always Read

This folder belongs to $HOST_NAME/$USER_NAME. If you are not this user, do not write here.

Allowed write areas: the owner's agent folder, scratch, notes, logs, outbox, and memory.
EOF
[ -f "$USER_ROOT/memory/USER_MEMORY.md" ] || printf '# User Memory

- No durable user preferences recorded yet.
' > "$USER_ROOT/memory/USER_MEMORY.md"
printf '# Agent Policy

Work only for the owner of this user folder. Check OWNER.json before writes. Use central helpers from AIRGAP_CLINE_HOME.
' > "$AGENT_ROOT/AGENT_POLICY.md"
printf '# Current Task

No task recorded yet.
' > "$AGENT_ROOT/CURRENT_TASK.md"
printf '[]
' > "$AGENT_ROOT/WORKSPACE_BINDINGS.json"
printf '# Session Memory

## Current Task
- No task recorded yet.

## Summary
- No summary recorded yet.

## Durable Proposals
- Write durable findings as proposals under outbox/memory-proposals/.
' > "$AGENT_ROOT/memory/SESSION.md"
echo "$AGENT_ROOT"
