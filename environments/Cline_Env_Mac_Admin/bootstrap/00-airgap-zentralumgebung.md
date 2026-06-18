<!-- AIRGAP-CLINE-STUB:v4 -->
# Air-Gap-Cline-Zentralumgebung

Dieser Stub wird bei der Initialisierung in globale Cline-Regelpfade des aktuellen Nutzers geschrieben. Er ist der dauerhafte Startanker nach dem ersten Bootstrap.

AIRGAP_CLINE_HOME wird beim Sync auf den absoluten Pfad dieser Umgebung gesetzt.

## Pflicht Fuer Cline

- Vor jeder Aufgabe zuerst den globalen Stub lesen und daraus `AIRGAP_CLINE_HOME` bestimmen.
- Danach immer `bootstrap/FIRST_READ.md` aus `AIRGAP_CLINE_HOME` lesen.
- Danach `AGENTS.md`, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION` und `shared/rules/*.md` lesen.
- Erst danach Workflows, Skills, Helper, Nutzerordner, Workspace-Metadaten oder Zielrepos verwenden.
- Wenn `AIRGAP_CLINE_HOME` nicht lesbar oder widerspruechlich ist, anhalten und den Nutzer nach dem gueltigen Pfad fragen.
- Keine Provider-, Modell-, Authentifizierungs- oder KI-Serverdaten veraendern.

## Erwarteter Pfad

- Umgebung: `Cline_Env_Mac_Admin`
- OS: `Mac`
- Rolle: `Admin`
- FIRST_READ_CONTRACT: `AIRGAP_CLINE_HOME/bootstrap/FIRST_READ.md`
- First-Read-Vertrag: `AIRGAP_CLINE_HOME/bootstrap/FIRST_READ.md`