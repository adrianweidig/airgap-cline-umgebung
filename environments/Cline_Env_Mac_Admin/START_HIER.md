# Start Hier: Cline_Env_Mac_Admin

Diese Umgebung ist eine exportierbare Air-Gap-Cline-Ausgangsumgebung.

## Voraussetzung

Cline ist bereits installiert, eingerichtet und mit dem gewuenschten KI-Server verbunden. Diese Umgebung veraendert keine Provider-, Modell- oder Authentifizierungsdaten.

## Initialisierung durch Cline

Gib Cline diesen Auftrag:

`	ext
Initialisiere dich ueber folgenden Pfad: <vollstaendiger Pfad zu diesem Ordner>
`

Cline muss dann in dieser Reihenfolge lesen:

1. START_HIER.md
2. AGENTS.md
3. ENVIRONMENT.md
4. shared/rules/00-airgap-grundsaetze.md

## Lokales Setup

Falls Cline ein Skript ausfuehren soll, ist fuer diese Variante vorgesehen:

`	ext
./scripts/initialize-airgap-cline-environment.sh
`

Das Skript erzeugt den eigenen Nutzer-/Agentenordner, synchronisiert globale Cline-Stubs und schreibt state/bootstrap-status.json. Es darf keine Provider- oder KI-Server-Konfiguration aendern.