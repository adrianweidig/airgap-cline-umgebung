[CmdletBinding()]
param(
    [string]$RootPath = "",
    [switch]$NoGlobalStub,
    [switch]$DryRun,
    [switch]$Repair
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = (Resolve-Path (Join-Path $ScriptDir "..")).Path
}
$root = [System.IO.Path]::GetFullPath($RootPath)
$errors = @()
$versionPath = Join-Path $root "VERSION"
$version = if (Test-Path -LiteralPath $versionPath) { (Get-Content -LiteralPath $versionPath -Raw).Trim() } else { "unknown" }

function Write-BootstrapStatus {
    param([string]$Status, [string]$AgentRoot, $StubTargets, [string[]]$Errors)
    $identityDomain = if ($env:USERDOMAIN) { $env:USERDOMAIN } else { $env:COMPUTERNAME }
    $identityUser = if ($env:USERNAME) { $env:USERNAME } else { [Environment]::UserName }
    $statusObject = [ordered]@{
        schemaVersion = 2
        status = $Status
        environment = "Cline_Env_Windows_Admin"
        version = $version
        os = "Windows"
        role = "Admin"
        rootPath = $root
        domain = $identityDomain
        username = $identityUser
        host = if ($env:COMPUTERNAME) { $env:COMPUTERNAME } else { [Environment]::MachineName }
        agentRoot = $AgentRoot
        dryRun = [bool]$DryRun
        repair = [bool]$Repair
        noGlobalStub = [bool]$NoGlobalStub
        providerChanged = $false
        checkedAt = (Get-Date).ToString("o")
        stubTargets = $StubTargets
        errors = $Errors
    }
    if (-not $DryRun) {
        $stateDir = Join-Path $root "state"
        New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
        $statusObject | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath (Join-Path $stateDir "bootstrap-status.json") -Encoding UTF8
    }
    $statusObject | ConvertTo-Json -Depth 20
}

try {
    foreach ($required in @("START_HIER.md", "AGENTS.md", "ENVIRONMENT.md", "MANIFEST.json", "shared/rules", "shared/workflows", "shared/skills", "shared/helpers/python")) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $required))) {
            throw "Fehlender Bestandteil: $required"
        }
    }

    $agentOutput = & (Join-Path $ScriptDir "New-AirgapClineUserWorkspace.ps1") -RootPath $root -DryRun:$DryRun
    $agentRoot = ($agentOutput | Select-Object -Last 1)
    if ($DryRun) {
        $agentJson = ($agentOutput | Out-String).Trim()
        if ($agentJson) {
            try {
                $agentPlan = $agentJson | ConvertFrom-Json
                if ($agentPlan.agentRoot) { $agentRoot = $agentPlan.agentRoot }
            } catch {
                $agentRoot = $agentJson
            }
        }
    }
    $stubTargets = @()
    if (-not $NoGlobalStub) {
        $syncOutput = & (Join-Path $ScriptDir "Sync-ClineGlobalStubs.ps1") -RootPath $root -DryRun:$DryRun -Repair:$Repair
        $syncJson = ($syncOutput | Out-String).Trim()
        if ($syncJson) {
            try {
                $sync = $syncJson | ConvertFrom-Json
                $stubTargets = $sync.targets
            } catch {
                $stubTargets = @($syncJson)
            }
        }
    }

    Write-BootstrapStatus -Status "ok" -AgentRoot $agentRoot -StubTargets $stubTargets -Errors @()
    Write-Host "Initialisierung abgeschlossen fuer Cline_Env_Windows_Admin."
} catch {
    $errors += $_.Exception.Message
    Write-BootstrapStatus -Status "error" -AgentRoot "" -StubTargets @() -Errors $errors
    throw
}