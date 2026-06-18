# Agentenanweisungen: Cline_Env_Solaris_Admin

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
- Schreibe Nutzer- und Agentendaten nur in den eigenen Ordner unter `users/solaris/`.
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

- OS: Solaris
- Variante: Admin
- Primaerer Modus: Solaris POSIX best-effort mit zentraler Ablage
- Empfohlener Ablageort: `/opt/cline-airgap/Cline_Env_Solaris_Admin`