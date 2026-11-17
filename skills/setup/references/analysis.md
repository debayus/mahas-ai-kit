# Targeted reading guide

Goal: answer the questions below with the fewest file reads. Prefer Grep and directory listings over reading whole files. Budget: about 25 file reads for a medium repo; never read generated code, lockfiles, or build output.

## Questions to answer (all stacks)

1. **What is it?** One sentence: product, users, platform. Source: README, manifest.
2. **How is the code layered?** Trace ONE representative feature end to end (UI → state/logic → data → storage/network). Record the real folder for each layer.
3. **What must never be broken?** Project invariants. Look for: a single choke point all writes go through, migration/version constants, generated files, comments containing `NEVER`, `JANGAN`, `WAJIB`, `do not`, `must`, `hack`, `workaround`; anything the CI enforces.
4. **How are things named and where do they go?** File naming, feature folder shape, where strings/colors/constants live.
5. **How is it tested?** Test folders, helpers/fakes, how a DB or network is faked, tags, the exact commands, known flaky patterns (look at recent test fixes in `git log`).
6. **How is it built, checked, and released?** Exact analyze, format, test, and run commands; env files needed; CI gates and pinned tool versions.
7. **Where are secrets?** How keys are injected. Record the mechanism only — never copy a value.
8. **Domain vocabulary.** Non-English or business terms a newcomer would misread.

## Stack hints

**Flutter/Dart** — `pubspec.yaml` (state management, DB, backend SDKs), `analysis_options.yaml`, `lib/main.dart`, the router, one feature folder, one repository + its datasource, the DB helper/migrations, `test/helpers/`, `dart_test.yaml`, `.github/workflows/`. Check: `flutter analyze`, `dart format --output=none --set-exit-if-changed <dirs>`, `flutter test`.

**Node tool without a web API (MCP server, CLI, library)** — `package.json` (`bin`, `main`, `type`, `files`, scripts), `tsconfig.json`, the entry point, where tools or commands are registered, one tool traced to the code that does the work, what is written to stdout (for a stdio server it is the protocol, so logs go to stderr), which external APIs are called and where their keys come from, whether it runs from `dist/`.

**Node/TypeScript** — `package.json` scripts, `tsconfig.json`, ESLint/Prettier config, entry point, one route/handler through to the data layer, ORM schema and migrations folder, test setup file.

**Web app without a server of its own (React, Vue, Svelte with Vite or similar)** — `package.json` scripts, the bundler config, the router or the top-level component that switches pages, one page through to the service or hook that reads and writes data, how the backend client is initialised and where its keys come from (`import.meta.env`, a config file), where UI strings live, the hosting config and the CI workflow that deploys. There is often no analyze script: use `tsc --noEmit` when a `tsconfig.json` exists.

**Static or content site (Astro, Next.js export, Eleventy)** — the framework config, the content folder and its schema, one page through to the content it renders, the i18n mechanism, how prices or other facts are kept consistent across pages, the build script (it is often the only gate), the deploy workflow.

**Godot** — `project.godot` (autoloads, main scene, features), one scene with its script, the data resources and how they are loaded, the save format and its version, `addons/` (third-party, do not read), the test runner and its folders, the lint config (`gdlintrc`), export presets. `.uid` and `.import` files are engine sidecars: never read or edit them. Check: the repo's own gate script if it has one; otherwise `gdlint` and `gdformat --check` when gdtoolkit is in the manifest. Tests need the engine binary: without it, record them as unverified.

**Python** — `pyproject.toml`, entry point, settings module, one view/handler through to models, migrations folder, `conftest.py`.

**Go / Rust / other** — manifest, `main`, one request path end to end, migrations, test helpers, Makefile targets.

**Backend-as-a-service (Supabase, Firebase)** — rules/policies files, migrations folder, edge/cloud functions, how the client is initialised, who can read what (role boundaries).

## Stop conditions

Stop reading when all eight questions have an answer or an explicit "not present". Unanswered after the budget → record it as an open question for the user instead of reading more.
