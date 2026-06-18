[CmdletBinding()]
param([string]$RootPath = "", [string]$Version = "0.5.0")
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
& (Join-Path $ScriptDir "Apply-EnglishEnvironment.ps1") -RootPath $RootPath -Version $Version
