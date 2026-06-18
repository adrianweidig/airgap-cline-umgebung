---
AIRGAP-CLINE-MANAGED:v5
name: user-agent-protection
description: Checks OWNER.json and protects foreign user and agent folders from writes.
---
# user-agent-protection

Use this skill when the current task matches this description: Checks OWNER.json and protects foreign user and agent folders from writes.

## Procedure

1. Perform the central first-read sequence.
2. Read `AGENTS.md`, `ENVIRONMENT.md`, and the relevant rules.
3. Use central helpers and central workspace metadata.
4. Do not write to foreign user or agent folders.
5. Do not change provider, model, authentication, or AI-server settings.
