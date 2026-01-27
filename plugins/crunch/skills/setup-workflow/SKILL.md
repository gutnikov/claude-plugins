---
name: setup-workflow
description: Set up and manage Temporal.io workflow orchestration system
arguments:
  - name: action
    required: false
    description: |
      Action to perform:
      - 'setup': Initial setup (install deps, start server)
      - 'start': Start server and worker
      - 'stop': Stop server and worker
      - 'test': Run workflow tests
      - 'deploy': Deploy workflow changes (restart worker)
      Default: setup
  - name: mode
    required: false
    description: |
      Server mode: 'local' for local development server, 'cloud' for Temporal Cloud.
      Default: local
---

# Setup Workflow Skill

This skill manages the Temporal.io workflow orchestration system. The workflow source code
lives in `workflow/` subdirectory and serves as the **source of truth** for all workflow
definitions, activities, and workers.

## Workflow Directory

```
plugins/crunch/skills/setup-workflow/
├── SKILL.md                              # This file
└── workflow/                             # Workflow orchestration system (source of truth)
    ├── package.json                      # Dependencies (@temporalio/*)
    ├── tsconfig.json                     # TypeScript configuration
    ├── src/
    │   ├── activities/                   # Activity implementations
    │   │   └── greet.ts                  # Example: greet, farewell
    │   ├── workflows/                    # Workflow definitions
    │   │   └── hello-world.ts            # Example: helloWorld workflow
    │   ├── worker.ts                     # Worker process
    │   └── client.ts                     # Workflow client (for starting workflows)
    ├── scripts/
    │   ├── start-worker.sh               # Start worker
    │   ├── run-workflow.sh               # Execute workflow
    │   └── test-workflow.sh              # End-to-end test
    └── tests/
        └── hello-world.test.ts           # Unit tests
```

## Arguments

| Argument | Required | Default | Description                              |
|----------|----------|---------|------------------------------------------|
| `action` | No       | `setup` | `setup`, `start`, `stop`, `test`, `deploy` |
| `mode`   | No       | `local` | `local` or `cloud` server mode           |

## Definition of Done

1. Temporal server is running and healthy
2. Dependencies are installed in `workflow/`
3. Worker is running and polling task queue
4. Test workflow executes successfully
5. CLAUDE.md is updated with workflow operations

## Dependencies

```yaml
skills:
  - track-setup-progress   # State persistence

data:
  - plugins/crunch/data/domains.yaml
  - plugins/crunch/data/abstract/workflow-orchestration.md

source:
  - plugins/crunch/skills/setup-workflow/workflow/  # Workflow source code

external:
  - Node.js >= 18
  - npm or pnpm
  - temporal CLI (will install if missing)
```

---

## Actions

### Action: setup

Initial setup of the workflow orchestration system.

**Steps:**

1. Check prerequisites (Node.js >= 18, npm)
2. Install temporal CLI if not present
3. Install dependencies in `workflow/`
4. Start local Temporal server
5. Verify server health
6. Run verification workflow
7. Update CLAUDE.md

**Commands:**

```bash
# Install temporal CLI (macOS)
brew install temporal

# Install dependencies
cd plugins/crunch/skills/setup-workflow/workflow
npm install

# Start server (runs in foreground, use separate terminal)
temporal server start-dev

# Verify server
curl -s http://localhost:7233/health
```

---

### Action: start

Start the Temporal server and worker.

**Commands:**

```bash
# Terminal 1: Start server
temporal server start-dev

# Terminal 2: Start worker
cd plugins/crunch/skills/setup-workflow/workflow
npm run start:worker
```

---

### Action: stop

Stop the worker and server.

**Commands:**

```bash
# Stop worker (Ctrl+C in worker terminal)
# Stop server (Ctrl+C in server terminal)

# Or kill by port
lsof -ti:7233 | xargs kill -9  # Server
lsof -ti:8233 | xargs kill -9  # Web UI
```

---

### Action: test

Run workflow tests.

**Commands:**

