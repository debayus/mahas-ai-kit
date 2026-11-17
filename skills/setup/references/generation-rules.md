# Generation rules

## Tiers

| Tier | When | What is generated |
|---|---|---|
| **lite** | Under ~40 source files, or no automated tests | `CLAUDE.md`, `.agent/README.md` + `overview.md` + `conventions.md`, one stack skill, `planner` and `reviewer` agents, `process-planning`, `process-code-review`, `/plan` (planner only), `/review-changes`, the format hook if the repo has a formatter, the protect hook if the repo has files to protect |
| **standard** | 40–300 source files with tests | lite + `architecture.md`, `testing.md`, `glossary.md` if needed, up to 3 stack skills, all 5 agents, `process-planning`, `process-tech-design`, `/pipeline`, `/plan`, `/test`, workflow, both hooks |
| **full** | Over ~300 source files, or persistent data with migrations/sync, or multiple roles/tenants | standard + `data-model.md`, a data stack skill, `workflows.md` (release/ops runbooks found in the repo) |

Size and tests decide the tier first: a small repo or one without tests is lite even if it has shared data or several roles. Then add single pieces from a higher tier when the code clearly needs them (a data section, a second stack skill), and drop a piece that does not apply. State each such decision in the plan. Data saved on the device with a version number and migration functions (a save file format, a local database schema) counts as persistent data with migrations.

A repo without tests: in the copied process skills, drop the sentences that require tests ("Include test tasks", "tests green") and name the gates that do exist instead. Tier lite has no pipeline: drop the sentences that refer to one.

## Not a git repository

The scan says so in its Git section. Then:

- `/review-changes` is not generated: it reads a diff. The reviewer agent reviews the files it is given.
- Delete every sentence that names a branch, a diff, a commit, or a push; `{{DEFAULT_BRANCH}}` has no value.
- `{{COMMIT}}` is written as "no git" and `kit.json` gets `"commit": null`.
- The `git-flow` and `ticket` modules are not asked; record neither.
- Say in the plan that `git init` and a rerun with `--update` add these parts.

## Deep docs

A project that already keeps this knowledge elsewhere (a `docs/` folder with architecture, schema, or glossary files) keeps it there: link to those files from the index and from the skills, and do not copy them into `.claude/.agent/`.

No template: each doc is written from what Step 2 found, one section per item below, every section with a link to the file that proves it. Leave out an item the code does not show.

