# Umgebung: Cline_Env_Solaris_Admin

| Feld | Wert |
| --- | --- |
| OS | Solaris |
| Berechtigungsmodell | Admin |
| Primaerer Modus | Solaris POSIX best-effort mit zentraler Ablage |
| Empfohlener Ablageort | $(System.Collections.Hashtable.RecommendedPath) |

Admin-Variante fuer zentrale Ablage auf Maschinen- oder Share-Ebene. POSIX-best-effort fuer Solaris, sofern Cline bereits lauffaehig ist.

## Grenzen

- Cline muss bereits funktionsfaehig vorhanden sein.
- Keine Provider-, Modell- oder Authentifizierungsdaten werden geaendert.
- Die Umgebung ist ein zentraler Startpfad fuer Regeln, Workflows, Skills und Helper.
- Externe Repos sollen nicht mit Cline-Hilfsdateien verschmutzt werden.

## Solaris-Hinweis

Solaris-Varianten sind POSIX-best-effort. Nutze sie nur, wenn Cline, Node und die benoetigte Shell-Umgebung dort bereits lauffaehig sind.