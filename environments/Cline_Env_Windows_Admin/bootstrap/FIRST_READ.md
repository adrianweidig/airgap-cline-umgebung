<!-- AIRGAP-CLINE-FIRST-READ:v1 -->
# First-Read-Vertrag: Cline_Env_Windows_Admin

Diese Datei beschreibt das Verhalten nach dem ersten Bootstrap. Sie ist der erste fachliche Kontext, den Cline aus `AIRGAP_CLINE_HOME` lesen muss, bevor irgendeine Nutzeraufgabe bearbeitet wird.

## Pflichtstart Jeder Aufgabe

1. Loese `AIRGAP_CLINE_HOME` aus dem globalen Air-Gap-Stub auf.
2. Pruefe, dass dieser Pfad lesbar ist und zu `Cline_Env_Windows_Admin` gehoert.
3. Lies immer zuerst diese Datei: `bootstrap/FIRST_READ.md`.
4. Lies danach `AGENTS.md`, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION` und alle Regeln unter `shared/rules/`.
5. Pruefe `state/bootstrap-status.json`, falls vorhanden. Wenn dort ein Fehlerstatus steht, bearbeite keine Zielworkspace-Aufgabe, bevor der Zustand geklaert ist.
6. Wenn ein externer Arbeitsordner verwendet wird, registriere oder finde ihn unter `workspaces/<hash>/` und lies danach dessen `memory/MEMORY.md`, falls vorhanden.
7. Waehle erst nach diesen Schritten passende Workflows, Skills und Helper.

## Stop-Bedingungen

- Wenn `AIRGAP_CLINE_HOME` fehlt, nicht lesbar ist oder nicht zu dieser Umgebung passt, stoppe und frage nach dem gueltigen Air-Gap-Pfad.
- Wenn `AGENTS.md`, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION` oder `shared/rules/` fehlen, stoppe und melde den konkreten fehlenden Bestandteil.
- Wenn mehrere Air-Gap-Stubs widerspruechliche Pfade nennen, stoppe und lasse den Nutzer den aktiven Zentralpfad bestaetigen.
- Wenn der Nutzer eine Aufgabe in einem Zielrepo stellt, lege dort trotzdem keine dauerhaften `.cline`, `.clinerules`, Skills, Workflows, Helper oder Memory-Dateien an, solange dies nicht ausdruecklich verlangt wurde.

## Verhaltensanker

- Der Zentralpfad ist Quelle der Wahrheit fuer Regeln, Workflows, Skills, Helper, Nutzerstatus, Workspace-Metadaten und Memory.
- Provider-, Modell-, Auth- und KI-Serverkonfiguration sind nicht Teil dieser Umgebung und werden nicht veraendert.
- Nutzer- und Agentendaten werden nur in den Owner-konformen Ordnern unter `users/windows/` geschrieben.
- Geteilte Workspace-Memory wird nur zentral unter `workspaces/<hash>/memory/` gepflegt.
- Jede Abweichung von diesem Vertrag muss vom Nutzer explizit beauftragt werden.