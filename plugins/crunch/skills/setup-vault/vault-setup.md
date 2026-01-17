# HashiCorp Vault Setup Guide

Step-by-step instructions for installing and configuring HashiCorp Vault.

## Overview

HashiCorp Vault is a secrets management tool that provides:

- Secure secret storage (encrypted at rest)
- Dynamic secrets (database credentials, cloud IAM, etc.)
- Encryption as a service
- Identity-based access

## Installation

### macOS (Homebrew)

```bash
# Add HashiCorp tap
brew tap hashicorp/tap

# Install Vault
brew install hashicorp/tap/vault

# Verify installation
vault version
```

### Ubuntu/Debian

```bash
# Add HashiCorp GPG key
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install
sudo apt update && sudo apt install vault

# Verify
vault version
```

### CentOS/RHEL

```bash
# Add repository
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

# Install
sudo yum -y install vault

# Verify
vault version
```

### Binary Installation (Any OS)

1. Go to https://releases.hashicorp.com/vault/
2. Download the appropriate package for your OS/architecture
3. Extract the binary:
   ```bash
   unzip vault_*_*.zip
   ```
4. Move to PATH:
   ```bash
   sudo mv vault /usr/local/bin/
   ```
5. Verify:
   ```bash
   vault version
   ```

### Docker

```bash
# Run Vault in dev mode
docker run --cap-add=IPC_LOCK -d \
  --name=vault \
  -p 8200:8200 \
  hashicorp/vault server -dev

# Get root token from logs
docker logs vault 2>&1 | grep "Root Token"
```

## Dev Server Mode

For local development and testing:

```bash
# Start dev server (foreground)
vault server -dev

# Or with specific root token
vault server -dev -dev-root-token-id="dev-token"

# Or listening on all interfaces
vault server -dev -dev-listen-address="0.0.0.0:8200"
```

**Dev server characteristics:**

- Runs in-memory (data lost on restart)
- Automatically initialized and unsealed
- Root token provided in output
- TLS disabled
- Single node (no HA)

**Output example:**

```
==> Vault server configuration:

             Api Address: http://127.0.0.1:8200
                     Cgo: disabled
         Cluster Address: https://127.0.0.1:8201
   Environment Variables: ...
              Go Version: go1.21.0
              Listener 1: tcp (addr: "127.0.0.1:8200", ...)
               Log Level: info
                   Mlock: supported: false, enabled: false
           Recovery Mode: false
                 Storage: inmem
                 Version: Vault v1.15.0

==> Vault server started! Log data will stream in below:

WARNING! dev mode is enabled!...

Root Token: hvs.xxxxxxxxxxxxxxxxxxxxxx

Development mode should NOT be used in production...
```

## Authentication Methods

### Token Authentication (Simplest)

```bash
# Set token directly
export VAULT_TOKEN='hvs.xxxxxxxxxxxxxxxxxxxxxx'

# Or login with token
vault login hvs.xxxxxxxxxxxxxxxxxxxxxx

# Token is saved to ~/.vault-token
```

### AppRole Authentication (For Applications)

1. **Enable AppRole auth method:**

   ```bash
   vault auth enable approle
   ```

2. **Create a policy:**

   ```bash
   vault policy write my-app - <<EOF
   path "secret/data/my-app/*" {
     capabilities = ["read", "list"]
   }
   EOF
   ```

3. **Create an AppRole:**

   ```bash
   vault write auth/approle/role/my-app \
     token_policies="my-app" \
     token_ttl=1h \
     token_max_ttl=4h
   ```

4. **Get Role ID:**

   ```bash
   vault read auth/approle/role/my-app/role-id
   ```

5. **Generate Secret ID:**

   ```bash
   vault write -f auth/approle/role/my-app/secret-id
   ```

6. **Login with AppRole:**
   ```bash
   vault write auth/approle/login \
     role_id="<role-id>" \
     secret_id="<secret-id>"
   ```

### LDAP Authentication

```bash
# Enable LDAP
vault auth enable ldap

# Configure LDAP
vault write auth/ldap/config \
  url="ldap://ldap.example.com" \
  userdn="ou=users,dc=example,dc=com" \
  groupdn="ou=groups,dc=example,dc=com" \
  binddn="cn=admin,dc=example,dc=com" \
  bindpass="admin-password"

# Login
vault login -method=ldap username=myuser
```

### GitHub Authentication

```bash
# Enable GitHub auth
vault auth enable github

# Configure (requires org membership)
vault write auth/github/config organization=my-org

# Login with personal access token
vault login -method=github token=ghp_xxxxxxxxxxxx
```

### Kubernetes Authentication

