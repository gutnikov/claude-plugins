# Workflow Orchestration - Abstract

This section defines the workflow orchestration system used for durable, long-running processes. It is vendor-agnostic and describes the conceptual model.

## Core Concepts

| Concept      | Description                                                  |
|--------------|--------------------------------------------------------------|
| **Workflow** | Durable function that orchestrates activities and child workflows |
| **Activity** | Single unit of work (API call, computation, side effect)     |
| **Worker**   | Process that executes workflows and activities               |
| **Task Queue**| Named queue that routes work to appropriate workers         |
| **Schedule** | Cron-like trigger for recurring workflow executions          |

---

## Workflow Characteristics

| Property            | Description                                      |
|---------------------|--------------------------------------------------|
| **Durability**      | Survives process crashes and restarts            |
| **Determinism**     | Same inputs always produce same state transitions|
| **Retries**         | Automatic retry with configurable backoff        |
| **Timeouts**        | Workflow, activity, and schedule timeouts        |
| **Versioning**      | Handle code changes without breaking executions  |

---

## Workflow States

| State         | Description                            | Terminal |
|---------------|----------------------------------------|----------|
| `Running`     | Actively executing                     | No       |
| `Completed`   | Finished successfully                  | Yes      |
| `Failed`      | Terminated due to unhandled error      | Yes      |
| `Cancelled`   | Cancelled by request                   | Yes      |
| `Terminated`  | Forcefully terminated                  | Yes      |
| `TimedOut`    | Exceeded workflow timeout              | Yes      |
| `ContinuedAsNew` | Restarted with new execution        | Yes*     |

*ContinuedAsNew creates a new execution, so the original is terminal.

---

## Activity Retry Policy

| Parameter              | Description                          | Default    |
|------------------------|--------------------------------------|------------|
| `initialInterval`      | First retry delay                    | 1s         |
| `backoffCoefficient`   | Multiplier for subsequent retries    | 2.0        |
| `maximumInterval`      | Max delay between retries            | 100 * init |
| `maximumAttempts`      | Max retry count (0 = unlimited)      | 0          |
| `nonRetryableErrors`   | Errors that should not retry         | []         |

---

## Workflow Patterns

### Sequential Activities

Execute activities one after another, each using the result of the previous.

```
Start → Activity A → Activity B → Activity C → Complete
```

### Parallel Activities

Execute multiple activities concurrently and wait for all.

```
        ┌→ Activity A ─┐
Start → ├→ Activity B ─┼→ Complete
        └→ Activity C ─┘
```

### Saga Pattern

Compensating transactions for distributed operations.

```
Activity A → Activity B → Activity C
    ↓ fail      ↓ fail
Compensate A ← Compensate B
```

### Child Workflows

Spawn child workflows for modularity and separate failure domains.

```
Parent Workflow
    ├→ Child Workflow 1
    ├→ Child Workflow 2
    └→ Child Workflow 3
```

---

## Operations Required

### Server Operations

| Operation           | Description                              |
|---------------------|------------------------------------------|
| Start server        | Start local development server           |
| Stop server         | Stop the local development server        |
| Health check        | Verify server is responding              |

### Workflow Operations

| Operation           | Description                              |
|---------------------|------------------------------------------|
| Register workflow   | Deploy workflow definition to server     |
| Start execution     | Begin a new workflow execution           |
| Query status        | Get current state of execution           |
| Cancel execution    | Request graceful cancellation            |
| Terminate execution | Force immediate termination              |
| List executions     | List with filters (status, type, time)   |
| Get history         | Retrieve execution event history         |

### Worker Operations

| Operation           | Description                              |
|---------------------|------------------------------------------|
| Start worker        | Begin processing task queue              |
| Stop worker         | Gracefully shutdown worker               |
| Health check        | Verify worker is processing              |

### Schedule Operations

| Operation           | Description                              |
|---------------------|------------------------------------------|
| Create schedule     | Set up recurring workflow trigger        |
| Update schedule     | Modify schedule parameters               |
| Delete schedule     | Remove scheduled trigger                 |
| List schedules      | View all configured schedules            |

---

## Execution Guarantees

| Guarantee           | Description                              |
|---------------------|------------------------------------------|
| **At-least-once**   | Activities may execute more than once    |
| **Exactly-once**    | Workflow state changes are atomic        |
| **Idempotency**     | Activities should be idempotent          |
| **Visibility**      | All executions are observable            |

---

## Best Practices

1. **Keep workflows deterministic** - No random values, current time, or external calls in workflow code
2. **Use activities for side effects** - All I/O, API calls, and non-deterministic operations go in activities
3. **Design for failure** - Assume any activity can fail at any time
4. **Use appropriate timeouts** - Set workflow, activity, and heartbeat timeouts
5. **Version carefully** - Use versioning APIs when changing workflow logic
6. **Monitor executions** - Set up alerts for failed workflows and stuck executions
