[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$AgentId = "",
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = (Resolve-Path (Join-Path $ScriptDir "..")).Path
}
$root = [System.IO.Path]::GetFullPath($RootPath)
$domain = if ($env:USERDOMAIN) { $env:USERDOMAIN } else { $env:COMPUTERNAME }
$user = if ($env:USERNAME) { $env:USERNAME } else { [Environment]::UserName }
$computer = if ($env:COMPUTERNAME) { $env:COMPUTERNAME } else { [Environment]::MachineName }
$sid = ""
try { $sid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value } catch { $sid = "" }
$safe = (($domain + "_" + $user) -replace "[^A-Za-z0-9_.-]", "_").ToLowerInvariant()
$userRoot = Join-Path $root "users/windows/$safe"
if ([string]::IsNullOrWhiteSpace($AgentId)) {
    $AgentId = (Get-Date).ToString("yyyyMMdd-HHmmss") + "-" + ([guid]::NewGuid().ToString("N").Substring(0, 8))
}
$agentRoot = Join-Path $userRoot "agents/$AgentId"
$ownerPath = Join-Path $userRoot "OWNER.json"

if (Test-Path -LiteralPath $ownerPath) {
    $existing = Get-Content -LiteralPath $ownerPath -Raw | ConvertFrom-Json
    if ($existing.username -ne $user -or ($existing.domain -and $existing.domain -ne $domain)) {
        throw "OWNER.json gehoert nicht zum aktuellen Nutzer: $ownerPath"
    }
}

$plan = [ordered]@{
    dryRun = [bool]$DryRun
    userRoot = $userRoot
    agentRoot = $agentRoot
    ownerPath = $ownerPath
}
if ($DryRun) {
    $plan | ConvertTo-Json -Depth 10
    return
}

New-Item -ItemType Directory -Force -Path $agentRoot, (Join-Path $agentRoot "memory"), (Join-Path $agentRoot "outbox/memory-proposals"), (Join-Path $userRoot "memory"), (Join-Path $userRoot "scratch"), (Join-Path $userRoot "notes"), (Join-Path $userRoot "logs"), (Join-Path $userRoot "outbox") | Out-Null

$createdAt = (Get-Date).ToString("o")
if (Test-Path -LiteralPath $ownerPath) {
    $existing = Get-Content -LiteralPath $ownerPath -Raw | ConvertFrom-Json
    if ($existing.createdAt) { $createdAt = $existing.createdAt }
}
$owner = [ordered]@{
    schemaVersion = 1
    environment = "Cline_Env_Windows_User"
    os = "Windows"
    role = "User"
    domain = $domain
    username = $user
    computerName = $computer
    userSid = $sid
    writableBy = "owner-only"
    createdAt = $createdAt
    updatedAt = (Get-Date).ToString("o")
}
$owner | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ownerPath -Encoding UTF8

Set-Content -LiteralPath (Join-Path $userRoot "IMMER_LESEN.md") -Encoding UTF8 -Value "# Immer Lesen`n`nDieser Ordner gehoert zu $domain\$user. Wenn du nicht dieser Nutzer bist, schreibe nicht in diesen Ordner.`n`nErlaubte Schreibbereiche: eigener Agentenordner, scratch, notes, logs und outbox.`n"
Set-Content -LiteralPath (Join-Path $agentRoot "AGENT_POLICY.md") -Encoding UTF8 -Value "# Agent Policy`n`nArbeite nur fuer den Owner dieses Nutzerordners. Pruefe OWNER.json vor Schreibzugriffen. Nutze zentrale Helper aus AIRGAP_CLINE_HOME.`n"
Set-Content -LiteralPath (Join-Path $agentRoot "CURRENT_TASK.md") -Encoding UTF8 -Value "# Aktuelle Aufgabe`n`nNoch keine Aufgabe dokumentiert.`n"
$userMemoryTemplate = @'
# User Memory

scope: user
schema: airgap-user-memory/v1

## READ_FIRST
- Keine Secrets, Tokens, Passwoerter oder privaten Rohdaten speichern.

## PREFERENCES
- Noch keine dauerhaften Nutzerpraeferenzen erfasst.

## DO_NOT
- Nicht in fremde Nutzer- oder Agentenordner schreiben.
'@
Set-Content -LiteralPath (Join-Path $userRoot "memory/USER_MEMORY.md") -Encoding UTF8 -Value $userMemoryTemplate
$sessionMemoryTemplate = @'
# Session Memory

scope: agent-session
schema: airgap-session-memory/v1

## TASK
- Noch keine Aufgabe dokumentiert.

## SUMMARY
- Noch keine Zusammenfassung erfasst.

## MEMORY_PROPOSALS
- Dauerhafte Erkenntnisse als Vorschlaege nach `outbox/memory-proposals/` schreiben.
'@
Set-Content -LiteralPath (Join-Path $agentRoot "memory/SESSION.md") -Encoding UTF8 -Value $sessionMemoryTemplate
Set-Content -LiteralPath (Join-Path $agentRoot "WORKSPACE_BINDINGS.json") -Encoding UTF8 -Value "{}"

$stateDir = Join-Path $root "state"
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
@{
    schemaVersion = 1
    userRoot = $userRoot
    agentRoot = $agentRoot
    agentId = $AgentId
    updatedAt = (Get-Date).ToString("o")
} | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $stateDir "last-agent.json") -Encoding UTF8

Write-Output $agentRoot