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
/mahas-ai-kit:setup --no-pipeline  # knowledge about the repo only; keep your own way of working
/mahas-ai-kit:setup --add ticket  # add one module to an existing setup
/mahas-ai-kit:setup --update   # check an existing setup against the current code; adopts a hand-made setup without renaming it
```

## Choices during setup

Setup recommends an answer for each choice from what it finds in the repo. Accept all recommendations in one step, or choose one by one.

| Choice | Options | Recommended from |
|---|---|---|
| Pipeline | the kit's pipeline, or knowledge only | A workflow framework already in use (Superpowers, Spec Kit, BMAD, OpenSpec) |
| Git flow | direct, branch, pull request | Branch names, PR merges in the history, the PR CLI installed |
| Tickets | Trello, Jira, GitHub Issues, none | Servers in `.mcp.json`, ticket codes in commit subjects |
| Database | none, files only, read a live database | Migration and rules files, servers in `.mcp.json`, database CLIs |
| Testing | gate only, fill gaps in existing levels, extended levels | Test files per level, test tools, coverage signals |
| Operations | Play Store deploy, App Store deploy, crash triage | Release signing, bundle id, crash SDK |

Jira, GitHub Issues, extended test levels, SQL databases other than Supabase and Firebase, and pull requests on hosts other than GitHub are experimental: written, not yet run on a real project. The kit never installs an MCP server and never writes a token.

## What a run looks like

`--dry-run` prints the plan and stops. A shortened example for a small web app (illustrative, not a real project):

```
Found: React 19 + Vite + TypeScript, data in Firestore, 19 source files, no tests.
       CI deploys to hosting on every push to main.
Tier:  lite (under 40 source files, no tests)

Hard rules, each with the file that proves it
  1. A push to main goes live              .github/workflows/deploy.yml
  2. All data access goes through one file  src/services/dataService.ts
  3. UI text lives in one place, two languages  src/context/LanguageContext.tsx

Will create
  CLAUDE.md, .claude/.agent/{README,overview,conventions}.md
  .claude/skills/stack-react-firebase, process-planning, process-code-review
  .claude/agents/{planner,reviewer}.md, .claude/commands/{plan,review-changes}.md
  .claude/hooks/protect-files.sh   (protects .env and the lockfile)

Left out, and why
  architect, developer, tester, /pipeline, /test   tier lite
  format hook                                      no formatter in the repo
  deploy and crash pieces                          no mobile app, no crash SDK

Choices (recommended)
  tickets   none   no ticket codes in the last 200 commit subjects
  testing   none   no test files found
  database  none   Firestore is used in 2 files, but no rules file is in the repo

Checked: `npx tsc --noEmit` passes (9 s). Not run: `npm run build` (writes output).
```

After generating, `verify.sh` checks the result and setup fixes what it flags before reporting:

```
ok:   CLAUDE.md (31 lines)
ok:   4 hot rules
ok:   no leftover placeholders
ok:   protect-files.sh wired in settings.json
ok:   all relative links resolve
RESULT: PASS
```

## Already using Superpowers, Spec Kit, or BMAD?

Those tell Claude how to work; they are the same in every project. This kit writes down what is true about one repository: its layers, its hard rules, the commands that run, the files that must not be edited. Use `--no-pipeline` to get that part only (`CLAUDE.md`, the deep docs, the stack skills, the hooks) and keep the workflow you have. Setup recommends this on its own when it finds such a framework.

## What it has been tried on

The kit is young. This is what has actually been run, so you can judge how far to trust it on your stack.

| Stack | Scan | Dry-run of the full setup |
|---|---|---|
| Flutter with Supabase and Firebase | yes | yes, including adoption of a hand-made setup |
| React + Vite + TypeScript with Firestore | yes | yes |
| Node.js + TypeScript tool (MCP server), no git repository | yes | yes |
| Godot 4 (GDScript) with Python tooling | yes | yes, adoption |
| Astro static site | yes | no |
| Next.js, Django, FastAPI, Go, Rust, .NET | fixtures only, or not at all | no |

A dry-run follows every step up to the plan and checks it against `verify.sh`; it stops before writing files. Each of these runs turned up defects. The ones that could be reproduced are fixed and covered by `tests/run.sh`. Expect more on a stack that is not listed: start with `--dry-run`, and please report what looks wrong.

## After setup

```
/plan <request>      # plan and design, no code changes
/pipeline <request>  # plan → design → code → test → review, until approved
/test [--check]      # run the gate and fix failures; --check only reports
/review-changes      # read-only review of the pending changes
/pr                  # push the branch and open a pull request (pull-request flow only)
/test-gaps           # find untested behaviour and write the missing tests (testing module)
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
| `.claude/agents/` | planner, architect, developer, tester, reviewer; plus `test-gap`, deployers, and crash-fixer when chosen and the evidence is there |
| `.claude/commands/` | `/plan`, `/pipeline`, `/test`, `/review-changes`; plus deploy and crash commands when the evidence is there |
| `.claude/skills/process-*` | Planning, design, and review rules; git delivery, ticket, and database rules for the options you chose |
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

It does not overwrite existing files, commit, copy secret values, change analyzer settings without approval, install an MCP server, or add a dependency.

## Working on the kit

```bash
bash tests/run.sh
```

The tests build setups from the templates for each combination of choices and run `verify.sh` on them, check that `verify.sh` rejects broken setups, and run `detect.sh` on small repositories made for the test. They need bash, git, and python3, and write only to a temporary folder.

## License

MIT. See [LICENSE](LICENSE). The files the kit generates in your project are yours, with no conditions.
