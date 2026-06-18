#!/usr/bin/env python3
"""Generate the English Air-Gap Cline environments."""
from __future__ import annotations

import hashlib
import json
import shutil
import textwrap
from pathlib import Path


VERSION_DEFAULT = "0.5.0"


ENVIRONMENTS = [
    {
        "name": "Cline_Env_Windows_User",
        "os": "Windows",
        "role": "User",
        "family": "windows",
        "primary": "Windows with the VS Code Cline extension in a user-owned location",
        "path": r"C:\Cline_AirGap\Cline_Env_Windows_User or a user-writable share",
        "platform_skill": "windows-vscode-cline",
    },
    {
        "name": "Cline_Env_Windows_Admin",
        "os": "Windows",
        "role": "Admin",
        "family": "windows",
        "primary": "Windows with the VS Code Cline extension from a central location",
        "path": r"C:\Cline_AirGap\Cline_Env_Windows_Admin or a central network share",
        "platform_skill": "windows-vscode-cline",
    },
    {
        "name": "Cline_Env_Linux_User",
        "os": "Linux",
        "role": "User",
        "family": "linux",
        "primary": "Linux Cline CLI from a user-owned location",
        "path": "~/cline-airgap/Cline_Env_Linux_User",
        "platform_skill": "linux-cli-cline",
    },
    {
        "name": "Cline_Env_Linux_Admin",
        "os": "Linux",
        "role": "Admin",
        "family": "linux",
        "primary": "Linux Cline CLI from a central location",
        "path": "/opt/cline-airgap/Cline_Env_Linux_Admin",
        "platform_skill": "linux-cli-cline",
    },
    {
        "name": "Cline_Env_Mac_User",
        "os": "macOS",
        "role": "User",
        "family": "mac",
        "primary": "macOS Cline usage from a user-owned location",
        "path": "~/Cline_AirGap/Cline_Env_Mac_User",
        "platform_skill": "mac-cline",
    },
    {
        "name": "Cline_Env_Mac_Admin",
        "os": "macOS",
        "role": "Admin",
        "family": "mac",
        "primary": "macOS Cline usage from a central location",
        "path": "/Users/Shared/Cline_AirGap/Cline_Env_Mac_Admin or /opt/cline-airgap/Cline_Env_Mac_Admin",
        "platform_skill": "mac-cline",
    },
    {
        "name": "Cline_Env_Solaris_User",
        "os": "Solaris",
        "role": "User",
        "family": "solaris",
        "primary": "Solaris or POSIX-like best-effort usage from a user-owned location",
        "path": "~/cline-airgap/Cline_Env_Solaris_User",
        "platform_skill": "solaris-posix-cline",
    },
    {
        "name": "Cline_Env_Solaris_Admin",
        "os": "Solaris",
        "role": "Admin",
        "family": "solaris",
        "primary": "Solaris or POSIX-like best-effort usage from a central location",
        "path": "/opt/cline-airgap/Cline_Env_Solaris_Admin",
        "platform_skill": "solaris-posix-cline",
    },
]


RULES = {
    "00-first-read-central-environment.md": """
        ---
        AIRGAP-CLINE-MANAGED:v5
        ---
        # First-Read Central Environment

        This rule is always active. After bootstrap, Cline must read the central Air-Gap path before any target workspace task.

        ## Must

        - Resolve `AIRGAP_CLINE_HOME` from the global stub or from the path given by the user.
        - Read `bootstrap/FIRST_READ.md` first.
        - Then read `AGENTS.md`, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION`, and all files under `shared/rules/`.
        - Work in target workspaces only after the central environment was read successfully.

        ## Must Not

        - Do not start in a target repository when the central Air-Gap path is missing or unclear.
        - Do not create persistent Cline files, rules, skills, workflows, helpers, or memory files in target repositories unless the user explicitly requests that.
        - Do not change provider, model, authentication, or AI-server configuration.
    """,
    "00-airgap-principles.md": """
        ---
        AIRGAP-CLINE-MANAGED:v5
        ---
        # Air-Gap Principles

        - Assume the target environment has no internet access.
        - Do not start downloads, marketplace installations, or cloud lookups.
        - Do not invent replacement artifacts. If something is missing, report the exact file name, path, and purpose.
        - Cline is already functional. Provider, model, authentication, and AI-server settings are not changed by this environment.
        - Every automation step must be locally auditable and must not require external installers, model files, or VSIX files.
    """,
    "05-platform-and-variant.md": """
        ---
        AIRGAP-CLINE-MANAGED:v5
        ---
        # Platform And Variant

        - Environment: __ENV_NAME__
        - Operating system: __ENV_OS__
        - Permission role: __ENV_ROLE__
        - Primary mode: __ENV_PRIMARY__
        - Recommended location: __ENV_PATH__

        Use only scripts and paths that match this variant. Windows is the primary VS Code Cline extension target. Linux, macOS, and Solaris are CLI/POSIX-oriented. Solaris remains best effort.
    """,
    "10-central-path-is-source-of-truth.md": """
        ---
        AIRGAP-CLINE-MANAGED:v5
        ---
        # Central Path Is Source Of Truth

        - Rules, workflows, skills, helpers, user state, workspace metadata, and memory live in the central path.
        - Global Cline stubs may contain only a stable pointer to this central path and first-read instructions.
        - When Cline works in external repositories, Cline infrastructure files remain in the central path.
        - Target repositories receive only project changes that directly belong to the user's task.
    """,
    "20-user-and-agent-isolation.md": """
        ---
        AIRGAP-CLINE-MANAGED:v5
        ---
        # User And Agent Isolation

        - Check `OWNER.json` before writing under `users/`.
        - If owner data does not match the current user and host, writing is forbidden.
        - Each agent writes only to its own agent folder, scratch area, notes, logs, outbox, and session memory.
        - Foreign agent folders may be read only when the human user explicitly requests it.
    """,
    "30-no-repo-pollution.md": """
        ---
        AIRGAP-CLINE-MANAGED:v5
        ---
        # No Repository Pollution

        - Do not create persistent `.cline`, `.clinerules`, skills, workflows, helpers, or memory files in target repositories by default.
        - Central metadata for target repositories belongs under `workspaces/<hash>/`.
        - Helper outputs belong under `workspaces/<hash>/helper-output/`.
        - Project files may be changed when the user task requires that.
        - Exceptions must be explicitly requested by the user.
    """,
    "40-use-central-helpers.md": """
        ---
        AIRGAP-CLINE-MANAGED:v5
        ---
        # Use Central Helpers

        - Prefer helper scripts from `shared/helpers/`.
        - Execute helpers from the central environment path.
        - Write helper outputs into the central workspace metadata folder.
        - Do not copy helpers into target repositories unless the user explicitly requests that.
        - If a helper is missing or incompatible, report the exact limitation and continue manually when safe.
    """,
    "50-verification-and-documentation.md": """
        ---
        AIRGAP-CLINE-MANAGED:v5
        ---
        # Verification And Documentation

        - Verify changes locally with the smallest reliable check first.
        - Record durable findings in the appropriate memory proposal, not in raw chat logs.
        - Keep final reports short, factual, and tied to files or commands that were actually checked.
        - State clearly when a check could not be run.
    """,
    "60-coordinated-memory.md": """
        ---
        AIRGAP-CLINE-MANAGED:v5
        ---
        # Coordinated Memory

        - Read workspace `memory/MEMORY.md` before changing an external workspace when memory exists.
        - Keep shared memory short, deterministic, and structured by stable IDs.
        - Write short-lived notes to the current agent session memory.
        - Write durable shared updates through the memory helper as proposals or validated apply operations.
        - Never store secrets, raw logs, chat transcripts, or chain-of-thought in memory.
        - Never place memory files in target repositories unless the user explicitly requests that.
    """,
}


WORKFLOWS = {
    "00-initialization.md": """
        ---
        AIRGAP-CLINE-MANAGED:v5
        ---
        # Initialization

        1. Read `START_HERE.md`, `AGENTS.md`, and `ENVIRONMENT.md`.
        2. Validate the central path through `MANIFEST.json`, `VERSION`, `shared/`, and `scripts/`.
        3. Run the matching initialization script, preferably first with `--dry-run`.
        4. Create the current user and agent folder.
        5. Sync global Cline stubs.
        6. Write `state/bootstrap-status.json`.
        7. Confirm that provider, model, authentication, and AI-server settings were not changed.
    """,
    "01-sync-central-stubs.md": """
        ---
        AIRGAP-CLINE-MANAGED:v5
        ---
        # Sync Central Stubs

        1. Determine the absolute central environment path.
        2. Determine user-owned global Cline rule locations for the platform.
        3. If an existing target file is not marked as Air-Gap managed, create a timestamped backup first.
        4. Write a stub that contains `AIRGAP_CLINE_HOME`, `AIRGAP-CLINE-STUB:v5`, and the first-read contract.
        5. Verify that each written stub points to the same central path.
    """,
    "02-create-user-folder.md": """
        ---
        AIRGAP-CLINE-MANAGED:v5
        ---
        # Create User Folder

        1. Detect user, host, platform, and variant.
        2. Create `users/<platform>/<owner>/` when it does not exist.
        3. If `OWNER.json` exists, verify ownership before writing.
        4. Create `memory/USER_MEMORY.md`, `ALWAYS_READ.md`, and the agent folder.
        5. Create `AGENT_POLICY.md`, `CURRENT_TASK.md`, `WORKSPACE_BINDINGS.json`, and `memory/SESSION.md` for the agent.
    """,
    "03-check-first-read-behavior.md": """
        ---
        AIRGAP-CLINE-MANAGED:v5
        ---
        # Check First-Read Behavior

        1. Find the global Cline stub.
        2. Resolve `AIRGAP_CLINE_HOME`.
        3. Confirm that `bootstrap/FIRST_READ.md` exists.
        4. Confirm that `AGENTS.md`, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION`, and `shared/rules/` are readable.
        5. Stop if different stubs point to different central paths.
    """,
    "10-register-external-workspace.md": """
        ---
        AIRGAP-CLINE-MANAGED:v5
        ---
        # Register External Workspace

        1. Normalize the target path.
        2. Hash the normalized path.
        3. Create `workspaces/<hash>/WORKSPACE.json` in the central environment.
        4. Create `NOTES.md`, `RULE_OVERRIDES.md`, `helper-output/`, and `memory/` under that workspace metadata folder.
        5. Do not create Cline infrastructure files in the target repository.
    """,
    "20-handle-standard-task.md": """
        ---
        AIRGAP-CLINE-MANAGED:v5
        ---
        # Handle Standard Task

        1. Perform the central first-read sequence.
        2. Register or locate the external workspace when a target path is involved.
        3. Read workspace memory and relevant rules.
        4. Make only task-related changes in the target workspace.
        5. Keep helper output, memory, and agent notes central.
        6. Verify the result and summarize what changed.
    """,
    "30-use-helper-script.md": """
        ---
        AIRGAP-CLINE-MANAGED:v5
        ---
        # Use Helper Script

        1. Pick the helper from `shared/helpers/` that matches the platform and task.
        2. Run it from the central environment path.
        3. Write output to `workspaces/<hash>/helper-output/` when a workspace is involved.
        4. Do not copy helper scripts into the target repository by default.
        5. Record durable findings through a memory proposal when useful.
    """,
    "40-airgap-acceptance.md": """
        ---
        AIRGAP-CLINE-MANAGED:v5
        ---
        # Air-Gap Acceptance

        1. Confirm no provider, model, authentication, or AI-server settings changed.
        2. Confirm no forbidden binaries or generated archives were added.
        3. Confirm target repositories do not contain persistent Cline infrastructure files unless explicitly requested.
        4. Confirm the relevant test or verification command was run.
        5. Confirm useful durable findings were proposed for memory.
    """,
    "50-read-memory.md": """
        ---
        AIRGAP-CLINE-MANAGED:v5
        ---
        # Read Memory

        1. Resolve the workspace hash.
        2. Read `workspaces/<hash>/memory/MEMORY.md` when it exists.
        3. Read `ACTIVE.md`, `DECISIONS.md`, and `PROGRESS.md` only when more detail is needed.
        4. Treat `MEMORY.json` as the machine-readable state.
        5. Keep memory context small and high signal.
    """,
    "51-propose-memory.md": """
        ---
        AIRGAP-CLINE-MANAGED:v5
        ---
        # Propose Memory

        1. Write durable findings as short facts, decisions, next steps, risks, or questions.
        2. Use the memory helper `propose` action.
        3. Keep one assertion per proposal.
        4. Never include secrets, raw logs, chat transcripts, or chain-of-thought.
        5. Leave conflicting updates in `memory/inbox/`.
    """,
    "52-consolidate-memory.md": """
        ---
        AIRGAP-CLINE-MANAGED:v5
        ---
        # Consolidate Memory

        1. Validate the target proposal.
        2. Confirm the proposal parent hash still matches the current memory state.
        3. Apply through the memory helper.
        4. Re-render `MEMORY.md`, `ACTIVE.md`, `DECISIONS.md`, and `PROGRESS.md`.
        5. Append the event to `EVENTS.jsonl`.
    """,
    "90-self-improvement.md": """
        ---
        AIRGAP-CLINE-MANAGED:v5
        ---
        # Self Improvement

        1. Treat the central path as the only place for environment improvements.
        2. Propose changes through memory or a repository task before changing shared rules.
        3. Keep changes compatible across all eight environments unless the difference is platform-specific.
        4. Verify every environment after shared changes.
    """,
}


