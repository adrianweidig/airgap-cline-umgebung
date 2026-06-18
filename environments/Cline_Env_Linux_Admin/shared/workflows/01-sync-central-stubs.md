---
AIRGAP-CLINE-MANAGED:v5
---
# Sync Central Stubs

1. Determine the absolute central environment path.
2. Determine user-owned global Cline rule locations for the platform.
3. If an existing target file is not marked as Air-Gap managed, create a timestamped backup first.
4. Write a stub that contains `AIRGAP_CLINE_HOME`, `AIRGAP-CLINE-STUB:v5`, and the first-read contract.
5. Verify that each written stub points to the same central path.
