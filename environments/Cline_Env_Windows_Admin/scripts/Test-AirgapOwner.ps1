[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$OwnerPath, [switch]$Write)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
if (-not $python) { throw "Python was not found." }
$args = @((Join-Path $root "shared/helpers/python/guard_owner.py"), "--owner", $OwnerPath)
if ($Write) { $args += "--write" }
& $python.Source @args
