[CmdletBinding()]
param(
    [string]$RootPath = "",
    [string]$Version = "0.3.0"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = Split-Path -Parent $ScriptDir
}
$RepoRoot = [System.IO.Path]::GetFullPath($RootPath)
$V2 = Join-Path $ScriptDir "Apply-V2Enhancements.ps1"
if (-not (Test-Path -LiteralPath $V2 -PathType Leaf)) {
    throw "Fehlende Basis-Generatorquelle: $V2"
}

& $V2 -RootPath $RepoRoot -Version $Version

function Write-TextFile {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $target = Join-Path $RepoRoot $RelativePath
    $parent = Split-Path -Parent $target
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($target, $Content.TrimStart("`r", "`n"), $utf8NoBom)
}

function Ensure-Directory {
    param([Parameter(Mandatory = $true)][string]$RelativePath)
    $target = Join-Path $RepoRoot $RelativePath
    New-Item -ItemType Directory -Force -Path $target | Out-Null
    $gitkeep = Join-Path $target ".gitkeep"
    if (-not (Test-Path -LiteralPath $gitkeep)) {
        [System.IO.File]::WriteAllText($gitkeep, "", (New-Object System.Text.UTF8Encoding($false)))
    }
}

function ConvertTo-JsonText {
    param([Parameter(Mandatory = $true)]$Object)
    return ($Object | ConvertTo-Json -Depth 40)
}

$Environments = @(
    @{ Name = "Cline_Env_Windows_User"; Os = "Windows"; Role = "User"; Family = "windows"; Primary = "Windows mit VS Code Cline Extension"; RecommendedPath = "C:\Cline_AirGap\Cline_Env_Windows_User oder Netzwerkshare" },
    @{ Name = "Cline_Env_Windows_Admin"; Os = "Windows"; Role = "Admin"; Family = "windows"; Primary = "Windows mit VS Code Cline Extension, zentrale Ablage"; RecommendedPath = "C:\Cline_AirGap\Cline_Env_Windows_Admin oder zentraler Netzwerkshare" },
    @{ Name = "Cline_Env_Linux_User"; Os = "Linux"; Role = "User"; Family = "linux"; Primary = "Linux Cline CLI im Benutzerkontext"; RecommendedPath = "~/cline-airgap/Cline_Env_Linux_User" },
    @{ Name = "Cline_Env_Linux_Admin"; Os = "Linux"; Role = "Admin"; Family = "linux"; Primary = "Linux Cline CLI mit zentraler Ablage"; RecommendedPath = "/opt/cline-airgap/Cline_Env_Linux_Admin" },
    @{ Name = "Cline_Env_Mac_User"; Os = "Mac"; Role = "User"; Family = "mac"; Primary = "macOS Cline CLI oder Editor-Integration"; RecommendedPath = "~/cline-airgap/Cline_Env_Mac_User" },
    @{ Name = "Cline_Env_Mac_Admin"; Os = "Mac"; Role = "Admin"; Family = "mac"; Primary = "macOS zentrale Ablage"; RecommendedPath = "/Users/Shared/Cline_AirGap/Cline_Env_Mac_Admin oder /opt/cline-airgap/Cline_Env_Mac_Admin" },
    @{ Name = "Cline_Env_Solaris_User"; Os = "Solaris"; Role = "User"; Family = "solaris"; Primary = "Solaris POSIX best-effort im Benutzerkontext"; RecommendedPath = "~/cline-airgap/Cline_Env_Solaris_User" },
    @{ Name = "Cline_Env_Solaris_Admin"; Os = "Solaris"; Role = "Admin"; Family = "solaris"; Primary = "Solaris POSIX best-effort mit zentraler Ablage"; RecommendedPath = "/opt/cline-airgap/Cline_Env_Solaris_Admin" }
)

function Get-MemorySchema {
    return @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "airgap-memory.schema.json",
  "title": "Airgap Cline Workspace Memory",
  "type": "object",
  "required": ["schemaVersion", "scope", "workspaceHash", "revision", "updatedAt", "updatedBy", "sections"],
  "properties": {
    "schemaVersion": { "type": "integer", "const": 1 },
    "scope": { "type": "string", "const": "workspace" },
    "workspaceHash": { "type": "string", "minLength": 8 },
    "revision": { "type": "integer", "minimum": 0 },
    "updatedAt": { "type": "string" },
    "updatedBy": { "type": "string" },
    "sections": {
      "type": "object",
      "required": ["readFirst", "facts", "decisions", "active", "next", "doNot", "openQuestions"],
      "properties": {
        "readFirst": { "$ref": "#/$defs/entries" },
        "facts": { "$ref": "#/$defs/entries" },
        "decisions": { "$ref": "#/$defs/entries" },
        "active": { "$ref": "#/$defs/entries" },
        "next": { "$ref": "#/$defs/entries" },
        "doNot": { "$ref": "#/$defs/entries" },
        "openQuestions": { "$ref": "#/$defs/entries" }
      }
    }
  },
  "$defs": {
    "entries": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "text", "createdAt", "createdBy"],
        "properties": {
          "id": { "type": "string" },
          "text": { "type": "string" },
          "createdAt": { "type": "string" },
          "createdBy": { "type": "string" }
        }
      }
    }
  }
}
'@
}

function Get-MemoryEventSchema {
    return @'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "memory-event.schema.json",
  "title": "Airgap Cline Memory Event",
  "type": "object",
  "required": ["schemaVersion", "eventId", "eventType", "workspaceHash", "revision", "createdAt", "createdBy"],
  "properties": {
    "schemaVersion": { "type": "integer", "const": 1 },
    "eventId": { "type": "string" },
    "eventType": { "type": "string" },
    "workspaceHash": { "type": "string" },
    "revision": { "type": "integer" },
    "createdAt": { "type": "string" },
    "createdBy": { "type": "string" },
    "details": { "type": "object" }
  }
}
'@
}

function Get-MemoryTemplate {
    return @'
---
schema: airgap-memory/v1
scope: workspace
workspace_hash: TEMPLATE
revision: 0
updated_at: 1970-01-01T00:00:00Z
updated_by: template
---
# MEMORY

## READ_FIRST
- R-0001 Keine Chatverlaeufe, Rohlogs, Secrets oder Chain-of-Thought in Memory schreiben.

## FACTS
- F-0001 Noch keine dauerhaften Fakten erfasst.

## DECISIONS
- D-0001 Noch keine dauerhaften Entscheidungen erfasst.

## ACTIVE
- A-0001 Kein aktiver Fokus gesetzt.

## NEXT
- N-0001 Keine naechsten Schritte gesetzt.

## DO_NOT
- X-0001 Keine dauerhaften Cline-Dateien in Zielrepos anlegen, ausser der Nutzer verlangt es ausdruecklich.

## OPEN_QUESTIONS
- Q-0001 Keine offenen Fragen erfasst.
'@
}

