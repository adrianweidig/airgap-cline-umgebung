---
AIRGAP-CLINE-MANAGED:v5
---
# User And Agent Isolation

- Check `OWNER.json` before writing under `users/`.
- If owner data does not match the current user and host, writing is forbidden.
- Each agent writes only to its own agent folder, scratch area, notes, logs, outbox, and session memory.
- Foreign agent folders may be read only when the human user explicitly requests it.
