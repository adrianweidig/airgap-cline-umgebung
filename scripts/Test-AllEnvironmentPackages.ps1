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
$forbiddenExtensions = @(".exe", ".msi", ".msix", ".appx", ".vsix", ".dmg", ".pkg", ".deb", ".rpm", ".7z", ".zip", ".gguf", ".safetensors", ".onnx", ".pt", ".pth", ".ckpt")
$requiredRules = @("00-airgap-grundsaetze.md", "05-plattform-und-variante.md", "10-zentralpfad-ist-quell-der-wahrheit.md", "20-nutzer-und-agententrennung.md", "30-keine-repo-verschmutzung.md", "40-zentrale-helper-nutzen.md", "50-verifikation-und-dokumentation.md")
$requiredWorkflows = @("00-initialisierung.md", "01-zentralstubs-synchronisieren.md", "02-nutzerordner-anlegen.md", "10-externer-arbeitsordner-registrieren.md", "20-klassische-aufgabe-bearbeiten.md", "30-helper-script-nutzen.md", "40-airgap-abnahme.md", "90-selbstverbesserung.md")
$requiredSkills = @("airgap-bootstrap", "plattform-variante", "nutzer-agenten-schutz", "externer-arbeitsordner", "zentrale-helper", "airgap-validierung")

function Assert-FileContains {
    param([string]$Path, [string]$Needle)
    $content = Get-Content -LiteralPath $Path -Raw
    if ($content -notlike "*$Needle*") {
        throw "Datei enthaelt Pflichttext nicht: $Path :: $Needle"
    }
}

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

    $manifest = Get-Content -LiteralPath (Join-Path $envRoot "MANIFEST.json") -Raw | ConvertFrom-Json
    if ($manifest.name -ne $name) { throw "MANIFEST name passt nicht fuer $name." }
    if ($manifest.assumesClineAlreadyConfigured -ne $true) { throw "MANIFEST muss Cline als Voraussetzung markieren: $name." }
    if ($manifest.changesProviderConfiguration -ne $false) { throw "MANIFEST darf keine Provider-Aenderung markieren: $name." }
    if (-not $manifest.schemaVersion) { throw "MANIFEST braucht schemaVersion: $name." }

    foreach ($rule in $requiredRules) {
        $path = Join-Path $envRoot "shared/rules/$rule"
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Fehlende Regel in ${name}: $rule" }
        Assert-FileContains -Path $path -Needle "AIRGAP-CLINE-MANAGED:v2"
    }
    foreach ($workflow in $requiredWorkflows) {
        $path = Join-Path $envRoot "shared/workflows/$workflow"
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Fehlender Workflow in ${name}: $workflow" }
        Assert-FileContains -Path $path -Needle "AIRGAP-CLINE-MANAGED:v2"
    }
    foreach ($skill in $requiredSkills) {
        $path = Join-Path $envRoot "shared/skills/$skill/SKILL.md"
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Fehlender Skill in ${name}: $skill" }
        Assert-FileContains -Path $path -Needle "AIRGAP-CLINE-MANAGED:v2"
    }

    foreach ($helper in @("shared/helpers/python/register_workspace.py", "shared/helpers/python/guard_owner.py")) {
        if (-not (Test-Path -LiteralPath (Join-Path $envRoot $helper) -PathType Leaf)) {
            throw "Fehlender Python-Helper in ${name}: $helper"
        }
    }

    if ($name -like "*Windows*") {
        foreach ($script in @("Initialize-AirgapClineEnvironment.ps1", "Sync-ClineGlobalStubs.ps1", "New-AirgapClineUserWorkspace.ps1", "Register-ExternalWorkspace.ps1", "Test-AirgapOwner.ps1")) {
            $path = Join-Path $envRoot "scripts/$script"
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Fehlendes Windows-Skript in ${name}: $script" }
        }
        Assert-FileContains -Path (Join-Path $envRoot "scripts/Initialize-AirgapClineEnvironment.ps1") -Needle "DryRun"
        Assert-FileContains -Path (Join-Path $envRoot "scripts/Initialize-AirgapClineEnvironment.ps1") -Needle "Repair"
    } else {
        foreach ($script in @("initialize-airgap-cline-environment.sh", "sync-cline-global-stubs.sh", "new-airgap-cline-user-workspace.sh", "register-external-workspace.sh", "guard-owner.sh")) {
            $path = Join-Path $envRoot "scripts/$script"
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Fehlendes POSIX-Skript in ${name}: $script" }
        }
        Assert-FileContains -Path (Join-Path $envRoot "scripts/initialize-airgap-cline-environment.sh") -Needle "--dry-run"
    }

    $badRef = Get-ChildItem -LiteralPath $envRoot -Recurse -File |
        Where-Object { $_.FullName -notmatch "\\users\\|/users/" -and $_.FullName -notmatch "\\state\\|/state/" } |
        Select-String -Pattern "../src/common" -SimpleMatch -ErrorAction SilentlyContinue
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
$mustContain = @(".codex/", ".agents/", "CODEX_LOCAL.md", "CODEX_NOTES.md", "*.codex.md", "*.local.md", "!**/users/**/.gitkeep", "!**/state/.gitkeep", "*.7z", "*.zip", "*.vsix")
foreach ($entry in $mustContain) {
    if ($gitignore -notlike "*$entry*") {
        throw ".gitignore enthaelt Pflichtmuster nicht: $entry"
    }
}

$psErrors = @()
Get-ChildItem -Path (Join-Path $RepoRoot "scripts"), (Join-Path $RepoRoot "environments") -Recurse -Include *.ps1 | ForEach-Object {
    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
    if ($parseErrors) { $psErrors += "$($_.FullName): $($parseErrors[0].Message)" }
}
if ($psErrors.Count -gt 0) {
    throw ($psErrors -join "`n")
}

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
if ($python) {
    Get-ChildItem -LiteralPath (Join-Path $RepoRoot "environments") -Recurse -Filter *.py | ForEach-Object {
        & $python.Source -m py_compile $_.FullName
        if ($LASTEXITCODE -ne 0) { throw "Python-Syntaxfehler: $($_.FullName)" }
    }
}

Write-Host "Alle exportierbaren Umgebungen sind valide."