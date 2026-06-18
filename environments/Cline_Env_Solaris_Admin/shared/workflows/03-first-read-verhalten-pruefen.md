<!-- AIRGAP-CLINE-MANAGED:v4 -->
# First-Read Verhalten Pruefen

1. Ermittle `AIRGAP_CLINE_HOME` aus dem globalen Stub.
2. Pruefe `bootstrap/FIRST_READ.md`, `AGENTS.md`, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION` und `shared/rules/`.
3. Lies die Dateien in genau dieser Reihenfolge.
4. Pruefe optional `state/bootstrap-status.json` und melde Fehlerstatus.
5. Registriere externe Zielordner zentral unter `workspaces/<hash>/`, bevor dort gearbeitet wird.
6. Lade passende Memory, Workflows, Skills und Helper erst nach dem zentralen First-Read.