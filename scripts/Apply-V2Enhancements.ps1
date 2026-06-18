[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$Version = "0.2.0"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = Split-Path -Parent $ScriptDir
}
$RepoRoot = [System.IO.Path]::GetFullPath($RootPath)

function Write-TextFile {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $target = Join-Path $RepoRoot $RelativePath
    $parent = Split-Path -Parent $target
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($target, $Content.TrimStart("`r", "`n"), $utf8NoBom)
}

function Ensure-Directory {
    param([Parameter(Mandatory = $true)][string]$RelativePath)
    $target = Join-Path $RepoRoot $RelativePath
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    $gitkeep = Join-Path $target ".gitkeep"
    if (-not (Test-Path -LiteralPath $gitkeep)) {
        [System.IO.File]::WriteAllText($gitkeep, "", (New-Object System.Text.UTF8Encoding($false)))
    }
}

function ConvertTo-JsonText {
    param([Parameter(Mandatory = $true)]$Object)
    return ($Object | ConvertTo-Json -Depth 30)
}

$Environments = @(
    @{ Name = "Cline_Env_Windows_User"; Os = "Windows"; Role = "User"; Family = "windows"; Primary = "Windows mit VS Code Cline Extension"; RecommendedPath = "C:\Cline_AirGap\Cline_Env_Windows_User oder Netzwerkshare" },
    @{ Name = "Cline_Env_Windows_Admin"; Os = "Windows"; Role = "Admin"; Family = "windows"; Primary = "Windows mit VS Code Cline Extension, zentrale Ablage"; RecommendedPath = "C:\Cline_AirGap\Cline_Env_Windows_Admin oder zentraler Netzwerkshare" },
    @{ Name = "Cline_Env_Linux_User"; Os = "Linux"; Role = "User"; Family = "linux"; Primary = "Linux Cline CLI im Benutzerkontext"; RecommendedPath = "~/cline-airgap/Cline_Env_Linux_User" },
    @{ Name = "Cline_Env_Linux_Admin"; Os = "Linux"; Role = "Admin"; Family = "linux"; Primary = "Linux Cline CLI mit zentraler Ablage"; RecommendedPath = "/opt/cline-airgap/Cline_Env_Linux_Admin" },
    @{ Name = "Cline_Env_Mac_User"; Os = "Mac"; Role = "User"; Family = "mac"; Primary = "macOS Cline CLI oder Editor-Integration"; RecommendedPath = "~/cline-airgap/Cline_Env_Mac_User" },
    @{ Name = "Cline_Env_Mac_Admin"; Os = "Mac"; Role = "Admin"; Family = "mac"; Primary = "macOS zentrale Ablage"; RecommendedPath = "/Users/Shared/Cline_AirGap/Cline_Env_Mac_Admin oder /opt/cline-airgap/Cline_Env_Mac_Admin" },
    @{ Name = "Cline_Env_Solaris_User"; Os = "Solaris"; Role = "User"; Family = "solaris"; Primary = "Solaris POSIX best-effort im Benutzerkontext"; RecommendedPath = "~/cline-airgap/Cline_Env_Solaris_User" },
    @{ Name = "Cline_Env_Solaris_Admin"; Os = "Solaris"; Role = "Admin"; Family = "solaris"; Primary = "Solaris POSIX best-effort mit zentraler Ablage"; RecommendedPath = "/opt/cline-airgap/Cline_Env_Solaris_Admin" }
)

$RuleNames = @(
    "00-airgap-grundsaetze.md",
    "05-plattform-und-variante.md",
    "10-zentralpfad-ist-quell-der-wahrheit.md",
    "20-nutzer-und-agententrennung.md",
    "30-keine-repo-verschmutzung.md",
    "40-zentrale-helper-nutzen.md",
    "50-verifikation-und-dokumentation.md"
)

$WorkflowNames = @(
    "00-initialisierung.md",
    "01-zentralstubs-synchronisieren.md",
    "02-nutzerordner-anlegen.md",
    "10-externer-arbeitsordner-registrieren.md",
    "20-klassische-aufgabe-bearbeiten.md",
    "30-helper-script-nutzen.md",
    "40-airgap-abnahme.md",
    "90-selbstverbesserung.md"
)

$SkillDescriptions = [ordered]@{
    "airgap-bootstrap" = "Initialisiert eine bestehende Cline-Installation anhand eines exportierten Air-Gap-Zentralpfads."
    "plattform-variante" = "Waehlt OS- und User/Admin-spezifische Pfade, Skripte und Grenzen ohne Provider-Konfiguration."
    "nutzer-agenten-schutz" = "Prueft OWNER.json und schuetzt fremde Nutzer- und Agentenordner vor Schreibzugriffen."
    "externer-arbeitsordner" = "Registriert Zielrepos, Desktop-Ordner oder Shares zentral unter workspaces ohne Repo-Verschmutzung."
    "zentrale-helper" = "Findet und nutzt zentrale Helper-Skripte und schreibt deren Ausgaben in zentrale Workspace-Metadaten."
    "airgap-validierung" = "Prueft lokale Artefakte, Air-Gap-Annahmen, Abschlusschecks und Dokumentation."
}

function Get-VariantDescription {
    param($Env)
    if ($Env.Role -eq "Admin") {
        $role = "Admin-Variante fuer zentrale Maschinen-, Opt- oder Share-Ablage. Sie darf optionale Rechtevorbereitung beschreiben, veraendert aber keine Cline-Provider-, Modell- oder Authentifizierungsdaten."
    } else {
        $role = "User-Variante ohne Adminrechte. Sie schreibt nur in den gewaehlten Zentralpfad und in benutzereigene Cline-Pfade."
    }

    if ($Env.Os -eq "Solaris") {
        return "$role Solaris bleibt POSIX-best-effort und setzt voraus, dass Cline, Node und Python bereits lauffaehig vorhanden sind."
    }
    return $role
}

function Get-StartText {
    param($Env)
    $scriptHint = if ($Env.Os -eq "Windows") { ".\scripts\Initialize-AirgapClineEnvironment.ps1" } else { "sh ./scripts/initialize-airgap-cline-environment.sh" }
    $template = @'
# Start Hier: __ENV_NAME__

Diese Umgebung ist eine direkt exportierbare Air-Gap-Cline-Ausgangsumgebung. Cline selbst muss bereits installiert, eingerichtet und mit dem vorgesehenen KI-Server verbunden sein.

## Erstauftrag an Cline

Gib Cline den vollstaendigen Pfad zu diesem Ordner:

```text
Initialisiere dich ueber folgenden Pfad: <vollstaendiger Pfad zu diesem Cline_Env_... Ordner>
```

Cline muss danach in dieser Reihenfolge lesen:

1. `START_HIER.md`
2. `AGENTS.md`
3. `ENVIRONMENT.md`
4. alle Dateien unter `shared/rules/`
5. den passenden Workflow unter `shared/workflows/`

## Setup-Skript

Vorgesehen fuer diese Variante:

```text
__SCRIPT_HINT__
```

Fuer eine Vorschau ohne Schreibzugriff:

```text
__SCRIPT_HINT__ --dry-run
```

Das Skript validiert den Zentralpfad, erzeugt einen eigenen Nutzer-/Agentenordner, synchronisiert globale Cline-Stubs und schreibt `state/bootstrap-status.json`. Es veraendert keine Provider-, Modell-, Auth- oder KI-Server-Konfiguration.

## Wichtige Cline-Pfade

- Globale Regeln: `~/.cline/rules` und kompatibel `Documents/Cline/Rules`.
- Globale Workflows: `~/.cline/data/workflows`.
- Globale Skills: `~/.cline/skills`.
- Projektbezogene Cline-Dateien werden in externen Zielrepos nicht angelegt, ausser der Nutzer fordert das ausdruecklich.
'@
    return $template.Replace("__ENV_NAME__", $Env.Name).Replace("__SCRIPT_HINT__", $scriptHint)
}

function Get-EnvironmentText {
    param($Env)
    return @"
# Umgebung: $($Env.Name)

| Feld | Wert |
| --- | --- |
| OS | $($Env.Os) |
| Berechtigungsmodell | $($Env.Role) |
| Primaerer Modus | $($Env.Primary) |
| Empfohlener Ablageort | `$($Env.RecommendedPath)` |
| Version | $Version |

$(Get-VariantDescription -Env $Env)

## Grenzen

- Cline ist Voraussetzung und wird nicht durch diese Umgebung installiert.
- Provider-, Modell-, Auth- und KI-Serverdaten sind ausserhalb dieses Projekts.
- Der aktuelle Ordner ist `AIRGAP_CLINE_HOME` und bleibt Quelle der Wahrheit.
- Dauerhafte Cline-Regeln, Skills, Workflows und Helper bleiben im Zentralpfad.
- Externe Repos erhalten keine dauerhaften `.cline`, `.clinerules`, Skills, Workflows oder Helper, solange der Nutzer das nicht explizit verlangt.

## Variantenhinweise

- User-Varianten duerfen keine systemweiten Pfade oder ACLs erzwingen.
- Admin-Varianten duerfen zentrale Ablage- und Rechtevorbereitung beschreiben, aber keine Providerdaten aendern.
- Solaris ist best-effort POSIX und darf keine GNU-only-Pflicht annehmen.
"@
}

function Get-AgentsText {
    param($Env)
    return @"
# Agentenanweisungen: $($Env.Name)

Diese Datei ist Pflichtkontext. Lies sie vor jeder Aufgabe, die mit dieser Umgebung oder aus dieser Umgebung heraus arbeitet.

## Lesereihenfolge

1. `START_HIER.md`
2. `AGENTS.md`
3. `ENVIRONMENT.md`
4. `shared/rules/*.md`
5. passender Workflow aus `shared/workflows/`
6. bei Bedarf passender Skill aus `shared/skills/*/SKILL.md`

## Harte Regeln

- Behandle diesen Ordner als `AIRGAP_CLINE_HOME`.
- Veraendere keine Provider-, Modell-, Auth- oder KI-Server-Konfiguration.
- Nutze zentrale Helper unter `shared/helpers/`; kopiere sie nicht in Zielrepos.
- Schreibe Nutzer- und Agentendaten nur in den eigenen Ordner unter ``users/$($Env.Family)/``.
- Pruefe `OWNER.json`, bevor du in einen vorhandenen Nutzer- oder Agentenordner schreibst.
- Wenn `OWNER.json` nicht zum aktuellen Nutzer passt, darfst du dort nicht schreiben.
- Registriere externe Arbeitsordner unter `workspaces/<hash>/`.
- Schreibe Helper-Ausgaben nach `workspaces/<hash>/helper-output/`.
- Lege in externen Repos keine dauerhaften `.cline`, `.clinerules`, Skills, Workflows oder Helper an, ausser der Nutzer fordert das ausdruecklich.

## Arbeitsablauf fuer normale Tasks

1. Ziel und Arbeitsordner klaeren.
2. Externen Arbeitsordner zentral registrieren, falls ausserhalb von `AIRGAP_CLINE_HOME` gearbeitet wird.
3. Owner-Guard ausfuehren, bevor in ``users/`` geschrieben wird.
4. Zentrale Regeln, Workflows, Skills und Helper nutzen.
5. Fachliche Aenderungen nur im Zielrepo vornehmen, wenn sie zur Nutzeraufgabe gehoeren.
6. Checks ausfuehren oder klar dokumentieren, warum sie nicht moeglich waren.
7. Ergebnis im eigenen Agentenordner oder im passenden `workspaces/<hash>/` dokumentieren.

## Plattform

- OS: $($Env.Os)
- Variante: $($Env.Role)
- Primaerer Modus: $($Env.Primary)
- Empfohlener Ablageort: ``$($Env.RecommendedPath)``
"@
}

