---
name: setup-sops-age
description: Interactive setup wizard for SOPS with age encryption. Guides user through installing tools, generating keys, configuring SOPS, and verifying by encrypting/decrypting a test secrets file.
---

# Setup SOPS with age Encryption

This skill guides users through the complete end-to-end process of setting up SOPS (Secrets OPerationS) with age encryption for file-based secrets management.

## Definition of Done

The setup is complete when:

1. SOPS and age are installed and configured
2. age key pair is generated (or existing key is configured)
3. User successfully encrypts and decrypts a test secrets file

## What is SOPS + age?

| Tool     | Purpose                                                                 |
| -------- | ----------------------------------------------------------------------- |
| **SOPS** | Encrypts/decrypts specific values in structured files (YAML, JSON, ENV) |
| **age**  | Modern, simple encryption tool (replacement for PGP)                    |

**Benefits:**

- Encrypted files can be committed to git (only values are encrypted, keys visible)
- Simple key management (no PGP complexity)
- Supports multiple recipients (team members)
- Works with YAML, JSON, INI, ENV, and binary files

## Setup Modes

This skill supports two setup modes:

| Mode             | Description                            | Use When                        |
| ---------------- | -------------------------------------- | ------------------------------- |
| **Full Setup**   | Install tools + generate new age key   | Starting fresh                  |
| **Connect Only** | Configure SOPS to use existing age key | Key already exists (team setup) |

## Progress Tracking

Since SOPS setup may require session restarts (e.g., after environment changes), progress is tracked in a file.

### Progress File: `setup-sops-age-progress.md`

Location: Project root (`./setup-sops-age-progress.md`)

**Format:**

```markdown
# SOPS+age Setup Progress

## Status

- **Started**: 2024-01-15 10:30:00
- **Current Phase**: Phase 4A - Configure SOPS
- **Setup Mode**: Full Setup (Path A)

## Completed Steps

- [x] Phase 1: Prerequisites & Mode Selection
- [x] Phase 2A: Install Tools
- [x] Phase 3A: Generate age Key
- [ ] Phase 4A: Configure SOPS ← CURRENT
- [ ] Phase 5: Test Encryption
- [ ] Phase 6: Completion

## Collected Information

- **Setup Mode**: Full Setup (New Key)
- **Public Key**: age1xxxxxxxxx...
- **Key Location**: ~/.config/sops/age/keys.txt
- **Config File**: .sops.yaml

## Notes

- Key generated successfully
- Resume from Phase 5 if session interrupted
```

### Progress Tracking Rules

1. **Create progress file** at the start of Phase 1
2. **Update after each phase** completion
3. **Store collected information** (non-sensitive) for resumption
4. **Delete progress file** only after successful DOD verification
5. **On session start**, check for existing progress file and resume

## Workflow

Follow these steps interactively, confirming each stage with the user before proceeding.

### Phase 0: Check for Existing Progress

**ALWAYS start here.** Before anything else:

1. **Check for progress file**

   ```bash
   cat setup-sops-age-progress.md 2>/dev/null
   ```

2. **If progress file exists:**
   - Parse current phase and collected information
   - Display status to user:

     ```
     Found existing SOPS+age setup in progress!

     Current Phase: Phase 4A - Configure SOPS
     Setup Mode: Full Setup (New Key)
     Public Key: age1xxxxxxxxx...

     Would you like to:
     1. Resume from where you left off
     2. Start over (will delete progress)
     ```

   - If resuming, skip to the indicated phase with collected information
   - If starting over, delete progress file and begin Phase 1

3. **If no progress file:**
   - Proceed to Phase 1

### Phase 1: Prerequisites & Mode Selection

First, determine what kind of setup the user needs:

1. **Check for existing configuration**
   - Check for `~/.config/sops/age/keys.txt` (age key file)
   - Look for `.sops.yaml` in project root
   - Check for `SOPS_AGE_KEY_FILE` or `SOPS_AGE_KEY` environment variables

