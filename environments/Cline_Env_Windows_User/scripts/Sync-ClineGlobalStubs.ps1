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
$root = [System.IO.Path]::GetFullPath($RootPath)
$stub = "# Air-Gap-Cline-Zentralumgebung

AIRGAP_CLINE_HOME: ``$root``

Vor jeder Aufgabe: lies ``$root\AGENTS.md```, ``$root\ENVIRONMENT.md``` und die Regeln unter ``$root\shared\rules```. Veraendere keine Provider- oder Modellkonfiguration.
"

$targets = @(
    Join-Path $HOME ".cline/rules/00-airgap-zentralumgebung.md"
)

if ("Windows" -eq "Windows") {
    $targets += Join-Path ([Environment]::GetFolderPath("MyDocuments")) "Cline/Rules/00-airgap-zentralumgebung.md"
}

foreach ($target in $targets) {
    $parent = Split-Path -Parent $target
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    Set-Content -LiteralPath $target -Encoding UTF8 -Value $stub
}

$workflowTarget = Join-Path $HOME ".cline/data/workflows"
New-Item -ItemType Directory -Force -Path $workflowTarget | Out-Null
Get-ChildItem -LiteralPath (Join-Path $root "shared/workflows") -Filter "*.md" -File | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $workflowTarget -Force
}

$skillsTarget = Join-Path $HOME ".cline/skills"
New-Item -ItemType Directory -Force -Path $skillsTarget | Out-Null
Get-ChildItem -LiteralPath (Join-Path $root "shared/skills") -Directory | ForEach-Object {
    $targetSkill = Join-Path $skillsTarget $_.Name
    if (Test-Path -LiteralPath $targetSkill) {
        Remove-Item -LiteralPath $targetSkill -Recurse -Force
    }
    Copy-Item -LiteralPath $_.FullName -Destination $targetSkill -Recurse -Force
}

Write-Host "Globale Cline-Stubs synchronisiert."