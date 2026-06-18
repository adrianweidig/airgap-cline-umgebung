<!-- AIRGAP-CLINE-MANAGED:v3 -->
---
name: koordiniertes-memory
description: Liest, erstellt und konsolidiert kurze deterministische Workspace- und User-Memory in der zentralen Air-Gap-Umgebung.
---

# koordiniertes-memory

## Wann verwenden

Nutze diesen Skill, wenn ein Agent Kontext dauerhaft fuer andere Agenten erhalten soll oder vor einer Aufgabe geteiltes Workspace-Memory lesen muss.

## Vorgehen

1. Bestimme `AIRGAP_CLINE_HOME`.
2. Registriere den externen Arbeitsordner und ermittle `workspaces/<hash>/`.
3. Initialisiere Memory bei Bedarf mit `memory_update.py init`.
4. Lies `memory/MEMORY.md`.
5. Schreibe dauerhafte Erkenntnisse mit `memory_update.py propose`.
6. Konsolidiere nur mit `memory_update.py apply`.

## Grenzen

Kein Memory in Zielrepos, keine Secrets, keine Rohlogs, keine Chatverlaeufe und keine Chain-of-Thought.