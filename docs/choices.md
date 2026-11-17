# Choices during setup

Setup recommends an answer for each choice from what it finds in the repo. Accept all recommendations in one step, or choose one by one.

| Choice | Options | Recommended from |
|---|---|---|
| Pipeline | the kit's pipeline, or knowledge only | A workflow framework already in use (Superpowers, Spec Kit, BMAD, OpenSpec) |
| Git flow | direct, branch, pull request | Branch names, PR merges in the history, the PR CLI installed |
| Tickets | Trello, Jira, GitHub Issues, none | Servers in `.mcp.json`, ticket codes in commit subjects |
| Database | none, files only, read a live database | Migration and rules files, servers in `.mcp.json`, database CLIs |
| Testing | gate only, fill gaps in existing levels, extended levels | Test files per level, test tools, coverage signals |
| Operations | Play Store deploy, App Store deploy, crash triage | Release signing, bundle id, crash SDK |

Jira, GitHub Issues, extended test levels, SQL databases other than Supabase and Firebase, and pull requests on hosts other than GitHub are experimental: written, not yet run on a real project. The kit never installs an MCP server and never writes a token.

## Already using Superpowers, Spec Kit, or BMAD?

Those tell Claude how to work; they are the same in every project. This kit writes down what is true about one repository: its layers, its hard rules, the commands that run, the files that must not be edited. Use `--no-pipeline` to get that part only (`CLAUDE.md`, the deep docs, the stack skills, the hooks) and keep the workflow you have. Setup recommends this on its own when it finds such a framework.

[Back to the README](../README.md)
