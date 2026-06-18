[CmdletBinding()]
param([string]$RootPath = "")

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) { $RootPath = Split-Path -Parent $ScriptDir }
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

function Get-TextFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Missing file for Cline behavior simulation: $Path"
    }
    Get-Content -LiteralPath $Path -Raw
}

function Assert-ContainsAll {
    param(
        [string]$Scope,
        [string]$Text,
        [string[]]$Needles
    )
    foreach ($needle in $Needles) {
        if ($Text.IndexOf($needle, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            throw "Cline behavior simulation failed in ${Scope}: missing '$needle'"
        }
    }
}

function Assert-Sequence {
    param(
        [string]$Scope,
        [string]$Text,
        [string[]]$Needles
    )
    $cursor = -1
    foreach ($needle in $Needles) {
        $index = $Text.IndexOf($needle, [System.StringComparison]::OrdinalIgnoreCase)
        if ($index -lt 0) {
            throw "Cline behavior simulation failed in ${Scope}: missing sequence item '$needle'"
        }
        if ($index -le $cursor) {
            throw "Cline behavior simulation failed in ${Scope}: sequence item '$needle' is out of order"
        }
        $cursor = $index
    }
}

function Get-AgentContext {
    param([string]$EnvironmentRoot)
    $parts = @()
    foreach ($file in @(
        "START_HERE.md",
        "bootstrap/FIRST_READ.md",
        "AGENTS.md",
        "ENVIRONMENT.md",
        "bootstrap/00-airgap-central-environment.md"
    )) {
        $path = Join-Path $EnvironmentRoot $file
        $parts += Get-TextFile -Path $path
    }
    foreach ($folder in @("shared/rules", "shared/workflows", "shared/skills", "shared/memory")) {
        Get-ChildItem -LiteralPath (Join-Path $EnvironmentRoot $folder) -Recurse -File -Include *.md | Sort-Object FullName | ForEach-Object {
            $parts += Get-Content -LiteralPath $_.FullName -Raw
        }
    }
    $parts -join "`n`n---`n`n"
}

$scenarioChecks = @(
    [ordered]@{
        Name = "first-read-before-any-task"
        Needles = @(
            "Before any task",
            "AIRGAP_CLINE_HOME",
            "bootstrap/FIRST_READ.md",
            "AGENTS.md",
            "ENVIRONMENT.md",
            "MANIFEST.json",
            "VERSION",
            "shared/rules/"
        )
    },
    [ordered]@{
        Name = "stop-when-central-path-is-invalid"
        Needles = @(
            'Stop when `AIRGAP_CLINE_HOME` is missing',
            "multiple Air-Gap stubs point to contradictory paths",
            "ask for the valid path"
        )
    },
    [ordered]@{
        Name = "provider-boundary"
        Needles = @(
            "Do not change provider, model, authentication, or AI-server settings",
            "does not configure providers, models, authentication, or AI servers",
            "Provider, model, authentication, and AI-server configuration are outside this environment"
        )
    },
    [ordered]@{
        Name = "external-workspace-no-pollution"
        Needles = @(
            'Register target folders under `workspaces/<hash>/`',
            'Do not create persistent `.cline`, `.clinerules`, skills, workflows, helpers, or memory files in target repositories',
            "helper-output",
            "Target repositories receive only project changes"
        )
    },
    [ordered]@{
        Name = "memory-routing"
        Needles = @(
            "Shared workspace memory",
            "memory/MEMORY.md",
            "memory helper",
            "proposals",
            "Never store secrets, raw logs, chat transcripts, or chain-of-thought"
        )
    },
    [ordered]@{
        Name = "owner-and-agent-protection"
        Needles = @(
            'Read `OWNER.json` before writing under `users/`',
            "If the owner does not match the current user and host, do not write there",
            "Stop before writing to a foreign user or agent folder"
        )
    },
    [ordered]@{
        Name = "central-helper-use"
        Needles = @(
            'Prefer helper scripts from `shared/helpers/`',
            "Execute helpers from the central environment path",
            "Do not copy helpers into target repositories"
        )
    },
    [ordered]@{
        Name = "airgap-assumptions"
        Needles = @(
            "Assume the target environment has no internet access",
            "Do not start downloads, marketplace installations, or cloud lookups",
            "Do not invent replacement artifacts"
        )
    }
)

foreach ($name in $expected) {
    $envRoot = Join-Path $RepoRoot "environments/$name"
    if (-not (Test-Path -LiteralPath $envRoot -PathType Container)) {
        throw "Missing environment for Cline behavior simulation: $name"
    }

    $startHere = Get-TextFile -Path (Join-Path $envRoot "START_HERE.md")
    Assert-Sequence -Scope "$name START_HERE.md read order" -Text $startHere -Needles @(
        "START_HERE.md",
        "bootstrap/FIRST_READ.md",
        "AGENTS.md",
        "ENVIRONMENT.md",
        "MANIFEST.json",
        "VERSION",
        "shared/rules/"
    )

    $firstRead = Get-TextFile -Path (Join-Path $envRoot "bootstrap/FIRST_READ.md")
    Assert-Sequence -Scope "$name FIRST_READ.md sequence" -Text $firstRead -Needles @(
        'Resolve `AIRGAP_CLINE_HOME`',
        "Read this file completely",
        'Read `AGENTS.md`',
        'Check `state/bootstrap-status.json`',
        "If an external workspace is used"
    )

    $agentContext = Get-AgentContext -EnvironmentRoot $envRoot
    foreach ($scenario in $scenarioChecks) {
        Assert-ContainsAll -Scope "$name scenario '$($scenario.Name)'" -Text $agentContext -Needles $scenario.Needles
    }
}

Write-Host "Cline Markdown behavior simulation passed."