```bash
cd plugins/crunch/skills/setup-workflow/workflow

# Unit tests (no server required)
npm test

# End-to-end test (requires server running)
./scripts/test-workflow.sh
```

---

### Action: deploy

Deploy workflow changes by restarting the worker.

**Steps:**

1. Build TypeScript: `npm run build`
2. Restart worker to pick up changes

**Commands:**

```bash
cd plugins/crunch/skills/setup-workflow/workflow
npm run build

# Restart worker (stop and start)
# Worker will load new workflow definitions
npm run start:worker
```

---

## Workflow Phases

### Phase 0: State Detection

Check current state of the workflow system.

**Checks:**

| Check                  | Command                                    |
|------------------------|--------------------------------------------|
| Server running         | `curl -s http://localhost:7233/health`     |
| Dependencies installed | `test -d workflow/node_modules`            |
| Worker running         | Check process on task queue                |

---

### Phase 1: Environment Check

Verify prerequisites.

**Requirements:**

| Requirement     | Check Command              | Minimum |
|-----------------|----------------------------|---------|
| Node.js         | `node --version`           | 18.0.0  |
| npm             | `npm --version`            | 8.0.0   |
| temporal CLI    | `temporal --version`       | 1.0.0   |

**Install temporal CLI:**

```bash
# macOS
brew install temporal

# Linux/other
curl -sSf https://temporal.download/cli.sh | sh
```

---

### Phase 2: Server Setup

Start local Temporal development server.

**Commands:**

```bash
# Start dev server with persistent storage
temporal server start-dev --db-filename /tmp/temporal.db

# Server endpoints:
# - gRPC: localhost:7233
# - Web UI: localhost:8233
```

**Verify:**

```bash
# Health check
curl -s http://localhost:7233/health

# Open Web UI
open http://localhost:8233
```

---

### Phase 3: Install Dependencies

Install workflow dependencies.

**Commands:**

```bash
cd plugins/crunch/skills/setup-workflow/workflow
npm install
```

---

### Phase 4: Verification

Run test workflow to verify setup.

**Commands:**

```bash
cd plugins/crunch/skills/setup-workflow/workflow

# Start worker in background
npm run start:worker &

# Run test workflow
npm run start:workflow TestUser

# Or run full test script
./scripts/test-workflow.sh
```

**Expected Output:**

```
Starting workflow: hello-world-1234567890
Workflow started: hello-world-1234567890
Run ID: abc-123-def

Workflow completed!
Result: {
  "greetingResult": {
    "greeting": "Hello, TestUser!",
    "timestamp": "2024-01-15T10:30:00.000Z"
  },
  "farewellResult": {
    "greeting": "Goodbye, TestUser!",
    "timestamp": "2024-01-15T10:30:01.000Z"
  },
  "workflowCompleted": true
}
```

---

### Phase 5: Documentation

Update CLAUDE.md with workflow section.

**Content:**

```markdown
## Workflow Orchestration

### Vendor: Temporal

- **Status**: Configured
- **Server**: http://localhost:7233
- **Web UI**: http://localhost:8233
- **Source**: plugins/crunch/skills/setup-workflow/workflow/

#### Quick Commands

| Action         | Command                                                    |
|----------------|------------------------------------------------------------|
| Start server   | `temporal server start-dev`                                |
| Start worker   | `cd plugins/crunch/skills/setup-workflow/workflow && npm run start:worker` |
| Run workflow   | `cd plugins/crunch/skills/setup-workflow/workflow && npm run start:workflow` |
| Run tests      | `cd plugins/crunch/skills/setup-workflow/workflow && npm test` |
| Open Web UI    | `open http://localhost:8233`                               |

#### Environment Variables

| Variable            | Description                  | Default        |
|---------------------|------------------------------|----------------|
| `TEMPORAL_ADDRESS`  | Temporal server gRPC address | localhost:7233 |
| `TEMPORAL_NAMESPACE`| Temporal namespace           | default        |
```

---

## Source Code Reference

### src/activities/greet.ts

Activities perform the actual work (API calls, database operations, side effects).

```typescript
export interface GreetInput {
  name: string;
}

