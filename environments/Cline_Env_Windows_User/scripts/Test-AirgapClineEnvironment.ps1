[CmdletBinding()]
param([string]$RootPath = "")
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($RootPath)) { $RootPath = Split-Path -Parent $PSScriptRoot }
foreach ($rel in @("START_HERE.md", "AGENTS.md", "ENVIRONMENT.md", "MANIFEST.json", "bootstrap/FIRST_READ.md")) {
    if (-not (Test-Path -LiteralPath (Join-Path $RootPath $rel))) { throw "Missing required file: $rel" }
}
Write-Host "Environment valid: $RootPath"
