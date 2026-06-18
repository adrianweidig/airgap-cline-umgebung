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

MARKER="AIRGAP-CLINE-STUB:v2"
MANAGED="AIRGAP-CLINE-MANAGED:v2"
CLINE_HOME="${HOME}/.cline"
RULE_TARGET="$CLINE_HOME/rules/00-airgap-zentralumgebung.md"

write_file() {
  target=$1
  content_file=$2
  parent=$(dirname "$target")
  [ "$DRY_RUN" -eq 1 ] || mkdir -p "$parent"
  if [ -f "$target" ] && ! grep -q "$MARKER\|$MANAGED" "$target"; then
    backup="$target.backup-$(date '+%Y%m%d-%H%M%S')"
    echo "backup $target -> $backup"
    [ "$DRY_RUN" -eq 1 ] || cp "$target" "$backup"
  fi
  echo "write $target"
  [ "$DRY_RUN" -eq 1 ] || cp "$content_file" "$target"
}

TMP_STUB="${TMPDIR:-/tmp}/airgap-cline-stub.$$"
cat > "$TMP_STUB" <<EOF
<!-- $MARKER -->
# Air-Gap-Cline-Zentralumgebung

AIRGAP_CLINE_HOME: \`$ROOT_PATH\`

Vor jeder Aufgabe: lies \`$ROOT_PATH/AGENTS.md\`, \`$ROOT_PATH/ENVIRONMENT.md\` und die Regeln unter \`$ROOT_PATH/shared/rules\`. Veraendere keine Provider-, Modell-, Auth- oder KI-Server-Konfiguration.
EOF
write_file "$RULE_TARGET" "$TMP_STUB"
rm -f "$TMP_STUB"

WORKFLOW_TARGET="$CLINE_HOME/data/workflows"
for workflow in "$ROOT_PATH"/shared/workflows/*.md; do
  [ -f "$workflow" ] || continue
  write_file "$WORKFLOW_TARGET/$(basename "$workflow")" "$workflow"
done

SKILLS_TARGET="$CLINE_HOME/skills"
[ "$DRY_RUN" -eq 1 ] || mkdir -p "$SKILLS_TARGET"
for skill in "$ROOT_PATH"/shared/skills/*; do
  [ -d "$skill" ] || continue
  base=$(basename "$skill")
  target="$SKILLS_TARGET/$base"
  if [ -d "$target" ]; then
    if [ ! -f "$target/SKILL.md" ] || ! grep -q "$MANAGED" "$target/SKILL.md"; then
      backup="$target.backup-$(date '+%Y%m%d-%H%M%S')"
      echo "backup-directory $target -> $backup"
      [ "$DRY_RUN" -eq 1 ] || mv "$target" "$backup"
    else
      [ "$DRY_RUN" -eq 1 ] || rm -rf "$target"
    fi
  fi
  echo "sync-skill $target"
  [ "$DRY_RUN" -eq 1 ] || cp -R "$skill" "$target"
done

if [ "$DRY_RUN" -eq 0 ]; then
  mkdir -p "$ROOT_PATH/state"
  cat > "$ROOT_PATH/state/last-stub-sync.json" <<EOF
{
  "schemaVersion": 1,
  "rootPath": "$ROOT_PATH",
  "providerChanged": false
}
EOF
fi