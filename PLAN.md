# Plan: Add Custom Vendor Support with Gap Analysis

## Overview

Extend the `setup-project-domain` meta-skill and its generated skills to support custom vendor entry. When users enter a vendor not in the predefined list, the system will:
1. Search for available MCPs/APIs for that vendor
2. Analyze capability gaps against the extracted domain model
3. Allow users to provide workarounds for unsupported scenarios
4. Document workarounds in CLAUDE.md for Claude to use correctly

## File to Modify

- `plugins/crunch/skills/setup-project-domain/SKILL.md`

## Changes Summary

| Section | Change |
|---------|--------|
| Phase 2.5 Suggestion Display | Add "Enter custom vendor" option |
| NEW: Phase 2.6 | Custom Vendor Discovery & Gap Analysis |
| Template Phase 1 | Add "Other" option to vendor selection |
| Template NEW Phase 1.5 | Custom Vendor Validation flow |
| Template Phase 5 | Add workaround documentation to CLAUDE.md |
| Generation Details | Add workaround documentation format |

---

## Phase 2.6: Custom Vendor Discovery & Gap Analysis (NEW)

### When Triggered

User selects "Enter custom vendor" from Phase 2.5 suggestions or types a vendor name not in the registry.

### Step 1: Vendor Name Collection

```
Custom Vendor Entry
===================

Enter the name of the vendor you'd like to use:
>
```

### Step 2: MCP/API Discovery

Search for available MCPs and APIs:

```
Searching for {Vendor} integration options...

Found:
  MCP Options:
    - {mcp-package-name} (npm) - {description}
    - {official-mcp-url} (official) - {description}

  Direct API:
    - REST API: {api-docs-url}
    - GraphQL: {graphql-url}

Select integration method:
1. {mcp-package-name} (MCP - recommended)
2. {official-mcp-url} (Official MCP)
3. Direct API integration
4. Search again with different name
>
```

**Discovery Methods:**
- Web search for "{vendor} MCP server"
- Check npm registry for "{vendor}-mcp" packages
- Search MCP registry/awesome-mcp lists
- Check vendor's official documentation for MCP support

### Step 3: Capability Analysis

After MCP/API selection, analyze capabilities against extracted model:

```
Analyzing {Vendor} capabilities against your domain model...

Checking {N} entities, {M} operations, {P} attributes...
```

**Analysis Process:**
1. Fetch MCP tool definitions (if MCP selected)
2. Parse API documentation (if direct API)
3. Match extracted entities/operations/attributes
4. Identify gaps

### Step 4: Gap Report

```
{Vendor} Capability Analysis
============================

SUPPORTED ({X}% match)

Entities:
  + ticket    → {vendor_entity}  [Full]
  + agent     → {vendor_entity}  [Full]

Operations:
  + create    → {api_method}     [Full]
  + assign    → {api_method}     [Full]

Attributes:
  + priority  → {field}          [Full]
  + status    → {field}          [Full]

GAPS FOUND

The following scenarios from your requirements cannot be directly implemented:

1. Scenario: "assign ticket to customer"
   Gap: {Vendor} has no 'customer' entity
   Required: customer entity with email attribute

2. Scenario: "link related tickets"
   Gap: {Vendor} has no native linking operation
   Required: link operation between tickets

Would you like to:
1. Provide workarounds for these gaps
2. Choose a different vendor
3. Proceed anyway (gaps will be noted as unsupported)
>
```

### Step 5: Workaround Collection

For each gap, collect user's workaround:

```
Gap Resolution
==============

Gap 1: No 'customer' entity in {Vendor}

Your scenario: "assign ticket to customer"

How would you like to handle this in {Vendor}?

Examples:
- "Use a custom field called 'customer_email'"
- "Create a label with customer name"
- "Store customer ID in description field"
- "Skip this - we don't need customer tracking"

Your workaround:
>
```

After collecting:

```
Workaround recorded!

Gap: No 'customer' entity
Workaround: Use custom field 'customer_email'
Implementation: When assigning to customer, set custom_field_12345 = customer.email

Continue to next gap? (yes / modify this one)
>
```

### Step 6: Workaround Validation

Verify the workaround is implementable:

```
Validating workaround...

Checking if {Vendor} supports:
  - Custom fields: Yes
  - Field type 'email': Yes
  - API access to custom fields: Yes

Workaround is valid and implementable.
```

**If workaround is NOT implementable:**

```
Workaround Validation Failed
============================

The workaround "Use custom field 'customer_email'" cannot be implemented because:
  - {Vendor} does not support custom fields on the free plan
  - OR: The API does not expose custom field modification

Alternative suggestions:
1. Use the description field instead
2. Use labels/tags
3. Skip this requirement

Please provide an alternative workaround:
>
```

### Step 7: Consolidated Workaround Review

```
Workaround Summary
==================

{Vendor} will be configured with these adaptations:

| Gap | Workaround | Implementation |
|-----|------------|----------------|
| No customer entity | Custom field | Set custom_field_12345 |
| No link operation | Use comments | Add "Related: #ID" in comments |

These will be documented in CLAUDE.md so I know how to use {Vendor} correctly.

Proceed with setup? (yes / modify / cancel)
>
```

