## Environments

| Environment | Purpose | URL | Config File |
|-------------|---------|-----|-------------|
| development | Local development | http://localhost:{port} | `.env.development` |
| staging | Pre-production testing | https://staging.{domain} | `.env.staging` |
| production | Live application | https://{domain} | `.env.production` |

### Environment-Specific Variables

| Variable | development | staging | production |
|----------|-------------|---------|------------|
| `API_URL` | localhost:{api_port} | api-staging.{domain} | api.{domain} |
| `LOG_LEVEL` | debug | info | warn |
| `ENABLE_DEBUG` | true | true | false |
| `DATABASE_URL` | local DB | staging DB | production DB |

### Switching Environments

```bash
# Option 1: Copy environment file
cp .env.{environment} .env
{dev_cmd}

# Option 2: Use direnv (automatic)
cd environments/{environment}
# .envrc automatically loads

# Option 3: Inline override
{env_var}={value} {dev_cmd}
```

### Deployment Targets

| Environment | Platform | Region | Auto-deploy |
|-------------|----------|--------|-------------|
| staging | {platform} | {region} | On merge to main |
| production | {platform} | {region} | Manual trigger |

### Feature Flags

| Flag | development | staging | production |
|------|-------------|---------|------------|
| `NEW_FEATURE` | true | true | false |
