## CI/CD

**Platform**: {ci_platform}
**Config**: `{config_path}`

### Workflows

| Workflow | File | Trigger | Purpose |
|----------|------|---------|---------|
| CI | `{ci_workflow_file}` | Push, PR | Run tests and linting |
| Deploy | `{deploy_workflow_file}` | Release | Deploy to production |
| Preview | `{preview_workflow_file}` | PR | Deploy preview environment |

### CI Pipeline

**File**: `{ci_workflow_file}`

```yaml
{ci_workflow_summary}
```

**Steps**:
1. Checkout code
2. Setup runtime ({runtime})
3. Install dependencies
4. Run linting
5. Run tests
6. Build
7. Upload artifacts

### Deploy Pipeline

**File**: `{deploy_workflow_file}`

**Steps**:
1. Checkout code
2. Build application
3. Run security scan
4. Deploy to {environment}
5. Run smoke tests
6. Notify team

### Environment Deployments

| Environment | Trigger | Approval |
|-------------|---------|----------|
| staging | Merge to main | Automatic |
| production | Release tag | Manual |

### Secrets & Variables

| Name | Scope | Description |
|------|-------|-------------|
| `{secret_1}` | Repository | {description} |
| `{secret_2}` | Environment | {description} |

### Running Locally

```bash
# Simulate CI locally
{local_ci_cmd}

# Test workflow syntax
{validate_workflow_cmd}
```