function Get-ActiveTemplate {
    return @'
# Active

- A-0001 Kein aktiver Fokus gesetzt.
'@
}

function Get-DecisionsTemplate {
    return @'
# Decisions

- D-0001 Noch keine dauerhaften Entscheidungen erfasst.
'@
}

function Get-ProgressTemplate {
    return @'
# Progress

## Status
- Noch kein Status erfasst.

## Risiken
- Keine Risiken erfasst.

## Offene Punkte
- Keine offenen Punkte erfasst.
'@
}

function Get-IndexTemplate {
    return @'
{
  "schemaVersion": 1,
  "scope": "workspace-memory-index",
  "workspaceHash": "TEMPLATE",
  "files": {
    "memory": "MEMORY.md",
    "canonical": "MEMORY.json",
    "active": "ACTIVE.md",
    "decisions": "DECISIONS.md",
    "progress": "PROGRESS.md",
    "events": "EVENTS.jsonl",
    "inbox": "inbox/",
    "locks": "locks/"
  }
}
'@
}

function Get-MemoryReadme {
    return @'
# Koordiniertes Memory

Memory ist ein zentraler Runtime-Datenbestand unter `workspaces/<hash>/memory/`. Zielrepos werden nicht mit Memory-Dateien verschmutzt.

## Regeln

- `MEMORY.md` ist die kurze deterministische Lesefassung fuer Agenten.
- `MEMORY.json` ist die kanonische maschinenlesbare Wahrheit.
- Neue Fakten, Entscheidungen und naechste Schritte werden erst als Vorschlag nach `memory/inbox/*.memory.md` geschrieben.
- Konsolidierte Updates laufen ueber `shared/helpers/python/memory_update.py`.
- `EVENTS.jsonl` ist append-only.
- Keine Secrets, Rohlogs, Chatverlaeufe oder Chain-of-Thought speichern.

## Abschnitte

- `READ_FIRST`: kritische Hinweise, die jeder Agent zuerst beachten muss.
- `FACTS`: stabile Fakten mit IDs `F-0001`.
- `DECISIONS`: dauerhafte Entscheidungen mit IDs `D-0001`.
- `ACTIVE`: aktueller Fokus mit IDs `A-0001`.
- `NEXT`: naechste Schritte mit IDs `N-0001`.
- `DO_NOT`: Verbote und harte Grenzen mit IDs `X-0001`.
- `OPEN_QUESTIONS`: offene Fragen mit IDs `Q-0001`.
'@
}

function Get-MemoryRule {
    return @'
<!-- AIRGAP-CLINE-MANAGED:v3 -->
# Koordiniertes Memory

- Lies bei externen Arbeitsordnern zuerst `workspaces/<hash>/memory/MEMORY.md`, falls vorhanden.
- Wenn Workspace-Memory fehlt, initialisiere es nur zentral unter `workspaces/<hash>/memory/`.
- Schreibe fluechtige Arbeitsnotizen in den eigenen Agentenordner.
- Schreibe dauerhafte Erkenntnisse zuerst als Vorschlag in `memory/inbox/`.
- Konsolidiere geteilte Memory nur ueber `shared/helpers/python/memory_update.py` oder die Wrapper.
- `MEMORY.md` bleibt kurz, deterministisch und ohne Rohlogs, Secrets, Chatverlaeufe oder Chain-of-Thought.
- `MEMORY.json` ist die kanonische maschinenlesbare Quelle; `MEMORY.md` wird daraus gerendert.
'@
}

function Get-MemoryWorkflows {
    $workflows = [ordered]@{}
    $workflows["50-memory-lesen.md"] = @'
<!-- AIRGAP-CLINE-MANAGED:v3 -->
# Memory Lesen

1. Registriere den externen Arbeitsordner, falls noch kein `workspaces/<hash>/` existiert.
2. Initialisiere Workspace-Memory mit `memory_update.py init`, falls `memory/MEMORY.md` fehlt.
3. Lies `memory/MEMORY.md` vor fachlicher Arbeit.
4. Nutze `MEMORY.json` nur fuer maschinenlesbare Pruefungen.
5. Lies Details in `ACTIVE.md`, `DECISIONS.md` und `PROGRESS.md`, wenn die Kurzfassung nicht reicht.
'@
    $workflows["51-memory-vorschlagen.md"] = @'
<!-- AIRGAP-CLINE-MANAGED:v3 -->
# Memory Vorschlagen

1. Schreibe Session-Zusammenfassungen in den eigenen Agentenordner.
2. Erstelle dauerhafte Memory-Aenderungen als Vorschlag mit `memory_update.py propose`.
3. Waehle einen Typ: `read_first`, `fact`, `decision`, `active`, `next`, `do_not` oder `open_question`.
4. Formuliere kurz und deterministisch: eine Aussage pro Vorschlag.
5. Schreibe keine Secrets, Rohlogs, Chatverlaeufe oder Chain-of-Thought.
'@
    $workflows["52-memory-konsolidieren.md"] = @'
<!-- AIRGAP-CLINE-MANAGED:v3 -->
# Memory Konsolidieren

1. Pruefe `memory/inbox/*.memory.md`.
2. Wende Vorschlaege mit `memory_update.py apply --proposal <datei>` an.
3. Wenn `parentSha256` nicht mehr passt, bleibt der Vorschlag in `inbox/` und muss neu bewertet werden.
4. Nach erfolgreichem Apply werden `MEMORY.json`, `MEMORY.md`, `ACTIVE.md`, `DECISIONS.md`, `PROGRESS.md` und `EVENTS.jsonl` aktualisiert.
5. Halte `MEMORY.md` unter ca. 150-200 Zeilen.
'@
    return $workflows
}

