---
name: user-survey
description: Reads a markdown file describing what needs to be clarified, conducts a conversational survey with the user, and outputs the result in markdown format.
arguments:
  - name: file
    required: true
    description: "Path to markdown file describing what to clarify"
---

# User Survey

A utility skill that conducts a conversational survey based on a markdown description file.

## Flow Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  Step 1: Read Description File                                   │
│  Load markdown file that describes what needs to be clarified    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Step 2: Analyze Content                                         │
│  Identify topics, questions, and information gaps                │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Step 3: Conduct Survey                                          │
│  Ask open question, then targeted follow-ups for gaps            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Step 4: Output Result                                           │
│  Print collected information in markdown format                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Usage

```yaml
invoke: user-survey
file: "plugins/crunch/data/surveys/project-info.md"
```

---

## Description File Format

The description file is a simple markdown document that describes:
- What topic needs clarification
- What specific information is needed
- Examples of good answers (optional)

### Example: `project-info.md`

```markdown
# Project Info

We need to understand the project's purpose and goals.

## What to Clarify

- **Project name** - What is the project called?
- **Goal** - What is the main purpose? (one sentence)
- **Problem** - What problem does this solve?
- **Target users** - Who will use this?
- **Objectives** - What are 3-5 specific outcomes?

## Optional

- Success criteria - How will you measure success?
- Constraints - Any limitations or boundaries?
- Out of scope - What is explicitly NOT included?

## Examples

**Good goal statement:**
> Build a real-time analytics dashboard for e-commerce metrics

**Good problem statement:**
> Merchants lack visibility into real-time sales data, causing delayed decision-making
```

---

## Definition of Done

The survey is complete when:

1. Description file has been read and analyzed
2. User has answered the main open question
3. All required topics have been covered (via follow-ups if needed)
4. Result is output in markdown format

---

## Workflow

### Step 1: Read Description File

```bash
cat "{file_path}"
```

Parse the markdown to identify:
- **Title** - From H1 heading
- **Context** - Introductory text
- **Required topics** - Items under "What to Clarify" or similar
- **Optional topics** - Items under "Optional" section
- **Examples** - Sample answers for guidance

### Step 2: Analyze Content

Extract topics to ask about:

```typescript
interface Topic {
  name: string;        // e.g., "Goal"
  description: string; // e.g., "What is the main purpose?"
  required: boolean;   // true if under required section
  example?: string;    // sample answer if provided
}

const topics = parseTopics(fileContent);
// Result:
// [
//   { name: "Project name", description: "What is the project called?", required: true },
//   { name: "Goal", description: "What is the main purpose?", required: true },
//   { name: "Success criteria", description: "How will you measure success?", required: false },
//   ...
// ]
```

### Step 3: Conduct Survey

#### Step 3.1: Ask Open Question

Generate an open question based on the topics:

```
Tell me about your project.

I'd like to understand:
- What it's called and what it does
- What problem it solves and who it's for
- What the key objectives are

Feel free to share as much or as little as you'd like - I'll ask follow-up questions for anything I need to clarify.
```

Wait for user's free-form response.

#### Step 3.2: Parse Response

Analyze the user's response to identify which topics were covered:

```typescript
const covered: Topic[] = [];    // Topics answered
const missing: Topic[] = [];    // Topics not mentioned
const unclear: Topic[] = [];    // Topics mentioned but need clarification

for (const topic of topics) {
  const status = analyzeTopicCoverage(userResponse, topic);
  if (status === 'covered') covered.push(topic);
  else if (status === 'unclear') unclear.push(topic);
  else missing.push(topic);
}
```

#### Step 3.3: Ask Follow-up Questions

For each missing or unclear **required** topic:

```typescript
// For missing required topics
AskUserQuestion({
  questions: [{
    question: `I didn't catch the ${topic.name}. ${topic.description}`,
    header: topic.name,
    options: [
      { label: "Let me explain", description: "I'll provide details" },
      { label: "Skip for now", description: "Come back to this later" }
    ],
    multiSelect: false
  }]
})