SKILLS = {
    "airgap-bootstrap": "Initializes an existing Cline installation from an exported Air-Gap central path.",
    "platform-variant": "Selects OS-specific and User/Admin-specific paths, scripts, and boundaries without provider configuration.",
    "user-agent-protection": "Checks OWNER.json and protects foreign user and agent folders from writes.",
    "external-workspace": "Registers target repositories, desktop folders, or shares centrally under workspaces without repository pollution.",
    "central-helpers": "Finds and uses central helper scripts and writes their output to central workspace metadata.",
    "airgap-validation": "Checks local artifacts, Air-Gap assumptions, completion criteria, and documentation.",
    "coordinated-memory": "Reads, creates, proposes, and consolidates short deterministic workspace and user memory in the central Air-Gap environment.",
}


PLATFORM_SKILLS = {
    "windows-vscode-cline": "Windows-specific skill for the VS Code Cline extension and user-owned Cline rule paths.",
    "linux-cli-cline": "Linux-specific skill for Cline CLI and POSIX-oriented user or central paths.",
    "mac-cline": "macOS-specific skill for CLI or editor-adjacent Cline usage.",
    "solaris-posix-cline": "Solaris/POSIX best-effort skill for systems where Cline already runs.",
}


def compact(text: str) -> str:
    return textwrap.dedent(text).strip() + "\n"


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(compact(text), encoding="utf-8", newline="\n")


