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
    environment = "Cline_Env_Windows_Admin"
    version = "0.4.0"
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