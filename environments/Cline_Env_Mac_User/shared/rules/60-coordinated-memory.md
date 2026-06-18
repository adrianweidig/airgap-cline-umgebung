---
AIRGAP-CLINE-MANAGED:v5
---
# Coordinated Memory

- Read workspace `memory/MEMORY.md` before changing an external workspace when memory exists.
- Keep shared memory short, deterministic, and structured by stable IDs.
- Write short-lived notes to the current agent session memory.
- Write durable shared updates through the memory helper as proposals or validated apply operations.
- Never store secrets, raw logs, chat transcripts, or chain-of-thought in memory.
- Never place memory files in target repositories unless the user explicitly requests that.