| Doc | Contents |
|---|---|
| `README.md` | The index, from `templates/docs/agent-README.md`. Generated in every tier |
| `overview.md` | What the product is and who uses it, the stack with versions, the top-level folder map, how to run it, how it is deployed |
| `conventions.md` | File and symbol naming, the shape of a feature folder, where strings, colors, and constants live. Tier lite also puts here what would otherwise go in `testing.md` and `data-model.md` |
| `architecture.md` | The layers with real paths, one feature traced end to end, state management, the choke points every write goes through |
| `testing.md` | Test folders, helpers and fakes, how the database and network are faked, the commands, known flaky patterns. The testing module adds its "Test levels" section here |
| `glossary.md` | Domain and non-English terms a newcomer would misread |
| `data-model.md` | Tables or collections and their relations, the migration mechanism, sync, who may read what |
| `workflows.md` | Release and operations runbooks found in the repo |

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
- A deploy that CI performs on its own (the scan's "deploy in CI" line: hosting, pages, a store upload action) gets no piece. Name it in `{{VERSION_AND_RELEASE_NOTE}}` and, if a push to the default branch triggers it, as a hot rule.

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

Stack skills: at most 3 (4 in full tier). A skill exists only if at least two agents need it; the single stack skill of tier lite is exempt.

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
| `{{ANALYZE_CMD}}` `{{FORMAT_CHECK_CMD}}` `{{FORMAT_FILE_CMD}}` `{{TEST_CMD}}` `{{E2E_CMD}}` | Verified commands. A project that lacks one of them: remove that command from the sentence and keep the rest; delete the line only when none is left |
| `{{RUN_COMMANDS}}` `{{COMMANDS}}` | The run, build, and check commands that worked in Step 2, one per line |
| `{{VERSION_AND_RELEASE_NOTE}}` | Where the version lives and how a release is made, in one line; delete the line if the repo shows neither |
| `{{DOC_INDEX_ROWS}}` | One row per generated deep doc: file, what it covers, when to read it |
| `{{DATE}}` `{{COMMIT}}` | Today's date and the short SHA from the scan |
| `{{KIT_VERSION}}` `{{TIER}}` `{{SETUP_MAP}}` `{{CHOICES}}` `{{UNVERIFIED}}` | For `.claude/README.md`: the kit version and tier as in `kit.json`; one line per generated folder saying what is in it; each module option and operations piece chosen or declined; every command or piece marked "unverified", or "Nothing" |
| `{{TOPIC}}` `{{TOPIC_TITLE}}` `{{WHAT_IT_COVERS}}` `{{WHEN_TO_LOAD}}` `{{DOC}}` `{{KEY_FILE}}` `{{RULE}}` `{{REASON}}` `{{PROOF_FILE}}` `{{STEP}}` `{{WHAT}}` | Stack skill slots, explained in `templates/skills/stack-skill.md` itself |
| `{{TEST_GUIDE}}` | "Load the `stack-testing` skill" when that skill is generated; otherwise "Read [testing.md](.claude/.agent/testing.md)", or the conventions doc in tier lite |
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
| `{{MODEL_PLANNER}}` `{{MODEL_DESIGN}}` `{{MODEL_BUILD}}` `{{MODEL_REVIEW}}` | Default `fable`, `opus`, `sonnet`, `opus`. Tier lite has only the planner and the reviewer and uses the same defaults for them |

## Modules (the user chooses)

Optional parts live in `modules/`; read `modules/README.md` for the format. Each module asks one question with a recommended answer taken from the scan. Current modules: `pipeline` (the kit's pipeline, or the knowledge layer only), `git-flow` (direct, branch, or pull request), `ticket` (Trello, Jira, GitHub Issues, or none), `testing` (gate only, gaps in existing levels, or extended levels), and `database` (files only, or also read-only inspection of a live database). Tier lite skips `git-flow` unless the user asks for it.

A module agent counts as an operations agent for the size limit (80 lines).

At most 10 skills in total (stack + process + module skills). Over the cap → drop a stack skill and fold its rules into the deep docs.

## Kit record

Write `.claude/kit.json` last. It is the only record of what the kit generated; update mode and `--add` read it.

```json
{
  "kit": "<version from the kit's .claude-plugin/plugin.json>",
  "generated": "<date>",
  "commit": "<short sha>",
  "tier": "lite | standard | full",
  "appDir": ".",
  "modules": { "pipeline": "kit", "git-flow": "branch", "ticket": "trello", "testing": "existing", "database": "files" },
  "ops": ["playstore-deploy", "appstore-deploy", "crash"],
  "adopted": { "crash": ".claude/agents/crash-analyzer.md", "ticket": ".claude/skills/process-ticket-offer" }
}
```

`adopted` appears only for a setup the kit did not generate (update mode): it maps a kit role, module, or operations piece to the existing file that already does the job, so later runs do not offer it again. Keys: an agent role (`planner`, `architect`, `developer`, `tester`, `reviewer`), a command (`pipeline`, `plan`, `test`, `review-changes`), `workflow`, `docs`, `stack-skills`, `format-hook`, `protect-hook`, a module name, or an operations piece name. The value is one path, or a list of paths when two files share the role. An adopted module is also recorded under `modules` with the option that describes what the existing file does, and an adopted operations piece is also listed in `ops`; declining an extension to it does not change that. For such a setup, `tier` is the tier the scan suggests and `kit` is the version of the kit that wrote the record.

A module the user declined is recorded as `"none"`, so update mode does not offer it again unasked.

## Tooling proposals (offer, never force)

- **Formatter hook** — when the repo itself has a formatter: one that ships with the toolchain (`dart format`, `gofmt`, `cargo fmt`) or one listed in the manifest (Prettier, Ruff, Black, gdformat from gdtoolkit). The hook's Python branch uses whichever of Ruff or Black is on the machine: keep it only if the repo's manifest names one of them. No formatter in the repo → no hook; do not add a formatter dependency.
- **Protected paths hook** — when the repo has files that must not be hand-edited: applied migration files, generated code, lockfiles, secret files. List them in `.claude/hooks/protected-paths.txt`.
- **Stricter static analysis** — Dart: `strict-casts`, `strict-inference`, `strict-raw-types`, lint `unawaited_futures`. TypeScript: `strict`, `noUncheckedIndexedAccess`. Python: enable the type checker already in the repo. Measure new findings before and after; report the count. With `--dry-run`, or when measuring means editing a config file, offer the change as unmeasured instead. Do not recommend a setting that adds more than about 50 findings in one step; report the count and leave it to the user.
- **Rules that became enforceable** — if a hot rule can be a lint or a hook, propose that and shorten the prose.
