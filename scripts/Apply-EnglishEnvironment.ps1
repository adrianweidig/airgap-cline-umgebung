[CmdletBinding()]
param([string]$RootPath = "", [string]$Version = "0.5.0")
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) { $RootPath = Split-Path -Parent $ScriptDir }
$RepoRoot = [System.IO.Path]::GetFullPath($RootPath)
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
if (-not $python) { throw "Python was not found." }
& $python.Source (Join-Path $ScriptDir "Apply-EnglishEnvironment.py") --root $RepoRoot --version $Version