function Get-Rules {
    param($Env)
    $rules = [ordered]@{}
    $rules["00-airgap-grundsaetze.md"] = @'
<!-- AIRGAP-CLINE-MANAGED:v2 -->
# Air-Gap-Grundsaetze

- Gehe davon aus, dass die Zielumgebung keinen Internetzugriff hat.
- Starte keine Downloads, Marketplace-Installationen oder Cloud-Abfragen.
- Verwende keine geratenen Ersatzartefakte. Wenn etwas fehlt, melde den exakten Dateinamen, Pfad und Zweck.
- Cline ist bereits funktionsfaehig eingerichtet; Provider, Modelle, Auth und KI-Server werden durch diese Umgebung nicht geaendert.
- Jede Automatisierung muss lokal nachvollziehbar sein und darf keine fremden Installer, Modelle oder VSIX-Dateien erwarten.
'@
    $rules["05-plattform-und-variante.md"] = @"
<!-- AIRGAP-CLINE-MANAGED:v2 -->
# Plattform Und Variante

- Umgebung: $($Env.Name)
- OS: $($Env.Os)
- Rolle: $($Env.Role)
- Primaerer Modus: $($Env.Primary)
- Empfohlener Ablageort: ``$($Env.RecommendedPath)``

Nutze nur Skripte und Pfade, die zu dieser Variante passen. Windows ist primaer fuer VS Code Cline Extension vorgesehen. Linux, macOS und Solaris sind CLI-/POSIX-orientiert. Solaris bleibt best-effort.
"@
    $rules["10-zentralpfad-ist-quell-der-wahrheit.md"] = @'
<!-- AIRGAP-CLINE-MANAGED:v2 -->
# Zentralpfad Ist Quelle Der Wahrheit

- Der aktuelle `Cline_Env_*`-Ordner ist `AIRGAP_CLINE_HOME`.
- Regeln, Workflows, Skills, Helper, Nutzerstatus und Workspace-Metadaten liegen zentral in diesem Pfad.
- Globale Cline-Stubs duerfen nur einen stabilen Verweis auf diesen Zentralpfad enthalten.
- Wenn in externen Repos gearbeitet wird, bleiben Cline-Hilfsdateien im Zentralpfad.
- Zielrepos erhalten nur fachliche Aenderungen, die direkt zur Nutzeraufgabe gehoeren.
'@
    $rules["20-nutzer-und-agententrennung.md"] = @'
<!-- AIRGAP-CLINE-MANAGED:v2 -->
# Nutzer- Und Agententrennung

- Vor Schreibarbeit in `users/` muss `OWNER.json` geprueft werden.
- Wenn Owner-Daten nicht zum aktuellen Nutzer passen, ist Schreiben verboten.
- Jeder Task-Agent arbeitet in einem eigenen Agentenordner.
- Fremde Agentenordner duerfen nur gelesen werden, wenn der Mensch dies explizit verlangt.
- Nutze `shared/helpers/python/guard_owner.py` oder den plattformspezifischen Wrapper, wenn ein Schreibziel unter `users/` liegt.
'@
    $rules["30-keine-repo-verschmutzung.md"] = @'
<!-- AIRGAP-CLINE-MANAGED:v2 -->
# Keine Repo-Verschmutzung

- Lege keine dauerhaften `.cline`, `.clinerules`, Skills, Workflows oder Helper in Zielrepos an.
- Zentrale Metadaten zu Zielrepos gehoeren nach `workspaces/<hash>/`.
- Helper-Ausgaben gehoeren nach `workspaces/<hash>/helper-output/`.
- Fachliche Projektdateien duerfen geaendert werden, wenn die Nutzeraufgabe es verlangt.
- Ausnahmen muessen vom Nutzer ausdruecklich beauftragt werden.
'@
    $rules["40-zentrale-helper-nutzen.md"] = @'
<!-- AIRGAP-CLINE-MANAGED:v2 -->
# Zentrale Helper Nutzen

- Suche Helper zuerst unter `shared/helpers/python/`, `shared/helpers/powershell/`, `shared/helpers/bash/` und `shared/helpers/posix/`.
- Fuehre Helper aus dem Zentralpfad aus.
- Schreibe Ausgaben in den zentralen Workspace-Metadatenordner.
- Lege neue dauerhafte Helper nur im Zentralpfad an, nicht im Zielrepo.
- Wenn ein Helper fehlt oder nicht passt, dokumentiere die Luecke und frage bei dauerhaftem Ausbau nach Zustimmung.
'@
    $rules["50-verifikation-und-dokumentation.md"] = @'
<!-- AIRGAP-CLINE-MANAGED:v2 -->
# Verifikation Und Dokumentation

- Melde Arbeit erst als fertig, wenn passende Checks ausgefuehrt wurden oder nachvollziehbar begruendet ist, warum sie nicht moeglich waren.
- Dokumentiere zentrale Entscheidungen in deutschen Markdown-Dateien.
- Schreibe Abschlussstatus in den eigenen Agentenordner oder in den passenden Workspace-Metadatenordner.
- Halte fest, wenn ein Ergebnis von fehlenden lokalen Artefakten, fehlenden Rechten oder fehlenden Tools begrenzt ist.
'@
    return $rules
}

function Get-Workflows {
    $workflows = [ordered]@{}
    $workflows["00-initialisierung.md"] = @'
<!-- AIRGAP-CLINE-MANAGED:v2 -->
# Initialisierung

1. Lies `START_HIER.md`, `AGENTS.md` und `ENVIRONMENT.md`.
2. Validiere den Zentralpfad anhand von `MANIFEST.json`, `VERSION`, `shared/` und `scripts/`.
3. Fuehre das passende Initialisierungsskript aus, bevorzugt erst mit `--dry-run`.
4. Erzeuge den eigenen Nutzer-/Agentenordner.
5. Synchronisiere globale Stubs, Workflows und Skills.
6. Pruefe `state/bootstrap-status.json`.
7. Bestaetige, dass Provider-, Modell-, Auth- und KI-Serverkonfiguration nicht geaendert wurden.
'@
    $workflows["01-zentralstubs-synchronisieren.md"] = @'
<!-- AIRGAP-CLINE-MANAGED:v2 -->
# Zentralstubs Synchronisieren

1. Bestimme `AIRGAP_CLINE_HOME`.
2. Schreibe nur markierte Air-Gap-Stubs direkt neu.
3. Wenn eine bestehende Zieldatei nicht als Air-Gap-managed markiert ist, erst Backup mit Zeitstempel anlegen.
4. Synchronisiere Workflows nach `~/.cline/data/workflows`.
5. Synchronisiere Skills nach `~/.cline/skills`.
6. Windows zusaetzlich mit `Documents/Cline/Rules` kompatibel halten.
7. Ergebnis in `state/last-stub-sync.json` dokumentieren.
'@
    $workflows["02-nutzerordner-anlegen.md"] = @'
<!-- AIRGAP-CLINE-MANAGED:v2 -->
# Nutzerordner Anlegen

1. Erkenne Nutzer, Host, OS und Variante.
2. Erzeuge den passenden Ordner unter `users/<plattform>/<nutzer>/`.
3. Wenn `OWNER.json` existiert, pruefe Owner vor jedem Schreibzugriff.
4. Schreibe oder aktualisiere `OWNER.json` mit Schema-Version.
5. Erzeuge einen neuen Agentenordner mit `AGENT_POLICY.md`, `CURRENT_TASK.md` und `WORKSPACE_BINDINGS.json`.
'@
    $workflows["10-externer-arbeitsordner-registrieren.md"] = @'
<!-- AIRGAP-CLINE-MANAGED:v2 -->
# Externen Arbeitsordner Registrieren

1. Nimm Zielpfad und optionalen Alias entgegen.
2. Normalisiere den Pfad plattformspezifisch.
3. Hashe den normalisierten Pfad.
4. Erzeuge oder aktualisiere `workspaces/<hash>/WORKSPACE.json`.
5. Wenn derselbe Hash auf einen anderen Pfad zeigt, brich wegen Kollision ab.
6. Schreibe `NOTIZEN.md`, `RULE_OVERRIDES.md` und `helper-output/`.
'@
    $workflows["20-klassische-aufgabe-bearbeiten.md"] = @'
<!-- AIRGAP-CLINE-MANAGED:v2 -->
# Klassische Aufgabe Bearbeiten

1. Ziel, Arbeitsordner und Erfolgskriterien klaeren.
2. Externen Arbeitsordner zentral registrieren.
3. Relevante Regeln, Workflows und Skills aus dem Zentralpfad laden.
4. Keine dauerhaften Cline-Hilfsdateien im Zielrepo anlegen.
5. Fachliche Aenderungen gezielt im Zielrepo vornehmen.
6. Passende Checks ausfuehren.
7. Ergebnis zentral dokumentieren.
'@
    $workflows["30-helper-script-nutzen.md"] = @'
<!-- AIRGAP-CLINE-MANAGED:v2 -->
# Helper-Script Nutzen

1. Helper zuerst unter `shared/helpers/` suchen.
2. Zielworkspace zentral registrieren.
3. Helper aus dem Zentralpfad ausfuehren.
4. Ausgabe nach `workspaces/<hash>/helper-output/` schreiben.
5. Helper nicht in das Zielrepo kopieren.
'@
    $workflows["40-airgap-abnahme.md"] = @'
<!-- AIRGAP-CLINE-MANAGED:v2 -->
# Air-Gap-Abnahme

1. Pruefe, ob alle benoetigten Dateien lokal vorhanden sind.
2. Suche nach Internet-, Download-, Marketplace- oder Provider-Annahmen.
3. Pruefe, ob Zielrepos frei von dauerhaften Cline-Hilfsdateien geblieben sind.
4. Pruefe Owner-Schutz, wenn `users/` betroffen war.
5. Dokumentiere den Abnahmestatus.
'@
    $workflows["90-selbstverbesserung.md"] = @'
<!-- AIRGAP-CLINE-MANAGED:v2 -->
# Selbstverbesserung

1. Sammle wiederkehrende Probleme.
2. Schlage Verbesserungen an Regeln, Workflows, Skills oder Helpern vor.
3. Aendere zentrale Vorgaben nur nach expliziter Zustimmung des Nutzers.
4. Halte jede Aenderung deutsch, air-gap-faehig und provider-neutral.
'@
    return $workflows
}

