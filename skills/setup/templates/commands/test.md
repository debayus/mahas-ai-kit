---
description: Run the verification gate (static checks + tests) and fix failures until green; --check only reports
argument-hint: "[--check] [--e2e] [file or area to scope]"
allowed-tools: Task, Bash, Read, Grep, Glob, AskUserQuestion
---

Run the **{{PROJECT_NAME}}** verification gate outside the pipeline.

Arguments: $ARGUMENTS

**With `--check` (read-only):** run `{{ANALYZE_CMD}}`, `{{FORMAT_CHECK_CMD}}`, and `{{TEST_CMD}}` yourself, in that order, capturing the full output. Edit nothing. Report each stage as passed or failed with its summary line, then group the failures by likely root cause.

**Without `--check`:** delegate to the `tester` agent. Pass the scope, and tell it there are no acceptance criteria for this run: its job is to get the existing suite green. It fixes compile, lint, format, and test-infrastructure errors and stale tests; it returns red with a diagnosis for product-logic defects. Never accept a weakened test (a deleted assertion, a loosened matcher, a skip) as a fix.

Add end-to-end (`{{E2E_CMD}}`) only with `--e2e`.

Report in the user's language: per-stage status, every file changed with a one-line reason (product code separated from test code), the final passing summary lines as proof, and anything left red with its diagnosis. Never report green if a stage failed or was skipped. Do not commit.

If the `process-ticket` skill exists, follow it for product bugs left open.
