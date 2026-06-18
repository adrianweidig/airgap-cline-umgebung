<!-- AIRGAP-CLINE-MANAGED:v2 -->
# Nutzerordner Anlegen

1. Erkenne Nutzer, Host, OS und Variante.
2. Erzeuge den passenden Ordner unter `users/<plattform>/<nutzer>/`.
3. Wenn `OWNER.json` existiert, pruefe Owner vor jedem Schreibzugriff.
4. Schreibe oder aktualisiere `OWNER.json` mit Schema-Version.
5. Erzeuge einen neuen Agentenordner mit `AGENT_POLICY.md`, `CURRENT_TASK.md` und `WORKSPACE_BINDINGS.json`.