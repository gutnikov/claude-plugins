## Documentation

**Platform**: {docs_platform}
**URL**: {docs_url}
**Source**: `{docs_source_path}`

### Structure

```
{docs_directory_structure}
```

### Commands

| Command | Description |
|---------|-------------|
| `{docs_dev_cmd}` | Start docs dev server |
| `{docs_build_cmd}` | Build docs |
| `{docs_deploy_cmd}` | Deploy docs |

### Writing Docs

1. Create/edit markdown files in `{docs_source_path}`
2. Update navigation in `{nav_config_file}`
3. Preview with `{docs_dev_cmd}`
4. Deploy with `{docs_deploy_cmd}`

### Doc Types

| Type | Location | Purpose |
|------|----------|---------|
| Getting Started | `{getting_started_path}` | Onboarding new users |
| Guides | `{guides_path}` | How-to tutorials |
| API Reference | `{api_ref_path}` | API documentation |
| Architecture | `{arch_path}` | System design docs |

### Versioning

| Version | Status | Branch |
|---------|--------|--------|
| {version_1} | Current | main |
| {version_2} | Previous | v{version_2} |

### Search

Search is {enabled/disabled}.

Configuration: `{search_config}`

### Deployment

| Environment | URL | Auto-deploy |
|-------------|-----|-------------|
| Preview | {preview_url} | On PR |
| Production | {prod_url} | On merge to main |

### Style Guide

- {style_rule_1}
- {style_rule_2}
- {style_rule_3}
