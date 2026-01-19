## Configuration

**Tool**: {config_tool}

### Environment Files

| File | Purpose | Git Status |
|------|---------|------------|
| `.env` | Local development | Ignored |
| `.env.example` | Template with all variables | Tracked |
| `.env.test` | Test environment | Ignored |

### Variables

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `NODE_ENV` | Environment name | Yes | development |
| `PORT` | Server port | No | 3000 |
| `DATABASE_URL` | Database connection string | Yes | - |
| `API_KEY` | External API key | Yes | - |

### Usage

```bash
# Copy template and fill in values
cp .env.example .env

# Load environment (if using direnv)
direnv allow
```

### Adding New Variables

1. Add to `.env.example` with description comment
2. Add to this table
3. Update application code to use the variable
