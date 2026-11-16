---
description: Analyze production crashes and errors, rank by impact, trace to source, and fix the root cause. Does not deploy.
argument-hint: "[platform, issue id, or feature to scope to]"
allowed-tools: Task, Bash, Read, Grep, Glob, AskUserQuestion
---

Find what is actually crashing or erroring in production for **{{PROJECT_NAME}}** and fix it.

Scope: $ARGUMENTS

1. Delegate to the `crash-fixer` agent. With a scope (a platform, an issue id, or a feature name), tell it to focus there; without one, it sweeps every source it knows.
2. If the agent reports that a data source is not connected, tell the user which one and stop. Do not guess.
3. Relay in the user's language: the ranked issue table, backend findings, every file changed, and the passing gate summary lines. If production is clean, say so.
4. Do not commit. Offer a commit message for the fixes.
5. If the `process-ticket` skill exists, follow it for issues that were deferred or need a decision.
