# HashiCorp Vault Disable Guide

Step-by-step instructions for disabling HashiCorp Vault in a project.

## Overview

This guide covers disabling Vault configuration and optionally removing the Vault binary. Choose a disable tier based on how thoroughly you want to remove Vault.

## Disable Tiers

| Tier | Name | What It Removes | Use When |
|------|------|-----------------|----------|
| 1 | Config Only | CLAUDE.md section, .env entries | Switching to different secrets backend |
| 2 | Full Project | Above + progress files | Clean project removal |
| 3 | Complete | Above + binary, token file, dev server | Full system cleanup |

## Pre-Disable Checklist

Before disabling, consider:

- [ ] Export any secrets you still need
- [ ] Document which secrets exist (for recreation elsewhere)
- [ ] Notify team members if shared configuration
- [ ] Backup `.env` file if needed

## Tier 1: Config Only (Light)

Remove project-level Vault configuration while keeping Vault available for other projects.

### Step 1: Remove from CLAUDE.md

Find and remove the Vault section:

```markdown
## Secrets Management

### HashiCorp Vault

- **Status**: Configured
- **Setup mode**: Local Dev Server
...
```

Remove everything from `### HashiCorp Vault` until the next `###` or `##` header.

### Step 2: Remove from .env

```bash
# View current Vault entries
grep "^VAULT_" .env

# Remove Vault entries
grep -v "^VAULT_" .env > .env.tmp && mv .env.tmp .env

# Verify removal
grep "^VAULT_" .env
# Should return nothing
```

### Step 3: Unset Environment Variables

For the current session:

```bash
unset VAULT_ADDR
unset VAULT_TOKEN
unset VAULT_CACERT
unset VAULT_SKIP_VERIFY
```

## Tier 2: Full Project (Medium)

Everything from Tier 1, plus remove setup progress files.

### Additional Step: Remove Progress Files

```bash
# Remove setup progress file (if exists)
rm -f vault-setup-progress.md

# Remove disable progress file (if exists)
rm -f vault-disable-progress.md
```

## Tier 3: Complete (Heavy)

Everything from Tiers 1-2, plus system-level cleanup. Confirm each step before proceeding.

### Additional Step 1: Stop Dev Server

Check if a Vault dev server is running:

```bash
# Find running Vault processes
pgrep -f "vault server"

# Or check for the specific dev server
ps aux | grep "vault server -dev"
```

Stop the dev server:

```bash
# Graceful stop
pkill -f "vault server -dev"

# Or find PID and kill
kill <PID>
```

### Additional Step 2: Remove Token File

```bash
# Check if token file exists
ls -la ~/.vault-token

# Remove it
rm ~/.vault-token

# Verify removal
ls ~/.vault-token 2>/dev/null || echo "Token file removed"
```

### Additional Step 3: Uninstall Vault Binary

**macOS (Homebrew):**

```bash
# Uninstall Vault
brew uninstall hashicorp/tap/vault

# Optionally remove the tap
brew untap hashicorp/tap

# Verify removal
which vault
# Should return nothing or "vault not found"
```

**Ubuntu/Debian:**

```bash
# Uninstall Vault
sudo apt remove vault

# Remove repository (optional)
sudo rm /etc/apt/sources.list.d/hashicorp.list
sudo rm /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Verify removal
which vault
```

**CentOS/RHEL:**

```bash
# Uninstall Vault
sudo yum remove vault

# Verify removal
which vault
```

**Binary Installation:**

```bash
# Find the binary
which vault

# Remove it (usually /usr/local/bin/vault)
sudo rm /usr/local/bin/vault

# Verify removal
which vault
```

## Verification

After disabling, verify the removal was successful:

### Tier 1 Verification

```bash
# Check CLAUDE.md
grep -i "vault" CLAUDE.md
# Should return nothing Vault-related

# Check .env
grep "^VAULT_" .env
# Should return nothing

# Check environment
echo $VAULT_ADDR
# Should be empty
```

### Tier 2 Verification

```bash
# All Tier 1 checks, plus:

# Check progress files
ls vault-*-progress.md 2>/dev/null
# Should return nothing
```

### Tier 3 Verification

```bash
# All Tier 1-2 checks, plus:

# Check token file
ls ~/.vault-token 2>/dev/null
# Should return nothing

# Check binary
vault version 2>/dev/null
# Should fail

# Check for running processes
pgrep -f "vault server"
# Should return nothing
```

## Rollback

If you need to restore Vault after disabling:

### Re-enable Configuration

1. Re-run the Vault setup skill: `/vault` → "setup"
2. Or manually restore from backup:

```bash
# Restore .env entries
echo "VAULT_ADDR=http://127.0.0.1:8200" >> .env
echo "VAULT_TOKEN=<your-token>" >> .env

# Source the environment
source .env
```

### Reinstall Binary

Follow the installation instructions in `vault-setup.md`.

## Common Issues

### "vault: command not found" after partial disable

The binary was removed but environment still references it:

```bash
# Remove Vault from PATH references in shell config
grep -l "vault" ~/.bashrc ~/.zshrc ~/.bash_profile 2>/dev/null
# Edit those files to remove Vault-related lines
```

### Environment variables persist after .env cleanup

Shell session still has old values:

```bash
# Unset in current session
unset VAULT_ADDR VAULT_TOKEN VAULT_CACERT

# Or start a new shell session
exec $SHELL
```

### Dev server keeps restarting

Check for process managers or startup scripts:

```bash
# Check launchd (macOS)
launchctl list | grep vault

# Check systemd (Linux)
systemctl status vault

# Check cron
crontab -l | grep vault
```

### Cannot remove ~/.vault-token (permission denied)

```bash
# Check permissions
ls -la ~/.vault-token

# Force remove
sudo rm ~/.vault-token
```

## Quick Reference

| What to Remove | Command |
|----------------|---------|
| .env entries | `grep -v "^VAULT_" .env > .env.tmp && mv .env.tmp .env` |
| Environment vars | `unset VAULT_ADDR VAULT_TOKEN` |
| Token file | `rm ~/.vault-token` |
| Dev server | `pkill -f "vault server -dev"` |
| Binary (brew) | `brew uninstall hashicorp/tap/vault` |
| Binary (apt) | `sudo apt remove vault` |
| Binary (manual) | `sudo rm /usr/local/bin/vault` |
| Progress files | `rm -f vault-*-progress.md` |
