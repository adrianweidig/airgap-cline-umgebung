# Security Policy

## Scope

This project provides Cline rules, workflows, skills, local helper scripts, and memory templates. It contains no secrets, provider configuration, third-party binaries, model files, or installers.

## Reporting Security Issues

Do not report sensitive security issues in public issues when they contain concrete vulnerabilities, tokens, internal paths, or abuse-ready details. Use a private contact path provided by the repository owner.

## Security Expectations

- Cline agents must respect foreign user and agent folders.
- Provider, model, authentication, and AI-server settings are outside this project.
- Target repositories must not receive persistent Cline infrastructure files unless explicitly requested by the user.
- Runtime memory must not contain secrets, raw chat logs, or chain-of-thought.
