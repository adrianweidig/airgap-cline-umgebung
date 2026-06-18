---
AIRGAP-CLINE-MANAGED:v5
---
# Air-Gap Principles

- Assume the target environment has no internet access.
- Do not start downloads, marketplace installations, or cloud lookups.
- Do not invent replacement artifacts. If something is missing, report the exact file name, path, and purpose.
- Cline is already functional. Provider, model, authentication, and AI-server settings are not changed by this environment.
- Every automation step must be locally auditable and must not require external installers, model files, or VSIX files.
