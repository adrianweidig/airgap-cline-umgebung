# Memory-Modell

Dieses Projekt trennt fluechtige Arbeitsnotizen, private Nutzer-Memory und geteilte Workspace-Memory.

## Schreiborte

| Inhalt | Ort |
| --- | --- |
| Fluechtige Task-Notizen | `users/<plattform>/<owner>/agents/<agentid>/memory/SESSION.md` oder `scratch/` |
| Nutzerpraeferenzen | `users/<plattform>/<owner>/memory/USER_MEMORY.md` |
| Geteilte Workspace-Kurzfassung | `workspaces/<hash>/memory/MEMORY.md` |
| Kanonische Workspace-Daten | `workspaces/<hash>/memory/MEMORY.json` |
| Vorschlaege | `workspaces/<hash>/memory/inbox/*.memory.md` |
| Aenderungsjournal | `workspaces/<hash>/memory/EVENTS.jsonl` |

## Format

`MEMORY.md` ist kurz, deterministisch und fuer Agenten optimiert. Es enthaelt feste Abschnitte: `READ_FIRST`, `FACTS`, `DECISIONS`, `ACTIVE`, `NEXT`, `DO_NOT`, `OPEN_QUESTIONS`.

Eine Aussage steht auf einer Zeile und erhaelt eine stabile ID, zum Beispiel `F-0001` oder `D-0001`.

## Grenzen

Keine Secrets, Rohlogs, Chatverlaeufe oder Chain-of-Thought speichern. Zielrepos erhalten keine Memory-Dateien, ausser der Nutzer fordert das ausdruecklich.