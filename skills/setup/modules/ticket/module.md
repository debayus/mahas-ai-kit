# Module: ticket

Decides which tracker holds the work items and how ticket codes appear in branches, commits, and pull requests.

## Options

| Option | Meaning | Generates |
|---|---|---|
| `trello` | Cards on a Trello board | `process-ticket` skill |
| `jira` | Issues in a Jira project (experimental) | `process-ticket` skill |
| `github` | GitHub Issues through the `gh` CLI (experimental) | `process-ticket` skill |
| `none` | No tracker | nothing; delete every "if the `process-ticket` skill exists" line from the generated commands |

## Recommendation (scan sections "Tickets" and "Release and operations signals")

Apply the first rule that matches and quote its evidence line in the question:

1. A tracker server is listed in `.mcp.json` → that tracker.
2. Ticket codes appear in at least 5 of the last 200 commit subjects → the tracker their shape points to: `Trello #123` → `trello`; `ABC-123` → `jira`; a bare `#123` with a GitHub remote → `github`.
3. Otherwise → `none`. Still ask, with `none` first.

## Question

"Where are this project's tickets kept?" — options in recommended order. Then ask only what the scan and the tracker itself cannot answer:

- The board or project to bind to (name or URL), and the label or component that marks this project if the board is shared.
- The list or status names for: new work, in progress, waiting for review, done.

Read the rest from the tracker when a tool for it is connected (list names, labels) instead of asking.

## Placeholders

| Placeholder | Fill with |
|---|---|
| `{{TRACKER}}` | Tracker name |
| `{{TRACKER_BINDING}}` | Board or project, its URL, the project label or component, and the four list or status names |
| `{{TICKET_TOOL}}` | How this machine reaches the tracker, in this order of preference: a user-level skill the user already has for it (name it, and say it holds the procedure); an MCP server that is already configured (name it as configured); a CLI (`gh issue` for GitHub). None of these → write "not connected" |
| `{{TICKET_CODE_FORMAT}}` | How a ticket is referred to, taken from the commit history (for example `Trello #2197` or `KM-123`), and where it goes: branch name, commit subject, PR title |

## Rules

- The skill holds this project's binding and the rules below it. It does not repeat a procedure that a user-level skill or the tracker's own tool already provides.
- Tracker not connected → still generate the skill with `{{TICKET_TOOL}}` "not connected". The skill then produces paste-ready ticket text. Tell the user which connection is missing; do not add a server entry on your own.
- With the git-flow module on, pass `{{TICKET_CODE_FORMAT}}` to it so branch and commit rules include the code.
- Never write a token, API key, or board secret into any generated file.
