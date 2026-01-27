# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A skill framework for Claude Code, centered on the "crunch" plugin which provides interactive project setup wizards.

## Architecture

### Directory Structure

```
plugins/crunch/
├── data/
│   ├── domains.yaml             # Domain definitions with vendor_requirements, domain_check
│   ├── abstract/                # Vendor-agnostic domain content (e.g., task-management.md)
│   └── survey/                  # Survey description files for user-survey skill
└── skills/
    ├── setup-project/           # Main entry point - orchestrates all domain setup
    ├── setup-domain-vendor/     # Generic vendor setup (7 phases)
    ├── lookup-vendor/           # Vendor discovery with web search + caching
    ├── user-survey/             # Conversational survey from markdown descriptions
    ├── user-communication/      # Two-way messaging (DM/channel modes)
    ├── setup-mcp/               # MCP server configuration
    └── track-setup-progress/    # Persistent state across session restarts
```

### Skill Hierarchy

```
setup-project (main wizard)
├── user-survey          # Collect project-specific info
├── setup-domain-vendor  # Configure vendor for domain
│   ├── lookup-vendor    # Get vendor definition
│   └── track-setup-progress
└── [writes CLAUDE.md sections: Survey → Abstract → Vendor]
```

### Domain Configuration (`domains.yaml`)

Each domain can have:

```yaml
- name: Task Management
  key: task-management
  required: true
  has_vendor: true
  survey: plugins/crunch/data/survey/task-management.md # Optional
  vendor_requirements: # What vendor must support
    - It should allow to create a task
    - It should allow to read a task by id
  domain_check:
    general_check: # Run by setup-project after survey
      - Verify runtime is installed
    vendor_check: # Run by setup-domain-vendor after install
      - Create test task
      - Delete test task
  vendors: # Known vendors for this domain
    - Linear
    - Jira
```

### CLAUDE.md Section Structure

Skills generate domain sections in this order:

```markdown
## {Domain Name}

{Survey result - project-specific info from user-survey}

### Abstract

{Content from data/abstract/{domain-key}.md - vendor-agnostic concepts}

### Vendor: {Vendor Name}

{Vendor-specific configuration, operations, troubleshooting}
```

## Code Style

### Markdown Tables

Align column widths with spaces for readability:

```markdown
# Good - aligned columns

| Minimal Task System | {task_backend} Equivalent |
| ------------------- | ------------------------- |
| Input               | {backend_input_mapping}   |
| Intent              | {backend_intent_mapping}  |
```

### Skill Files

Each skill has a `SKILL.md` with:

- **Frontmatter**: name, description, arguments
- **Definition of Done**: Explicit completion criteria
- **Workflow**: Numbered phases with steps
- **Interactive Checkpoints**: Where user input is needed
- **Error Handling**: Recovery strategies

## Git Workflow

- **Branch naming**: `<username>/<feature-description>`
- **Commit format**: `feat(scope):`, `fix(scope):`, `docs(scope):`

## Claude Models

Current model IDs:

- Sonnet: `claude-sonnet-4-5-20250929`
- Haiku: `claude-haiku-4-5-20251001`
- Opus: `claude-opus-4-5-20251101`
