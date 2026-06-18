# Air-Gap-Cline-Umgebung

Dieses Repo stellt exportierbare Startumgebungen fuer Cline bereit. Cline selbst muss bereits installiert, eingerichtet und mit dem gewuenschten KI-Server verbunden sein. Dieses Projekt veraendert keine Provider-, Modell- oder Authentifizierungsdaten.

## Schnellwahl

| Umgebung | Zweck |
| --- | --- |
| Cline_Env_Windows_User | Windows-Nutzer ohne Adminrechte, primaer VS Code Cline Extension |
| Cline_Env_Windows_Admin | Windows-Admin fuer zentrale Ablage auf Maschine oder Share |
| Cline_Env_Linux_User | Linux-Nutzer mit Cline CLI |
| Cline_Env_Linux_Admin | Linux-Admin fuer /opt oder zentrale Shares |
| Cline_Env_Mac_User | macOS-Nutzer mit Cline CLI oder Editor-Integration |
| Cline_Env_Mac_Admin | macOS-Admin fuer /Users/Shared oder /opt |
| Cline_Env_Solaris_User | Solaris/POSIX best-effort im Nutzerkontext |
| Cline_Env_Solaris_Admin | Solaris/POSIX best-effort fuer zentrale Ablage |

## Nutzung

1. Passenden Ordner aus environments/ oder aus einem Release-Paket entpacken.
2. Cline starten.
3. Cline anweisen:

`	ext
Initialisiere dich ueber folgenden Pfad: <vollstaendiger Pfad zum Cline_Env_... Ordner>
`

4. Cline liest im Umgebungsordner zuerst START_HIER.md, dann AGENTS.md, dann ENVIRONMENT.md.

## Wichtig

- Ziel ist eine zentrale, wiederverwendbare Air-Gap-Ausgangsumgebung.
- Regeln, Workflows, Skills und Helper bleiben im zentralen Umgebungsordner.
- Externe Repos werden nicht mit Cline-Regeln, Workflows oder Helper-Dateien verschmutzt, ausser der Nutzer verlangt es ausdruecklich.
- Nutzer- und Agentenordner werden ueber OWNER.json und Pflichtregeln getrennt.
- Release-Pakete enthalten keine Cline-Installer, keine KI-Modelle und keine Drittanbieter-Binaries.

## Release-Artefakte

Pro Version werden .7z- und .zip-Pakete pro Umgebung sowie Gesamtpakete erzeugt. Die Skripte liegen unter scripts/.