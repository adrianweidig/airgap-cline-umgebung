<!-- AIRGAP-CLINE-MANAGED:v4 -->
# First-Read Zentralumgebung

Diese Regel ist absichtlich allgemein und immer aktiv. Sie sorgt dafuer, dass Cline nach dem ersten Bootstrap den zentralen Air-Gap-Pfad vor jeder Aufgabe als erste Quelle liest.

## Muss Vor Jeder Aufgabe

- Loese `AIRGAP_CLINE_HOME` aus dem globalen Air-Gap-Stub auf.
- Lies zuerst `bootstrap/FIRST_READ.md` aus `AIRGAP_CLINE_HOME`.
- Lies danach `AGENTS.md`, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION` und alle Regeln unter `shared/rules/`.
- Pruefe `state/bootstrap-status.json`, falls vorhanden.
- Bearbeite Zielworkspaces erst, nachdem die zentrale Umgebung erfolgreich gelesen wurde.

## Darf Nicht

- Nicht mit einem Zielrepo beginnen, wenn der zentrale Air-Gap-Pfad fehlt oder unklar ist.
- Keine dauerhaften Cline-Dateien, Regeln, Skills, Workflows, Helper oder Memory-Dateien in Zielrepos anlegen, ausser der Nutzer fordert das ausdruecklich.
- Keine Provider-, Modell-, Auth- oder KI-Serverkonfiguration aendern.