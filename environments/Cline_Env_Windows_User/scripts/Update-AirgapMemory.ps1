[CmdletBinding()]
param([string]$RootPath = "", [Parameter(Mandatory = $true)][ValidateSet("init", "read", "propose", "apply", "validate")][string]$Action, [Parameter(Mandatory = $true)][string]$Workspace, [string]$Type = "fact", [string]$Text = "", [string]$Proposal = "", [string]$AgentId = "agent")
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($RootPath)) { $RootPath = Split-Path -Parent $PSScriptRoot }
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
if (-not $python) { throw "Python was not found." }
$helper = Join-Path $RootPath "shared/helpers/python/memory_update.py"
$argv = @($helper, "--root", $RootPath, $Action, "--workspace", $Workspace, "--agent-id", $AgentId)
if ($Action -eq "propose") {
    if ([string]::IsNullOrWhiteSpace($Text)) { throw "Text is required for propose." }
    $argv += @("--type", $Type, "--text", $Text)
}
if ($Action -eq "apply") {
    if ([string]::IsNullOrWhiteSpace($Proposal)) { throw "Proposal is required for apply." }
    $argv += @("--proposal", $Proposal)
}
& $python.Source @argv
