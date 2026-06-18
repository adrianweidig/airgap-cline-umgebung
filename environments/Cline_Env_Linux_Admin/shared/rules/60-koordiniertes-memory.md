<!-- AIRGAP-CLINE-MANAGED:v3 -->
# Koordiniertes Memory

- Lies bei externen Arbeitsordnern zuerst `workspaces/<hash>/memory/MEMORY.md`, falls vorhanden.
- Wenn Workspace-Memory fehlt, initialisiere es nur zentral unter `workspaces/<hash>/memory/`.
- Schreibe fluechtige Arbeitsnotizen in den eigenen Agentenordner.
- Schreibe dauerhafte Erkenntnisse zuerst als Vorschlag in `memory/inbox/`.
- Konsolidiere geteilte Memory nur ueber `shared/helpers/python/memory_update.py` oder die Wrapper.
- `MEMORY.md` bleibt kurz, deterministisch und ohne Rohlogs, Secrets, Chatverlaeufe oder Chain-of-Thought.
- `MEMORY.json` ist die kanonische maschinenlesbare Quelle; `MEMORY.md` wird daraus gerendert.