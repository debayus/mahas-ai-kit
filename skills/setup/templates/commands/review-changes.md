---
description: Review the pending changes (uncommitted + commits not yet on the default branch) for bugs and rule violations; read-only report
argument-hint: "[file or path to scope the review]"
allowed-tools: Task, Bash, Read, Grep, Glob, AskUserQuestion
---

Review the code changes on the current branch of **{{PROJECT_NAME}}** and report findings. Read-only — do not edit code.

Scope: $ARGUMENTS

1. Work out the review set:
   ```bash
   BASE=$(git merge-base HEAD {{DEFAULT_BRANCH}} 2>/dev/null)
   git --no-pager diff "$BASE"...HEAD --stat   # committed on this branch
   git --no-pager status --short               # uncommitted
   ```
   On `{{DEFAULT_BRANCH}}` itself, review the uncommitted changes only. Nothing to review → say so and stop.
2. Delegate to the `reviewer` agent with the review set and the scope. Tell it there are no acceptance criteria for this run: it reviews against the project invariants and the `process-code-review` checklist, including the noise rules, and returns findings instead of a verdict loop.
3. Report in the user's language, grouped by severity, each finding as `file:line — what is wrong — why it matters — suggested fix`. End with one line: clean, or the number of issues and whether the change looks ready to merge. A clean diff is a valid result.
4. If the `process-ticket` skill exists, follow it for findings the user will not fix now.
