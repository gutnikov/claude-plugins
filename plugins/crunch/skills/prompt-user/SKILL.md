---
name: prompt-user
description: Natural conversation skill that collects structured data from free-form user input, then fills gaps with targeted questions.
---

# Prompt User

A utility skill that collects structured data through natural conversation:
1. Ask an open question with hints about what info is needed
2. User writes free-form text
3. Parse text into schema fields
4. Ask targeted follow-up questions only for missing required fields

## Usage

Other skills invoke this skill by providing:
1. A schema definition with field types and descriptions
2. An open question to start the conversation
3. Optional context about why the data is being collected

## Flow Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  Step 1: Ask Open Question                                       │
│  "Tell me about your project's tech stack..."                    │
│  Hints: languages, frameworks, package manager                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Step 2: User Free-Form Response                                 │
│  "We use TypeScript with React for frontend and Python with      │
│   FastAPI for backend. npm for packages."                        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Step 3: Parse into Schema                                       │
│  languages: [TypeScript, Python] ✓                               │
│  frameworks: [React, FastAPI] ✓                                  │
│  package_manager: npm ✓                                          │
│  primary_language: ? (missing)                                   │
│  test_framework: ? (missing)                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Step 4: Ask Only for Gaps                                       │
│  "Which is the primary language - TypeScript or Python?"         │
│  "What testing framework do you use?"                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Step 5: Confirm & Return                                        │
│  Show parsed result, get confirmation                            │
└─────────────────────────────────────────────────────────────────┘
```

## Input Schema Format

```yaml
open_question: "Tell me about {topic}. Include details like {hint1}, {hint2}, {hint3}."

schema:
  field_name:
    type: string | number | boolean | array | enum | object
    required: true | false
    default: <value>
    options: [...]          # for enum type
    description: "What this field represents"
    example: "Example value"
    parse_hints:            # Keywords/patterns to look for in free text
      - "typescript"
      - "ts"
      - "node"

context: "Brief explanation shown to user"
```

## Definition of Done

The conversation is complete when:

1. User has provided initial free-form response
2. All required fields have been extracted or collected
3. User has confirmed the parsed result
4. Result is returned as structured data

---

## Workflow

### Step 1: Ask Open Question

Present a single open question that hints at all needed information:

```yaml
open_question: |
  Tell me about your deployment environments.

  For example: what environments do you deploy to (local, staging, production)?
  Do you have SSH access? What are the hostnames?
```

Display the question and wait for free-form text input.

### Step 2: Receive Free-Form Response

User types natural text, for example:

```
We deploy to three environments:
- local for development
- stable at stable.example.com (SSH as deploy user)
- production at prod.example.com (SSH on port 2222)
```

### Step 3: Parse Response into Schema

Use LLM to extract schema fields from the free-form text:

```yaml
# Parsing prompt
Given this schema:
{schema}

Extract field values from this user response:
{user_response}

For each field:
- If clearly mentioned: extract the value
- If implied but ambiguous: mark as "needs_clarification"
- If not mentioned: mark as "missing"
```

**Parsed result:**

```yaml
parsed:
  environments:
    value:
      - { name: "local", type: "local" }
      - { name: "stable", type: "staging" }
      - { name: "production", type: "production" }
    status: extracted

  access_details:
    value:
      - { environment: "stable", ssh_host: "stable.example.com", ssh_user: "deploy" }
      - { environment: "production", ssh_host: "prod.example.com", ssh_port: 2222 }
    status: extracted
    gaps:
      - "stable: ssh_port not specified (default 22?)"
      - "production: ssh_user not specified"

  verify_access:
    status: missing
```

### Step 4: Fill Gaps with Targeted Questions

Only ask about missing or ambiguous fields:

#### For Missing Required Fields

```typescript
AskUserQuestion({
  questions: [{
    question: "Would you like to verify SSH connectivity after setup?",
    header: "Verify",
    options: [
      { label: "Yes", description: "Test SSH connections" },
      { label: "No", description: "Skip verification" }
    ],
    multiSelect: false
  }]
})
```

#### For Ambiguous Values

```typescript
AskUserQuestion({
  questions: [{
    question: "For production SSH - what username should be used?",
    header: "SSH User",
    options: [
      { label: "deploy", description: "Same as stable" },
      { label: "root", description: "Root user" },
      { label: "Other", description: "Specify different user" }
    ],
    multiSelect: false
  }]
})
```

#### For Confirmation of Defaults

```typescript
AskUserQuestion({
  questions: [{
    question: "For stable environment, SSH port wasn't specified. Use default?",
    header: "SSH Port",
    options: [
      { label: "Yes, use 22", description: "Standard SSH port" },
      { label: "Specify different", description: "Enter port number" }
    ],
    multiSelect: false
  }]
})
```

### Step 5: Confirm and Return

Show the complete parsed result:

```
Parsed Configuration
====================

