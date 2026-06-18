[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateSet("init", "read", "propose", "apply", "render", "validate")][string]$Action,
    [Parameter(Mandatory = $true)][string]$Workspace,
    [string]$RootPath = "",
    [ValidateSet("read_first", "fact", "decision", "active", "next", "do_not", "open_question")][string]$Type = "fact",
    [string]$Text = "",
    [string]$Proposal = "",
    [string]$AgentId = ""
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

$helper = Join-Path $RootPath "shared/helpers/python/memory_update.py"
$argsList = @($helper, "--root", $RootPath, $Action, "--workspace", $Workspace)
if ($Action -eq "propose") {
    if ([string]::IsNullOrWhiteSpace($Text)) { throw "Text ist fuer propose erforderlich." }
    $argsList += @("--type", $Type, "--text", $Text)
}
if ($Action -eq "apply") {
    if ([string]::IsNullOrWhiteSpace($Proposal)) { throw "Proposal ist fuer apply erforderlich." }
    $argsList += @("--proposal", $Proposal)
}
if ($AgentId) { $argsList += @("--agent-id", $AgentId) }
& $python.Source @argsList