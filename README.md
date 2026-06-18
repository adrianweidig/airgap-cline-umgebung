# Air-Gap-Cline-Umgebung

Exportierbare Startumgebungen fuer Cline in abgeschotteten oder kontrollierten Umgebungen.

Dieses Repo liefert **keinen Cline-Installer**, keine Provider-Konfiguration, keine Modellserver-Konfiguration und keine Auth-Daten. Es setzt voraus, dass Cline bereits funktioniert, zum Beispiel als VS Code Extension unter Windows oder als CLI auf Linux/macOS/POSIX. Dieses Repo liefert den zentralen Pfad, aus dem Cline dauerhaft Regeln, Workflows, Skills, Helper und Memory-Strukturen lesen soll.

Aktuelle Version: `v0.4.0`

## Was Ist Das?

Eine `Cline_Env_*`-Umgebung ist ein Ordner, den man an einen stabilen Ort legt, zum Beispiel auf `C:\Cline_AirGap\`, einen Netzwerkshare, `/opt/cline-airgap/` oder in ein Home-Verzeichnis. Danach bekommt Cline einmalig den Pfad zu diesem Ordner und initialisiert sich daraus.

Nach der Initialisierung schreibt die Umgebung globale Cline-Stubs. Diese Stubs verweisen auf den zentralen Pfad (`AIRGAP_CLINE_HOME`) und sorgen dafuer, dass Cline vor jeder Aufgabe zuerst wieder in diese Umgebung schaut.

Das Ziel ist: Cline arbeitet in beliebigen Zielordnern, Repos oder Netzwerkshares, aber seine Regeln, Workflows, Helper, Agentenstatus und Memory bleiben zentral im Air-Gap-Pfad.

## Schnellstart

1. Auf der [Release-Seite](https://github.com/adrianweidig/airgap-cline-umgebung/releases) das passende Paket herunterladen.
2. Paket entpacken, zum Beispiel:
   - Windows User: `C:\Cline_AirGap\Cline_Env_Windows_User`
   - Windows Admin/Share: `\\server\share\Cline_AirGap\Cline_Env_Windows_Admin`
   - Linux Admin: `/opt/cline-airgap/Cline_Env_Linux_Admin`
   - Linux User: `~/cline-airgap/Cline_Env_Linux_User`
3. Cline starten.
4. Cline einmalig anweisen:

```text
Initialisiere dich ueber folgenden Pfad: <vollstaendiger Pfad zum Cline_Env_... Ordner>
```

Beispiel Windows:

```text
Initialisiere dich ueber folgenden Pfad: C:\Cline_AirGap\Cline_Env_Windows_User
```

Beispiel Linux:

```text
Initialisiere dich ueber folgenden Pfad: /opt/cline-airgap/Cline_Env_Linux_Admin
```

5. Cline liest `START_HIER.md` im gewaehlten Ordner und fuehrt das passende Initialisierungsskript aus oder beschreibt die manuelle Ausfuehrung.
6. Fuer eine Vorschau kann das Initialisierungsskript mit `--dry-run` laufen.

Wichtig: Nicht den Repo-Root als Cline-Startumgebung verwenden. Immer einen konkreten Ordner wie `Cline_Env_Windows_User` verwenden.

## Welche Umgebung Waehlen?

| Wenn du... | Nimm dieses Paket |
| --- | --- |
| Windows nutzt, keine Adminrechte brauchst und Cline in VS Code verwendest | `Cline_Env_Windows_User` |
| Windows zentral fuer mehrere Nutzer oder auf einem Share vorbereitest | `Cline_Env_Windows_Admin` |
| Linux im Benutzerkontext mit Cline CLI nutzt | `Cline_Env_Linux_User` |
| Linux zentral unter `/opt` oder auf einem Share bereitstellst | `Cline_Env_Linux_Admin` |
| macOS im Benutzerkontext nutzt | `Cline_Env_Mac_User` |
| macOS zentral unter `/Users/Shared` oder `/opt` bereitstellst | `Cline_Env_Mac_Admin` |
| Solaris/POSIX best-effort ohne Adminrechte nutzt | `Cline_Env_Solaris_User` |
| Solaris/POSIX best-effort zentral bereitstellst | `Cline_Env_Solaris_Admin` |

Windows mit VS Code Cline Extension ist das Primaerziel. Linux, macOS und Solaris sind CLI-/POSIX-orientierte Varianten. Solaris ist ausdruecklich best-effort und setzt voraus, dass Cline dort bereits lauffaehig ist.

## Was Nach Der Initialisierung Passiert

Die Initialisierung:

- validiert den gewaehlten `Cline_Env_*`-Ordner,
- erzeugt einen eigenen Nutzer- und Agentenordner unter `users/`,
- schreibt globale Cline-Regelstubs in benutzereigene Cline-Pfade,
- synchronisiert zentrale Workflows und Skills,
- schreibt Statusdaten unter `state/`,
- veraendert keine Provider-, Modell-, Auth- oder KI-Serverdaten.

Der wichtigste Mechanismus ab `v0.4.0` ist der **First-Read-Vertrag**:

1. Cline liest vor jeder Aufgabe den globalen Air-Gap-Stub.
2. Cline loest daraus `AIRGAP_CLINE_HOME` auf.
3. Cline liest zuerst `bootstrap/FIRST_READ.md`.
4. Danach liest Cline `AGENTS.md`, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION` und `shared/rules/*.md`.
5. Erst danach darf Cline Zielworkspaces, externe Repos, Memory, Workflows, Skills oder Helper verwenden.

