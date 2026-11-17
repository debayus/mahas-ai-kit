# What gets created in your project

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

## Commands after setup

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

## Why it stays cheap

- The plugin adds a single skill description to the context. Everything else is read only when setup runs.
- The first scan is a script, not the model.
- Only the parts that match the code are generated; small projects get the light version.
- Rules a formatter, linter, or hook can enforce are not written as prose.
- The reviewer has noise rules, so there are fewer fix rounds.
- `verify.sh` checks the result (size limits, links, placeholders, JSON, hooks).

[Back to the README](../README.md)
