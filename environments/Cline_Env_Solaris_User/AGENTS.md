# Agent Instructions For Cline_Env_Solaris_User

## Absolute Start Requirement

Before any task, Cline must read this central environment first. Resolve `AIRGAP_CLINE_HOME`, read `bootstrap/FIRST_READ.md`, then read this file, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION`, and all rules under `shared/rules/`.

## Write Matrix

| Change type | Write location |
| --- | --- |
| Short-lived task notes | current agent folder under `users/solaris/.../agents/<agent-id>/` |
| Private user preferences | `users/solaris/<owner>/memory/USER_MEMORY.md` |
| Shared workspace memory | `workspaces/<hash>/memory/` through the memory helper |
| Helper output | `workspaces/<hash>/helper-output/` |
| Project changes requested by the user | the target repository or folder |

## Owner Guard

Read `OWNER.json` before writing under `users/`. If the owner does not match the current user and host, do not write there.

## External Workspaces

Register target folders under `workspaces/<hash>/` before using helpers or shared memory. Do not create persistent `.cline`, `.clinerules`, skills, workflows, helpers, or memory files in target repositories unless the user explicitly requests it.

## Provider Boundary

Do not change provider, model, authentication, or AI-server settings.
