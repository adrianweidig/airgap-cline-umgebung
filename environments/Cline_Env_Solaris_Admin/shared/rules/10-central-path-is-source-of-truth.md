---
AIRGAP-CLINE-MANAGED:v5
---
# Central Path Is Source Of Truth

- Rules, workflows, skills, helpers, user state, workspace metadata, and memory live in the central path.
- Global Cline stubs may contain only a stable pointer to this central path and first-read instructions.
- When Cline works in external repositories, Cline infrastructure files remain in the central path.
- Target repositories receive only project changes that directly belong to the user's task.
