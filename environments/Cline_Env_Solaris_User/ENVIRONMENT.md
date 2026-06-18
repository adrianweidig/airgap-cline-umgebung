# Umgebung: Cline_Env_Solaris_User

| Feld | Wert |
| --- | --- |
| OS | Solaris |
| Berechtigungsmodell | User |
| Primaerer Modus | Solaris POSIX best-effort im Benutzerkontext |
| Empfohlener Ablageort | $(System.Collections.Hashtable.RecommendedPath) |
| Version | 0.3.0 |

User-Variante ohne Adminrechte. Sie schreibt nur in den gewaehlten Zentralpfad und in benutzereigene Cline-Pfade. Solaris bleibt POSIX-best-effort und setzt voraus, dass Cline, Node und Python bereits lauffaehig vorhanden sind.

## Grenzen

- Cline ist Voraussetzung und wird nicht durch diese Umgebung installiert.
- Provider-, Modell-, Auth- und KI-Serverdaten sind ausserhalb dieses Projekts.
- Der aktuelle Ordner ist AIRGAP_CLINE_HOME und bleibt Quelle der Wahrheit.
- Dauerhafte Cline-Regeln, Skills, Workflows und Helper bleiben im Zentralpfad.
- Externe Repos erhalten keine dauerhaften .cline, .clinerules, Skills, Workflows oder Helper, solange der Nutzer das nicht explizit verlangt.

## Variantenhinweise

- User-Varianten duerfen keine systemweiten Pfade oder ACLs erzwingen.
- Admin-Varianten duerfen zentrale Ablage- und Rechtevorbereitung beschreiben, aber keine Providerdaten aendern.
- Solaris ist best-effort POSIX und darf keine GNU-only-Pflicht annehmen.