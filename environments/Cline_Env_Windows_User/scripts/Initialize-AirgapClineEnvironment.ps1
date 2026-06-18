[CmdletBinding()]
param([string]$RootPath = "", [string]$AgentId = "default-agent", [switch]$DryRun, [switch]$Repair)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($RootPath)) { $RootPath = Split-Path -Parent $PSScriptRoot }
$RootPath = [System.IO.Path]::GetFullPath($RootPath)
if (-not (Test-Path -LiteralPath (Join-Path $RootPath "MANIFEST.json") -PathType Leaf)) { throw "Invalid Air-Gap Cline environment: $RootPath" }
if ($DryRun) {
    Write-Host "Dry run for Cline_Env_Windows_User at $RootPath"
    Write-Host "Would create or repair the current user folder and sync global Cline stubs."
    return
}
& (Join-Path $PSScriptRoot "New-AirgapClineUserWorkspace.ps1") -RootPath $RootPath -AgentId $AgentId | Out-Null
& (Join-Path $PSScriptRoot "Sync-ClineGlobalStubs.ps1") -RootPath $RootPath -Repair:$Repair | Out-Null
$statusPath = Join-Path $RootPath "state/bootstrap-status.json"
$status = [ordered]@{ schemaVersion = 2; environment = "Cline_Env_Windows_User"; status = "ok"; version = "0.5.0"; user = $env:USERNAME; domain = $env:USERDOMAIN; host = $env:COMPUTERNAME; rootPath = $RootPath; repair = [bool]$Repair; updatedAt = (Get-Date).ToString("o"); providerConfigurationChanged = $false }
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $statusPath) | Out-Null
$status | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $statusPath -Encoding UTF8
Write-Host "Initialization completed for Cline_Env_Windows_User."
