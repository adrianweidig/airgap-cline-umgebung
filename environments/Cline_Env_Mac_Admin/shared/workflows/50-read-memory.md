---
AIRGAP-CLINE-MANAGED:v5
---
# Read Memory

1. Resolve the workspace hash.
2. Read `workspaces/<hash>/memory/MEMORY.md` when it exists.
3. Read `ACTIVE.md`, `DECISIONS.md`, and `PROGRESS.md` only when more detail is needed.
4. Treat `MEMORY.json` as the machine-readable state.
5. Keep memory context small and high signal.
