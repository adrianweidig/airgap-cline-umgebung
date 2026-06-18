<!-- AIRGAP-CLINE-MANAGED:v3 -->
# Memory Konsolidieren

1. Pruefe `memory/inbox/*.memory.md`.
2. Wende Vorschlaege mit `memory_update.py apply --proposal <datei>` an.
3. Wenn `parentSha256` nicht mehr passt, bleibt der Vorschlag in `inbox/` und muss neu bewertet werden.
4. Nach erfolgreichem Apply werden `MEMORY.json`, `MEMORY.md`, `ACTIVE.md`, `DECISIONS.md`, `PROGRESS.md` und `EVENTS.jsonl` aktualisiert.
5. Halte `MEMORY.md` unter ca. 150-200 Zeilen.