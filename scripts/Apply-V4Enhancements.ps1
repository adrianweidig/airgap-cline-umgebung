[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$Version = "0.4.0"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = Split-Path -Parent $ScriptDir
}
$RepoRoot = [System.IO.Path]::GetFullPath($RootPath)
$V3 = Join-Path $ScriptDir "Apply-V3Enhancements.ps1"
if (-not (Test-Path -LiteralPath $V3 -PathType Leaf)) {
    throw "Fehlende Basis-Generatorquelle: $V3"
}

& $V3 -RootPath $RepoRoot -Version $Version

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

function ConvertTo-JsonText {
    param([Parameter(Mandatory = $true)]$Object)
    return ($Object | ConvertTo-Json -Depth 40)
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

function Get-FirstReadContract {
    param($Env)
    $template = @'
<!-- AIRGAP-CLINE-FIRST-READ:v1 -->
# First-Read-Vertrag: __ENV_NAME__

Diese Datei beschreibt das Verhalten nach dem ersten Bootstrap. Sie ist der erste fachliche Kontext, den Cline aus `AIRGAP_CLINE_HOME` lesen muss, bevor irgendeine Nutzeraufgabe bearbeitet wird.

## Pflichtstart Jeder Aufgabe

1. Loese `AIRGAP_CLINE_HOME` aus dem globalen Air-Gap-Stub auf.
2. Pruefe, dass dieser Pfad lesbar ist und zu `__ENV_NAME__` gehoert.
3. Lies immer zuerst diese Datei: `bootstrap/FIRST_READ.md`.
4. Lies danach `AGENTS.md`, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION` und alle Regeln unter `shared/rules/`.
5. Pruefe `state/bootstrap-status.json`, falls vorhanden. Wenn dort ein Fehlerstatus steht, bearbeite keine Zielworkspace-Aufgabe, bevor der Zustand geklaert ist.
6. Wenn ein externer Arbeitsordner verwendet wird, registriere oder finde ihn unter `workspaces/<hash>/` und lies danach dessen `memory/MEMORY.md`, falls vorhanden.
7. Waehle erst nach diesen Schritten passende Workflows, Skills und Helper.

## Stop-Bedingungen

- Wenn `AIRGAP_CLINE_HOME` fehlt, nicht lesbar ist oder nicht zu dieser Umgebung passt, stoppe und frage nach dem gueltigen Air-Gap-Pfad.
- Wenn `AGENTS.md`, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION` oder `shared/rules/` fehlen, stoppe und melde den konkreten fehlenden Bestandteil.
- Wenn mehrere Air-Gap-Stubs widerspruechliche Pfade nennen, stoppe und lasse den Nutzer den aktiven Zentralpfad bestaetigen.
- Wenn der Nutzer eine Aufgabe in einem Zielrepo stellt, lege dort trotzdem keine dauerhaften `.cline`, `.clinerules`, Skills, Workflows, Helper oder Memory-Dateien an, solange dies nicht ausdruecklich verlangt wurde.

## Verhaltensanker

- Der Zentralpfad ist Quelle der Wahrheit fuer Regeln, Workflows, Skills, Helper, Nutzerstatus, Workspace-Metadaten und Memory.
- Provider-, Modell-, Auth- und KI-Serverkonfiguration sind nicht Teil dieser Umgebung und werden nicht veraendert.
- Nutzer- und Agentendaten werden nur in den Owner-konformen Ordnern unter `users/__ENV_FAMILY__/` geschrieben.
- Geteilte Workspace-Memory wird nur zentral unter `workspaces/<hash>/memory/` gepflegt.
- Jede Abweichung von diesem Vertrag muss vom Nutzer explizit beauftragt werden.
'@
    return $template.Replace("__ENV_NAME__", $Env.Name).Replace("__ENV_FAMILY__", $Env.Family)
}

function Get-FirstReadRule {
    return @'
<!-- AIRGAP-CLINE-MANAGED:v4 -->
# First-Read Zentralumgebung

Diese Regel ist absichtlich allgemein und immer aktiv. Sie sorgt dafuer, dass Cline nach dem ersten Bootstrap den zentralen Air-Gap-Pfad vor jeder Aufgabe als erste Quelle liest.

## Muss Vor Jeder Aufgabe

- Loese `AIRGAP_CLINE_HOME` aus dem globalen Air-Gap-Stub auf.
- Lies zuerst `bootstrap/FIRST_READ.md` aus `AIRGAP_CLINE_HOME`.
- Lies danach `AGENTS.md`, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION` und alle Regeln unter `shared/rules/`.
- Pruefe `state/bootstrap-status.json`, falls vorhanden.
- Bearbeite Zielworkspaces erst, nachdem die zentrale Umgebung erfolgreich gelesen wurde.

## Darf Nicht

- Nicht mit einem Zielrepo beginnen, wenn der zentrale Air-Gap-Pfad fehlt oder unklar ist.
- Keine dauerhaften Cline-Dateien, Regeln, Skills, Workflows, Helper oder Memory-Dateien in Zielrepos anlegen, ausser der Nutzer fordert das ausdruecklich.
- Keine Provider-, Modell-, Auth- oder KI-Serverkonfiguration aendern.
'@
}

function Get-FirstReadWorkflow {
    return @'
<!-- AIRGAP-CLINE-MANAGED:v4 -->
# First-Read Verhalten Pruefen

1. Ermittle `AIRGAP_CLINE_HOME` aus dem globalen Stub.
2. Pruefe `bootstrap/FIRST_READ.md`, `AGENTS.md`, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION` und `shared/rules/`.
3. Lies die Dateien in genau dieser Reihenfolge.
4. Pruefe optional `state/bootstrap-status.json` und melde Fehlerstatus.
5. Registriere externe Zielordner zentral unter `workspaces/<hash>/`, bevor dort gearbeitet wird.
6. Lade passende Memory, Workflows, Skills und Helper erst nach dem zentralen First-Read.
'@
}

function Get-BootstrapStubTemplate {
    param($Env)
    $template = @'
<!-- AIRGAP-CLINE-STUB:v4 -->
# Air-Gap-Cline-Zentralumgebung

Dieser Stub wird bei der Initialisierung in globale Cline-Regelpfade des aktuellen Nutzers geschrieben. Er ist der dauerhafte Startanker nach dem ersten Bootstrap.

AIRGAP_CLINE_HOME wird beim Sync auf den absoluten Pfad dieser Umgebung gesetzt.

## Pflicht Fuer Cline

- Vor jeder Aufgabe zuerst den globalen Stub lesen und daraus `AIRGAP_CLINE_HOME` bestimmen.
- Danach immer `bootstrap/FIRST_READ.md` aus `AIRGAP_CLINE_HOME` lesen.
- Danach `AGENTS.md`, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION` und `shared/rules/*.md` lesen.
- Erst danach Workflows, Skills, Helper, Nutzerordner, Workspace-Metadaten oder Zielrepos verwenden.
- Wenn `AIRGAP_CLINE_HOME` nicht lesbar oder widerspruechlich ist, anhalten und den Nutzer nach dem gueltigen Pfad fragen.
- Keine Provider-, Modell-, Authentifizierungs- oder KI-Serverdaten veraendern.

## Erwarteter Pfad

- Umgebung: `__ENV_NAME__`
- OS: `__ENV_OS__`
- Rolle: `__ENV_ROLE__`
- FIRST_READ_CONTRACT: `AIRGAP_CLINE_HOME/bootstrap/FIRST_READ.md`
- First-Read-Vertrag: `AIRGAP_CLINE_HOME/bootstrap/FIRST_READ.md`
'@
    return $template.Replace("__ENV_NAME__", $Env.Name).Replace("__ENV_OS__", $Env.Os).Replace("__ENV_ROLE__", $Env.Role)
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
$marker = "AIRGAP-CLINE-STUB:v4"
$managedMarkers = @("AIRGAP-CLINE-STUB:v2", "AIRGAP-CLINE-STUB:v3", "AIRGAP-CLINE-STUB:v4", "AIRGAP-CLINE-MANAGED:v2", "AIRGAP-CLINE-MANAGED:v3", "AIRGAP-CLINE-MANAGED:v4", "AIRGAP-CLINE-FIRST-READ:v1")
$actions = New-Object System.Collections.ArrayList

function Add-Action {
    param([string]$Action, [string]$Path, [string]$BackupPath = "")
    [void]$actions.Add([ordered]@{ action = $Action; path = $Path; backupPath = $BackupPath })
}

function Test-ManagedContent {
    param([string]$Content)
    foreach ($knownMarker in $managedMarkers) {
        if ($Content -match [regex]::Escape($knownMarker)) { return $true }
    }
    return $false
}

function Write-ManagedFile {
    param([string]$Path, [string]$Content)
    $parent = Split-Path -Parent $Path
    if (-not $DryRun) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    $backupPath = ""
    if (Test-Path -LiteralPath $Path) {
        $existing = Get-Content -LiteralPath $Path -Raw
        if (-not (Test-ManagedContent -Content $existing)) {
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
            $isManaged = Test-ManagedContent -Content (Get-Content -LiteralPath $skillFile -Raw)
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
FIRST_READ_CONTRACT: ``$root\bootstrap\FIRST_READ.md``

Diese globale Regel ist der dauerhafte Startanker nach dem ersten Bootstrap.

Pflicht als allererster Schritt jeder Aufgabe:

1. Loese AIRGAP_CLINE_HOME aus diesem Stub auf.
2. Pruefe, dass ``$root`` lesbar ist und die Dateien ``START_HIER.md``, ``AGENTS.md``, ``ENVIRONMENT.md``, ``MANIFEST.json``, ``VERSION`` und ``shared\rules`` enthaelt.
3. Lies zuerst ``$root\bootstrap\FIRST_READ.md``.
4. Lies danach ``$root\AGENTS.md``, ``$root\ENVIRONMENT.md``, ``$root\MANIFEST.json``, ``$root\VERSION`` und alle Regeln unter ``$root\shared\rules``.
5. Pruefe ``$root\state\bootstrap-status.json``, falls vorhanden.
6. Nutze Workflows, Skills, Helper, Nutzerordner, Workspace-Metadaten und Zielrepos erst nach diesem First-Read.
7. Wenn der Pfad fehlt, unlesbar ist oder mehreren Stubs widerspricht, halte an und frage den Nutzer nach dem gueltigen Air-Gap-Pfad.
8. Veraendere keine Provider-, Modell-, Auth- oder KI-Server-Konfiguration.
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

$workflowTargets = @((Join-Path $HOME ".cline/data/workflows"))
if ($documents) {
    $workflowTargets += Join-Path $documents "Cline/Workflows"
}
foreach ($workflowTarget in $workflowTargets) {
    foreach ($workflow in Get-ChildItem -LiteralPath (Join-Path $root "shared/workflows") -Filter "*.md" -File) {
        Copy-ManagedFile -Source $workflow.FullName -Destination (Join-Path $workflowTarget $workflow.Name)
    }
}

$skillsTarget = Join-Path $HOME ".cline/skills"
foreach ($skill in Get-ChildItem -LiteralPath (Join-Path $root "shared/skills") -Directory) {
    Copy-ManagedSkill -SourceDir $skill.FullName -DestinationDir (Join-Path $skillsTarget $skill.Name)
}

$state = [ordered]@{
    schemaVersion = 2
    environment = "__ENV_NAME__"
    version = "__VERSION__"
    dryRun = [bool]$DryRun
    repair = [bool]$Repair
    rootPath = $root
    firstReadContract = Join-Path $root "bootstrap/FIRST_READ.md"
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
    return $template.Replace("__ENV_NAME__", $Env.Name).Replace("__VERSION__", $Version)
}

function Get-PosixSyncScript {
    param($Env)
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

MARKER="AIRGAP-CLINE-STUB:v4"
MANAGED_PATTERN="AIRGAP-CLINE-STUB:v2\|AIRGAP-CLINE-STUB:v3\|AIRGAP-CLINE-STUB:v4\|AIRGAP-CLINE-MANAGED:v2\|AIRGAP-CLINE-MANAGED:v3\|AIRGAP-CLINE-MANAGED:v4\|AIRGAP-CLINE-FIRST-READ:v1"
CLINE_HOME="${HOME}/.cline"

write_file() {
  target=$1
  content_file=$2
  parent=$(dirname "$target")
  [ "$DRY_RUN" -eq 1 ] || mkdir -p "$parent"
  if [ -f "$target" ] && ! grep -q "$MANAGED_PATTERN" "$target"; then
    backup="$target.backup-$(date '+%Y%m%d-%H%M%S')"
    echo "backup $target -> $backup"
    [ "$DRY_RUN" -eq 1 ] || cp "$target" "$backup"
  fi
  echo "write $target"
  [ "$DRY_RUN" -eq 1 ] || cp "$content_file" "$target"
}

copy_skill() {
  source_dir=$1
  target_dir=$2
  if [ -d "$target_dir" ]; then
    if [ ! -f "$target_dir/SKILL.md" ] || ! grep -q "$MANAGED_PATTERN" "$target_dir/SKILL.md"; then
      backup="$target_dir.backup-$(date '+%Y%m%d-%H%M%S')"
      echo "backup-directory $target_dir -> $backup"
      [ "$DRY_RUN" -eq 1 ] || mv "$target_dir" "$backup"
    else
      [ "$DRY_RUN" -eq 1 ] || rm -rf "$target_dir"
    fi
  fi
  echo "sync-skill $target_dir"
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$(dirname "$target_dir")"
    cp -R "$source_dir" "$target_dir"
  fi
}

TMP_STUB="${TMPDIR:-/tmp}/airgap-cline-stub.$$"
cat > "$TMP_STUB" <<EOF
<!-- $MARKER -->
# Air-Gap-Cline-Zentralumgebung

AIRGAP_CLINE_HOME: \`$ROOT_PATH\`
FIRST_READ_CONTRACT: \`$ROOT_PATH/bootstrap/FIRST_READ.md\`

Diese globale Regel ist der dauerhafte Startanker nach dem ersten Bootstrap.

Pflicht als allererster Schritt jeder Aufgabe:

1. Loese AIRGAP_CLINE_HOME aus diesem Stub auf.
2. Pruefe, dass \`$ROOT_PATH\` lesbar ist und die Dateien \`START_HIER.md\`, \`AGENTS.md\`, \`ENVIRONMENT.md\`, \`MANIFEST.json\`, \`VERSION\` und \`shared/rules\` enthaelt.
3. Lies zuerst \`$ROOT_PATH/bootstrap/FIRST_READ.md\`.
4. Lies danach \`$ROOT_PATH/AGENTS.md\`, \`$ROOT_PATH/ENVIRONMENT.md\`, \`$ROOT_PATH/MANIFEST.json\`, \`$ROOT_PATH/VERSION\` und alle Regeln unter \`$ROOT_PATH/shared/rules\`.
5. Pruefe \`$ROOT_PATH/state/bootstrap-status.json\`, falls vorhanden.
6. Nutze Workflows, Skills, Helper, Nutzerordner, Workspace-Metadaten und Zielrepos erst nach diesem First-Read.
7. Wenn der Pfad fehlt, unlesbar ist oder mehreren Stubs widerspricht, halte an und frage den Nutzer nach dem gueltigen Air-Gap-Pfad.
8. Veraendere keine Provider-, Modell-, Auth- oder KI-Server-Konfiguration.
EOF

write_file "$CLINE_HOME/rules/00-airgap-zentralumgebung.md" "$TMP_STUB"
write_file "$HOME/Documents/Cline/Rules/00-airgap-zentralumgebung.md" "$TMP_STUB"
write_file "$HOME/Cline/Rules/00-airgap-zentralumgebung.md" "$TMP_STUB"
rm -f "$TMP_STUB"

for workflow_target in "$CLINE_HOME/data/workflows" "$HOME/Documents/Cline/Workflows" "$HOME/Cline/Workflows"; do
  for workflow in "$ROOT_PATH"/shared/workflows/*.md; do
    [ -f "$workflow" ] || continue
    write_file "$workflow_target/$(basename "$workflow")" "$workflow"
  done
done

SKILLS_TARGET="$CLINE_HOME/skills"
for skill in "$ROOT_PATH"/shared/skills/*; do
  [ -d "$skill" ] || continue
  copy_skill "$skill" "$SKILLS_TARGET/$(basename "$skill")"
done

if [ "$DRY_RUN" -eq 0 ]; then
  mkdir -p "$ROOT_PATH/state"
  cat > "$ROOT_PATH/state/last-stub-sync.json" <<EOF
{
  "schemaVersion": 2,
  "environment": "__ENV_NAME__",
  "version": "__VERSION__",
  "rootPath": "$ROOT_PATH",
  "firstReadContract": "$ROOT_PATH/bootstrap/FIRST_READ.md",
  "providerChanged": false
}
EOF
fi
'@
    return $template.Replace("__ENV_NAME__", $Env.Name).Replace("__VERSION__", $Version)
}

function Update-RequiredTestContent {
    $testPath = Join-Path $RepoRoot "scripts/Test-AllEnvironmentPackages.ps1"
    $test = Get-Content -LiteralPath $testPath -Raw
    $test = $test.Replace('if ($content -notlike "*$Needle*" -and -not ($Needle -eq "AIRGAP-CLINE-MANAGED:v2" -and $content -like "*AIRGAP-CLINE-MANAGED:v3*")) {', 'if ($content -notlike "*$Needle*" -and -not ($Needle -eq "AIRGAP-CLINE-MANAGED:v2" -and ($content -like "*AIRGAP-CLINE-MANAGED:v3*" -or $content -like "*AIRGAP-CLINE-MANAGED:v4*"))) {')
    $test = $test -replace '"00-airgap-grundsaetze.md"', '"00-first-read-zentralumgebung.md", "00-airgap-grundsaetze.md"'
    $test = $test -replace '"02-nutzerordner-anlegen.md"', '"02-nutzerordner-anlegen.md", "03-first-read-verhalten-pruefen.md"'
    $test = $test -replace 'if \(-not \$manifest\.schemaVersion\) \{ throw "MANIFEST braucht schemaVersion: \$name\." \}', @'
if (-not $manifest.schemaVersion) { throw "MANIFEST braucht schemaVersion: $name." }
    if (-not $manifest.firstReadContract.enabled) { throw "MANIFEST braucht aktivierten First-Read-Vertrag: $name." }
    Assert-FileContains -Path (Join-Path $envRoot "bootstrap/FIRST_READ.md") -Needle "AIRGAP-CLINE-FIRST-READ:v1"
    Assert-FileContains -Path (Join-Path $envRoot "bootstrap/00-airgap-zentralumgebung.md") -Needle "FIRST_READ_CONTRACT"
    Assert-FileContains -Path (Join-Path $envRoot "AGENTS.md") -Needle "## Absolute Startpflicht"
    Assert-FileContains -Path (Join-Path $envRoot "START_HIER.md") -Needle "## Dauerhaftes Verhalten Nach Initialisierung"
'@
    $test = $test -replace 'Assert-FileContains -Path \(Join-Path \$envRoot "scripts/Initialize-AirgapClineEnvironment.ps1"\) -Needle "Repair"', @'
Assert-FileContains -Path (Join-Path $envRoot "scripts/Initialize-AirgapClineEnvironment.ps1") -Needle "Repair"
        Assert-FileContains -Path (Join-Path $envRoot "scripts/Sync-ClineGlobalStubs.ps1") -Needle "AIRGAP-CLINE-STUB:v4"
        Assert-FileContains -Path (Join-Path $envRoot "scripts/Sync-ClineGlobalStubs.ps1") -Needle "bootstrap\FIRST_READ.md"
'@
    $test = $test -replace 'Assert-FileContains -Path \(Join-Path \$envRoot "scripts/initialize-airgap-cline-environment.sh"\) -Needle "--dry-run"', @'
Assert-FileContains -Path (Join-Path $envRoot "scripts/initialize-airgap-cline-environment.sh") -Needle "--dry-run"
        Assert-FileContains -Path (Join-Path $envRoot "scripts/sync-cline-global-stubs.sh") -Needle "AIRGAP-CLINE-STUB:v4"
        Assert-FileContains -Path (Join-Path $envRoot "scripts/sync-cline-global-stubs.sh") -Needle "bootstrap/FIRST_READ.md"
'@
    Write-TextFile "scripts/Test-AllEnvironmentPackages.ps1" $test
}

Write-TextFile "VERSION" ($Version + "`n")

Write-TextFile "scripts/Sync-EnvironmentTemplates.ps1" @'
[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$Version = "0.4.0"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = Split-Path -Parent $ScriptDir
}
$RepoRoot = [System.IO.Path]::GetFullPath($RootPath)
$Enhancer = Join-Path $ScriptDir "Apply-V4Enhancements.ps1"

if (-not (Test-Path -LiteralPath $Enhancer -PathType Leaf)) {
    throw "Fehlende Generatorquelle: $Enhancer"
}

& $Enhancer -RootPath $RepoRoot -Version $Version
Write-Host "Umgebungen synchronisiert: $RepoRoot"
'@

foreach ($scriptName in @("Build-AllEnvironmentPackages.ps1", "New-ReleaseManifest.ps1")) {
    $path = Join-Path $RepoRoot "scripts/$scriptName"
    $content = Get-Content -LiteralPath $path -Raw
    $content = $content -replace '0\.3\.0', '0.4.0'
    if ($scriptName -eq "Build-AllEnvironmentPackages.ps1") {
        $content = $content.Replace('Ab v0.3 enthaelt jede Umgebung ein koordiniertes Memory-Modell; Runtime-Memory bleibt ausserhalb des Git-Verlaufs.', 'Ab v0.3 enthaelt jede Umgebung ein koordiniertes Memory-Modell; ab v0.4 enthaelt jede Umgebung einen First-Read-Vertrag, damit Cline nach dem ersten Bootstrap vor jeder Aufgabe zuerst den zentralen Air-Gap-Pfad prueft. Runtime-Memory bleibt ausserhalb des Git-Verlaufs.')
    }
    Write-TextFile "scripts/$scriptName" $content
}

$ciPath = Join-Path $RepoRoot ".github/workflows/ci.yml"
$ci = Get-Content -LiteralPath $ciPath -Raw
$ci = $ci -replace '0\.3\.0-ci', '0.4.0-ci'
Write-TextFile ".github/workflows/ci.yml" $ci

$readme = Get-Content -LiteralPath (Join-Path $RepoRoot "README.md") -Raw
if ($readme -notlike "*## First-Read Nach Bootstrap*") {
    $readme = $readme.TrimEnd() + @'

## First-Read Nach Bootstrap

Ab v0.4 schreibt die Initialisierung einen globalen Air-Gap-Stub in die Cline-Regelpfade. Dieser Stub enthaelt den absoluten `AIRGAP_CLINE_HOME`-Pfad und verpflichtet Cline, vor jeder Aufgabe zuerst `bootstrap/FIRST_READ.md`, danach `AGENTS.md`, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION` und `shared/rules/` aus der zentralen Umgebung zu lesen. Wenn der Pfad fehlt oder widerspruechlich ist, muss Cline anhalten und den Nutzer nach dem gueltigen Air-Gap-Pfad fragen.
'@
    Write-TextFile "README.md" $readme
}

$architecture = Get-Content -LiteralPath (Join-Path $RepoRoot "ARCHITEKTUR.md") -Raw
if ($architecture -notlike "*## First-Read-Vertrag*") {
    $architecture = $architecture.TrimEnd() + @'

## First-Read-Vertrag

Nach der ersten Initialisierung ist der globale Stub die dauerhafte Eintrittsstelle fuer Cline. Er liegt in den globalen Cline-Regelpfaden und verweist auf `AIRGAP_CLINE_HOME`. Cline muss diesen Pfad als Quelle der Wahrheit behandeln und vor jeder Zielworkspace-Arbeit zuerst `bootstrap/FIRST_READ.md` lesen. Danach folgen `AGENTS.md`, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION`, `shared/rules/`, optional `state/bootstrap-status.json` und erst dann Workspace-Memory, Workflows, Skills und Helper.
'@
    Write-TextFile "ARCHITEKTUR.md" $architecture
}

foreach ($Env in $Environments) {
    $base = "environments/$($Env.Name)"
    Write-TextFile "$base/VERSION" ($Version + "`n")
    Write-TextFile "$base/bootstrap/FIRST_READ.md" (Get-FirstReadContract -Env $Env)
    Write-TextFile "$base/bootstrap/00-airgap-zentralumgebung.md" (Get-BootstrapStubTemplate -Env $Env)
    Write-TextFile "$base/shared/rules/00-first-read-zentralumgebung.md" (Get-FirstReadRule)
    Write-TextFile "$base/shared/workflows/03-first-read-verhalten-pruefen.md" (Get-FirstReadWorkflow)

    if ($Env.Os -eq "Windows") {
        Write-TextFile "$base/scripts/Sync-ClineGlobalStubs.ps1" (Get-PowerShellSyncScript -Env $Env)
    } else {
        Write-TextFile "$base/scripts/sync-cline-global-stubs.sh" (Get-PosixSyncScript -Env $Env)
    }

    $startPath = Join-Path $RepoRoot "$base/START_HIER.md"
    $start = Get-Content -LiteralPath $startPath -Raw
    if ($start -notlike "*## Dauerhaftes Verhalten Nach Initialisierung*") {
        $start = $start.TrimEnd() + @'

## Dauerhaftes Verhalten Nach Initialisierung

Nach erfolgreicher Initialisierung muss Cline nicht erneut ueber diesen Pfad instruiert werden, solange der globale Air-Gap-Stub vorhanden ist. Der Stub ist eine globale Cline-Regel und verweist auf `AIRGAP_CLINE_HOME`. Vor jeder Aufgabe muss Cline zuerst `bootstrap/FIRST_READ.md` aus diesem Zentralpfad lesen und danach die zentralen Agentenanweisungen, Umgebung, Manifest, Version und Regeln pruefen. Erst danach darf ein externer Arbeitsordner bearbeitet werden.
'@
        Write-TextFile "$base/START_HIER.md" $start
    }

    $agentsPath = Join-Path $RepoRoot "$base/AGENTS.md"
    $agents = Get-Content -LiteralPath $agentsPath -Raw
    if ($agents -notlike "*## Absolute Startpflicht*") {
        $agentsAppend = @'

## Absolute Startpflicht

Nach dem ersten Bootstrap gilt fuer jeden Cline-Agenten:

1. Zuerst den globalen Air-Gap-Stub lesen und daraus `AIRGAP_CLINE_HOME` bestimmen.
2. Dann `bootstrap/FIRST_READ.md` aus `AIRGAP_CLINE_HOME` lesen.
3. Danach `AGENTS.md`, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION` und `shared/rules/*.md` lesen.
4. Optional `state/bootstrap-status.json` pruefen.
5. Erst danach Zielworkspace, Memory, Workflows, Skills und Helper verwenden.

Wenn der Zentralpfad fehlt, nicht lesbar ist oder widerspruechlich erscheint, muss der Agent anhalten und den Nutzer nach dem gueltigen Air-Gap-Pfad fragen. Es ist kein valider Arbeitsmodus, ohne zentral gelesene Regeln direkt in einem Zielrepo zu starten.
'@
        $agents = $agents.TrimEnd() + $agentsAppend
        Write-TextFile "$base/AGENTS.md" $agents
    }

    $envPath = Join-Path $RepoRoot "$base/ENVIRONMENT.md"
    $envText = Get-Content -LiteralPath $envPath -Raw
    if ($envText -notlike "*## First-Read-Betrieb*") {
        $envText = $envText.TrimEnd() + @'

## First-Read-Betrieb

Die Initialisierung installiert globale Cline-Regelstubs. Diese Stubs sind keine Provider- oder Auth-Konfiguration, sondern nur ein dauerhafter Leseanker. Sie verpflichten Cline, bei jedem Task zuerst die zentrale Umgebung zu lesen und erst danach Zielordner zu bearbeiten.
'@
        Write-TextFile "$base/ENVIRONMENT.md" $envText
    }

    $manifestPath = Join-Path $RepoRoot "$base/MANIFEST.json"
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $manifest.version = $Version
    $manifest | Add-Member -NotePropertyName firstReadContract -NotePropertyValue ([ordered]@{
        enabled = $true
        schemaVersion = 1
        bootstrapFile = "bootstrap/FIRST_READ.md"
        globalStubRule = "00-airgap-zentralumgebung.md"
        requiredFirstFiles = @("bootstrap/FIRST_READ.md", "AGENTS.md", "ENVIRONMENT.md", "MANIFEST.json", "VERSION", "shared/rules/*.md")
        stopIfCentralPathMissing = $true
        changesProviderConfiguration = $false
    }) -Force
    Write-TextFile "$base/MANIFEST.json" (ConvertTo-JsonText $manifest)
}

Update-RequiredTestContent

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

Write-Host "v0.4-First-Read-Erweiterungen angewendet: $RepoRoot"
