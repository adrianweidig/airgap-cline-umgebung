---
AIRGAP-CLINE-MANAGED:v5
---
# No Repository Pollution

- Do not create persistent `.cline`, `.clinerules`, skills, workflows, helpers, or memory files in target repositories by default.
- Central metadata for target repositories belongs under `workspaces/<hash>/`.
- Helper outputs belong under `workspaces/<hash>/helper-output/`.
- Project files may be changed when the user task requires that.
- Exceptions must be explicitly requested by the user.
