# Architektur

Die Air-Gap-Cline-Umgebung ist ein zentraler Startpfad fuer Cline. Dieser Pfad enthaelt Regeln, Workflows, Skills, Memory-Vorlagen und Helper-Skripte. Cline soll diese zentrale Umgebung als Quelle der Wahrheit verwenden, auch wenn spaeter in beliebigen externen Repos, Desktop-Ordnern oder Netzwerkshares gearbeitet wird.

## Grundprinzipien

- Cline ist bereits installiert und KI-faehig eingerichtet.
- Die Umgebung veraendert keine Provider-, Modell- oder Authentifizierungsdaten.
- Der zentrale Umgebungsordner ist exportierbar.
- Nutzer- und Agentendaten werden lokal in `users/` erzeugt.
- Externe Arbeitsordner werden in `workspaces/` registriert.
- Helper und Memory bleiben zentral und werden nicht in Zielrepos kopiert.

## Memory-Lifecycle

- Private Nutzerpraeferenzen liegen unter `users/<plattform>/<owner>/memory/USER_MEMORY.md`.
- Laufende Agenten-Notizen liegen unter `users/<plattform>/<owner>/agents/<agentid>/memory/SESSION.md`.
- Geteiltes Workspace-Memory liegt unter `workspaces/<hash>/memory/`.
- `MEMORY.json` ist die kanonische maschinenlesbare Wahrheit.
- `MEMORY.md` ist die kurze deterministische Lesefassung fuer Cline- und andere KI-Agenten.
- Aenderungen an geteilter Memory laufen ueber Vorschlaege und den Helper `memory_update.py`.

## Varianten

Es gibt je OS eine User- und Admin-Variante. User-Varianten arbeiten ohne Adminrechte und schreiben nur in Benutzerpfade. Admin-Varianten duerfen zentrale Ablagen vorbereiten, bleiben aber ebenfalls provider-neutral.
## First-Read-Vertrag

Nach der ersten Initialisierung ist der globale Stub die dauerhafte Eintrittsstelle fuer Cline. Er liegt in den globalen Cline-Regelpfaden und verweist auf `AIRGAP_CLINE_HOME`. Cline muss diesen Pfad als Quelle der Wahrheit behandeln und vor jeder Zielworkspace-Arbeit zuerst `bootstrap/FIRST_READ.md` lesen. Danach folgen `AGENTS.md`, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION`, `shared/rules/`, optional `state/bootstrap-status.json` und erst dann Workspace-Memory, Workflows, Skills und Helper.