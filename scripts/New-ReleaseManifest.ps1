[CmdletBinding()]
param(
    [string]$DistPath = "",
    [string]$Version = "0.2.0"
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

function Get-AssetInfo {
    param([System.IO.FileInfo]$File)
    $hash = Get-FileHash -LiteralPath $File.FullName -Algorithm SHA256
    $packageType = if ($File.Extension -eq ".7z") { "7z" } elseif ($File.Extension -eq ".zip") { "zip" } else { "metadata" }
    $environmentName = "none"
    if ($File.Name -match "^(Cline_Env_(Windows|Linux|Mac|Solaris)_(User|Admin)|Cline_Env_All)_v") {
        $environmentName = $Matches[1]
    }
    [ordered]@{
        name = $File.Name
        size = $File.Length
        sha256 = $hash.Hash.ToLowerInvariant()
        packageType = $packageType
        environmentName = $environmentName
        generatedAt = (Get-Date).ToString("o")
    }
}

$assets = Get-ChildItem -LiteralPath $DistPath -File |
    Where-Object { $_.Name -notin @("RELEASE_MANIFEST.json", "SHA256SUMS.txt") } |
    Sort-Object Name |
    ForEach-Object { Get-AssetInfo -File $_ }

$manifest = [ordered]@{
    schemaVersion = 2
    version = $Version
    generatedAt = (Get-Date).ToString("o")
    artifactCount = $assets.Count
    assets = $assets
}

$manifestPath = Join-Path $DistPath "RELEASE_MANIFEST.json"
[System.IO.File]::WriteAllText($manifestPath, (($manifest | ConvertTo-Json -Depth 20) + "`n"), (New-Object System.Text.UTF8Encoding($false)))

$sumPath = Join-Path $DistPath "SHA256SUMS.txt"
$lines = foreach ($file in (Get-ChildItem -LiteralPath $DistPath -File | Where-Object { $_.Name -ne "SHA256SUMS.txt" } | Sort-Object Name)) {
    $hash = Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256
    "$($hash.Hash.ToLowerInvariant())  $($file.Name)"
}
[System.IO.File]::WriteAllText($sumPath, (($lines -join "`n") + "`n"), (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Release-Manifest geschrieben: $manifestPath"