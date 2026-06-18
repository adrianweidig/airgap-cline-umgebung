#!/bin/sh
set -eu
ROOT_PATH=""
AGENT_ID="default-agent"
DRY_RUN=0
REPAIR=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) ROOT_PATH="$2"; shift 2 ;;
    --agent-id) AGENT_ID="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --repair) REPAIR=1; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -z "$ROOT_PATH" ]; then ROOT_PATH=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd); fi
if [ ! -f "$ROOT_PATH/MANIFEST.json" ]; then echo "Invalid Air-Gap Cline environment: $ROOT_PATH" >&2; exit 1; fi
if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry run for Cline_Env_Solaris_User at $ROOT_PATH"
  echo "Would create or repair the current user folder and sync global Cline stubs."
  exit 0
fi
"$SCRIPT_DIR/new-airgap-cline-user-workspace.sh" --root "$ROOT_PATH" --agent-id "$AGENT_ID" >/dev/null
if [ "$REPAIR" -eq 1 ]; then "$SCRIPT_DIR/sync-cline-global-stubs.sh" --root "$ROOT_PATH" --repair >/dev/null; else "$SCRIPT_DIR/sync-cline-global-stubs.sh" --root "$ROOT_PATH" >/dev/null; fi
mkdir -p "$ROOT_PATH/state"
cat > "$ROOT_PATH/state/bootstrap-status.json" <<EOF
{"schemaVersion":2,"environment":"Cline_Env_Solaris_User","status":"ok","version":"0.5.0","user":"${USER:-unknown}","host":"$(hostname 2>/dev/null || uname -n)","rootPath":"$ROOT_PATH","providerConfigurationChanged":false}
EOF
echo "Initialization completed for Cline_Env_Solaris_User."
