[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$Version = "0.1.0"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = Split-Path -Parent $ScriptDir
}
$RepoRoot = [System.IO.Path]::GetFullPath($RootPath)
$Today = (Get-Date).ToString("yyyy-MM-dd")

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

    $normalized = $Content.TrimStart("`r", "`n")
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($target, $normalized, $utf8NoBom)
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
    return ($Object | ConvertTo-Json -Depth 20)
}

function Get-VariantDescription {
    param([string]$Os, [string]$Role)

    $mode = if ($Role -eq "Admin") { "Admin-Variante fuer zentrale Ablage auf Maschinen- oder Share-Ebene." } else { "User-Variante ohne Adminrechte fuer Home, Desktop oder Netzwerkshare." }
    switch ($Os) {
        "Windows" { return "$mode Primaer fuer VS Code mit installierter Cline Extension." }
        "Linux" { return "$mode Primaer fuer Cline CLI auf Linux." }
        "Mac" { return "$mode Fuer macOS mit Cline CLI oder editornahem Cline-Betrieb." }
        "Solaris" { return "$mode POSIX-best-effort fuer Solaris, sofern Cline bereits lauffaehig ist." }
        default { return $mode }
    }
}

function Get-Family {
    param([string]$Os)
    switch ($Os) {
        "Windows" { "windows" }
        "Linux" { "linux" }
        "Mac" { "mac" }
        "Solaris" { "solaris" }
    }
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

Write-TextFile ".gitattributes" @'
* text=auto eol=lf
*.ps1 text eol=crlf
*.cmd text eol=crlf
*.sh text eol=lf
*.md text eol=lf
*.json text eol=lf
*.yml text eol=lf
'@

Write-TextFile ".gitignore" @'
# Lokale Codex- und Agenten-Arbeitsdaten
.codex/
.agents/
codex_sessions/
rollout_summaries/
memory_exports/
CODEX_LOCAL.md
CODEX_NOTES.md
*.codex.md
*.local.md

# Laufzeitdaten der exportierbaren Umgebungen
**/state/*
!**/state/.gitkeep
**/logs/*
!**/logs/.gitkeep
**/audit/*
!**/audit/.gitkeep
**/users/*
!**/users/.gitkeep
!**/users/**/.gitkeep
**/workspaces/*
!**/workspaces/.gitkeep
!**/workspaces/**/.gitkeep
**/workspaces/**/helper-output/*
!**/workspaces/**/helper-output/.gitkeep

# Release- und Build-Ausgaben
dist/
release/
*.7z
*.zip
*.tar
*.tar.gz
*.tgz
*.nupkg

# Drittanbieter-Binaries und Installer duerfen nicht ins Repo
*.exe
*.msi
*.msix
*.appx
*.vsix
*.dmg
*.pkg
*.deb
*.rpm
*.AppImage

# KI-Modelle, grosse Daten und Caches
*.gguf
*.safetensors
*.onnx
*.bin
*.pt
*.pth
*.ckpt
*.sqlite
*.parquet
*.cache
node_modules/
.venv/
venv/
__pycache__/
.pytest_cache/

# Lokale Betriebssystem-/Editor-Dateien
.DS_Store
Thumbs.db
desktop.ini
.idea/
.vscode/*
!.vscode/extensions.json
'@

Write-TextFile ".clineignore" @'
# Diese Root-Datei schuetzt das Repo selbst vor unnoetigem Kontext.
dist/
release/
node_modules/
.venv/
venv/
**/__pycache__/
**/.pytest_cache/

# Laufzeitdaten der exportierbaren Umgebungen
**/users/**
**/workspaces/**
**/state/**
**/logs/**
**/audit/**

# Generierte Archive und fremde Binaries
*.7z
*.zip
*.exe
*.msi
*.vsix
*.dmg
*.pkg
*.deb
*.rpm
*.gguf
*.safetensors
*.onnx
'@

Write-TextFile "README.md" @"
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

## Wichtig

- Ziel ist eine zentrale, wiederverwendbare Air-Gap-Ausgangsumgebung.
- Regeln, Workflows, Skills und Helper bleiben im zentralen Umgebungsordner.
- Externe Repos werden nicht mit Cline-Regeln, Workflows oder Helper-Dateien verschmutzt, ausser der Nutzer verlangt es ausdruecklich.
- Nutzer- und Agentenordner werden ueber `OWNER.json` und Pflichtregeln getrennt.
- Release-Pakete enthalten keine Cline-Installer, keine KI-Modelle und keine Drittanbieter-Binaries.

## Release-Artefakte

Pro Version werden `.7z`- und `.zip`-Pakete pro Umgebung sowie Gesamtpakete erzeugt. Die Skripte liegen unter `scripts/`.
"@

Write-TextFile "START_HIER.md" @'
# Start Hier

Dieses Repo enthaelt mehrere exportierbare Cline-Ausgangsumgebungen. Verwende nicht den Repo-Root als dauerhafte Umgebung, sondern waehle einen konkreten Ordner unter `environments/`.

Beispiel:

```text
Initialisiere dich ueber folgenden Pfad: C:\Cline_AirGap\Cline_Env_Windows_User
```

oder:

```text
Initialisiere dich ueber folgenden Pfad: /opt/cline-airgap/Cline_Env_Linux_Admin
```

Cline muss bereits installiert und funktionsfaehig eingerichtet sein. Dieses Projekt konfiguriert keine Provider und keine Modellserver.
'@

Write-TextFile "ARCHITEKTUR.md" @'
# Architektur

Die Air-Gap-Cline-Umgebung ist ein zentraler Startpfad fuer Cline. Dieser Pfad enthaelt Regeln, Workflows, Skills und Helper-Skripte. Cline soll diese zentrale Umgebung als Quelle der Wahrheit verwenden, auch wenn spaeter in beliebigen externen Repos, Desktop-Ordnern oder Netzwerkshares gearbeitet wird.

## Grundprinzipien

- Cline ist bereits installiert und KI-faehig eingerichtet.
- Die Umgebung veraendert keine Provider-, Modell- oder Authentifizierungsdaten.
- Der zentrale Umgebungsordner ist exportierbar.
- Nutzer- und Agentendaten werden lokal in `users/` erzeugt.
- Externe Arbeitsordner werden in `workspaces/` registriert.
- Helper bleiben zentral und werden nicht in Zielrepos kopiert.

## Varianten

Es gibt je OS eine User- und Admin-Variante. User-Varianten arbeiten ohne Adminrechte und schreiben nur in Benutzerpfade. Admin-Varianten duerfen zentrale Ablagen vorbereiten, bleiben aber ebenfalls provider-neutral.
'@

Write-TextFile "SECURITY.md" @'
# Sicherheitsrichtlinie

## Grundsatz

Dieses Projekt liefert Cline-Regeln, Workflows, Skills und lokale Helper-Skripte. Es enthaelt keine Geheimnisse, keine Provider-Konfiguration und keine Drittanbieter-Binaries.

## Sicherheitsmeldungen

Bitte melde Sicherheitsprobleme nicht in oeffentlichen Issues, wenn sie konkrete Schwachstellen, Tokens, interne Pfade oder missbrauchbare Details enthalten. Nutze stattdessen einen privaten Kontaktweg des Repository-Betreibers.

## Air-Gap-Hinweise

- Keine Datei in diesem Repo darf verlangen, dass in der Zielumgebung Internetzugriff besteht.
- Provider-, API-Key- und Modellserverkonfigurationen sind ausserhalb dieses Projekts zu verwalten.
- Cline-Agenten muessen fremde Nutzer- und Agentenordner respektieren.
'@

Write-TextFile "CONTRIBUTING.md" @'
# Mitwirken

Beitraege sollen deutsch dokumentiert sein und die exportierbaren Umgebungen nicht von Generatorquellen abhaengig machen.

## Regeln

- Keine Drittanbieter-Installer, VSIX-Dateien, KI-Modelle oder Archive ins Repo einchecken.
- Jede exportierbare Umgebung muss fuer sich allein verstaendlich und nutzbar bleiben.
- Aenderungen an gemeinsamen Regeln muessen in allen acht Umgebungen synchronisiert werden.
- Tests unter `scripts/Test-AllEnvironmentPackages.ps1` muessen erfolgreich laufen.
'@

Write-TextFile "CODE_OF_CONDUCT.md" @'
# Verhaltenskodex

Dieses Projekt erwartet sachliche, respektvolle und technisch nachvollziehbare Zusammenarbeit. Beitraege sollen das Ziel einer sicheren, air-gap-faehigen Cline-Ausgangsumgebung unterstuetzen.
'@

Write-TextFile "LIZENZ-HINWEISE.md" @'
# Lizenzhinweise

Die Projektquellen stehen unter der im `LICENSE`-Dokument angegebenen Lizenz. Drittanbieter-Installer, Cline-Erweiterungen, KI-Modelle und sonstige fremde Binaries sind nicht Bestandteil dieses Repos und werden nicht ueber dieses Repo verteilt.
'@

Write-TextFile "LICENSE" @'
MIT License

Copyright (c) 2026 Adrian Weidig

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
'@

Write-TextFile "AGENTS.md" @'
# Agentenanweisungen fuer dieses Repo

- Dieses Repo erzeugt exportierbare Cline-Umgebungen.
- Cline ist Voraussetzung und wird nicht durch dieses Repo installiert oder als Provider konfiguriert.
- Keine Drittanbieter-Binaries, Installer, VSIX-Dateien, Modelle oder generierten Archive einchecken.
- Codex-spezifische lokale Notizen und Laufzeitdaten muessen ignoriert bleiben.
- Exportierbare Umgebungen duerfen nicht zwingend von `src/common` oder anderen Generatorquellen abhaengen.
- Dokumentation und Nutzertexte sind deutsch.
'@

Write-TextFile ".github/PULL_REQUEST_TEMPLATE.md" @'
## Aenderung

## Geprueft

- [ ] `scripts/Test-AllEnvironmentPackages.ps1`
- [ ] Keine Binaries oder Archive eingecheckt
- [ ] Alle acht Umgebungen bleiben exportierbar
'@

Write-TextFile ".github/ISSUE_TEMPLATE/fehlerbericht.md" @'
---
name: Fehlerbericht
about: Fehler in einer Air-Gap-Cline-Umgebung melden
title: "[Fehler]: "
labels: bug
---

## Umgebung

Welche `Cline_Env_*`-Variante wurde verwendet?

## Beschreibung

## Erwartetes Verhalten

## Tatsächliches Verhalten
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
      - name: Test environments
        shell: pwsh
        run: ./scripts/Test-AllEnvironmentPackages.ps1
      - name: Build packages
        shell: pwsh
        run: ./scripts/Build-AllEnvironmentPackages.ps1 -Version "0.1.0-ci" -SkipTests
'@

Write-TextFile "VERSION" "$Version`n"

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
$forbiddenExtensions = @(".exe", ".msi", ".msix", ".appx", ".vsix", ".dmg", ".pkg", ".deb", ".rpm", ".7z", ".zip", ".gguf", ".safetensors", ".onnx")

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

    Get-Content -LiteralPath (Join-Path $envRoot "MANIFEST.json") -Raw | ConvertFrom-Json | Out-Null

    $badRef = Get-ChildItem -LiteralPath $envRoot -Recurse -File |
        Where-Object { $_.FullName -notmatch "\\users\\|/users/" -and $_.FullName -notmatch "\\state\\|/state/" } |
        Select-String -Pattern "\.\./src/common" -SimpleMatch -ErrorAction SilentlyContinue
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
$mustContain = @(".codex/", ".agents/", "CODEX_LOCAL.md", "CODEX_NOTES.md", "*.codex.md", "*.local.md", "!**/users/**/.gitkeep", "!**/state/.gitkeep")
foreach ($entry in $mustContain) {
    if ($gitignore -notlike "*$entry*") {
        throw ".gitignore enthaelt Pflichtmuster nicht: $entry"
    }
}

Write-Host "Alle exportierbaren Umgebungen sind valide."
'@

Write-TextFile "scripts/New-ReleaseManifest.ps1" @'
[CmdletBinding()]
param(
    [string]$DistPath = "",
    [string]$Version = "0.1.0"
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

$files = Get-ChildItem -LiteralPath $DistPath -File | Sort-Object Name | ForEach-Object {
    $hash = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
    [ordered]@{
        name = $_.Name
        size = $_.Length
        sha256 = $hash.Hash.ToLowerInvariant()
    }
}

$manifest = [ordered]@{
    version = $Version
    generatedAt = (Get-Date).ToString("o")
    files = $files
}

$json = $manifest | ConvertTo-Json -Depth 10
$manifestPath = Join-Path $DistPath "RELEASE_MANIFEST.json"
[System.IO.File]::WriteAllText($manifestPath, $json, (New-Object System.Text.UTF8Encoding($false)))

$sumPath = Join-Path $DistPath "SHA256SUMS.txt"
$lines = foreach ($file in (Get-ChildItem -LiteralPath $DistPath -File | Sort-Object Name)) {
    if ($file.Name -eq "SHA256SUMS.txt") { continue }
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
    [string]$Version = "0.1.0",
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

try {
    $envRoot = Join-Path $RepoRoot "environments"
    $envs = Get-ChildItem -LiteralPath $envRoot -Directory -Filter "Cline_Env_*" | Sort-Object Name

    foreach ($env in $envs) {
        $stage = Join-Path $stageRoot $env.Name
        Copy-CleanTree -Source $env.FullName -Destination $stage

        $zipPath = Join-Path $OutputPath ("{0}_v{1}_{2}.zip" -f $env.Name, $Version, $Date)
        $sevenPath = Join-Path $OutputPath ("{0}_v{1}_{2}.7z" -f $env.Name, $Version, $Date)

        Compress-Archive -Path $stage -DestinationPath $zipPath -Force
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
    & $SevenZip a -t7z $all7z $allStage | Out-Null
    & $SevenZip t $all7z | Out-Null

    & (Join-Path $PSScriptRoot "New-ReleaseManifest.ps1") -DistPath $OutputPath -Version $Version

    $notes = @"
# Release v$Version

Dieses Release enthaelt pro exportierbarer Air-Gap-Cline-Umgebung je ein `.7z`- und `.zip`-Paket sowie ein Gesamtpaket.

Cline muss vor der Nutzung bereits installiert, eingerichtet und mit dem gewuenschten KI-Server verbunden sein. Diese Pakete enthalten keine Provider-, Modell- oder Authentifizierungsdaten.
"@
    [System.IO.File]::WriteAllText((Join-Path $OutputPath "RELEASE_NOTES_DE.md"), $notes, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Pakete erstellt in: $OutputPath"
}
finally {
    if (Test-Path -LiteralPath $stageRoot) {
        Remove-Item -LiteralPath $stageRoot -Recurse -Force
    }
}
'@

function Get-EnvironmentStartText {
    param($Env)
    $scriptHint = if ($Env.Os -eq "Windows") { ".\scripts\Initialize-AirgapClineEnvironment.ps1" } else { "./scripts/initialize-airgap-cline-environment.sh" }
    return @"
# Start Hier: $($Env.Name)

Diese Umgebung ist eine exportierbare Air-Gap-Cline-Ausgangsumgebung.

## Voraussetzung

Cline ist bereits installiert, eingerichtet und mit dem gewuenschten KI-Server verbunden. Diese Umgebung veraendert keine Provider-, Modell- oder Authentifizierungsdaten.

## Initialisierung durch Cline

Gib Cline diesen Auftrag:

```text
Initialisiere dich ueber folgenden Pfad: <vollstaendiger Pfad zu diesem Ordner>
```

Cline muss dann in dieser Reihenfolge lesen:

1. `START_HIER.md`
2. `AGENTS.md`
3. `ENVIRONMENT.md`
4. `shared/rules/00-airgap-grundsaetze.md`

## Lokales Setup

Falls Cline ein Skript ausfuehren soll, ist fuer diese Variante vorgesehen:

```text
$scriptHint
```

Das Skript erzeugt den eigenen Nutzer-/Agentenordner, synchronisiert globale Cline-Stubs und schreibt `state/bootstrap-status.json`. Es darf keine Provider- oder KI-Server-Konfiguration aendern.
"@
}

function Get-EnvironmentDoc {
    param($Env)
    return @"
# Umgebung: $($Env.Name)

| Feld | Wert |
| --- | --- |
| OS | $($Env.Os) |
| Berechtigungsmodell | $($Env.Role) |
| Primaerer Modus | $($Env.Primary) |
| Empfohlener Ablageort | `$($Env.RecommendedPath)` |

$(Get-VariantDescription -Os $Env.Os -Role $Env.Role)

## Grenzen

- Cline muss bereits funktionsfaehig vorhanden sein.
- Keine Provider-, Modell- oder Authentifizierungsdaten werden geaendert.
- Die Umgebung ist ein zentraler Startpfad fuer Regeln, Workflows, Skills und Helper.
- Externe Repos sollen nicht mit Cline-Hilfsdateien verschmutzt werden.

## Solaris-Hinweis

Solaris-Varianten sind POSIX-best-effort. Nutze sie nur, wenn Cline, Node und die benoetigte Shell-Umgebung dort bereits lauffaehig sind.
"@
}

function Get-AgentsText {
    param($Env)
    return @"
# Agentenanweisungen: $($Env.Name)

Diese Datei muss von Cline-Agenten immer gelesen werden, bevor in dieser Umgebung oder mit dieser Umgebung gearbeitet wird.

## Pflichten

- Behandle diesen Ordner als `AIRGAP_CLINE_HOME`.
- Lies vor Schreibarbeit `ENVIRONMENT.md` und alle relevanten Regeln unter `shared/rules/`.
- Schreibe Nutzer- und Agentendaten nur unter `users/` fuer den aktuellen Nutzer.
- Pruefe `OWNER.json`, bevor du in existierende Nutzer- oder Agentenordner schreibst.
- Wenn `OWNER.json` nicht zum aktuellen Nutzer passt, schreibe nicht in diesen Ordner.
- Verwende zentrale Helper aus `shared/helpers/`; kopiere sie nicht in Zielrepos.
- Lege in externen Repos keine dauerhaften `.cline`, `.clinerules`, Skills, Workflows oder Helper an, ausser der Nutzer verlangt es ausdruecklich.
- Veraendere keine Provider-, Modell-, Auth- oder KI-Server-Konfiguration.

## Plattform

- OS: $($Env.Os)
- Variante: $($Env.Role)
- Primaerer Modus: $($Env.Primary)
"@
}

function Get-EnvironmentClineIgnore {
    return @'
users/**
workspaces/**
state/**
logs/**
audit/**
**/__pycache__/
**/.pytest_cache/
*.7z
*.zip
*.exe
*.msi
*.vsix
*.dmg
*.pkg
*.deb
*.rpm
*.gguf
*.safetensors
*.onnx
'@
}

$Rules = @{
    "00-airgap-grundsaetze.md" = @'
# Air-Gap-Grundsaetze

- Gehe davon aus, dass die Zielumgebung keinen Internetzugriff hat.
- Versuche keine Downloads, Marketplace-Installationen oder Cloud-Abfragen.
- Wenn ein benoetigtes Artefakt fehlt, melde es konkret und arbeite nicht mit geratenen Ersatzdaten.
- Cline selbst ist bereits eingerichtet; Provider und KI-Server werden nicht durch diese Umgebung veraendert.
'@
    "10-zentralpfad-ist-quell-der-wahrheit.md" = @'
# Zentralpfad Ist Quelle Der Wahrheit

- Der aktuelle `Cline_Env_*`-Ordner ist `AIRGAP_CLINE_HOME`.
- Regeln, Workflows, Skills und Helper kommen aus diesem zentralen Pfad.
- Wenn in externen Repos gearbeitet wird, bleiben Cline-Hilfsdateien im Zentralpfad.
- Globale Cline-Stubs duerfen nur auf diesen Zentralpfad verweisen.
'@
    "20-nutzer-und-agententrennung.md" = @'
# Nutzer- Und Agententrennung

- Vor Schreibarbeit in `users/` muss `OWNER.json` geprueft werden.
- Wenn Owner-Daten nicht zum aktuellen Nutzer passen, nicht schreiben.
- Jeder Agent arbeitet in einem eigenen Agentenordner.
- Fremde Agentenordner duerfen nur als Kontext gelesen werden, wenn der Mensch es explizit verlangt.
'@
    "30-keine-repo-verschmutzung.md" = @'
# Keine Repo-Verschmutzung

- Lege keine dauerhaften `.cline`, `.clinerules`, Skills, Workflows oder Helper in Zielrepos an.
- Zentrale Metadaten zu Zielrepos gehoeren nach `workspaces/<hash>/`.
- Fachliche Projektdateien duerfen geaendert werden, wenn die Nutzeraufgabe es verlangt.
- Temporäre Analyseausgaben gehoeren in den zentralen Workspace-Metadatenordner.
'@
    "40-zentrale-helper-nutzen.md" = @'
# Zentrale Helper Nutzen

- Python-Helfer liegen unter `shared/helpers/python/`.
- PowerShell-, Bash- und POSIX-Helfer liegen unter `shared/helpers/`.
- Helper-Ausgaben sollen in `workspaces/<hash>/helper-output/` geschrieben werden.
- Wenn ein Helper fehlt oder nicht passt, frage den Nutzer, bevor du neue dauerhafte Helper anlegst.
'@
    "50-verifikation-und-dokumentation.md" = @'
# Verifikation Und Dokumentation

- Melde Arbeit erst als fertig, wenn passende Checks ausgefuehrt oder nachvollziehbar begruendet wurden.
- Dokumentiere zentrale Entscheidungen in deutschen Markdown-Dateien.
- Schreibe Abschlussstatus in den eigenen Agentenordner oder in den passenden Workspace-Metadatenordner.
'@
}

$Workflows = @{
    "00-initialisierung.md" = @'
# Initialisierung

1. Lies `START_HIER.md`, `AGENTS.md` und `ENVIRONMENT.md`.
2. Erkenne Betriebssystem, Nutzer und aktuellen Pfad.
3. Fuehre das passende Initialisierungsskript aus oder erklaere die manuelle Ausfuehrung.
4. Pruefe `state/bootstrap-status.json`.
5. Bestaetige, dass Provider- und Modellkonfiguration nicht veraendert wurden.
'@
    "01-zentralstubs-synchronisieren.md" = @'
# Zentralstubs Synchronisieren

1. Bestimme `AIRGAP_CLINE_HOME`.
2. Schreibe globale Regel-Stubs in die benutzereigenen Cline-Pfade.
3. Synchronisiere Workflows und Skills aus dem Zentralpfad.
4. Nutze Kopien, wenn Links nicht moeglich sind.
'@
    "02-nutzerordner-anlegen.md" = @'
# Nutzerordner Anlegen

1. Erkenne Nutzer, Host und OS.
2. Erzeuge den passenden Ordner unter `users/`.
3. Schreibe `OWNER.json` und `IMMER_LESEN.md`.
4. Erzeuge einen neuen Agentenordner mit `AGENT_POLICY.md`.
'@
    "10-externer-arbeitsordner-registrieren.md" = @'
# Externen Arbeitsordner Registrieren

1. Nimm den Zielpfad entgegen.
2. Normalisiere und hashe den Pfad.
3. Erzeuge `workspaces/<hash>/WORKSPACE.json`.
4. Schreibe Notizen und Helper-Ausgaben nur in diesen zentralen Ordner.
'@
    "20-klassische-aufgabe-bearbeiten.md" = @'
# Klassische Aufgabe Bearbeiten

1. Verstehe Ziel und Arbeitsordner.
2. Registriere externe Arbeitsordner zentral.
3. Nutze zentrale Regeln und Helper.
4. Aendere nur fachlich benoetigte Dateien im Ziel.
5. Fuehre passende Checks aus.
'@
    "30-helper-script-nutzen.md" = @'
# Helper-Script Nutzen

1. Suche Helper zuerst unter `shared/helpers/`.
2. Fuehre Helper aus dem Zentralpfad aus.
3. Schreibe Ausgaben nach `workspaces/<hash>/helper-output/`.
4. Kopiere Helper nicht in das Zielrepo.
'@
    "40-airgap-abnahme.md" = @'
# Air-Gap-Abnahme

1. Pruefe, ob alle benoetigten Dateien lokal vorhanden sind.
2. Suche nach Internet-, Download- oder Marketplace-Annahmen.
3. Melde fehlende Artefakte konkret.
4. Dokumentiere den Abnahmestatus.
'@
    "90-selbstverbesserung.md" = @'
# Selbstverbesserung

1. Sammle wiederkehrende Probleme.
2. Schlage Verbesserungen an Regeln, Workflows oder Skills vor.
3. Aendere zentrale Vorgaben nur nach expliziter Zustimmung des Nutzers.
'@
}

$SkillDescriptions = @{
    "airgap-bootstrap" = "Initialisiert eine exportierbare Air-Gap-Cline-Umgebung aus einem gegebenen Zentralpfad."
    "plattform-variante" = "Erkennt OS und User/Admin-Variante und waehlt passende Skripte und Pfade."
    "nutzer-agenten-schutz" = "Prueft OWNER.json und schuetzt fremde Nutzer- und Agentenordner vor Schreibzugriffen."
    "externer-arbeitsordner" = "Registriert externe Repos, Desktop-Ordner oder Shares zentral unter workspaces."
    "zentrale-helper" = "Nutzt zentrale Helper-Skripte ohne Zielrepos mit Hilfsdateien zu verschmutzen."
    "airgap-validierung" = "Prueft, ob eine Aufgabe ohne Internetannahmen und mit lokalen Artefakten abgeschlossen ist."
}

function Get-SkillText {
    param([string]$Name, [string]$Description)
    return @"
---
name: $Name
description: $Description
---

# $Name

## Zweck

$Description

## Vorgehen

1. Lies zuerst `AGENTS.md` und `ENVIRONMENT.md` im aktuellen `AIRGAP_CLINE_HOME`.
2. Beachte die Regeln unter `shared/rules/`.
3. Arbeite mit zentralen Helpern und zentralen Workspace-Metadaten.
4. Veraendere keine Provider-, Modell- oder Authentifizierungsdaten.

## Ergebnis

Dokumentiere das Ergebnis im eigenen Agentenordner oder im passenden `workspaces/<hash>/`-Ordner.
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
---
name: $skillName
description: Plattformskill fuer $($Env.Name) mit Fokus auf $($Env.Primary).
---

# $skillName

Diese Umgebung ist `$($Env.Name)`.

## Plattformregeln

- OS: $($Env.Os)
- Berechtigungsmodell: $($Env.Role)
- Primaerer Modus: $($Env.Primary)
- Empfohlener Ablageort: `$($Env.RecommendedPath)`

Nutze die Skripte unter `scripts/` dieser Umgebung und beachte, dass Cline bereits eingerichtet ist.
"@
    }
}

function Get-PythonHelper {
    return @'
#!/usr/bin/env python3
"""Registriert externe Arbeitsordner zentral unter workspaces/<hash>."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from datetime import datetime, timezone
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description="Externen Arbeitsordner registrieren")
    parser.add_argument("--root", required=True, help="AIRGAP_CLINE_HOME")
    parser.add_argument("--target", required=True, help="Externer Arbeitsordner")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    target = Path(args.target).resolve()
    digest = hashlib.sha256(str(target).encode("utf-8")).hexdigest()[:24]
    workspace = root / "workspaces" / digest
    (workspace / "helper-output").mkdir(parents=True, exist_ok=True)

    data = {
        "targetPath": str(target),
        "hash": digest,
        "createdAt": datetime.now(timezone.utc).isoformat(),
        "createdBy": os.environ.get("USERNAME") or os.environ.get("USER") or "unknown",
    }
    (workspace / "WORKSPACE.json").write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    (workspace / "NOTIZEN.md").write_text("# Notizen\n\n", encoding="utf-8")
    (workspace / "RULE_OVERRIDES.md").write_text("# Optionale arbeitsordnerspezifische Hinweise\n\n", encoding="utf-8")
    print(str(workspace))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
'@
}

function Get-PowerShellNewUserScript {
    param($Env)
    return @"
[CmdletBinding()]
param(
    [string]`$RootPath = ""
)

Set-StrictMode -Version Latest
`$ErrorActionPreference = "Stop"

`$ScriptDir = if (`$PSScriptRoot) { `$PSScriptRoot } else { Split-Path -Parent `$MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace(`$RootPath)) {
    `$RootPath = (Resolve-Path (Join-Path `$ScriptDir "..")).Path
}
`$root = [System.IO.Path]::GetFullPath(`$RootPath)
`$domain = if (`$env:USERDOMAIN) { `$env:USERDOMAIN } else { `$env:COMPUTERNAME }
`$user = if (`$env:USERNAME) { `$env:USERNAME } else { [Environment]::UserName }
`$safe = ((`$domain + "_" + `$user) -replace "[^A-Za-z0-9_.-]", "_").ToLowerInvariant()
`$userRoot = Join-Path `$root "users/$($Env.Family)/`$safe"
`$agentId = (Get-Date).ToString("yyyyMMdd-HHmmss") + "-" + ([guid]::NewGuid().ToString("N").Substring(0, 8))
`$agentRoot = Join-Path `$userRoot "agents/`$agentId"

New-Item -ItemType Directory -Force -Path `$agentRoot, (Join-Path `$userRoot "scratch"), (Join-Path `$userRoot "notes"), (Join-Path `$userRoot "logs"), (Join-Path `$userRoot "outbox") | Out-Null

`$ownerPath = Join-Path `$userRoot "OWNER.json"
if (Test-Path -LiteralPath `$ownerPath) {
    `$existing = Get-Content -LiteralPath `$ownerPath -Raw | ConvertFrom-Json
    if (`$existing.username -ne `$user) {
        throw "OWNER.json gehoert nicht zum aktuellen Nutzer: `$ownerPath"
    }
}

`$owner = [ordered]@{
    os = "$($Env.Os)"
    role = "$($Env.Role)"
    domain = `$domain
    username = `$user
    computerName = `$env:COMPUTERNAME
    createdAt = (Get-Date).ToString("o")
}
`$owner | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath `$ownerPath -Encoding UTF8

Set-Content -LiteralPath (Join-Path `$userRoot "IMMER_LESEN.md") -Encoding UTF8 -Value "# Immer Lesen`n`nDieser Ordner gehoert zu `$domain\`$user. Wenn du nicht dieser Nutzer bist, schreibe nicht in diesen Ordner.`n"
Set-Content -LiteralPath (Join-Path `$agentRoot "AGENT_POLICY.md") -Encoding UTF8 -Value "# Agent Policy`n`nArbeite nur fuer den Owner dieses Nutzerordners. Nutze zentrale Helper aus AIRGAP_CLINE_HOME.`n"
Set-Content -LiteralPath (Join-Path `$agentRoot "CURRENT_TASK.md") -Encoding UTF8 -Value "# Aktuelle Aufgabe`n`nNoch keine Aufgabe dokumentiert.`n"
Set-Content -LiteralPath (Join-Path `$agentRoot "WORKSPACE_BINDINGS.json") -Encoding UTF8 -Value "{}"

`$stateDir = Join-Path `$root "state"
New-Item -ItemType Directory -Force -Path `$stateDir | Out-Null
@{
    userRoot = `$userRoot
    agentRoot = `$agentRoot
    agentId = `$agentId
    updatedAt = (Get-Date).ToString("o")
} | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path `$stateDir "last-agent.json") -Encoding UTF8

Write-Host `$agentRoot
"@
}

function Get-PowerShellSyncScript {
    param($Env)
    return @"
[CmdletBinding()]
param(
    [string]`$RootPath = ""
)

Set-StrictMode -Version Latest
`$ErrorActionPreference = "Stop"

`$ScriptDir = if (`$PSScriptRoot) { `$PSScriptRoot } else { Split-Path -Parent `$MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace(`$RootPath)) {
    `$RootPath = (Resolve-Path (Join-Path `$ScriptDir "..")).Path
}
`$root = [System.IO.Path]::GetFullPath(`$RootPath)
`$stub = "# Air-Gap-Cline-Zentralumgebung`n`nAIRGAP_CLINE_HOME: `````$root`````n`nVor jeder Aufgabe: lies `````$root\AGENTS.md``````, `````$root\ENVIRONMENT.md`````` und die Regeln unter `````$root\shared\rules``````. Veraendere keine Provider- oder Modellkonfiguration.`n"

`$targets = @(
    Join-Path `$HOME ".cline/rules/00-airgap-zentralumgebung.md"
)

if ("$($Env.Os)" -eq "Windows") {
    `$targets += Join-Path ([Environment]::GetFolderPath("MyDocuments")) "Cline/Rules/00-airgap-zentralumgebung.md"
}

foreach (`$target in `$targets) {
    `$parent = Split-Path -Parent `$target
    New-Item -ItemType Directory -Force -Path `$parent | Out-Null
    Set-Content -LiteralPath `$target -Encoding UTF8 -Value `$stub
}

`$workflowTarget = Join-Path `$HOME ".cline/data/workflows"
New-Item -ItemType Directory -Force -Path `$workflowTarget | Out-Null
Get-ChildItem -LiteralPath (Join-Path `$root "shared/workflows") -Filter "*.md" -File | ForEach-Object {
    Copy-Item -LiteralPath `$_.FullName -Destination `$workflowTarget -Force
}

`$skillsTarget = Join-Path `$HOME ".cline/skills"
New-Item -ItemType Directory -Force -Path `$skillsTarget | Out-Null
Get-ChildItem -LiteralPath (Join-Path `$root "shared/skills") -Directory | ForEach-Object {
    `$targetSkill = Join-Path `$skillsTarget `$_.Name
    if (Test-Path -LiteralPath `$targetSkill) {
        Remove-Item -LiteralPath `$targetSkill -Recurse -Force
    }
    Copy-Item -LiteralPath `$_.FullName -Destination `$targetSkill -Recurse -Force
}

Write-Host "Globale Cline-Stubs synchronisiert."
"@
}

function Get-PowerShellInitializeScript {
    param($Env)
    return @"
[CmdletBinding()]
param(
    [string]`$RootPath = "",
    [switch]`$NoGlobalStub
)

Set-StrictMode -Version Latest
`$ErrorActionPreference = "Stop"

`$ScriptDir = if (`$PSScriptRoot) { `$PSScriptRoot } else { Split-Path -Parent `$MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace(`$RootPath)) {
    `$RootPath = (Resolve-Path (Join-Path `$ScriptDir "..")).Path
}
`$root = [System.IO.Path]::GetFullPath(`$RootPath)
foreach (`$required in @("START_HIER.md", "AGENTS.md", "ENVIRONMENT.md", "MANIFEST.json")) {
    if (-not (Test-Path -LiteralPath (Join-Path `$root `$required))) {
        throw "Fehlende Pflichtdatei: `$required"
    }
}

`$agentRoot = & (Join-Path `$ScriptDir "New-AirgapClineUserWorkspace.ps1") -RootPath `$root
if (-not `$NoGlobalStub) {
    & (Join-Path `$ScriptDir "Sync-ClineGlobalStubs.ps1") -RootPath `$root
}

`$status = [ordered]@{
    environment = "$($Env.Name)"
    rootPath = `$root
    agentRoot = (`$agentRoot | Select-Object -Last 1)
    providerChanged = `$false
    initializedAt = (Get-Date).ToString("o")
}
`$stateDir = Join-Path `$root "state"
New-Item -ItemType Directory -Force -Path `$stateDir | Out-Null
`$status | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path `$stateDir "bootstrap-status.json") -Encoding UTF8

Write-Host "Initialisierung abgeschlossen fuer $($Env.Name)."
"@
}

function Get-PowerShellRegisterScript {
    return @'
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$TargetPath,
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

& $python.Source (Join-Path $RootPath "shared/helpers/python/register_workspace.py") --root $RootPath --target $TargetPath
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
$required = @("START_HIER.md", "AGENTS.md", "ENVIRONMENT.md", "MANIFEST.json", "shared/rules", "shared/workflows", "shared/skills", "shared/helpers/python")
foreach ($item in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $RootPath $item))) {
        throw "Fehlender Bestandteil: $item"
    }
}

$forbidden = Get-ChildItem -LiteralPath $RootPath -Recurse -File |
    Where-Object { $_.Extension.ToLowerInvariant() -in @(".exe", ".msi", ".vsix", ".7z", ".zip", ".gguf", ".safetensors") }
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
ROOT_PATH=${1:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}

for required in START_HIER.md AGENTS.md ENVIRONMENT.md MANIFEST.json; do
  if [ ! -f "$ROOT_PATH/$required" ]; then
    echo "Fehlende Pflichtdatei: $required" >&2
    exit 1
  fi
done

"$ROOT_PATH/scripts/new-airgap-cline-user-workspace.sh" "$ROOT_PATH" >/tmp/airgap-cline-agent-root.$$
"$ROOT_PATH/scripts/sync-cline-global-stubs.sh" "$ROOT_PATH"
AGENT_ROOT=$(cat /tmp/airgap-cline-agent-root.$$)
rm -f /tmp/airgap-cline-agent-root.$$
mkdir -p "$ROOT_PATH/state"
cat > "$ROOT_PATH/state/bootstrap-status.json" <<EOF
{
  "environment": "__ENV_NAME__",
  "rootPath": "$ROOT_PATH",
  "agentRoot": "$AGENT_ROOT",
  "providerChanged": false
}
EOF
echo "Initialisierung abgeschlossen fuer __ENV_NAME__."
'@
            return $template.Replace("__ENV_NAME__", $Env.Name)
        }
        "newuser" {
            $template = @'
#!/bin/sh
set -eu
ROOT_PATH=${1:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}
HOST_NAME=$(hostname 2>/dev/null || uname -n)
USER_NAME=${USER:-$(id -un 2>/dev/null || echo unknown)}
SAFE=$(printf "%s_%s" "$HOST_NAME" "$USER_NAME" | tr -c 'A-Za-z0-9_.-' '_')
USER_ROOT="$ROOT_PATH/users/__ENV_FAMILY__/$SAFE"
AGENT_ID=$(date '+%Y%m%d-%H%M%S')-$$
AGENT_ROOT="$USER_ROOT/agents/$AGENT_ID"
mkdir -p "$AGENT_ROOT" "$USER_ROOT/scratch" "$USER_ROOT/notes" "$USER_ROOT/logs" "$USER_ROOT/outbox"
cat > "$USER_ROOT/OWNER.json" <<EOF
{
  "os": "__ENV_OS__",
  "role": "__ENV_ROLE__",
  "host": "$HOST_NAME",
  "username": "$USER_NAME",
  "uid": "$(id -u 2>/dev/null || echo unknown)"
}
EOF
cat > "$USER_ROOT/IMMER_LESEN.md" <<EOF
# Immer Lesen

Dieser Ordner gehoert zu $HOST_NAME/$USER_NAME. Wenn du nicht dieser Nutzer bist, schreibe nicht in diesen Ordner.
EOF
cat > "$AGENT_ROOT/AGENT_POLICY.md" <<EOF
# Agent Policy

Arbeite nur fuer den Owner dieses Nutzerordners. Nutze zentrale Helper aus AIRGAP_CLINE_HOME.
EOF
printf "# Aktuelle Aufgabe\n\nNoch keine Aufgabe dokumentiert.\n" > "$AGENT_ROOT/CURRENT_TASK.md"
printf "{}\n" > "$AGENT_ROOT/WORKSPACE_BINDINGS.json"
mkdir -p "$ROOT_PATH/state"
printf "%s\n" "$AGENT_ROOT"
'@
            return $template.Replace("__ENV_FAMILY__", $Env.Family).Replace("__ENV_OS__", $Env.Os).Replace("__ENV_ROLE__", $Env.Role)
        }
        "sync" {
            return @'
#!/bin/sh
set -eu
ROOT_PATH=${1:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}
CLINE_HOME="${HOME}/.cline"
mkdir -p "$CLINE_HOME/rules" "$CLINE_HOME/data/workflows" "$CLINE_HOME/skills"
cat > "$CLINE_HOME/rules/00-airgap-zentralumgebung.md" <<EOF
# Air-Gap-Cline-Zentralumgebung

AIRGAP_CLINE_HOME: \`$ROOT_PATH\`

Vor jeder Aufgabe: lies \`$ROOT_PATH/AGENTS.md\`, \`$ROOT_PATH/ENVIRONMENT.md\` und die Regeln unter \`$ROOT_PATH/shared/rules\`. Veraendere keine Provider- oder Modellkonfiguration.
EOF
cp "$ROOT_PATH"/shared/workflows/*.md "$CLINE_HOME/data/workflows/"
for skill in "$ROOT_PATH"/shared/skills/*; do
  [ -d "$skill" ] || continue
  base=$(basename "$skill")
  rm -rf "$CLINE_HOME/skills/$base"
  cp -R "$skill" "$CLINE_HOME/skills/$base"
done
echo "Globale Cline-Stubs synchronisiert."
'@
        }
        "register" {
            return @'
#!/bin/sh
set -eu
if [ "$#" -lt 1 ]; then
  echo "Nutzung: register-external-workspace.sh <zielpfad> [root]" >&2
  exit 1
fi
TARGET_PATH=$1
ROOT_PATH=${2:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}
if command -v python3 >/dev/null 2>&1; then
  python3 "$ROOT_PATH/shared/helpers/python/register_workspace.py" --root "$ROOT_PATH" --target "$TARGET_PATH"
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
ROOT_PATH=${1:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)}
for item in START_HIER.md AGENTS.md ENVIRONMENT.md MANIFEST.json shared/rules shared/workflows shared/skills shared/helpers/python; do
  if [ ! -e "$ROOT_PATH/$item" ]; then
    echo "Fehlender Bestandteil: $item" >&2
    exit 1
  fi
done
find "$ROOT_PATH" \( -name '*.exe' -o -name '*.msi' -o -name '*.vsix' -o -name '*.7z' -o -name '*.zip' -o -name '*.gguf' -o -name '*.safetensors' \) -print | while IFS= read -r bad; do
  echo "Verbotene Datei in Umgebung: $bad" >&2
  exit 1
done
echo "Umgebung valide: $ROOT_PATH"
'@
        }
    }
}

foreach ($Env in $Environments) {
    $base = "environments/$($Env.Name)"
    Write-TextFile "$base/START_HIER.md" (Get-EnvironmentStartText -Env $Env)
    Write-TextFile "$base/ENVIRONMENT.md" (Get-EnvironmentDoc -Env $Env)
    Write-TextFile "$base/AGENTS.md" (Get-AgentsText -Env $Env)
    Write-TextFile "$base/.clineignore" (Get-EnvironmentClineIgnore)
    Write-TextFile "$base/VERSION" "$Version`n"

    $manifest = [ordered]@{
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
        selfContained = $true
    }
    Write-TextFile "$base/MANIFEST.json" (ConvertTo-JsonText $manifest)

    foreach ($dir in @("shared/rules", "shared/workflows", "shared/skills", "shared/helpers/python", "shared/helpers/powershell", "shared/helpers/bash", "shared/helpers/posix", "bootstrap", "scripts", "users", "workspaces", "state", "logs", "audit")) {
        Ensure-Directory "$base/$dir"
    }

    foreach ($ruleName in $Rules.Keys) {
        Write-TextFile "$base/shared/rules/$ruleName" $Rules[$ruleName]
    }
    Write-TextFile "$base/shared/rules/05-plattform-und-variante.md" @"
# Plattform Und Variante

- Umgebung: $($Env.Name)
- OS: $($Env.Os)
- Rolle: $($Env.Role)
- Primaerer Modus: $($Env.Primary)
- Empfohlener Ablageort: `$($Env.RecommendedPath)`

Nutze nur Skripte und Pfade, die zu dieser Variante passen. Cline ist bereits installiert und funktionsfaehig.
"@

    foreach ($workflowName in $Workflows.Keys) {
        Write-TextFile "$base/shared/workflows/$workflowName" $Workflows[$workflowName]
    }

    foreach ($skillName in $SkillDescriptions.Keys) {
        Write-TextFile "$base/shared/skills/$skillName/SKILL.md" (Get-SkillText -Name $skillName -Description $SkillDescriptions[$skillName])
    }
    $platformSkill = Get-PlatformSkillText -Env $Env
    Write-TextFile "$base/shared/skills/$($platformSkill.Name)/SKILL.md" $platformSkill.Text

    Write-TextFile "$base/shared/helpers/python/register_workspace.py" (Get-PythonHelper)

    Write-TextFile "$base/bootstrap/00-airgap-zentralumgebung.md" @"
# Air-Gap-Cline-Zentralumgebung

Dieser Stub wird bei der Initialisierung in den globalen Cline-Regelpfad des aktuellen Nutzers geschrieben.

AIRGAP_CLINE_HOME wird beim Sync auf den absoluten Pfad dieser Umgebung gesetzt.

Pflicht fuer Cline:

- Vor jeder Aufgabe `AGENTS.md` und `ENVIRONMENT.md` aus AIRGAP_CLINE_HOME lesen.
- Zentrale Regeln, Workflows, Skills und Helper aus AIRGAP_CLINE_HOME verwenden.
- Keine Provider-, Modell- oder Authentifizierungsdaten veraendern.
"@

    if ($Env.Os -eq "Windows") {
        Write-TextFile "$base/scripts/New-AirgapClineUserWorkspace.ps1" (Get-PowerShellNewUserScript -Env $Env)
        Write-TextFile "$base/scripts/Sync-ClineGlobalStubs.ps1" (Get-PowerShellSyncScript -Env $Env)
        Write-TextFile "$base/scripts/Initialize-AirgapClineEnvironment.ps1" (Get-PowerShellInitializeScript -Env $Env)
        Write-TextFile "$base/scripts/Register-ExternalWorkspace.ps1" (Get-PowerShellRegisterScript)
        Write-TextFile "$base/scripts/Test-AirgapClineEnvironment.ps1" (Get-PowerShellTestScript)
        Write-TextFile "$base/shared/helpers/powershell/README.md" "# PowerShell Helper`n`nWindows-spezifische Helper liegen zentral in diesem Ordner.`n"
    } else {
        Write-TextFile "$base/scripts/initialize-airgap-cline-environment.sh" (Get-PosixScript -Kind "init" -Env $Env)
        Write-TextFile "$base/scripts/new-airgap-cline-user-workspace.sh" (Get-PosixScript -Kind "newuser" -Env $Env)
        Write-TextFile "$base/scripts/sync-cline-global-stubs.sh" (Get-PosixScript -Kind "sync" -Env $Env)
        Write-TextFile "$base/scripts/register-external-workspace.sh" (Get-PosixScript -Kind "register" -Env $Env)
        Write-TextFile "$base/scripts/test-airgap-cline-environment.sh" (Get-PosixScript -Kind "test" -Env $Env)
        Write-TextFile "$base/shared/helpers/posix/README.md" "# POSIX Helper`n`nPOSIX-kompatible Helper liegen zentral in diesem Ordner.`n"
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

Write-Host "Umgebungen synchronisiert: $RepoRoot"
