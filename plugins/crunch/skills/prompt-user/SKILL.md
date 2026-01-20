---
name: prompt-user
description: Multi-turn conversation skill that collects structured data from users based on a schema with comments.
---

# Prompt User

A utility skill that takes a schema definition and runs a multi-turn conversation to collect all field values from the user.

## Usage

Other skills invoke this skill by providing:
1. A schema definition with field types and comments
2. Optional context about why the data is being collected

## Input Schema Format

```yaml
schema:
  field_name:
    type: string | number | boolean | array | enum | object
    required: true | false  # default: true
    default: <value>        # optional default value
    options: [...]          # for enum type
    items:                  # for array type
      type: string
    description: "Field description shown to user"
    example: "Example value"
    validate: <pattern>     # optional regex for strings

context: "Brief explanation of what we're collecting and why"
```

## Definition of Done

The conversation is complete when:

1. All required fields have values
2. User has confirmed the collected data
3. Result is returned as structured YAML/JSON

---

## Workflow

### Step 1: Parse Schema

Read the provided schema and identify:
- Required fields (must be collected)
- Optional fields (can be skipped)
- Field types and constraints
- Default values

```yaml
# Example input schema
schema:
  project_name:
    type: string
    required: true
    description: "Name of your project"
    example: "my-awesome-app"

  languages:
    type: array
    required: true
    items:
      type: string
    description: "Programming languages used"
    example: ["TypeScript", "Python"]

  environment:
    type: enum
    required: true
    options: ["development", "staging", "production"]
    description: "Target deployment environment"

  port:
    type: number
    required: false
    default: 3000
    description: "Port number for the application"

  enable_ssl:
    type: boolean
    required: false
    default: true
    description: "Enable SSL/TLS encryption"

context: "Setting up deployment configuration"
```

### Step 2: Group Fields for Conversation

Organize fields into logical conversation steps:
- Group related fields (max 4 per question due to AskUserQuestion limit)
- Order by: required first, then optional
- Consider field dependencies

### Step 3: Multi-Turn Collection

For each field or field group, use appropriate collection method:

#### String Fields

```typescript
AskUserQuestion({
  questions: [{
    question: "{description}. Example: {example}",
    header: "{field_name}",
    options: [
      { label: "Enter value", description: "Type your value" },
      { label: "Use example", description: "Use: {example}" },
      { label: "Skip", description: "Leave empty (if optional)" }
    ],
    multiSelect: false
  }]
})
```

If user selects "Enter value", they provide custom input via "Other".

#### Enum Fields

```typescript
AskUserQuestion({
  questions: [{
    question: "{description}",
    header: "{field_name}",
    options: options.map(opt => ({
      label: opt,
      description: ""
    })),
    multiSelect: false
  }]
})
```

#### Array Fields

```typescript
// First, ask how many items or collect one by one
AskUserQuestion({
  questions: [{
    question: "{description}. What items would you like to add?",
    header: "{field_name}",
    options: [
      { label: "Add items", description: "Enter comma-separated values" },
      { label: "Common presets", description: "Choose from common options" },
      { label: "Skip", description: "Empty list (if optional)" }
    ],
    multiSelect: false
  }]
})
```

#### Boolean Fields

```typescript
AskUserQuestion({
  questions: [{
    question: "{description}",
    header: "{field_name}",
    options: [
      { label: "Yes", description: "Enable this option" },
      { label: "No", description: "Disable this option" },
      { label: "Default ({default})", description: "Use default value" }
    ],
    multiSelect: false
  }]
})
```

#### Number Fields

```typescript
AskUserQuestion({
  questions: [{
    question: "{description}. Example: {example}",
    header: "{field_name}",
    options: [
      { label: "Enter value", description: "Type a number" },
      { label: "Default ({default})", description: "Use default: {default}" },
      { label: "Skip", description: "Leave empty (if optional)" }
    ],
    multiSelect: false
  }]
})
```

#### Object Fields (Nested)

For nested objects, recursively apply the same collection process:

