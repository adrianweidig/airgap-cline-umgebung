[CmdletBinding()]
param(
    [string]$RootPath = "",
    [switch]$NoGlobalStub
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = (Resolve-Path (Join-Path $ScriptDir "..")).Path
}
$root = [System.IO.Path]::GetFullPath($RootPath)
foreach ($required in @("START_HIER.md", "AGENTS.md", "ENVIRONMENT.md", "MANIFEST.json")) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $required))) {
        throw "Fehlende Pflichtdatei: $required"
    }
}

$agentRoot = & (Join-Path $ScriptDir "New-AirgapClineUserWorkspace.ps1") -RootPath $root
if (-not $NoGlobalStub) {
    & (Join-Path $ScriptDir "Sync-ClineGlobalStubs.ps1") -RootPath $root
}

$status = [ordered]@{
    environment = "Cline_Env_Windows_User"
    rootPath = $root
    agentRoot = ($agentRoot | Select-Object -Last 1)
    providerChanged = $false
    initializedAt = (Get-Date).ToString("o")
}
$stateDir = Join-Path $root "state"
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
$status | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $stateDir "bootstrap-status.json") -Encoding UTF8

Write-Host "Initialisierung abgeschlossen fuer Cline_Env_Windows_User."