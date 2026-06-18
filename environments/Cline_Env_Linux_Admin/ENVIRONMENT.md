# Umgebung: Cline_Env_Linux_Admin

| Feld | Wert |
| --- | --- |
| OS | Linux |
| Berechtigungsmodell | Admin |
| Primaerer Modus | Linux Cline CLI mit zentraler Ablage |
| Empfohlener Ablageort | $(System.Collections.Hashtable.RecommendedPath) |
| Version | 0.2.0 |

Admin-Variante fuer zentrale Maschinen-, Opt- oder Share-Ablage. Sie darf optionale Rechtevorbereitung beschreiben, veraendert aber keine Cline-Provider-, Modell- oder Authentifizierungsdaten.

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