```yaml
database:
  type: object
  description: "Database configuration"
  properties:
    host:
      type: string
      required: true
    port:
      type: number
      default: 5432
```

### Step 4: Validation

After collecting each field:

1. **Type validation** - Ensure value matches expected type
2. **Pattern validation** - If `validate` regex is provided, check match
3. **Required check** - Ensure required fields have values

If validation fails:
```typescript
AskUserQuestion({
  questions: [{
    question: "Invalid value for {field_name}: {error}. Please try again.",
    header: "Retry",
    options: [
      { label: "Enter new value", description: "Try again" },
      { label: "Use default", description: "Use: {default}" },
      { label: "Skip", description: "Leave empty (if optional)" }
    ],
    multiSelect: false
  }]
})
```

### Step 5: Confirmation

After all fields are collected, show summary and confirm:

```
Collected Configuration
=======================

project_name: my-awesome-app
languages: [TypeScript, Python]
environment: production
port: 3000 (default)
enable_ssl: true (default)

```

```typescript
AskUserQuestion({
  questions: [{
    question: "Does this configuration look correct?",
    header: "Confirm",
    options: [
      { label: "Yes, looks good", description: "Proceed with these values" },
      { label: "Edit a field", description: "Change a specific value" },
      { label: "Start over", description: "Re-enter all values" }
    ],
    multiSelect: false
  }]
})
```

If "Edit a field" is selected, ask which field to edit and re-collect that field.

### Step 6: Return Result

Return the collected data in structured format:

```yaml
result:
  status: complete
  data:
    project_name: "my-awesome-app"
    languages: ["TypeScript", "Python"]
    environment: "production"
    port: 3000
    enable_ssl: true
  skipped_fields: []  # List of optional fields that were skipped
```

---

## Advanced Features

### Conditional Fields

Fields can depend on other field values:

```yaml
schema:
  use_database:
    type: boolean
    description: "Does your project use a database?"

  database_type:
    type: enum
    options: ["postgres", "mysql", "mongodb"]
    description: "Which database?"
    condition: "use_database == true"  # Only ask if use_database is true
```

### Field Groups

Group related fields to ask together:

```yaml
schema:
  host:
    type: string
    group: "server"
  port:
    type: number
    group: "server"

  username:
    type: string
    group: "credentials"
  password:
    type: string
    group: "credentials"
```

### Pre-populated Values

Schema can include detected/suggested values:

```yaml
schema:
  project_name:
    type: string
    detected: "claude-plugins"  # Auto-detected from package.json
    description: "Project name"
```

When detected value exists:
```typescript
AskUserQuestion({
  questions: [{
    question: "Project name. Detected: {detected}",
    header: "project_name",
    options: [
      { label: "Use detected", description: "Use: {detected}" },
      { label: "Enter different", description: "Specify another name" }
    ],
    multiSelect: false
  }]
})
```

---

## Example Invocation

```yaml
invoke: prompt-user
schema:
  environment:
    type: enum
    required: true
    options: ["local", "stable", "production"]
    description: "Deployment environment"

  ssh_host:
    type: string
    required: true
    description: "SSH hostname or IP"
    example: "deploy.example.com"
    condition: "environment != 'local'"

  ssh_user:
    type: string
    required: false
    default: "deploy"
    description: "SSH username"
    condition: "environment != 'local'"

  ssh_port:
    type: number
    required: false
    default: 22
    description: "SSH port"
    condition: "environment != 'local'"

context: "Configuring deployment environment access"
```

---

## Error Handling

| Error | Recovery |
|-------|----------|
| User cancels mid-collection | Return partial result with `status: cancelled` |
| Invalid schema format | Return error with `status: invalid_schema` |
| Validation repeatedly fails | Offer to skip (if optional) or use default |

---

## Interactive Checkpoints

- [ ] For each required field: "What is {field_name}?"
- [ ] For optional fields: "Would you like to set {field_name}? (default: {default})"
- [ ] After collection: "Does this look correct?"
- [ ] If editing: "Which field would you like to change?"
