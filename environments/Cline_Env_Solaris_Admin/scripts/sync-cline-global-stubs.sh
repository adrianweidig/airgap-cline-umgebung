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

MARKER="AIRGAP-CLINE-STUB:v4"
MANAGED_PATTERN="AIRGAP-CLINE-STUB:v2\|AIRGAP-CLINE-STUB:v3\|AIRGAP-CLINE-STUB:v4\|AIRGAP-CLINE-MANAGED:v2\|AIRGAP-CLINE-MANAGED:v3\|AIRGAP-CLINE-MANAGED:v4\|AIRGAP-CLINE-FIRST-READ:v1"
CLINE_HOME="${HOME}/.cline"

write_file() {
  target=$1
  content_file=$2
  parent=$(dirname "$target")
  [ "$DRY_RUN" -eq 1 ] || mkdir -p "$parent"
  if [ -f "$target" ] && ! grep -q "$MANAGED_PATTERN" "$target"; then
    backup="$target.backup-$(date '+%Y%m%d-%H%M%S')"
    echo "backup $target -> $backup"
    [ "$DRY_RUN" -eq 1 ] || cp "$target" "$backup"
  fi
  echo "write $target"
  [ "$DRY_RUN" -eq 1 ] || cp "$content_file" "$target"
}

copy_skill() {
  source_dir=$1
  target_dir=$2
  if [ -d "$target_dir" ]; then
    if [ ! -f "$target_dir/SKILL.md" ] || ! grep -q "$MANAGED_PATTERN" "$target_dir/SKILL.md"; then
      backup="$target_dir.backup-$(date '+%Y%m%d-%H%M%S')"
      echo "backup-directory $target_dir -> $backup"
      [ "$DRY_RUN" -eq 1 ] || mv "$target_dir" "$backup"
    else
      [ "$DRY_RUN" -eq 1 ] || rm -rf "$target_dir"
    fi
  fi
  echo "sync-skill $target_dir"
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$(dirname "$target_dir")"
    cp -R "$source_dir" "$target_dir"
  fi
}

TMP_STUB="${TMPDIR:-/tmp}/airgap-cline-stub.$$"
cat > "$TMP_STUB" <<EOF
<!-- $MARKER -->
# Air-Gap-Cline-Zentralumgebung

AIRGAP_CLINE_HOME: \`$ROOT_PATH\`
FIRST_READ_CONTRACT: \`$ROOT_PATH/bootstrap/FIRST_READ.md\`

Diese globale Regel ist der dauerhafte Startanker nach dem ersten Bootstrap.

Pflicht als allererster Schritt jeder Aufgabe:

1. Loese AIRGAP_CLINE_HOME aus diesem Stub auf.
2. Pruefe, dass \`$ROOT_PATH\` lesbar ist und die Dateien \`START_HIER.md\`, \`AGENTS.md\`, \`ENVIRONMENT.md\`, \`MANIFEST.json\`, \`VERSION\` und \`shared/rules\` enthaelt.
3. Lies zuerst \`$ROOT_PATH/bootstrap/FIRST_READ.md\`.
4. Lies danach \`$ROOT_PATH/AGENTS.md\`, \`$ROOT_PATH/ENVIRONMENT.md\`, \`$ROOT_PATH/MANIFEST.json\`, \`$ROOT_PATH/VERSION\` und alle Regeln unter \`$ROOT_PATH/shared/rules\`.
5. Pruefe \`$ROOT_PATH/state/bootstrap-status.json\`, falls vorhanden.
6. Nutze Workflows, Skills, Helper, Nutzerordner, Workspace-Metadaten und Zielrepos erst nach diesem First-Read.
7. Wenn der Pfad fehlt, unlesbar ist oder mehreren Stubs widerspricht, halte an und frage den Nutzer nach dem gueltigen Air-Gap-Pfad.
8. Veraendere keine Provider-, Modell-, Auth- oder KI-Server-Konfiguration.
EOF

write_file "$CLINE_HOME/rules/00-airgap-zentralumgebung.md" "$TMP_STUB"
write_file "$HOME/Documents/Cline/Rules/00-airgap-zentralumgebung.md" "$TMP_STUB"
write_file "$HOME/Cline/Rules/00-airgap-zentralumgebung.md" "$TMP_STUB"
rm -f "$TMP_STUB"

for workflow_target in "$CLINE_HOME/data/workflows" "$HOME/Documents/Cline/Workflows" "$HOME/Cline/Workflows"; do
  for workflow in "$ROOT_PATH"/shared/workflows/*.md; do
    [ -f "$workflow" ] || continue
    write_file "$workflow_target/$(basename "$workflow")" "$workflow"
  done
done

SKILLS_TARGET="$CLINE_HOME/skills"
for skill in "$ROOT_PATH"/shared/skills/*; do
  [ -d "$skill" ] || continue
  copy_skill "$skill" "$SKILLS_TARGET/$(basename "$skill")"
done

if [ "$DRY_RUN" -eq 0 ]; then
  mkdir -p "$ROOT_PATH/state"
  cat > "$ROOT_PATH/state/last-stub-sync.json" <<EOF
{
  "schemaVersion": 2,
  "environment": "Cline_Env_Solaris_Admin",
  "version": "0.4.0",
  "rootPath": "$ROOT_PATH",
  "firstReadContract": "$ROOT_PATH/bootstrap/FIRST_READ.md",
  "providerChanged": false
}
EOF
fi