# Contributing

Contributions must keep all documentation, user-facing text, comments, templates, and generated content in English. Exportable environments must remain usable without mandatory dependency on generator sources.

## Rules

- Do not add installers, binaries, VSIX files, model files, or generated archives.
- Every exportable environment must remain self-contained and understandable on its own.
- Changes to shared rules, workflows, skills, helpers, or memory templates must be synchronized across all eight environments.
- Run `scripts/Test-AllEnvironmentPackages.ps1` before submitting changes.
