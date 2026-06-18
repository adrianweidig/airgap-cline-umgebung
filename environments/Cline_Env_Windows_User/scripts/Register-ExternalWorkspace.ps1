[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$TargetPath,
    [string]$RootPath = "",
    [string]$Alias = "",
    [switch]$DryRun
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

$argsList = @((Join-Path $RootPath "shared/helpers/python/register_workspace.py"), "--root", $RootPath, "--target", $TargetPath)
if ($Alias) { $argsList += @("--alias", $Alias) }
if ($DryRun) { $argsList += "--dry-run" }
& $python.Source @argsList