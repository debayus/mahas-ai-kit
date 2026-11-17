---
name: process-code-review
description: Review checklist, noise rules, and APPROVED/CHANGES_REQUIRED verdict format for the Reviewer stage of {{PROJECT_NAME}}. Load when performing a final implementation review.
---

# Code review checklist — {{PROJECT_NAME}}

## Procedure

1. `git status` + `git diff` for the true change surface; read changed files in full.
2. Walk **every acceptance criterion**: point at the code/tests satisfying it, or flag it unmet.
3. Sweep the dimensions below.

## Dimensions

| Dimension | What to probe |
|---|---|
| Requirements | Every criterion met; no scope drift in either direction |
| Correctness | Logic bugs; {{EDGE_CASES}} |
| Regression | Callers/consumers of every modified symbol; changed defaults |
| Project invariants | {{INVARIANTS_CHECK}} |
| Security | Data leaking across role/tenant boundaries, injection, secrets in code or logs |
| Performance | Repeated queries in loops, unindexed lookups, repeated work on a hot path, blocking I/O |
| Maintainability | Duplication of existing components, naming, dead code, test quality |

## Noise rules (keep review loops short)

- Report only findings you are at least 80% sure of. State the evidence.
- Merge similar findings into one issue with a count and the locations.
- Review the changed code. Flag untouched code only for a security or data-loss blocker.
- Style preferences go to `Notes`, never to `Issues`, unless they break a written project convention.
- Do not ask for work outside the acceptance criteria.

## Verdict format

```
VERDICT: APPROVED | CHANGES_REQUIRED

Acceptance criteria: <n>/<total> met  (list any unmet)

Issues (only when CHANGES_REQUIRED):
- [blocker|major|minor] <file:line> — what's wrong → what "fixed" looks like

Notes (non-blocking):
- ...
```

**APPROVED** requires: all criteria met, tests green, zero blocker/major issues.
