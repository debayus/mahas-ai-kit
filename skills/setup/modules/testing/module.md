# Module: testing

Decides how far testing goes beyond the gate (`/test` and the `tester` agent keep the existing suite green; they do not look for what is untested). This module adds the piece that finds missing tests and writes them.

## Options

| Option | Meaning | Generates |
|---|---|---|
| `none` | The gate only | nothing |
| `existing` | Find and fill gaps in the test levels the repo already has | `test-gap` agent, `/test-gaps` command, a "Test levels" section in `.claude/.agent/testing.md` |
| `extended` | Same, plus levels the user picks that the repo does not have yet (experimental) | same files; the new levels are listed as "to start" |

## Recommendation (scan sections "Tests" and "Test levels")

Apply the first rule that matches and quote its evidence line in the question:

1. No test files, or the test command did not run in Step 2 → `none`. The agent copies the repo's own test patterns and has none to copy. Say that `extended` is the way to start a suite.
2. Otherwise → `existing`, naming the levels the scan found.

`extended` is never the recommendation. Load and stress are never pre-selected.

## Question

"How far should testing go beyond the gate?" — options in recommended order. Then ask only what the choice needs:

- `extended`: one multi-select of the levels the repo lacks (unit and component, integration, golden or snapshot, end-to-end, load or stress). Unit and component is always offerable: use the stack's standard runner, or ask which one if the stack has several. Offer another level only if its tool is in the manifest, or the user names the tool. A CLI that is merely installed on the machine does not make a level offerable.
- Coverage floor. CI already enforces one (a `--min`, `fail_under`, or threshold in the scan's CI lines) → write that figure and its source as the floor and do not ask. Otherwise ask only when the repo defines a coverage command and you ran it in Step 2: "Keep coverage from dropping below today's figure (N%)?" Default no. Do not run a coverage command just to be able to ask.
- Load or stress chosen: which non-production host may be tested. No such host → record "none; scripts are written but not run".

## A level counts as present when

| Level | Evidence in the scan |
|---|---|
| Unit and component | At least one test file outside the integration and end-to-end folders |
| Integration | Integration test files that run without a device or browser |
| Golden or snapshot | Files with golden or snapshot assertions |
| End-to-end | End-to-end test files or a tool config (Playwright, Cypress, Patrol, Maestro, Detox). Flutter's `integration_test/` runs on a device: list it here, not under integration |
| Load or stress | Script files for k6, Locust, Artillery, or JMeter |

Performance or benchmark tests the repo already has are not a level here: leave them alone unless load or stress is chosen.

## Placeholders

| Placeholder | Fill with |
|---|---|
| `{{TEST_LEVELS}}` | One table row per level in scope: level, folder, the command that ran in Step 2 (or "unverified" if it needs a device, a browser, or a server), one existing test file to copy the pattern from. A level picked under `extended` has no pattern file: write "to start" and the tool |
| `{{TEST_FILE_RULE}}` | How a source file maps to its test file in this repo, read from existing pairs (for example `lib/a/b.dart` → `test/a/b_test.dart`) |
| `{{GAP_SOURCES}}` | How gaps are found here, in order: the coverage command and its report path if it ran in Step 2; then source files with no test file under the rule above |
| `{{COVERAGE_FLOOR}}` | The measured figure and the command that produced it. Declined or no coverage command → delete the line |
| `{{LOAD_TARGET}}` | The host the user allowed for load runs, or "none; scripts are written but not run" |

The "Test levels" section in `.claude/.agent/testing.md` is the only home for the table. The agent and the command link to it; they do not repeat it. Tier lite has no `testing.md`: create it with this section only.

## Rules

- Record the option in `.claude/kit.json` under `modules`. The levels in scope live in `testing.md` only.
- `{{TEST_GUIDE}}` and `{{TEST_CMD}}` are the kit-wide placeholders from `references/generation-rules.md`.

- Resolve the option blocks in the templates by level, not by option: keep `<!-- option: golden -->`, `e2e`, `load`, and `coverage` blocks only for the levels in scope and for an accepted coverage floor.
- A coverage floor is the measured figure, never a target. Do not write a number that no command produced in this session.
- Do not add a test tool to the manifest during setup. A level under `extended` whose tool is missing is recorded as "to start"; the agent proposes the dependency on first use and waits for approval.
- Mark `extended` levels "unverified" in `.claude/README.md` until their first passing run.
