---
AIRGAP-CLINE-MANAGED:v5
---
# Register External Workspace

1. Normalize the target path.
2. Hash the normalized path.
3. Create `workspaces/<hash>/WORKSPACE.json` in the central environment.
4. Create `NOTES.md`, `RULE_OVERRIDES.md`, `helper-output/`, and `memory/` under that workspace metadata folder.
5. Do not create Cline infrastructure files in the target repository.
