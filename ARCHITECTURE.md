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
