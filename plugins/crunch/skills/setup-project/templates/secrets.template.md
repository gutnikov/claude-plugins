## Secrets

**Backend**: {secrets_backend}
**Integration**: {integration_type}

### Configuration

| Setting | Value |
|---------|-------|
| Config file | `{config_file}` |
| Key location | `{key_location}` |
| Secrets path | `{secrets_path}` |

### Available Operations

| Operation | Command/Tool | Description |
|-----------|--------------|-------------|
| Get secret | `{get_cmd}` | Retrieve a secret value |
| Set secret | `{set_cmd}` | Store a new secret |
| List secrets | `{list_cmd}` | List all secret keys |
| Delete secret | `{delete_cmd}` | Remove a secret |

### Usage Examples

```bash
# Get a secret
{get_example}

# Set a secret
{set_example}

# List all secrets
{list_example}
```

### Security Notes

- Never commit unencrypted secrets
- Rotate secrets regularly
- Use least-privilege access
- Audit secret access periodically
