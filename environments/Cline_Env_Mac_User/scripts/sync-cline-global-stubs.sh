#!/bin/sh
set -eu
ROOT_PATH=${1:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}
CLINE_HOME="${HOME}/.cline"
mkdir -p "$CLINE_HOME/rules" "$CLINE_HOME/data/workflows" "$CLINE_HOME/skills"
cat > "$CLINE_HOME/rules/00-airgap-zentralumgebung.md" <<EOF
# Air-Gap-Cline-Zentralumgebung

AIRGAP_CLINE_HOME: \`$ROOT_PATH\`

Vor jeder Aufgabe: lies \`$ROOT_PATH/AGENTS.md\`, \`$ROOT_PATH/ENVIRONMENT.md\` und die Regeln unter \`$ROOT_PATH/shared/rules\`. Veraendere keine Provider- oder Modellkonfiguration.
EOF
cp "$ROOT_PATH"/shared/workflows/*.md "$CLINE_HOME/data/workflows/"
for skill in "$ROOT_PATH"/shared/skills/*; do
  [ -d "$skill" ] || continue
  base=$(basename "$skill")
  rm -rf "$CLINE_HOME/skills/$base"
  cp -R "$skill" "$CLINE_HOME/skills/$base"
done
echo "Globale Cline-Stubs synchronisiert."