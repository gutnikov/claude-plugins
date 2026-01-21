# Task Management - Abstract

This section defines the task management system used across the project. It is vendor-agnostic and describes the conceptual model.

## Task Types (exactly 4)

| Type          | Meaning              | Core Question               |
|---------------|----------------------|-----------------------------|
| **Input**     | Raw incoming signal  | What came to us?            |
| **Intent**    | Desired change       | What do we want to change?  |
| **Issue**     | Problem / deviation  | What is broken or risky?    |
| **Work Item** | Executable unit      | What exactly are we doing?  |

There are no other task types. "Blocker" is a role of a Work Item, not a type.

---

## States by Task Type

### Input States

| State            | Description              | Terminal |
|------------------|--------------------------|----------|
| `Input:New`      | Unprocessed signal       | No       |
| `Input:Reviewed` | Ready for classification | No       |
| → Intent         | Converted to Intent      | Yes      |
| → Issue          | Converted to Issue       | Yes      |

### Intent States

| State              | Description                  | Terminal |
|--------------------|------------------------------|----------|
| `Intent:Draft`     | Initial capture              | No       |
| `Intent:Refined`   | Requirements clarified       | No       |
| `Intent:Approved`  | Ready for decomposition      | No       |
| `Intent:Completed` | Goal satisfied by Work Items | Yes      |

### Issue States

| State             | Description                | Terminal |
|-------------------|----------------------------|----------|
| `Issue:Reported`  | Problem identified         | No       |
| `Issue:Confirmed` | Reproduced / validated     | No       |
| `Issue:Planned`   | Fix Work Item created      | No       |
| `Issue:Resolved`  | Fix Work Item done         | No       |
| `Issue:Verified`  | Post-fix validation passed | Yes      |
| `Issue:WontFix`   | Decided not to fix         | Yes      |

### Work Item States

| State                 | Description        | Terminal |
|-----------------------|--------------------|----------|
| `WorkItem:Backlog`    | Ready to start     | No       |
| `WorkItem:InProgress` | Being executed     | No       |
| `WorkItem:Blocked`    | Waiting on Blocker | No       |
| `WorkItem:Done`       | Completed          | Yes      |

---

## Creation Points (explicit)

| Action                         | Input                           | Output           | Trigger                 |
|--------------------------------|---------------------------------|------------------|-------------------------|
| **Create Input**               | Bot message, feedback, metric   | Input:New        | User communication      |
| **Create Intent**              | Reviewed Input                  | Intent:Draft     | Classification decision |
| **Create Issue**               | Reviewed Input                  | Issue:Reported   | Classification decision |
| **Create Work Item**           | Approved Intent or Planned Issue| WorkItem:Backlog | Decomposition           |
| **Create Work Item (Blocker)** | Blocked Work Item               | WorkItem:Backlog | Explicit block          |

Creation is not a status change — it introduces a new entity with its own lifecycle.

---

## Relationships (explicit and typed)

| From      | To        | Relationship          | Meaning                 |
|-----------|-----------|-----------------------|-------------------------|
| Input     | Intent    | `derived_from`        | Signal became intention |
| Input     | Issue     | `derived_from`        | Signal became problem   |
| Intent    | Work Item | `implemented_by`      | Intent realized by work |
| Issue     | Work Item | `fixed_by`            | Issue resolved by work  |
| Work Item | Work Item | `blocks` / `unblocks` | Dependency chain        |

---

## Blockers

A **Blocker** is a Work Item whose purpose is to unblock another Work Item.

**Rules:**
- A blocked Work Item never "waits silently"
- Blocking always produces a visible Blocker Work Item
- When the Blocker is `WorkItem:Done`:
  - The blocked Work Item transitions `Blocked → InProgress`

---

## Communication Model

Communication is **orthogonal** — it never changes state directly.

| Communication Step      | Purpose                      | May Inform            |
|-------------------------|------------------------------|-----------------------|
| Ask for clarification   | Gather details for Input     | Input review          |
| Confirm DoD             | Validate acceptance criteria | Work Item refinement  |
| Ask for review          | Request validation           | Work Item completion  |
| Explain block           | Document why work stopped    | Blocker creation      |

