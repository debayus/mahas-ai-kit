---
description: Push the current branch and open a pull request for it, following the project's delivery rules
argument-hint: "[ticket code or extra context for the PR body]"
allowed-tools: Bash, Read, Grep, Glob, Skill, AskUserQuestion
---

Open a pull request for the current branch of **{{PROJECT_NAME}}**. Invoking this command authorizes pushing this branch and creating the PR — nothing else.

Context: $ARGUMENTS

1. Load the `process-git-delivery` skill and follow it.
2. **Check before pushing.** Stop and report if any of these fail:
   - The current branch is not `{{DEFAULT_BRANCH}}` and its name follows the branch rule.
   - `git status` is clean: everything that belongs to the change is committed.
   - The gate is green in this session (`{{ANALYZE_CMD}}`, `{{FORMAT_CHECK_CMD}}`, `{{TEST_CMD}}`). Not run yet → run it now.
3. **Existing PR?** If the branch already has an open PR, push the new commits and report its URL instead of creating another.
4. **Push:** `git push -u origin <branch>`. Never force-push.
5. **Create the PR** against `{{DEFAULT_BRANCH}}` with `{{PR_CREATE_CMD}}`. Title and body as the skill defines them, written from the real `git log` and `git diff` of the branch against `{{DEFAULT_BRANCH}}`. If the CLI is not available, print the title and body as paste-ready text and the URL to open.
6. **Report** in the user's language: the PR URL, the title, and what remains for the user (review, merge).
7. If the `process-ticket` skill exists, follow it to link the PR on the ticket.

Do not merge the PR and do not enable auto-merge unless the user asked.
