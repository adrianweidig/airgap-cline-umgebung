[CmdletBinding()]
param([string]$RootPath = "", [string]$AgentId = "default-agent")
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($RootPath)) { $RootPath = Split-Path -Parent $PSScriptRoot }
$root = [System.IO.Path]::GetFullPath($RootPath)
$user = if ($env:USERNAME) { $env:USERNAME } else { "unknown" }
$domain = if ($env:USERDOMAIN) { $env:USERDOMAIN } else { "local" }
$hostName = if ($env:COMPUTERNAME) { $env:COMPUTERNAME } else { [System.Net.Dns]::GetHostName() }
$ownerName = (($domain + "_" + $user) -replace '[^A-Za-z0-9_.-]', '_')
$safeAgent = ($AgentId -replace '[^A-Za-z0-9_.-]', '_')
$userRoot = Join-Path $root ("users/windows/" + $ownerName)
$agentRoot = Join-Path $userRoot ("agents/" + $safeAgent)
$ownerPath = Join-Path $userRoot "OWNER.json"
if (Test-Path -LiteralPath $ownerPath) {
    $owner = Get-Content -LiteralPath $ownerPath -Raw | ConvertFrom-Json
    if ($owner.user -ne $user -or $owner.domain -ne $domain) { throw "OWNER.json does not belong to the current user: $ownerPath" }
}
foreach ($dir in @($userRoot, "$userRoot\agents", "$userRoot\scratch", "$userRoot\notes", "$userRoot\logs", "$userRoot\outbox", "$userRoot\memory", $agentRoot, "$agentRoot\memory", "$agentRoot\outbox", "$agentRoot\outbox\memory-proposals")) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}
[ordered]@{ schemaVersion = 1; platform = "windows"; user = $user; domain = $domain; host = $hostName; createdAt = (Get-Date).ToString("o") } | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $ownerPath -Encoding UTF8
Set-Content -LiteralPath (Join-Path $userRoot "ALWAYS_READ.md") -Encoding UTF8 -Value "# Always Read`n`nThis folder belongs to $domain\$user. If you are not this user, do not write here.`n`nAllowed write areas: the owner's agent folder, scratch, notes, logs, outbox, and memory.`n"
Set-Content -LiteralPath (Join-Path $userRoot "memory/USER_MEMORY.md") -Encoding UTF8 -Value "# User Memory`n`n- No durable user preferences recorded yet.`n"
Set-Content -LiteralPath (Join-Path $agentRoot "AGENT_POLICY.md") -Encoding UTF8 -Value "# Agent Policy`n`nWork only for the owner of this user folder. Check OWNER.json before writes. Use central helpers from AIRGAP_CLINE_HOME.`n"
Set-Content -LiteralPath (Join-Path $agentRoot "CURRENT_TASK.md") -Encoding UTF8 -Value "# Current Task`n`nNo task recorded yet.`n"
Set-Content -LiteralPath (Join-Path $agentRoot "WORKSPACE_BINDINGS.json") -Encoding UTF8 -Value "[]`n"
Set-Content -LiteralPath (Join-Path $agentRoot "memory/SESSION.md") -Encoding UTF8 -Value "# Session Memory`n`n## Current Task`n- No task recorded yet.`n`n## Summary`n- No summary recorded yet.`n`n## Durable Proposals`n- Write durable findings as proposals under outbox/memory-proposals/.`n"
$agentRoot
