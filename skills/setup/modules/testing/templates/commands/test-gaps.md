---
description: Find behaviour that no test covers and write the missing tests; --report only lists the gaps
argument-hint: "[--report] [--level <level>] [file or area to scope]"
allowed-tools: Task, Bash, Read, Grep, Glob, AskUserQuestion
---

Find and fill test gaps in **{{PROJECT_NAME}}**.

Arguments: $ARGUMENTS

1. Delegate to the `test-gap` agent. Pass the scope, `--report` if given, and the level if given. Without a scope, tell it to use the files changed since `{{DEFAULT_BRANCH}}`; if there are none, the whole app.
2. A level that is not in the "Test levels" section of [testing.md](.claude/.agent/testing.md) is out of scope: say so and name `setup --add testing` as the way to add it.
3. The agent stops if the suite is red. In that case tell the user to get `{{TEST_CMD}}` green first.
4. Relay in the user's language: the ranked gaps, each test written and what it proves, the passing summary lines as proof, tests written but not run, and product bugs found. Product bugs go first.
5. Do not commit. Offer a commit message for the new tests.
6. If the `process-ticket` skill exists, follow it for the product bugs found.
