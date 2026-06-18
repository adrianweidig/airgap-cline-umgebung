# First Read Contract

AIRGAP-CLINE-FIRST-READ:v1

This file describes behavior after the first bootstrap. It is the first operational context Cline must read from `AIRGAP_CLINE_HOME` before any user task is handled.

## Required Sequence

1. Resolve `AIRGAP_CLINE_HOME` from the global Cline stub or from the path explicitly given by the user.
2. Confirm that the path points to `Cline_Env_Mac_Admin` or to the intended replacement environment.
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
- User and agent data is written only to owner-compatible folders under `users/mac/`.
- Shared workspace memory is maintained only under `workspaces/<hash>/memory/`.