These steps feed information back into tasks but never create or transition state implicitly.

---

## Work Item Completion Effects

When a Work Item reaches `WorkItem:Done`:

| Condition                          | Effect                                    |
|------------------------------------|-------------------------------------------|
| Linked to Intent + goal achieved   | Intent → `Intent:Completed`               |
| Linked to Issue                    | Issue → `Issue:Resolved`                  |
| Is a Blocker for another Work Item | Blocked Work Item → `WorkItem:InProgress` |

---

## Operations Required

### Core Operations (all task types)

| Operation      | Description                                      |
|----------------|--------------------------------------------------|
| Create task    | Create a task ∈ {Input, Intent, Issue, WorkItem} |
| Read task      | Read a task by id                                |
| Update task    | Update task fields                               |
| Delete task    | Delete / cancel a task (where allowed by type)   |
| List tasks     | List tasks filtered by {type, status, relations} |
| Check task     | Check existence of a task                        |
| Change status  | Change task status, enforcing valid transitions  |

### Input Operations

| Operation        | Description                                          |
|------------------|------------------------------------------------------|
| Create Input     | Create Input                                         |
| Transition Input | Transition Input status ∈ {New → Reviewed → Dropped} |
| Classify Input   | Classify Input → {Intent, Issue}, creating target    |

### Intent Operations

| Operation          | Description                                                    |
|--------------------|----------------------------------------------------------------|
| Create Intent      | Create Intent (optionally derived from Input)                  |
| Update Intent      | Update Intent definition ∈ {outcome, value, success criteria}  |
| Transition Intent  | Transition status ∈ {Draft → Refined → Approved → Completed}   |
| Decompose Intent   | Decompose Intent → {WorkItem}*                                 |
| Query Intent items | Query WorkItems implementing Intent                            |
| Complete Intent    | Complete Intent when completion condition is met               |

### Issue Operations

| Operation         | Description                                                              |
|-------------------|--------------------------------------------------------------------------|
| Create Issue      | Create Issue (optionally derived from Input)                             |
| Update Issue      | Update Issue definition ∈ {expected, actual, severity}                   |
| Transition Issue  | Transition status ∈ {Reported → Confirmed → Planned → Resolved → Verified, WontFix} |
| Create fix        | Create WorkItem fixing Issue                                             |
| Query Issue items | Query WorkItems fixing Issue                                             |
| Resolve Issue     | Resolve Issue when fix WorkItem is Done                                  |
| Verify Issue      | Verify Issue                                                             |

### WorkItem Operations

| Operation           | Description                                                        |
|---------------------|--------------------------------------------------------------------|
| Create WorkItem     | Create WorkItem (from {Intent, Issue})                             |
| Update WorkItem     | Update definition ∈ {scope, exclusions, acceptance criteria, DoD}  |
| Transition WorkItem | Transition status ∈ {Backlog ↔ InProgress ↔ Blocked ↔ Done}        |
| Assign WorkItem     | Assign / reassign WorkItem                                         |
| Link to Intent      | Link WorkItem → Intent (implements)                                |
| Link to Issue       | Link WorkItem → Issue (fixes)                                      |

---

## Automation Invariants

These rules must **never** be violated:

1. Every task has a creation point
2. Every created task has a starting state and valid terminal state
3. No task changes state without an explicit transition
4. Communication never changes state implicitly
5. Work Item completion effects are explicit

---

## Workflow Diagram

