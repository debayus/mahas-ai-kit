---
name: setup
description: Analyzes the current repository, then generates a complete but lean Claude configuration tailored to the code — CLAUDE.md, deep docs, stack skills, the Planner→Architect→Developer→Tester→Reviewer pipeline, commands, and hooks. Use when the user says "set up this project", "set up Claude for this repo", "install the kit", "prepare the pipeline", "/setup", or starts work in a repo that has no .claude/ folder. Also handles "update the setup" (update mode).
argument-hint: "[--lite | --full] [--no-pipeline] [--update] [--add <module>] [--dry-run]"
---

# Project setup

Generate a Claude configuration for THIS repository from what the code actually contains. Talk to the user in the language they write in, in plain language. Generated files are written in English; keep domain terms exactly as they appear in the codebase.

Paths below are relative to this skill's folder: `${CLAUDE_PLUGIN_ROOT}/skills/setup/` when installed as a plugin, or `skills/setup/` inside the cloned kit when started from the copy-paste prompt. Run the scripts by their full path while the working directory stays at the target repository root.

## Principles (these are what make the result cheap to run)

1. **Evidence only.** Every rule, command, and path you write must be backed by a file you read or a command you ran. No generic best-practice filler. If the code does not show it, leave it out.
2. **One home per fact.** Knowledge lives once in `.claude/.agent/*.md`. Skills and agents carry a rule as one line with a link to it, never the explanation. Only the hot rules are repeated, in `CLAUDE.md` and in the agents that must not miss them.
3. **Generate only what applies.** No database → no data skill. No tests → no tester stage. Small repo → lite tier.
4. **Enforce with tools, not tokens.** Anything a formatter, linter, or hook can enforce goes there, not into prose.
5. **Never overwrite.** Existing files are kept. Show a diff and ask before changing one.
6. **Stay inside the size limits** in `references/generation-rules.md`.

## Step 1 — Scan (cheap, deterministic)

Run `bash <skill folder>/scripts/detect.sh` from the target repository root and read its report. Do not explore the repo by hand before this.

If the report's "App root" is a subfolder, the app does not live at the repository root: run analyze, test, and build commands from that folder, and write every generated command so it runs from there. `.claude/` and `CLAUDE.md` still go at the repository root.

If the report shows an existing `.claude/` with agents, skills, or commands, switch to **update mode** (Step 6) unless the user asked for a fresh setup. A `.claude/` that holds only other files (settings, a launch file) is a fresh setup: keep those files. `--update` on a repo with no setup is a fresh setup too.

An existing `CLAUDE.md` or `AGENTS.md` without a setup is kept. Read it in Step 2 as claims to check against the code. In Step 4, do not write over it: show the generated `CLAUDE.md` as a diff against the existing one, keep every project-specific rule, and move whole sections that do not fit the size limit into the deep docs with a link in their place. `AGENTS.md` is left as it is; name it in the plan.

Several apps in one repository (the scan lists nested manifests beside the primary app root): the setup covers the primary app root. Name the folders it leaves out in the plan, and ask which app is meant when the scan's choice is not clearly the main one.

## Step 2 — Targeted reading

Follow `references/analysis.md`. Read only what it lists for the detected stack, and stop when its questions are answered. Run the analyze and test commands once to confirm they work and to record a baseline (pass/fail, counts, duration). A command that fails here must not be written into CLAUDE.md as if it worked.

- No analyze or test command defined by the repo: use the toolchain's own check if the config for it exists (`tsc --noEmit` with a `tsconfig.json`, `go vet`, `cargo check`) and say it was inferred. Do not run a build that writes output as a baseline; record it as unverified.
- A test suite that would run longer than about 5 minutes, or that needs a device, a browser, or a server: run one small test file to prove the command works, and record the full suite as "not run during setup".
- Dependencies not installed: do not install them. Record the commands as unverified.
- Step 2 must leave the working tree as it found it. Use the flag that stops a command from fetching or rewriting (`--no-pub` for Flutter when a package config exists, `--frozen-lockfile`, `--offline`, a check mode instead of a format-in-place). A gate script that installs, formats in place, or deletes files is read, not run: record it as "not run during setup". A command that would write build output into the repo is not run there. Afterwards `git status` must show no change; report anything that did change.
- A gate that exits 0 is not a pass if its output shows skipped steps (a missing engine binary, a missing tool). Read the output and record what was skipped.