// For unclear topics
AskUserQuestion({
  questions: [{
    question: `Could you clarify the ${topic.name}? ${clarificationNeeded}`,
    header: topic.name,
    options: [
      { label: "Sure", description: "I'll clarify" },
      { label: "Keep as is", description: "What I said is correct" }
    ],
    multiSelect: false
  }]
})
```

For optional topics, only ask if user seems willing to provide more detail.

### Step 4: Output Result

Print the collected information in markdown format:

```markdown
## Project Info

**Name:** Acme Dashboard

**Goal:** Build a real-time analytics dashboard for e-commerce metrics

**Problem:** Merchants lack visibility into real-time sales data, causing delayed decision-making

**Target Users:** E-commerce store owners and their operations teams

**Objectives:**
- Display real-time revenue and order counts
- Show conversion funnel visualization
- Enable custom date range filtering
- Support multiple store connections

**Success Criteria:**
- Dashboard loads in under 2 seconds
- Data updates within 30 seconds of transaction

**Constraints:**
- Must integrate with Shopify API
- Budget limited to open-source tools
```

---

## Output Format

The output follows this structure:

```markdown
## {Title from H1}

**{Topic 1}:** {Answer}

**{Topic 2}:** {Answer}

**{Topic with list answer}:**
- Item 1
- Item 2
- Item 3

{For optional topics that were answered:}
**{Optional Topic}:** {Answer}
```

---

## Conversation Style

### Open and Friendly

```
Tell me about your project - I'm curious to learn what you're building!
```

### Acknowledge What Was Shared

```
Got it! So you're building a dashboard for e-commerce analytics.
That's a great use case.

I have a few follow-up questions...
```

### Targeted Follow-ups

```
You mentioned the target users are "store owners" - could you be more
specific? For example, are these small independent shops, enterprise
retailers, or both?
```

### Confirm Understanding

```
Let me make sure I've captured this correctly:

[Show summary]

Does this look right?
```

---

## Error Handling

| Situation                  | Response                                      |
|----------------------------|-----------------------------------------------|
| File not found             | Show error, suggest checking path             |
| File has no clear topics   | Ask user what they'd like to discuss          |
| User response too brief    | Ask gentle follow-up for more detail          |
| User wants to skip topic   | Mark as skipped, continue with others         |
| User provides conflicting info | Point out conflict, ask for clarification |

---

## Interactive Checkpoints

| Step | Checkpoint                                           |
|------|------------------------------------------------------|
| 3.1  | Open question based on description file              |
| 3.3  | Follow-up questions for missing required topics      |
| 4    | Show final result, ask for confirmation              |

---

## Example Session

```
User: /user-survey plugins/crunch/data/surveys/project-info.md

Claude: Tell me about your project!

I'd like to understand what you're building - the name, main goal,
who it's for, and what problem it solves. Feel free to share as
much as you'd like.

User: We're building a tool called DataSync that helps small
businesses sync their inventory across multiple sales channels.
Right now they have to manually update stock levels in each
platform which is error-prone and time-consuming.

Claude: DataSync sounds useful! So the core problem is manual
inventory updates across platforms.

A couple of quick follow-ups:
- What are the key objectives or features you want to deliver?
- Who specifically will use this - the business owners, their
  staff, or both?

User: The main features are automatic sync when stock changes,
alerts for low inventory, and a dashboard to see everything in
one place. Mainly for small business owners who sell on multiple
platforms like Shopify, Amazon, and Etsy.

Claude: Perfect, I've got a clear picture now. Here's what I captured:

## Project Info

**Name:** DataSync

**Goal:** Help small businesses sync inventory across multiple sales channels

**Problem:** Manual inventory updates across platforms are error-prone and time-consuming

**Target Users:** Small business owners selling on multiple platforms (Shopify, Amazon, Etsy)

**Objectives:**
- Automatic sync when stock changes
- Low inventory alerts
- Unified dashboard for all channels

Does this look right?

User: Yes, that's perfect!

Claude: Great! Here's the final result:

[Outputs markdown above]
```
