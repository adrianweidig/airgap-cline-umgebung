# Agentenanweisungen: Cline_Env_Windows_Admin

Diese Datei ist Pflichtkontext. Lies sie vor jeder Aufgabe, die mit dieser Umgebung oder aus dieser Umgebung heraus arbeitet.

## Lesereihenfolge

1. START_HIER.md
2. AGENTS.md
3. ENVIRONMENT.md
4. shared/rules/*.md
5. passender Workflow aus shared/workflows/
6. bei Bedarf passender Skill aus shared/skills/*/SKILL.md

## Harte Regeln

- Behandle diesen Ordner als AIRGAP_CLINE_HOME.
- Veraendere keine Provider-, Modell-, Auth- oder KI-Server-Konfiguration.
- Nutze zentrale Helper unter shared/helpers/; kopiere sie nicht in Zielrepos.
- Schreibe Nutzer- und Agentendaten nur in den eigenen Ordner unter `users/windows/`.
- Pruefe OWNER.json, bevor du in einen vorhandenen Nutzer- oder Agentenordner schreibst.
- Wenn OWNER.json nicht zum aktuellen Nutzer passt, darfst du dort nicht schreiben.
- Registriere externe Arbeitsordner unter workspaces/<hash>/.
- Schreibe Helper-Ausgaben nach workspaces/<hash>/helper-output/.
- Lege in externen Repos keine dauerhaften .cline, .clinerules, Skills, Workflows oder Helper an, ausser der Nutzer fordert das ausdruecklich.

## Arbeitsablauf fuer normale Tasks

1. Ziel und Arbeitsordner klaeren.
2. Externen Arbeitsordner zentral registrieren, falls ausserhalb von AIRGAP_CLINE_HOME gearbeitet wird.
3. Owner-Guard ausfuehren, bevor in `users/` geschrieben wird.
4. Zentrale Regeln, Workflows, Skills und Helper nutzen.
5. Fachliche Aenderungen nur im Zielrepo vornehmen, wenn sie zur Nutzeraufgabe gehoeren.
6. Checks ausfuehren oder klar dokumentieren, warum sie nicht moeglich waren.
7. Ergebnis im eigenen Agentenordner oder im passenden workspaces/<hash>/ dokumentieren.

## Plattform

- OS: Windows
- Variante: Admin
- Primaerer Modus: Windows mit VS Code Cline Extension, zentrale Ablage
- Empfohlener Ablageort: `C:\Cline_AirGap\Cline_Env_Windows_Admin oder zentraler Netzwerkshare`
## Schreibmatrix

| Inhalt | Schreibort |
| --- | --- |
| Fluechtige Task-Notizen | eigener Agentenordner unter `users/windows/.../agents/<agentid>/memory/SESSION.md` oder `scratch/` |
| Nutzerpraeferenzen | eigener Nutzerordner unter `users/windows/.../memory/USER_MEMORY.md` |
| Geteilte Workspace-Memory | `workspaces/<hash>/memory/` |
| Memory-Vorschlaege | `workspaces/<hash>/memory/inbox/*.memory.md` |
| Helper-Ausgaben | `workspaces/<hash>/helper-output/` |

Geteilte Memory wird nur ueber `shared/helpers/python/memory_update.py` oder die Wrapper aktualisiert. Schreibe keine Memory-Dateien in Zielrepos.
## Absolute Startpflicht

Nach dem ersten Bootstrap gilt fuer jeden Cline-Agenten:

1. Zuerst den globalen Air-Gap-Stub lesen und daraus `AIRGAP_CLINE_HOME` bestimmen.
2. Dann `bootstrap/FIRST_READ.md` aus `AIRGAP_CLINE_HOME` lesen.
3. Danach `AGENTS.md`, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION` und `shared/rules/*.md` lesen.
4. Optional `state/bootstrap-status.json` pruefen.
5. Erst danach Zielworkspace, Memory, Workflows, Skills und Helper verwenden.

Wenn der Zentralpfad fehlt, nicht lesbar ist oder widerspruechlich erscheint, muss der Agent anhalten und den Nutzer nach dem gueltigen Air-Gap-Pfad fragen. Es ist kein valider Arbeitsmodus, ohne zentral gelesene Regeln direkt in einem Zielrepo zu starten.