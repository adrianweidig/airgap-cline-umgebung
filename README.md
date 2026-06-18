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
Initialize yourself from this path: C:\Cline_AirGap\Cline_Env_Windows_User
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
.\scripts\Test-AllEnvironmentPackages.ps1
.\scripts\Test-ClineMarkdownBehavior.ps1
.\scripts\Build-AllEnvironmentPackages.ps1 -Version 0.5.0
```

`Test-AllEnvironmentPackages.ps1` includes the Cline Markdown behavior simulation. The simulation is a scenario-based deterministic test for the agent instructions: first-read order, central path handling, provider boundaries, external workspace behavior, coordinated memory, owner protection, central helper use, and air-gap assumptions.

## Useful Documents

- [`START_HERE.md`](START_HERE.md): entry point for repository viewers.
- [`ARCHITECTURE.md`](ARCHITECTURE.md): architecture and central path behavior.
- [`docs/MEMORY-MODEL.md`](docs/MEMORY-MODEL.md): coordinated memory format and update rules.
- [`SECURITY.md`](SECURITY.md): security expectations.
- [`CONTRIBUTING.md`](CONTRIBUTING.md): contribution rules.
