# Architektur

Die Air-Gap-Cline-Umgebung ist ein zentraler Startpfad fuer Cline. Dieser Pfad enthaelt Regeln, Workflows, Skills und Helper-Skripte. Cline soll diese zentrale Umgebung als Quelle der Wahrheit verwenden, auch wenn spaeter in beliebigen externen Repos, Desktop-Ordnern oder Netzwerkshares gearbeitet wird.

## Grundprinzipien

- Cline ist bereits installiert und KI-faehig eingerichtet.
- Die Umgebung veraendert keine Provider-, Modell- oder Authentifizierungsdaten.
- Der zentrale Umgebungsordner ist exportierbar.
- Nutzer- und Agentendaten werden lokal in `users/` erzeugt.
- Externe Arbeitsordner werden in `workspaces/` registriert.
- Helper bleiben zentral und werden nicht in Zielrepos kopiert.

## Varianten

Es gibt je OS eine User- und Admin-Variante. User-Varianten arbeiten ohne Adminrechte und schreiben nur in Benutzerpfade. Admin-Varianten duerfen zentrale Ablagen vorbereiten, bleiben aber ebenfalls provider-neutral.