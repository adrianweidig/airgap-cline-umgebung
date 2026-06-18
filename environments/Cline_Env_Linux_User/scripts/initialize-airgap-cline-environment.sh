#!/bin/sh
set -eu
ROOT_PATH=${1:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}

for required in START_HIER.md AGENTS.md ENVIRONMENT.md MANIFEST.json; do
  if [ ! -f "$ROOT_PATH/$required" ]; then
    echo "Fehlende Pflichtdatei: $required" >&2
    exit 1
  fi
done

"$ROOT_PATH/scripts/new-airgap-cline-user-workspace.sh" "$ROOT_PATH" >/tmp/airgap-cline-agent-root.$$
"$ROOT_PATH/scripts/sync-cline-global-stubs.sh" "$ROOT_PATH"
AGENT_ROOT=$(cat /tmp/airgap-cline-agent-root.$$)
rm -f /tmp/airgap-cline-agent-root.$$
mkdir -p "$ROOT_PATH/state"
cat > "$ROOT_PATH/state/bootstrap-status.json" <<EOF
{
  "environment": "Cline_Env_Linux_User",
  "rootPath": "$ROOT_PATH",
  "agentRoot": "$AGENT_ROOT",
  "providerChanged": false
}
EOF
echo "Initialisierung abgeschlossen fuer Cline_Env_Linux_User."