# mahas-ai-kit

One command to set up Claude in a project: the code is analyzed first, then a complete but lean configuration is generated to match it.

## Quick start: copy this prompt

Open your project in Claude Code, pick the Fable model (`/model`), then paste:

```
Clone https://github.com/debayus/mahas-ai-kit into a temporary folder outside this project.
Read skills/setup/SKILL.md inside it and follow its steps for this project.
Show me the plan and wait for my approval before creating any file.
```

Claude scans the code, reads the parts it needs, takes templates from this kit, shows you a plan, and after you approve creates the agents, skills, commands, and hooks in your project.

## Permanent install: as a plugin

Once, in Claude Code:

```
/plugin marketplace add debayus/mahas-ai-kit
/plugin install mahas-ai-kit@mahas
```

Then in each project:

```
/mahas-ai-kit:setup            # analyze, show the plan, wait for approval, then generate
/mahas-ai-kit:setup --dry-run  # analysis and plan only
/mahas-ai-kit:setup --lite     # force the light version
/mahas-ai-kit:setup --update   # check an existing setup against the current code
```

## After setup

```
/plan <request>      # plan and design, no code changes
/pipeline <request>  # plan → design → code → test → review, until approved
```

## What gets created in your project

| Part | Contents |
|---|---|
| `CLAUDE.md` | At most 40 lines: what the project is, its hard rules, commands proven to run |
| `.claude/.agent/` | Deep docs; the only place project knowledge is written down |
| `.claude/skills/stack-*` | At most 3–4 skills that only point into the docs |
| `.claude/agents/` | planner, architect, developer, tester, reviewer |
| `.claude/commands/` | `/plan` and `/pipeline` |
| `.claude/workflows/` | The pipeline with loop caps (4 test rounds, 3 review rounds) |
| `.claude/hooks/` | Auto-format after edits; block edits to protected files |

## Why it stays cheap

- The plugin adds a single skill description to the context. Everything else is read only when setup runs.
- The first scan is a script, not the model.
- Only the parts that match the code are generated; small projects get the light version.
- Rules a formatter, linter, or hook can enforce are not written as prose.
- The reviewer has noise rules, so there are fewer fix rounds.
- `verify.sh` checks the result (size limits, links, placeholders, JSON, hooks).

## What it never does

It does not overwrite existing files, commit, copy secret values, or change analyzer settings without approval.