2. **Ask the user about setup mode**:

   "How would you like to set up SOPS with age?"

   **Option A: Full Setup (New Key)**
   - "I need to install SOPS and age, and generate a new key"
   - Requires: Ability to install software
   - Result: New age key pair, SOPS configured

   **Option B: Use Existing Key**
   - "I already have an age key (or team shared key) to use"
   - Requires: Existing age private key
   - Result: SOPS configured with provided key

   **Option C: Not Sure**
   - Help user determine which option fits their situation
   - Ask: "Has your team already set up age keys for this project?"
   - Ask: "Do you have an age private key file or key string?"

3. **Based on selection, proceed to appropriate phase:**
   - Option A → Continue to Phase 2A (Full Setup)
   - Option B → Skip to Phase 2B (Use Existing Key)

4. **Create progress file**
   Create `setup-sops-age-progress.md` with initial status:

   ```markdown
   # SOPS+age Setup Progress

   ## Status

   - **Started**: [timestamp]
   - **Current Phase**: Phase 2A/2B
   - **Setup Mode**: [Full Setup / Use Existing Key]

   ## Completed Steps

   - [x] Phase 1: Prerequisites & Mode Selection
   - [ ] Phase 2: [Install Tools / Gather Key Information]
   - [ ] Phase 3: [Generate Key / Configure SOPS]
   - [ ] Phase 4: Configure SOPS
   - [ ] Phase 5: Test Encryption
   - [ ] Phase 6: Completion

   ## Collected Information

   - **Setup Mode**: [selected mode]
   ```

---

## Path A: Full Setup (New Key)

### Phase 2A: Install Tools

1. **Check if tools are already installed**

   ```bash
   sops --version
   age --version
   ```

   If both installed, skip to Phase 3A.

2. **Install age**

   **macOS (Homebrew):**

   ```bash
   brew install age
   ```

   **Ubuntu/Debian:**

   ```bash
   sudo apt install age
   ```

   **Go install:**

   ```bash
   go install filippo.io/age/cmd/...@latest
   ```

   **Binary download:**
   - https://github.com/FiloSottile/age/releases

3. **Install SOPS**

   **macOS (Homebrew):**

   ```bash
   brew install sops
   ```

   **Ubuntu/Debian:**

   ```bash
   # Download latest release
   curl -LO https://github.com/getsops/sops/releases/download/v3.8.1/sops-v3.8.1.linux.amd64
   sudo mv sops-v3.8.1.linux.amd64 /usr/local/bin/sops
   sudo chmod +x /usr/local/bin/sops
   ```

   **Go install:**

   ```bash
   go install github.com/getsops/sops/v3/cmd/sops@latest
   ```

4. **Verify installation**
   ```bash
   age --version
   sops --version
   ```

### Phase 3A: Generate age Key

1. **Create key directory**

   ```bash
   mkdir -p ~/.config/sops/age
   ```

2. **Generate new key pair**

   ```bash
   age-keygen -o ~/.config/sops/age/keys.txt
   ```

   This outputs the public key:

   ```
   Public key: age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

3. **Save the public key**
   - Display and ask user to copy the public key
   - This will be used in `.sops.yaml` configuration
   - Can be shared with team members

4. **Set environment variable (optional)**

   ```bash
   export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
   ```

5. **Backup reminder**
   - IMPORTANT: Backup `~/.config/sops/age/keys.txt`
   - If lost, encrypted files cannot be decrypted
   - Store backup securely (password manager, secure storage)

### Phase 4A: Configure SOPS

1. **Ask about project configuration**
   - "Should I create a `.sops.yaml` configuration for this project?"
   - This enables automatic key selection based on file patterns

2. **Create .sops.yaml**

   ```yaml
   creation_rules:
     # Encrypt all files in secrets/ directory
     - path_regex: secrets/.*\.(yaml|yml|json|env)$
       age: >-
         age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

     # Or encrypt specific files
     - path_regex: \.secrets\.yaml$
       age: >-
         age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

3. **Ask about multiple recipients**
   - "Do you want to add additional recipients (team members)?"
   - If yes, collect their public keys
   - Add multiple keys comma-separated:

   ```yaml
   age: >-
     age1xxxxx,age1yyyyy,age1zzzzz
   ```