Wenn der zentrale Pfad fehlt, nicht lesbar ist oder mehrere Stubs widerspruechliche Pfade nennen, muss Cline anhalten und den Nutzer nach dem gueltigen Air-Gap-Pfad fragen.

## Arbeiten In Externen Repos

Cline darf in Zielrepos fachliche Aenderungen machen, wenn die Nutzeraufgabe das verlangt. Die Air-Gap-Cline-Infrastruktur bleibt aber zentral:

- Keine dauerhaften `.cline`, `.clinerules`, Skills, Workflows, Helper oder Memory-Dateien im Zielrepo.
- Workspace-Metadaten liegen unter `workspaces/<hash>/`.
- Helper-Ausgaben liegen unter `workspaces/<hash>/helper-output/`.
- Geteilte Memory liegt unter `workspaces/<hash>/memory/`.
- Private Nutzer- und Agentendaten liegen unter `users/<plattform>/<owner>/`.

Ausnahmen sind nur erlaubt, wenn der Nutzer sie ausdruecklich verlangt.

## Koordiniertes Memory

Ab `v0.3.0` enthaelt jede Umgebung ein koordiniertes Memory-Modell:

- `MEMORY.json` ist die kanonische maschinenlesbare Wahrheit.
- `MEMORY.md` ist die kurze, deterministische Lesefassung fuer Cline und andere KI-Agenten.
- Neue dauerhafte Erkenntnisse werden zuerst als Vorschlag abgelegt.
- Geteilte Memory wird ueber `shared/helpers/python/memory_update.py` oder Wrapper aktualisiert.
- Runtime-Memory bleibt aus dem Git-Verlauf ausgeschlossen.

Details: [`docs/MEMORY-MODELL.md`](docs/MEMORY-MODELL.md)

## Ordnerstruktur Einer Umgebung

Jeder exportierbare `Cline_Env_*`-Ordner ist fuer sich nutzbar und enthaelt unter anderem:

```text
Cline_Env_.../
  START_HIER.md
  AGENTS.md
  ENVIRONMENT.md
  MANIFEST.json
  VERSION
  bootstrap/
    FIRST_READ.md
    00-airgap-zentralumgebung.md
  shared/
    rules/
    workflows/
    skills/
    helpers/
    memory/
  scripts/
  users/
  workspaces/
  state/
  logs/
  audit/
```

Die leeren Runtime-Ordner sind sichtbar, ihre Inhalte bleiben lokal und werden nicht eingecheckt.

## Release-Artefakte

Jede Version enthaelt:

- acht `.7z`-Pakete, eines pro Umgebung,
- acht `.zip`-Pakete, eines pro Umgebung,
- ein Gesamtpaket `.7z`,
- ein Gesamtpaket `.zip`,
- `SHA256SUMS.txt`,
- `RELEASE_MANIFEST.json`,
- `RELEASE_NOTES_DE.md`.

Namensbeispiel:

```text
Cline_Env_Windows_User_v0.4.0_2026-06-18.7z
Cline_Env_Windows_User_v0.4.0_2026-06-18.zip
```

## Was Nicht Enthalten Ist

Dieses Repo enthaelt bewusst nicht:

- Cline-Installer,
- VSIX-Dateien,
- Drittanbieter-Binaries,
- KI-Modelle oder Modellgewichte,
- Provider-Konfiguration,
- API-Keys, Tokens oder Auth-Daten,
- Container Images.

Die Release-Pakete sind Startumgebungen, keine Komplettinstaller.

## Entwicklung Und Pruefung

Wichtige Skripte:

```powershell
.\scripts\Sync-EnvironmentTemplates.ps1
.\scripts\Test-AllEnvironmentPackages.ps1
.\scripts\Build-AllEnvironmentPackages.ps1 -Version 0.4.0
```

Die Tests pruefen unter anderem:

- alle acht Umgebungen sind vollstaendig,
- First-Read-Vertrag ist vorhanden,
- Memory-Struktur ist vorhanden,
- keine Abhaengigkeit von Entwicklungsquellen wie `src/common`,
- keine verbotenen Binaries oder Archive in den Umgebungen,
- PowerShell-, Python- und POSIX-Syntax,
- Paketbau und Archivpruefung.

## Weitere Dokumente

- [`START_HIER.md`](START_HIER.md): Einstieg fuer Repo-Betrachter.
- [`ARCHITEKTUR.md`](ARCHITEKTUR.md): Architektur und zentrale Pfadlogik.
- [`docs/MEMORY-MODELL.md`](docs/MEMORY-MODELL.md): Memory-Format und Schreibregeln.
- [`SECURITY.md`](SECURITY.md): Sicherheitsmeldungen.
- [`CONTRIBUTING.md`](CONTRIBUTING.md): Mitarbeit.
