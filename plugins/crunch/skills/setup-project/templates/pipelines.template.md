## Pipelines

### local

Local development workflow:

| Step | Command | Description |
|------|---------|-------------|
| install | `{install_cmd}` | Install dependencies |
| dev | `{dev_cmd}` | Start dev server |
| test | `{test_cmd}` | Run tests |
| lint | `{lint_cmd}` | Check code style |
| build | `{build_cmd}` | Build locally |

### ci

Continuous integration pipeline:

| Step | Command | Description |
|------|---------|-------------|
| lint | `{ci_lint_cmd}` | Check code style |
| test | `{ci_test_cmd}` | Run tests with coverage |
| build | `{ci_build_cmd}` | Build for production |
| security | `{ci_security_cmd}` | Security scan |

### deploy

Deployment pipeline:

| Step | Command | Description |
|------|---------|-------------|
| build | `{deploy_build_cmd}` | Build for production |
| deploy | `{deploy_cmd}` | Deploy to environment |
| verify | `{verify_cmd}` | Run smoke tests |
| rollback | `{rollback_cmd}` | Rollback if needed |

### Pipeline Runner

**Tool**: {pipeline_tool}
**Config**: `{pipeline_config_file}`

```bash
# Run a pipeline
{run_pipeline_cmd}
```
