---
name: process-ticket-offer
description: Rules for offering {{TRACKER}} tickets for findings left unresolved in this run — only when they affect users, are critical bugs, or mean a feature does not match its design. The main session must ask the user before creating any ticket. Load when closing a /pipeline or /plan run that leaves findings open.
---

# Ticket offer — {{PROJECT_NAME}}

Open findings must not get lost, but tickets are **never created without the user's approval**.

## What qualifies

Only findings that are still open AND are one of: (1) directly felt by users, (2) a critical bug in usage, calculation, data, or security, (3) a feature that does not meet its acceptance criteria.

Not candidates: anything already fixed, nits and refactors, flaky tests (unless they expose a product bug), warnings, hypothetical risks.

Nothing qualifies → write `Ticket candidates: none` and do not ask.

## Subagents

Never create tickets. End the report with:

```
Ticket candidates:
1. [severity: high|medium|low] [category] <short title>
   - Location / Problem / Proposed fix / Evidence
```

## Main session

1. Collect the candidates, drop duplicates, and filter again with the criteria above.
2. Ask the user with AskUserQuestion (multiSelect, one option per candidate; more than 4 → offer "all", "high only", "let me pick", "none").
3. For approved ones: check for an existing ticket first, then create it in {{TRACKER}}. Description: Context, Problem, Location, Evidence, Done criteria.
4. Report which tickets were created and which were skipped. If the tracker is not connected, show the candidates as paste-ready text.
