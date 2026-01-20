# Claude Plugins

A skill framework for Claude Code, providing interactive project setup wizards and domain configuration tools.

## Overview

This repository contains the "crunch" plugin - a collection of skills that help configure and document project infrastructure through guided, multi-step wizards.

## Structure

```
plugins/crunch/
├── data/                    # Shared data files
│   └── domains.yaml         # 14 project domain definitions
├── skills/                  # Skill implementations
│   ├── setup-project-domain-vendor/  # Generic domain setup wizard
│   ├── setup-mcp/                    # MCP server configuration
│   ├── lookup-vendor/                # Vendor discovery service
│   └── track-setup-progress/         # Progress tracking service
└── templates/               # CLAUDE.md templates
    ├── CLAUDE.template.md   # Full project template with all domains
    └── task-management.template.md
```

## Project Domains

The framework supports **14 project domains** organized into required and optional categories:

### Required Domains (7)
- **Tech Stack** - Programming languages and frameworks
- **Configuration** - Environment variables management
- **Secrets** - Secure secrets storage
- **Pipelines** - Local, CI, and deploy pipelines
- **Deploy Environments** - dev/staging/prod environments
- **Task Management** - Work item tracking (Input → Intent → Issue → WorkItem)
- **Agents & Orchestration** - Claude Code agent configuration

### Optional Domains (7)
- **Memory Management** - Persistent AI context
- **User Communication Bot** - Slack/Discord integration
- **CI/CD** - Continuous integration/deployment
- **Observability** - Metrics, logs, traces, alerting
- **Problem Remediation** - Runbook automation
- **Documentation** - Doc site generation
- **Localization** - i18n and translation

## Skills

### setup-project-domain-vendor

Generic setup wizard that works for any domain. Uses a 6-phase workflow:

1. **State Detection** - Check existing configuration
2. **Vendor Selection** - Discover and select vendors via `lookup-vendor`
3. **Prerequisites** - Install required CLI tools
4. **Configuration** - Configure MCP/CLI/file-based integration
5. **Connection Test** - Verify setup works
6. **Documentation** - Update CLAUDE.md with configuration

### Supporting Skills

- **lookup-vendor** - Web search and caching for vendor discovery
- **track-setup-progress** - Persistent progress tracking across sessions
- **setup-mcp** - MCP server configuration helper

## Usage

Skills are invoked through Claude Code. The `setup-project-domain-vendor` skill will:

1. Ask which domain to configure
2. Enter plan mode to design the setup approach
3. Guide through vendor selection and configuration
4. Document the setup in your project's CLAUDE.md

## Templates

The `templates/CLAUDE.template.md` provides a complete project template with:
- All 14 domain sections
- Operations required tables for each vendor-enabled domain
- Setup checklists for tracking configuration progress

## Contributing

- **Branch naming**: `<username>/<feature-description>`
- **Commit format**: `feat(scope):`, `fix(scope):`, `docs(scope):`

## License

[Add license information]
