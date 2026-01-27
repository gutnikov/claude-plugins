# Claude Plugins

A skill framework for Claude Code, providing interactive project setup wizards and domain configuration tools.

## Overview

This repository contains the "crunch" plugin - a collection of skills that help configure and document project infrastructure through guided, multi-step wizards.

## Structure

```
plugins/crunch/
├── data/                        # Shared data files
│   ├── domains.yaml             # 15 project domain definitions
│   ├── abstract/                # Vendor-agnostic domain content
│   │   └── task-management.md   # Task types, states, relationships
│   └── survey/                  # Survey description files
│       ├── project-info.md
│       ├── tech-stack.md
│       └── deploy-environments.md
└── skills/                      # Skill implementations
    ├── setup-project/           # Main project setup wizard
    ├── setup-domain-vendor/     # Generic domain vendor setup
    ├── lookup-vendor/           # Vendor discovery service
    ├── user-survey/             # Conversational survey utility
    ├── user-communication/      # Two-way messaging with users
    ├── setup-mcp/               # MCP server configuration
    └── track-setup-progress/    # Progress tracking service
```

## Project Domains

The framework supports **15 project domains** organized into required and optional categories:

### Required Domains (8)

| Domain                     | Has Vendor | Survey | Abstract |
| -------------------------- | ---------- | ------ | -------- |
| **Project Info**           | No         | Yes    | No       |
| **Tech Stack**             | No         | Yes    | No       |
| **Configuration**          | Yes        | No     | No       |
| **Secrets**                | Yes        | No     | No       |
| **Pipelines**              | No         | No     | No       |
| **Deploy Environments**    | No         | Yes    | No       |
| **Task Management**        | Yes        | No     | Yes      |
| **Agents & Orchestration** | No         | No     | No       |

### Optional Domains (7)

| Domain                     | Has Vendor |
| -------------------------- | ---------- |
| **Memory Management**      | Yes        |
| **User Communication Bot** | Yes        |
| **CI/CD**                  | Yes        |
| **Observability**          | Yes        |
| **Problem Remediation**    | Yes        |
| **Documentation**          | Yes        |
| **Localization**           | Yes        |

## Skills

### setup-project

Main entry point for project configuration. Orchestrates domain setup with:

- CLAUDE.md creation/detection
- Domain status display (configured vs pending)
- Survey collection (via `user-survey`)
- General checks verification
- Vendor setup delegation (via `setup-domain-vendor`)
- CLAUDE.md section generation (Survey → Abstract → Vendor)

### setup-domain-vendor

Generic vendor setup wizard with 7-phase workflow:

1. **State Detection** - Resume or start fresh
2. **Domain Selection** - Pick domain (if not provided)
3. **Vendor Selection** - Choose vendor from list
4. **Vendor Lookup** - Get vendor definition via `lookup-vendor`
5. **Installation** - Install CLI tools, configure env vars
6. **Verification** - Run `domain_check.vendor_check` steps
7. **Documentation** - Update CLAUDE.md with abstract + vendor content

### user-survey

Conversational survey skill that:

- Reads markdown description files
- Asks open questions, then targeted follow-ups
- Outputs collected info in markdown format

### user-communication

Two-way async messaging with users:

- Supports DM (1-1) and channel (group chat) modes
- Operations: start, poll, send, close
- Works with any configured messaging vendor

### Supporting Skills

- **lookup-vendor** - Web search and caching for vendor discovery
- **track-setup-progress** - Persistent progress tracking across sessions
- **setup-mcp** - MCP server configuration helper

## Domain Checks

Domains can define verification steps in `domains.yaml`:

```yaml
domain_check:
  general_check: # Run during setup-project (after survey)
    - Verify Node.js is installed
    - Run npm install
  vendor_check: # Run during setup-domain-vendor (after install)
    - Create test secret
    - Read secret back
    - Delete test secret
```

## Usage

Skills are invoked through Claude Code:

```
/setup-project                              # Main wizard
/setup-domain-vendor                        # Domain selector
/setup-domain-vendor secrets                # Vendor selector for Secrets
/setup-domain-vendor secrets "HashiCorp Vault"  # Direct setup
```

## Contributing

- **Branch naming**: `<username>/<feature-description>`
- **Commit format**: `feat(scope):`, `fix(scope):`, `docs(scope):`

## License

[Add license information]
