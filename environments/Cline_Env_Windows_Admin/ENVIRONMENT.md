# Umgebung: Cline_Env_Windows_Admin

| Feld | Wert |
| --- | --- |
| OS | Windows |
| Berechtigungsmodell | Admin |
| Primaerer Modus | Windows mit VS Code Cline Extension, zentrale Ablage |
| Empfohlener Ablageort | $(System.Collections.Hashtable.RecommendedPath) |
| Version | 0.4.0 |

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
## First-Read-Betrieb

Die Initialisierung installiert globale Cline-Regelstubs. Diese Stubs sind keine Provider- oder Auth-Konfiguration, sondern nur ein dauerhafter Leseanker. Sie verpflichten Cline, bei jedem Task zuerst die zentrale Umgebung zu lesen und erst danach Zielordner zu bearbeiten.