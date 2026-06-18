<!-- AIRGAP-CLINE-MANAGED:v2 -->
# Externen Arbeitsordner Registrieren

1. Nimm Zielpfad und optionalen Alias entgegen.
2. Normalisiere den Pfad plattformspezifisch.
3. Hashe den normalisierten Pfad.
4. Erzeuge oder aktualisiere `workspaces/<hash>/WORKSPACE.json`.
5. Wenn derselbe Hash auf einen anderen Pfad zeigt, brich wegen Kollision ab.
6. Schreibe `NOTIZEN.md`, `RULE_OVERRIDES.md` und `helper-output/`.