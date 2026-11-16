# Generation rules

## Tiers

| Tier | When | What is generated |
|---|---|---|
| **lite** | Under ~40 source files, or no automated tests | `CLAUDE.md`, `.agent/overview.md` + `conventions.md`, one stack skill, `reviewer` agent, `process-code-review`, `/plan` (planner only), format hook |
| **standard** | 40–300 source files with tests | lite + `architecture.md`, `testing.md`, `glossary.md` if needed, up to 3 stack skills, all 5 agents, `process-planning`, `process-tech-design`, `/pipeline`, `/plan`, workflow, both hooks |
| **full** | Over ~300 source files, or persistent data with migrations/sync, or multiple roles/tenants | standard + `data-model.md`, a data stack skill, `workflows.md` (release/ops runbooks found in the repo), `process-ticket-offer` if a tracker is connected |

Add a piece from a higher tier when the code clearly needs it; drop a piece when it does not apply. State each such decision in the plan.

## Size limits (hard)

| File | Limit |
|---|---|
| `CLAUDE.md` | 40 lines; at most 6 hot rules |
| Stack skill | 50 lines; at most 8 hard rules |
| Process skill | 60 lines |
| Agent | 45 lines |
| Command | 30 lines |
| `.agent/*.md` | As long as needed, but no section without a file reference |

Stack skills: at most 3 (4 in full tier). A skill exists only if at least two agents need it.

## Writing rules

- A hard rule = an imperative + the reason in one clause + a link to the file that proves it. No rule without the link.
- Use exact commands that ran successfully in Step 2. Mark a command "unverified" if it could not be run (e.g. needs a device).
- Link to source files with relative Markdown links instead of quoting code.
- Do not restate what the linter, formatter, or CI already enforces — name the gate once in CLAUDE.md.
- Never write secret values, tokens, or real credentials. Refer to the env mechanism only.
- No emoji, no marketing language, no "best practice" lists.

## Placeholders

| Placeholder | Fill with |
|---|---|
| `{{PROJECT_NAME}}` | Product name |
| `{{PROJECT_ONE_LINER}}` | One sentence: what it is, stack, where data lives |
| `{{HOT_RULES}}` | Up to 6 invariants, each with a proving link |
| `{{STACK_SKILLS}}` | Names of the generated `stack-*` skills, with when to load each |
| `{{PROJECT_RISKS}}` | The structural risks specific to this code (for planner/reviewer) |
| `{{EDGE_CASES}}` | The edge cases this product always has (roles, offline, old versions, empty state…) |
| `{{INVARIANTS_CHECK}}` | One line listing the invariants the reviewer must verify |
| `{{ANALYZE_CMD}}` `{{FORMAT_CHECK_CMD}}` `{{FORMAT_FILE_CMD}}` `{{TEST_CMD}}` `{{E2E_CMD}}` | Verified commands; delete the line if the project has none |
| `{{LAYER_FILE_MAP}}` | The real layer order with real paths, for the design template |
| `{{DATA_SECTION}}` | Migration + data-flow checklist, or delete the section if no persistent data |
| `{{COMMIT_STYLE}}` | Commit convention seen in `git log`, and the message language |
| `{{TRACKER}}` | Tracker name, board/list/label; delete ticket parts if none |
| `{{MODEL_PLANNER}}` `{{MODEL_DESIGN}}` `{{MODEL_BUILD}}` `{{MODEL_REVIEW}}` | Default `fable`, `opus`, `sonnet`, `opus`. In lite tier use `sonnet` for build and `opus` for review only |

## Tooling proposals (offer, never force)

- **Formatter hook** — always, when the stack has a formatter.
- **Protected paths hook** — when the repo has files that must not be hand-edited: applied migration files, generated code, lockfiles, secret files. List them in `.claude/hooks/protected-paths.txt`.
- **Stricter static analysis** — Dart: `strict-casts`, `strict-inference`, `strict-raw-types`, lint `unawaited_futures`. TypeScript: `strict`, `noUncheckedIndexedAccess`. Python: enable the type checker already in the repo. Measure new findings before and after; report the count.
- **Rules that became enforceable** — if a hot rule can be a lint or a hook, propose that and shorten the prose.
