# mahas-ai-kit

One command to set up Claude in a project: the code is analyzed first, then a complete but lean configuration is generated to match it.

## Quick start: copy this prompt

Open your project in Claude Code, pick the Fable model (`/model`), then paste:

```
Clone https://github.com/debayus/mahas-ai-kit into a temporary folder outside this project.
Read skills/setup/SKILL.md inside it and follow its steps for this project.
Show me the plan and wait for my approval before creating any file.
```

Claude scans the code, reads the parts it needs, takes templates from this kit, shows you a plan, and after you approve creates the agents, skills, commands, and hooks in your project.

## Permanent install: as a plugin

Once, in Claude Code:

```
/plugin marketplace add debayus/mahas-ai-kit
/plugin install mahas-ai-kit@mahas
```

Then in each project:

```
/mahas-ai-kit:setup            # analyze, show the plan, wait for approval, then generate
/mahas-ai-kit:setup --dry-run  # analysis and plan only
/mahas-ai-kit:setup --lite     # force the light version
/mahas-ai-kit:setup --no-pipeline  # knowledge about the repo only; keep your own way of working
/mahas-ai-kit:setup --add ticket  # add one module to an existing setup
/mahas-ai-kit:setup --update   # check an existing setup against the current code; adopts a hand-made setup without renaming it
```

## What you get

- `CLAUDE.md` of at most 40 lines, with hard rules that each point to the file that proves them.
- Deep docs and stack skills written from your code, not from a general template.
- A plan, code, test, and review pipeline with agents and commands (`/plan`, `/pipeline`, `/test`, `/review-changes`), or knowledge only with `--no-pipeline`.
- Hooks that format after edits and block edits to protected files.

Setup recommends an answer for each choice (git flow, tickets, database, testing) from what it finds in the repo. Only the parts that match the code are generated; small projects get the light version.

## What it never does

It does not overwrite existing files, commit, copy secret values, change analyzer settings without approval, install an MCP server, or add a dependency.

## More detail

| Document | Contents |
|---|---|
| [Choices during setup](docs/choices.md) | Every choice, its options, and what the recommendation is based on; using the kit next to Superpowers, Spec Kit, or BMAD |
| [What a run looks like](docs/example-run.md) | A shortened example of the plan and of the check after generating |
| [What gets created](docs/what-it-creates.md) | Every file and folder, the commands you get, and why it stays cheap |
| [What it has been tried on](docs/tried-on.md) | The stacks it has been run on, so you can judge how far to trust it on yours |
| [Working on the kit](docs/contributing.md) | Running the tests |

The kit is young. On a stack that is not in the tried-on list, start with `--dry-run`.

## License

MIT. See [LICENSE](LICENSE). The files the kit generates in your project are yours, with no conditions.