**DOD:** All gaps have workarounds or are marked as unsupported

---

## Template Updates for Generated Skills

### Update Vendor Selection Display

Add "Other" option to the vendor selection in generated skills:

```
Which {domain_name} tool would you like to integrate?

All options support: {feature_list}

  1. {Vendor1}     - {vendor1_notes}
                    Best for: {use_case}

  2. {Vendor2}     - {vendor2_notes}
                    Best for: {use_case}

  ...

  N. Other         - Enter a custom vendor
                    (Will search for MCP/API and validate capabilities)

Enter number or name:
>
```

### Add Template Phase: Custom Vendor Validation

Insert new phase in generated skill template after vendor selection:

```markdown
### Phase 1.5: Custom Vendor Validation (if "Other" selected)

If user selected "Other" or entered an unknown vendor name:

#### Step 1: Search for Integration Options

Search for MCP servers and APIs for the entered vendor:

\`\`\`
Searching for "{vendor_name}" integration options...
\`\`\`

**Search locations:**
- npm registry: `{vendor}-mcp`, `mcp-{vendor}`
- MCP server lists and registries
- Vendor official documentation
- GitHub MCP repositories

#### Step 2: Validate Against Required Features

Check if discovered MCP/API supports required features:

Required features: {feature_list}

\`\`\`
Capability Check for {Vendor}
=============================

Required Feature          | Supported | How
--------------------------|-----------|------------------
{feature_1}               | Yes/No    | {api_method or "N/A"}
{feature_2}               | Yes/No    | {api_method or "N/A"}
...
\`\`\`

#### Step 3: Handle Gaps

If gaps exist, present options:

\`\`\`
{Vendor} does not fully support all required features.

Missing:
  - {feature}: {reason}

Options:
1. Provide a workaround for this gap
2. Choose a different vendor
3. Proceed without this feature
>
\`\`\`

#### Step 4: Collect Workarounds

For each gap where user chooses to provide workaround:

\`\`\`
How should "{feature}" be implemented in {Vendor}?

This feature is used in scenarios like:
  "{example_scenario}"

Your workaround:
>
\`\`\`

**DOD:** Vendor validated, gaps resolved or accepted
```

### Update CLAUDE.md Template

Add workarounds section to the CLAUDE.md documentation:

```markdown
## {Domain Name}

**Vendor**: {vendor}
**MCP**: {mcp_package}

### Available Operations

{standard_operations_list}

### Workarounds & Adaptations

When using {vendor} for this project, note these adaptations:

| Standard Operation | {Vendor} Implementation | Notes |
|--------------------|------------------------|-------|
| Assign to customer | Set `custom_field_12345` | Customer email stored in custom field |
| Link tickets | Add comment "Related: #ID" | No native linking |

### Usage Examples

**Standard scenario:**
"Create a ticket and assign to customer"

**How to implement with {vendor}:**
1. Create ticket using `createTicket` tool
2. Set `custom_field_12345` to customer email
3. (No native customer entity - email is the reference)

### Unsupported Features

The following features are NOT available with {vendor}:
- {feature}: {reason}
```

---

## Progress File Updates

Add to progress file format:

```markdown
## Custom Vendor Analysis

- **Vendor Name**: {user_entered_name}
- **Discovery Method**: {MCP search / API docs / manual}
- **Integration Type**: {MCP / Direct API}

### Capability Gaps

| Gap | Workaround | Validated |
|-----|------------|-----------|
| No customer entity | Custom field | Yes |
| No linking | Comments | Yes |

### Workaround Details

#### Gap 1: No customer entity
- **Scenario affected**: "assign ticket to customer"
- **Workaround**: Use custom field 'customer_email'
- **Implementation**: Set custom_field_12345 = customer.email
- **Validated**: Yes
```

---

## Implementation Steps

1. **Update Phase 2.5** (~20 lines)
   - Add "Enter custom vendor" option to suggestion display
   - Add flow for custom vendor entry

2. **Add Phase 2.6: Custom Vendor Discovery** (~100 lines)
   - Vendor name collection
   - MCP/API discovery instructions
   - Capability analysis process
   - Gap report format

3. **Add Workaround Collection flow** (~80 lines)
   - Per-gap workaround dialog
   - Workaround validation
   - Consolidated review

4. **Update Template Vendor Selection** (~15 lines)
   - Add "Other" option

5. **Add Template Phase 1.5** (~60 lines)
   - Custom vendor validation flow
   - Feature check display
   - Gap handling

6. **Update Template CLAUDE.md section** (~40 lines)
   - Add workarounds section
   - Usage examples with workarounds
   - Unsupported features list

7. **Update Progress File format** (~25 lines)
   - Custom vendor analysis section
   - Workaround tracking

---

## Verification

After implementation:
1. Run `/setup-project-domain`
2. Select "Custom Domain"
3. Provide 2-3 scenarios
4. At vendor suggestion, select "Enter custom vendor"
5. Enter a vendor not in registry (e.g., "Notion")
6. Verify discovery and gap analysis
7. Provide workarounds for gaps
8. Complete setup and verify CLAUDE.md includes workarounds
