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
