---
name: Bug report
description: Report a problem with an exportable Air-Gap Cline environment
title: "[Bug]: "
labels: ["bug"]
body:
  - type: textarea
    id: problem
    attributes:
      label: Problem
      description: What happened?
    validations:
      required: true
  - type: dropdown
    id: environment
    attributes:
      label: Environment
      options:
        - Cline_Env_Windows_User
        - Cline_Env_Windows_Admin
        - Cline_Env_Linux_User
        - Cline_Env_Linux_Admin
        - Cline_Env_Mac_User
        - Cline_Env_Mac_Admin
        - Cline_Env_Solaris_User
        - Cline_Env_Solaris_Admin
  - type: textarea
    id: validation
    attributes:
      label: Validation output
      description: Include relevant output from the test or initialization script. Remove secrets and internal paths when needed.
---
