[CmdletBinding()]
param(
    [string]$DistPath = "",
    [string]$Version = "0.1.0"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($DistPath)) {
    $DistPath = Join-Path (Split-Path -Parent $ScriptDir) "dist"
}
if (-not (Test-Path -LiteralPath $DistPath)) {
    throw "DistPath existiert nicht: $DistPath"
}

$files = Get-ChildItem -LiteralPath $DistPath -File | Sort-Object Name | ForEach-Object {
    $hash = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
    [ordered]@{
        name = $_.Name
        size = $_.Length
        sha256 = $hash.Hash.ToLowerInvariant()
    }
}

$manifest = [ordered]@{
    version = $Version
    generatedAt = (Get-Date).ToString("o")
    files = $files
}

$json = $manifest | ConvertTo-Json -Depth 10
$manifestPath = Join-Path $DistPath "RELEASE_MANIFEST.json"
[System.IO.File]::WriteAllText($manifestPath, $json, (New-Object System.Text.UTF8Encoding($false)))

$sumPath = Join-Path $DistPath "SHA256SUMS.txt"
$lines = foreach ($file in (Get-ChildItem -LiteralPath $DistPath -File | Sort-Object Name)) {
    if ($file.Name -eq "SHA256SUMS.txt") { continue }
    $hash = Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256
    "$($hash.Hash.ToLowerInvariant())  $($file.Name)"
}
[System.IO.File]::WriteAllText($sumPath, (($lines -join "`n") + "`n"), (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Release-Manifest geschrieben: $manifestPath"