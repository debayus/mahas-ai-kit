# Module: database

Decides how Claude may work with the project's server-side database: from files only, or also by reading the live database. The engine is detected, not chosen. An on-device store only (sqflite, drift, hive, isar) is covered by the data stack skill and `data-model.md`; this module is for a database that other users or devices share.

## Options

| Option | Meaning | Generates |
|---|---|---|
| `none` | No database rules | nothing |
| `files` | Work from the schema and migration files in the repo; applied migrations are protected from edits | `process-database` skill, entries in `.claude/hooks/protected-paths.txt` |
| `read` | Same, plus read-only inspection of a live database through a connection this machine already has | same files, with the connection named in the skill |

Engines: `supabase` and `firebase` have been checked against real repos by the scan. `sql` (PostgreSQL, SQL Server and Azure SQL, MySQL, through an ORM or plain migration files) is experimental.

## Recommendation (scan section "Database")

Apply the first rule that matches and quote its evidence line in the question:

1. "no database evidence found", or only on-device libraries, or Firebase without a "used in code" line (hosting, messaging, analytics only) → `none`. Do not ask, and do not record it.
2. A database server is listed in `.mcp.json`, or the engine's CLI is installed and the repo has its config (for example `supabase/config.toml` with the `supabase` CLI) → `read`.
3. Migration files, rules files, or a schema file exist → `files`.
4. Otherwise (a server-side database is used in code, but the repo holds no migration, rules, or schema file) → `none`, and still ask. Say in the plan that access rules live outside the repo and cannot be checked from it. Whatever the answer, record how the app reaches the database in `data-model.md`, or in `conventions.md` in tier lite.

For rule 2, "its config" means a database config: `supabase/config.toml`, or a `firebase.json` that has a `firestore` or `database` entry. A hosting-only `firebase.json` does not count, and a CLI on the machine is not evidence on its own.

## Question

"How may Claude work with the `<engine>` database?" — options in recommended order. Then ask only what the scan cannot answer:

- Which environments exist (production, staging, local) and which one the connection above points to. If it points to production, say so in the question.
- May Claude apply a migration to a non-production database after asking each time? Default no. Production is never offered.

## Detecting the engine

| Engine block | Evidence |
|---|---|
| `supabase` | `supabase/migrations/` or `supabase/config.toml` |
| `firebase` | `firestore.rules`, `database.rules.json`, or `firestore.indexes.json` |
| `sql` | A migrations folder, a Prisma or Drizzle schema, Alembic, Django-style migrations, EF Core, or connection strings declared in a config file |

A repo may have more than one. Keep a block for each engine that stores application data, name them all in the one question, and apply the one chosen option to all of them; `kit.json` records the option once. Firebase used only for messaging, analytics, or crash reports is not a database here, and `storage.rules` alone is not database evidence.

Firestore or Realtime Database used in code without a rules file in the repo: the engine is `firebase`, with `{{DB_ACCESS_RULES}}` written as "rules are not in this repository".

## Placeholders

| Placeholder | Fill with |
|---|---|
| `{{DB_ENGINE}}` | The engine and what it holds, in one line |
| `{{DB_ENVIRONMENTS}}` | The environments the user named, and which is production. Identify each by name or project reference only |
| `{{DB_SCHEMA_SOURCE}}` | Where the current schema is read from in the repo: the migrations folder, the schema file, or the rules file, as links. With `data-model.md` present, link to it instead of describing tables. None of these in the repo → link the code that defines the collections or tables |
| `{{DB_MIGRATION_NEW}}` | How a new migration is created here: the command or the file naming pattern, taken from the latest existing migration and the repo's own scripts. An engine without migration files (Firestore) → write that a schema change is a code change plus a rules change in the same commit, and delete the line about applied migrations |
| `{{DB_MIGRATION_CHECK}}` | The command that tests migrations locally if the repo has one (for example a local reset or a migration test script). None → delete the line |
| `{{DB_READ_TOOL}}` | Option `read`: the connection, in this order of preference: an MCP server already configured (name it as configured), then a CLI already logged in. Option `files` → delete the block |
| `{{DB_APPLY_POLICY}}` | The user's answer. Default: "Never apply a migration or run a statement that writes. Give the user the exact command instead." |
| `{{DB_ACCESS_RULES}}` | The access rule of this engine as the repo practises it, with a proving link: row-level security policies for Supabase, security rules for Firebase, the role or schema convention for SQL |

## Protected paths

Add to `.claude/hooks/protected-paths.txt` one glob per folder of applied migrations, written so that existing files are blocked and a new file can still be created. The hook also blocks creating a file that matches, so a glob must never match a name a new migration could get. Timestamped names → one glob per past year (`supabase/migrations/2024*.sql`) and one per past month of the current year (`supabase/migrations/202601*.sql`). Numbered names → list the existing files one by one. Say in the plan that migrations from the current month stay editable until `--update` adds their glob.

Do not protect rules files (`firestore.rules`) or a schema file (`schema.prisma`): they are edited in place.

## Rules

- Resolve the option blocks by engine (`supabase`, `firebase`, `sql`) and by the `read` option.
- Never write a connection string, password, key, or project secret into a generated file, and never read the value of one. Env variable names and config file paths are enough.
- Never add a database server to `.mcp.json`. If the user wants live inspection and no connection exists, generate `files`, name the missing connection in the report, and let them add it.
- A connection that can write is still used read-only. If it points to production, the skill says so in its first section.
- The skill carries the binding and the safety rules. Table and column knowledge stays in `.claude/.agent/data-model.md`.
