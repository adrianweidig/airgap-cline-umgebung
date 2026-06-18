#!/bin/sh
set -eu

DRY_RUN=0
REPAIR=0
NO_GLOBAL_STUB=0
ROOT_PATH=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --repair) REPAIR=1 ;;
    --no-global-stub) NO_GLOBAL_STUB=1 ;;
    *) ROOT_PATH=$1 ;;
  esac
  shift
done
if [ -z "$ROOT_PATH" ]; then
  SCRIPT_DIR=$(dirname "$0")
  ROOT_PATH=$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)
fi

for required in START_HIER.md AGENTS.md ENVIRONMENT.md MANIFEST.json shared/rules shared/workflows shared/skills shared/helpers/python; do
  if [ ! -e "$ROOT_PATH/$required" ]; then
    echo "Fehlender Bestandteil: $required" >&2
    exit 1
  fi
done

TMP_FILE="${TMPDIR:-/tmp}/airgap-cline-agent-root.$$"
if [ "$DRY_RUN" -eq 1 ]; then
  sh "$ROOT_PATH/scripts/new-airgap-cline-user-workspace.sh" --dry-run "$ROOT_PATH" > "$TMP_FILE"
else
  sh "$ROOT_PATH/scripts/new-airgap-cline-user-workspace.sh" "$ROOT_PATH" > "$TMP_FILE"
fi
AGENT_ROOT=$(tail -n 1 "$TMP_FILE")
rm -f "$TMP_FILE"

if [ "$NO_GLOBAL_STUB" -eq 0 ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    sh "$ROOT_PATH/scripts/sync-cline-global-stubs.sh" --dry-run "$ROOT_PATH"
  else
    sh "$ROOT_PATH/scripts/sync-cline-global-stubs.sh" "$ROOT_PATH"
  fi
fi

if [ "$DRY_RUN" -eq 0 ]; then
  mkdir -p "$ROOT_PATH/state"
  cat > "$ROOT_PATH/state/bootstrap-status.json" <<EOF
{
  "schemaVersion": 2,
  "status": "ok",
  "environment": "Cline_Env_Mac_User",
  "version": "0.2.0",
  "rootPath": "$ROOT_PATH",
  "agentRoot": "$AGENT_ROOT",
  "dryRun": false,
  "repair": $REPAIR,
  "providerChanged": false
}
EOF
fi
echo "Initialisierung abgeschlossen fuer Cline_Env_Mac_User."