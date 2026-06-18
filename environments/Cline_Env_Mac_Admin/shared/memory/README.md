# Koordiniertes Memory

Memory ist ein zentraler Runtime-Datenbestand unter `workspaces/<hash>/memory/`. Zielrepos werden nicht mit Memory-Dateien verschmutzt.

## Regeln

- `MEMORY.md` ist die kurze deterministische Lesefassung fuer Agenten.
- `MEMORY.json` ist die kanonische maschinenlesbare Wahrheit.
- Neue Fakten, Entscheidungen und naechste Schritte werden erst als Vorschlag nach `memory/inbox/*.memory.md` geschrieben.
- Konsolidierte Updates laufen ueber `shared/helpers/python/memory_update.py`.
- `EVENTS.jsonl` ist append-only.
- Keine Secrets, Rohlogs, Chatverlaeufe oder Chain-of-Thought speichern.

## Abschnitte

- `READ_FIRST`: kritische Hinweise, die jeder Agent zuerst beachten muss.
- `FACTS`: stabile Fakten mit IDs `F-0001`.
- `DECISIONS`: dauerhafte Entscheidungen mit IDs `D-0001`.
- `ACTIVE`: aktueller Fokus mit IDs `A-0001`.
- `NEXT`: naechste Schritte mit IDs `N-0001`.
- `DO_NOT`: Verbote und harte Grenzen mit IDs `X-0001`.
- `OPEN_QUESTIONS`: offene Fragen mit IDs `Q-0001`.