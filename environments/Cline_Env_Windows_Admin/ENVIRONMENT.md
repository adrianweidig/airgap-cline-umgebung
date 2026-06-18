# Umgebung: Cline_Env_Windows_Admin

| Feld | Wert |
| --- | --- |
| OS | Windows |
| Berechtigungsmodell | Admin |
| Primaerer Modus | Windows mit VS Code Cline Extension, zentrale Ablage |
| Empfohlener Ablageort | $(System.Collections.Hashtable.RecommendedPath) |

Admin-Variante fuer zentrale Ablage auf Maschinen- oder Share-Ebene. Primaer fuer VS Code mit installierter Cline Extension.

## Grenzen

- Cline muss bereits funktionsfaehig vorhanden sein.
- Keine Provider-, Modell- oder Authentifizierungsdaten werden geaendert.
- Die Umgebung ist ein zentraler Startpfad fuer Regeln, Workflows, Skills und Helper.
- Externe Repos sollen nicht mit Cline-Hilfsdateien verschmutzt werden.

## Solaris-Hinweis

Solaris-Varianten sind POSIX-best-effort. Nutze sie nur, wenn Cline, Node und die benoetigte Shell-Umgebung dort bereits lauffaehig sind.