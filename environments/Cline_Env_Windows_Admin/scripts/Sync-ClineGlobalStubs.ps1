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
    environment = "Cline_Env_Windows_Admin"
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