```bash
# Enable Kubernetes auth
vault auth enable kubernetes

# Configure (from within cluster)
vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc"

# Login (in pod)
vault write auth/kubernetes/login \
  role="my-app" \
  jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
```

## Secrets Engines

### KV (Key-Value) Secrets Engine

**KV Version 2 (default, with versioning):**

```bash
# Enable KV v2
vault secrets enable -path=secret kv-v2

# Write secret
vault kv put secret/myapp/config \
  username="admin" \
  password="s3cr3t"

# Read secret
vault kv get secret/myapp/config

# Read specific field
vault kv get -field=password secret/myapp/config

# List secrets
vault kv list secret/myapp/

# Delete secret
vault kv delete secret/myapp/config

# View versions
vault kv metadata get secret/myapp/config
```

**KV Version 1 (no versioning):**

```bash
# Enable KV v1
vault secrets enable -path=kv -version=1 kv

# Write (same commands, different behavior)
vault kv put kv/myapp/config key=value
```

### Dynamic Database Credentials

```bash
# Enable database secrets engine
vault secrets enable database

# Configure PostgreSQL connection
vault write database/config/my-postgresql-database \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@localhost:5432/mydb" \
  allowed_roles="my-role" \
  username="vault-admin" \
  password="vault-admin-password"

# Create role
vault write database/roles/my-role \
  db_name=my-postgresql-database \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';" \
  default_ttl="1h" \
  max_ttl="24h"

# Get dynamic credentials
vault read database/creds/my-role
```

## Environment Variables

| Variable            | Purpose               | Example                  |
| ------------------- | --------------------- | ------------------------ |
| `VAULT_ADDR`        | Vault server address  | `http://127.0.0.1:8200`  |
| `VAULT_TOKEN`       | Authentication token  | `hvs.xxxx`               |
| `VAULT_CACERT`      | CA certificate path   | `/etc/vault/ca.crt`      |
| `VAULT_SKIP_VERIFY` | Skip TLS verification | `true` (not recommended) |
| `VAULT_NAMESPACE`   | Enterprise namespace  | `admin/team1`            |
| `VAULT_FORMAT`      | Output format         | `json`, `table`, `yaml`  |

## Common CLI Commands

```bash
# Status and health
vault status
vault operator members

# Authentication
vault login <token>
vault token lookup
vault token renew

# Secrets (KV v2)
vault kv put secret/path key=value
vault kv get secret/path
vault kv get -format=json secret/path
vault kv list secret/
vault kv delete secret/path

# Policy management
vault policy list
vault policy read <policy>
vault policy write <policy> <file>

# Audit
vault audit enable file file_path=/var/log/vault/audit.log
vault audit list
```

## Security Best Practices

1. **Never use dev mode in production**
2. **Use short-lived tokens** - Set appropriate TTLs
3. **Implement least privilege** - Narrow policies
4. **Enable audit logging** - Track all access
5. **Use identity-based auth** - AppRole, OIDC, Kubernetes
6. **Rotate secrets** - Use dynamic secrets where possible
7. **Encrypt in transit** - Always use TLS in production
8. **Seal when not in use** - For sensitive environments

## Troubleshooting

### "connection refused"

- Check Vault is running: `ps aux | grep vault`
- Check address: `echo $VAULT_ADDR`
- Check firewall/network

### "permission denied"

- Check token: `vault token lookup`
- Check policies: `vault token capabilities <path>`
- Token may have expired

### "x509: certificate signed by unknown authority"

- Set CA cert: `export VAULT_CACERT=/path/to/ca.crt`
- Or skip verify: `export VAULT_SKIP_VERIFY=true` (dev only!)

### "missing client token"

- Login first: `vault login`
- Or set token: `export VAULT_TOKEN=<token>`

## Quick Reference

| Item           | Format        | Example              |
| -------------- | ------------- | -------------------- |
| Root Token     | `hvs.` prefix | `hvs.xxxxxxxxxxxxxx` |
| Service Token  | `s.` prefix   | `s.xxxxxxxxxxxxxx`   |
| Batch Token    | `b.` prefix   | `b.xxxxxxxxxxxxxx`   |
| Recovery Token | `r.` prefix   | `r.xxxxxxxxxxxxxx`   |
| Unseal Key     | Base64        | `8a1b2c3d...`        |

## Resources

- **Documentation**: https://developer.hashicorp.com/vault/docs
- **API Reference**: https://developer.hashicorp.com/vault/api-docs
- **Learn Tutorials**: https://developer.hashicorp.com/vault/tutorials
- **GitHub**: https://github.com/hashicorp/vault
