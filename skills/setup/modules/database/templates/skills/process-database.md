---
name: process-database
description: Database rules for {{PROJECT_NAME}} — which database and environments exist, where the schema is read from, how a migration is written, what may be read or run against a live database, and what is never done. Load before writing or changing a migration, a security rule or policy, or a query that changes stored data, and before inspecting a live database.
---

# Database — {{PROJECT_NAME}}

## Binding

- Engine: {{DB_ENGINE}}
- Environments: {{DB_ENVIRONMENTS}}
- Schema source: {{DB_SCHEMA_SOURCE}}
<!-- option: read -->
- Live inspection: {{DB_READ_TOOL}}
<!-- /option -->

## Changing the schema

- Read the schema source first. Do not guess a table, column, or field name.
- A change is always a new migration: {{DB_MIGRATION_NEW}}
- Never edit or delete a migration that has been applied. The protected-paths hook blocks it; if it blocks you, write a new migration that corrects the old one.
- Every migration must be safe for rows that already exist: a new required column needs a default or a backfill in the same migration, and a rename or type change must keep the code that is live now working until the new code is released.
- Say in your report whether the change can be undone, and what data is lost if it is.
- {{DB_MIGRATION_CHECK}}
<!-- option: supabase -->
- A new table gets row-level security in the same migration that creates it. {{DB_ACCESS_RULES}}
- A function that runs with the definer's rights sets its `search_path` and checks the caller itself.
<!-- /option -->
<!-- option: firebase -->
- A new collection or path gets its security rule in the same change. {{DB_ACCESS_RULES}}
- A query that needs a composite index gets its entry in the indexes file in the same change.
<!-- /option -->
<!-- option: sql -->
- {{DB_ACCESS_RULES}}
- One migration does one thing. Do not mix a schema change and a large data rewrite in one file.
<!-- /option -->

## Running anything against a database

{{DB_APPLY_POLICY}}

<!-- option: read -->
With the inspection connection: read-only statements only (schema, counts, a few rows to understand a shape). Limit every row query. Do not copy personal data (names, phone numbers, emails, addresses) into a report, a ticket, a commit, or a test; describe the shape instead.
<!-- /option -->

Never, on any environment, without the user asking for that exact action in this session: drop or truncate a table, delete rows without a narrow condition, turn off an access rule, reset a database, or restore a backup.

Never on production: apply a migration, run a statement that writes, or change a setting. Give the user the exact command and what it will change.

## When something is wrong in the data

Report what you found, how many rows, and since when, with the query that shows it. Propose the fix as a migration or a script for the user to review. Do not repair data directly.