def write_plain(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")


def clear_generated_folder(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)
    for child in list(path.iterdir()):
        if child.name == ".gitkeep":
            continue
        if child.is_dir():
            shutil.rmtree(child)
        else:
            child.unlink()


def write_root_docs(root: Path, version: str) -> None:
    write_plain(root / "VERSION", version + "\n")
    write(root / "AGENTS.md", """
        # Agent Instructions For This Repository

        - This repository produces exportable Cline environments.
        - Cline is a prerequisite. This repository does not install Cline and does not configure providers, models, authentication, or AI servers.
        - Do not commit third-party binaries, installers, VSIX files, model files, generated archives, or runtime caches.
        - Codex-specific local notes and runtime data must stay ignored.
        - Exportable environments must remain usable without mandatory dependencies on generator sources such as `src/common`.
        - Documentation, instructions, scripts, comments, templates, release notes, and generated content must be written in English.
    """)
    write(root / ".gitignore", """
        # Local agent and Codex data
        .codex/
        .agents/
        codex_sessions/
        rollout_summaries/
        memory_exports/
        CODEX_LOCAL.md
        CODEX_NOTES.md
        *.codex.md
        *.local.md

        # Runtime data created by exportable environments
        **/state/**
        **/logs/**
        **/audit/**
        **/users/**
        **/workspaces/**/helper-output/**
        !**/state/.gitkeep
        !**/logs/.gitkeep
        !**/audit/.gitkeep
        !**/users/.gitkeep
        !**/workspaces/.gitkeep

        # Release and package artifacts
        dist/
        *.7z
        *.zip
        *.tgz
        *.tar
        *.tar.gz

        # Third-party installers, extensions, packages, and model files
        *.exe
        *.msi
        *.msix
        *.appx
        *.vsix
        *.nupkg
        *.dmg
        *.pkg
        *.deb
        *.rpm
        *.gguf
        *.safetensors
        *.onnx
        *.pt
        *.pth
        *.ckpt

        # Common local build/cache output
        .cache/
        .tmp/
        tmp/
        __pycache__/
        *.pyc
    """)
    write(root / ".clineignore", """
        # Runtime noise
        **/logs/**
        **/audit/**
        **/state/**
        **/users/**/scratch/**
        **/users/**/logs/**
        **/workspaces/**/helper-output/**

        # Keep curated memory readable
        !**/workspaces/**/memory/MEMORY.md
        !**/workspaces/**/memory/ACTIVE.md
        !**/workspaces/**/memory/DECISIONS.md
        !**/workspaces/**/memory/PROGRESS.md
        !**/workspaces/**/memory/INDEX.json

        # Local agent notes
        .codex/**
        .agents/**
        codex_sessions/**
        rollout_summaries/**
        memory_exports/**
        CODEX_LOCAL.md
        CODEX_NOTES.md
        *.codex.md
        *.local.md

        # Binary and release artifacts
        *.7z
        *.zip
        *.tgz
        *.tar
        *.tar.gz
        *.exe
        *.msi
        *.vsix
        *.gguf
        *.safetensors
        *.onnx
        *.pt
        *.pth
        *.ckpt
    """)
    write(root / "README.md", f"""
        # Air-Gap Cline Environment

        Exportable starter environments for Cline in air-gapped or tightly controlled networks.

        This repository does **not** provide a Cline installer, provider configuration, model-server configuration, authentication material, or AI server setup. It assumes Cline already works, for example as the VS Code Cline extension on Windows or as Cline CLI on Linux, macOS, or POSIX-like systems. The repository provides the central path from which Cline should permanently read rules, workflows, skills, helper scripts, and memory structures.

        ## Quick Start

        1. Confirm that Cline is already installed, configured, and connected to the intended AI server.
        2. Choose one exportable folder under `environments/`.
        3. Copy that folder to its final location.
        4. Tell Cline:

        ```text
        Initialize yourself from this path: <absolute path to the Cline_Env_... folder>
        ```

        Example for Windows:

        ```text
        Initialize yourself from this path: C:\\Cline_AirGap\\Cline_Env_Windows_User
        ```

        Example for Linux:

        ```text
        Initialize yourself from this path: /opt/cline-airgap/Cline_Env_Linux_Admin
        ```

        Cline reads `START_HERE.md`, then `bootstrap/FIRST_READ.md`, then `AGENTS.md`, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION`, and `shared/rules/`.

        ## Which Environment Should I Use?

        | Situation | Folder |
        | --- | --- |
        | Windows, normal user permissions, VS Code Cline extension | `Cline_Env_Windows_User` |
        | Windows, central machine or share location, multiple users | `Cline_Env_Windows_Admin` |
        | Linux in a user home directory | `Cline_Env_Linux_User` |
        | Linux under `/opt` or on a shared location | `Cline_Env_Linux_Admin` |
        | macOS in a user home directory | `Cline_Env_Mac_User` |
        | macOS under `/Users/Shared` or `/opt` | `Cline_Env_Mac_Admin` |
        | Solaris or POSIX-like user setup, best effort | `Cline_Env_Solaris_User` |
        | Solaris or POSIX-like shared setup, best effort | `Cline_Env_Solaris_Admin` |

        Windows with the VS Code Cline extension is the primary target. Linux, macOS, and Solaris are CLI/POSIX-oriented variants. Solaris is best effort and only makes sense when Cline already runs there.

        ## First-Read Contract

        Every environment contains `bootstrap/FIRST_READ.md` and `bootstrap/00-airgap-central-environment.md`. After bootstrap, global Cline stubs point back to `AIRGAP_CLINE_HOME`. Before every task, Cline must read the central path first.

        If the central path is missing, unreadable, or contradictory across stubs, Cline must stop and ask the user for the valid Air-Gap path.

        ## External Workspaces

        Cline may edit project files in target repositories when the user task requires it. The Air-Gap infrastructure stays central:

        - no persistent `.cline`, `.clinerules`, skills, workflows, helpers, or memory files are created in target repositories unless the user explicitly asks for that;
        - helper output goes to `workspaces/<hash>/helper-output/`;
        - workspace metadata and shared memory go to `workspaces/<hash>/`;
        - private user and agent state goes to `users/<platform>/<owner>/`.

        ## Coordinated Memory

        Each environment includes a coordinated memory model. `MEMORY.md` is the short deterministic read view for agents, while `MEMORY.json` is the canonical machine-readable state. Shared memory updates go through `shared/helpers/python/memory_update.py` or the platform wrapper.

        ## Environment Folder Layout

        ```text
        START_HERE.md
        AGENTS.md
        ENVIRONMENT.md
        MANIFEST.json
        VERSION
        bootstrap/
          FIRST_READ.md
          00-airgap-central-environment.md
        shared/
          rules/
          workflows/
          skills/
          helpers/
          memory/
        scripts/
        users/
        workspaces/
        state/
        logs/
        audit/
        ```

        ## Releases

        A release provides separate `.7z` and `.zip` packages for every environment plus an all-in-one package. Release metadata includes `SHA256SUMS.txt`, `RELEASE_MANIFEST.json`, and `RELEASE_NOTES.md`.

        ## Explicit Non-Goals

        This repository intentionally excludes Cline installers, VS Code extensions, provider configuration, model configuration, authentication, AI-server setup, third-party installers, model weights, container images, runtime user data, and generated archive artifacts in Git.

        ## Validation

        ```powershell
        .\\scripts\\Test-AllEnvironmentPackages.ps1
        .\\scripts\\Test-ClineMarkdownBehavior.ps1
        .\\scripts\\Build-AllEnvironmentPackages.ps1 -Version {version}
        ```

        `Test-AllEnvironmentPackages.ps1` includes the Cline Markdown behavior simulation. The simulation is a scenario-based deterministic test for the agent instructions: first-read order, central path handling, provider boundaries, external workspace behavior, coordinated memory, owner protection, central helper use, and air-gap assumptions.

        ## Useful Documents

        - [`START_HERE.md`](START_HERE.md): entry point for repository viewers.
        - [`ARCHITECTURE.md`](ARCHITECTURE.md): architecture and central path behavior.
        - [`docs/MEMORY-MODEL.md`](docs/MEMORY-MODEL.md): coordinated memory format and update rules.
        - [`SECURITY.md`](SECURITY.md): security expectations.
        - [`CONTRIBUTING.md`](CONTRIBUTING.md): contribution rules.
    """)
    write(root / "START_HERE.md", """
        # Start Here

        This repository contains multiple exportable Cline starter environments. Do not use the repository root as the long-term Cline environment. Choose exactly one folder under `environments/`.

        Example for Windows:

        ```text
        Initialize yourself from this path: C:\\Cline_AirGap\\Cline_Env_Windows_User
        ```

        Example for Linux:

        ```text
        Initialize yourself from this path: /opt/cline-airgap/Cline_Env_Linux_Admin
        ```

        Cline must already be installed and functional. This project does not configure providers or model servers.
    """)
    write(root / "ARCHITECTURE.md", """
        # Architecture

        The Air-Gap Cline environment is a central starter path for Cline. That path contains rules, workflows, skills, memory templates, and helper scripts. Cline should treat the central environment as the source of truth even when it later works in external repositories, desktop folders, or network shares.

        ## Boundaries

        - The environment does not change provider, model, authentication, or AI-server settings.
        - The central environment folder is exportable.
        - User and agent data is created under `users/`.
        - External workspaces are registered under `workspaces/`.
        - Helpers and memory stay central and are not copied into target repositories.

        ## Memory Lifecycle

        - Private user preferences live under `users/<platform>/<owner>/memory/USER_MEMORY.md`.
        - Session notes live under `users/<platform>/<owner>/agents/<agent-id>/memory/SESSION.md`.
        - Shared workspace memory lives under `workspaces/<hash>/memory/`.
        - `MEMORY.md` is the short deterministic read view for Cline and other AI agents.
        - Changes to shared memory flow through proposals and the `memory_update.py` helper.

        ## First-Read Behavior

        After initialization, the global stub is Cline's permanent entry point. It points to `AIRGAP_CLINE_HOME`. Cline must read `bootstrap/FIRST_READ.md`, `AGENTS.md`, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION`, and `shared/rules/` before every target workspace task.
    """)
    write(root / "SECURITY.md", """
        # Security Policy

        ## Scope

        This project provides Cline rules, workflows, skills, local helper scripts, and memory templates. It contains no secrets, provider configuration, third-party binaries, model files, or installers.

        ## Reporting Security Issues

        Do not report sensitive security issues in public issues when they contain concrete vulnerabilities, tokens, internal paths, or abuse-ready details. Use a private contact path provided by the repository owner.

        ## Security Expectations

        - Cline agents must respect foreign user and agent folders.
        - Provider, model, authentication, and AI-server settings are outside this project.
        - Target repositories must not receive persistent Cline infrastructure files unless explicitly requested by the user.
        - Runtime memory must not contain secrets, raw chat logs, or chain-of-thought.
    """)
    write(root / "CONTRIBUTING.md", """
        # Contributing

        Contributions must keep all documentation, user-facing text, comments, templates, and generated content in English. Exportable environments must remain usable without mandatory dependency on generator sources.

        ## Rules

        - Do not add installers, binaries, VSIX files, model files, or generated archives.
        - Every exportable environment must remain self-contained and understandable on its own.
        - Changes to shared rules, workflows, skills, helpers, or memory templates must be synchronized across all eight environments.
        - Run `scripts/Test-AllEnvironmentPackages.ps1` before submitting changes. This includes the deterministic Cline Markdown behavior simulation.
    """)
    write(root / "CODE_OF_CONDUCT.md", """
        # Code Of Conduct

        Be factual, respectful, and focused on the work. This repository is intended for controlled Cline environments, so changes should be understandable, auditable, and conservative.
    """)
    write(root / "LICENSE-NOTES.md", """
        # License Notes

        The project sources are available under the license stated in `LICENSE`. Third-party installers, Cline extensions, AI models, and other external binaries are not part of this repository and are not distributed through it.
    """)
    write(root / "docs/BASELINE-v0.1.md", """
        # Baseline v0.1

        The initial baseline provided the core repository structure:

        - eight exportable environments are present;
        - no provider, model, authentication, or installer logic is included;
        - runtime data under `users/`, `workspaces/`, `state/`, `logs/`, and `audit/` is excluded from Git;
        - package and validation scripts exist for release preparation.
    """)
    write(root / "docs/MEMORY-MODEL.md", """
        # Coordinated Memory Model

        This project separates short-lived work notes, private user memory, and shared workspace memory.

        | Scope | Path |
        | --- | --- |
        | User preferences | `users/<platform>/<owner>/memory/USER_MEMORY.md` |
        | Agent session notes | `users/<platform>/<owner>/agents/<agent-id>/memory/SESSION.md` |
        | Shared workspace memory | `workspaces/<hash>/memory/` |
        | Helper output | `workspaces/<hash>/helper-output/` |

        `MEMORY.md` is short, deterministic, and optimized for agents. It uses fixed sections: `READ_FIRST`, `FACTS`, `DECISIONS`, `ACTIVE`, `NEXT`, `DO_NOT`, and `OPEN_QUESTIONS`.

        Do not store secrets, raw logs, chat transcripts, or chain-of-thought. Target repositories must not receive memory files unless the user explicitly requests that.
    """)
    write(root / ".github/PULL_REQUEST_TEMPLATE.md", """
        ## Summary

        -

        ## Validation

        - [ ] `scripts/Test-AllEnvironmentPackages.ps1`
        - [ ] Release packages were rebuilt when exported environment contents changed.

        ## Checklist

        - [ ] Documentation and generated content are English.
        - [ ] No installers, binaries, model files, VSIX files, or generated archives are committed.
        - [ ] Runtime data remains ignored.
    """)
    write(root / ".github/ISSUE_TEMPLATE/bug-report.md", """
        ---
        name: Bug report
        description: Report a problem with an exportable Air-Gap Cline environment
        title: "[Bug]: "
        labels: ["bug"]
        body:
          - type: textarea
            id: problem
            attributes:
              label: Problem
              description: What happened?
            validations:
              required: true
          - type: dropdown
            id: environment
            attributes:
              label: Environment
              options:
                - Cline_Env_Windows_User
                - Cline_Env_Windows_Admin
                - Cline_Env_Linux_User
                - Cline_Env_Linux_Admin
                - Cline_Env_Mac_User
                - Cline_Env_Mac_Admin
                - Cline_Env_Solaris_User
                - Cline_Env_Solaris_Admin
          - type: textarea
            id: validation
            attributes:
              label: Validation output
              description: Include relevant output from the test or initialization script. Remove secrets and internal paths when needed.
        ---
    """)


def skill_text(name: str, description: str) -> str:
    return compact(f"""
        ---
        AIRGAP-CLINE-MANAGED:v5
        name: {name}
        description: {description}
        ---
        # {name}

        Use this skill when the current task matches this description: {description}

        ## Procedure

        1. Perform the central first-read sequence.
        2. Read `AGENTS.md`, `ENVIRONMENT.md`, and the relevant rules.
        3. Use central helpers and central workspace metadata.
        4. Do not write to foreign user or agent folders.
        5. Do not change provider, model, authentication, or AI-server settings.
    """)


REGISTER_WORKSPACE_PY = r'''#!/usr/bin/env python3
"""Register external workspaces centrally under workspaces/<hash>."""
from __future__ import annotations
import argparse, hashlib, json, os, socket
from datetime import datetime, timezone
from pathlib import Path

def now() -> str:
    return datetime.now(timezone.utc).isoformat()

def write_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    tmp.replace(path)

def main() -> int:
    parser = argparse.ArgumentParser(description="Register an external workspace in the central Air-Gap environment")
    parser.add_argument("--root", required=True)
    parser.add_argument("--target", required=True)
    parser.add_argument("--alias", default="")
    args = parser.parse_args()
    root = Path(args.root).expanduser().resolve()
    target = Path(args.target).expanduser().resolve()
    if not root.is_dir():
        raise SystemExit(f"AIRGAP_CLINE_HOME does not exist: {root}")
    if not target.is_dir():
        raise SystemExit(f"Target workspace does not exist or is not a directory: {target}")
    normalized = str(target)
    digest = hashlib.sha256(normalized.encode("utf-8")).hexdigest()[:24]
    workspace_dir = root / "workspaces" / digest
    workspace_dir.mkdir(parents=True, exist_ok=True)
    workspace_file = workspace_dir / "WORKSPACE.json"
    if workspace_file.exists():
        current = json.loads(workspace_file.read_text(encoding="utf-8"))
        if current.get("normalizedPath") and current["normalizedPath"] != normalized:
            raise SystemExit(f"Workspace hash collision for {digest}")
        created_at = current.get("createdAt", now())
    else:
        created_at = now()
    write_json(workspace_file, {
        "schemaVersion": 2,
        "hash": digest,
        "originalPath": args.target,
        "normalizedPath": normalized,
        "alias": args.alias,
        "host": socket.gethostname(),
        "user": os.environ.get("USERNAME") or os.environ.get("USER") or "unknown",
        "createdAt": created_at,
        "updatedAt": now(),
    })
    defaults = {
        "NOTES.md": "# Notes\n\n- No notes recorded yet.\n",
        "RULE_OVERRIDES.md": "# Rule Overrides\n\n- No overrides recorded.\n",
    }
    for name, content in defaults.items():
        file_path = workspace_dir / name
        if not file_path.exists():
            file_path.write_text(content, encoding="utf-8")
    (workspace_dir / "helper-output").mkdir(exist_ok=True)
    (workspace_dir / "memory").mkdir(exist_ok=True)
    print(digest)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
'''


GUARD_OWNER_PY = r'''#!/usr/bin/env python3
"""Check OWNER.json before writing to user or agent folders."""
from __future__ import annotations
import argparse, json, os, socket
from pathlib import Path

def current_identity() -> dict:
    return {
        "user": os.environ.get("USERNAME") or os.environ.get("USER") or "unknown",
        "domain": os.environ.get("USERDOMAIN", ""),
        "host": socket.gethostname(),
    }

def main() -> int:
    parser = argparse.ArgumentParser(description="Validate OWNER.json for the current user")
    parser.add_argument("--owner", required=True)
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()
    path = Path(args.owner)
    if not path.is_file():
        raise SystemExit(f"OWNER.json not found: {path}")
    owner = json.loads(path.read_text(encoding="utf-8"))
    ident = current_identity()
    allowed = owner.get("user") == ident["user"]
    if owner.get("domain"):
        allowed = allowed and owner["domain"] == ident["domain"]
    if owner.get("host"):
        allowed = allowed and owner["host"] == ident["host"]
    print(json.dumps({"allowed": allowed, "owner": owner, "current": ident}, indent=2, sort_keys=True))
    if args.write and not allowed:
        raise SystemExit("Current identity may not write to this owner folder")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
'''


MEMORY_UPDATE_PY = r'''#!/usr/bin/env python3
"""Manage coordinated workspace memory for Air-Gap Cline environments."""
from __future__ import annotations
import argparse, hashlib, json, time
from datetime import datetime, timezone
from pathlib import Path

TARGET = {"fact": "facts", "decision": "decisions", "active": "active", "next": "next", "do_not": "doNot", "question": "openQuestions", "read_first": "readFirst"}
PREFIX = {"fact": "F", "decision": "D", "active": "A", "next": "N", "do_not": "X", "question": "Q", "read_first": "R"}
SECTIONS = ["readFirst", "facts", "decisions", "active", "next", "doNot", "openQuestions"]

def now() -> str:
    return datetime.now(timezone.utc).isoformat()

def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else ""

def memory_dir(root: Path, workspace_hash: str) -> Path:
    workspace = root / "workspaces" / workspace_hash
    if not workspace.is_dir():
        raise SystemExit(f"Workspace does not exist: {workspace}")
    path = workspace / "memory"
    (path / "inbox").mkdir(parents=True, exist_ok=True)
    (path / "locks").mkdir(exist_ok=True)
    return path

def default_state(workspace_hash: str, agent_id: str) -> dict:
    stamp = now()
    return {
        "schemaVersion": 1,
        "scope": "workspace",
        "workspaceHash": workspace_hash,
        "revision": 0,
        "updatedAt": stamp,
        "updatedBy": agent_id,
        "readFirst": [{"id": "R-0001", "text": "Do not store secrets, raw logs, chat transcripts, or chain-of-thought in memory.", "createdAt": stamp, "createdBy": agent_id}],
        "facts": [],
        "decisions": [],
        "active": [],
        "next": [],
        "doNot": [{"id": "X-0001", "text": "Do not create persistent Cline or memory files in target repositories unless the user explicitly requests it.", "createdAt": stamp, "createdBy": agent_id}],
        "openQuestions": [],
    }

def load_state(path: Path, workspace_hash: str, agent_id: str) -> dict:
    file_path = path / "MEMORY.json"
    if file_path.exists():
        return json.loads(file_path.read_text(encoding="utf-8"))
    return default_state(workspace_hash, agent_id)

def write_json(path: Path, data: dict) -> None:
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    tmp.replace(path)

def section(title: str, items: list[dict], empty: str) -> list[str]:
    lines = [f"## {title}"]
    if items:
        lines.extend(f"- {item['id']}: {item['text']}" for item in items)
    else:
        lines.append(f"- {empty}")
    lines.append("")
    return lines

def render(path: Path, state: dict) -> None:
    lines = [
        "# Memory",
        "",
        "schema: airgap-memory/v1",
        f"scope: {state['scope']}",
        f"workspace_hash: {state['workspaceHash']}",
        f"revision: {state['revision']}",
        f"updated_at: {state['updatedAt']}",
        f"updated_by: {state['updatedBy']}",
        "",
    ]
    lines += section("READ_FIRST", state.get("readFirst", []), "No additional read-first items.")
    lines += section("FACTS", state.get("facts", []), "No durable facts recorded.")
    lines += section("DECISIONS", state.get("decisions", []), "No durable decisions recorded.")
    lines += section("ACTIVE", state.get("active", []), "No active focus recorded.")
    lines += section("NEXT", state.get("next", []), "No next steps recorded.")
    lines += section("DO_NOT", state.get("doNot", []), "No additional prohibitions recorded.")
    lines += section("OPEN_QUESTIONS", state.get("openQuestions", []), "No open questions recorded.")
    (path / "MEMORY.md").write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
    (path / "ACTIVE.md").write_text("\n".join(section("ACTIVE", state.get("active", []), "No active focus recorded.")), encoding="utf-8")
    (path / "DECISIONS.md").write_text("\n".join(section("DECISIONS", state.get("decisions", []), "No durable decisions recorded.")), encoding="utf-8")
    (path / "PROGRESS.md").write_text("\n".join(section("NEXT", state.get("next", []), "No next steps recorded.")), encoding="utf-8")
    write_json(path / "INDEX.json", {"schemaVersion": 1, "revision": state["revision"], "updatedAt": state["updatedAt"], "files": ["MEMORY.md", "MEMORY.json", "ACTIVE.md", "DECISIONS.md", "PROGRESS.md", "EVENTS.jsonl"]})

def append_event(path: Path, event: dict) -> None:
    with (path / "EVENTS.jsonl").open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(event, sort_keys=True) + "\n")

def next_id(state: dict, item_type: str) -> str:
    section_name = TARGET[item_type]
    prefix = PREFIX[item_type]
    used = []
    for item in state.get(section_name, []):
        value = str(item.get("id", ""))
        if value.startswith(prefix + "-"):
            try:
                used.append(int(value.split("-", 1)[1]))
            except ValueError:
                pass
    return f"{prefix}-{(max(used) if used else 0) + 1:04d}"

def action_init(args) -> None:
    path = memory_dir(args.root, args.workspace)
    state = load_state(path, args.workspace, args.agent_id)
    write_json(path / "MEMORY.json", state)
    render(path, state)
    append_event(path, {"type": "init", "at": now(), "agentId": args.agent_id, "revision": state["revision"]})
    print(path / "MEMORY.md")

def action_read(args) -> None:
    path = memory_dir(args.root, args.workspace)
    if not (path / "MEMORY.md").exists():
        action_init(args)
    print((path / "MEMORY.md").read_text(encoding="utf-8"))

def action_propose(args) -> None:
    path = memory_dir(args.root, args.workspace)
    state = load_state(path, args.workspace, args.agent_id)
    write_json(path / "MEMORY.json", state)
    render(path, state)
    proposal = {"schemaVersion": 1, "workspaceHash": args.workspace, "type": args.type, "text": args.text.strip(), "agentId": args.agent_id, "createdAt": now(), "parentRevision": state.get("revision", 0), "parentSha256": sha(path / "MEMORY.json")}
    target = path / "inbox" / f"{int(time.time())}-{args.agent_id}-{args.type}.memory.json"
    write_json(target, proposal)
    append_event(path, {"type": "propose", "at": now(), "agentId": args.agent_id, "proposal": str(target)})
    print(target)

def action_apply(args) -> None:
    path = memory_dir(args.root, args.workspace)
    state = load_state(path, args.workspace, args.agent_id)
    proposal = Path(args.proposal)
    data = json.loads(proposal.read_text(encoding="utf-8"))
    if data.get("parentSha256") and data["parentSha256"] != sha(path / "MEMORY.json"):
        print(f"Conflict: parentSha256 does not match. Proposal remains in inbox: {proposal}")
        return
    item_type = data["type"]
    target_section = TARGET[item_type]
    item = {"id": next_id(state, item_type), "text": data["text"], "createdAt": now(), "createdBy": data.get("agentId", args.agent_id)}
    state.setdefault(target_section, []).append(item)
    state["revision"] = int(state.get("revision", 0)) + 1
    state["updatedAt"] = now()
    state["updatedBy"] = args.agent_id
    write_json(path / "MEMORY.json", state)
    render(path, state)
    append_event(path, {"type": "apply", "at": now(), "agentId": args.agent_id, "itemId": item["id"], "revision": state["revision"]})
    print(item["id"])

def action_validate(args) -> None:
    path = memory_dir(args.root, args.workspace)
    state = load_state(path, args.workspace, args.agent_id)
    missing = [name for name in ["MEMORY.md", "MEMORY.json", "ACTIVE.md", "DECISIONS.md", "PROGRESS.md"] if not (path / name).exists()]
    if missing:
        raise SystemExit(f"Missing memory files: {', '.join(missing)}")
    for key in SECTIONS:
        if key not in state:
            raise SystemExit(f"Missing memory section: {key}")
    print("memory valid")

def main() -> int:
    parser = argparse.ArgumentParser(description="Manage coordinated Air-Gap workspace memory")
    parser.add_argument("--root", required=True, type=Path)
    sub = parser.add_subparsers(dest="action", required=True)
    for action in ["init", "read", "validate"]:
        child = sub.add_parser(action)
        child.add_argument("--workspace", required=True)
        child.add_argument("--agent-id", default="agent")
    child = sub.add_parser("propose")
    child.add_argument("--workspace", required=True)
    child.add_argument("--type", required=True, choices=sorted(TARGET))
    child.add_argument("--text", required=True)
    child.add_argument("--agent-id", default="agent")
    child = sub.add_parser("apply")
    child.add_argument("--workspace", required=True)
    child.add_argument("--proposal", required=True)
    child.add_argument("--agent-id", default="agent")
    args = parser.parse_args()
    args.root = args.root.expanduser().resolve()
    globals()[f"action_{args.action}"](args)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
'''


def windows_scripts(env: dict, version: str) -> dict[str, str]:
    return {
        "Initialize-AirgapClineEnvironment.ps1": f'''
            [CmdletBinding()]
            param([string]$RootPath = "", [string]$AgentId = "default-agent", [switch]$DryRun, [switch]$Repair)
            Set-StrictMode -Version Latest
            $ErrorActionPreference = "Stop"
            if ([string]::IsNullOrWhiteSpace($RootPath)) {{ $RootPath = Split-Path -Parent $PSScriptRoot }}
            $RootPath = [System.IO.Path]::GetFullPath($RootPath)
            if (-not (Test-Path -LiteralPath (Join-Path $RootPath "MANIFEST.json") -PathType Leaf)) {{ throw "Invalid Air-Gap Cline environment: $RootPath" }}
            if ($DryRun) {{
                Write-Host "Dry run for {env["name"]} at $RootPath"
                Write-Host "Would create or repair the current user folder and sync global Cline stubs."
                return
            }}
            & (Join-Path $PSScriptRoot "New-AirgapClineUserWorkspace.ps1") -RootPath $RootPath -AgentId $AgentId | Out-Null
            & (Join-Path $PSScriptRoot "Sync-ClineGlobalStubs.ps1") -RootPath $RootPath -Repair:$Repair | Out-Null
            $statusPath = Join-Path $RootPath "state/bootstrap-status.json"
            $status = [ordered]@{{ schemaVersion = 2; environment = "{env["name"]}"; status = "ok"; version = "{version}"; user = $env:USERNAME; domain = $env:USERDOMAIN; host = $env:COMPUTERNAME; rootPath = $RootPath; repair = [bool]$Repair; updatedAt = (Get-Date).ToString("o"); providerConfigurationChanged = $false }}
            New-Item -ItemType Directory -Force -Path (Split-Path -Parent $statusPath) | Out-Null
            $status | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $statusPath -Encoding UTF8
            Write-Host "Initialization completed for {env["name"]}."
        ''',
        "Sync-ClineGlobalStubs.ps1": r'''
            [CmdletBinding()]
            param([string]$RootPath = "", [switch]$DryRun, [switch]$Repair)
            Set-StrictMode -Version Latest
            $ErrorActionPreference = "Stop"
            if ([string]::IsNullOrWhiteSpace($RootPath)) { $RootPath = Split-Path -Parent $PSScriptRoot }
            $root = [System.IO.Path]::GetFullPath($RootPath)
            $targets = @((Join-Path $HOME ".cline/rules/00-airgap-central-environment.md"))
            $documents = [Environment]::GetFolderPath("MyDocuments")
            if (-not [string]::IsNullOrWhiteSpace($documents)) { $targets += Join-Path $documents "Cline/Rules/00-airgap-central-environment.md" }
            $stubLines = @(
                "# Air-Gap Cline Central Environment",
                "",
                "AIRGAP-CLINE-STUB:v5",
                "FIRST_READ_CONTRACT: bootstrap/FIRST_READ.md",
                "AIRGAP_CLINE_HOME=$root",
                "",
                "This global rule is the permanent entry point after the first bootstrap.",
                "",
                "## Required Behavior For Cline",
                "",
                "1. Resolve AIRGAP_CLINE_HOME from this stub before every task.",
                "2. Read $root\bootstrap\FIRST_READ.md.",
                "3. Read $root\AGENTS.md, $root\ENVIRONMENT.md, $root\MANIFEST.json, $root\VERSION, and all rules under $root\shared\rules.",
                "4. Use workflows, skills, helpers, user folders, workspace metadata, and target repositories only after this first read.",
                "5. Stop and ask for the valid Air-Gap path when the path is missing, unreadable, or contradicted by another stub.",
                "6. Do not change provider, model, authentication, or AI-server configuration."
            )
            $content = ($stubLines -join [Environment]::NewLine) + [Environment]::NewLine
            foreach ($target in $targets) {
                if ($DryRun) { Write-Host "Would write stub: $target"; continue }
                $parent = Split-Path -Parent $target
                New-Item -ItemType Directory -Force -Path $parent | Out-Null
                if ((Test-Path -LiteralPath $target) -and -not ((Get-Content -LiteralPath $target -Raw) -like "*AIRGAP-CLINE-STUB:*")) {
                    Copy-Item -LiteralPath $target -Destination "$target.backup-$(Get-Date -Format yyyyMMddHHmmss)" -Force
                }
                Set-Content -LiteralPath $target -Value $content -Encoding UTF8
            }
            $targets
        ''',
        "New-AirgapClineUserWorkspace.ps1": r'''
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
        ''',
        "Register-ExternalWorkspace.ps1": r'''
            [CmdletBinding()]
            param([string]$RootPath = "", [Parameter(Mandatory = $true)][string]$TargetPath, [string]$Alias = "")
            Set-StrictMode -Version Latest
            $ErrorActionPreference = "Stop"
            if ([string]::IsNullOrWhiteSpace($RootPath)) { $RootPath = Split-Path -Parent $PSScriptRoot }
            $python = Get-Command python -ErrorAction SilentlyContinue
            if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
            if (-not $python) { throw "Python was not found." }
            & $python.Source (Join-Path $RootPath "shared/helpers/python/register_workspace.py") --root $RootPath --target $TargetPath --alias $Alias
        ''',
        "Test-AirgapOwner.ps1": r'''
            [CmdletBinding()]
            param([Parameter(Mandatory = $true)][string]$OwnerPath, [switch]$Write)
            Set-StrictMode -Version Latest
            $ErrorActionPreference = "Stop"
            $root = Split-Path -Parent $PSScriptRoot
            $python = Get-Command python -ErrorAction SilentlyContinue
            if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
            if (-not $python) { throw "Python was not found." }
            $args = @((Join-Path $root "shared/helpers/python/guard_owner.py"), "--owner", $OwnerPath)
            if ($Write) { $args += "--write" }
            & $python.Source @args
        ''',
        "Update-AirgapMemory.ps1": r'''
            [CmdletBinding()]
            param([string]$RootPath = "", [Parameter(Mandatory = $true)][ValidateSet("init", "read", "propose", "apply", "validate")][string]$Action, [Parameter(Mandatory = $true)][string]$Workspace, [string]$Type = "fact", [string]$Text = "", [string]$Proposal = "", [string]$AgentId = "agent")
            Set-StrictMode -Version Latest
            $ErrorActionPreference = "Stop"
            if ([string]::IsNullOrWhiteSpace($RootPath)) { $RootPath = Split-Path -Parent $PSScriptRoot }
            $python = Get-Command python -ErrorAction SilentlyContinue
            if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
            if (-not $python) { throw "Python was not found." }
            $helper = Join-Path $RootPath "shared/helpers/python/memory_update.py"
            $argv = @($helper, "--root", $RootPath, $Action, "--workspace", $Workspace, "--agent-id", $AgentId)
            if ($Action -eq "propose") {
                if ([string]::IsNullOrWhiteSpace($Text)) { throw "Text is required for propose." }
                $argv += @("--type", $Type, "--text", $Text)
            }
            if ($Action -eq "apply") {
                if ([string]::IsNullOrWhiteSpace($Proposal)) { throw "Proposal is required for apply." }
                $argv += @("--proposal", $Proposal)
            }
            & $python.Source @argv
        ''',
        "Test-AirgapClineEnvironment.ps1": r'''
            [CmdletBinding()]
            param([string]$RootPath = "")
            Set-StrictMode -Version Latest
            $ErrorActionPreference = "Stop"
            if ([string]::IsNullOrWhiteSpace($RootPath)) { $RootPath = Split-Path -Parent $PSScriptRoot }
            foreach ($rel in @("START_HERE.md", "AGENTS.md", "ENVIRONMENT.md", "MANIFEST.json", "bootstrap/FIRST_READ.md")) {
                if (-not (Test-Path -LiteralPath (Join-Path $RootPath $rel))) { throw "Missing required file: $rel" }
            }
            Write-Host "Environment valid: $RootPath"
        ''',
    }


def posix_scripts(env: dict, version: str) -> dict[str, str]:
    return {
        "initialize-airgap-cline-environment.sh": f'''#!/bin/sh
set -eu
ROOT_PATH=""
AGENT_ID="default-agent"
DRY_RUN=0
REPAIR=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) ROOT_PATH="$2"; shift 2 ;;
    --agent-id) AGENT_ID="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --repair) REPAIR=1; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -z "$ROOT_PATH" ]; then ROOT_PATH=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd); fi
if [ ! -f "$ROOT_PATH/MANIFEST.json" ]; then echo "Invalid Air-Gap Cline environment: $ROOT_PATH" >&2; exit 1; fi
if [ "$DRY_RUN" -eq 1 ]; then
  echo "Dry run for {env["name"]} at $ROOT_PATH"
  echo "Would create or repair the current user folder and sync global Cline stubs."
  exit 0
fi
"$SCRIPT_DIR/new-airgap-cline-user-workspace.sh" --root "$ROOT_PATH" --agent-id "$AGENT_ID" >/dev/null
if [ "$REPAIR" -eq 1 ]; then "$SCRIPT_DIR/sync-cline-global-stubs.sh" --root "$ROOT_PATH" --repair >/dev/null; else "$SCRIPT_DIR/sync-cline-global-stubs.sh" --root "$ROOT_PATH" >/dev/null; fi
mkdir -p "$ROOT_PATH/state"
cat > "$ROOT_PATH/state/bootstrap-status.json" <<EOF
{{"schemaVersion":2,"environment":"{env["name"]}","status":"ok","version":"{version}","user":"${{USER:-unknown}}","host":"$(hostname 2>/dev/null || uname -n)","rootPath":"$ROOT_PATH","providerConfigurationChanged":false}}
EOF
echo "Initialization completed for {env["name"]}."
''',
        "sync-cline-global-stubs.sh": '''#!/bin/sh
set -eu
ROOT_PATH=""
DRY_RUN=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) ROOT_PATH="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --repair) shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -z "$ROOT_PATH" ]; then ROOT_PATH=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd); fi
write_file() {
  target="$1"
  if [ "$DRY_RUN" -eq 1 ]; then echo "Would write stub: $target"; return; fi
  dir=$(dirname -- "$target")
  mkdir -p "$dir"
  if [ -f "$target" ] && ! grep -q "AIRGAP-CLINE-STUB:" "$target" 2>/dev/null; then cp "$target" "$target.backup-$(date +%Y%m%d%H%M%S)"; fi
  cat > "$target" <<EOF
# Air-Gap Cline Central Environment

AIRGAP-CLINE-STUB:v5
FIRST_READ_CONTRACT: bootstrap/FIRST_READ.md
AIRGAP_CLINE_HOME=$ROOT_PATH

This global rule is the permanent entry point after the first bootstrap.

## Required Behavior For Cline

1. Resolve AIRGAP_CLINE_HOME from this stub before every task.
2. Read $ROOT_PATH/bootstrap/FIRST_READ.md.
3. Read $ROOT_PATH/AGENTS.md, $ROOT_PATH/ENVIRONMENT.md, $ROOT_PATH/MANIFEST.json, $ROOT_PATH/VERSION, and all rules under $ROOT_PATH/shared/rules.
4. Use workflows, skills, helpers, user folders, workspace metadata, and target repositories only after this first read.
5. Stop and ask for the valid Air-Gap path when the path is missing, unreadable, or contradicted by another stub.
6. Do not change provider, model, authentication, or AI-server configuration.
EOF
}
CLINE_HOME="${CLINE_HOME:-$HOME/.cline}"
write_file "$CLINE_HOME/rules/00-airgap-central-environment.md"
write_file "$HOME/Documents/Cline/Rules/00-airgap-central-environment.md"
write_file "$HOME/Cline/Rules/00-airgap-central-environment.md"
''',
        "new-airgap-cline-user-workspace.sh": '''#!/bin/sh
set -eu
ROOT_PATH=""
AGENT_ID="default-agent"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) ROOT_PATH="$2"; shift 2 ;;
    --agent-id) AGENT_ID="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -z "$ROOT_PATH" ]; then ROOT_PATH=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd); fi
USER_NAME="${USER:-unknown}"
HOST_NAME=$(hostname 2>/dev/null || uname -n)
OWNER_NAME=$(printf '%s_%s' "$HOST_NAME" "$USER_NAME" | sed 's/[^A-Za-z0-9_.-]/_/g')
SAFE_AGENT=$(printf '%s' "$AGENT_ID" | sed 's/[^A-Za-z0-9_.-]/_/g')
FAMILY=$(basename "$ROOT_PATH" | awk -F_ '{print tolower($3)}')
case "$FAMILY" in mac) FAMILY="mac" ;; linux) FAMILY="linux" ;; solaris) FAMILY="solaris" ;; *) FAMILY="posix" ;; esac
USER_ROOT="$ROOT_PATH/users/$FAMILY/$OWNER_NAME"
AGENT_ROOT="$USER_ROOT/agents/$SAFE_AGENT"
mkdir -p "$USER_ROOT/agents" "$USER_ROOT/scratch" "$USER_ROOT/notes" "$USER_ROOT/logs" "$USER_ROOT/outbox" "$USER_ROOT/memory" "$AGENT_ROOT/memory" "$AGENT_ROOT/outbox/memory-proposals"
cat > "$USER_ROOT/OWNER.json" <<EOF
{"schemaVersion":1,"platform":"$FAMILY","user":"$USER_NAME","host":"$HOST_NAME"}
EOF
cat > "$USER_ROOT/ALWAYS_READ.md" <<EOF
# Always Read

This folder belongs to $HOST_NAME/$USER_NAME. If you are not this user, do not write here.

Allowed write areas: the owner's agent folder, scratch, notes, logs, outbox, and memory.
EOF
[ -f "$USER_ROOT/memory/USER_MEMORY.md" ] || printf '# User Memory\n\n- No durable user preferences recorded yet.\n' > "$USER_ROOT/memory/USER_MEMORY.md"
printf '# Agent Policy\n\nWork only for the owner of this user folder. Check OWNER.json before writes. Use central helpers from AIRGAP_CLINE_HOME.\n' > "$AGENT_ROOT/AGENT_POLICY.md"
printf '# Current Task\n\nNo task recorded yet.\n' > "$AGENT_ROOT/CURRENT_TASK.md"
printf '[]\n' > "$AGENT_ROOT/WORKSPACE_BINDINGS.json"
printf '# Session Memory\n\n## Current Task\n- No task recorded yet.\n\n## Summary\n- No summary recorded yet.\n\n## Durable Proposals\n- Write durable findings as proposals under outbox/memory-proposals/.\n' > "$AGENT_ROOT/memory/SESSION.md"
echo "$AGENT_ROOT"
''',
        "register-external-workspace.sh": '''#!/bin/sh
set -eu
ROOT_PATH=""
TARGET_PATH=""
ALIAS=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) ROOT_PATH="$2"; shift 2 ;;
    --target) TARGET_PATH="$2"; shift 2 ;;
    --alias) ALIAS="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -z "$ROOT_PATH" ]; then ROOT_PATH=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd); fi
PYTHON=$(command -v python3 || command -v python || true)
if [ -z "$PYTHON" ]; then echo "Python was not found." >&2; exit 1; fi
exec "$PYTHON" "$ROOT_PATH/shared/helpers/python/register_workspace.py" --root "$ROOT_PATH" --target "$TARGET_PATH" --alias "$ALIAS"
''',
        "guard-owner.sh": '''#!/bin/sh
set -eu
OWNER_PATH=""
WRITE=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --owner) OWNER_PATH="$2"; shift 2 ;;
    --write) WRITE=1; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_PATH=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
PYTHON=$(command -v python3 || command -v python || true)
if [ -z "$PYTHON" ]; then echo "Python was not found." >&2; exit 1; fi
if [ "$WRITE" -eq 1 ]; then exec "$PYTHON" "$ROOT_PATH/shared/helpers/python/guard_owner.py" --owner "$OWNER_PATH" --write; fi
exec "$PYTHON" "$ROOT_PATH/shared/helpers/python/guard_owner.py" --owner "$OWNER_PATH"
''',
        "update-airgap-memory.sh": '''#!/bin/sh
set -eu
ROOT_PATH=""
ACTION=""
WORKSPACE=""
TYPE="fact"
TEXT=""
PROPOSAL=""
AGENT_ID="agent"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root) ROOT_PATH="$2"; shift 2 ;;
    --action) ACTION="$2"; shift 2 ;;
    --workspace) WORKSPACE="$2"; shift 2 ;;
    --type) TYPE="$2"; shift 2 ;;
    --text) TEXT="$2"; shift 2 ;;
    --proposal) PROPOSAL="$2"; shift 2 ;;
    --agent-id) AGENT_ID="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -z "$ROOT_PATH" ]; then ROOT_PATH=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd); fi
PYTHON=$(command -v python3 || command -v python || true)
if [ -z "$PYTHON" ]; then echo "Python was not found." >&2; exit 1; fi
set -- "$ROOT_PATH/shared/helpers/python/memory_update.py" --root "$ROOT_PATH" "$ACTION" --workspace "$WORKSPACE" --agent-id "$AGENT_ID"
if [ "$ACTION" = "propose" ]; then set -- "$@" --type "$TYPE" --text "$TEXT"; fi
if [ "$ACTION" = "apply" ]; then set -- "$@" --proposal "$PROPOSAL"; fi
exec "$PYTHON" "$@"
''',
        "test-airgap-cline-environment.sh": '''#!/bin/sh
set -eu
ROOT_PATH="${1:-}"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -z "$ROOT_PATH" ]; then ROOT_PATH=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd); fi
for rel in START_HERE.md AGENTS.md ENVIRONMENT.md MANIFEST.json bootstrap/FIRST_READ.md; do
  [ -f "$ROOT_PATH/$rel" ] || { echo "Missing required file: $rel" >&2; exit 1; }
done
echo "Environment valid: $ROOT_PATH"
''',
    }


def write_environment(root: Path, env: dict, version: str) -> None:
    base = root / "environments" / env["name"]
    base.mkdir(parents=True, exist_ok=True)
    for child in base.glob("START_*.md"):
        child.unlink()
    for folder in ["bootstrap", "shared/rules", "shared/workflows", "shared/skills"]:
        clear_generated_folder(base / folder)
    for folder in [
        "scripts",
        "shared/helpers/python",
        "shared/helpers/powershell",
        "shared/helpers/bash",
        "shared/helpers/posix",
        "shared/memory/schemas",
        "shared/memory/templates",
        "users",
        "workspaces",
        "state",
        "logs",
        "audit",
    ]:
        (base / folder).mkdir(parents=True, exist_ok=True)
    for folder in [
        "bootstrap",
        "scripts",
        "shared/rules",
        "shared/workflows",
        "shared/helpers/python",
        "shared/helpers/powershell",
        "shared/helpers/bash",
        "shared/helpers/posix",
        "users",
        "workspaces",
        "state",
        "logs",
        "audit",
    ]:
        write_plain(base / folder / ".gitkeep", "")
    write_plain(base / "VERSION", version + "\n")
    write(base / ".clineignore", """
        logs/**
        audit/**
        state/**
        users/**/scratch/**
        users/**/logs/**
        workspaces/**/helper-output/**
        !workspaces/**/memory/MEMORY.md
        !workspaces/**/memory/ACTIVE.md
        !workspaces/**/memory/DECISIONS.md
        !workspaces/**/memory/PROGRESS.md
        !workspaces/**/memory/INDEX.json
        *.7z
        *.zip
        *.tgz
        *.tar
        *.tar.gz
        *.exe
        *.msi
        *.vsix
        *.gguf
        *.safetensors
        *.onnx
        *.pt
        *.pth
        *.ckpt
    """)
    write(base / "START_HERE.md", f"""
        # Start Here: {env["name"]}

        This folder is an exportable Air-Gap Cline starter environment.

        ## Initialization Prompt

        Give Cline this instruction:

        ```text
        Initialize yourself from this path: {env["path"]}
        ```

        Use the actual absolute path where this folder was placed.

        ## Required Read Order

        1. `START_HERE.md`
        2. `bootstrap/FIRST_READ.md`
        3. `AGENTS.md`
        4. `ENVIRONMENT.md`
        5. `MANIFEST.json`
        6. `VERSION`
        7. `shared/rules/`

        ## Persistent Behavior After Initialization

        After bootstrap, Cline must always read the central Air-Gap path before every task. The global stub points to `AIRGAP_CLINE_HOME` and enforces the first-read contract.

        This environment does not change provider, model, authentication, or AI-server configuration.
    """)
    write(base / "AGENTS.md", f"""
        # Agent Instructions For {env["name"]}

        ## Absolute Start Requirement

        Before any task, Cline must read this central environment first. Resolve `AIRGAP_CLINE_HOME`, read `bootstrap/FIRST_READ.md`, then read this file, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION`, and all rules under `shared/rules/`.

        ## Write Matrix

        | Change type | Write location |
        | --- | --- |
        | Short-lived task notes | current agent folder under `users/{env["family"]}/.../agents/<agent-id>/` |
        | Private user preferences | `users/{env["family"]}/<owner>/memory/USER_MEMORY.md` |
        | Shared workspace memory | `workspaces/<hash>/memory/` through the memory helper |
        | Helper output | `workspaces/<hash>/helper-output/` |
        | Project changes requested by the user | the target repository or folder |

        ## Owner Guard

        Read `OWNER.json` before writing under `users/`. If the owner does not match the current user and host, do not write there.

        ## External Workspaces

        Register target folders under `workspaces/<hash>/` before using helpers or shared memory. Do not create persistent `.cline`, `.clinerules`, skills, workflows, helpers, or memory files in target repositories unless the user explicitly requests it.

        ## Provider Boundary

        Do not change provider, model, authentication, or AI-server settings.
    """)
    write(base / "ENVIRONMENT.md", f"""
        # Environment

        - Name: `{env["name"]}`
        - Operating system: {env["os"]}
        - Permission role: {env["role"]}
        - Platform family: {env["family"]}
        - Primary usage: {env["primary"]}
        - Recommended location: `{env["path"]}`
        - Version: `{version}`

        This folder is self-contained. It may be copied to a stable local path or shared path and then used as the Cline initialization path.

        Cline must already be installed, configured, and connected to the intended AI server. This environment does not install Cline and does not configure providers, models, authentication, or AI servers.
    """)
    write(base / "bootstrap/FIRST_READ.md", f"""
        # First Read Contract

        AIRGAP-CLINE-FIRST-READ:v1

        This file describes behavior after the first bootstrap. It is the first operational context Cline must read from `AIRGAP_CLINE_HOME` before any user task is handled.

        ## Required Sequence

        1. Resolve `AIRGAP_CLINE_HOME` from the global Cline stub or from the path explicitly given by the user.
        2. Confirm that the path points to `{env["name"]}` or to the intended replacement environment.
        3. Read this file completely.
        4. Read `AGENTS.md`, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION`, and all rules under `shared/rules/`.
        5. Check `state/bootstrap-status.json` when it exists. If it reports an error, do not work in a target workspace until the state is clarified.
        6. If an external workspace is used, register or locate it under `workspaces/<hash>/` and then read `memory/MEMORY.md` when it exists.

        ## Stop Conditions

        - Stop when `AIRGAP_CLINE_HOME` is missing, unreadable, or does not match the intended environment.
        - Stop when multiple Air-Gap stubs point to contradictory paths.
        - Stop before writing to a foreign user or agent folder.

        ## Invariants

        - The central path is the source of truth for rules, workflows, skills, helpers, user state, workspace metadata, and memory.
        - Provider, model, authentication, and AI-server configuration are outside this environment and must not be changed.
        - User and agent data is written only to owner-compatible folders under `users/{env["family"]}/`.
        - Shared workspace memory is maintained only under `workspaces/<hash>/memory/`.
    """)
    write(base / "bootstrap/00-airgap-central-environment.md", f"""
        # Air-Gap Cline Central Environment

        AIRGAP-CLINE-STUB:v5
        FIRST_READ_CONTRACT: bootstrap/FIRST_READ.md
        AIRGAP_CLINE_HOME=__SET_DURING_STUB_SYNC__

        This stub is written to global Cline rule paths during initialization. It is the permanent start anchor after the first bootstrap.

        ## Required For Cline

        - Read the global stub before every task and resolve `AIRGAP_CLINE_HOME`.
        - Then read `bootstrap/FIRST_READ.md` from `AIRGAP_CLINE_HOME`.
        - Then read `AGENTS.md`, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION`, and `shared/rules/*.md`.
        - Only then use workflows, skills, helpers, user folders, workspace metadata, or target repositories.
        - Stop and ask for the valid path when `AIRGAP_CLINE_HOME` is unreadable or contradictory.
        - Do not change provider, model, authentication, or AI-server settings.

        ## Environment

        - Environment: `{env["name"]}`
        - Version: `{version}`
    """)
    for name, body in RULES.items():
        text = (
            body.replace("__ENV_NAME__", env["name"])
            .replace("__ENV_OS__", env["os"])
            .replace("__ENV_ROLE__", env["role"])
            .replace("__ENV_PRIMARY__", env["primary"])
            .replace("__ENV_PATH__", env["path"])
        )
        write(base / "shared/rules" / name, text)
    for name, body in WORKFLOWS.items():
        write(base / "shared/workflows" / name, body)
    for skill_name, description in SKILLS.items():
        write_plain(base / "shared/skills" / skill_name / "SKILL.md", skill_text(skill_name, description))
    platform_skill = env["platform_skill"]
    platform_description = f"{PLATFORM_SKILLS[platform_skill]} Environment: {env['name']}. Primary mode: {env['primary']}."
    write_plain(base / "shared/skills" / platform_skill / "SKILL.md", skill_text(platform_skill, platform_description))
    write_plain(base / "shared/helpers/python/register_workspace.py", REGISTER_WORKSPACE_PY)
    write_plain(base / "shared/helpers/python/guard_owner.py", GUARD_OWNER_PY)
    write_plain(base / "shared/helpers/python/memory_update.py", MEMORY_UPDATE_PY)
    write(base / "shared/helpers/python/README.md", """
        # Python Helpers

        Python helpers are executed from the central Air-Gap environment. Their output must stay in central workspace metadata folders unless the user explicitly requests another location.
    """)
    write(base / "shared/helpers/powershell/README.md", """
        # PowerShell Helpers

        Windows-specific helpers live centrally in this folder. Use scripts through the central path and write outputs to `workspaces/<hash>/helper-output/`.
    """)
    write(base / "shared/helpers/bash/README.md", """
        # Bash Helpers

        Bash helpers live centrally in this folder. Keep target repositories free from copied helper scripts unless explicitly requested.
    """)
    write(base / "shared/helpers/posix/README.md", """
        # POSIX Helpers

        POSIX helpers must avoid non-portable assumptions where possible. Solaris support is best effort.
    """)
    write(base / "shared/memory/README.md", """
        # Coordinated Memory

        This folder contains tracked schemas and templates. Runtime memory is created under `workspaces/<hash>/memory/` and remains outside Git.

        Use `shared/helpers/python/memory_update.py` or the platform wrapper to initialize, propose, apply, read, and validate memory.
    """)
    write_plain(
        base / "shared/memory/schemas/airgap-memory.schema.json",
        json.dumps(
            {
                "$schema": "https://json-schema.org/draft/2020-12/schema",
                "title": "Air-Gap Memory",
                "type": "object",
                "required": ["schemaVersion", "scope", "workspaceHash", "revision", "updatedAt", "updatedBy"],
                "properties": {
                    "schemaVersion": {"type": "integer"},
                    "scope": {"type": "string"},
                    "workspaceHash": {"type": "string"},
                    "revision": {"type": "integer"},
                    "updatedAt": {"type": "string"},
                    "updatedBy": {"type": "string"},
                },
            },
            indent=2,
        )
        + "\n",
    )
    write_plain(
        base / "shared/memory/schemas/memory-event.schema.json",
        json.dumps(
            {
                "$schema": "https://json-schema.org/draft/2020-12/schema",
                "title": "Memory Event",
                "type": "object",
                "required": ["type", "at", "agentId"],
                "properties": {"type": {"type": "string"}, "at": {"type": "string"}, "agentId": {"type": "string"}, "revision": {"type": "integer"}},
            },
            indent=2,
        )
        + "\n",
    )
    templates = {
        "MEMORY.md": """# Memory

schema: airgap-memory/v1
scope: workspace
workspace_hash: TEMPLATE
revision: 0
updated_at: TEMPLATE
updated_by: TEMPLATE

## READ_FIRST
- R-0001: Do not store secrets, raw logs, chat transcripts, or chain-of-thought in memory.

## FACTS
- No durable facts recorded.

## DECISIONS
- No durable decisions recorded.

## ACTIVE
- No active focus recorded.

## NEXT
- No next steps recorded.

## DO_NOT
- X-0001: Do not create persistent Cline or memory files in target repositories unless explicitly requested.

## OPEN_QUESTIONS
- No open questions recorded.
""",
        "ACTIVE.md": "# Active\n\n- No active focus recorded.\n",
        "DECISIONS.md": "# Decisions\n\n- No durable decisions recorded.\n",
        "PROGRESS.md": "# Progress\n\n- No progress recorded.\n",
        "INDEX.json": json.dumps({"schemaVersion": 1, "files": ["MEMORY.md", "MEMORY.json", "ACTIVE.md", "DECISIONS.md", "PROGRESS.md", "EVENTS.jsonl"]}, indent=2) + "\n",
    }
    for name, content in templates.items():
        write_plain(base / "shared/memory/templates" / name, content)
    scripts = windows_scripts(env, version) if env["os"] == "Windows" else posix_scripts(env, version)
    for name, body in scripts.items():
        write(base / "scripts" / name, body)
    manifest = {
        "schemaVersion": 5,
        "name": env["name"],
        "version": version,
        "language": "en",
        "operatingSystem": env["os"],
        "role": env["role"],
        "platformFamily": env["family"],
        "primaryUsage": env["primary"],
        "recommendedPath": env["path"],
        "assumesClineAlreadyConfigured": True,
        "changesProviderConfiguration": False,
        "containsInstaller": False,
        "containsModelFiles": False,
        "firstReadContract": {"enabled": True, "file": "bootstrap/FIRST_READ.md", "stub": "bootstrap/00-airgap-central-environment.md"},
        "requiredFirstReadFiles": ["START_HERE.md", "bootstrap/FIRST_READ.md", "AGENTS.md", "ENVIRONMENT.md", "MANIFEST.json", "VERSION", "shared/rules"],
        "runtimeDataExcludedFromGit": ["users", "workspaces", "state", "logs", "audit"],
    }
    write_plain(base / "MANIFEST.json", json.dumps(manifest, indent=2) + "\n")
    sums = []
    for file_path in sorted(base.rglob("*")):
        if file_path.is_file() and file_path.name != "SHA256SUMS.txt":
            rel = file_path.relative_to(base).as_posix()
            sums.append(f"{hashlib.sha256(file_path.read_bytes()).hexdigest()}  {rel}")
    write_plain(base / "SHA256SUMS.txt", "\n".join(sums) + "\n")


def write_root_scripts(root: Path, version: str) -> None:
    write(root / "scripts/Apply-EnglishEnvironment.ps1", f"""
        [CmdletBinding()]
        param([string]$RootPath = "", [string]$Version = "{version}")
        Set-StrictMode -Version Latest
        $ErrorActionPreference = "Stop"
        $ScriptDir = if ($PSScriptRoot) {{ $PSScriptRoot }} else {{ Split-Path -Parent $MyInvocation.MyCommand.Path }}
        if ([string]::IsNullOrWhiteSpace($RootPath)) {{ $RootPath = Split-Path -Parent $ScriptDir }}
        $RepoRoot = [System.IO.Path]::GetFullPath($RootPath)
        $python = Get-Command python -ErrorAction SilentlyContinue
        if (-not $python) {{ $python = Get-Command python3 -ErrorAction SilentlyContinue }}
        if (-not $python) {{ throw "Python was not found." }}
        & $python.Source (Join-Path $ScriptDir "Apply-EnglishEnvironment.py") --root $RepoRoot --version $Version
    """)
    wrapper = f"""
        [CmdletBinding()]
        param([string]$RootPath = "", [string]$Version = "{version}")
        Set-StrictMode -Version Latest
        $ErrorActionPreference = "Stop"
        $ScriptDir = if ($PSScriptRoot) {{ $PSScriptRoot }} else {{ Split-Path -Parent $MyInvocation.MyCommand.Path }}
        & (Join-Path $ScriptDir "Apply-EnglishEnvironment.ps1") -RootPath $RootPath -Version $Version
    """
    for name in ["Apply-V2Enhancements.ps1", "Apply-V3Enhancements.ps1", "Apply-V4Enhancements.ps1"]:
        write(root / "scripts" / name, wrapper)
    write(root / "scripts/Sync-EnvironmentTemplates.ps1", f"""
        [CmdletBinding()]
        param([string]$RootPath = "", [string]$Version = "{version}")
        Set-StrictMode -Version Latest
        $ErrorActionPreference = "Stop"
        $ScriptDir = if ($PSScriptRoot) {{ $PSScriptRoot }} else {{ Split-Path -Parent $MyInvocation.MyCommand.Path }}
        if ([string]::IsNullOrWhiteSpace($RootPath)) {{ $RootPath = Split-Path -Parent $ScriptDir }}
        $RepoRoot = [System.IO.Path]::GetFullPath($RootPath)
        & (Join-Path $ScriptDir "Apply-EnglishEnvironment.ps1") -RootPath $RepoRoot -Version $Version
        Write-Host "Environment templates synchronized: $RepoRoot"
    """)
    write(root / "scripts/New-ReleaseManifest.ps1", f"""
        [CmdletBinding()]
        param([string]$DistPath = "", [string]$Version = "{version}")
        Set-StrictMode -Version Latest
        $ErrorActionPreference = "Stop"
        $ScriptDir = if ($PSScriptRoot) {{ $PSScriptRoot }} else {{ Split-Path -Parent $MyInvocation.MyCommand.Path }}
        if ([string]::IsNullOrWhiteSpace($DistPath)) {{ $DistPath = Join-Path (Split-Path -Parent $ScriptDir) "dist" }}
        if (-not (Test-Path -LiteralPath $DistPath)) {{ throw "DistPath does not exist: $DistPath" }}
        function Get-AssetInfo {{
            param([System.IO.FileInfo]$File)
            $hash = Get-FileHash -LiteralPath $File.FullName -Algorithm SHA256
            $packageType = if ($File.Extension -eq ".7z") {{ "7z" }} elseif ($File.Extension -eq ".zip") {{ "zip" }} else {{ "metadata" }}
            $environmentName = "none"
            if ($File.Name -match "^(Cline_Env_(Windows|Linux|Mac|Solaris)_(User|Admin)|Cline_Env_All)_v") {{ $environmentName = $Matches[1] }}
            [ordered]@{{ name = $File.Name; size = $File.Length; sha256 = $hash.Hash.ToLowerInvariant(); packageType = $packageType; environmentName = $environmentName; generatedAt = (Get-Date).ToString("o") }}
        }}
        $assets = Get-ChildItem -LiteralPath $DistPath -File | Where-Object {{ $_.Name -notin @("RELEASE_MANIFEST.json", "SHA256SUMS.txt") }} | Sort-Object Name | ForEach-Object {{ Get-AssetInfo -File $_ }}
        $manifest = [ordered]@{{ schemaVersion = 3; version = $Version; language = "en"; generatedAt = (Get-Date).ToString("o"); artifactCount = $assets.Count; assets = $assets }}
        $manifestPath = Join-Path $DistPath "RELEASE_MANIFEST.json"
        $manifest | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
        $sumPath = Join-Path $DistPath "SHA256SUMS.txt"
        $lines = Get-ChildItem -LiteralPath $DistPath -File | Where-Object {{ $_.Name -ne "SHA256SUMS.txt" }} | Sort-Object Name | ForEach-Object {{ $hash = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256; "$($hash.Hash.ToLowerInvariant())  $($_.Name)" }}
        Set-Content -LiteralPath $sumPath -Value (($lines -join "`n") + "`n") -Encoding UTF8
        Write-Host "Release manifest written: $manifestPath"
    """)
    write(root / "scripts/Build-AllEnvironmentPackages.ps1", f"""
        [CmdletBinding()]
        param([string]$RootPath = "", [string]$Version = "{version}", [string]$OutputPath = "", [switch]$SkipTests)
        Set-StrictMode -Version Latest
        $ErrorActionPreference = "Stop"
        $ScriptDir = if ($PSScriptRoot) {{ $PSScriptRoot }} else {{ Split-Path -Parent $MyInvocation.MyCommand.Path }}
        if ([string]::IsNullOrWhiteSpace($RootPath)) {{ $RootPath = Split-Path -Parent $ScriptDir }}
        if ([string]::IsNullOrWhiteSpace($OutputPath)) {{ $OutputPath = Join-Path (Split-Path -Parent $ScriptDir) "dist" }}
        $RepoRoot = [System.IO.Path]::GetFullPath($RootPath)
        $Date = (Get-Date).ToString("yyyy-MM-dd")
        $SevenZip = "C:\\Program Files\\7-Zip\\7z.exe"
        if (-not $SkipTests) {{ & (Join-Path $PSScriptRoot "Test-AllEnvironmentPackages.ps1") -RootPath $RepoRoot }}
        if (-not (Test-Path -LiteralPath $SevenZip)) {{ throw "7-Zip was not found: $SevenZip" }}
        if (Test-Path -LiteralPath $OutputPath) {{ Remove-Item -LiteralPath $OutputPath -Recurse -Force }}
        New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null
        $stageRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("airgap-cline-package-" + [guid]::NewGuid().ToString("N"))
        New-Item -ItemType Directory -Force -Path $stageRoot | Out-Null
        function Copy-CleanTree {{
            param([Parameter(Mandatory = $true)][string]$Source, [Parameter(Mandatory = $true)][string]$Destination)
            $sourceFull = [System.IO.Path]::GetFullPath($Source)
            Get-ChildItem -LiteralPath $sourceFull -Recurse -Force | ForEach-Object {{
                $relative = $_.FullName.Substring($sourceFull.Length).TrimStart('\\', '/')
                if ([string]::IsNullOrWhiteSpace($relative)) {{ return }}
                $parts = $relative -split '[\\\\/]'
                $isRuntime = $parts[0] -in @("users", "workspaces", "state", "logs", "audit")
                if ($isRuntime -and $_.PSIsContainer) {{ New-Item -ItemType Directory -Force -Path (Join-Path $Destination $relative) | Out-Null; return }}
                if ($isRuntime -and $_.Name -ne ".gitkeep") {{ return }}
                $target = Join-Path $Destination $relative
                if ($_.PSIsContainer) {{ New-Item -ItemType Directory -Force -Path $target | Out-Null }} else {{ $parent = Split-Path -Parent $target; if ($parent) {{ New-Item -ItemType Directory -Force -Path $parent | Out-Null }}; Copy-Item -LiteralPath $_.FullName -Destination $target -Force }}
            }}
        }}
        function Test-ZipArchive {{
            param([string]$ZipPath, [string]$ExpectedRootName)
            $extractRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("airgap-cline-ziptest-" + [guid]::NewGuid().ToString("N"))
            try {{ Expand-Archive -LiteralPath $ZipPath -DestinationPath $extractRoot -Force; $found = Get-ChildItem -LiteralPath $extractRoot -Directory -Recurse -Filter $ExpectedRootName | Select-Object -First 1; if (-not $found) {{ throw "ZIP archive does not contain expected root: $ExpectedRootName" }} }} finally {{ if (Test-Path -LiteralPath $extractRoot) {{ Remove-Item -LiteralPath $extractRoot -Recurse -Force }} }}
        }}
        try {{
            $envRoot = Join-Path $RepoRoot "environments"
            $envs = Get-ChildItem -LiteralPath $envRoot -Directory -Filter "Cline_Env_*" | Sort-Object Name
            foreach ($env in $envs) {{
                $stage = Join-Path $stageRoot $env.Name
                Copy-CleanTree -Source $env.FullName -Destination $stage
                $zipPath = Join-Path $OutputPath ("{{0}}_v{{1}}_{{2}}.zip" -f $env.Name, $Version, $Date)
                $sevenPath = Join-Path $OutputPath ("{{0}}_v{{1}}_{{2}}.7z" -f $env.Name, $Version, $Date)
                Compress-Archive -Path $stage -DestinationPath $zipPath -Force
                Test-ZipArchive -ZipPath $zipPath -ExpectedRootName $env.Name
                & $SevenZip a -t7z $sevenPath $stage | Out-Null
                & $SevenZip t $sevenPath | Out-Null
            }}
            $allStage = Join-Path $stageRoot "Cline_Env_All"
            New-Item -ItemType Directory -Force -Path $allStage | Out-Null
            foreach ($env in $envs) {{ Copy-CleanTree -Source $env.FullName -Destination (Join-Path $allStage $env.Name) }}
            $allZip = Join-Path $OutputPath ("Cline_Env_All_v{{0}}_{{1}}.zip" -f $Version, $Date)
            $all7z = Join-Path $OutputPath ("Cline_Env_All_v{{0}}_{{1}}.7z" -f $Version, $Date)
            Compress-Archive -Path $allStage -DestinationPath $allZip -Force
            Test-ZipArchive -ZipPath $allZip -ExpectedRootName "Cline_Env_All"
            & $SevenZip a -t7z $all7z $allStage | Out-Null
            & $SevenZip t $all7z | Out-Null
            $notes = @(
                "# Release v$Version",
                "",
                "This release contains one `.7z` and one `.zip` package for each exportable Air-Gap Cline environment plus an all-in-one package.",
                "",
                "Cline must already be installed, configured, and connected to the intended AI server. These packages contain no provider, model, authentication, or AI-server data.",
                "",
                "## Selection",
                "",
                "- Windows User/Admin: primary target for the VS Code Cline extension.",
                "- Linux User/Admin: primary target for Cline CLI.",
                "- macOS User/Admin: CLI or editor-adjacent usage.",
                "- Solaris User/Admin: POSIX best effort, only when Cline already runs there.",
                "",
                "## Verification",
                "",
                "All `.7z` packages were tested with 7-Zip. All `.zip` packages were extracted and checked for the expected root folder. Each environment includes the coordinated memory model and first-read contract. Runtime memory remains outside Git."
            ) -join "`n"
            Set-Content -LiteralPath (Join-Path $OutputPath "RELEASE_NOTES.md") -Value ($notes + "`n") -Encoding UTF8
            & (Join-Path $PSScriptRoot "New-ReleaseManifest.ps1") -DistPath $OutputPath -Version $Version
            Write-Host "Packages created in: $OutputPath"
        }} finally {{ if (Test-Path -LiteralPath $stageRoot) {{ Remove-Item -LiteralPath $stageRoot -Recurse -Force }} }}
    """)
    write(root / "scripts/Test-AllEnvironmentPackages.ps1", """
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
                Assert-FileContains -Path (Join-Path $envRoot "scripts/Sync-ClineGlobalStubs.ps1") -Needle "bootstrap\\FIRST_READ.md"
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
        & (Join-Path $ScriptDir "Test-ClineMarkdownBehavior.ps1") -RootPath $RepoRoot
        $nonAscii = Get-ChildItem -LiteralPath $RepoRoot -Recurse -File -Force | Where-Object { $_.FullName -notmatch "\\\\.git\\\\|\\\\dist\\\\|\\\\__pycache__\\\\" -and $_.Extension -ne ".pyc" } | Select-String -Pattern "[^\\x00-\\x7F]" -ErrorAction SilentlyContinue
        if ($nonAscii) { throw "Non-ASCII content remains: $($nonAscii[0].Path)" }
        Write-Host "All exportable environments are valid."
    """)


def main() -> int:
    import argparse

    parser = argparse.ArgumentParser(description="Generate English Air-Gap Cline environments")
    parser.add_argument("--root", default="")
    parser.add_argument("--version", default=VERSION_DEFAULT)
    args = parser.parse_args()

    script_dir = Path(__file__).resolve().parent
    repo_root = Path(args.root).resolve() if args.root else script_dir.parent
    write_root_docs(repo_root, args.version)
    write_root_scripts(repo_root, args.version)
    for env in ENVIRONMENTS:
        write_environment(repo_root, env, args.version)
    print(f"English environments generated: {repo_root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