function Get-SkillText {
    param([string]$Name, [string]$Description)
    return @"
<!-- AIRGAP-CLINE-MANAGED:v2 -->
---
name: $Name
description: $Description
---

# $Name

## Wann verwenden

Verwende diesen Skill, wenn die Nutzeraufgabe zu dieser Beschreibung passt: $Description

## Vorgehen

1. Bestimme `AIRGAP_CLINE_HOME`.
2. Lies `AGENTS.md`, `ENVIRONMENT.md` und die relevanten Regeln.
3. Verwende zentrale Helper und zentrale Workspace-Metadaten.
4. Schreibe nicht in fremde Nutzer-/Agentenordner.
5. Veraendere keine Provider-, Modell-, Auth- oder KI-Serverdaten.

## Ergebnis

Dokumentiere Ergebnis, Checks und offene Punkte im eigenen Agentenordner oder im passenden `workspaces/<hash>/`-Ordner.
"@
}

function Get-PlatformSkillText {
    param($Env)
    $skillName = switch ($Env.Os) {
        "Windows" { "windows-vscode-cline" }
        "Linux" { "linux-cli-cline" }
        "Mac" { "mac-cline" }
        "Solaris" { "solaris-posix-cline" }
    }
    return @{
        Name = $skillName
        Text = @"
<!-- AIRGAP-CLINE-MANAGED:v2 -->
---
name: $skillName
description: Plattformskill fuer $($Env.Name) mit Fokus auf $($Env.Primary).
---

# $skillName

## Plattformregeln

- Umgebung: $($Env.Name)
- OS: $($Env.Os)
- Berechtigungsmodell: $($Env.Role)
- Primaerer Modus: $($Env.Primary)
- Empfohlener Ablageort: ``$($Env.RecommendedPath)``

Nutze die Skripte unter `scripts/` dieser Umgebung. Cline muss bereits eingerichtet sein. Diese Umgebung veraendert keine Provider-, Modell- oder Authentifizierungsdaten.
"@
    }
}

