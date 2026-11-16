# Module: git-flow

Decides how finished work reaches the default branch. Tier lite skips this module (it has no `/pipeline`) unless the user asks for it.

## Options

| Option | Meaning | Generates |
|---|---|---|
| `direct` | Commit on the default branch | `process-git-delivery` skill |
| `branch` | One branch per change, merged locally | `process-git-delivery` skill |
| `pr` | One branch per change, merged through a pull request | `process-git-delivery` skill, `/pr` command |

`pr` is experimental for hosts other than GitHub.

## Recommendation (scan section "Git")

Apply the first rule that matches and quote its evidence line in the question:

1. PR merges in the last 200 commits ≥ 3, or a pull request template exists → `pr`.
2. More than one commit author in the last 200 commits, and the remote host has a PR CLI installed → `pr`.
3. Prefixed branches exist (for example `fix/`, `feat/`), or more than one author → `branch`.
4. Otherwise → `branch` for tier standard and full, `direct` for tier lite.

## Question

"How does finished work reach `<default branch>`?" — options in recommended order, each with a one-line description; put the evidence in the recommended option's description.

Ask a follow-up only when the code cannot answer it:

- `branch`: may finished, approved work be merged without asking each time? (fills `{{MERGE_POLICY}}`)
- `pr`: who merges the PR — the user on the host, or Claude after approval? (fills `{{MERGE_POLICY}}`)

## Placeholders

| Placeholder | Fill with |
|---|---|
| `{{DEFAULT_BRANCH}}` | From the scan |
| `{{BRANCH_STYLE}}` | The pattern seen in existing branch names. With the ticket module on, include the ticket code: `<type>/<CODE>-<slug>`, using the code format from the ticket module. No existing branches → propose `<type>/<slug>` and confirm |
| `{{COMMIT_STYLE}}` | The convention seen in `git log` (types, scopes, language), with one real subject as the example. With the ticket module on, add how the ticket code is written in the subject, as the history already does it |
| `{{VERSION_FILE}}` `{{VERSION_POLICY}}` | The file holding the version line and who changes it. Delete the line if the project has no version line |
| `{{MERGE_POLICY}}` | The user's answer, in their own words. Default: "Ask the user before merging into the default branch." |
| `{{PR_HOST}}` `{{PR_CREATE_CMD}}` | The remote host and its CLI command (`gh pr create` on GitHub). CLI not installed → write "none" and the command outputs a paste-ready title and body instead |
| `{{PR_TEMPLATE}}` | Path of the repo's pull request template, or delete the line |

## Rules

- Never record a standing permission to merge or push that the user did not give in this setup session.
- `/pipeline` step 3 points at `process-git-delivery`; with option `pr` its last step offers `/pr` instead of a push command.
