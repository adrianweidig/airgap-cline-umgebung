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
$requiredDirs = @("shared/rules", "shared/workflows", "shared/skills", "shared/helpers/python", "shared/memory/schemas", "shared/memory/templates", "bootstrap", "scripts", "users", "workspaces", "state", "logs", "audit")
$forbiddenExtensions = @(".exe", ".msi", ".msix", ".appx", ".vsix", ".dmg", ".pkg", ".deb", ".rpm", ".7z", ".zip", ".gguf", ".safetensors", ".onnx", ".pt", ".pth", ".ckpt")
$requiredRules = @("00-first-read-zentralumgebung.md", "00-airgap-grundsaetze.md", "05-plattform-und-variante.md", "10-zentralpfad-ist-quell-der-wahrheit.md", "20-nutzer-und-agententrennung.md", "30-keine-repo-verschmutzung.md", "40-zentrale-helper-nutzen.md", "50-verifikation-und-dokumentation.md", "60-koordiniertes-memory.md")
$requiredWorkflows = @("00-initialisierung.md", "01-zentralstubs-synchronisieren.md", "02-nutzerordner-anlegen.md", "03-first-read-verhalten-pruefen.md", "10-externer-arbeitsordner-registrieren.md", "20-klassische-aufgabe-bearbeiten.md", "30-helper-script-nutzen.md", "40-airgap-abnahme.md", "90-selbstverbesserung.md", "50-memory-lesen.md", "51-memory-vorschlagen.md", "52-memory-konsolidieren.md")
$requiredSkills = @("airgap-bootstrap", "plattform-variante", "nutzer-agenten-schutz", "externer-arbeitsordner", "zentrale-helper", "airgap-validierung", "koordiniertes-memory")

function Assert-FileContains {
    param([string]$Path, [string]$Needle)
    $content = Get-Content -LiteralPath $Path -Raw
    if ($content -notlike "*$Needle*" -and -not ($Needle -eq "AIRGAP-CLINE-MANAGED:v2" -and ($content -like "*AIRGAP-CLINE-MANAGED:v3*" -or $content -like "*AIRGAP-CLINE-MANAGED:v4*"))) {
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
    if (-not $manifest.firstReadContract.enabled) { throw "MANIFEST braucht aktivierten First-Read-Vertrag: $name." }
    Assert-FileContains -Path (Join-Path $envRoot "bootstrap/FIRST_READ.md") -Needle "AIRGAP-CLINE-FIRST-READ:v1"
    Assert-FileContains -Path (Join-Path $envRoot "bootstrap/00-airgap-zentralumgebung.md") -Needle "FIRST_READ_CONTRACT"
    Assert-FileContains -Path (Join-Path $envRoot "AGENTS.md") -Needle "## Absolute Startpflicht"
    Assert-FileContains -Path (Join-Path $envRoot "START_HIER.md") -Needle "## Dauerhaftes Verhalten Nach Initialisierung"

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

    foreach ($helper in @("shared/helpers/python/register_workspace.py", "shared/helpers/python/guard_owner.py", "shared/helpers/python/memory_update.py", "shared/memory/schemas/airgap-memory.schema.json", "shared/memory/templates/MEMORY.md")) {
        if (-not (Test-Path -LiteralPath (Join-Path $envRoot $helper) -PathType Leaf)) {
            throw "Fehlender Python-Helper in ${name}: $helper"
        }
    }

    if ($name -like "*Windows*") {
        foreach ($script in @("Initialize-AirgapClineEnvironment.ps1", "Sync-ClineGlobalStubs.ps1", "New-AirgapClineUserWorkspace.ps1", "Register-ExternalWorkspace.ps1", "Test-AirgapOwner.ps1", "Update-AirgapMemory.ps1")) {
            $path = Join-Path $envRoot "scripts/$script"
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Fehlendes Windows-Skript in ${name}: $script" }
        }
        Assert-FileContains -Path (Join-Path $envRoot "scripts/Initialize-AirgapClineEnvironment.ps1") -Needle "DryRun"
        Assert-FileContains -Path (Join-Path $envRoot "scripts/Initialize-AirgapClineEnvironment.ps1") -Needle "Repair"
        Assert-FileContains -Path (Join-Path $envRoot "scripts/Sync-ClineGlobalStubs.ps1") -Needle "AIRGAP-CLINE-STUB:v4"
        Assert-FileContains -Path (Join-Path $envRoot "scripts/Sync-ClineGlobalStubs.ps1") -Needle "bootstrap\FIRST_READ.md"
    } else {
        foreach ($script in @("initialize-airgap-cline-environment.sh", "sync-cline-global-stubs.sh", "new-airgap-cline-user-workspace.sh", "register-external-workspace.sh", "guard-owner.sh", "update-airgap-memory.sh")) {
            $path = Join-Path $envRoot "scripts/$script"
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Fehlendes POSIX-Skript in ${name}: $script" }
        }
        Assert-FileContains -Path (Join-Path $envRoot "scripts/initialize-airgap-cline-environment.sh") -Needle "--dry-run"
        Assert-FileContains -Path (Join-Path $envRoot "scripts/sync-cline-global-stubs.sh") -Needle "AIRGAP-CLINE-STUB:v4"
        Assert-FileContains -Path (Join-Path $envRoot "scripts/sync-cline-global-stubs.sh") -Needle "bootstrap/FIRST_READ.md"
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
        & $python.Source -c "import ast, pathlib, sys; ast.parse(pathlib.Path(sys.argv[1]).read_text(encoding='utf-8'))" $_.FullName
        if ($LASTEXITCODE -ne 0) { throw "Python-Syntaxfehler: $($_.FullName)" }
    }
}

$sampleEnv = Join-Path $RepoRoot "environments/Cline_Env_Windows_User"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("airgap-memory-test-" + [guid]::NewGuid().ToString("N"))
try {
    Copy-Item -LiteralPath $sampleEnv -Destination $tempRoot -Recurse
    $workspace = Join-Path $tempRoot "workspaces/testhash"
    New-Item -ItemType Directory -Force -Path $workspace | Out-Null
    @{ schemaVersion = 1; hash = "testhash"; targetPath = $tempRoot } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $workspace "WORKSPACE.json") -Encoding UTF8
    $pythonForMemory = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pythonForMemory) { $pythonForMemory = Get-Command python3 -ErrorAction SilentlyContinue }
    if ($pythonForMemory) {
        $helper = Join-Path $tempRoot "shared/helpers/python/memory_update.py"
        & $pythonForMemory.Source $helper --root $tempRoot init --workspace testhash | Out-Null
        & $pythonForMemory.Source $helper --root $tempRoot propose --workspace testhash --type fact --text "Testfakt fuer Memory-Validierung." --agent-id test-agent | Tee-Object -Variable proposalPath | Out-Null
        & $pythonForMemory.Source $helper --root $tempRoot apply --workspace testhash --proposal ($proposalPath | Select-Object -Last 1) --agent-id test-agent | Out-Null
        & $pythonForMemory.Source $helper --root $tempRoot validate --workspace testhash | Out-Null
        if (-not (Test-Path -LiteralPath (Join-Path $workspace "memory/EVENTS.jsonl"))) { throw "Memory EVENTS.jsonl wurde nicht erzeugt." }
    }
} finally {
    if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}

Write-Host "Alle exportierbaren Umgebungen sind valide."