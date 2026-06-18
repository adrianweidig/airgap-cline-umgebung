# Agentenanweisungen: Cline_Env_Mac_User

Diese Datei muss von Cline-Agenten immer gelesen werden, bevor in dieser Umgebung oder mit dieser Umgebung gearbeitet wird.

## Pflichten

- Behandle diesen Ordner als AIRGAP_CLINE_HOME.
- Lies vor Schreibarbeit ENVIRONMENT.md und alle relevanten Regeln unter shared/rules/.
- Schreibe Nutzer- und Agentendaten nur unter users/ fuer den aktuellen Nutzer.
- Pruefe OWNER.json, bevor du in existierende Nutzer- oder Agentenordner schreibst.
- Wenn OWNER.json nicht zum aktuellen Nutzer passt, schreibe nicht in diesen Ordner.
- Verwende zentrale Helper aus shared/helpers/; kopiere sie nicht in Zielrepos.
- Lege in externen Repos keine dauerhaften .cline, .clinerules, Skills, Workflows oder Helper an, ausser der Nutzer verlangt es ausdruecklich.
- Veraendere keine Provider-, Modell-, Auth- oder KI-Server-Konfiguration.

## Plattform

- OS: Mac
- Variante: User
- Primaerer Modus: macOS Cline CLI oder Editor-Integration