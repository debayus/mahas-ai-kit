# Generation rules

## Tiers

| Tier | When | What is generated |
|---|---|---|
| **lite** | Under ~40 source files, or no automated tests | `CLAUDE.md`, `.agent/overview.md` + `conventions.md`, one stack skill, `reviewer` agent, `process-code-review`, `/plan` (planner only), `/review-changes`, format hook |
| **standard** | 40–300 source files with tests | lite + `architecture.md`, `testing.md`, `glossary.md` if needed, up to 3 stack skills, all 5 agents, `process-planning`, `process-tech-design`, `/pipeline`, `/plan`, `/test`, workflow, both hooks |
| **full** | Over ~300 source files, or persistent data with migrations/sync, or multiple roles/tenants | standard + `data-model.md`, a data stack skill, `workflows.md` (release/ops runbooks found in the repo) |

Add a piece from a higher tier when the code clearly needs it; drop a piece when it does not apply. State each such decision in the plan.

## Operations pieces (any tier, evidence only)

These are independent of the tier. Generate one only when the scan's "Release and operations signals" section shows its evidence, and list each one in the plan so the user can decline it.

| Piece | Evidence required | Files |
|---|---|---|
| Play Store deploy | An Android app with release signing configured (a `key.properties` or signing config the gradle file reads) | `agents/playstore-deployer.md`, `commands/deploy-playstore.md` |
| App Store deploy | An iOS app folder with a bundle identifier | `agents/appstore-deployer.md`, `commands/deploy-appstore.md` |
| Crash triage | A crash SDK in the manifest AND a way to read its reports from this machine (an MCP server in `.mcp.json` or a CLI) | `agents/crash-fixer.md`, `commands/crashes.md` |

Rules for these pieces:

- The deploy templates are written for Flutter mobile apps. For another stack, keep the structure (confirm version → pre-check → build → upload → report) and replace the commands with ones found in the repo's own release scripts or CI. No release command found in the repo → do not generate the piece; say so in the plan.
- Deploy commands cannot be test-run during setup. Mark them "unverified" in `.claude/README.md` until the first real deploy.
- Credentials are referred to by path only. Ask the user where they live if the default path does not exist; never read or print their content.
- Crash SDK present but no way to read reports → do not generate the piece; name the missing connection in the report.

## Size limits (hard)

| File | Limit |
|---|---|
| `CLAUDE.md` | 40 lines; at most 6 hot rules |
| Stack skill | 50 lines; at most 8 hard rules |
| Process skill | 60 lines |
| Pipeline agent (planner, architect, developer, tester, reviewer) | 45 lines |
| Operations agent (deployers, crash-fixer, any other) | 80 lines |
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
| `{{APP_DIR}}` | The scan's primary app root (`.` when it is the repository root). When it is a subfolder, every command in CLAUDE.md, agents, and skills is written to run from there |
| `{{DEFAULT_BRANCH}}` | From the scan's Git section |
| `{{VERSION_FILE}}` | The file holding the version line (used by the deploy pieces) |
| Module placeholders | Listed in each `modules/<name>/module.md` |
| `{{BUILD_ENV_NOTE}}` | Build-time env mechanism (for example a `--dart-define-from-file` flag and the file it needs), or delete the line |
| `{{ANDROID_GRADLE_FILE}}` `{{ANDROID_KEY_PROPERTIES}}` `{{ANDROID_BUILD_CMD}}` `{{AAB_PATH}}` `{{PLAY_KEY_PATH}}` | Android release facts from the scan. Default key path `~/.playstore/service-account.json`; confirm it with the user |
| `{{BUNDLE_ID}}` `{{IOS_BUILD_CMD}}` `{{IPA_PATH}}` `{{ASC_KEY_DIR}}` `{{ASC_ISSUER_FILE}}` | iOS release facts from the scan. Defaults `~/.appstoreconnect/private_keys` and `~/.appstoreconnect/issuer_id.txt`; confirm them with the user |
| `{{CRASH_SOURCES}}` `{{BACKEND_ERROR_SOURCES}}` | Where crash reports are read (project and app identifiers, the tools to use, where reporting is wired in the code and what it filters). Backend log and advisor sources, or delete the line |
| `{{MODEL_PLANNER}}` `{{MODEL_DESIGN}}` `{{MODEL_BUILD}}` `{{MODEL_REVIEW}}` | Default `fable`, `opus`, `sonnet`, `opus`. In lite tier use `sonnet` for build and `opus` for review only |

## Modules (the user chooses)

Optional parts live in `modules/`; read `modules/README.md` for the format. Each module asks one question with a recommended answer taken from the scan. Current modules: `git-flow` (direct, branch, or pull request) and `ticket` (Trello, Jira, GitHub Issues, or none). Tier lite skips `git-flow` unless the user asks for it.

At most 9 skills in total (stack + process + module skills). Over the cap → drop a stack skill and fold its rules into the deep docs.

## Kit record

Write `.claude/kit.json` last. It is the only record of what the kit generated; update mode and `--add` read it.

```json
{
  "kit": "<version from the kit's .claude-plugin/plugin.json>",
  "generated": "<date>",
  "commit": "<short sha>",
  "tier": "lite | standard | full",
  "appDir": ".",
  "modules": { "git-flow": "branch", "ticket": "trello" },
  "ops": ["playstore-deploy", "appstore-deploy", "crash"]
}
```

A module the user declined is recorded as `"none"`, so update mode does not offer it again unasked.

## Tooling proposals (offer, never force)

- **Formatter hook** — always, when the stack has a formatter.
- **Protected paths hook** — when the repo has files that must not be hand-edited: applied migration files, generated code, lockfiles, secret files. List them in `.claude/hooks/protected-paths.txt`.
- **Stricter static analysis** — Dart: `strict-casts`, `strict-inference`, `strict-raw-types`, lint `unawaited_futures`. TypeScript: `strict`, `noUncheckedIndexedAccess`. Python: enable the type checker already in the repo. Measure new findings before and after; report the count.
- **Rules that became enforceable** — if a hot rule can be a lint or a hook, propose that and shorten the prose.
