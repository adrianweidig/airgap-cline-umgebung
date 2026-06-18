[CmdletBinding()]
param([string]$RootPath = "", [string]$Version = "0.5.0")
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) { $RootPath = Split-Path -Parent $ScriptDir }
$RepoRoot = [System.IO.Path]::GetFullPath($RootPath)
& (Join-Path $ScriptDir "Apply-EnglishEnvironment.ps1") -RootPath $RepoRoot -Version $Version
Write-Host "Environment templates synchronized: $RepoRoot"
