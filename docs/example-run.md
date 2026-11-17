# What a run looks like

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

[Back to the README](../README.md)
