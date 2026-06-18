---
AIRGAP-CLINE-MANAGED:v5
---
# Check First-Read Behavior

1. Find the global Cline stub.
2. Resolve `AIRGAP_CLINE_HOME`.
3. Confirm that `bootstrap/FIRST_READ.md` exists.
4. Confirm that `AGENTS.md`, `ENVIRONMENT.md`, `MANIFEST.json`, `VERSION`, and `shared/rules/` are readable.
5. Stop if different stubs point to different central paths.
