---
name: process-git-delivery
description: Git and delivery conventions for {{PROJECT_NAME}} — where work is committed, branch naming, commit format, what must hold before a commit, and how work reaches {{DEFAULT_BRANCH}}. Load before committing, branching, pushing, or merging.
---

# Git and delivery — {{PROJECT_NAME}}

Used by the main session at delivery time. Subagents never commit.

## Where work goes

<!-- option: direct -->
Work is committed directly on `{{DEFAULT_BRANCH}}`. Do not create branches unless the user asks.
<!-- /option -->
<!-- option: branch pr -->
- Default branch: `{{DEFAULT_BRANCH}}`. Never commit on it directly; create a branch before the first edit.
- Branch name: {{BRANCH_STYLE}}
- One branch per ticket or change. Do not mix unrelated work in a branch.
<!-- /option -->

## Commit format

{{COMMIT_STYLE}}

One logical change per commit.

## Before any commit

1. The gate is green in this session: `{{ANALYZE_CMD}}`, `{{FORMAT_CHECK_CMD}}`, `{{TEST_CMD}}`.
2. After `/pipeline`: the verdict is APPROVED and every acceptance criterion is met.
3. `git status` and `git diff` were read. Stage only the files that belong to the change, by name — no `git add -A`, no logs, build output, or scratch files.
4. The version line in `{{VERSION_FILE}}` is not touched by feature work. {{VERSION_POLICY}}

## Reaching {{DEFAULT_BRANCH}}

<!-- option: direct -->
Push only when the user asked: `git push`.
<!-- /option -->
<!-- option: branch -->
{{MERGE_POLICY}}

- Merge with `git merge --ff-only <branch>`; if the default branch has moved, `git merge --no-ff <branch>` and re-run the gate on the result.
- Never merge a branch that is not approved and green, or that has uncommitted work.
- On a conflict or a red gate after merging: abort, go back to the branch, and report. Do not resolve by guessing.
- Delete a merged branch with `git branch -d` only (never `-D`).
- Push only when the user asked.
<!-- /option -->
<!-- option: pr -->
Work reaches `{{DEFAULT_BRANCH}}` only through a pull request on {{PR_HOST}}. Use `/pr` to push the branch and open it.

- PR title: the commit format above. Body: what was asked, what changed, test evidence (which gates ran and their result), and migration notes if stored data changed. {{PR_TEMPLATE}}
- Never push to `{{DEFAULT_BRANCH}}` and never merge locally into it.
- {{MERGE_POLICY}}
- After a review comment: fix on the same branch with a new commit; do not amend or force-push unless the user asks.
<!-- /option -->
