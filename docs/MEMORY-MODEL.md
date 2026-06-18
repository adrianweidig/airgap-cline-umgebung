# Coordinated Memory Model

This project separates short-lived work notes, private user memory, and shared workspace memory.

| Scope | Path |
| --- | --- |
| User preferences | `users/<platform>/<owner>/memory/USER_MEMORY.md` |
| Agent session notes | `users/<platform>/<owner>/agents/<agent-id>/memory/SESSION.md` |
| Shared workspace memory | `workspaces/<hash>/memory/` |
| Helper output | `workspaces/<hash>/helper-output/` |

`MEMORY.md` is short, deterministic, and optimized for agents. It uses fixed sections: `READ_FIRST`, `FACTS`, `DECISIONS`, `ACTIVE`, `NEXT`, `DO_NOT`, and `OPEN_QUESTIONS`.

Do not store secrets, raw logs, chat transcripts, or chain-of-thought. Target repositories must not receive memory files unless the user explicitly requests that.
