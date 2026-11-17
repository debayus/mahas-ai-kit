---
<!-- option: standard full -->
description: Planning only — the Planner writes the plan, then the Architect writes the technical design; no code is changed
<!-- /option -->
<!-- option: lite -->
description: Planning only — the Planner writes the plan; no code is changed
<!-- /option -->
argument-hint: "<requirement or task description>"
allowed-tools: Task, Read, Grep, Glob, Bash, AskUserQuestion
---

Plan this requirement WITHOUT implementing any code:

$ARGUMENTS

1. Spawn the `planner` agent (Task tool) with the requirement verbatim.
<!-- option: standard full -->
2. Spawn the `architect` agent with the requirement + the full planner output.
3. Present both to the user in their language — plan first, then design — and offer to run `/pipeline` with this requirement or to implement it directly.
<!-- /option -->
<!-- option: lite -->
2. Present the plan to the user in their language and offer to implement it directly.
<!-- /option -->
- If the `process-ticket` skill exists, follow it for open questions and out-of-scope work.

Do not edit any files. Do not start implementation unless the user asks afterwards.
