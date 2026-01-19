## Task Management

**Backend**: {task_backend}
**Integration**: {integration_type}

### Configuration

| Setting | Value |
|---------|-------|
| Project | {project_key} |
| Board | {board_name} |
| Workflow | {workflow_states} |

### Available Operations

| Operation | Description |
|-----------|-------------|
| Create task | Create new work items |
| Update task | Modify existing tasks |
| Transition | Change task status |
| Assign | Assign to team members |
| Comment | Add comments to tasks |
| Search | Query tasks with filters |

### Workflow States

```
{workflow_diagram}
```

### Task Types

| Type | Description | Labels |
|------|-------------|--------|
| Bug | Defect to fix | bug, priority |
| Feature | New functionality | feature, epic |
| Task | General work item | task |
| Chore | Maintenance work | chore, tech-debt |

### Usage Examples

```
"Create a bug ticket for the login issue"
"Move {task_id} to In Progress"
"What are my assigned tickets?"
"List open bugs in {project}"
```

### Integration Notes

- {integration_specific_notes}