4. **Verify .gitignore**
   - Ensure `~/.config/sops/age/keys.txt` is NOT committed
   - The `.sops.yaml` file CAN be committed (contains only public keys)
   - Ensure decrypted files are gitignored if using decrypt-to-file workflow

→ Proceed to Phase 5: Test Encryption

---

## Path B: Use Existing Key

### Phase 2B: Gather Key Information

Ask the user for existing key information:

1. **Key source** - Ask: "Where is your age private key?"

   **Option 1: Key file**

   ```bash
   # Default location
   ~/.config/sops/age/keys.txt

   # Or custom location
   /path/to/age-key.txt
   ```

   **Option 2: Environment variable**

   ```bash
   # File path
   export SOPS_AGE_KEY_FILE=/path/to/keys.txt

   # Or key directly (not recommended for production)
   export SOPS_AGE_KEY='AGE-SECRET-KEY-1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
   ```

   **Option 3: Key string (for CI/CD)**
   - User provides the private key string directly
   - Starts with `AGE-SECRET-KEY-1`

2. **Collect key details:**
   - Path to key file OR key string
   - Associated public key (for verification)

3. **Verify key works**
   ```bash
   # Test with age directly
   echo "test" | age -r <public-key> | age -d -i <key-file>
   ```

### Phase 3B: Configure SOPS

1. **Set up key access**

   **Option: Copy to default location**

   ```bash
   mkdir -p ~/.config/sops/age
   cp /path/to/provided/key.txt ~/.config/sops/age/keys.txt
   chmod 600 ~/.config/sops/age/keys.txt
   ```

   **Option: Use environment variable**

   ```bash
   export SOPS_AGE_KEY_FILE=/path/to/key.txt
   ```

2. **Create or update .sops.yaml**
   - If `.sops.yaml` exists, verify configuration
   - If not, create one with the provided public key

3. **Handle team setup**
   - If project already has `.sops.yaml`, verify user's key is listed
   - If not, they may need to be added as a recipient

→ Proceed to Phase 5: Test Encryption

---

## Common Path: Testing & Completion

### Phase 5: Test Encryption

This is the critical verification step (same for both paths):

1. **Inform user about testing**
   "I'll now verify SOPS+age by encrypting and decrypting a test file."

2. **Create test secrets file**

   ```bash
   mkdir -p secrets
   cat > secrets/test.yaml << 'EOF'
   # Test secrets file
   database:
     host: localhost
     port: 5432
     username: testuser
     password: supersecretpassword
   api:
     key: test-api-key-12345
   message: "SOPS+age setup successful!"
   EOF
   ```

3. **Encrypt the file**

   ```bash
   sops --encrypt --in-place secrets/test.yaml
   ```

   Or if `.sops.yaml` not configured:

   ```bash
   sops --encrypt --age age1xxxxx... secrets/test.yaml > secrets/test.enc.yaml
   ```

4. **Verify encryption**
   - Show encrypted file contents
   - Keys (database, api, message) should be visible
   - Values should be encrypted (starting with `ENC[AES256_GCM,data:...`)

5. **Decrypt the file**

   ```bash
   sops --decrypt secrets/test.yaml
   ```

6. **Confirm with user**
   "I encrypted and decrypted the test file successfully. Did you see the original values restored?"

### Phase 6: Completion

Once test is confirmed:

1. **Document in CLAUDE.md**
   - Check if `CLAUDE.md` exists in project root
   - If not, create it with basic project structure
   - Add or update the "Integrations" or "Secrets Management" section:

   ```markdown
   ## Secrets Management

   ### SOPS with age Encryption

   - **Status**: Configured
   - **Setup mode**: [New Key / Existing Key]
   - **Public key**: `age1xxxxxxxxx...` (for adding recipients)
   - **Key location**: `~/.config/sops/age/keys.txt`
   - **Config file**: `.sops.yaml`
   - **Encrypted files pattern**: [e.g., `secrets/*.yaml`]
   - **Usage**:
     - Encrypt: `sops --encrypt --in-place <file>`
     - Decrypt: `sops --decrypt <file>`
     - Edit: `sops <file>` (opens in $EDITOR)
   - **Security**:
     - Private key in `~/.config/sops/age/keys.txt` (NEVER commit)
     - Encrypted files CAN be committed (values encrypted, keys visible)
   - **Team**: Add members by including their public key in `.sops.yaml`
   ```

   - If CLAUDE.md already has secrets section, append SOPS configuration
   - Preserve existing content in the file

2. **Summarize what was configured**
   - age key location
   - Public key (for sharing)
   - `.sops.yaml` configuration
   - Test file location

3. **Provide usage examples**

   ```bash
   # Encrypt a file
   sops --encrypt secrets.yaml > secrets.enc.yaml

   # Encrypt in place
   sops --encrypt --in-place secrets.yaml

   # Decrypt to stdout
   sops --decrypt secrets.yaml

   # Decrypt in place
   sops --decrypt --in-place secrets.yaml

   # Edit encrypted file (opens in $EDITOR)
   sops secrets.yaml

   # Extract specific value
   sops --decrypt --extract '["database"]["password"]' secrets.yaml
   ```

4. **Git workflow**

   ```bash
   # Safe to commit encrypted files
   git add secrets/test.yaml
   git commit -m "Add encrypted secrets"

   # The encrypted file contains:
   # - Visible keys (structure)
   # - Encrypted values
   # - SOPS metadata (recipients, MAC)
   ```

5. **Security reminders**
   - NEVER commit private key (`keys.txt`)
   - Public key can be shared/committed
   - Backup private key securely
   - Add team members by adding their public keys to `.sops.yaml`

6. **Cleanup suggestion**
   - "Would you like to keep the test file for reference, or delete it?"

   ```bash
   rm secrets/test.yaml
   ```

7. **Clean up progress file**
   After successful DOD verification:
   ```bash
   rm setup-sops-age-progress.md
   ```
   Inform user:
   ```
   ✓ SOPS+age setup complete!
   ✓ Progress file cleaned up
   ✓ Configuration documented in CLAUDE.md
   ```

## Error Handling

### Common Issues

**"no key found" or "failed to decrypt":**

- Key file not in expected location
- `SOPS_AGE_KEY_FILE` not set
- Wrong key for this file (encrypted for different recipient)

**"could not find common encryption keys":**

- `.sops.yaml` doesn't match file path
- No creation rule matches the file
- Use `--age` flag explicitly

**"MAC mismatch" error:**

- File was modified after encryption
- File corrupted
- May need to re-encrypt from decrypted source

**"failed to get the data key":**

- None of your keys can decrypt this file
- You need to be added as a recipient
- Ask file owner to re-encrypt with your public key

**"age: no identity matched any recipient":**

- Public key in `.sops.yaml` doesn't match your private key
- Verify public key with: `age-keygen -y ~/.config/sops/age/keys.txt`

**Permission errors:**

- Key file permissions too open
- Fix with: `chmod 600 ~/.config/sops/age/keys.txt`

## Interactive Checkpoints

At each phase, confirm with user before proceeding:

### Mode Selection

- [ ] "Which setup mode: Full Setup (new key) or Use Existing Key?"

### Path A (Full Setup) Checkpoints

- [ ] "SOPS and age installed. Ready to generate key?"
- [ ] "Key generated. Here's your public key - please save it. Ready to configure SOPS?"
- [ ] "Do you want to add additional recipients (team members)?"
- [ ] ".sops.yaml created. Ready to test?"

### Path B (Use Existing Key) Checkpoints

- [ ] "Where is your age private key? (file path or key string)"
- [ ] "Key verified. Ready to configure SOPS?"
- [ ] "Configuration complete. Ready to test?"

### Final Verification (Both Paths)

- [ ] "Test file encrypted and decrypted successfully. Setup complete?"
- [ ] "Would you like to keep or delete the test file?"

**Definition of Done:** Only mark setup as complete when user confirms successful encrypt/decrypt of test file.