export interface GreetOutput {
  greeting: string;
  timestamp: string;
}

export async function greet(input: GreetInput): Promise<GreetOutput> {
  return {
    greeting: `Hello, ${input.name}!`,
    timestamp: new Date().toISOString(),
  };
}

export async function farewell(input: GreetInput): Promise<GreetOutput> {
  return {
    greeting: `Goodbye, ${input.name}!`,
    timestamp: new Date().toISOString(),
  };
}
```

### src/workflows/hello-world.ts

Workflows orchestrate activities. Must be deterministic.

```typescript
import { proxyActivities, sleep } from '@temporalio/workflow';
import type * as activities from '../activities/greet';

const { greet, farewell } = proxyActivities<typeof activities>({
  startToCloseTimeout: '1 minute',
  retry: {
    initialInterval: '1s',
    backoffCoefficient: 2,
    maximumAttempts: 3,
  },
});

export async function helloWorld(input: HelloWorldInput): Promise<HelloWorldOutput> {
  const greetingResult = await greet({ name: input.name });

  let farewellResult;
  if (input.includeGoodbye) {
    await sleep('1 second');
    farewellResult = await farewell({ name: input.name });
  }

  return { greetingResult, farewellResult, workflowCompleted: true };
}
```

### src/worker.ts

Worker polls task queue and executes workflows/activities.

```typescript
import { Worker, NativeConnection } from '@temporalio/worker';
import * as activities from './activities/greet';

const worker = await Worker.create({
  connection: await NativeConnection.connect({ address: 'localhost:7233' }),
  namespace: 'default',
  taskQueue: 'hello-world-queue',
  workflowsPath: require.resolve('./workflows/hello-world'),
  activities,
});

await worker.run();
```

### src/client.ts

Client starts workflows and retrieves results.

```typescript
import { Client, Connection } from '@temporalio/client';
import { helloWorld } from './workflows/hello-world';

const client = new Client({
  connection: await Connection.connect({ address: 'localhost:7233' }),
});

const handle = await client.workflow.start(helloWorld, {
  taskQueue: 'hello-world-queue',
  workflowId: `hello-world-${Date.now()}`,
  args: [{ name: 'World', includeGoodbye: true }],
});

const result = await handle.result();
```

---

## Adding New Workflows

1. **Create activity** in `workflow/src/activities/`:
   ```typescript
   // src/activities/task-management.ts
   export async function createTask(input: CreateTaskInput): Promise<Task> {
     // Call task management API
   }
   ```

2. **Create workflow** in `workflow/src/workflows/`:
   ```typescript
   // src/workflows/process-input.ts
   import { proxyActivities } from '@temporalio/workflow';
   import type * as activities from '../activities/task-management';

   const { createTask } = proxyActivities<typeof activities>({
     startToCloseTimeout: '5 minutes',
   });

   export async function processInput(input: ProcessInputInput) {
     const task = await createTask({ title: input.title });
     return { taskId: task.id };
   }
   ```

3. **Register in worker** - update `workflow/src/worker.ts`

4. **Deploy** - restart worker to load new workflows

---

## Troubleshooting

| Error                        | Cause                    | Solution                        |
|------------------------------|--------------------------|---------------------------------|
| Connection refused :7233     | Server not running       | `temporal server start-dev`     |
| No worker polling task queue | Worker not started       | `npm run start:worker`          |
| Workflow execution timeout   | Worker crashed           | Check logs, restart worker      |
| Non-determinism detected     | Workflow code changed    | Use versioning or reset         |
| Activity failed              | Activity threw error     | Check activity implementation   |

---

## Error Handling

| Error                  | Detection                    | Recovery                          |
|------------------------|------------------------------|-----------------------------------|
| Node.js not installed  | `node --version` fails       | Install Node.js >= 18             |
| Server won't start     | Port 7233 in use             | Kill existing: `lsof -ti:7233 \| xargs kill` |
| npm install fails      | Non-zero exit                | Check network, clear cache        |
| Worker won't connect   | Connection refused           | Verify server is running          |
