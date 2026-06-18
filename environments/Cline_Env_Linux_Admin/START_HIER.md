# Start Hier: Cline_Env_Linux_Admin

Diese Umgebung ist eine direkt exportierbare Air-Gap-Cline-Ausgangsumgebung. Cline selbst muss bereits installiert, eingerichtet und mit dem vorgesehenen KI-Server verbunden sein.

## Erstauftrag an Cline

Gib Cline den vollstaendigen Pfad zu diesem Ordner:

```text
Initialisiere dich ueber folgenden Pfad: <vollstaendiger Pfad zu diesem Cline_Env_... Ordner>
```

Cline muss danach in dieser Reihenfolge lesen:

1. `START_HIER.md`
2. `AGENTS.md`
3. `ENVIRONMENT.md`
4. alle Dateien unter `shared/rules/`
5. den passenden Workflow unter `shared/workflows/`

## Setup-Skript

Vorgesehen fuer diese Variante:

```text
sh ./scripts/initialize-airgap-cline-environment.sh
```

Fuer eine Vorschau ohne Schreibzugriff:

```text
sh ./scripts/initialize-airgap-cline-environment.sh --dry-run
```

Das Skript validiert den Zentralpfad, erzeugt einen eigenen Nutzer-/Agentenordner, synchronisiert globale Cline-Stubs und schreibt `state/bootstrap-status.json`. Es veraendert keine Provider-, Modell-, Auth- oder KI-Server-Konfiguration.

## Wichtige Cline-Pfade

- Globale Regeln: `~/.cline/rules` und kompatibel `Documents/Cline/Rules`.
- Globale Workflows: `~/.cline/data/workflows`.
- Globale Skills: `~/.cline/skills`.
- Projektbezogene Cline-Dateien werden in externen Zielrepos nicht angelegt, ausser der Nutzer fordert das ausdruecklich.
## Koordiniertes Memory

Bei externen Arbeitsordnern liest Cline nach der Registrierung `workspaces/<hash>/memory/MEMORY.md`. Wenn Memory fehlt, wird sie zentral mit dem Memory-Helper initialisiert. Zielrepos erhalten keine Memory-Dateien.