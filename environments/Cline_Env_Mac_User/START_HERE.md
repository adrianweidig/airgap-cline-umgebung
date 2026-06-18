# Start Here: Cline_Env_Mac_User

This folder is an exportable Air-Gap Cline starter environment.

## Initialization Prompt

Give Cline this instruction:

```text
Initialize yourself from this path: ~/Cline_AirGap/Cline_Env_Mac_User
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
