---
name: process-planning
description: Plan template and quality bar for the Planner stage — tasks, dependencies, risks, edge cases, and acceptance criteria for a {{PROJECT_NAME}} change. Load when producing or evaluating an execution plan.
---

# Planning template — {{PROJECT_NAME}}

A plan is good when the next stage can work from it **without asking the user anything**.

## 1. Requirement

Business intent (what the user gets) + technical implication. One short paragraph.

## 2. Tasks

```
T1  <title> — <one-line detail>            (depends on: —)
T2  <title> — <one-line detail>            (depends on: T1)
```

Small, ordered, independently verifiable. Include test tasks, and an explicit migration task if stored data changes. Never include a commit, push, or tag task — the main session commits after APPROVED.

## 3. Risks

Always consider: {{PROJECT_RISKS}}

## 4. Edge cases

Minimum sweep: {{EDGE_CASES}}

## 5. Acceptance criteria

Concrete, testable, unambiguous — they become the Reviewer's checklist.

- Good: states an observable result and where to see it.
- Bad: "works correctly".

Criteria checked by text search must not match comment lines; say which files and which pattern.

## 6. Open questions / assumptions

Prefer a stated assumption over a blocking question.
