# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A skill framework for Claude Code, centered on the "crunch" plugin which provides interactive project setup wizards.

## Architecture

### Plugin System (`plugins/crunch/skills/`)

The plugin framework uses **meta-skills** that generate domain-specific setup wizards:

```
setup-project/           # Main dashboard - detects and configures 14 project domains
├── SKILL.md             # Wizard definition with phases and DOD
└── templates/           # Domain templates for CLAUDE.md generation
    ├── task-management.template.md
    ├── secrets.template.md
    ├── ci-cd.template.md
    └── [11 more domains]

create-project-domain-setup-skill/  # Meta-skill to generate new domain skills
setup-mcp/               # Generic MCP server setup wizard
create-tool-skills/      # Generate skills for tools
```

**14 Project Domains**: Tech Stack, Configuration, Secrets, Pipelines, Environments, Task Management, Agents & Orchestration (required); Memory Management, User Communication Bot, CI/CD, Observability, Problem Remediation, Documentation, Localization (optional)

### Skill Structure Pattern

Each skill follows a standardized pattern:
- **Phases**: Discovery → Suggestion → Configuration → Verification
- **DOD (Definition of Done)**: Explicit completion criteria
- **Progress files**: Persistent state across Claude Code reloads (e.g., `{domain}-setup-progress.md`)
- **CLAUDE.md sections**: Skills generate sections for project context

## Code Style

### Markdown Tables

Align column widths with spaces for readability:

```markdown
# Bad - misaligned columns
| Minimal Task System | {task_backend} Equivalent |
|---------------------|---------------------------|
| Input | {backend_input_mapping} |
| Intent | {backend_intent_mapping} |

# Good - aligned columns
| Minimal Task System | {task_backend} Equivalent  |
|---------------------|----------------------------|
| Input               | {backend_input_mapping}    |
| Intent              | {backend_intent_mapping}   |
```

## Git Workflow

- **Branch naming**: `<username>/<feature-description>`
- **Commit format**: `feat(scope):`, `fix(scope):`, `docs(scope):`

## Claude Models

Current model IDs:
- Sonnet: `claude-sonnet-4-5-20250929`
- Haiku: `claude-haiku-4-5-20251001`
- Opus: `claude-opus-4-5-20251101`
