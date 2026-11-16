# Modules

A module is one optional part of the setup that the user chooses. Each module asks one question, has a recommended answer derived from the scan, and generates at most one skill and one command.

```
modules/<name>/
├── module.md      # options, recommendation rules, the question, placeholders, rules
└── templates/     # same layout as ../templates (skills/, commands/, agents/)
```

## How setup uses a module

1. Read `module.md`. Apply its recommendation rules to the scan report to pick the recommended option and the evidence line for it.
2. Ask the question (see Step 3 of `SKILL.md`), recommended option first.
3. Generate the chosen option's files from the module's `templates/`. Option `none` generates nothing.
4. Record the choice in `.claude/kit.json` under `modules`.

## Option blocks in templates

A template may hold text for several options:

```
<!-- option: pr -->
...text kept only when the option is pr...
<!-- /option -->
```

Keep the block of the chosen option, delete the other blocks, and delete every marker line. A block may name several options: `<!-- option: branch pr -->`. `verify.sh` fails on a leftover marker.

## Rules for every module

- One home per fact still holds: a module skill carries the project's binding (names, formats, the tool to use), not a general tutorial.
- A module never installs an MCP server and never writes a token, key, or password. It may propose a server entry the user already uses and name the env variable it needs.
- Do not write a server name, package, or URL from memory. Take it from `.mcp.json`, from the user's configured servers, or from the user's answer.
- An option marked "experimental" in `module.md` has not been run on a real project yet. Say so in the plan when it is chosen.
- Adding a module later: `setup --add <name>` runs Steps 1–2 for that module's evidence only, asks its question, generates, and updates `kit.json`.

## Modules

| Module | Decides |
|---|---|
| [git-flow](git-flow/module.md) | How finished work reaches the default branch: direct, branch, or pull request |
| [ticket](ticket/module.md) | Which tracker holds the work items, and how ticket codes appear in branches and commits |
