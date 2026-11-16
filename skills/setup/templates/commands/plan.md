---
description: Planning only — the Planner writes the plan, then the Architect writes the technical design; no code is changed
argument-hint: "<requirement or task description>"
allowed-tools: Task, Read, Grep, Glob, Bash, AskUserQuestion
---

Plan and design this requirement WITHOUT implementing any code:

$ARGUMENTS

1. Spawn the `planner` agent (Task tool) with the requirement verbatim.
2. Spawn the `architect` agent with the requirement + the full planner output. (Lite tier: skip this step.)
3. Present both to the user in their language — plan first, then design — and offer to run `/pipeline` with this requirement or to implement it directly.
4. If the `process-ticket-offer` skill exists, follow it for open questions and out-of-scope work.

Do not edit any files. Do not start implementation unless the user asks afterwards.
