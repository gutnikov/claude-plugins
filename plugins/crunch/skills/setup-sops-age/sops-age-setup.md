# SOPS with age Encryption Setup Guide

Step-by-step instructions for setting up SOPS with age encryption for secrets management.

## Overview

### What is SOPS?

SOPS (Secrets OPerationS) is a tool that encrypts values in structured data files while keeping keys visible. This allows:

- Version control of encrypted secrets
- Code review of secret changes (you see which keys changed)
- Easy diffing of encrypted files

### What is age?

age (actually pronounced "aghe") is a simple, modern file encryption tool:

- No configuration or options (simple by design)
- Secure defaults (X25519, ChaCha20-Poly1305)
- Small keys (easy to share, backup)
- Replaces PGP/GPG complexity

### Why SOPS + age?

| Feature         | SOPS + age             | Vault           | Raw encryption |
| --------------- | ---------------------- | --------------- | -------------- |
| Complexity      | Low                    | High            | Medium         |
| Infrastructure  | None                   | Server required | None           |
| Version control | Yes (encrypted)        | No (external)   | Yes (opaque)   |
| Key management  | File-based             | Centralized     | Manual         |
| Team sharing    | Easy (multi-recipient) | Policy-based    | Complex        |

## Installation

### Install age

**macOS:**

```bash
brew install age
```

**Ubuntu/Debian:**

```bash
sudo apt install age
```

**Arch Linux:**

```bash
sudo pacman -S age
```

**Go:**

```bash
go install filippo.io/age/cmd/...@latest
```

**Binary:**
Download from https://github.com/FiloSottile/age/releases

### Install SOPS

**macOS:**

```bash
brew install sops
```

**Ubuntu/Debian:**

```bash
# Check latest version at https://github.com/getsops/sops/releases
SOPS_VERSION=3.8.1
curl -LO "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.amd64"
sudo mv "sops-v${SOPS_VERSION}.linux.amd64" /usr/local/bin/sops
sudo chmod +x /usr/local/bin/sops
```

**Go:**

```bash
go install github.com/getsops/sops/v3/cmd/sops@latest
```

### Verify Installation

```bash
age --version
# age v1.1.1

sops --version
# sops 3.8.1
```

## Key Management

### Generate New Key

```bash
# Create directory for keys
mkdir -p ~/.config/sops/age

# Generate key pair
age-keygen -o ~/.config/sops/age/keys.txt

# Output shows public key:
# Public key: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
```

### Key File Format

The key file (`keys.txt`) contains:

```
# created: 2024-01-15T10:30:00Z
# public key: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
AGE-SECRET-KEY-1QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ
```

### Get Public Key from Private Key

```bash
age-keygen -y ~/.config/sops/age/keys.txt
# age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p
```

### Configure Shell Environment (REQUIRED)

After generating your key, you **must** configure your shell so SOPS can find it:

```bash
# Add to ~/.zshrc or ~/.bashrc
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
```

Then reload your shell:

```bash
source ~/.zshrc  # or source ~/.bashrc
```

**Verify configuration:**

```bash
echo $SOPS_AGE_KEY_FILE
# Should output: /Users/<you>/.config/sops/age/keys.txt
```

> **Important:** Without this environment variable, SOPS will fail with "no identity matched any of the recipients" when trying to decrypt files.

### Multiple Keys

You can have multiple keys in the key file:

```
# Key 1 - Personal
# public key: age1xxxxx...
AGE-SECRET-KEY-1XXXXX...

# Key 2 - Team shared
# public key: age1yyyyy...
AGE-SECRET-KEY-1YYYYY...
```

SOPS will try all keys when decrypting.

## SOPS Configuration

### .sops.yaml File

Create `.sops.yaml` in your project root:

```yaml
creation_rules:
  # Rule 1: Encrypt all YAML files in secrets/
  - path_regex: secrets/.*\.yaml$
    age: age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p

  # Rule 2: Different key for production
  - path_regex: secrets/prod/.*\.yaml$
    age: age1prodkey...

  # Rule 3: Multiple recipients (team)
  - path_regex: secrets/team/.*\.yaml$
    age: >-
      age1alice...,
      age1bob...,
      age1charlie...
```

