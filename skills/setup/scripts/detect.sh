#!/usr/bin/env bash
# Deterministic repository scan. Prints a compact report for the setup skill.
# Read-only. Run from the repository root.
set -u
PRUNE='-name .git -o -name node_modules -o -name build -o -name dist -o -name .dart_tool -o -name Pods -o -name .gradle -o -name vendor -o -name target -o -name .next -o -name coverage -o -name .venv -o -name venv -o -name __pycache__ -o -name .idea'
ff() { find . \( $PRUNE \) -prune -o -type f "$@" -print 2>/dev/null; }
sec() { printf '\n## %s\n' "$1"; }

echo "# Repo scan: $(basename "$(pwd)")"

sec "Manifests"
for m in pubspec.yaml package.json pyproject.toml requirements.txt go.mod Cargo.toml composer.json Gemfile build.gradle build.gradle.kts pom.xml Package.swift Makefile melos.yaml firebase.json; do
  [ -e "$m" ] && echo "- $m"
done
[ -d supabase ] && echo "- supabase/ ($(ls supabase/migrations 2>/dev/null | wc -l | tr -d ' ') migrations)"
[ -d functions ] && echo "- functions/"

sec "Source files by extension (top 8, generated and vendored folders excluded)"
ff \( -name '*.dart' -o -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.py' -o -name '*.go' -o -name '*.rs' -o -name '*.kt' -o -name '*.swift' -o -name '*.java' -o -name '*.php' -o -name '*.rb' -o -name '*.vue' -o -name '*.sql' \) \
  | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -8

sec "Size"
SRC=$(ff \( -name '*.dart' -o -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.py' -o -name '*.go' -o -name '*.rs' -o -name '*.kt' -o -name '*.swift' -o -name '*.php' \) | grep -vE '(^|/)(test|tests|__tests__|integration_test|spec)/|_test\.|\.test\.|\.spec\.|\.g\.dart$|\.freezed\.dart$' | wc -l | tr -d ' ')
TST=$(ff \( -name '*_test.*' -o -name '*.test.*' -o -name '*.spec.*' -o -name 'test_*.py' \) | wc -l | tr -d ' ')
echo "- source files: $SRC"
echo "- test files: $TST"
if   [ "$SRC" -lt 40 ] || [ "$TST" -eq 0 ]; then echo "- suggested tier: lite"
elif [ "$SRC" -gt 300 ]; then echo "- suggested tier: full"
else echo "- suggested tier: standard (full if persistent data with migrations/sync or multiple roles)"; fi

sec "Top-level folders"
ls -d */ 2>/dev/null | tr '\n' ' '; echo

sec "Largest source files"
ff \( -name '*.dart' -o -name '*.ts' -o -name '*.tsx' -o -name '*.py' -o -name '*.go' \) | grep -vE '\.g\.dart$|\.freezed\.dart$' | xargs wc -l 2>/dev/null | grep -v ' total$' | sort -rn | head -5

sec "Dependencies of interest"
if [ -f pubspec.yaml ]; then
  grep -nE '^\s+(provider|flutter_bloc|bloc|flutter_riverpod|riverpod|get|mobx|signals|sqflite|drift|isar|hive|objectbox|supabase_flutter|cloud_firestore|firebase_[a-z_]+|dio|http|go_router|auto_route|freezed|json_serializable|flutter_secure_storage|shared_preferences|purchases_flutter|flutter_lints|very_good_analysis|mocktail|mockito|integration_test|golden_toolkit):' pubspec.yaml | sed 's/^/- /'
  grep -nE '^\s*(sdk|flutter):\s*["^>=0-9]' pubspec.yaml | head -3 | sed 's/^/- /'
fi
if [ -f package.json ]; then
  grep -nE '"(react|next|vue|nuxt|svelte|express|fastify|nestjs|@nestjs/core|prisma|@prisma/client|drizzle-orm|typeorm|@supabase/supabase-js|firebase|firebase-admin|jest|vitest|playwright|@playwright/test|cypress|eslint|prettier|typescript)"' package.json | sed 's/^/- /'
  echo "- scripts:"; sed -n '/"scripts"/,/}/p' package.json | head -25 | cut -c1-160
fi
[ -f pyproject.toml ] && grep -nE '(django|fastapi|flask|sqlalchemy|alembic|pytest|ruff|black|mypy|pyright)' pyproject.toml | head -12 | sed 's/^/- /'

sec "Quality gates"
for f in analysis_options.yaml .eslintrc .eslintrc.js .eslintrc.json eslint.config.js eslint.config.mjs .prettierrc .prettierrc.json tsconfig.json ruff.toml mypy.ini dart_test.yaml jest.config.js vitest.config.ts .pre-commit-config.yaml lefthook.yml; do
  [ -e "$f" ] && echo "- $f"
done
[ -f analysis_options.yaml ] && { grep -qE 'strict-(casts|inference|raw-types)' analysis_options.yaml && echo "- dart strict modes: on" || echo "- dart strict modes: off"; grep -q 'unawaited_futures' analysis_options.yaml && echo "- unawaited_futures: on" || echo "- unawaited_futures: off"; }
if [ -d .github/workflows ]; then
  for w in .github/workflows/*.y*ml; do
    [ -e "$w" ] || continue
    echo "- CI $w:"; grep -nE '^\s*-?\s*run:' "$w" | head -12 | sed 's/^/    /'
  done
fi

sec "Tests"
for d in test tests __tests__ integration_test e2e spec; do [ -d "$d" ] && echo "- $d/ ($(find "$d" -type f | wc -l | tr -d ' ') files)"; done
for d in test/helpers test/fakes test/mocks tests/fixtures tests/helpers; do [ -d "$d" ] && echo "- helpers: $d/"; done

sec "Env and secret files (names only)"
ls -a 2>/dev/null | grep -E '^\.env|key\.properties|service-account|adminsdk|\.jks$|\.keystore$' | sed 's/^/- /'
[ -f .gitignore ] && { grep -qE '^\s*\.env' .gitignore && echo "- .env ignored by git: yes" || echo "- .env ignored by git: NO (check with the user before assuming this is a mistake)"; }

sec "Invariant markers in code (count)"
N=$(grep -rIiE '(NEVER|JANGAN|WAJIB|DO NOT|MUST NOT|HACK|WORKAROUND)\b' --include='*.dart' --include='*.ts' --include='*.tsx' --include='*.py' --include='*.go' --exclude-dir=node_modules --exclude-dir=build --exclude-dir=.dart_tool . 2>/dev/null | wc -l | tr -d ' ')
echo "- $N lines; list them with: grep -rnIiE '(NEVER|JANGAN|WAJIB|DO NOT|MUST NOT)' <src dir> | head -40"

sec "Existing Claude setup"
for f in CLAUDE.md AGENTS.md .mcp.json; do [ -e "$f" ] && echo "- $f ($(wc -l < "$f" | tr -d ' ') lines)"; done
if [ -d .claude ]; then
  for d in agents skills commands workflows hooks .agent; do [ -d ".claude/$d" ] && echo "- .claude/$d/: $(ls ".claude/$d" | tr '\n' ' ')"; done
  [ -f .claude/settings.json ] && { grep -q '"hooks"' .claude/settings.json && echo "- settings.json: has hooks" || echo "- settings.json: no hooks"; }
else echo "- no .claude/ folder (fresh setup)"; fi

sec "Git"
if git rev-parse --git-dir >/dev/null 2>&1; then
  echo "- branch: $(git branch --show-current 2>/dev/null), commits: $(git rev-list --count HEAD 2>/dev/null), head: $(git rev-parse --short HEAD 2>/dev/null)"
  echo "- recent subjects:"; git log -8 --format='    %s' 2>/dev/null
else echo "- not a git repository"; fi
