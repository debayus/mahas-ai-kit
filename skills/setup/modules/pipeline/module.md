# Module: pipeline

Decides whether the kit generates its own way of working (Planner → Architect → Developer → Tester → Reviewer), or only the knowledge about this repository. A team that already works with a workflow framework (Superpowers, Spec Kit, BMAD, OpenSpec) keeps that framework and takes the knowledge layer from the kit.

## Options

| Option | Meaning | Generates |
|---|---|---|
| `kit` | The kit's pipeline, sized by the tier | the agents, process skills, commands, and workflow of the tier |
| `none` | Knowledge layer only | `CLAUDE.md`, the deep docs, the stack skills, the hooks, `.claude/README.md`, `kit.json`. No agent, no process skill, no command, no workflow |

This module has no templates of its own: it switches the core templates on or off.

## Recommendation (scan section "Existing Claude setup", and this session's skills)

Apply the first rule that matches and quote its evidence in the question:

1. The scan lists a workflow framework folder (`.specify/`, `.bmad-core/`, `_bmad/`, `openspec/`) → `none`.
2. This session lists skills of a workflow framework (names that start with `superpowers:`, `speckit`, or `bmad`) → `none`. The scan cannot see user-level plugins, so check the skill list yourself.
3. Otherwise → `kit`. Do not ask; say in the plan that `--no-pipeline` gives the knowledge layer only.

`--no-pipeline` on the command line selects `none` without asking.

## Question

"Should the kit generate its own pipeline, or only the knowledge about this repository?" — options in recommended order, naming the framework that was found.

## Rules

- With `none`, the `git-flow` module is not asked, as in tier lite, and `{{STACK_SKILLS}}` and `{{TEST_GUIDE}}` have no agent to go into: write them into `CLAUDE.md` under the hot rules as one line, "Load `stack-<topic>` before <when>".
- With `none`, the modules `ticket`, `testing`, and `database` are still offered. Their files stand on their own; delete the lines in them that refer to `/pipeline`, `/test`, or a pipeline agent.
- The tier still decides which deep docs and how many stack skills are generated.
- Update mode: a setup recorded with `none` is never offered pipeline pieces again unless the user asks.
- Record the option in `.claude/kit.json` under `modules`. In update mode, a pipeline the project made itself is recorded as `"own"`, with its files under `adopted`.
