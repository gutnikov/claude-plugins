## Problem Remediation

**Runbooks Location**: `{runbooks_path}`
**Automation**: `{automation_path}`

### Available Runbooks

| Runbook | Issue | Auto-remediate | Last Updated |
|---------|-------|----------------|--------------|
| `{runbook_1}.md` | {issue_1} | {auto_1} | {date_1} |
| `{runbook_2}.md` | {issue_2} | {auto_2} | {date_2} |
| `{runbook_3}.md` | {issue_3} | {auto_3} | {date_3} |

### Runbook Template

```markdown
# Runbook: {Issue Name}

## Symptoms
- What the user/system observes

## Diagnosis
1. Step to identify root cause
2. Additional diagnostic steps

## Resolution
1. Step to fix the issue
2. Additional fix steps

## Verification
1. How to confirm the fix worked

## Prevention
- How to prevent recurrence

## Automation
- Script: `{script_path}`
- Auto-trigger: {yes/no}
```

### Automation

```bash
# Run a specific runbook
{run_runbook_cmd}

# List available runbooks
{list_runbooks_cmd}

# Test runbook (dry-run)
{test_runbook_cmd}
```

### Escalation Path

| Level | Contact | Response Time |
|-------|---------|---------------|
| L1 | {l1_contact} | {l1_time} |
| L2 | {l2_contact} | {l2_time} |
| L3 | {l3_contact} | {l3_time} |

### Post-Incident

1. Document incident in `{incidents_path}`
2. Update runbook if needed
3. Create prevention tasks
4. Schedule post-mortem if needed