## Step 3 — Choose the tier and show the plan

Pick the tier using `references/generation-rules.md` (`--lite` / `--full` override it). Then present to the user:

- What you found (stack, architecture in one or two sentences, test and CI status). If the scan's CI lines show that a push to the default branch deploys, say so here and make it a hot rule.
- The project's hard rules you inferred, each with the file that proves it.
- The list of files you will create, and what you are deliberately leaving out and why.
- The recommended option for each module, and the operations pieces the evidence supports (deploy, crash triage), each with its evidence.
- Tooling changes you propose (stricter analyzer settings, hooks), each with its measured impact or marked "unmeasured".

### Choices

For each module in `modules/` (see `modules/README.md`), apply its recommendation rules to the scan and note the recommended option with its evidence line. Do the same for each operations piece the evidence supports. Then ask with AskUserQuestion:

1. First question: "Follow all recommendations" (list them in the description: tier, each module's option, each operations piece, each tooling change) or "Choose one by one". This answer is the approval to generate; nothing is written before it. If the user instead wants a file left out, another tier, a rule changed, or to stop, revise the plan and ask again, or stop.
2. Only if the user chooses one by one: one question per module, recommended option first, then one multi-select question for the operations pieces and one for the tooling changes. No operations piece has evidence → skip that question and say so in the plan. A module whose `module.md` says "do not ask" is skipped the same way. Deploy pieces publish to a store when used, so they are never pre-selected without the user seeing them named.
3. Then the follow-up questions the chosen options need and the code cannot answer (each `module.md` lists them), the language for commit messages if the history is mixed, and where release credentials live if the default paths do not exist.

Keep it to as few questions as the choices allow; never ask what the scan already answered. With `--dry-run`, stop after this step: show the plan and the questions with their recommended answers, ask nothing, and write nothing. "Write nothing" means no file that git tracks or would track; the analyze and test commands of Step 2 still run, since the plan depends on their result.

## Step 4 — Generate

Copy from `templates/` and fill the `{{PLACEHOLDERS}}` listed in `references/generation-rules.md`. Delete any template section that does not apply — never leave a placeholder or an empty heading behind.

Order:

1. `.claude/.agent/` deep docs (see generation rules for which files).
2. `CLAUDE.md` from `templates/docs/CLAUDE.md`.
3. Stack skills (`.claude/skills/stack-*/SKILL.md`) shaped like `templates/skills/stack-skill.md`.
4. Process skills, agents, commands, and the workflow — only those in the chosen tier, and none of them when the `pipeline` module is `none` — plus the operations pieces the user accepted. A skill template `templates/skills/<name>.md` is written to `.claude/skills/<name>/SKILL.md`. Blocks marked `<!-- option: lite -->` or `<!-- option: standard full -->` are resolved by tier; a block marked with a module option (`<!-- option: pr -->` in `/pipeline`) is resolved by that module's choice.
5. Module files for the options the user chose, from `modules/<name>/templates/`, resolving option blocks as `modules/README.md` describes. A module set to `none`: delete the lines in generated commands that refer to its skill, unless its `module.md` says what replaces them.
6. Hooks: copy the scripts to `.claude/hooks/`, make them executable, remove formatter branches for languages the repo does not use, replace the examples in `protected-paths.txt` with this repo's own paths, and merge `templates/hooks/settings-hooks.json` into `.claude/settings.json` (merge, do not replace). No formatter in the repo: leave out `format-on-edit.sh` and its `PostToolUse` entry. Nothing to protect: leave out `protect-files.sh`, its list, and its `PreToolUse` entry.
7. Tooling changes the user approved. For stricter analyzer or linter settings: apply, re-run the analyzer, and compare with the baseline. If new findings appear, report the count and ask whether to keep, fix, or revert — do not silently leave the project failing.
8. `.claude/README.md` from `templates/docs/claude-README.md`, and `.claude/kit.json`, the kit record described in the generation rules.

## Step 5 — Verify, then report

Run `bash <skill folder>/scripts/verify.sh` from the target repository root and fix everything it flags. Then confirm by hand that each command written in CLAUDE.md either ran successfully in this session or is marked "unverified".

Report to the user: tier chosen, files created, what was skipped and why, tooling changes and their result, anything you could not verify, and how to start (`/plan <request>`; outside tier lite also `/pipeline <request>`; with the pipeline off, name the stack skills instead). Do not commit; offer a commit message.

## Step 6 — Update mode

For a repo that already has a setup. Run Steps 1–2, then `bash <skill folder>/scripts/verify.sh --existing` (size overruns are warnings in this mode, not failures). In Step 2, read the existing deep docs first and the code only where a doc is missing or the scan contradicts it. A doc too large to read whole (over about 1,500 lines, or far larger in bytes than its line count suggests): read its headings and only the sections the analysis questions need, and say in the plan which sections were not read. With `--dry-run`, show the mapping, the findings, and the proposals below as a list, then stop before any diff.

**Setup with a kit record (`.claude/kit.json`).** Compare and report: (a) docs that no longer match the code, (b) when the recorded `kit` version is older than this kit: sections the current templates have that the generated files lack, (c) rules in docs that a hook or lint could now enforce, (d) operations pieces and modules the evidence now supports but the record lacks — not modules recorded as `none`, and not operations pieces listed under `opsDeclined`.

**Setup without a kit record (made by hand or by an older kit) — adopt it, do not replace it.**

1. Map what exists by what it does, not by its name. A command that runs plan → design → code → test → review is the pipeline whatever it is called (`/engineer`, `/ship`, `/feature`); an agent that runs the gate and fixes failures is the tester (`test-fixer`, `test-runner`); a skill holding commit rules is git delivery (`git-delivery`, `commit-prep`). Show the user this mapping.
2. Keep existing names, files, and conventions: a project that keeps its commands as skills, or its deep docs under `docs/`, gets new pieces in that same form.
   Keep existing names and files. Never rename, merge, or delete them, and never add a kit piece that duplicates one that already does the job.
3. Propose only what is missing after the mapping: hooks, deep docs, a noise-rule section for the reviewer, a core command nothing existing covers (`/review-changes`, a gate-only `/test`), and each module or operations piece whose evidence is there and that nothing existing covers. Use the module's own recommendation rules. The "Follow all recommendations" question lists only these additions, never a piece that is already covered.
   - Partly covered (an existing skill does half of what the kit's piece does): do not add the kit's file beside it. Offer to add the missing sections to the existing file, as a diff, or leave it. If that would push the file over its size limit, or the covering text sits inside a command or a deep doc instead of a skill, offer the kit's file plus a one-line pointer that replaces the inline text, and show both diffs. When the existing file already has the kit file's own name (`process-git-delivery`), there is no second file to add: offer the missing sections as a diff to it, after first moving its longest section into a deep doc if it is over its limit.
   - Two existing pieces share one kit role (a gate agent and a full-suite agent): keep both and map both.
   - A new kit file names the project's own pieces, not the kit's: if `process-ticket-offer` plays the ticket role and `/test-all` is the test command, write those names wherever the template says `process-ticket` or `/test`.
   - Also report docs that no longer match the code, and rules a hook could now enforce, as in the kit-record case.
4. An oversized `CLAUDE.md` or agent: propose moving whole sections, unchanged, into the deep docs and leaving a link in their place. The deep docs are where the project already keeps them (item 2); `.claude/.agent/*.md` only when it has no such place. Show the diff. Nothing is dropped, only moved. A command or skill over its limit by a few lines is reported, not moved; over by half or more, treat it the same way.
5. Write `.claude/kit.json` when the user has accepted at least one change, or has declined them all and agrees to keep the record. Record chosen options under `modules`, declined ones as `"none"`, and every mapped piece under `adopted` (see the generation rules), so the next update does not repeat the same offers.
6. After applying changes, run `verify.sh --existing` again.

In both cases propose each change as a diff and apply only what the user approves. Never delete project-specific rules.

## Adding a module later (`--add <module>`)

Needs an existing setup; without one, run the full setup instead. Run the scan, read `modules/<module>/module.md`, ask its question, generate its files, and update `.claude/kit.json`. A module that is already recorded: show the recorded option and ask whether to change it. If the choice changes facts another module wrote (a ticket code in the branch rule, a `/pr` step in `/pipeline`), show that diff too. Then run `verify.sh` (`verify.sh --existing` when `kit.json` has an `adopted` map).
