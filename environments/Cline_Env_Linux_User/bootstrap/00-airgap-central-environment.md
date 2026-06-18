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

- Environment: `Cline_Env_Linux_User`
- Version: `0.5.0`
