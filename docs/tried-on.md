# What it has been tried on

The kit is young. This is what has actually been run, so you can judge how far to trust it on your stack.

| Stack | Scan | Dry-run of the full setup |
|---|---|---|
| Flutter with Supabase and Firebase | yes | yes, including adoption of a hand-made setup |
| React + Vite + TypeScript with Firestore | yes | yes |
| Node.js + TypeScript tool (MCP server), no git repository | yes | yes |
| Godot 4 (GDScript) with Python tooling | yes | yes, adoption |
| Astro static site | yes | no |
| Next.js, Django, FastAPI, Go, Rust, .NET | fixtures only, or not at all | no |

A dry-run follows every step up to the plan and checks it against `verify.sh`; it stops before writing files. Each of these runs turned up defects. The ones that could be reproduced are fixed and covered by `tests/run.sh`. Expect more on a stack that is not listed: start with `--dry-run`, and please report what looks wrong.

[Back to the README](../README.md)
