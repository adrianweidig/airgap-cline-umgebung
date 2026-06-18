[CmdletBinding()]
param([string]$RootPath = "", [switch]$DryRun, [switch]$Repair)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($RootPath)) { $RootPath = Split-Path -Parent $PSScriptRoot }
$root = [System.IO.Path]::GetFullPath($RootPath)
$targets = @((Join-Path $HOME ".cline/rules/00-airgap-central-environment.md"))
$documents = [Environment]::GetFolderPath("MyDocuments")
if (-not [string]::IsNullOrWhiteSpace($documents)) { $targets += Join-Path $documents "Cline/Rules/00-airgap-central-environment.md" }
$stubLines = @(
    "# Air-Gap Cline Central Environment",
    "",
    "AIRGAP-CLINE-STUB:v5",
    "FIRST_READ_CONTRACT: bootstrap/FIRST_READ.md",
    "AIRGAP_CLINE_HOME=$root",
    "",
    "This global rule is the permanent entry point after the first bootstrap.",
    "",
    "## Required Behavior For Cline",
    "",
    "1. Resolve AIRGAP_CLINE_HOME from this stub before every task.",
    "2. Read $root\bootstrap\FIRST_READ.md.",
    "3. Read $root\AGENTS.md, $root\ENVIRONMENT.md, $root\MANIFEST.json, $root\VERSION, and all rules under $root\shared\rules.",
    "4. Use workflows, skills, helpers, user folders, workspace metadata, and target repositories only after this first read.",
    "5. Stop and ask for the valid Air-Gap path when the path is missing, unreadable, or contradicted by another stub.",
    "6. Do not change provider, model, authentication, or AI-server configuration."
)
$content = ($stubLines -join [Environment]::NewLine) + [Environment]::NewLine
foreach ($target in $targets) {
    if ($DryRun) { Write-Host "Would write stub: $target"; continue }
    $parent = Split-Path -Parent $target
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    if ((Test-Path -LiteralPath $target) -and -not ((Get-Content -LiteralPath $target -Raw) -like "*AIRGAP-CLINE-STUB:*")) {
        Copy-Item -LiteralPath $target -Destination "$target.backup-$(Get-Date -Format yyyyMMddHHmmss)" -Force
    }
    Set-Content -LiteralPath $target -Value $content -Encoding UTF8
}
$targets
