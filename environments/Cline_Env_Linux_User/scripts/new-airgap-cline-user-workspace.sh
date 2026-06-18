#!/bin/sh
set -eu
ROOT_PATH=${1:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}
HOST_NAME=$(hostname 2>/dev/null || uname -n)
USER_NAME=${USER:-$(id -un 2>/dev/null || echo unknown)}
SAFE=$(printf "%s_%s" "$HOST_NAME" "$USER_NAME" | tr -c 'A-Za-z0-9_.-' '_')
USER_ROOT="$ROOT_PATH/users/linux/$SAFE"
AGENT_ID=$(date '+%Y%m%d-%H%M%S')-$$
AGENT_ROOT="$USER_ROOT/agents/$AGENT_ID"
mkdir -p "$AGENT_ROOT" "$USER_ROOT/scratch" "$USER_ROOT/notes" "$USER_ROOT/logs" "$USER_ROOT/outbox"
cat > "$USER_ROOT/OWNER.json" <<EOF
{
  "os": "Linux",
  "role": "User",
  "host": "$HOST_NAME",
  "username": "$USER_NAME",
  "uid": "$(id -u 2>/dev/null || echo unknown)"
}
EOF
cat > "$USER_ROOT/IMMER_LESEN.md" <<EOF
# Immer Lesen

Dieser Ordner gehoert zu $HOST_NAME/$USER_NAME. Wenn du nicht dieser Nutzer bist, schreibe nicht in diesen Ordner.
EOF
cat > "$AGENT_ROOT/AGENT_POLICY.md" <<EOF
# Agent Policy

Arbeite nur fuer den Owner dieses Nutzerordners. Nutze zentrale Helper aus AIRGAP_CLINE_HOME.
EOF
printf "# Aktuelle Aufgabe\n\nNoch keine Aufgabe dokumentiert.\n" > "$AGENT_ROOT/CURRENT_TASK.md"
printf "{}\n" > "$AGENT_ROOT/WORKSPACE_BINDINGS.json"
mkdir -p "$ROOT_PATH/state"
printf "%s\n" "$AGENT_ROOT"