[CmdletBinding()]
param(
    [string]$RootPath = ""
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
$safe = (($domain + "_" + $user) -replace "[^A-Za-z0-9_.-]", "_").ToLowerInvariant()
$userRoot = Join-Path $root "users/windows/$safe"
$agentId = (Get-Date).ToString("yyyyMMdd-HHmmss") + "-" + ([guid]::NewGuid().ToString("N").Substring(0, 8))
$agentRoot = Join-Path $userRoot "agents/$agentId"

New-Item -ItemType Directory -Force -Path $agentRoot, (Join-Path $userRoot "scratch"), (Join-Path $userRoot "notes"), (Join-Path $userRoot "logs"), (Join-Path $userRoot "outbox") | Out-Null

$ownerPath = Join-Path $userRoot "OWNER.json"
if (Test-Path -LiteralPath $ownerPath) {
    $existing = Get-Content -LiteralPath $ownerPath -Raw | ConvertFrom-Json
    if ($existing.username -ne $user) {
        throw "OWNER.json gehoert nicht zum aktuellen Nutzer: $ownerPath"
    }
}

$owner = [ordered]@{
    os = "Windows"
    role = "Admin"
    domain = $domain
    username = $user
    computerName = $env:COMPUTERNAME
    createdAt = (Get-Date).ToString("o")
}
$owner | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ownerPath -Encoding UTF8

Set-Content -LiteralPath (Join-Path $userRoot "IMMER_LESEN.md") -Encoding UTF8 -Value "# Immer Lesen

Dieser Ordner gehoert zu $domain\$user. Wenn du nicht dieser Nutzer bist, schreibe nicht in diesen Ordner.
"
Set-Content -LiteralPath (Join-Path $agentRoot "AGENT_POLICY.md") -Encoding UTF8 -Value "# Agent Policy

Arbeite nur fuer den Owner dieses Nutzerordners. Nutze zentrale Helper aus AIRGAP_CLINE_HOME.
"
Set-Content -LiteralPath (Join-Path $agentRoot "CURRENT_TASK.md") -Encoding UTF8 -Value "# Aktuelle Aufgabe

Noch keine Aufgabe dokumentiert.
"
Set-Content -LiteralPath (Join-Path $agentRoot "WORKSPACE_BINDINGS.json") -Encoding UTF8 -Value "{}"

$stateDir = Join-Path $root "state"
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
@{
    userRoot = $userRoot
    agentRoot = $agentRoot
    agentId = $agentId
    updatedAt = (Get-Date).ToString("o")
} | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $stateDir "last-agent.json") -Encoding UTF8

Write-Host $agentRoot