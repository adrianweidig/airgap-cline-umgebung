[CmdletBinding()]
param([string]$RootPath = "", [Parameter(Mandatory = $true)][string]$TargetPath, [string]$Alias = "")
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($RootPath)) { $RootPath = Split-Path -Parent $PSScriptRoot }
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
if (-not $python) { throw "Python was not found." }
& $python.Source (Join-Path $RootPath "shared/helpers/python/register_workspace.py") --root $RootPath --target $TargetPath --alias $Alias
