[CmdletBinding()]
param([string]$RootPath = "")
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) { $RootPath = Split-Path -Parent $ScriptDir }
$RepoRoot = [System.IO.Path]::GetFullPath($RootPath)
$expected = @("Cline_Env_Windows_User", "Cline_Env_Windows_Admin", "Cline_Env_Linux_User", "Cline_Env_Linux_Admin", "Cline_Env_Mac_User", "Cline_Env_Mac_Admin", "Cline_Env_Solaris_User", "Cline_Env_Solaris_Admin")
$requiredFiles = @("START_HERE.md", "ENVIRONMENT.md", "AGENTS.md", ".clineignore", "VERSION", "MANIFEST.json", "SHA256SUMS.txt")
$requiredDirs = @("shared/rules", "shared/workflows", "shared/skills", "shared/helpers/python", "shared/memory/schemas", "shared/memory/templates", "bootstrap", "scripts", "users", "workspaces", "state", "logs", "audit")
$forbiddenExtensions = @(".exe", ".msi", ".msix", ".appx", ".vsix", ".dmg", ".pkg", ".deb", ".rpm", ".7z", ".zip", ".gguf", ".safetensors", ".onnx", ".pt", ".pth", ".ckpt")
$requiredRules = @("00-first-read-central-environment.md", "00-airgap-principles.md", "05-platform-and-variant.md", "10-central-path-is-source-of-truth.md", "20-user-and-agent-isolation.md", "30-no-repo-pollution.md", "40-use-central-helpers.md", "50-verification-and-documentation.md", "60-coordinated-memory.md")
$requiredWorkflows = @("00-initialization.md", "01-sync-central-stubs.md", "02-create-user-folder.md", "03-check-first-read-behavior.md", "10-register-external-workspace.md", "20-handle-standard-task.md", "30-use-helper-script.md", "40-airgap-acceptance.md", "50-read-memory.md", "51-propose-memory.md", "52-consolidate-memory.md", "90-self-improvement.md")
$requiredSkills = @("airgap-bootstrap", "platform-variant", "user-agent-protection", "external-workspace", "central-helpers", "airgap-validation", "coordinated-memory")
function Assert-FileContains { param([string]$Path, [string]$Needle); $content = Get-Content -LiteralPath $Path -Raw; if ($content -notlike "*$Needle*") { throw "Required text missing: $Path :: $Needle" } }
foreach ($name in $expected) {
    $envRoot = Join-Path $RepoRoot "environments/$name"
    if (-not (Test-Path -LiteralPath $envRoot -PathType Container)) { throw "Missing environment: $name" }
    foreach ($file in $requiredFiles) { if (-not (Test-Path -LiteralPath (Join-Path $envRoot $file) -PathType Leaf)) { throw "Missing file in ${name}: $file" } }
    foreach ($dir in $requiredDirs) { if (-not (Test-Path -LiteralPath (Join-Path $envRoot $dir) -PathType Container)) { throw "Missing directory in ${name}: $dir" } }
    $manifest = Get-Content -LiteralPath (Join-Path $envRoot "MANIFEST.json") -Raw | ConvertFrom-Json
    if ($manifest.name -ne $name) { throw "MANIFEST name mismatch for $name." }
    if ($manifest.language -ne "en") { throw "MANIFEST must declare English content: $name." }
    if ($manifest.assumesClineAlreadyConfigured -ne $true) { throw "MANIFEST must mark Cline as a prerequisite: $name." }
    if ($manifest.changesProviderConfiguration -ne $false) { throw "MANIFEST must not mark provider changes: $name." }
    if (-not $manifest.firstReadContract.enabled) { throw "MANIFEST needs an enabled first-read contract: $name." }
    Assert-FileContains -Path (Join-Path $envRoot "bootstrap/FIRST_READ.md") -Needle "AIRGAP-CLINE-FIRST-READ:v1"
    Assert-FileContains -Path (Join-Path $envRoot "bootstrap/00-airgap-central-environment.md") -Needle "FIRST_READ_CONTRACT"
    Assert-FileContains -Path (Join-Path $envRoot "AGENTS.md") -Needle "## Absolute Start Requirement"
    Assert-FileContains -Path (Join-Path $envRoot "START_HERE.md") -Needle "## Persistent Behavior After Initialization"
    foreach ($rule in $requiredRules) { $path = Join-Path $envRoot "shared/rules/$rule"; if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing rule in ${name}: $rule" }; Assert-FileContains -Path $path -Needle "AIRGAP-CLINE-MANAGED:v5" }
    foreach ($workflow in $requiredWorkflows) { $path = Join-Path $envRoot "shared/workflows/$workflow"; if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing workflow in ${name}: $workflow" }; Assert-FileContains -Path $path -Needle "AIRGAP-CLINE-MANAGED:v5" }
    foreach ($skill in $requiredSkills) { $path = Join-Path $envRoot "shared/skills/$skill/SKILL.md"; if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing skill in ${name}: $skill" }; Assert-FileContains -Path $path -Needle "AIRGAP-CLINE-MANAGED" }
    foreach ($helper in @("shared/helpers/python/register_workspace.py", "shared/helpers/python/guard_owner.py", "shared/helpers/python/memory_update.py", "shared/memory/schemas/airgap-memory.schema.json", "shared/memory/templates/MEMORY.md")) { if (-not (Test-Path -LiteralPath (Join-Path $envRoot $helper) -PathType Leaf)) { throw "Missing helper or memory file in ${name}: $helper" } }
    if ($name -like "*Windows*") {
        foreach ($script in @("Initialize-AirgapClineEnvironment.ps1", "Sync-ClineGlobalStubs.ps1", "New-AirgapClineUserWorkspace.ps1", "Register-ExternalWorkspace.ps1", "Test-AirgapOwner.ps1", "Update-AirgapMemory.ps1")) { if (-not (Test-Path -LiteralPath (Join-Path $envRoot "scripts/$script") -PathType Leaf)) { throw "Missing Windows script in ${name}: $script" } }
        Assert-FileContains -Path (Join-Path $envRoot "scripts/Initialize-AirgapClineEnvironment.ps1") -Needle "DryRun"
        Assert-FileContains -Path (Join-Path $envRoot "scripts/Initialize-AirgapClineEnvironment.ps1") -Needle "Repair"
        Assert-FileContains -Path (Join-Path $envRoot "scripts/Sync-ClineGlobalStubs.ps1") -Needle "AIRGAP-CLINE-STUB:v5"
        Assert-FileContains -Path (Join-Path $envRoot "scripts/Sync-ClineGlobalStubs.ps1") -Needle "bootstrap\FIRST_READ.md"
    } else {
        foreach ($script in @("initialize-airgap-cline-environment.sh", "sync-cline-global-stubs.sh", "new-airgap-cline-user-workspace.sh", "register-external-workspace.sh", "guard-owner.sh", "update-airgap-memory.sh")) { if (-not (Test-Path -LiteralPath (Join-Path $envRoot "scripts/$script") -PathType Leaf)) { throw "Missing POSIX script in ${name}: $script" } }
        Assert-FileContains -Path (Join-Path $envRoot "scripts/initialize-airgap-cline-environment.sh") -Needle "--dry-run"
        Assert-FileContains -Path (Join-Path $envRoot "scripts/sync-cline-global-stubs.sh") -Needle "AIRGAP-CLINE-STUB:v5"
        Assert-FileContains -Path (Join-Path $envRoot "scripts/sync-cline-global-stubs.sh") -Needle "bootstrap/FIRST_READ.md"
    }
    $badRef = Get-ChildItem -LiteralPath $envRoot -Recurse -File | Select-String -Pattern "../src/common" -SimpleMatch -ErrorAction SilentlyContinue
    if ($badRef) { throw "Environment $name contains a mandatory reference to ../src/common." }
    $badBinary = Get-ChildItem -LiteralPath $envRoot -Recurse -File | Where-Object { $forbiddenExtensions -contains $_.Extension.ToLowerInvariant() }
    if ($badBinary) { throw "Forbidden binary file in ${name}: $($badBinary[0].FullName)" }
}
$gitignore = Get-Content -LiteralPath (Join-Path $RepoRoot ".gitignore") -Raw
foreach ($entry in @(".codex/", ".agents/", "CODEX_LOCAL.md", "CODEX_NOTES.md", "*.codex.md", "*.local.md", "!**/users/**/.gitkeep", "!**/state/.gitkeep", "*.7z", "*.zip", "*.vsix")) { if ($gitignore -notlike "*$entry*") { throw ".gitignore is missing required pattern: $entry" } }
$psErrors = @()
Get-ChildItem -Path (Join-Path $RepoRoot "scripts"), (Join-Path $RepoRoot "environments") -Recurse -Include *.ps1 | ForEach-Object { $tokens = $null; $parseErrors = $null; [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null; if ($parseErrors) { $psErrors += "$($_.FullName): $($parseErrors[0].Message)" } }
if ($psErrors.Count -gt 0) { throw ($psErrors -join "`n") }
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
if ($python) {
    Get-ChildItem -LiteralPath (Join-Path $RepoRoot "environments") -Recurse -Filter *.py | ForEach-Object { & $python.Source -c "import ast, pathlib, sys; ast.parse(pathlib.Path(sys.argv[1]).read_text(encoding='utf-8'))" $_.FullName; if ($LASTEXITCODE -ne 0) { throw "Python syntax error: $($_.FullName)" } }
    $sampleEnv = Join-Path $RepoRoot "environments/Cline_Env_Windows_User"
    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("airgap-memory-test-" + [guid]::NewGuid().ToString("N"))
    try {
        Copy-Item -LiteralPath $sampleEnv -Destination $tempRoot -Recurse
        $workspace = Join-Path $tempRoot "workspaces/testhash"
        New-Item -ItemType Directory -Force -Path $workspace | Out-Null
        @{ schemaVersion = 1; hash = "testhash"; targetPath = $tempRoot } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $workspace "WORKSPACE.json") -Encoding UTF8
        $helper = Join-Path $tempRoot "shared/helpers/python/memory_update.py"
        & $python.Source $helper --root $tempRoot init --workspace testhash | Out-Null
        & $python.Source $helper --root $tempRoot propose --workspace testhash --type fact --text "Memory validation fact." --agent-id test-agent | Tee-Object -Variable proposalPath | Out-Null
        & $python.Source $helper --root $tempRoot apply --workspace testhash --proposal ($proposalPath | Select-Object -Last 1) --agent-id test-agent | Out-Null
        & $python.Source $helper --root $tempRoot validate --workspace testhash | Out-Null
        if (-not (Test-Path -LiteralPath (Join-Path $workspace "memory/EVENTS.jsonl"))) { throw "Memory EVENTS.jsonl was not created." }
    } finally { if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force } }
}
$nonAscii = Get-ChildItem -LiteralPath $RepoRoot -Recurse -File -Force | Where-Object { $_.FullName -notmatch "\\.git\\|\\dist\\|\\__pycache__\\" -and $_.Extension -ne ".pyc" } | Select-String -Pattern "[^\x00-\x7F]" -ErrorAction SilentlyContinue
if ($nonAscii) { throw "Non-ASCII content remains: $($nonAscii[0].Path)" }
Write-Host "All exportable environments are valid."