### Path Regex Patterns

| Pattern            | Matches                 |
| ------------------ | ----------------------- |
| `.*\.yaml$`        | All YAML files          |
| `secrets/.*`       | Anything in secrets/    |
| `\.env\..*`        | .env.prod, .env.staging |
| `config/.*\.json$` | JSON files in config/   |

### Encrypted Suffix Pattern

Only encrypt files with specific suffix:

```yaml
creation_rules:
  - path_regex: \.enc\.yaml$
    age: age1xxxxx...
```

Then use `secrets.enc.yaml` for encrypted files.

## Basic Operations

### Encrypt a File

```bash
# With .sops.yaml configured (recommended)
sops --encrypt secrets.yaml > secrets.enc.yaml

# Or encrypt in place
sops --encrypt --in-place secrets.yaml

# Without .sops.yaml (specify key)
sops --encrypt --age age1xxxxx... secrets.yaml > secrets.enc.yaml
```

### Decrypt a File

```bash
# To stdout
sops --decrypt secrets.enc.yaml

# To file
sops --decrypt secrets.enc.yaml > secrets.yaml

# In place
sops --decrypt --in-place secrets.enc.yaml
```

### Edit Encrypted File

Opens decrypted content in `$EDITOR`, re-encrypts on save:

```bash
sops secrets.enc.yaml
```

### Extract Specific Value

```bash
# Get single value
sops --decrypt --extract '["database"]["password"]' secrets.yaml

# JSON path for JSON files
sops --decrypt --extract '["api"]["key"]' config.json
```

## File Formats

### YAML (Recommended)

**Before encryption:**

```yaml
database:
  host: localhost
  password: supersecret
api_key: abc123
```

**After encryption:**

```yaml
database:
  host: localhost
  password: ENC[AES256_GCM,data:abc123...,iv:...,tag:...,type:str]
api_key: ENC[AES256_GCM,data:xyz789...,iv:...,tag:...,type:str]
sops:
  age:
    - recipient: age1xxxxx...
      enc: |
        -----BEGIN AGE ENCRYPTED FILE-----
        ...
        -----END AGE ENCRYPTED FILE-----
  lastmodified: "2024-01-15T10:30:00Z"
  mac: ENC[AES256_GCM,data:...,iv:...,tag:...,type:str]
  version: 3.8.1
```

### JSON

```json
{
  "database": {
    "password": "ENC[AES256_GCM,data:...,type:str]"
  },
  "sops": {
    "age": [{ "recipient": "age1...", "enc": "..." }],
    "mac": "..."
  }
}
```

### ENV Files

```bash
# .env.enc
DATABASE_PASSWORD=ENC[AES256_GCM,data:...,type:str]
API_KEY=ENC[AES256_GCM,data:...,type:str]
sops_age__list_0__recipient=age1...
sops_age__list_0__enc=...
```

### Binary Files

```bash
# Encrypt binary
sops --encrypt binary.dat > binary.dat.enc

# Entire file is encrypted (opaque)
```

## Advanced Configuration

### Encrypted Regex (Selective Encryption)

Only encrypt specific keys:

```yaml
creation_rules:
  - path_regex: .*\.yaml$
    age: age1xxxxx...
    encrypted_regex: "^(password|secret|key|token)$"
```

### Unencrypted Regex

Encrypt everything EXCEPT matching keys:

```yaml
creation_rules:
  - path_regex: .*\.yaml$
    age: age1xxxxx...
    unencrypted_regex: "^(host|port|enabled)$"
```

### Key Groups (Require Multiple Keys)

Require keys from multiple groups to decrypt:

```yaml
creation_rules:
  - path_regex: .*\.yaml$
    key_groups:
      - age:
          - age1admin1...
          - age1admin2...
      - age:
          - age1security1...
    shamir_threshold: 2 # Need 2 of the groups
```

## Team Workflows

### Adding a Team Member

1. Get their public key:

   ```bash
   # They run:
   age-keygen -y ~/.config/sops/age/keys.txt
   ```

2. Add to `.sops.yaml`:

   ```yaml
   creation_rules:
     - path_regex: secrets/.*
       age: >-
         age1existing...,
         age1newmember...
   ```

