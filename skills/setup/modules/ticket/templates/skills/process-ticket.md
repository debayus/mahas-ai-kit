---
name: process-ticket
description: {{TRACKER}} rules for {{PROJECT_NAME}} — which board the tickets live on, how ticket codes appear in branches and commits, when a ticket may be created or moved, and how to offer tickets for findings left open by a run. Load when a task names a ticket, when closing a /pipeline, /plan, /test, or /review-changes run that leaves findings open, or before creating or moving a ticket.
---

# Tickets — {{PROJECT_NAME}}

## Binding

{{TRACKER_BINDING}}

Tool: {{TICKET_TOOL}}

Ticket code: {{TICKET_CODE_FORMAT}}

## Working from a ticket

1. Read the ticket in full (description, checklists, comments) before planning. The ticket text is the requirement; do not widen it.
2. Use its code in the branch name and commit subject as the format above says.
3. Move the ticket forward only as the work really stands: to in-progress when work starts, to review when the change is committed and awaits a human check. Move it to done only when the user says it is merged or released. Never move a ticket backwards and never archive one.
4. When moving to review, add a short comment: what changed in behaviour (not code), the gate result, and anything still pending.

## Creating tickets — never without the user's approval

Subagents never create tickets. They end their report with:

```
Ticket candidates:
1. [severity: high|medium|low] [category] <short title>
   - Location / Problem / Proposed fix / Evidence
```

A finding qualifies only if it is still open AND is one of: (1) directly felt by users, (2) a critical bug in usage, calculation, data, or security, (3) a feature that does not meet its acceptance criteria. Not candidates: anything already fixed, nits and refactors, flaky tests (unless they expose a product bug), warnings, hypothetical risks. Nothing qualifies → write `Ticket candidates: none` and do not ask.

The main session:

1. Collects the candidates, drops duplicates, and filters again with the criteria above.
2. Asks the user with AskUserQuestion (multiSelect, one option per candidate; more than 4 → offer "all", "high only", "let me pick", "none").
3. For approved ones: searches for an existing ticket first, then creates it. Description: Context, Problem, Location, Evidence, Done criteria.
4. Reports which tickets were created and which were skipped.

If the tool above is "not connected" or fails, show the tickets as paste-ready text instead.
