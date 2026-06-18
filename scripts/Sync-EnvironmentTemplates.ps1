[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$Version = "0.2.0"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = Split-Path -Parent $ScriptDir
}
$RepoRoot = [System.IO.Path]::GetFullPath($RootPath)
$Enhancer = Join-Path $ScriptDir "Apply-V2Enhancements.ps1"

if (-not (Test-Path -LiteralPath $Enhancer -PathType Leaf)) {
    throw "Fehlende Generatorquelle: $Enhancer"
}

& $Enhancer -RootPath $RepoRoot -Version $Version
Write-Host "Umgebungen synchronisiert: $RepoRoot"
