[CmdletBinding()]
param([string]$RootPath = "", [string]$Version = "0.5.0", [string]$OutputPath = "", [switch]$SkipTests)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) { $RootPath = Split-Path -Parent $ScriptDir }
if ([string]::IsNullOrWhiteSpace($OutputPath)) { $OutputPath = Join-Path (Split-Path -Parent $ScriptDir) "dist" }
$RepoRoot = [System.IO.Path]::GetFullPath($RootPath)
$Date = (Get-Date).ToString("yyyy-MM-dd")
$SevenZip = "C:\Program Files\7-Zip\7z.exe"
if (-not $SkipTests) { & (Join-Path $PSScriptRoot "Test-AllEnvironmentPackages.ps1") -RootPath $RepoRoot }
if (-not (Test-Path -LiteralPath $SevenZip)) { throw "7-Zip was not found: $SevenZip" }
if (Test-Path -LiteralPath $OutputPath) { Remove-Item -LiteralPath $OutputPath -Recurse -Force }
New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null
$stageRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("airgap-cline-package-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $stageRoot | Out-Null
function Copy-CleanTree {
    param([Parameter(Mandatory = $true)][string]$Source, [Parameter(Mandatory = $true)][string]$Destination)
    $sourceFull = [System.IO.Path]::GetFullPath($Source)
    Get-ChildItem -LiteralPath $sourceFull -Recurse -Force | ForEach-Object {
        $relative = $_.FullName.Substring($sourceFull.Length).TrimStart('\', '/')
        if ([string]::IsNullOrWhiteSpace($relative)) { return }
        $parts = $relative -split '[\\/]'
        $isRuntime = $parts[0] -in @("users", "workspaces", "state", "logs", "audit")
        if ($isRuntime -and $_.PSIsContainer) { New-Item -ItemType Directory -Force -Path (Join-Path $Destination $relative) | Out-Null; return }
        if ($isRuntime -and $_.Name -ne ".gitkeep") { return }
        $target = Join-Path $Destination $relative
        if ($_.PSIsContainer) { New-Item -ItemType Directory -Force -Path $target | Out-Null } else { $parent = Split-Path -Parent $target; if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }; Copy-Item -LiteralPath $_.FullName -Destination $target -Force }
    }
}
function Test-ZipArchive {
    param([string]$ZipPath, [string]$ExpectedRootName)
    $extractRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("airgap-cline-ziptest-" + [guid]::NewGuid().ToString("N"))
    try { Expand-Archive -LiteralPath $ZipPath -DestinationPath $extractRoot -Force; $found = Get-ChildItem -LiteralPath $extractRoot -Directory -Recurse -Filter $ExpectedRootName | Select-Object -First 1; if (-not $found) { throw "ZIP archive does not contain expected root: $ExpectedRootName" } } finally { if (Test-Path -LiteralPath $extractRoot) { Remove-Item -LiteralPath $extractRoot -Recurse -Force } }
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
        Test-ZipArchive -ZipPath $zipPath -ExpectedRootName $env.Name
        & $SevenZip a -t7z $sevenPath $stage | Out-Null
        & $SevenZip t $sevenPath | Out-Null
    }
    $allStage = Join-Path $stageRoot "Cline_Env_All"
    New-Item -ItemType Directory -Force -Path $allStage | Out-Null
    foreach ($env in $envs) { Copy-CleanTree -Source $env.FullName -Destination (Join-Path $allStage $env.Name) }
    $allZip = Join-Path $OutputPath ("Cline_Env_All_v{0}_{1}.zip" -f $Version, $Date)
    $all7z = Join-Path $OutputPath ("Cline_Env_All_v{0}_{1}.7z" -f $Version, $Date)
    Compress-Archive -Path $allStage -DestinationPath $allZip -Force
    Test-ZipArchive -ZipPath $allZip -ExpectedRootName "Cline_Env_All"
    & $SevenZip a -t7z $all7z $allStage | Out-Null
    & $SevenZip t $all7z | Out-Null
    $notes = @(
        "# Release v$Version",
        "",
        "This release contains one `.7z` and one `.zip` package for each exportable Air-Gap Cline environment plus an all-in-one package.",
        "",
        "Cline must already be installed, configured, and connected to the intended AI server. These packages contain no provider, model, authentication, or AI-server data.",
        "",
        "## Selection",
        "",
        "- Windows User/Admin: primary target for the VS Code Cline extension.",
        "- Linux User/Admin: primary target for Cline CLI.",
        "- macOS User/Admin: CLI or editor-adjacent usage.",
        "- Solaris User/Admin: POSIX best effort, only when Cline already runs there.",
        "",
        "## Verification",
        "",
        "All `.7z` packages were tested with 7-Zip. All `.zip` packages were extracted and checked for the expected root folder. Each environment includes the coordinated memory model and first-read contract. Runtime memory remains outside Git."
    ) -join "`n"
    Set-Content -LiteralPath (Join-Path $OutputPath "RELEASE_NOTES.md") -Value ($notes + "`n") -Encoding UTF8
    & (Join-Path $PSScriptRoot "New-ReleaseManifest.ps1") -DistPath $OutputPath -Version $Version
    Write-Host "Packages created in: $OutputPath"
} finally { if (Test-Path -LiteralPath $stageRoot) { Remove-Item -LiteralPath $stageRoot -Recurse -Force } }
