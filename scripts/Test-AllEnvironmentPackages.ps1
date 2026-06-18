[CmdletBinding()]
param(
    [string]$RootPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = Split-Path -Parent $ScriptDir
}
$RepoRoot = [System.IO.Path]::GetFullPath($RootPath)
$expected = @(
    "Cline_Env_Windows_User",
    "Cline_Env_Windows_Admin",
    "Cline_Env_Linux_User",
    "Cline_Env_Linux_Admin",
    "Cline_Env_Mac_User",
    "Cline_Env_Mac_Admin",
    "Cline_Env_Solaris_User",
    "Cline_Env_Solaris_Admin"
)

$requiredFiles = @("START_HIER.md", "ENVIRONMENT.md", "AGENTS.md", ".clineignore", "VERSION", "MANIFEST.json", "SHA256SUMS.txt")
$requiredDirs = @("shared/rules", "shared/workflows", "shared/skills", "shared/helpers/python", "bootstrap", "scripts", "users", "workspaces", "state", "logs", "audit")
$forbiddenExtensions = @(".exe", ".msi", ".msix", ".appx", ".vsix", ".dmg", ".pkg", ".deb", ".rpm", ".7z", ".zip", ".gguf", ".safetensors", ".onnx")

foreach ($name in $expected) {
    $envRoot = Join-Path $RepoRoot "environments/$name"
    if (-not (Test-Path -LiteralPath $envRoot -PathType Container)) {
        throw "Fehlende Umgebung: $name"
    }

    foreach ($file in $requiredFiles) {
        $path = Join-Path $envRoot $file
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Fehlende Datei in ${name}: $file"
        }
    }

    foreach ($dir in $requiredDirs) {
        $path = Join-Path $envRoot $dir
        if (-not (Test-Path -LiteralPath $path -PathType Container)) {
            throw "Fehlender Ordner in ${name}: $dir"
        }
    }

    Get-Content -LiteralPath (Join-Path $envRoot "MANIFEST.json") -Raw | ConvertFrom-Json | Out-Null

    $badRef = Get-ChildItem -LiteralPath $envRoot -Recurse -File |
        Where-Object { $_.FullName -notmatch "\\users\\|/users/" -and $_.FullName -notmatch "\\state\\|/state/" } |
        Select-String -Pattern "\.\./src/common" -SimpleMatch -ErrorAction SilentlyContinue
    if ($badRef) {
        throw "Umgebung $name enthaelt eine zwingende Referenz auf ../src/common."
    }

    $badBinary = Get-ChildItem -LiteralPath $envRoot -Recurse -File |
        Where-Object { $forbiddenExtensions -contains $_.Extension.ToLowerInvariant() }
    if ($badBinary) {
        throw "Verbotene Binaerdatei in ${name}: $($badBinary[0].FullName)"
    }
}

$gitignore = Get-Content -LiteralPath (Join-Path $RepoRoot ".gitignore") -Raw
$mustContain = @(".codex/", ".agents/", "CODEX_LOCAL.md", "CODEX_NOTES.md", "*.codex.md", "*.local.md", "!**/users/**/.gitkeep", "!**/state/.gitkeep")
foreach ($entry in $mustContain) {
    if ($gitignore -notlike "*$entry*") {
        throw ".gitignore enthaelt Pflichtmuster nicht: $entry"
    }
}

Write-Host "Alle exportierbaren Umgebungen sind valide."