3. Re-encrypt existing files:
   ```bash
   # Update all encrypted files with new key
   sops updatekeys secrets/config.yaml
   ```

### Rotating Keys

1. Generate new key
2. Add new public key to `.sops.yaml`
3. Re-encrypt all files:
   ```bash
   find secrets -name "*.yaml" -exec sops updatekeys {} \;
   ```
4. Remove old key from `.sops.yaml`
5. Re-encrypt again (removes old key access)

### CI/CD Integration

**GitHub Actions:**

```yaml
jobs:
  deploy:
    steps:
      - name: Setup SOPS
        run: |
          # Install SOPS
          curl -LO https://github.com/getsops/sops/releases/download/v3.8.1/sops-v3.8.1.linux.amd64
          chmod +x sops-v3.8.1.linux.amd64
          sudo mv sops-v3.8.1.linux.amd64 /usr/local/bin/sops

      - name: Decrypt secrets
        env:
          SOPS_AGE_KEY: ${{ secrets.SOPS_AGE_KEY }}
        run: |
          sops --decrypt secrets.enc.yaml > secrets.yaml
```

**GitLab CI:**

```yaml
deploy:
  script:
    - export SOPS_AGE_KEY="$SOPS_AGE_KEY"
    - sops --decrypt secrets.enc.yaml > secrets.yaml
```

## Environment Variables

| Variable            | Purpose                   | Example                       |
| ------------------- | ------------------------- | ----------------------------- |
| `SOPS_AGE_KEY_FILE` | Path to key file          | `~/.config/sops/age/keys.txt` |
| `SOPS_AGE_KEY`      | Key directly (CI/CD)      | `AGE-SECRET-KEY-1...`         |
| `EDITOR`            | Editor for `sops` command | `vim`, `code --wait`          |

## Troubleshooting

### "no identity matched any of the recipients"

This is the most common error. It means SOPS cannot find your age private key.

```bash
# 1. Check if environment variable is set
echo $SOPS_AGE_KEY_FILE
# If empty, that's the problem!

# 2. Set it for this session
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt

# 3. Make it permanent - add to ~/.zshrc or ~/.bashrc:
echo 'export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt' >> ~/.zshrc
source ~/.zshrc

# 4. Verify key file exists
ls -la ~/.config/sops/age/keys.txt
```

### "no key found"

```bash
# Check key file exists
ls -la ~/.config/sops/age/keys.txt

# Check environment variable
echo $SOPS_AGE_KEY_FILE

# Verify key matches recipient
age-keygen -y ~/.config/sops/age/keys.txt
# Compare with recipient in encrypted file
```

### "could not find common encryption keys"

```bash
# Check .sops.yaml path regex
cat .sops.yaml

# Test with explicit key
sops --decrypt --age age1xxxxx... file.yaml
```

### "MAC mismatch"

- File was modified after encryption
- Re-encrypt from known good source:
  ```bash
  sops --decrypt backup.yaml | sops --encrypt /dev/stdin > file.yaml
  ```

### Permission Denied on Key File

```bash
chmod 600 ~/.config/sops/age/keys.txt
```

## Security Best Practices

1. **Backup private keys** - Store securely (password manager, secure storage)
2. **Never commit private keys** - Add to `.gitignore`
3. **Use separate keys for environments** - dev, staging, prod
4. **Rotate keys periodically** - Especially after team changes
5. **Audit recipients** - Review `.sops.yaml` regularly
6. **Use key groups for sensitive data** - Require multiple parties

## Quick Reference

| Command                              | Description                  |
| ------------------------------------ | ---------------------------- |
| `age-keygen -o key.txt`              | Generate new key pair        |
| `age-keygen -y key.txt`              | Get public key from private  |
| `sops -e file.yaml`                  | Encrypt file                 |
| `sops -d file.yaml`                  | Decrypt file                 |
| `sops file.yaml`                     | Edit encrypted file          |
| `sops updatekeys file.yaml`          | Re-encrypt with updated keys |
| `sops --extract '["key"]' file.yaml` | Extract single value         |

## Resources

- **SOPS Documentation**: https://github.com/getsops/sops
- **age Documentation**: https://github.com/FiloSottile/age
- **age Specification**: https://age-encryption.org/
