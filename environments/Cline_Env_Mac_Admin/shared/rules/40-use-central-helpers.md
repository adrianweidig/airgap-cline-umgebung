---
AIRGAP-CLINE-MANAGED:v5
---
# Use Central Helpers

- Prefer helper scripts from `shared/helpers/`.
- Execute helpers from the central environment path.
- Write helper outputs into the central workspace metadata folder.
- Do not copy helpers into target repositories unless the user explicitly requests that.
- If a helper is missing or incompatible, report the exact limitation and continue manually when safe.
