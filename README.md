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
/mahas-ai-kit:setup --add ticket  # add one module to an existing setup
/mahas-ai-kit:setup --update   # check an existing setup against the current code; adopts a hand-made setup without renaming it
```

## Choices during setup

Setup recommends an answer for each choice from what it finds in the repo. Accept all recommendations in one step, or choose one by one.

| Choice | Options | Recommended from |
|---|---|---|
| Git flow | direct, branch, pull request | Branch names, PR merges in the history, the PR CLI installed |
| Tickets | Trello, Jira, GitHub Issues, none | Servers in `.mcp.json`, ticket codes in commit subjects |
| Operations | Play Store deploy, App Store deploy, crash triage | Release signing, bundle id, crash SDK |

Jira, GitHub Issues, and pull requests on hosts other than GitHub are experimental: written, not yet run on a real project. The kit never installs an MCP server and never writes a token.

## After setup

```
/plan <request>      # plan and design, no code changes
/pipeline <request>  # plan → design → code → test → review, until approved
/test [--check]      # run the gate and fix failures; --check only reports
/review-changes      # read-only review of the pending changes
/pr                  # push the branch and open a pull request (pull-request flow only)
```

Generated only when the code shows the evidence, and only after you accept each one:

```
/deploy-playstore    # Android app with release signing
/deploy-appstore     # iOS app
/crashes             # crash SDK plus a way to read its reports
```

## What gets created in your project

| Part | Contents |
|---|---|
| `CLAUDE.md` | At most 40 lines: what the project is, its hard rules, commands proven to run |
| `.claude/.agent/` | Deep docs; the only place project knowledge is written down |
| `.claude/skills/stack-*` | At most 3–4 skills that only point into the docs |
| `.claude/agents/` | planner, architect, developer, tester, reviewer; plus deployers and crash-fixer when the evidence is there |
| `.claude/commands/` | `/plan`, `/pipeline`, `/test`, `/review-changes`; plus deploy and crash commands when the evidence is there |
| `.claude/skills/process-*` | Planning, design, and review rules; git delivery and ticket rules for the options you chose |
| `.claude/kit.json` | What was generated and which options were chosen; read by `--update` and `--add` |
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
