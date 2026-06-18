#!/bin/sh
set -eu
ROOT_PATH=""
DRY_RUN=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) ROOT_PATH="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --repair) shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -z "$ROOT_PATH" ]; then ROOT_PATH=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd); fi
write_file() {
  target="$1"
  if [ "$DRY_RUN" -eq 1 ]; then echo "Would write stub: $target"; return; fi
  dir=$(dirname -- "$target")
  mkdir -p "$dir"
  if [ -f "$target" ] && ! grep -q "AIRGAP-CLINE-STUB:" "$target" 2>/dev/null; then cp "$target" "$target.backup-$(date +%Y%m%d%H%M%S)"; fi
  cat > "$target" <<EOF
# Air-Gap Cline Central Environment

AIRGAP-CLINE-STUB:v5
FIRST_READ_CONTRACT: bootstrap/FIRST_READ.md
AIRGAP_CLINE_HOME=$ROOT_PATH

This global rule is the permanent entry point after the first bootstrap.

## Required Behavior For Cline

1. Resolve AIRGAP_CLINE_HOME from this stub before every task.
2. Read $ROOT_PATH/bootstrap/FIRST_READ.md.
3. Read $ROOT_PATH/AGENTS.md, $ROOT_PATH/ENVIRONMENT.md, $ROOT_PATH/MANIFEST.json, $ROOT_PATH/VERSION, and all rules under $ROOT_PATH/shared/rules.
4. Use workflows, skills, helpers, user folders, workspace metadata, and target repositories only after this first read.
5. Stop and ask for the valid Air-Gap path when the path is missing, unreadable, or contradicted by another stub.
6. Do not change provider, model, authentication, or AI-server configuration.
EOF
}
CLINE_HOME="${CLINE_HOME:-$HOME/.cline}"
write_file "$CLINE_HOME/rules/00-airgap-central-environment.md"
write_file "$HOME/Documents/Cline/Rules/00-airgap-central-environment.md"
write_file "$HOME/Cline/Rules/00-airgap-central-environment.md"
