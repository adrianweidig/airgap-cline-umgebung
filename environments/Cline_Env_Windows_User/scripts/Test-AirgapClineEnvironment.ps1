[CmdletBinding()]
param(
    [string]$RootPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = (Resolve-Path (Join-Path $ScriptDir "..")).Path
}
$required = @("START_HIER.md", "AGENTS.md", "ENVIRONMENT.md", "MANIFEST.json", "shared/rules", "shared/workflows", "shared/skills", "shared/helpers/python")
foreach ($item in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $RootPath $item))) {
        throw "Fehlender Bestandteil: $item"
    }
}

$forbidden = Get-ChildItem -LiteralPath $RootPath -Recurse -File |
    Where-Object { $_.Extension.ToLowerInvariant() -in @(".exe", ".msi", ".vsix", ".7z", ".zip", ".gguf", ".safetensors") }
if ($forbidden) {
    throw "Verbotene Datei in Umgebung: $($forbidden[0].FullName)"
}

Write-Host "Umgebung valide: $RootPath"