Environments:
  ✓ local (local)
  ✓ stable (staging) - stable.example.com
  ✓ production (production) - prod.example.com

SSH Access:
  ✓ stable: deploy@stable.example.com:22
  ✓ production: deploy@prod.example.com:2222

Verify access: Yes
```

```typescript
AskUserQuestion({
  questions: [{
    question: "Does this look correct?",
    header: "Confirm",
    options: [
      { label: "Yes, correct", description: "Proceed with these values" },
      { label: "Make changes", description: "Edit some values" }
    ],
    multiSelect: false
  }]
})
```

### Step 6: Return Result

```yaml
result:
  status: complete
  data:
    environments:
      - { name: "local", type: "local" }
      - { name: "stable", type: "staging" }
      - { name: "production", type: "production" }
    access_details:
      - { environment: "stable", ssh_host: "stable.example.com", ssh_user: "deploy", ssh_port: 22 }
      - { environment: "production", ssh_host: "prod.example.com", ssh_user: "deploy", ssh_port: 2222 }
    verify_access: true
  source:
    from_text: ["environments", "access_details.ssh_host", "access_details.ssh_port"]
    from_questions: ["verify_access", "access_details.ssh_user"]
    from_defaults: ["access_details.ssh_port (stable)"]
```

---

## Parsing Strategies

### Keyword Matching

```yaml
languages:
  parse_hints:
    - pattern: "typescript|ts"
      value: "TypeScript"
    - pattern: "python|py"
      value: "Python"
    - pattern: "javascript|js"
      value: "JavaScript"
```

### Pattern Extraction

```yaml
ssh_host:
  parse_hints:
    - pattern: "(?:at|@|host[: ]+)([a-zA-Z0-9.-]+)"
      group: 1
    - pattern: "([a-zA-Z0-9-]+\\.example\\.com)"
      group: 1

ssh_port:
  parse_hints:
    - pattern: "port[: ]+([0-9]+)"
      group: 1
    - pattern: ":([0-9]+)(?:\\s|$)"
      group: 1
```

### Context-Aware Extraction

```yaml
# When user says "stable at host.com as deploy"
# LLM understands:
#   - "stable" is environment name
#   - "host.com" is ssh_host
#   - "deploy" is ssh_user (due to "as" keyword)
```

---

## Example Invocation

```yaml
invoke: prompt-user

open_question: |
  Tell me about your project's tech stack.

  What languages do you use? Any frameworks?
  What package manager? Testing tools?

schema:
  languages:
    type: array
    required: true
    items:
      type: string
    description: "Programming languages"
    parse_hints:
      - { pattern: "typescript|ts", value: "TypeScript" }
      - { pattern: "javascript|js", value: "JavaScript" }
      - { pattern: "python|py", value: "Python" }
      - { pattern: "go|golang", value: "Go" }
      - { pattern: "rust", value: "Rust" }

  frameworks:
    type: array
    required: false
    items:
      type: string
    description: "Frameworks and libraries"

  package_manager:
    type: enum
    required: true
    options: ["npm", "yarn", "pnpm", "bun", "pip", "poetry", "cargo"]
    description: "Package manager"

  test_framework:
    type: enum
    required: false
    options: ["jest", "vitest", "pytest", "go test", "none"]
    description: "Testing framework"

context: "Setting up tech stack documentation"
```

---

## Conversation Example

**Claude:** Tell me about your project's tech stack.

What languages do you use? Any frameworks? What package manager? Testing tools?

**User:** It's a TypeScript project with React frontend and Express backend. We use npm and jest for testing.

**Claude:** Got it! I parsed:
- Languages: TypeScript
- Frameworks: React, Express
- Package manager: npm
- Test framework: jest

Just one question - is TypeScript your only language, or do you use anything else (Python, Go, etc.)?

**User:** Just TypeScript

**Claude:**
```
Tech Stack
==========
Languages: [TypeScript]
Frameworks: [React, Express]
Package Manager: npm
Test Framework: jest
```

Does this look correct?

**User:** Yes

**Claude:** *(returns structured result)*

---

## Error Handling

| Situation | Response |
|-----------|----------|
| User response is too vague | Ask clarifying open question |
| Can't parse any fields | Fall back to field-by-field questions |
| User contradicts earlier input | Show conflict, ask for clarification |
| Required field truly missing | Ask specific targeted question |

---

## Interactive Checkpoints

- [ ] Initial open question
- [ ] Parse user response
- [ ] For each gap: targeted question
- [ ] Final confirmation
