# Security Policy

## Supported Branch

Only `main` receives active security and integrity fixes.

## Reporting a Vulnerability

Do not publish exploit details in a public issue. Use GitHub private
vulnerability reporting if it is enabled for this repository, or contact the
repository owner with a minimal private reproduction.

Useful reports include:

- Affected system or file path.
- Steps to reproduce.
- Expected and actual behavior.
- Possible impact on saves, player data, tooling, or local development.
- Any suggested mitigation.

## Scope

Dragon Forge is currently a local Godot game project. The most relevant issues
are save integrity problems, local tooling hazards, unintended secret exposure,
and automation that can modify files or execute commands without clear consent.

Out of scope:

- Vulnerabilities in Godot itself.
- Issues in third-party addons unless the project pins or wraps the behavior.
- General gameplay bugs without a security or data-integrity impact.
