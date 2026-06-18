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
USER_ROOT="$ROOT_PATH/users/solaris/$SAFE"
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

mkdir -p "$AGENT_ROOT" "$AGENT_ROOT/memory" "$AGENT_ROOT/outbox/memory-proposals" "$USER_ROOT/memory" "$USER_ROOT/scratch" "$USER_ROOT/notes" "$USER_ROOT/logs" "$USER_ROOT/outbox"
cat > "$OWNER_PATH" <<EOF
{
  "schemaVersion": 1,
  "environment": "Cline_Env_Solaris_User",
  "os": "Solaris",
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
cat > "$USER_ROOT/memory/USER_MEMORY.md" <<'EOF'
# User Memory

scope: user
schema: airgap-user-memory/v1

## READ_FIRST
- Keine Secrets, Tokens, Passwoerter oder privaten Rohdaten speichern.

## PREFERENCES
- Noch keine dauerhaften Nutzerpraeferenzen erfasst.

## DO_NOT
- Nicht in fremde Nutzer- oder Agentenordner schreiben.
EOF
cat > "$AGENT_ROOT/memory/SESSION.md" <<'EOF'
# Session Memory

scope: agent-session
schema: airgap-session-memory/v1

## TASK
- Noch keine Aufgabe dokumentiert.

## SUMMARY
- Noch keine Zusammenfassung erfasst.

## MEMORY_PROPOSALS
- Dauerhafte Erkenntnisse als Vorschlaege nach `outbox/memory-proposals/` schreiben.
EOF
printf "{}\n" > "$AGENT_ROOT/WORKSPACE_BINDINGS.json"
mkdir -p "$ROOT_PATH/state"
printf "%s\n" "$AGENT_ROOT"