```mermaid
flowchart TD

  classDef bot fill:#ffe9a6,stroke:#f2b700,stroke-width:1px,color:#000;
  classDef created fill:#ffedd5,stroke:#f97316,stroke-width:1px,color:#000;
  classDef decision fill:#dbeafe,stroke:#1d4ed8,stroke-width:1px,color:#000;
  classDef refine fill:#dcfce7,stroke:#16a34a,stroke-width:1px,color:#000;
  classDef problem fill:#fee2e2,stroke:#ef4444,stroke-width:1px,color:#000;
  classDef terminal fill:#e5e7eb,stroke:#6b7280,stroke-width:1px,color:#000;
  classDef status fill:#f9fafb,stroke:#9ca3af,stroke-width:1px,color:#000;

  %% INPUT
  B0[User communication bot message]:::bot
  I[Create Input]:::created
  I_NEW[Input:New]:::status
  C0[Input clear]:::decision
  B1[Ask details via bot]:::bot
  I_REVIEWED[Input:Reviewed]:::status
  CL[Classify Input]:::decision

  B0 --> I
  I --> I_NEW
  I_NEW --> C0
  C0 -- No --> B1
  B1 --> I
  C0 -- Yes --> I_REVIEWED
  I_REVIEWED --> CL

  %% INTENT
  INT[Create Intent]:::created
  INT_DRAFT[Intent:Draft]:::status
  INT_R[Refine Intent]:::refine
  INT_REFINED[Intent:Refined]:::status
  INT_A[Approve Intent]:::decision
  INT_APPROVED[Intent:Approved]:::status
  INT_D[Decompose to Work Items]:::refine
  INT_COMPLETED[Intent:Completed]:::status

  CL --> INT
  INT --> INT_DRAFT
  INT_DRAFT --> INT_R
  INT_R --> INT_REFINED
  INT_REFINED --> INT_A
  INT_A --> INT_APPROVED
  INT_APPROVED --> INT_D

  %% ISSUE
  ISS[Create Issue]:::created
  ISS_REPORTED[Issue:Reported]:::status
  ISS_C[Confirm or reproduce]:::problem
  ISS_CONFIRMED[Issue:Confirmed]:::status
  F0[Plan fix]:::decision
  ISS_WONTFIX[Issue:WontFix]:::terminal
  ISS_PLANNED[Issue:Planned]:::status
  ISS_RESOLVED[Issue:Resolved]:::status
  ISS_VERIFIED[Issue:Verified]:::status
  WI_FROM_ISS[Create WorkItem]:::created

  CL --> ISS
  ISS --> ISS_REPORTED
  ISS_REPORTED --> ISS_C
  ISS_C --> ISS_CONFIRMED
  ISS_CONFIRMED --> F0
  F0 -- No --> ISS_WONTFIX
  F0 -- Yes --> ISS_PLANNED
  ISS_PLANNED --> WI_FROM_ISS

  %% WORK ITEM
  WI[Create WorkItem]:::created
  WI_KIND[Classify Work Item type]:::decision
  WI_EXP[Assign experts]:::refine
  WI_ENR[Add implementation details]:::refine
  WI_DOD[Define DoD tests checks]:::refine
  B2[Confirm DoD via bot]:::bot
  WI_BACKLOG[WorkItem:Backlog]:::status
  WI_INPROG[WorkItem:InProgress]:::status
  B_REVIEW[Ask for review]:::bot
  WI_DONE[WorkItem:Done]:::terminal
  WI_BLOCKED[WorkItem:Blocked]:::status
  B3[Explain block via bot]:::bot
  BLOCKER[Create WorkItem Blocker]:::created
  BLOCKER_BACKLOG[WorkItem:Backlog]:::status

  INT_D --> WI
  WI_FROM_ISS --> WI

  WI --> WI_KIND
  WI_KIND --> WI_EXP
  WI_EXP --> WI_ENR
  WI_ENR --> WI_DOD

  WI_DOD --> B2
  B2 --> WI_DOD

  WI_DOD --> WI_BACKLOG
  WI_BACKLOG --> WI_INPROG

  %% REVIEW AS COMMUNICATION
  WI_INPROG --> B_REVIEW
  B_REVIEW --> WI_DONE
  B_REVIEW --> WI_INPROG

  %% BLOCKED
  WI_INPROG --> WI_BLOCKED
  WI_BLOCKED --> B3

  WI_BLOCKED --> BLOCKER
  BLOCKER --> BLOCKER_BACKLOG
  BLOCKER_BACKLOG --> WI_KIND

  %% EFFECT ON INTENT AND ISSUE WHEN WORK ITEM IS DONE
  WI_DONE -- for linked Intent when goal achieved --> INT_COMPLETED
  WI_DONE -- for linked Issue --> ISS_RESOLVED
  ISS_RESOLVED --> ISS_VERIFIED

  %% UNBLOCKING EFFECT WHEN BLOCKER IS DONE
  WI_DONE -- for blocked WorkItem --> WI_INPROG
```
