[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$Version = "0.1.0",
    [string]$OutputPath = "",
    [switch]$SkipTests
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = Split-Path -Parent $ScriptDir
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path (Split-Path -Parent $ScriptDir) "dist"
}
$RepoRoot = [System.IO.Path]::GetFullPath($RootPath)
$Date = (Get-Date).ToString("yyyy-MM-dd")
$SevenZip = "C:\Program Files\7-Zip\7z.exe"

if (-not $SkipTests) {
    & (Join-Path $PSScriptRoot "Test-AllEnvironmentPackages.ps1") -RootPath $RepoRoot
}

if (-not (Test-Path -LiteralPath $SevenZip)) {
    throw "7-Zip wurde nicht gefunden: $SevenZip"
}

if (Test-Path -LiteralPath $OutputPath) {
    Remove-Item -LiteralPath $OutputPath -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null

$stageRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("airgap-cline-package-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $stageRoot | Out-Null

function Copy-CleanTree {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    $sourceFull = [System.IO.Path]::GetFullPath($Source)
    Get-ChildItem -LiteralPath $sourceFull -Recurse -Force | ForEach-Object {
        $relative = $_.FullName.Substring($sourceFull.Length).TrimStart('\', '/')
        if ([string]::IsNullOrWhiteSpace($relative)) { return }

        $parts = $relative -split '[\\/]'
        $isRuntime = $parts[0] -in @("users", "workspaces", "state", "logs", "audit")
        if ($isRuntime -and $_.PSIsContainer) {
            $targetDir = Join-Path $Destination $relative
            New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
            return
        }
        if ($isRuntime -and $_.Name -ne ".gitkeep") {
            return
        }

        $target = Join-Path $Destination $relative
        if ($_.PSIsContainer) {
            New-Item -ItemType Directory -Force -Path $target | Out-Null
        } else {
            $parent = Split-Path -Parent $target
            if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
            Copy-Item -LiteralPath $_.FullName -Destination $target -Force
        }
    }
}

try {
    $envRoot = Join-Path $RepoRoot "environments"
    $envs = Get-ChildItem -LiteralPath $envRoot -Directory -Filter "Cline_Env_*" | Sort-Object Name

    foreach ($env in $envs) {
        $stage = Join-Path $stageRoot $env.Name
        Copy-CleanTree -Source $env.FullName -Destination $stage

        $zipPath = Join-Path $OutputPath ("{0}_v{1}_{2}.zip" -f $env.Name, $Version, $Date)
        $sevenPath = Join-Path $OutputPath ("{0}_v{1}_{2}.7z" -f $env.Name, $Version, $Date)

        Compress-Archive -Path $stage -DestinationPath $zipPath -Force
        & $SevenZip a -t7z $sevenPath $stage | Out-Null
        & $SevenZip t $sevenPath | Out-Null
    }

    $allStage = Join-Path $stageRoot "Cline_Env_All"
    New-Item -ItemType Directory -Force -Path $allStage | Out-Null
    foreach ($env in $envs) {
        Copy-CleanTree -Source $env.FullName -Destination (Join-Path $allStage $env.Name)
    }

    $allZip = Join-Path $OutputPath ("Cline_Env_All_v{0}_{1}.zip" -f $Version, $Date)
    $all7z = Join-Path $OutputPath ("Cline_Env_All_v{0}_{1}.7z" -f $Version, $Date)
    Compress-Archive -Path $allStage -DestinationPath $allZip -Force
    & $SevenZip a -t7z $all7z $allStage | Out-Null
    & $SevenZip t $all7z | Out-Null

    & (Join-Path $PSScriptRoot "New-ReleaseManifest.ps1") -DistPath $OutputPath -Version $Version

    $notes = @"
# Release v$Version

Dieses Release enthaelt pro exportierbarer Air-Gap-Cline-Umgebung je ein `.7z`- und `.zip`-Paket sowie ein Gesamtpaket.

Cline muss vor der Nutzung bereits installiert, eingerichtet und mit dem gewuenschten KI-Server verbunden sein. Diese Pakete enthalten keine Provider-, Modell- oder Authentifizierungsdaten.
"@
    [System.IO.File]::WriteAllText((Join-Path $OutputPath "RELEASE_NOTES_DE.md"), $notes, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Pakete erstellt in: $OutputPath"
}
finally {
    if (Test-Path -LiteralPath $stageRoot) {
        Remove-Item -LiteralPath $stageRoot -Recurse -Force
    }
}