function Get-PythonRegisterWorkspace {
    return @'
#!/usr/bin/env python3
"""Registriert externe Arbeitsordner zentral unter workspaces/<hash>."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import platform
from datetime import datetime, timezone
from pathlib import Path

SCHEMA_VERSION = 1


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def current_user() -> str:
    return os.environ.get("USERNAME") or os.environ.get("USER") or "unknown"


def normalized_path(path: Path) -> str:
    text = str(path.resolve(strict=False))
    return os.path.normcase(text) if os.name == "nt" else text


def write_text(path: Path, text: str) -> None:
    path.write_text(text, encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description="Externen Arbeitsordner zentral registrieren")
    parser.add_argument("--root", required=True, help="AIRGAP_CLINE_HOME")
    parser.add_argument("--target", required=True, help="Externer Arbeitsordner")
    parser.add_argument("--alias", default="", help="Optionaler Anzeigename")
    parser.add_argument("--dry-run", action="store_true", help="Nur geplante Aenderungen ausgeben")
    args = parser.parse_args()

    root = Path(args.root).resolve(strict=False)
    target = Path(args.target).resolve(strict=False)
    if not root.exists():
        raise SystemExit(f"AIRGAP_CLINE_HOME existiert nicht: {root}")
    if not target.exists() or not target.is_dir():
        raise SystemExit(f"Zielordner existiert nicht oder ist kein Ordner: {target}")

    normalized = normalized_path(target)
    digest = hashlib.sha256(normalized.encode("utf-8")).hexdigest()[:24]
    workspace = root / "workspaces" / digest
    manifest_path = workspace / "WORKSPACE.json"
    created_at = now()

    if manifest_path.exists():
        existing = json.loads(manifest_path.read_text(encoding="utf-8"))
        existing_normalized = existing.get("normalizedPath")
        if existing_normalized and existing_normalized != normalized:
            raise SystemExit(f"Workspace-Hash-Kollision: {manifest_path}")
        created_at = existing.get("createdAt") or created_at

    data = {
        "schemaVersion": SCHEMA_VERSION,
        "hash": digest,
        "originalPath": str(Path(args.target)),
        "targetPath": str(target),
        "normalizedPath": normalized,
        "alias": args.alias,
        "createdAt": created_at,
        "updatedAt": now(),
        "createdBy": current_user(),
        "host": platform.node() or "unknown",
        "platform": platform.system() or "unknown",
        "helperOutput": "helper-output",
    }

    if args.dry_run:
        print(json.dumps({"dryRun": True, "workspacePath": str(workspace), "manifest": data}, indent=2))
        return 0

    (workspace / "helper-output").mkdir(parents=True, exist_ok=True)
    write_text(manifest_path, json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    notes = workspace / "NOTIZEN.md"
    if not notes.exists():
        write_text(notes, "# Notizen\n\n")
    overrides = workspace / "RULE_OVERRIDES.md"
    if not overrides.exists():
        write_text(overrides, "# Optionale arbeitsordnerspezifische Hinweise\n\n")
    print(str(workspace))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
'@
}

function Get-PythonGuardOwner {
    return @'
#!/usr/bin/env python3
"""Prueft OWNER.json vor Schreibzugriffen auf Nutzer- oder Agentenordner."""

from __future__ import annotations

import argparse
import json
import os
import platform
from pathlib import Path


def current_username() -> str:
    return os.environ.get("USERNAME") or os.environ.get("USER") or "unknown"


def current_domain() -> str:
    return os.environ.get("USERDOMAIN") or platform.node() or "unknown"


def main() -> int:
    parser = argparse.ArgumentParser(description="OWNER.json pruefen")
    parser.add_argument("--owner", required=True, help="Pfad zu OWNER.json")
    parser.add_argument("--explain", action="store_true", help="JSON-Ergebnis ausgeben")
    args = parser.parse_args()

    owner_path = Path(args.owner)
    if not owner_path.exists():
        print(f"OWNER.json fehlt: {owner_path}")
        return 3

    owner = json.loads(owner_path.read_text(encoding="utf-8"))
    expected_user = owner.get("username")
    expected_domain = owner.get("domain") or owner.get("host")
    user_ok = expected_user == current_username()
    domain_ok = not expected_domain or expected_domain in {current_domain(), platform.node()}
    ok = bool(user_ok and domain_ok)
    result = {
        "ok": ok,
        "ownerPath": str(owner_path),
        "expectedUser": expected_user,
        "actualUser": current_username(),
        "expectedDomainOrHost": expected_domain,
        "actualDomainOrHost": current_domain(),
    }
    if args.explain or not ok:
        print(json.dumps(result, indent=2))
    return 0 if ok else 2


if __name__ == "__main__":
    raise SystemExit(main())
'@
}

function Get-PowerShellNewUserScript {
    param($Env)
    $template = @'
[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$AgentId = "",
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = (Resolve-Path (Join-Path $ScriptDir "..")).Path
}
$root = [System.IO.Path]::GetFullPath($RootPath)
$domain = if ($env:USERDOMAIN) { $env:USERDOMAIN } else { $env:COMPUTERNAME }
$user = if ($env:USERNAME) { $env:USERNAME } else { [Environment]::UserName }
$computer = if ($env:COMPUTERNAME) { $env:COMPUTERNAME } else { [Environment]::MachineName }
$sid = ""
try { $sid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value } catch { $sid = "" }
$safe = (($domain + "_" + $user) -replace "[^A-Za-z0-9_.-]", "_").ToLowerInvariant()
$userRoot = Join-Path $root "users/__ENV_FAMILY__/$safe"
if ([string]::IsNullOrWhiteSpace($AgentId)) {
    $AgentId = (Get-Date).ToString("yyyyMMdd-HHmmss") + "-" + ([guid]::NewGuid().ToString("N").Substring(0, 8))
}
$agentRoot = Join-Path $userRoot "agents/$AgentId"
$ownerPath = Join-Path $userRoot "OWNER.json"

if (Test-Path -LiteralPath $ownerPath) {
    $existing = Get-Content -LiteralPath $ownerPath -Raw | ConvertFrom-Json
    if ($existing.username -ne $user -or ($existing.domain -and $existing.domain -ne $domain)) {
        throw "OWNER.json gehoert nicht zum aktuellen Nutzer: $ownerPath"
    }
}

$plan = [ordered]@{
    dryRun = [bool]$DryRun
    userRoot = $userRoot
    agentRoot = $agentRoot
    ownerPath = $ownerPath
}
if ($DryRun) {
    $plan | ConvertTo-Json -Depth 10
    return
}

New-Item -ItemType Directory -Force -Path $agentRoot, (Join-Path $userRoot "scratch"), (Join-Path $userRoot "notes"), (Join-Path $userRoot "logs"), (Join-Path $userRoot "outbox") | Out-Null

$createdAt = (Get-Date).ToString("o")
if (Test-Path -LiteralPath $ownerPath) {
    $existing = Get-Content -LiteralPath $ownerPath -Raw | ConvertFrom-Json
    if ($existing.createdAt) { $createdAt = $existing.createdAt }
}
$owner = [ordered]@{
    schemaVersion = 1
    environment = "__ENV_NAME__"
    os = "__ENV_OS__"
    role = "__ENV_ROLE__"
    domain = $domain
    username = $user
    computerName = $computer
    userSid = $sid
    writableBy = "owner-only"
    createdAt = $createdAt
    updatedAt = (Get-Date).ToString("o")
}
$owner | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ownerPath -Encoding UTF8

Set-Content -LiteralPath (Join-Path $userRoot "IMMER_LESEN.md") -Encoding UTF8 -Value "# Immer Lesen`n`nDieser Ordner gehoert zu $domain\$user. Wenn du nicht dieser Nutzer bist, schreibe nicht in diesen Ordner.`n`nErlaubte Schreibbereiche: eigener Agentenordner, scratch, notes, logs und outbox.`n"
Set-Content -LiteralPath (Join-Path $agentRoot "AGENT_POLICY.md") -Encoding UTF8 -Value "# Agent Policy`n`nArbeite nur fuer den Owner dieses Nutzerordners. Pruefe OWNER.json vor Schreibzugriffen. Nutze zentrale Helper aus AIRGAP_CLINE_HOME.`n"
Set-Content -LiteralPath (Join-Path $agentRoot "CURRENT_TASK.md") -Encoding UTF8 -Value "# Aktuelle Aufgabe`n`nNoch keine Aufgabe dokumentiert.`n"
Set-Content -LiteralPath (Join-Path $agentRoot "WORKSPACE_BINDINGS.json") -Encoding UTF8 -Value "{}"

$stateDir = Join-Path $root "state"
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
@{
    schemaVersion = 1
    userRoot = $userRoot
    agentRoot = $agentRoot
    agentId = $AgentId
    updatedAt = (Get-Date).ToString("o")
} | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $stateDir "last-agent.json") -Encoding UTF8

Write-Output $agentRoot
'@
    return $template.Replace("__ENV_FAMILY__", $Env.Family).Replace("__ENV_NAME__", $Env.Name).Replace("__ENV_OS__", $Env.Os).Replace("__ENV_ROLE__", $Env.Role)
}

function Get-PowerShellSyncScript {
    param($Env)
    $template = @'
[CmdletBinding()]
param(
    [string]$RootPath = "",
    [switch]$DryRun,
    [switch]$Repair
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = (Resolve-Path (Join-Path $ScriptDir "..")).Path
}
$root = [System.IO.Path]::GetFullPath($RootPath)
$marker = "AIRGAP-CLINE-STUB:v2"
$managedMarker = "AIRGAP-CLINE-MANAGED:v2"
$actions = New-Object System.Collections.ArrayList

function Add-Action {
    param([string]$Action, [string]$Path, [string]$BackupPath = "")
    [void]$actions.Add([ordered]@{ action = $Action; path = $Path; backupPath = $BackupPath })
}

function Write-ManagedFile {
    param([string]$Path, [string]$Content)
    $parent = Split-Path -Parent $Path
    if (-not $DryRun) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    $backupPath = ""
    if (Test-Path -LiteralPath $Path) {
        $existing = Get-Content -LiteralPath $Path -Raw
        if ($existing -notmatch [regex]::Escape($marker) -and $existing -notmatch [regex]::Escape($managedMarker)) {
            $backupPath = "$Path.backup-$(Get-Date -Format yyyyMMdd-HHmmss)"
            if (-not $DryRun) { Copy-Item -LiteralPath $Path -Destination $backupPath -Force }
            Add-Action "backup" $Path $backupPath
        }
    }
    if (-not $DryRun) { Set-Content -LiteralPath $Path -Encoding UTF8 -Value $Content }
    Add-Action "write" $Path $backupPath
}

function Copy-ManagedFile {
    param([string]$Source, [string]$Destination)
    $content = Get-Content -LiteralPath $Source -Raw
    Write-ManagedFile -Path $Destination -Content $content
}

function Copy-ManagedSkill {
    param([string]$SourceDir, [string]$DestinationDir)
    $skillFile = Join-Path $DestinationDir "SKILL.md"
    if (Test-Path -LiteralPath $DestinationDir) {
        $isManaged = $false
        if (Test-Path -LiteralPath $skillFile) {
            $isManaged = ((Get-Content -LiteralPath $skillFile -Raw) -match [regex]::Escape($managedMarker))
        }
        if (-not $isManaged) {
            $backupDir = "$DestinationDir.backup-$(Get-Date -Format yyyyMMdd-HHmmss)"
            if (-not $DryRun) { Move-Item -LiteralPath $DestinationDir -Destination $backupDir -Force }
            Add-Action "backup-directory" $DestinationDir $backupDir
        } elseif (-not $DryRun) {
            Remove-Item -LiteralPath $DestinationDir -Recurse -Force
        }
    }
    if (-not $DryRun) {
        $parent = Split-Path -Parent $DestinationDir
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
        Copy-Item -LiteralPath $SourceDir -Destination $DestinationDir -Recurse -Force
    }
    Add-Action "sync-skill" $DestinationDir
}

$stub = @"
<!-- $marker -->
# Air-Gap-Cline-Zentralumgebung

AIRGAP_CLINE_HOME: ``$root``

Pflicht vor jeder Aufgabe:

1. Lies ``$root\AGENTS.md``.
2. Lies ``$root\ENVIRONMENT.md``.
3. Beachte alle Regeln unter ``$root\shared\rules``.
4. Nutze zentrale Helper unter ``$root\shared\helpers``.
5. Veraendere keine Provider-, Modell-, Auth- oder KI-Server-Konfiguration.
"@

$ruleTargets = @(
    (Join-Path $HOME ".cline/rules/00-airgap-zentralumgebung.md")
)
$documents = [Environment]::GetFolderPath("MyDocuments")
if ($documents) {
    $ruleTargets += Join-Path $documents "Cline/Rules/00-airgap-zentralumgebung.md"
}

foreach ($target in $ruleTargets) {
    Write-ManagedFile -Path $target -Content $stub
}

$workflowTarget = Join-Path $HOME ".cline/data/workflows"
foreach ($workflow in Get-ChildItem -LiteralPath (Join-Path $root "shared/workflows") -Filter "*.md" -File) {
    Copy-ManagedFile -Source $workflow.FullName -Destination (Join-Path $workflowTarget $workflow.Name)
}

$skillsTarget = Join-Path $HOME ".cline/skills"
foreach ($skill in Get-ChildItem -LiteralPath (Join-Path $root "shared/skills") -Directory) {
    Copy-ManagedSkill -SourceDir $skill.FullName -DestinationDir (Join-Path $skillsTarget $skill.Name)
}

$state = [ordered]@{
    schemaVersion = 1
    environment = "__ENV_NAME__"
    dryRun = [bool]$DryRun
    repair = [bool]$Repair
    rootPath = $root
    syncedAt = (Get-Date).ToString("o")
    targets = $actions
    providerChanged = $false
}
if (-not $DryRun) {
    $stateDir = Join-Path $root "state"
    New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
    $state | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath (Join-Path $stateDir "last-stub-sync.json") -Encoding UTF8
}
$state | ConvertTo-Json -Depth 20
'@
    return $template.Replace("__ENV_NAME__", $Env.Name)
}

function Get-PowerShellInitializeScript {
    param($Env)
    $template = @'
[CmdletBinding()]
param(
    [string]$RootPath = "",
    [switch]$NoGlobalStub,
    [switch]$DryRun,
    [switch]$Repair
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = (Resolve-Path (Join-Path $ScriptDir "..")).Path
}
$root = [System.IO.Path]::GetFullPath($RootPath)
$errors = @()
$versionPath = Join-Path $root "VERSION"
$version = if (Test-Path -LiteralPath $versionPath) { (Get-Content -LiteralPath $versionPath -Raw).Trim() } else { "unknown" }

function Write-BootstrapStatus {
    param([string]$Status, [string]$AgentRoot, $StubTargets, [string[]]$Errors)
    $identityDomain = if ($env:USERDOMAIN) { $env:USERDOMAIN } else { $env:COMPUTERNAME }
    $identityUser = if ($env:USERNAME) { $env:USERNAME } else { [Environment]::UserName }
    $statusObject = [ordered]@{
        schemaVersion = 2
        status = $Status
        environment = "__ENV_NAME__"
        version = $version
        os = "__ENV_OS__"
        role = "__ENV_ROLE__"
        rootPath = $root
        domain = $identityDomain
        username = $identityUser
        host = if ($env:COMPUTERNAME) { $env:COMPUTERNAME } else { [Environment]::MachineName }
        agentRoot = $AgentRoot
        dryRun = [bool]$DryRun
        repair = [bool]$Repair
        noGlobalStub = [bool]$NoGlobalStub
        providerChanged = $false
        checkedAt = (Get-Date).ToString("o")
        stubTargets = $StubTargets
        errors = $Errors
    }
    if (-not $DryRun) {
        $stateDir = Join-Path $root "state"
        New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
        $statusObject | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath (Join-Path $stateDir "bootstrap-status.json") -Encoding UTF8
    }
    $statusObject | ConvertTo-Json -Depth 20
}

try {
    foreach ($required in @("START_HIER.md", "AGENTS.md", "ENVIRONMENT.md", "MANIFEST.json", "shared/rules", "shared/workflows", "shared/skills", "shared/helpers/python")) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $required))) {
            throw "Fehlender Bestandteil: $required"
        }
    }

    $agentOutput = & (Join-Path $ScriptDir "New-AirgapClineUserWorkspace.ps1") -RootPath $root -DryRun:$DryRun
    $agentRoot = ($agentOutput | Select-Object -Last 1)
    if ($DryRun) {
        $agentJson = ($agentOutput | Out-String).Trim()
        if ($agentJson) {
            try {
                $agentPlan = $agentJson | ConvertFrom-Json
                if ($agentPlan.agentRoot) { $agentRoot = $agentPlan.agentRoot }
            } catch {
                $agentRoot = $agentJson
            }
        }
    }
    $stubTargets = @()
    if (-not $NoGlobalStub) {
        $syncOutput = & (Join-Path $ScriptDir "Sync-ClineGlobalStubs.ps1") -RootPath $root -DryRun:$DryRun -Repair:$Repair
        $syncJson = ($syncOutput | Out-String).Trim()
        if ($syncJson) {
            try {
                $sync = $syncJson | ConvertFrom-Json
                $stubTargets = $sync.targets
            } catch {
                $stubTargets = @($syncJson)
            }
        }
    }

    Write-BootstrapStatus -Status "ok" -AgentRoot $agentRoot -StubTargets $stubTargets -Errors @()
    Write-Host "Initialisierung abgeschlossen fuer __ENV_NAME__."
} catch {
    $errors += $_.Exception.Message
    Write-BootstrapStatus -Status "error" -AgentRoot "" -StubTargets @() -Errors $errors
    throw
}
'@
    return $template.Replace("__ENV_NAME__", $Env.Name).Replace("__ENV_OS__", $Env.Os).Replace("__ENV_ROLE__", $Env.Role)
}

function Get-PowerShellRegisterScript {
    return @'
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$TargetPath,
    [string]$RootPath = "",
    [string]$Alias = "",
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = (Resolve-Path (Join-Path $ScriptDir "..")).Path
}
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
if (-not $python) { throw "Python wurde nicht gefunden." }

$argsList = @((Join-Path $RootPath "shared/helpers/python/register_workspace.py"), "--root", $RootPath, "--target", $TargetPath)
if ($Alias) { $argsList += @("--alias", $Alias) }
if ($DryRun) { $argsList += "--dry-run" }
& $python.Source @argsList
'@
}

function Get-PowerShellGuardScript {
    return @'
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$OwnerPath,
    [string]$RootPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = (Resolve-Path (Join-Path $ScriptDir "..")).Path
}
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
if (-not $python) { throw "Python wurde nicht gefunden." }

& $python.Source (Join-Path $RootPath "shared/helpers/python/guard_owner.py") --owner $OwnerPath --explain
if ($LASTEXITCODE -ne 0) {
    throw "Owner-Guard hat Schreibzugriff verweigert: $OwnerPath"
}
'@
}

function Get-PowerShellTestScript {
    return @'
[CmdletBinding()]
param(
    [string]$RootPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = (Resolve-Path (Join-Path $ScriptDir "..")).Path
}
$required = @("START_HIER.md", "AGENTS.md", "ENVIRONMENT.md", "MANIFEST.json", "shared/rules", "shared/workflows", "shared/skills", "shared/helpers/python/register_workspace.py", "shared/helpers/python/guard_owner.py")
foreach ($item in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $RootPath $item))) {
        throw "Fehlender Bestandteil: $item"
    }
}

$manifest = Get-Content -LiteralPath (Join-Path $RootPath "MANIFEST.json") -Raw | ConvertFrom-Json
if ($manifest.assumesClineAlreadyConfigured -ne $true -or $manifest.changesProviderConfiguration -ne $false) {
    throw "MANIFEST.json verletzt Provider-/Cline-Annahmen."
}

$forbidden = Get-ChildItem -LiteralPath $RootPath -Recurse -File |
    Where-Object { $_.Extension.ToLowerInvariant() -in @(".exe", ".msi", ".vsix", ".7z", ".zip", ".gguf", ".safetensors", ".onnx") }
if ($forbidden) {
    throw "Verbotene Datei in Umgebung: $($forbidden[0].FullName)"
}

Write-Host "Umgebung valide: $RootPath"
'@
}

function Get-PosixScript {
    param([string]$Kind, $Env)

    switch ($Kind) {
        "init" {
            $template = @'
#!/bin/sh
set -eu

DRY_RUN=0
REPAIR=0
NO_GLOBAL_STUB=0
ROOT_PATH=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --repair) REPAIR=1 ;;
    --no-global-stub) NO_GLOBAL_STUB=1 ;;
    *) ROOT_PATH=$1 ;;
  esac
  shift
done
if [ -z "$ROOT_PATH" ]; then
  SCRIPT_DIR=$(dirname "$0")
  ROOT_PATH=$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)
fi

for required in START_HIER.md AGENTS.md ENVIRONMENT.md MANIFEST.json shared/rules shared/workflows shared/skills shared/helpers/python; do
  if [ ! -e "$ROOT_PATH/$required" ]; then
    echo "Fehlender Bestandteil: $required" >&2
    exit 1
  fi
done

TMP_FILE="${TMPDIR:-/tmp}/airgap-cline-agent-root.$$"
if [ "$DRY_RUN" -eq 1 ]; then
  sh "$ROOT_PATH/scripts/new-airgap-cline-user-workspace.sh" --dry-run "$ROOT_PATH" > "$TMP_FILE"
else
  sh "$ROOT_PATH/scripts/new-airgap-cline-user-workspace.sh" "$ROOT_PATH" > "$TMP_FILE"
fi
AGENT_ROOT=$(tail -n 1 "$TMP_FILE")
rm -f "$TMP_FILE"

if [ "$NO_GLOBAL_STUB" -eq 0 ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    sh "$ROOT_PATH/scripts/sync-cline-global-stubs.sh" --dry-run "$ROOT_PATH"
  else
    sh "$ROOT_PATH/scripts/sync-cline-global-stubs.sh" "$ROOT_PATH"
  fi
fi

if [ "$DRY_RUN" -eq 0 ]; then
  mkdir -p "$ROOT_PATH/state"
  cat > "$ROOT_PATH/state/bootstrap-status.json" <<EOF
{
  "schemaVersion": 2,
  "status": "ok",
  "environment": "__ENV_NAME__",
  "version": "__VERSION__",
  "rootPath": "$ROOT_PATH",
  "agentRoot": "$AGENT_ROOT",
  "dryRun": false,
  "repair": $REPAIR,
  "providerChanged": false
}
EOF
fi
echo "Initialisierung abgeschlossen fuer __ENV_NAME__."
'@
            return $template.Replace("__ENV_NAME__", $Env.Name).Replace("__VERSION__", $Version)
        }
        "newuser" {
            $template = @'
#!/bin/sh
set -eu

DRY_RUN=0
ROOT_PATH=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    *) ROOT_PATH=$1 ;;
  esac
  shift
done
if [ -z "$ROOT_PATH" ]; then
  SCRIPT_DIR=$(dirname "$0")
  ROOT_PATH=$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)
fi

HOST_NAME=$(hostname 2>/dev/null || uname -n)
USER_NAME=${USER:-$(id -un 2>/dev/null || echo unknown)}
UID_VALUE=$(id -u 2>/dev/null || echo unknown)
SAFE=$(printf "%s_%s" "$HOST_NAME" "$USER_NAME" | tr -c 'A-Za-z0-9_.-' '_')
USER_ROOT="$ROOT_PATH/users/__ENV_FAMILY__/$SAFE"
AGENT_ID=$(date '+%Y%m%d-%H%M%S')-$$
AGENT_ROOT="$USER_ROOT/agents/$AGENT_ID"
OWNER_PATH="$USER_ROOT/OWNER.json"

if [ -f "$OWNER_PATH" ]; then
  if ! grep -q "\"username\": \"$USER_NAME\"" "$OWNER_PATH"; then
    echo "OWNER.json gehoert nicht zum aktuellen Nutzer: $OWNER_PATH" >&2
    exit 2
  fi
fi

if [ "$DRY_RUN" -eq 1 ]; then
  printf '{"dryRun":true,"userRoot":"%s","agentRoot":"%s","ownerPath":"%s"}\n' "$USER_ROOT" "$AGENT_ROOT" "$OWNER_PATH"
  exit 0
fi

mkdir -p "$AGENT_ROOT" "$USER_ROOT/scratch" "$USER_ROOT/notes" "$USER_ROOT/logs" "$USER_ROOT/outbox"
cat > "$OWNER_PATH" <<EOF
{
  "schemaVersion": 1,
  "environment": "__ENV_NAME__",
  "os": "__ENV_OS__",
  "role": "__ENV_ROLE__",
  "host": "$HOST_NAME",
  "username": "$USER_NAME",
  "uid": "$UID_VALUE",
  "writableBy": "owner-only"
}
EOF
cat > "$USER_ROOT/IMMER_LESEN.md" <<EOF
# Immer Lesen

Dieser Ordner gehoert zu $HOST_NAME/$USER_NAME. Wenn du nicht dieser Nutzer bist, schreibe nicht in diesen Ordner.
EOF
cat > "$AGENT_ROOT/AGENT_POLICY.md" <<EOF
# Agent Policy

Arbeite nur fuer den Owner dieses Nutzerordners. Pruefe OWNER.json vor Schreibzugriffen. Nutze zentrale Helper aus AIRGAP_CLINE_HOME.
EOF
printf "# Aktuelle Aufgabe\n\nNoch keine Aufgabe dokumentiert.\n" > "$AGENT_ROOT/CURRENT_TASK.md"
printf "{}\n" > "$AGENT_ROOT/WORKSPACE_BINDINGS.json"
mkdir -p "$ROOT_PATH/state"
printf "%s\n" "$AGENT_ROOT"
'@
            return $template.Replace("__ENV_FAMILY__", $Env.Family).Replace("__ENV_NAME__", $Env.Name).Replace("__ENV_OS__", $Env.Os).Replace("__ENV_ROLE__", $Env.Role)
        }
        "sync" {
            return @'
#!/bin/sh
set -eu

DRY_RUN=0
ROOT_PATH=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    *) ROOT_PATH=$1 ;;
  esac
  shift
done
if [ -z "$ROOT_PATH" ]; then
  SCRIPT_DIR=$(dirname "$0")
  ROOT_PATH=$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)
fi

MARKER="AIRGAP-CLINE-STUB:v2"
MANAGED="AIRGAP-CLINE-MANAGED:v2"
CLINE_HOME="${HOME}/.cline"
RULE_TARGET="$CLINE_HOME/rules/00-airgap-zentralumgebung.md"

write_file() {
  target=$1
  content_file=$2
  parent=$(dirname "$target")
  [ "$DRY_RUN" -eq 1 ] || mkdir -p "$parent"
  if [ -f "$target" ] && ! grep -q "$MARKER\|$MANAGED" "$target"; then
    backup="$target.backup-$(date '+%Y%m%d-%H%M%S')"
    echo "backup $target -> $backup"
    [ "$DRY_RUN" -eq 1 ] || cp "$target" "$backup"
  fi
  echo "write $target"
  [ "$DRY_RUN" -eq 1 ] || cp "$content_file" "$target"
}

TMP_STUB="${TMPDIR:-/tmp}/airgap-cline-stub.$$"
cat > "$TMP_STUB" <<EOF
<!-- $MARKER -->
# Air-Gap-Cline-Zentralumgebung

AIRGAP_CLINE_HOME: \`$ROOT_PATH\`

Vor jeder Aufgabe: lies \`$ROOT_PATH/AGENTS.md\`, \`$ROOT_PATH/ENVIRONMENT.md\` und die Regeln unter \`$ROOT_PATH/shared/rules\`. Veraendere keine Provider-, Modell-, Auth- oder KI-Server-Konfiguration.
EOF
write_file "$RULE_TARGET" "$TMP_STUB"
rm -f "$TMP_STUB"

WORKFLOW_TARGET="$CLINE_HOME/data/workflows"
for workflow in "$ROOT_PATH"/shared/workflows/*.md; do
  [ -f "$workflow" ] || continue
  write_file "$WORKFLOW_TARGET/$(basename "$workflow")" "$workflow"
done

SKILLS_TARGET="$CLINE_HOME/skills"
[ "$DRY_RUN" -eq 1 ] || mkdir -p "$SKILLS_TARGET"
for skill in "$ROOT_PATH"/shared/skills/*; do
  [ -d "$skill" ] || continue
  base=$(basename "$skill")
  target="$SKILLS_TARGET/$base"
  if [ -d "$target" ]; then
    if [ ! -f "$target/SKILL.md" ] || ! grep -q "$MANAGED" "$target/SKILL.md"; then
      backup="$target.backup-$(date '+%Y%m%d-%H%M%S')"
      echo "backup-directory $target -> $backup"
      [ "$DRY_RUN" -eq 1 ] || mv "$target" "$backup"
    else
      [ "$DRY_RUN" -eq 1 ] || rm -rf "$target"
    fi
  fi
  echo "sync-skill $target"
  [ "$DRY_RUN" -eq 1 ] || cp -R "$skill" "$target"
done

if [ "$DRY_RUN" -eq 0 ]; then
  mkdir -p "$ROOT_PATH/state"
  cat > "$ROOT_PATH/state/last-stub-sync.json" <<EOF
{
  "schemaVersion": 1,
  "rootPath": "$ROOT_PATH",
  "providerChanged": false
}
EOF
fi
'@
        }
        "register" {
            return @'
#!/bin/sh
set -eu
DRY_RUN=""
ALIAS_VALUE=""
TARGET_PATH=""
ROOT_PATH=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN="--dry-run" ;;
    --alias) shift; ALIAS_VALUE=$1 ;;
    --root) shift; ROOT_PATH=$1 ;;
    *) TARGET_PATH=$1 ;;
  esac
  shift
done
if [ -z "$TARGET_PATH" ]; then
  echo "Nutzung: register-external-workspace.sh <zielpfad> [--alias name] [--root root] [--dry-run]" >&2
  exit 1
fi
if [ -z "$ROOT_PATH" ]; then
  SCRIPT_DIR=$(dirname "$0")
  ROOT_PATH=$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)
fi
if command -v python3 >/dev/null 2>&1; then
  python3 "$ROOT_PATH/shared/helpers/python/register_workspace.py" --root "$ROOT_PATH" --target "$TARGET_PATH" --alias "$ALIAS_VALUE" $DRY_RUN
else
  echo "python3 wurde nicht gefunden." >&2
  exit 1
fi
'@
        }
        "guard" {
            return @'
#!/bin/sh
set -eu
if [ "$#" -lt 1 ]; then
  echo "Nutzung: guard-owner.sh <OWNER.json> [root]" >&2
  exit 1
fi
OWNER_PATH=$1
ROOT_PATH=${2:-}
if [ -z "$ROOT_PATH" ]; then
  SCRIPT_DIR=$(dirname "$0")
  ROOT_PATH=$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)
fi
if command -v python3 >/dev/null 2>&1; then
  python3 "$ROOT_PATH/shared/helpers/python/guard_owner.py" --owner "$OWNER_PATH" --explain
else
  echo "python3 wurde nicht gefunden." >&2
  exit 1
fi
'@
        }
        "test" {
            return @'
#!/bin/sh
set -eu
ROOT_PATH=${1:-}
if [ -z "$ROOT_PATH" ]; then
  SCRIPT_DIR=$(dirname "$0")
  ROOT_PATH=$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)
fi
for item in START_HIER.md AGENTS.md ENVIRONMENT.md MANIFEST.json shared/rules shared/workflows shared/skills shared/helpers/python/register_workspace.py shared/helpers/python/guard_owner.py; do
  if [ ! -e "$ROOT_PATH/$item" ]; then
    echo "Fehlender Bestandteil: $item" >&2
    exit 1
  fi
done
find "$ROOT_PATH" \( -name '*.exe' -o -name '*.msi' -o -name '*.vsix' -o -name '*.7z' -o -name '*.zip' -o -name '*.gguf' -o -name '*.safetensors' -o -name '*.onnx' \) -print | while IFS= read -r bad; do
  echo "Verbotene Datei in Umgebung: $bad" >&2
  exit 1
done
echo "Umgebung valide: $ROOT_PATH"
'@
        }
    }
}

Write-TextFile "README.md" @'
# Air-Gap-Cline-Umgebung

Dieses Repo stellt exportierbare Startumgebungen fuer Cline bereit. Cline selbst muss bereits installiert, eingerichtet und mit dem gewuenschten KI-Server verbunden sein. Dieses Projekt veraendert keine Provider-, Modell- oder Authentifizierungsdaten.

## Schnellwahl

| Umgebung | Zweck |
| --- | --- |
| `Cline_Env_Windows_User` | Windows-Nutzer ohne Adminrechte, primaer VS Code Cline Extension |
| `Cline_Env_Windows_Admin` | Windows-Admin fuer zentrale Ablage auf Maschine oder Share |
| `Cline_Env_Linux_User` | Linux-Nutzer mit Cline CLI |
| `Cline_Env_Linux_Admin` | Linux-Admin fuer `/opt` oder zentrale Shares |
| `Cline_Env_Mac_User` | macOS-Nutzer mit Cline CLI oder Editor-Integration |
| `Cline_Env_Mac_Admin` | macOS-Admin fuer `/Users/Shared` oder `/opt` |
| `Cline_Env_Solaris_User` | Solaris/POSIX best-effort im Nutzerkontext |
| `Cline_Env_Solaris_Admin` | Solaris/POSIX best-effort fuer zentrale Ablage |

## Nutzung

1. Passenden Ordner aus `environments/` oder aus einem Release-Paket entpacken.
2. Cline starten.
3. Cline anweisen:

```text
Initialisiere dich ueber folgenden Pfad: <vollstaendiger Pfad zum Cline_Env_... Ordner>
```

4. Cline liest im Umgebungsordner zuerst `START_HIER.md`, dann `AGENTS.md`, dann `ENVIRONMENT.md`.
5. Optional das Initialisierungsskript erst mit `--dry-run` ausfuehren lassen.

## Wichtig

- Ziel ist eine zentrale, wiederverwendbare Air-Gap-Ausgangsumgebung.
- Regeln, Workflows, Skills und Helper bleiben im zentralen Umgebungsordner.
- Externe Repos werden nicht mit Cline-Regeln, Workflows oder Helper-Dateien verschmutzt, ausser der Nutzer verlangt es ausdruecklich.
- Nutzer- und Agentenordner werden ueber `OWNER.json` und Guard-Helper getrennt.
- Release-Pakete enthalten keine Cline-Installer, keine KI-Modelle und keine Drittanbieter-Binaries.
- Globale Stubs sichern unmarkierte bestehende Dateien vor dem Ueberschreiben mit Zeitstempel-Backup.

## Release-Artefakte

Pro Version werden `.7z`- und `.zip`-Pakete pro Umgebung sowie Gesamtpakete erzeugt. Die Skripte liegen unter `scripts/`.
'@

Write-TextFile "docs/BASELINE-v0.1.md" @'
# Baseline v0.1

Stand vor v0.2:

- Acht exportierbare Umgebungen sind vorhanden.
- Release-Artefakte werden als `.7z` und `.zip` gebaut.
- Provider-, Modell-, Auth- und KI-Serverkonfiguration sind bewusst ausserhalb des Projekts.
- Laufzeitdaten unter `users/`, `workspaces/`, `state/`, `logs/` und `audit/` sind nicht Teil des Git-Verlaufs.

v0.2 haertet Bootstrap, Stubs, Owner-Schutz, Workspace-Registrierung, Tests und Release-Metadaten.
'@

Write-TextFile ".github/workflows/ci.yml" @'
name: CI

on:
  push:
  pull_request:

jobs:
  validate:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Test generated environments
        shell: pwsh
        run: ./scripts/Test-AllEnvironmentPackages.ps1
      - name: PowerShell syntax
        shell: pwsh
        run: |
          $errors = @()
          Get-ChildItem -Path scripts,environments -Recurse -Include *.ps1 | ForEach-Object {
            $tokens = $null
            $parseErrors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
            if ($parseErrors) { $errors += "$($_.FullName): $($parseErrors[0].Message)" }
          }
          if ($errors.Count -gt 0) { throw ($errors -join "`n") }
      - name: Python syntax
        shell: pwsh
        run: |
          $python = Get-Command python -ErrorAction SilentlyContinue
          if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
          if (-not $python) { throw "Python wurde nicht gefunden." }
          Get-ChildItem -Path environments -Recurse -Filter *.py | ForEach-Object {
            & $python.Source -m py_compile $_.FullName
          }
      - name: POSIX shell syntax
        shell: bash
        run: |
          find environments -name '*.sh' -print0 | xargs -0 -n 1 sh -n
      - name: Build packages
        shell: pwsh
        run: ./scripts/Build-AllEnvironmentPackages.ps1 -Version "0.2.0-ci" -SkipTests
'@

Write-TextFile "scripts/Test-AllEnvironmentPackages.ps1" @'
[CmdletBinding()]
param(
    [string]$RootPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = Split-Path -Parent $ScriptDir
}
$RepoRoot = [System.IO.Path]::GetFullPath($RootPath)
$expected = @(
    "Cline_Env_Windows_User",
    "Cline_Env_Windows_Admin",
    "Cline_Env_Linux_User",
    "Cline_Env_Linux_Admin",
    "Cline_Env_Mac_User",
    "Cline_Env_Mac_Admin",
    "Cline_Env_Solaris_User",
    "Cline_Env_Solaris_Admin"
)

$requiredFiles = @("START_HIER.md", "ENVIRONMENT.md", "AGENTS.md", ".clineignore", "VERSION", "MANIFEST.json", "SHA256SUMS.txt")
$requiredDirs = @("shared/rules", "shared/workflows", "shared/skills", "shared/helpers/python", "bootstrap", "scripts", "users", "workspaces", "state", "logs", "audit")
$forbiddenExtensions = @(".exe", ".msi", ".msix", ".appx", ".vsix", ".dmg", ".pkg", ".deb", ".rpm", ".7z", ".zip", ".gguf", ".safetensors", ".onnx", ".pt", ".pth", ".ckpt")
$requiredRules = @("00-airgap-grundsaetze.md", "05-plattform-und-variante.md", "10-zentralpfad-ist-quell-der-wahrheit.md", "20-nutzer-und-agententrennung.md", "30-keine-repo-verschmutzung.md", "40-zentrale-helper-nutzen.md", "50-verifikation-und-dokumentation.md")
$requiredWorkflows = @("00-initialisierung.md", "01-zentralstubs-synchronisieren.md", "02-nutzerordner-anlegen.md", "10-externer-arbeitsordner-registrieren.md", "20-klassische-aufgabe-bearbeiten.md", "30-helper-script-nutzen.md", "40-airgap-abnahme.md", "90-selbstverbesserung.md")
$requiredSkills = @("airgap-bootstrap", "plattform-variante", "nutzer-agenten-schutz", "externer-arbeitsordner", "zentrale-helper", "airgap-validierung")

function Assert-FileContains {
    param([string]$Path, [string]$Needle)
    $content = Get-Content -LiteralPath $Path -Raw
    if ($content -notlike "*$Needle*") {
        throw "Datei enthaelt Pflichttext nicht: $Path :: $Needle"
    }
}

foreach ($name in $expected) {
    $envRoot = Join-Path $RepoRoot "environments/$name"
    if (-not (Test-Path -LiteralPath $envRoot -PathType Container)) {
        throw "Fehlende Umgebung: $name"
    }

    foreach ($file in $requiredFiles) {
        $path = Join-Path $envRoot $file
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Fehlende Datei in ${name}: $file"
        }
    }

    foreach ($dir in $requiredDirs) {
        $path = Join-Path $envRoot $dir
        if (-not (Test-Path -LiteralPath $path -PathType Container)) {
            throw "Fehlender Ordner in ${name}: $dir"
        }
    }

    $manifest = Get-Content -LiteralPath (Join-Path $envRoot "MANIFEST.json") -Raw | ConvertFrom-Json
    if ($manifest.name -ne $name) { throw "MANIFEST name passt nicht fuer $name." }
    if ($manifest.assumesClineAlreadyConfigured -ne $true) { throw "MANIFEST muss Cline als Voraussetzung markieren: $name." }
    if ($manifest.changesProviderConfiguration -ne $false) { throw "MANIFEST darf keine Provider-Aenderung markieren: $name." }
    if (-not $manifest.schemaVersion) { throw "MANIFEST braucht schemaVersion: $name." }

    foreach ($rule in $requiredRules) {
        $path = Join-Path $envRoot "shared/rules/$rule"
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Fehlende Regel in ${name}: $rule" }
        Assert-FileContains -Path $path -Needle "AIRGAP-CLINE-MANAGED:v2"
    }
    foreach ($workflow in $requiredWorkflows) {
        $path = Join-Path $envRoot "shared/workflows/$workflow"
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Fehlender Workflow in ${name}: $workflow" }
        Assert-FileContains -Path $path -Needle "AIRGAP-CLINE-MANAGED:v2"
    }
    foreach ($skill in $requiredSkills) {
        $path = Join-Path $envRoot "shared/skills/$skill/SKILL.md"
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Fehlender Skill in ${name}: $skill" }
        Assert-FileContains -Path $path -Needle "AIRGAP-CLINE-MANAGED:v2"
    }

    foreach ($helper in @("shared/helpers/python/register_workspace.py", "shared/helpers/python/guard_owner.py")) {
        if (-not (Test-Path -LiteralPath (Join-Path $envRoot $helper) -PathType Leaf)) {
            throw "Fehlender Python-Helper in ${name}: $helper"
        }
    }

    if ($name -like "*Windows*") {
        foreach ($script in @("Initialize-AirgapClineEnvironment.ps1", "Sync-ClineGlobalStubs.ps1", "New-AirgapClineUserWorkspace.ps1", "Register-ExternalWorkspace.ps1", "Test-AirgapOwner.ps1")) {
            $path = Join-Path $envRoot "scripts/$script"
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Fehlendes Windows-Skript in ${name}: $script" }
        }
        Assert-FileContains -Path (Join-Path $envRoot "scripts/Initialize-AirgapClineEnvironment.ps1") -Needle "DryRun"
        Assert-FileContains -Path (Join-Path $envRoot "scripts/Initialize-AirgapClineEnvironment.ps1") -Needle "Repair"
    } else {
        foreach ($script in @("initialize-airgap-cline-environment.sh", "sync-cline-global-stubs.sh", "new-airgap-cline-user-workspace.sh", "register-external-workspace.sh", "guard-owner.sh")) {
            $path = Join-Path $envRoot "scripts/$script"
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Fehlendes POSIX-Skript in ${name}: $script" }
        }
        Assert-FileContains -Path (Join-Path $envRoot "scripts/initialize-airgap-cline-environment.sh") -Needle "--dry-run"
    }

    $badRef = Get-ChildItem -LiteralPath $envRoot -Recurse -File |
        Where-Object { $_.FullName -notmatch "\\users\\|/users/" -and $_.FullName -notmatch "\\state\\|/state/" } |
        Select-String -Pattern "../src/common" -SimpleMatch -ErrorAction SilentlyContinue
    if ($badRef) {
        throw "Umgebung $name enthaelt eine zwingende Referenz auf ../src/common."
    }

    $badBinary = Get-ChildItem -LiteralPath $envRoot -Recurse -File |
        Where-Object { $forbiddenExtensions -contains $_.Extension.ToLowerInvariant() }
    if ($badBinary) {
        throw "Verbotene Binaerdatei in ${name}: $($badBinary[0].FullName)"
    }
}

$gitignore = Get-Content -LiteralPath (Join-Path $RepoRoot ".gitignore") -Raw
$mustContain = @(".codex/", ".agents/", "CODEX_LOCAL.md", "CODEX_NOTES.md", "*.codex.md", "*.local.md", "!**/users/**/.gitkeep", "!**/state/.gitkeep", "*.7z", "*.zip", "*.vsix")
foreach ($entry in $mustContain) {
    if ($gitignore -notlike "*$entry*") {
        throw ".gitignore enthaelt Pflichtmuster nicht: $entry"
    }
}

$psErrors = @()
Get-ChildItem -Path (Join-Path $RepoRoot "scripts"), (Join-Path $RepoRoot "environments") -Recurse -Include *.ps1 | ForEach-Object {
    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
    if ($parseErrors) { $psErrors += "$($_.FullName): $($parseErrors[0].Message)" }
}
if ($psErrors.Count -gt 0) {
    throw ($psErrors -join "`n")
}

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
if ($python) {
    Get-ChildItem -LiteralPath (Join-Path $RepoRoot "environments") -Recurse -Filter *.py | ForEach-Object {
        & $python.Source -m py_compile $_.FullName
        if ($LASTEXITCODE -ne 0) { throw "Python-Syntaxfehler: $($_.FullName)" }
    }
}

Write-Host "Alle exportierbaren Umgebungen sind valide."
'@

Write-TextFile "scripts/New-ReleaseManifest.ps1" @'
[CmdletBinding()]
param(
    [string]$DistPath = "",
    [string]$Version = "0.2.0"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($DistPath)) {
    $DistPath = Join-Path (Split-Path -Parent $ScriptDir) "dist"
}
if (-not (Test-Path -LiteralPath $DistPath)) {
    throw "DistPath existiert nicht: $DistPath"
}

function Get-AssetInfo {
    param([System.IO.FileInfo]$File)
    $hash = Get-FileHash -LiteralPath $File.FullName -Algorithm SHA256
    $packageType = if ($File.Extension -eq ".7z") { "7z" } elseif ($File.Extension -eq ".zip") { "zip" } else { "metadata" }
    $environmentName = "none"
    if ($File.Name -match "^(Cline_Env_(Windows|Linux|Mac|Solaris)_(User|Admin)|Cline_Env_All)_v") {
        $environmentName = $Matches[1]
    }
    [ordered]@{
        name = $File.Name
        size = $File.Length
        sha256 = $hash.Hash.ToLowerInvariant()
        packageType = $packageType
        environmentName = $environmentName
        generatedAt = (Get-Date).ToString("o")
    }
}

$assets = Get-ChildItem -LiteralPath $DistPath -File |
    Where-Object { $_.Name -notin @("RELEASE_MANIFEST.json", "SHA256SUMS.txt") } |
    Sort-Object Name |
    ForEach-Object { Get-AssetInfo -File $_ }

$manifest = [ordered]@{
    schemaVersion = 2
    version = $Version
    generatedAt = (Get-Date).ToString("o")
    artifactCount = $assets.Count
    assets = $assets
}

$manifestPath = Join-Path $DistPath "RELEASE_MANIFEST.json"
[System.IO.File]::WriteAllText($manifestPath, (($manifest | ConvertTo-Json -Depth 20) + "`n"), (New-Object System.Text.UTF8Encoding($false)))

$sumPath = Join-Path $DistPath "SHA256SUMS.txt"
$lines = foreach ($file in (Get-ChildItem -LiteralPath $DistPath -File | Where-Object { $_.Name -ne "SHA256SUMS.txt" } | Sort-Object Name)) {
    $hash = Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256
    "$($hash.Hash.ToLowerInvariant())  $($file.Name)"
}
[System.IO.File]::WriteAllText($sumPath, (($lines -join "`n") + "`n"), (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Release-Manifest geschrieben: $manifestPath"
'@

Write-TextFile "scripts/Build-AllEnvironmentPackages.ps1" @'
[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$Version = "0.2.0",
    [string]$OutputPath = "",
    [switch]$SkipTests
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = Split-Path -Parent $ScriptDir
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path (Split-Path -Parent $ScriptDir) "dist"
}
$RepoRoot = [System.IO.Path]::GetFullPath($RootPath)
$Date = (Get-Date).ToString("yyyy-MM-dd")
$SevenZip = "C:\Program Files\7-Zip\7z.exe"

if (-not $SkipTests) {
    & (Join-Path $PSScriptRoot "Test-AllEnvironmentPackages.ps1") -RootPath $RepoRoot
}

if (-not (Test-Path -LiteralPath $SevenZip)) {
    throw "7-Zip wurde nicht gefunden: $SevenZip"
}

if (Test-Path -LiteralPath $OutputPath) {
    Remove-Item -LiteralPath $OutputPath -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null

$stageRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("airgap-cline-package-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $stageRoot | Out-Null

function Copy-CleanTree {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    $sourceFull = [System.IO.Path]::GetFullPath($Source)
    Get-ChildItem -LiteralPath $sourceFull -Recurse -Force | ForEach-Object {
        $relative = $_.FullName.Substring($sourceFull.Length).TrimStart('\', '/')
        if ([string]::IsNullOrWhiteSpace($relative)) { return }

        $parts = $relative -split '[\\/]'
        $isRuntime = $parts[0] -in @("users", "workspaces", "state", "logs", "audit")
        if ($isRuntime -and $_.PSIsContainer) {
            $targetDir = Join-Path $Destination $relative
            New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
            return
        }
        if ($isRuntime -and $_.Name -ne ".gitkeep") {
            return
        }

        $target = Join-Path $Destination $relative
        if ($_.PSIsContainer) {
            New-Item -ItemType Directory -Force -Path $target | Out-Null
        } else {
            $parent = Split-Path -Parent $target
            if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
            Copy-Item -LiteralPath $_.FullName -Destination $target -Force
        }
    }
}

function Test-ZipArchive {
    param([string]$ZipPath, [string]$ExpectedRootName)
    $extractRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("airgap-cline-ziptest-" + [guid]::NewGuid().ToString("N"))
    try {
        Expand-Archive -LiteralPath $ZipPath -DestinationPath $extractRoot -Force
        $found = Get-ChildItem -LiteralPath $extractRoot -Directory -Recurse -Filter $ExpectedRootName | Select-Object -First 1
        if (-not $found) { throw "ZIP enthaelt erwarteten Root nicht: $ExpectedRootName" }
    } finally {
        if (Test-Path -LiteralPath $extractRoot) { Remove-Item -LiteralPath $extractRoot -Recurse -Force }
    }
}

try {
    $envRoot = Join-Path $RepoRoot "environments"
    $envs = Get-ChildItem -LiteralPath $envRoot -Directory -Filter "Cline_Env_*" | Sort-Object Name

    foreach ($env in $envs) {
        $stage = Join-Path $stageRoot $env.Name
        Copy-CleanTree -Source $env.FullName -Destination $stage

        $zipPath = Join-Path $OutputPath ("{0}_v{1}_{2}.zip" -f $env.Name, $Version, $Date)
        $sevenPath = Join-Path $OutputPath ("{0}_v{1}_{2}.7z" -f $env.Name, $Version, $Date)

        Compress-Archive -Path $stage -DestinationPath $zipPath -Force
        Test-ZipArchive -ZipPath $zipPath -ExpectedRootName $env.Name
        & $SevenZip a -t7z $sevenPath $stage | Out-Null
        & $SevenZip t $sevenPath | Out-Null
    }

    $allStage = Join-Path $stageRoot "Cline_Env_All"
    New-Item -ItemType Directory -Force -Path $allStage | Out-Null
    foreach ($env in $envs) {
        Copy-CleanTree -Source $env.FullName -Destination (Join-Path $allStage $env.Name)
    }

    $allZip = Join-Path $OutputPath ("Cline_Env_All_v{0}_{1}.zip" -f $Version, $Date)
    $all7z = Join-Path $OutputPath ("Cline_Env_All_v{0}_{1}.7z" -f $Version, $Date)
    Compress-Archive -Path $allStage -DestinationPath $allZip -Force
    Test-ZipArchive -ZipPath $allZip -ExpectedRootName "Cline_Env_All"
    & $SevenZip a -t7z $all7z $allStage | Out-Null
    & $SevenZip t $all7z | Out-Null

    $notes = @"
# Release v$Version

Dieses Release enthaelt pro exportierbarer Air-Gap-Cline-Umgebung je ein `.7z`- und `.zip`-Paket sowie ein Gesamtpaket.

Cline muss vor der Nutzung bereits installiert, eingerichtet und mit dem gewuenschten KI-Server verbunden sein. Diese Pakete enthalten keine Provider-, Modell-, Authentifizierungs- oder KI-Serverdaten.

## Auswahl

- Windows User/Admin: primaer fuer VS Code Cline Extension.
- Linux User/Admin: primaer fuer Cline CLI.
- macOS User/Admin: CLI- oder editornahe Nutzung.
- Solaris User/Admin: POSIX-best-effort, nur wenn Cline dort bereits lauffaehig ist.

## Verifikation

Alle `.7z`-Pakete wurden mit 7-Zip getestet. Alle `.zip`-Pakete wurden entpackt und auf den erwarteten Root-Ordner geprueft.
"@
    [System.IO.File]::WriteAllText((Join-Path $OutputPath "RELEASE_NOTES_DE.md"), $notes, (New-Object System.Text.UTF8Encoding($false)))
    & (Join-Path $PSScriptRoot "New-ReleaseManifest.ps1") -DistPath $OutputPath -Version $Version
    Write-Host "Pakete erstellt in: $OutputPath"
}
finally {
    if (Test-Path -LiteralPath $stageRoot) {
        Remove-Item -LiteralPath $stageRoot -Recurse -Force
    }
}
'@

foreach ($Env in $Environments) {
    $base = "environments/$($Env.Name)"
    Write-TextFile "$base/START_HIER.md" (Get-StartText -Env $Env)
    Write-TextFile "$base/ENVIRONMENT.md" (Get-EnvironmentText -Env $Env)
    Write-TextFile "$base/AGENTS.md" (Get-AgentsText -Env $Env)
    Write-TextFile "$base/VERSION" "$Version`n"

    $manifest = [ordered]@{
        schemaVersion = 2
        name = $Env.Name
        version = $Version
        generatedAt = (Get-Date).ToString("o")
        os = $Env.Os
        role = $Env.Role
        family = $Env.Family
        primaryMode = $Env.Primary
        recommendedPath = $Env.RecommendedPath
        assumesClineAlreadyConfigured = $true
        changesProviderConfiguration = $false
        containsProviderConfiguration = $false
        containsInstaller = $false
        containsModels = $false
        selfContained = $true
        bootstrap = [ordered]@{
            supportsDryRun = $true
            supportsRepair = $true
            writesBootstrapStatus = $true
            createsOwnerGuardedUserFolders = $true
        }
    }
    Write-TextFile "$base/MANIFEST.json" (ConvertTo-JsonText $manifest)

    foreach ($dir in @("shared/rules", "shared/workflows", "shared/skills", "shared/helpers/python", "shared/helpers/powershell", "shared/helpers/bash", "shared/helpers/posix", "bootstrap", "scripts", "users", "workspaces", "state", "logs", "audit")) {
        Ensure-Directory "$base/$dir"
    }

    $rules = Get-Rules -Env $Env
    foreach ($ruleName in $rules.Keys) {
        Write-TextFile "$base/shared/rules/$ruleName" $rules[$ruleName]
    }

    $workflows = Get-Workflows
    foreach ($workflowName in $workflows.Keys) {
        Write-TextFile "$base/shared/workflows/$workflowName" $workflows[$workflowName]
    }

    foreach ($skillName in $SkillDescriptions.Keys) {
        Write-TextFile "$base/shared/skills/$skillName/SKILL.md" (Get-SkillText -Name $skillName -Description $SkillDescriptions[$skillName])
    }
    $platformSkill = Get-PlatformSkillText -Env $Env
    Write-TextFile "$base/shared/skills/$($platformSkill.Name)/SKILL.md" $platformSkill.Text

    Write-TextFile "$base/shared/helpers/python/register_workspace.py" (Get-PythonRegisterWorkspace)
    Write-TextFile "$base/shared/helpers/python/guard_owner.py" (Get-PythonGuardOwner)

    Write-TextFile "$base/bootstrap/00-airgap-zentralumgebung.md" @"
<!-- AIRGAP-CLINE-STUB:v2 -->
# Air-Gap-Cline-Zentralumgebung

Dieser Stub wird bei der Initialisierung in globale Cline-Regelpfade des aktuellen Nutzers geschrieben.

AIRGAP_CLINE_HOME wird beim Sync auf den absoluten Pfad dieser Umgebung gesetzt.

Pflicht fuer Cline:

- Vor jeder Aufgabe `AGENTS.md` und `ENVIRONMENT.md` aus AIRGAP_CLINE_HOME lesen.
- Zentrale Regeln, Workflows, Skills und Helper aus AIRGAP_CLINE_HOME verwenden.
- Keine Provider-, Modell-, Authentifizierungs- oder KI-Serverdaten veraendern.
"@

    if ($Env.Os -eq "Windows") {
        Write-TextFile "$base/scripts/New-AirgapClineUserWorkspace.ps1" (Get-PowerShellNewUserScript -Env $Env)
        Write-TextFile "$base/scripts/Sync-ClineGlobalStubs.ps1" (Get-PowerShellSyncScript -Env $Env)
        Write-TextFile "$base/scripts/Initialize-AirgapClineEnvironment.ps1" (Get-PowerShellInitializeScript -Env $Env)
        Write-TextFile "$base/scripts/Register-ExternalWorkspace.ps1" (Get-PowerShellRegisterScript)
        Write-TextFile "$base/scripts/Test-AirgapOwner.ps1" (Get-PowerShellGuardScript)
        Write-TextFile "$base/scripts/Test-AirgapClineEnvironment.ps1" (Get-PowerShellTestScript)
        Write-TextFile "$base/shared/helpers/powershell/README.md" "# PowerShell Helper`n`nWindows-spezifische Helper liegen zentral in diesem Ordner. Nutze Skripte ueber den Zentralpfad und schreibe Ausgaben nach `workspaces/<hash>/helper-output/`.`n"
    } else {
        Write-TextFile "$base/scripts/initialize-airgap-cline-environment.sh" (Get-PosixScript -Kind "init" -Env $Env)
        Write-TextFile "$base/scripts/new-airgap-cline-user-workspace.sh" (Get-PosixScript -Kind "newuser" -Env $Env)
        Write-TextFile "$base/scripts/sync-cline-global-stubs.sh" (Get-PosixScript -Kind "sync" -Env $Env)
        Write-TextFile "$base/scripts/register-external-workspace.sh" (Get-PosixScript -Kind "register" -Env $Env)
        Write-TextFile "$base/scripts/guard-owner.sh" (Get-PosixScript -Kind "guard" -Env $Env)
        Write-TextFile "$base/scripts/test-airgap-cline-environment.sh" (Get-PosixScript -Kind "test" -Env $Env)
        Write-TextFile "$base/shared/helpers/posix/README.md" "# POSIX Helper`n`nPOSIX-kompatible Helper liegen zentral in diesem Ordner. Skripte koennen mit `sh scripts/name.sh` ausgefuehrt werden, falls ein Archiv keine Executable-Bits erhaelt.`n"
        if ($Env.Os -in @("Linux", "Mac")) {
            Write-TextFile "$base/shared/helpers/bash/README.md" "# Bash Helper`n`nBash-nahe Helper fuer $($Env.Os) liegen zentral in diesem Ordner.`n"
        }
    }
}

foreach ($Env in $Environments) {
    $base = Join-Path $RepoRoot "environments/$($Env.Name)"
    $hashTargets = @("START_HIER.md", "ENVIRONMENT.md", "AGENTS.md", "MANIFEST.json", "VERSION")
    $lines = foreach ($file in $hashTargets) {
        $path = Join-Path $base $file
        $hash = Get-FileHash -LiteralPath $path -Algorithm SHA256
        "$($hash.Hash.ToLowerInvariant())  $file"
    }
    Write-TextFile "environments/$($Env.Name)/SHA256SUMS.txt" (($lines -join "`n") + "`n")
}

Write-Host "v0.2-Erweiterungen angewendet: $RepoRoot"
