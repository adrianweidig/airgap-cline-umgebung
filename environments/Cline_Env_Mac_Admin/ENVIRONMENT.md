# Umgebung: Cline_Env_Mac_Admin

| Feld | Wert |
| --- | --- |
| OS | Mac |
| Berechtigungsmodell | Admin |
| Primaerer Modus | macOS zentrale Ablage |
| Empfohlener Ablageort | $(System.Collections.Hashtable.RecommendedPath) |

Admin-Variante fuer zentrale Ablage auf Maschinen- oder Share-Ebene. Fuer macOS mit Cline CLI oder editornahem Cline-Betrieb.

## Grenzen

- Cline muss bereits funktionsfaehig vorhanden sein.
- Keine Provider-, Modell- oder Authentifizierungsdaten werden geaendert.
- Die Umgebung ist ein zentraler Startpfad fuer Regeln, Workflows, Skills und Helper.
- Externe Repos sollen nicht mit Cline-Hilfsdateien verschmutzt werden.

## Solaris-Hinweis

Solaris-Varianten sind POSIX-best-effort. Nutze sie nur, wenn Cline, Node und die benoetigte Shell-Umgebung dort bereits lauffaehig sind.