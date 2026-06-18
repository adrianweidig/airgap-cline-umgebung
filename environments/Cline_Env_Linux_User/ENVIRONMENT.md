# Umgebung: Cline_Env_Linux_User

| Feld | Wert |
| --- | --- |
| OS | Linux |
| Berechtigungsmodell | User |
| Primaerer Modus | Linux Cline CLI im Benutzerkontext |
| Empfohlener Ablageort | $(System.Collections.Hashtable.RecommendedPath) |

User-Variante ohne Adminrechte fuer Home, Desktop oder Netzwerkshare. Primaer fuer Cline CLI auf Linux.

## Grenzen

- Cline muss bereits funktionsfaehig vorhanden sein.
- Keine Provider-, Modell- oder Authentifizierungsdaten werden geaendert.
- Die Umgebung ist ein zentraler Startpfad fuer Regeln, Workflows, Skills und Helper.
- Externe Repos sollen nicht mit Cline-Hilfsdateien verschmutzt werden.

## Solaris-Hinweis

Solaris-Varianten sind POSIX-best-effort. Nutze sie nur, wenn Cline, Node und die benoetigte Shell-Umgebung dort bereits lauffaehig sind.