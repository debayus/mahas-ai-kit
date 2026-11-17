#!/usr/bin/env bash
# Test suite for the kit's own scripts and templates. Run from anywhere: bash tests/run.sh
# Needs bash, git, and python3. Writes only to a temporary folder.
set -u
KIT=$(cd "$(dirname "$0")/.." && pwd)
VERIFY="$KIT/skills/setup/scripts/verify.sh"
DETECT="$KIT/skills/setup/scripts/detect.sh"
BUILD="$KIT/tests/build_setup.py"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/kit-tests.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
pass=0; failed=0
yes() { echo "ok   $1"; pass=$((pass+1)); }
no()  { echo "FAIL $1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/       /' | head -12; failed=$((failed+1)); }

# --- verify.sh on setups built from the templates -------------------------------------

build() { # name, then build_setup.py arguments
  local name=$1; shift
  python3 "$BUILD" "$KIT" "$TMP/$name" "$@" 2> "$TMP/$name.err" || no "build from templates: $name" "$(tail -1 "$TMP/$name.err")"
}
expect_pass() { # name [verify arguments]
  local name=$1; shift
  local out; out=$(cd "$TMP/$name" && bash "$VERIFY" "$@" 2>&1)
  if printf '%s\n' "$out" | grep -q '^RESULT: PASS$'; then yes "verify passes: $name"
  else no "verify should pass: $name" "$(printf '%s\n' "$out" | grep -E '^FAIL' )"; fi
}
expect_fail() { # name, text the failure must contain [verify arguments]
  local name=$1 want=$2; shift 2
  local out; out=$(cd "$TMP/$name" && bash "$VERIFY" "$@" 2>&1)
  if printf '%s\n' "$out" | grep -q '^RESULT: FAIL$' && printf '%s\n' "$out" | grep -qF "$want"; then yes "verify rejects: $name"
  else no "verify should reject: $name (expected \"$want\")" "$(printf '%s\n' "$out" | tail -4)"; fi
}

echo "## Templates resolve to a setup that passes"
build standard-direct     --modules git-flow --options direct
build standard-branch     --modules git-flow --options branch
build standard-pr-ticket  --modules git-flow,ticket --options pr
build testing-existing    --modules git-flow,testing --options branch
build testing-extended    --modules git-flow,ticket,testing --options branch,golden,e2e,load,coverage
build db-supabase-read    --modules git-flow,database --options branch,supabase,read
build db-firebase-files   --modules git-flow,database --options branch,firebase
build db-sql-files        --modules database --options sql
build protect-only        --modules git-flow --options branch --no-format
build lite                --tier lite
build knowledge-only      --no-pipeline --modules ticket,database --options supabase
build everything          --modules git-flow,ticket,testing,database --options pr,golden,e2e,load,coverage,supabase,firebase,read
for s in standard-direct standard-branch standard-pr-ticket testing-existing testing-extended db-supabase-read db-firebase-files db-sql-files protect-only lite knowledge-only everything; do
  expect_pass "$s"
done

echo "## verify.sh rejects a broken setup"
bad() { build "$1" --modules git-flow --options branch; }
bad bad-placeholder; echo 'Uses {{TEST_CMD}} here.' >> "$TMP/bad-placeholder/CLAUDE.md"
expect_fail bad-placeholder "leftover placeholders"
bad bad-marker; printf '<!-- option: pr -->\nx\n<!-- /option -->\n' >> "$TMP/bad-marker/.claude/commands/plan.md"
expect_fail bad-marker "leftover option markers"
bad bad-hook; printf '#!/usr/bin/env bash\nexit 0\n' > "$TMP/bad-hook/.claude/hooks/extra.sh"; chmod +x "$TMP/bad-hook/.claude/hooks/extra.sh"
expect_fail bad-hook "extra.sh exists but is not wired"
bad bad-link; echo 'See [missing](.claude/.agent/missing.md).' >> "$TMP/bad-link/CLAUDE.md"
expect_fail bad-link "broken link"
bad bad-skill-ref; echo 'Load the `process-nothing` skill.' >> "$TMP/bad-skill-ref/.claude/agents/planner.md"
expect_fail bad-skill-ref "skill 'process-nothing' is referenced but does not exist"
bad bad-size; for i in $(seq 1 45); do echo "line $i" >> "$TMP/bad-size/CLAUDE.md"; done
expect_fail bad-size "CLAUDE.md has"
bad bad-skill-cap
for i in 1 2 3 4 5 6 7 8; do d="$TMP/bad-skill-cap/.claude/skills/process-extra$i"; mkdir -p "$d"; printf -- '---\nname: process-extra%s\ndescription: x\n---\n' "$i" > "$d/SKILL.md"; done
expect_fail bad-skill-cap "skills in total (max 10)"
bad bad-name; sed -i.bak 's/^name: process-planning$/name: planning/' "$TMP/bad-name/.claude/skills/process-planning/SKILL.md"; rm -f "$TMP/bad-name/.claude/skills/process-planning/SKILL.md.bak"
expect_fail bad-name "name must equal folder name"
bad bad-json; echo '{' > "$TMP/bad-json/.claude/settings.json"
expect_fail bad-json "settings.json is not valid JSON"
bad bad-secret; echo 'key: sk_live_abcdefghijklmnop' >> "$TMP/bad-secret/.claude/README.md"
expect_fail bad-secret "possible secrets"
bad no-record; rm "$TMP/no-record/.claude/kit.json" "$TMP/no-record/.claude/README.md"
expect_fail no-record "kit.json missing"

bad bad-hot-rules; for i in 1 2 3 4 5 6 7; do sed -i.bak "s|^## Run\$|- Rule $i, see [README](README.md).\\
## Run|" "$TMP/bad-hot-rules/CLAUDE.md"; done; rm -f "$TMP/bad-hot-rules/CLAUDE.md.bak"
expect_fail bad-hot-rules "7 hot rules in CLAUDE.md (max 6)"
bad bad-hot-link; sed -i.bak 's|^## Run$|- A rule with no proof.\
## Run|' "$TMP/bad-hot-link/CLAUDE.md"; rm -f "$TMP/bad-hot-link/CLAUDE.md.bak"
expect_fail bad-hot-link "without a link to the file that proves"
bad bad-command; echo 'Then run `/ship <request>`.' >> "$TMP/bad-command/.claude/commands/plan.md"
expect_fail bad-command "command '/ship' is named"
bad bad-agent; echo 'Spawn the `deployer` agent.' >> "$TMP/bad-agent/.claude/commands/plan.md"
expect_fail bad-agent "agent 'deployer' is named"

echo "## verify.sh does not flag what is fine"
bad fine-refs
{ echo 'Run `flutter analyze`/build first, use `/clear` after, and see `/lib` for sources.'; echo 'Use `mcp__trello__get_card` to read the card.'; } >> "$TMP/fine-refs/.claude/commands/plan.md"
mkdir -p "$TMP/fine-refs/lib" "$TMP/fine-refs/.claude/worktrees/x"; echo 'Leftover {{TEST_CMD}} in another checkout.' > "$TMP/fine-refs/.claude/worktrees/x/CLAUDE.md"
expect_pass fine-refs
out=$(cd "$TMP/fine-refs" && bash "$VERIFY" 2>&1)
printf '%s\n' "$out" | grep -q "MCP server 'trello' are named" && yes "an MCP server missing from .mcp.json is a warning" || no "an MCP server missing from .mcp.json is a warning" "$(printf '%s\n' "$out" | grep -i mcp)"

echo "## --existing turns size and record problems into warnings"
expect_pass no-record --existing
expect_pass bad-size --existing
expect_fail bad-placeholder "leftover placeholders" --existing

# --- the protect hook ------------------------------------------------------------------

echo "## protect-files.sh blocks protected paths, also in another worktree"
H="$TMP/hookrepo"; mkdir -p "$H" && cd "$H" && git init -q -b main . && git config user.email a@example.com && git config user.name "Dev One"
mkdir -p .claude/hooks supabase/migrations lib
cp "$KIT"/skills/setup/templates/hooks/*.sh .claude/hooks/
printf 'supabase/migrations/2024*.sql\npubspec.lock\n' > .claude/hooks/protected-paths.txt
echo 'select 1;' > supabase/migrations/20240101000000_init.sql
git add -A && git commit -q -m init
git worktree add -q "$TMP/hook-wt-outside" -b wt-a
git worktree add -q .claude/worktrees/inside -b wt-b
hook() { # file path -> exit status of the hook
  printf '{"tool_input":{"file_path":"%s"}}' "$1" | CLAUDE_PROJECT_DIR="$H" bash "$H/.claude/hooks/protect-files.sh" 2>/dev/null; echo $?
}
blocked() { [ "$(hook "$2")" = 2 ] && yes "blocked: $1" || no "should be blocked: $1"; }
allowed() { [ "$(hook "$2")" = 0 ] && yes "allowed: $1" || no "should be allowed: $1"; }
blocked "applied migration in the main checkout" "$H/supabase/migrations/20240101000000_init.sql"
blocked "new file matching a protected glob" "$H/supabase/migrations/20241231000000_new.sql"
blocked "the same file in a worktree outside the project" "$TMP/hook-wt-outside/supabase/migrations/20240101000000_init.sql"
blocked "the same file in a worktree inside .claude/" "$H/.claude/worktrees/inside/supabase/migrations/20240101000000_init.sql"
blocked "protected file at the root" "$H/pubspec.lock"
allowed "a migration from another year" "$H/supabase/migrations/20260101000000_new.sql"
allowed "ordinary source file" "$H/lib/main.dart"
allowed "new file in a folder that does not exist yet" "$H/lib/new/deep/file.dart"
# Without git, and reached through a symlink: the path is spelled differently from the root.
N="$TMP/hook-nogit"; mkdir -p "$N/.claude/hooks" && cp "$KIT"/skills/setup/templates/hooks/*.sh "$N/.claude/hooks/" && echo '.env' > "$N/.claude/hooks/protected-paths.txt" && ln -s "$N" "$TMP/hook-link"
r=$(printf '{"tool_input":{"file_path":"%s"}}' "$TMP/hook-link/.env" | CLAUDE_PROJECT_DIR="$N" bash "$N/.claude/hooks/protect-files.sh" 2>/dev/null; echo $?)
[ "$r" = 2 ] && yes "blocked: protected file reached through a symlink, no git" || no "should be blocked: protected file reached through a symlink, no git"

# --- detect.sh on small repositories ---------------------------------------------------

repo() { # name: creates an empty git repository and enters it
  mkdir -p "$TMP/$1" && cd "$TMP/$1" && git init -q -b main . && git config user.email a@example.com && git config user.name "Dev One"
}
commit() { git commit -q --allow-empty -m "$1"; }
scan() { bash "$DETECT" 2>&1; }
has()  { if printf '%s\n' "$OUT" | grep -qF -- "$2"; then yes "$1"; else no "$1 (expected: $2)" "$(printf '%s\n' "$OUT" | grep -iE "${3:-xxxxxxxx}")"; fi; }
hasnt() { if printf '%s\n' "$OUT" | grep -qF -- "$2"; then no "$1 (unexpected: $2)"; else yes "$1"; fi; }

echo "## detect.sh: git history"
repo r-git
commit "feat: first"
commit "Merge pull request #1 from x/y"
commit "Merge pull request #2 from x/z"
commit "fix: total rounding (#1928)"
commit "fix: stock sync (#1930)"
commit "feat: receipts (#1931)"
commit "Merge branch 'feature/a'"
git -c user.email=other@example.com commit -q --allow-empty -m "chore: same person, second email"
git -c user.name="Claude" -c user.email=noreply@example.com commit -q --allow-empty -m "chore: automated"
OUT=$(scan); code=$?
[ "$code" -eq 0 ] && yes "exit status 0 on a successful scan" || no "exit status 0 on a successful scan (got $code)"
has "PR merges are counted on their own" "'Merge pull request #N' commits (last 200): 2" "Merge pull"
has "(#N) endings are counted apart from PR merges" "(last 200; a squash-merged PR or a ticket number — check against the Tickets section): 3" "ending in"
has "local branch merges are counted" "'Merge branch ...' (last 200): 1" "local branch"
has "one person with two emails is one author; automation is separate" "human commit authors by name (last 200): 1; automated authors: 1" "authors"
git checkout -q -b wt/t2101 && commit "fix: on a ticket branch" && git checkout -q main && git merge -q --no-ff -m "Merge branch 'wt/t2101'" wt/t2101 && git branch -q -D wt/t2101
OUT=$(scan)
has "a merged, deleted ticket branch is still seen" "branch names with a ticket code (live and merged): 1 — for example: wt/t2101" "ticket code"
has "merged branch prefixes are listed" "merged branch name prefixes (from merge subjects): wt/ (1)" "prefixes"
has "a repo with nothing to release says so" "- none found" "none"
has "no .claude folder is a fresh setup" "no .claude/ folder (fresh setup)" "claude"

echo "## detect.sh: tests, data libraries, existing setup"
repo r-flutter
mkdir -p lib test/unit integration_test .claude supabase/migrations
cat > pubspec.yaml <<'EOF'
name: mock
dependencies:
  archive: ^3.0.0
  supabase_flutter: ^2.0.0
  # drift: was replaced
EOF
echo 'void main() {}' > lib/main.dart
echo '// whenever the perpanjangan runs' > lib/note.dart
echo 'void main() {}' > test/unit/a_test.dart
echo 'void main() {}' > test/unit/b_test.dart
echo 'void main() {}' > integration_test/app_test.dart
echo 'select 1;' > supabase/migrations/20260101000000_init.sql
echo 'select 1;' > test/seed_test.sql
echo '{}' > .claude/launch.json
echo 'SECRET=x' > .env
git add -A && commit "feat: app"
OUT=$(scan)
has "test files are counted by code extension only" "- test files: 3" "test files"
has "unit count is not reduced twice" "- unit and component: 2 test files" "unit and"
has "Flutter integration_test files are end-to-end, not integration" "- end-to-end: 1 test files" "end-to-end"
has "integration count excludes them" "- integration: 0 test files" "integration:"
hasnt "\"archive\" is not read as the hive library" "hive"
hasnt "a library named only in a comment is not listed" "drift"
has "supabase migrations are found" "supabase migrations: ./supabase/migrations/ (1 files" "supabase"
has "a .claude folder without agents, skills, or commands is a fresh setup" "treat as a fresh setup" "claude"
has "a tracked .env is flagged" "TRACKED IN GIT" "env"
has "\"whenever\" and \"perpanjangan\" are not invariant markers" "- 0 lines (text" "lines"

echo "## detect.sh: ticket evidence and folders without git"
repo r-tickets
commit "feat: start"
for i in 1 2 3 4 5; do git commit -q --allow-empty -m "docs(DEC-$i): record a decision" -m "Refs: https://trello.com/c/abc$i/1-card"; done
commit "Merge pull request #7 from someone/feat/new-thing"
OUT=$(scan)
has "tracker links in commit bodies are counted" "tracker links in commit bodies: trello.com 5" "tracker links"
has "a KEY code comes with the warning about ids defined in docs" "is not a ticket)" "KEY-123"
has "branch prefixes are read from PR merges too" "merged branch name prefixes (from merge subjects): feat/ (1)" "prefixes"
mkdir -p "$TMP/r-nogit/src" && cd "$TMP/r-nogit"
printf '{\n  "name": "tool",\n  "dependencies": { "@modelcontextprotocol/sdk": "^1.0.0" }\n}\n' > package.json
echo 'export {}' > src/index.mjs; echo 'junk' > src/._index.mjs; echo '.env' > .gitignore
OUT=$(GIT_CEILING_DIRECTORIES="$TMP" scan); code=$?
[ "$code" -eq 0 ] && yes "a folder without git scans with exit status 0" || no "a folder without git scans with exit status 0"
has "a folder without git is named as such" "not a git repository: no branch, no commit, no history" "git"
has "the Tickets section still exists without git" "no git history to read ticket codes from" "ticket"
hasnt "nothing is claimed about .gitignore without git" ".env ignored by git"
has ".mjs is source and macOS metadata files are not" "- source files: 1" "source files"

echo "## detect.sh: other stacks"
repo r-godot
printf 'config/name="Mock"\nconfig/features=PackedStringArray("4.7")\n' > project.godot
mkdir -p scripts tests/unit tests/integration addons/gut .specify
echo 'extends Node' > scripts/player.gd
echo 'extends Node' > addons/gut/plugin.gd
echo 'extends GutTest' > tests/unit/test_player.gd
echo 'extends GutTest' > tests/integration/test_save.gd
git add -A && commit "feat: game"
OUT=$(scan)
has "a Godot project is recognised by its manifest" "- project.godot" "godot"
has "GDScript counts as source, addons excluded" "- source files: 1" "source files"
has "GDScript tests are counted by level" "- unit and component: 1 test files (by extension: gd 1" "unit and"
has "a workflow framework folder is reported" "workflow framework folders: .specify/" "workflow"
repo r-astro
mkdir -p site/src/pages site/.astro
printf '{\n  "name": "site",\n  "dependencies": {\n    "astro": "^6.0.0"\n  }\n}\n' > site/package.json
echo '<h1>x</h1>' > site/src/pages/index.astro
echo 'export {}' > site/.astro/content.d.ts
git add -A && commit "feat: site"
OUT=$(scan)
has "the app root is found in a subfolder" "primary app root: site/" "app root"
has "Astro is listed as a dependency of interest" '"astro": "^6.0.0"' "astro"
has ".astro pages count as source, generated .astro/ does not" "- source files: 1" "source files"

echo "## detect.sh: empty repository and Firestore in code"
repo r-web
cat > package.json <<'EOF'
{
  "name": "mock",
  "version": "1.2.3",
  "dependencies": { "firebase": "^11.0.0", "react": "^19.0.0" },
  "scripts": { "build": "vite build" }
}
EOF
mkdir -p .github/workflows
cat > .github/workflows/deploy.yml <<'EOF'
on:
  push:
    branches: [main]
jobs:
  deploy:
    steps:
      - uses: FirebaseExtended/action-hosting-deploy@v0
EOF
mkdir -p src && echo "import { getFirestore } from 'firebase/firestore'" > src/db.ts
echo '{ "hosting": {} }' > firebase.json
git add -A && commit "feat: web"
OUT=$(scan)
has "no test files is stated" "- no test files found" "test"
has "a repo without tests is tier lite" "suggested tier: lite" "tier"
has "Firestore used in code is reported" "Firestore or Realtime Database used in code: 1 files" "Firestore"
has "the package.json version is listed under release signals" "- ./package.json:3: \"version\": \"1.2.3\"" "version"
has "a deploy done by CI is listed under release signals" "- deploy in CI:" "deploy"
has "firebase.json alone is not called a database" "not by itself a database" "firebase.json"

echo
echo "$pass passed, $failed failed"
[ "$failed" -eq 0 ]
