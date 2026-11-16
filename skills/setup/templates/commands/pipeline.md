---
description: Run the full pipeline — Planner → Architect → Developer → Tester → Reviewer until APPROVED, then commit and prepare a PR
argument-hint: "<requirement or task description> [--e2e]"
allowed-tools: Workflow, TaskOutput, TaskStop, Bash, Read, Grep, Glob, Task, AskUserQuestion
---

Run the full engineer pipeline on this requirement:

$ARGUMENTS

## Steps

1. Check `git status`. If there are unrelated uncommitted changes, warn the user and ask whether to proceed.
2. Call the **Workflow** tool with `{name: "engineer-pipeline", args: {task: "<the requirement, verbatim>"}}`. Add `"e2e": true` only if the user passed `--e2e`. Wait for completion.
3. Relay to the user in their language: plan summary, design approach, files changed, tester status, review verdict.

## After the workflow returns

**`APPROVED`:**

1. Cross-check every acceptance criterion against the final `git diff` yourself. If one looks unmet, treat it as not approved and say so.
2. Confirm the tester report is green and quote its summary line.
3. Commit following the `process-git-delivery` skill.
4. Do not push or merge on your own. Tell the user the next delivery step the skill defines (in a pull-request flow: `/pr`).
5. If the `process-ticket` skill exists, follow it for leftover findings.

**`NOT_APPROVED` or `BLOCKED_TESTS_RED`:** do not commit. Report the remaining issues or failing tests verbatim and which loop cap was hit, then ask how to proceed (raise the caps, narrow the scope, or take over manually).
