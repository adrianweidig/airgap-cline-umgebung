---
AIRGAP-CLINE-MANAGED:v5
---
# Create User Folder

1. Detect user, host, platform, and variant.
2. Create `users/<platform>/<owner>/` when it does not exist.
3. If `OWNER.json` exists, verify ownership before writing.
4. Create `memory/USER_MEMORY.md`, `ALWAYS_READ.md`, and the agent folder.
5. Create `AGENT_POLICY.md`, `CURRENT_TASK.md`, `WORKSPACE_BINDINGS.json`, and `memory/SESSION.md` for the agent.
