#!/bin/sh
set -eu

DRY_RUN=0
ROOT_PATH=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    *) ROOT_PATH=$1 ;;
  esac
  shift
done
if [ -z "$ROOT_PATH" ]; then
  SCRIPT_DIR=$(dirname "$0")
  ROOT_PATH=$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)
fi

HOST_NAME=$(hostname 2>/dev/null || uname -n)
USER_NAME=${USER:-$(id -un 2>/dev/null || echo unknown)}
UID_VALUE=$(id -u 2>/dev/null || echo unknown)
SAFE=$(printf "%s_%s" "$HOST_NAME" "$USER_NAME" | tr -c 'A-Za-z0-9_.-' '_')
USER_ROOT="$ROOT_PATH/users/linux/$SAFE"
AGENT_ID=$(date '+%Y%m%d-%H%M%S')-$$
AGENT_ROOT="$USER_ROOT/agents/$AGENT_ID"
OWNER_PATH="$USER_ROOT/OWNER.json"

if [ -f "$OWNER_PATH" ]; then
  if ! grep -q "\"username\": \"$USER_NAME\"" "$OWNER_PATH"; then
    echo "OWNER.json gehoert nicht zum aktuellen Nutzer: $OWNER_PATH" >&2
    exit 2
  fi
fi

if [ "$DRY_RUN" -eq 1 ]; then
  printf '{"dryRun":true,"userRoot":"%s","agentRoot":"%s","ownerPath":"%s"}\n' "$USER_ROOT" "$AGENT_ROOT" "$OWNER_PATH"
  exit 0
fi

mkdir -p "$AGENT_ROOT" "$USER_ROOT/scratch" "$USER_ROOT/notes" "$USER_ROOT/logs" "$USER_ROOT/outbox"
cat > "$OWNER_PATH" <<EOF
{
  "schemaVersion": 1,
  "environment": "Cline_Env_Linux_User",
  "os": "Linux",
  "role": "User",
  "host": "$HOST_NAME",
  "username": "$USER_NAME",
  "uid": "$UID_VALUE",
  "writableBy": "owner-only"
}
EOF
cat > "$USER_ROOT/IMMER_LESEN.md" <<EOF
# Immer Lesen

Dieser Ordner gehoert zu $HOST_NAME/$USER_NAME. Wenn du nicht dieser Nutzer bist, schreibe nicht in diesen Ordner.
EOF
cat > "$AGENT_ROOT/AGENT_POLICY.md" <<EOF
# Agent Policy

Arbeite nur fuer den Owner dieses Nutzerordners. Pruefe OWNER.json vor Schreibzugriffen. Nutze zentrale Helper aus AIRGAP_CLINE_HOME.
EOF
printf "# Aktuelle Aufgabe\n\nNoch keine Aufgabe dokumentiert.\n" > "$AGENT_ROOT/CURRENT_TASK.md"
printf "{}\n" > "$AGENT_ROOT/WORKSPACE_BINDINGS.json"
mkdir -p "$ROOT_PATH/state"
printf "%s\n" "$AGENT_ROOT"