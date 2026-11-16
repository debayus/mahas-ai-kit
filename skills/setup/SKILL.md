---
name: setup
description: Analyzes the current repository, then generates a complete but lean Claude configuration tailored to the code — CLAUDE.md, deep docs, stack skills, the Planner→Architect→Developer→Tester→Reviewer pipeline, commands, and hooks. Use when the user says "set up this project", "set up Claude for this repo", "install the kit", "prepare the pipeline", "/setup", or starts work in a repo that has no .claude/ folder. Also handles "update the setup" (update mode).
argument-hint: "[--lite | --full] [--update] [--dry-run]"
---

# Project setup

Generate a Claude configuration for THIS repository from what the code actually contains. Talk to the user in the language they write in, in plain language. Generated files are written in English; keep domain terms exactly as they appear in the codebase.

Paths below are relative to this skill's folder: `${CLAUDE_PLUGIN_ROOT}/skills/setup/` when installed as a plugin, or `skills/setup/` inside the cloned kit when started from the copy-paste prompt. Run the scripts by their full path while the working directory stays at the target repository root.

## Principles (these are what make the result cheap to run)

1. **Evidence only.** Every rule, command, and path you write must be backed by a file you read or a command you ran. No generic best-practice filler. If the code does not show it, leave it out.
2. **One home per fact.** Knowledge lives once in `.claude/.agent/*.md`. Skills and agents point to it; they never repeat it.
3. **Generate only what applies.** No database → no data skill. No tests → no tester stage. Small repo → lite tier.
4. **Enforce with tools, not tokens.** Anything a formatter, linter, or hook can enforce goes there, not into prose.
5. **Never overwrite.** Existing files are kept. Show a diff and ask before changing one.
6. **Stay inside the size limits** in `references/generation-rules.md`.

## Step 1 — Scan (cheap, deterministic)

Run `bash <skill folder>/scripts/detect.sh` from the target repository root and read its report. Do not explore the repo by hand before this.

If the report shows an existing `.claude/` with agents or skills, switch to **update mode** (Step 6) unless the user asked for a fresh setup.

## Step 2 — Targeted reading

Follow `references/analysis.md`. Read only what it lists for the detected stack, and stop when its questions are answered. Run the analyze and test commands once to confirm they work and to record a baseline (pass/fail, counts, duration). A command that fails here must not be written into CLAUDE.md as if it worked.

## Step 3 — Choose the tier and show the plan

Pick the tier using `references/generation-rules.md` (`--lite` / `--full` override it). Then present to the user:

- What you found (stack, architecture in one or two sentences, test and CI status).
- The project's hard rules you inferred, each with the file that proves it.
- The list of files you will create, and what you are deliberately leaving out and why.
- Tooling changes you propose (stricter analyzer settings, hooks) with their measured impact.

Ask for confirmation with AskUserQuestion. Also ask, only if the code cannot answer: the ticket tracker to use for leftover findings (skip the ticket skill if none), and the language for commit messages. With `--dry-run`, stop after this step.

## Step 4 — Generate

Copy from `templates/` and fill the `{{PLACEHOLDERS}}` listed in `references/generation-rules.md`. Delete any template section that does not apply — never leave a placeholder or an empty heading behind.

Order:

1. `.claude/.agent/` deep docs (see generation rules for which files).
2. `CLAUDE.md` from `templates/docs/CLAUDE.md`.
3. Stack skills (`.claude/skills/stack-*/SKILL.md`) shaped like `templates/skills/stack-skill.md`.
4. Process skills, agents, commands, and the workflow — only those in the chosen tier. A skill template `templates/skills/<name>.md` is written to `.claude/skills/<name>/SKILL.md`.
5. Hooks: copy the scripts to `.claude/hooks/`, make them executable, remove formatter branches for languages the repo does not use, and merge `templates/hooks/settings-hooks.json` into `.claude/settings.json` (merge, do not replace).
6. Tooling changes the user approved. For stricter analyzer or linter settings: apply, re-run the analyzer, and compare with the baseline. If new findings appear, report the count and ask whether to keep, fix, or revert — do not silently leave the project failing.
7. `.claude/README.md` — a short map of what was generated.

## Step 5 — Verify, then report

Run `bash <skill folder>/scripts/verify.sh` from the target repository root and fix everything it flags. Then confirm by hand that each command written in CLAUDE.md ran successfully in this session.

Report to the user: tier chosen, files created, what was skipped and why, tooling changes and their result, anything you could not verify, and how to start (`/plan <request>` or `/pipeline <request>`). Do not commit; offer a commit message.

## Step 6 — Update mode

For a repo that already has a setup: run Steps 1–2, then compare. Report (a) docs that no longer match the code, (b) kit templates newer than the project's copies, (c) rules in docs that a hook or lint could now enforce. Propose each change as a diff and apply only what the user approves. Never delete project-specific rules.