function Get-MemorySkill {
    return @'
<!-- AIRGAP-CLINE-MANAGED:v3 -->
---
name: koordiniertes-memory
description: Liest, erstellt und konsolidiert kurze deterministische Workspace- und User-Memory in der zentralen Air-Gap-Umgebung.
---

# koordiniertes-memory

## Wann verwenden

Nutze diesen Skill, wenn ein Agent Kontext dauerhaft fuer andere Agenten erhalten soll oder vor einer Aufgabe geteiltes Workspace-Memory lesen muss.

## Vorgehen

1. Bestimme `AIRGAP_CLINE_HOME`.
2. Registriere den externen Arbeitsordner und ermittle `workspaces/<hash>/`.
3. Initialisiere Memory bei Bedarf mit `memory_update.py init`.
4. Lies `memory/MEMORY.md`.
5. Schreibe dauerhafte Erkenntnisse mit `memory_update.py propose`.
6. Konsolidiere nur mit `memory_update.py apply`.

## Grenzen

Kein Memory in Zielrepos, keine Secrets, keine Rohlogs, keine Chatverlaeufe und keine Chain-of-Thought.
'@
}

function Get-MemoryHelper {
    return @'
#!/usr/bin/env python3
"""Koordiniertes Workspace-Memory fuer Air-Gap-Cline-Umgebungen."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import sys
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path

SCHEMA_VERSION = 1
SECTION_MAP = {
    "read_first": ("readFirst", "R", "READ_FIRST"),
    "fact": ("facts", "F", "FACTS"),
    "decision": ("decisions", "D", "DECISIONS"),
    "active": ("active", "A", "ACTIVE"),
    "next": ("next", "N", "NEXT"),
    "do_not": ("doNot", "X", "DO_NOT"),
    "open_question": ("openQuestions", "Q", "OPEN_QUESTIONS"),
}


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def current_user() -> str:
    return os.environ.get("USERNAME") or os.environ.get("USER") or "unknown"


def atomic_write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + f".tmp-{os.getpid()}-{uuid.uuid4().hex[:8]}")
    tmp.write_text(text, encoding="utf-8")
    tmp.replace(path)


def sha256_file(path: Path) -> str:
    if not path.exists():
        return ""
    return hashlib.sha256(path.read_bytes()).hexdigest()


def workspace_dir(root: Path, ref: str) -> Path:
    candidate = Path(ref)
    if candidate.exists() and (candidate / "WORKSPACE.json").exists():
        return candidate.resolve(strict=False)
    return (root / "workspaces" / ref).resolve(strict=False)


def memory_dir(workspace: Path) -> Path:
    return workspace / "memory"


def load_workspace_hash(workspace: Path) -> str:
    manifest = workspace / "WORKSPACE.json"
    if manifest.exists():
        data = json.loads(manifest.read_text(encoding="utf-8-sig"))
        return str(data.get("hash") or workspace.name)
    return workspace.name


def default_memory(workspace_hash: str, user: str) -> dict:
    stamp = now()
    return {
        "schemaVersion": SCHEMA_VERSION,
        "scope": "workspace",
        "workspaceHash": workspace_hash,
        "revision": 0,
        "updatedAt": stamp,
        "updatedBy": user,
        "sections": {
            "readFirst": [{"id": "R-0001", "text": "Keine Secrets, Rohlogs, Chatverlaeufe oder Chain-of-Thought in Memory schreiben.", "createdAt": stamp, "createdBy": user}],
            "facts": [],
            "decisions": [],
            "active": [],
            "next": [],
            "doNot": [{"id": "X-0001", "text": "Keine dauerhaften Cline- oder Memory-Dateien in Zielrepos anlegen, ausser der Nutzer verlangt es ausdruecklich.", "createdAt": stamp, "createdBy": user}],
            "openQuestions": [],
        },
    }


def load_memory(mem_dir: Path) -> dict:
    path = mem_dir / "MEMORY.json"
    if not path.exists():
        raise SystemExit(f"MEMORY.json fehlt: {path}")
    return json.loads(path.read_text(encoding="utf-8-sig"))


def save_json(path: Path, data: dict) -> None:
    atomic_write(path, json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def render_memory_md(data: dict) -> str:
    lines = [
        "---",
        "schema: airgap-memory/v1",
        "scope: workspace",
        f"workspace_hash: {data['workspaceHash']}",
        f"revision: {data['revision']}",
        f"updated_at: {data['updatedAt']}",
        f"updated_by: {data['updatedBy']}",
        "---",
        "# MEMORY",
        "",
    ]
    sections = data["sections"]
    for _, (key, _, title) in SECTION_MAP.items():
        lines.append(f"## {title}")
        entries = sections.get(key, [])
        if entries:
            for entry in entries:
                text = str(entry["text"]).replace("\n", " ").strip()
                lines.append(f"- {entry['id']} {text}")
        else:
            lines.append("- none")
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def render_detail_files(mem_dir: Path, data: dict) -> None:
    sections = data["sections"]
    active = "\n".join(f"- {e['id']} {e['text']}" for e in sections.get("active", [])) or "- none"
    decisions = "\n".join(f"- {e['id']} {e['text']}" for e in sections.get("decisions", [])) or "- none"
    next_items = "\n".join(f"- {e['id']} {e['text']}" for e in sections.get("next", [])) or "- none"
    questions = "\n".join(f"- {e['id']} {e['text']}" for e in sections.get("openQuestions", [])) or "- none"
    atomic_write(mem_dir / "ACTIVE.md", f"# Active\n\n{active}\n")
    atomic_write(mem_dir / "DECISIONS.md", f"# Decisions\n\n{decisions}\n")
    atomic_write(mem_dir / "PROGRESS.md", f"# Progress\n\n## Next\n{next_items}\n\n## Open Questions\n{questions}\n")
    index = {
        "schemaVersion": 1,
        "scope": "workspace-memory-index",
        "workspaceHash": data["workspaceHash"],
        "revision": data["revision"],
        "files": {
            "memory": "MEMORY.md",
            "canonical": "MEMORY.json",
            "active": "ACTIVE.md",
            "decisions": "DECISIONS.md",
            "progress": "PROGRESS.md",
            "events": "EVENTS.jsonl",
            "inbox": "inbox/",
            "locks": "locks/",
        },
    }
    save_json(mem_dir / "INDEX.json", index)


def render_all(mem_dir: Path, data: dict) -> None:
    save_json(mem_dir / "MEMORY.json", data)
    atomic_write(mem_dir / "MEMORY.md", render_memory_md(data))
    render_detail_files(mem_dir, data)


def append_event(mem_dir: Path, event_type: str, data: dict, details: dict | None = None) -> None:
    event = {
        "schemaVersion": 1,
        "eventId": uuid.uuid4().hex,
        "eventType": event_type,
        "workspaceHash": data["workspaceHash"],
        "revision": data["revision"],
        "createdAt": now(),
        "createdBy": current_user(),
        "details": details or {},
    }
    with (mem_dir / "EVENTS.jsonl").open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(event, ensure_ascii=False) + "\n")


def acquire_lock(mem_dir: Path, holder: str, ttl: int = 120) -> Path:
    locks = mem_dir / "locks"
    locks.mkdir(parents=True, exist_ok=True)
    lock = locks / "LOCK.json"
    current = int(time.time())
    if lock.exists():
        try:
            data = json.loads(lock.read_text(encoding="utf-8"))
            if int(data.get("expiresEpoch", 0)) > current:
                raise SystemExit(f"Memory ist gesperrt durch {data.get('holder')}: {lock}")
        except json.JSONDecodeError:
            pass
    payload = {"schemaVersion": 1, "holder": holder, "createdAt": now(), "expiresEpoch": current + ttl}
    atomic_write(lock, json.dumps(payload, indent=2) + "\n")
    return lock


def release_lock(lock: Path) -> None:
    try:
        lock.unlink()
    except FileNotFoundError:
        pass


def init_memory(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve(strict=False)
    workspace = workspace_dir(root, args.workspace)
    if not workspace.exists():
        raise SystemExit(f"Workspace existiert nicht: {workspace}")
    mem_dir = memory_dir(workspace)
    mem_dir.mkdir(parents=True, exist_ok=True)
    for sub in ("inbox", "locks", "applied"):
        (mem_dir / sub).mkdir(exist_ok=True)
    if (mem_dir / "MEMORY.json").exists() and not args.force:
        data = load_memory(mem_dir)
    else:
        data = default_memory(load_workspace_hash(workspace), args.agent_id or current_user())
    if not args.dry_run:
        render_all(mem_dir, data)
        events = mem_dir / "EVENTS.jsonl"
        if not events.exists():
            events.write_text("", encoding="utf-8")
        append_event(mem_dir, "init", data)
    print(str(mem_dir))
    return 0


def read_memory(args: argparse.Namespace) -> int:
    mem = memory_dir(workspace_dir(Path(args.root).resolve(strict=False), args.workspace)) / "MEMORY.md"
    if not mem.exists():
        raise SystemExit(f"MEMORY.md fehlt: {mem}")
    print(mem.read_text(encoding="utf-8"))
    return 0


def next_id(data: dict, section_key: str, prefix: str) -> str:
    max_id = 0
    for entry in data["sections"].get(section_key, []):
        match = re.match(r"^[A-Z]-(\d{4,})$", str(entry.get("id", "")))
        if match:
            max_id = max(max_id, int(match.group(1)))
    return f"{prefix}-{max_id + 1:04d}"


def proposal_text(path: Path, metadata: dict, text: str) -> str:
    return "---\n" + json.dumps(metadata, indent=2, ensure_ascii=False) + "\n---\n" + text.strip() + "\n"


def parse_proposal(path: Path) -> tuple[dict, str]:
    content = path.read_text(encoding="utf-8-sig")
    if not content.startswith("---\n"):
        raise SystemExit(f"Ungueltiger Memory-Vorschlag: {path}")
    _, rest = content.split("---\n", 1)
    meta_text, body = rest.split("\n---\n", 1)
    return json.loads(meta_text), body.strip()


def propose_memory(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve(strict=False)
    workspace = workspace_dir(root, args.workspace)
    mem_dir = memory_dir(workspace)
    if not (mem_dir / "MEMORY.json").exists():
        init_args = argparse.Namespace(root=str(root), workspace=args.workspace, agent_id=args.agent_id, force=False, dry_run=False)
        init_memory(init_args)
    current_sha = sha256_file(mem_dir / "MEMORY.json")
    proposal_id = f"{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}-{uuid.uuid4().hex[:8]}"
    metadata = {
        "schemaVersion": 1,
        "proposalId": proposal_id,
        "workspaceHash": load_workspace_hash(workspace),
        "type": args.type,
        "parentSha256": args.parent_sha256 or current_sha,
        "agentId": args.agent_id or current_user(),
        "createdAt": now(),
        "createdBy": current_user(),
    }
    target = mem_dir / "inbox" / f"{proposal_id}.memory.md"
    atomic_write(target, proposal_text(target, metadata, args.text))
    print(str(target))
    return 0


def apply_memory(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve(strict=False)
    workspace = workspace_dir(root, args.workspace)
    mem_dir = memory_dir(workspace)
    data = load_memory(mem_dir)
    proposal = Path(args.proposal).resolve(strict=False)
    metadata, body = parse_proposal(proposal)
    current_sha = sha256_file(mem_dir / "MEMORY.json")
    if metadata.get("parentSha256") and metadata["parentSha256"] != current_sha:
        print(f"Konflikt: parentSha256 passt nicht. Vorschlag bleibt in inbox: {proposal}")
        return 2
    section_key, prefix, _ = SECTION_MAP[metadata["type"]]
    lock = acquire_lock(mem_dir, args.agent_id or current_user())
    try:
        data = load_memory(mem_dir)
        entry = {
            "id": next_id(data, section_key, prefix),
            "text": body.replace("\n", " ").strip(),
            "createdAt": now(),
            "createdBy": metadata.get("agentId") or current_user(),
        }
        data["sections"][section_key].append(entry)
        data["revision"] = int(data.get("revision", 0)) + 1
        data["updatedAt"] = now()
        data["updatedBy"] = args.agent_id or current_user()
        render_all(mem_dir, data)
        append_event(mem_dir, "apply", data, {"proposalId": metadata.get("proposalId"), "entryId": entry["id"], "type": metadata["type"]})
        applied = mem_dir / "applied" / proposal.name
        applied.parent.mkdir(exist_ok=True)
        shutil.move(str(proposal), str(applied))
    finally:
        release_lock(lock)
    print(entry["id"])
    return 0


def render_memory(args: argparse.Namespace) -> int:
    mem_dir = memory_dir(workspace_dir(Path(args.root).resolve(strict=False), args.workspace))
    data = load_memory(mem_dir)
    render_all(mem_dir, data)
    print(str(mem_dir / "MEMORY.md"))
    return 0


def validate_memory(args: argparse.Namespace) -> int:
    mem_dir = memory_dir(workspace_dir(Path(args.root).resolve(strict=False), args.workspace))
    required = ["MEMORY.json", "MEMORY.md", "ACTIVE.md", "DECISIONS.md", "PROGRESS.md", "INDEX.json", "EVENTS.jsonl"]
    missing = [name for name in required if not (mem_dir / name).exists()]
    if missing:
        raise SystemExit("Fehlende Memory-Dateien: " + ", ".join(missing))
    data = load_memory(mem_dir)
    for key, _, _ in SECTION_MAP.values():
        if key not in data.get("sections", {}):
            raise SystemExit(f"Fehlender Memory-Abschnitt: {key}")
    print("Memory valide: " + str(mem_dir))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Koordiniertes Air-Gap-Cline-Memory")
    parser.add_argument("--root", required=True, help="AIRGAP_CLINE_HOME")
    sub = parser.add_subparsers(dest="command", required=True)
    p_init = sub.add_parser("init")
    p_init.add_argument("--workspace", required=True)
    p_init.add_argument("--agent-id", default="")
    p_init.add_argument("--force", action="store_true")
    p_init.add_argument("--dry-run", action="store_true")
    p_init.set_defaults(func=init_memory)
    p_read = sub.add_parser("read")
    p_read.add_argument("--workspace", required=True)
    p_read.set_defaults(func=read_memory)
    p_prop = sub.add_parser("propose")
    p_prop.add_argument("--workspace", required=True)
    p_prop.add_argument("--type", required=True, choices=sorted(SECTION_MAP.keys()))
    p_prop.add_argument("--text", required=True)
    p_prop.add_argument("--agent-id", default="")
    p_prop.add_argument("--parent-sha256", default="")
    p_prop.set_defaults(func=propose_memory)
    p_apply = sub.add_parser("apply")
    p_apply.add_argument("--workspace", required=True)
    p_apply.add_argument("--proposal", required=True)
    p_apply.add_argument("--agent-id", default="")
    p_apply.set_defaults(func=apply_memory)
    p_render = sub.add_parser("render")
    p_render.add_argument("--workspace", required=True)
    p_render.set_defaults(func=render_memory)
    p_validate = sub.add_parser("validate")
    p_validate.add_argument("--workspace", required=True)
    p_validate.set_defaults(func=validate_memory)
    args = parser.parse_args()
    return int(args.func(args))


if __name__ == "__main__":
    raise SystemExit(main())
'@
}

function Get-PowerShellMemoryWrapper {
    return @'
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateSet("init", "read", "propose", "apply", "render", "validate")][string]$Action,
    [Parameter(Mandatory = $true)][string]$Workspace,
    [string]$RootPath = "",
    [ValidateSet("read_first", "fact", "decision", "active", "next", "do_not", "open_question")][string]$Type = "fact",
    [string]$Text = "",
    [string]$Proposal = "",
    [string]$AgentId = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($RootPath)) {
    $RootPath = (Resolve-Path (Join-Path $ScriptDir "..")).Path
}
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
if (-not $python) { throw "Python wurde nicht gefunden." }

$helper = Join-Path $RootPath "shared/helpers/python/memory_update.py"
$argsList = @($helper, "--root", $RootPath, $Action, "--workspace", $Workspace)
if ($Action -eq "propose") {
    if ([string]::IsNullOrWhiteSpace($Text)) { throw "Text ist fuer propose erforderlich." }
    $argsList += @("--type", $Type, "--text", $Text)
}
if ($Action -eq "apply") {
    if ([string]::IsNullOrWhiteSpace($Proposal)) { throw "Proposal ist fuer apply erforderlich." }
    $argsList += @("--proposal", $Proposal)
}
if ($AgentId) { $argsList += @("--agent-id", $AgentId) }
& $python.Source @argsList
'@
}

function Get-PosixMemoryWrapper {
    return @'
#!/bin/sh
set -eu
ROOT_PATH=""
ACTION=""
WORKSPACE=""
TYPE="fact"
TEXT=""
PROPOSAL=""
AGENT_ID=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) shift; ROOT_PATH=$1 ;;
    --action) shift; ACTION=$1 ;;
    --workspace) shift; WORKSPACE=$1 ;;
    --type) shift; TYPE=$1 ;;
    --text) shift; TEXT=$1 ;;
    --proposal) shift; PROPOSAL=$1 ;;
    --agent-id) shift; AGENT_ID=$1 ;;
    *) if [ -z "$ACTION" ]; then ACTION=$1; elif [ -z "$WORKSPACE" ]; then WORKSPACE=$1; else TEXT=$1; fi ;;
  esac
  shift
done
if [ -z "$ROOT_PATH" ]; then
  SCRIPT_DIR=$(dirname "$0")
  ROOT_PATH=$(CDPATH= cd "$SCRIPT_DIR/.." && pwd)
fi
if [ -z "$ACTION" ] || [ -z "$WORKSPACE" ]; then
  echo "Nutzung: update-airgap-memory.sh --action <init|read|propose|apply|render|validate> --workspace <hash|pfad>" >&2
  exit 1
fi
if command -v python3 >/dev/null 2>&1; then
  PY=python3
else
  echo "python3 wurde nicht gefunden." >&2
  exit 1
fi
set -- "$ROOT_PATH/shared/helpers/python/memory_update.py" --root "$ROOT_PATH" "$ACTION" --workspace "$WORKSPACE"
if [ "$ACTION" = "propose" ]; then
  set -- "$@" --type "$TYPE" --text "$TEXT"
fi
if [ "$ACTION" = "apply" ]; then
  set -- "$@" --proposal "$PROPOSAL"
fi
if [ -n "$AGENT_ID" ]; then
  set -- "$@" --agent-id "$AGENT_ID"
fi
exec "$PY" "$@"
'@
}

function Get-UserMemoryTemplate {
    return @'
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
}

function Get-SessionMemoryTemplate {
    return @'
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
}

Write-TextFile "docs/MEMORY-MODELL.md" @'
# Memory-Modell

Dieses Projekt trennt fluechtige Arbeitsnotizen, private Nutzer-Memory und geteilte Workspace-Memory.

## Schreiborte

| Inhalt | Ort |
| --- | --- |
| Fluechtige Task-Notizen | `users/<plattform>/<owner>/agents/<agentid>/memory/SESSION.md` oder `scratch/` |
| Nutzerpraeferenzen | `users/<plattform>/<owner>/memory/USER_MEMORY.md` |
| Geteilte Workspace-Kurzfassung | `workspaces/<hash>/memory/MEMORY.md` |
| Kanonische Workspace-Daten | `workspaces/<hash>/memory/MEMORY.json` |
| Vorschlaege | `workspaces/<hash>/memory/inbox/*.memory.md` |
| Aenderungsjournal | `workspaces/<hash>/memory/EVENTS.jsonl` |

## Format

`MEMORY.md` ist kurz, deterministisch und fuer Agenten optimiert. Es enthaelt feste Abschnitte: `READ_FIRST`, `FACTS`, `DECISIONS`, `ACTIVE`, `NEXT`, `DO_NOT`, `OPEN_QUESTIONS`.

Eine Aussage steht auf einer Zeile und erhaelt eine stabile ID, zum Beispiel `F-0001` oder `D-0001`.

## Grenzen

Keine Secrets, Rohlogs, Chatverlaeufe oder Chain-of-Thought speichern. Zielrepos erhalten keine Memory-Dateien, ausser der Nutzer fordert das ausdruecklich.
'@

Write-TextFile "ARCHITEKTUR.md" @'
# Architektur

Die Air-Gap-Cline-Umgebung ist ein zentraler Startpfad fuer Cline. Dieser Pfad enthaelt Regeln, Workflows, Skills, Memory-Vorlagen und Helper-Skripte. Cline soll diese zentrale Umgebung als Quelle der Wahrheit verwenden, auch wenn spaeter in beliebigen externen Repos, Desktop-Ordnern oder Netzwerkshares gearbeitet wird.

## Grundprinzipien

- Cline ist bereits installiert und KI-faehig eingerichtet.
- Die Umgebung veraendert keine Provider-, Modell- oder Authentifizierungsdaten.
- Der zentrale Umgebungsordner ist exportierbar.
- Nutzer- und Agentendaten werden lokal in `users/` erzeugt.
- Externe Arbeitsordner werden in `workspaces/` registriert.
- Helper und Memory bleiben zentral und werden nicht in Zielrepos kopiert.

## Memory-Lifecycle

- Private Nutzerpraeferenzen liegen unter `users/<plattform>/<owner>/memory/USER_MEMORY.md`.
- Laufende Agenten-Notizen liegen unter `users/<plattform>/<owner>/agents/<agentid>/memory/SESSION.md`.
- Geteiltes Workspace-Memory liegt unter `workspaces/<hash>/memory/`.
- `MEMORY.json` ist die kanonische maschinenlesbare Wahrheit.
- `MEMORY.md` ist die kurze deterministische Lesefassung fuer Cline- und andere KI-Agenten.
- Aenderungen an geteilter Memory laufen ueber Vorschlaege und den Helper `memory_update.py`.

## Varianten

Es gibt je OS eine User- und Admin-Variante. User-Varianten arbeiten ohne Adminrechte und schreiben nur in Benutzerpfade. Admin-Varianten duerfen zentrale Ablagen vorbereiten, bleiben aber ebenfalls provider-neutral.
'@

$readme = Get-Content -LiteralPath (Join-Path $RepoRoot "README.md") -Raw
if ($readme -notlike "*## Koordiniertes Memory*") {
    $readme = $readme.TrimEnd() + @'

## Koordiniertes Memory

Ab v0.3 enthaelt jede Umgebung Vorlagen, Regeln und Helper fuer deterministische Workspace-Memory. Geteilte Memory liegt zentral unter `workspaces/<hash>/memory/`; Zielrepos werden nicht mit Memory-Dateien verschmutzt. Siehe `docs/MEMORY-MODELL.md`.
'@
    Write-TextFile "README.md" $readme
}

Write-TextFile ".clineignore" @'
# Diese Root-Datei schuetzt das Repo selbst vor unnoetigem Kontext.
dist/
release/
node_modules/
.venv/
venv/
**/__pycache__/
**/.pytest_cache/

# Laufzeitdaten der exportierbaren Umgebungen
**/users/**
**/workspaces/**
!**/workspaces/**/memory/
!**/workspaces/**/memory/MEMORY.md
!**/workspaces/**/memory/ACTIVE.md
!**/workspaces/**/memory/DECISIONS.md
!**/workspaces/**/memory/PROGRESS.md
!**/workspaces/**/memory/INDEX.json
**/state/**
**/logs/**
**/audit/**

# Generierte Archive und fremde Binaries
*.7z
*.zip
*.exe
*.msi
*.vsix
*.dmg
*.pkg
*.deb
*.rpm
*.gguf
*.safetensors
*.onnx
'@

$ci = @'
name: CI

on:
  push:
  pull_request:

jobs:
  validate:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Test generated environments
        shell: pwsh
        run: ./scripts/Test-AllEnvironmentPackages.ps1
      - name: PowerShell syntax
        shell: pwsh
        run: |
          $errors = @()
          Get-ChildItem -Path scripts,environments -Recurse -Include *.ps1 | ForEach-Object {
            $tokens = $null
            $parseErrors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
            if ($parseErrors) { $errors += "$($_.FullName): $($parseErrors[0].Message)" }
          }
          if ($errors.Count -gt 0) { throw ($errors -join "`n") }
      - name: Python syntax
        shell: pwsh
        run: |
          $python = Get-Command python -ErrorAction SilentlyContinue
          if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
          if (-not $python) { throw "Python wurde nicht gefunden." }
          Get-ChildItem -Path environments -Recurse -Filter *.py | ForEach-Object {
            & $python.Source -c "import ast, pathlib, sys; ast.parse(pathlib.Path(sys.argv[1]).read_text(encoding='utf-8'))" $_.FullName
          }
      - name: POSIX shell syntax
        shell: bash
        run: |
          find environments -name '*.sh' -print0 | xargs -0 -n 1 sh -n
      - name: Build packages
        shell: pwsh
        run: ./scripts/Build-AllEnvironmentPackages.ps1 -Version "0.3.0-ci" -SkipTests
'@
Write-TextFile ".github/workflows/ci.yml" $ci

foreach ($Env in $Environments) {
    $base = "environments/$($Env.Name)"
    foreach ($dir in @("shared/memory/schemas", "shared/memory/templates")) {
        Ensure-Directory "$base/$dir"
    }
    Write-TextFile "$base/shared/memory/schemas/airgap-memory.schema.json" (Get-MemorySchema)
    Write-TextFile "$base/shared/memory/schemas/memory-event.schema.json" (Get-MemoryEventSchema)
    Write-TextFile "$base/shared/memory/templates/MEMORY.md" (Get-MemoryTemplate)
    Write-TextFile "$base/shared/memory/templates/ACTIVE.md" (Get-ActiveTemplate)
    Write-TextFile "$base/shared/memory/templates/DECISIONS.md" (Get-DecisionsTemplate)
    Write-TextFile "$base/shared/memory/templates/PROGRESS.md" (Get-ProgressTemplate)
    Write-TextFile "$base/shared/memory/templates/INDEX.json" (Get-IndexTemplate)
    Write-TextFile "$base/shared/memory/README.md" (Get-MemoryReadme)
    Write-TextFile "$base/shared/rules/60-koordiniertes-memory.md" (Get-MemoryRule)
    $memoryWorkflows = Get-MemoryWorkflows
    foreach ($workflowName in $memoryWorkflows.Keys) {
        Write-TextFile "$base/shared/workflows/$workflowName" $memoryWorkflows[$workflowName]
    }
    Write-TextFile "$base/shared/skills/koordiniertes-memory/SKILL.md" (Get-MemorySkill)
    Write-TextFile "$base/shared/helpers/python/memory_update.py" (Get-MemoryHelper)

    $manifestPath = Join-Path $RepoRoot "$base/MANIFEST.json"
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $manifest | Add-Member -NotePropertyName memoryModel -NotePropertyValue ([ordered]@{
        schemaVersion = 1
        supportsWorkspaceMemory = $true
        supportsUserMemory = $true
        canonicalFile = "workspaces/<hash>/memory/MEMORY.json"
        agentReadableFile = "workspaces/<hash>/memory/MEMORY.md"
        helper = "shared/helpers/python/memory_update.py"
    }) -Force
    Write-TextFile "$base/MANIFEST.json" (ConvertTo-JsonText $manifest)

    $start = Get-Content -LiteralPath (Join-Path $RepoRoot "$base/START_HIER.md") -Raw
    if ($start -notlike "*## Koordiniertes Memory*") {
        $start = $start.TrimEnd() + @'

## Koordiniertes Memory

Bei externen Arbeitsordnern liest Cline nach der Registrierung `workspaces/<hash>/memory/MEMORY.md`. Wenn Memory fehlt, wird sie zentral mit dem Memory-Helper initialisiert. Zielrepos erhalten keine Memory-Dateien.
'@
        Write-TextFile "$base/START_HIER.md" $start
    }

    $agents = Get-Content -LiteralPath (Join-Path $RepoRoot "$base/AGENTS.md") -Raw
    if ($agents -notlike "*## Schreibmatrix*") {
        $agents = $agents.TrimEnd() + @"

## Schreibmatrix

| Inhalt | Schreibort |
| --- | --- |
| Fluechtige Task-Notizen | eigener Agentenordner unter ``users/$($Env.Family)/.../agents/<agentid>/memory/SESSION.md`` oder ``scratch/`` |
| Nutzerpraeferenzen | eigener Nutzerordner unter ``users/$($Env.Family)/.../memory/USER_MEMORY.md`` |
| Geteilte Workspace-Memory | ``workspaces/<hash>/memory/`` |
| Memory-Vorschlaege | ``workspaces/<hash>/memory/inbox/*.memory.md`` |
| Helper-Ausgaben | ``workspaces/<hash>/helper-output/`` |

Geteilte Memory wird nur ueber ``shared/helpers/python/memory_update.py`` oder die Wrapper aktualisiert. Schreibe keine Memory-Dateien in Zielrepos.
"@
        Write-TextFile "$base/AGENTS.md" $agents
    }

    $ignore = @'
users/**
workspaces/**
!workspaces/**/memory/
!workspaces/**/memory/MEMORY.md
!workspaces/**/memory/ACTIVE.md
!workspaces/**/memory/DECISIONS.md
!workspaces/**/memory/PROGRESS.md
!workspaces/**/memory/INDEX.json
state/**
logs/**
audit/**
**/__pycache__/
**/.pytest_cache/
*.7z
*.zip
*.exe
*.msi
*.vsix
*.dmg
*.pkg
*.deb
*.rpm
*.gguf
*.safetensors
*.onnx
'@
    Write-TextFile "$base/.clineignore" $ignore

    if ($Env.Os -eq "Windows") {
        Write-TextFile "$base/scripts/Update-AirgapMemory.ps1" (Get-PowerShellMemoryWrapper)
        $newUserPath = Join-Path $RepoRoot "$base/scripts/New-AirgapClineUserWorkspace.ps1"
        $newUser = Get-Content -LiteralPath $newUserPath -Raw
        $newUser = $newUser -replace 'New-Item -ItemType Directory -Force -Path \$agentRoot, \(Join-Path \$userRoot "scratch"\), \(Join-Path \$userRoot "notes"\), \(Join-Path \$userRoot "logs"\), \(Join-Path \$userRoot "outbox"\) \| Out-Null', 'New-Item -ItemType Directory -Force -Path $agentRoot, (Join-Path $agentRoot "memory"), (Join-Path $agentRoot "outbox/memory-proposals"), (Join-Path $userRoot "memory"), (Join-Path $userRoot "scratch"), (Join-Path $userRoot "notes"), (Join-Path $userRoot "logs"), (Join-Path $userRoot "outbox") | Out-Null'
        $oldCurrentTask = 'Set-Content -LiteralPath (Join-Path $agentRoot "CURRENT_TASK.md") -Encoding UTF8 -Value "# Aktuelle Aufgabe`n`nNoch keine Aufgabe dokumentiert.`n"'
        $replacementLines = @(
            $oldCurrentTask,
            "`$userMemoryTemplate = @'",
            (Get-UserMemoryTemplate).TrimEnd(),
            "'@",
            'Set-Content -LiteralPath (Join-Path $userRoot "memory/USER_MEMORY.md") -Encoding UTF8 -Value $userMemoryTemplate',
            "`$sessionMemoryTemplate = @'",
            (Get-SessionMemoryTemplate).TrimEnd(),
            "'@",
            'Set-Content -LiteralPath (Join-Path $agentRoot "memory/SESSION.md") -Encoding UTF8 -Value $sessionMemoryTemplate'
        )
        $replacement = $replacementLines -join "`n"
        $newUser = $newUser.Replace($oldCurrentTask, $replacement)
        Write-TextFile "$base/scripts/New-AirgapClineUserWorkspace.ps1" $newUser
    } else {
        Write-TextFile "$base/scripts/update-airgap-memory.sh" (Get-PosixMemoryWrapper)
        $newUserPath = Join-Path $RepoRoot "$base/scripts/new-airgap-cline-user-workspace.sh"
        $newUser = Get-Content -LiteralPath $newUserPath -Raw
        $newUser = $newUser -replace 'mkdir -p "\$AGENT_ROOT" "\$USER_ROOT/scratch" "\$USER_ROOT/notes" "\$USER_ROOT/logs" "\$USER_ROOT/outbox"', 'mkdir -p "$AGENT_ROOT" "$AGENT_ROOT/memory" "$AGENT_ROOT/outbox/memory-proposals" "$USER_ROOT/memory" "$USER_ROOT/scratch" "$USER_ROOT/notes" "$USER_ROOT/logs" "$USER_ROOT/outbox"'
        $insert = @'
cat > "$USER_ROOT/memory/USER_MEMORY.md" <<'EOF'
# User Memory

scope: user
schema: airgap-user-memory/v1

## READ_FIRST
- Keine Secrets, Tokens, Passwoerter oder privaten Rohdaten speichern.

## PREFERENCES
- Noch keine dauerhaften Nutzerpraeferenzen erfasst.

## DO_NOT
- Nicht in fremde Nutzer- oder Agentenordner schreiben.
EOF
cat > "$AGENT_ROOT/memory/SESSION.md" <<'EOF'
# Session Memory

scope: agent-session
schema: airgap-session-memory/v1

## TASK
- Noch keine Aufgabe dokumentiert.

## SUMMARY
- Noch keine Zusammenfassung erfasst.

## MEMORY_PROPOSALS
- Dauerhafte Erkenntnisse als Vorschlaege nach `outbox/memory-proposals/` schreiben.
EOF
'@
        $newUser = $newUser -replace 'printf "# Aktuelle Aufgabe\\n\\nNoch keine Aufgabe dokumentiert\.\\n" > "\$AGENT_ROOT/CURRENT_TASK\.md"', "printf ""# Aktuelle Aufgabe\n\nNoch keine Aufgabe dokumentiert.\n"" > ""`$AGENT_ROOT/CURRENT_TASK.md""`n$insert"
        Write-TextFile "$base/scripts/new-airgap-cline-user-workspace.sh" $newUser
    }
}

$testPath = Join-Path $RepoRoot "scripts/Test-AllEnvironmentPackages.ps1"
$test = Get-Content -LiteralPath $testPath -Raw
$test = $test.Replace('& $python.Source -m py_compile $_.FullName', '& $python.Source -c "import ast, pathlib, sys; ast.parse(pathlib.Path(sys.argv[1]).read_text(encoding=''utf-8''))" $_.FullName')
$test = $test.Replace('if ($content -notlike "*$Needle*") {', 'if ($content -notlike "*$Needle*" -and -not ($Needle -eq "AIRGAP-CLINE-MANAGED:v2" -and $content -like "*AIRGAP-CLINE-MANAGED:v3*")) {')
$test = $test -replace '"50-verifikation-und-dokumentation.md"\)', '"50-verifikation-und-dokumentation.md", "60-koordiniertes-memory.md")'
$test = $test -replace '"90-selbstverbesserung.md"\)', '"90-selbstverbesserung.md", "50-memory-lesen.md", "51-memory-vorschlagen.md", "52-memory-konsolidieren.md")'
$test = $test -replace '"airgap-validierung"\)', '"airgap-validierung", "koordiniertes-memory")'
$test = $test -replace '"shared/helpers/python/register_workspace.py", "shared/helpers/python/guard_owner.py"', '"shared/helpers/python/register_workspace.py", "shared/helpers/python/guard_owner.py", "shared/helpers/python/memory_update.py"'
$test = $test -replace '\$requiredDirs = @\("shared/rules", "shared/workflows", "shared/skills", "shared/helpers/python", "bootstrap", "scripts", "users", "workspaces", "state", "logs", "audit"\)', '$requiredDirs = @("shared/rules", "shared/workflows", "shared/skills", "shared/helpers/python", "shared/memory/schemas", "shared/memory/templates", "bootstrap", "scripts", "users", "workspaces", "state", "logs", "audit")'
$test = $test -replace 'foreach \(\$helper in @\("shared/helpers/python/register_workspace.py", "shared/helpers/python/guard_owner.py", "shared/helpers/python/memory_update.py"\)\)', 'foreach ($helper in @("shared/helpers/python/register_workspace.py", "shared/helpers/python/guard_owner.py", "shared/helpers/python/memory_update.py", "shared/memory/schemas/airgap-memory.schema.json", "shared/memory/templates/MEMORY.md"))'
$test = $test -replace '"Test-AirgapOwner.ps1"\)', '"Test-AirgapOwner.ps1", "Update-AirgapMemory.ps1")'
$test = $test -replace '"guard-owner.sh"\)', '"guard-owner.sh", "update-airgap-memory.sh")'
$test = $test -replace 'Write-Host "Alle exportierbaren Umgebungen sind valide\."', @'
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
'@
Write-TextFile "scripts/Test-AllEnvironmentPackages.ps1" $test

$buildPath = Join-Path $RepoRoot "scripts/Build-AllEnvironmentPackages.ps1"
$build = Get-Content -LiteralPath $buildPath -Raw
$build = $build -replace 'Version = "0\.2\.0"', 'Version = "0.3.0"'
$build = $build -replace 'Alle `\.7z`-Pakete wurden mit 7-Zip getestet\. Alle `\.zip`-Pakete wurden entpackt und auf den erwarteten Root-Ordner geprueft\.', 'Alle `.7z`-Pakete wurden mit 7-Zip getestet. Alle `.zip`-Pakete wurden entpackt und auf den erwarteten Root-Ordner geprueft. Ab v0.3 enthaelt jede Umgebung ein koordiniertes Memory-Modell; Runtime-Memory bleibt ausserhalb des Git-Verlaufs.'
Write-TextFile "scripts/Build-AllEnvironmentPackages.ps1" $build

$manifestScript = Get-Content -LiteralPath (Join-Path $RepoRoot "scripts/New-ReleaseManifest.ps1") -Raw
$manifestScript = $manifestScript -replace 'Version = "0\.2\.0"', 'Version = "0.3.0"'
Write-TextFile "scripts/New-ReleaseManifest.ps1" $manifestScript

Write-TextFile "VERSION" "$Version`n"

foreach ($Env in $Environments) {
    $base = Join-Path $RepoRoot "environments/$($Env.Name)"
    $hashTargets = @("START_HIER.md", "ENVIRONMENT.md", "AGENTS.md", "MANIFEST.json", "VERSION")
    $lines = foreach ($file in $hashTargets) {
        $path = Join-Path $base $file
        $hash = Get-FileHash -LiteralPath $path -Algorithm SHA256
        "$($hash.Hash.ToLowerInvariant())  $file"
    }
    Write-TextFile "environments/$($Env.Name)/SHA256SUMS.txt" (($lines -join "`n") + "`n")
}

Write-Host "v0.3-Memory-Erweiterungen angewendet: $RepoRoot"
