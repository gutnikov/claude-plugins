## Memory

**Backend**: {memory_backend}
**Integration**: {integration_type}

### Configuration

| Setting | Value |
|---------|-------|
| Storage | {storage_type} |
| Retention | {retention_policy} |
| Scope | {memory_scope} |

### Available Operations

| Operation | Description |
|-----------|-------------|
| Store | Save information to memory |
| Retrieve | Get stored information |
| Search | Find relevant memories |
| List | List all stored items |
| Delete | Remove stored item |
| Update | Modify existing memory |

### Memory Categories

| Category | Description | Auto-save |
|----------|-------------|-----------|
| facts | Project facts and decisions | No |
| preferences | User preferences | Yes |
| context | Session context | Yes |
| learnings | Learned patterns | No |

### Usage

Memories are automatically used to maintain context across sessions.

**Storing a memory:**
```
{store_example}
```

**Retrieving memories:**
```
{retrieve_example}
```

### Retention Policy

- {retention_rule_1}
- {retention_rule_2}
- {retention_rule_3}

### Privacy Notes

- Memories are project-scoped
- No sensitive data should be stored
- Users can clear memories at any time
