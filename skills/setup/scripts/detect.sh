#!/usr/bin/env bash
# Deterministic repository scan. Prints a compact report for the setup skill.
# Read-only. Run from the repository root.
set -u
PRUNE='-name .git -o -name node_modules -o -name build -o -name dist -o -name .dart_tool -o -name Pods -o -name .gradle -o -name vendor -o -name target -o -name .next -o -name coverage -o -name .venv -o -name venv -o -name __pycache__ -o -name .idea -o -name .symlinks -o -name ephemeral'
ff() { find . \( $PRUNE \) -prune -o -type f "$@" -print 2>/dev/null; }
sec() { printf '\n## %s\n' "$1"; }
CODE_EXT="-name *.dart -o -name *.ts -o -name *.tsx -o -name *.js -o -name *.py -o -name *.go -o -name *.rs -o -name *.kt -o -name *.swift -o -name *.php"
MANIFESTS='pubspec.yaml package.json pyproject.toml requirements.txt go.mod Cargo.toml composer.json Gemfile build.gradle build.gradle.kts pom.xml Package.swift'

echo "# Repo scan: $(basename "$(pwd)")"

sec "Manifests"
ROOT_HAS=0
for m in $MANIFESTS; do [ -e "$m" ] && { echo "- $m"; ROOT_HAS=1; }; done
for m in Makefile melos.yaml firebase.json; do [ -e "$m" ] && echo "- $m"; done
[ -d supabase ] && echo "- supabase/ ($(ls supabase/migrations 2>/dev/null | wc -l | tr -d ' ') migrations)"
[ -d functions ] && echo "- functions/"

# App root = the folder that holds the main manifest. It is not always the repo root.
sec "App root"
NESTED=$(find . -maxdepth 3 \( $PRUNE -o -name android -o -name ios -o -name macos -o -name linux -o -name windows \) -prune -o -type f \( -name pubspec.yaml -o -name package.json -o -name pyproject.toml -o -name go.mod -o -name Cargo.toml \) -print 2>/dev/null | sed 's|^\./||' | grep / | sort | head -12)
APP=.
if [ "$ROOT_HAS" -eq 0 ] && [ -n "$NESTED" ]; then
  best=-1
  for m in $NESTED; do
    d=$(dirname "$m")
    # shellcheck disable=SC2086
    n=$(set -f; find "$d" \( $PRUNE \) -prune -o -type f \( $CODE_EXT \) -print 2>/dev/null | wc -l | tr -d ' ')
    [ "$n" -gt "$best" ] && { best=$n; APP=$d; }
  done
fi
if [ "$APP" = . ]; then
  [ "$ROOT_HAS" -eq 1 ] && echo "- primary app root: . (the repository root)" || echo "- no manifest found at the root or two levels below it"
else
  echo "- primary app root: $APP/ — the root has no manifest; run analyze, test, and build commands from $APP/"
fi
[ -n "$NESTED" ] && { echo "- nested manifests:"; echo "$NESTED" | sed 's/^/    /'; }

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
if [ -f "$APP/pubspec.yaml" ]; then
  grep -nE '^\s+(provider|flutter_bloc|bloc|flutter_riverpod|riverpod|get|mobx|signals|sqflite|drift|isar|hive|objectbox|supabase_flutter|cloud_firestore|firebase_[a-z_]+|sentry_flutter|dio|http|go_router|auto_route|freezed|json_serializable|flutter_secure_storage|shared_preferences|purchases_flutter|flutter_lints|very_good_analysis|mocktail|mockito|integration_test|golden_toolkit):' "$APP/pubspec.yaml" | sed 's/^/- /'
  grep -nE '^\s*(sdk|flutter):\s*["^>=0-9]' "$APP/pubspec.yaml" | head -3 | sed 's/^/- /'
fi
if [ -f "$APP/package.json" ]; then
  grep -nE '"(react|next|vue|nuxt|svelte|express|fastify|nestjs|@nestjs/core|prisma|@prisma/client|drizzle-orm|typeorm|@supabase/supabase-js|firebase|firebase-admin|@sentry/[a-z-]+|jest|vitest|playwright|@playwright/test|cypress|eslint|prettier|typescript)"' "$APP/package.json" | sed 's/^/- /'
  echo "- scripts:"; sed -n '/"scripts"/,/}/p' "$APP/package.json" | head -25 | cut -c1-160
fi
[ -f "$APP/pyproject.toml" ] && grep -nE '(django|fastapi|flask|sqlalchemy|alembic|sentry|pytest|ruff|black|mypy|pyright)' "$APP/pyproject.toml" | head -12 | sed 's/^/- /'

sec "Quality gates"
for f in analysis_options.yaml .eslintrc .eslintrc.js .eslintrc.json eslint.config.js eslint.config.mjs .prettierrc .prettierrc.json tsconfig.json ruff.toml mypy.ini dart_test.yaml jest.config.js vitest.config.ts .pre-commit-config.yaml lefthook.yml; do
  [ -e "$APP/$f" ] && echo "- ${APP#.}${APP:+/}$f" | sed 's|^- /|- |'
done
AO="$APP/analysis_options.yaml"
[ -f "$AO" ] && { grep -qE 'strict-(casts|inference|raw-types)' "$AO" && echo "- dart strict modes: on" || echo "- dart strict modes: off"; grep -q 'unawaited_futures' "$AO" && echo "- unawaited_futures: on" || echo "- unawaited_futures: off"; }
if [ -d .github/workflows ]; then
  for w in .github/workflows/*.y*ml; do
    [ -e "$w" ] || continue
    echo "- CI $w:"; grep -nE '^\s*-?\s*run:' "$w" | head -12 | sed 's/^/    /'
  done
fi

sec "Tests"
for d in test tests __tests__ integration_test e2e spec; do [ -d "$APP/$d" ] && echo "- $APP/$d/ ($(find "$APP/$d" -type f | wc -l | tr -d ' ') files)"; done
for d in test/helpers test/fakes test/mocks tests/fixtures tests/helpers; do [ -d "$APP/$d" ] && echo "- helpers: $APP/$d/"; done

sec "Env and secret files (names only)"
for d in . "$APP"; do
  ls -a "$d" 2>/dev/null | grep -E '^\.env|key\.properties|service-account|adminsdk|\.jks$|\.keystore$' | sed "s|^|- $d/|"
  [ "$APP" = . ] && break
done
[ -f .gitignore ] && { grep -qE '^\s*\.env' .gitignore && echo "- .env ignored by git: yes" || echo "- .env ignored by git: NO (check with the user before assuming this is a mistake)"; }

sec "Invariant markers in code (count)"
N=$(grep -rIiE '(NEVER|JANGAN|WAJIB|DO NOT|MUST NOT|HACK|WORKAROUND)\b' --include='*.dart' --include='*.ts' --include='*.tsx' --include='*.py' --include='*.go' --exclude-dir=node_modules --exclude-dir=build --exclude-dir=.dart_tool . 2>/dev/null | wc -l | tr -d ' ')
echo "- $N lines; list them with: grep -rnIiE '(NEVER|JANGAN|WAJIB|DO NOT|MUST NOT)' <src dir> | head -40"

# Evidence for the optional operations pieces (deploy, crash triage). Names and paths only.
sec "Release and operations signals"
[ -f "$APP/pubspec.yaml" ] && grep -m1 -nE '^version:' "$APP/pubspec.yaml" | sed "s|^|- $APP/pubspec.yaml:|"
if [ -d "$APP/android" ]; then
  [ -f "$APP/android/key.properties" ] && echo "- android: release signing file present ($APP/android/key.properties)" || echo "- android: folder present, no key.properties (no release signing found)"
  for g in "$APP/android/app/build.gradle.kts" "$APP/android/app/build.gradle"; do
    [ -f "$g" ] && { echo "- $g:"; grep -nE 'applicationId|key\.properties' "$g" | head -3 | cut -c1-140 | sed 's/^/    /'; }
  done
fi
if [ -d "$APP/ios" ]; then
  P="$APP/ios/Runner.xcodeproj/project.pbxproj"
  echo "- ios: folder present$([ -f "$P" ] && grep -m1 -oE 'PRODUCT_BUNDLE_IDENTIFIER = [^;]+' "$P" | sed 's/^/, /')"
fi
for d in fastlane "$APP/fastlane" "$APP/android/fastlane" "$APP/ios/fastlane"; do [ -d "$d" ] && echo "- fastlane folder: $d/"; done
command -v fastlane >/dev/null 2>&1 && echo "- fastlane CLI: installed" || echo "- fastlane CLI: not installed"
for m in "$APP/pubspec.yaml" "$APP/package.json" "$APP/pyproject.toml" "$APP/requirements.txt"; do
  [ -f "$m" ] && grep -nE 'firebase_crashlytics|sentry|bugsnag' "$m" | head -2 | cut -c1-120 | sed "s|^|- crash SDK in $m:|"
done
if [ -f .mcp.json ] && command -v python3 >/dev/null 2>&1; then
  echo "- .mcp.json servers: $(python3 -c 'import json;print(", ".join(json.load(open(".mcp.json")).get("mcpServers",{}).keys()) or "none")' 2>/dev/null)"
fi
for d in scripts tool "$APP/scripts" "$APP/tool"; do
  [ -d "$d" ] && ls "$d" 2>/dev/null | grep -iE 'release|deploy|gate|build' | head -6 | sed "s|^|- release script: $d/|"
  [ "$APP" = . ] && [ "$d" = tool ] && break
done

sec "Existing Claude setup"
for f in CLAUDE.md AGENTS.md .mcp.json; do [ -e "$f" ] && echo "- $f ($(wc -l < "$f" | tr -d ' ') lines)"; done
if [ -d .claude ]; then
  for d in agents skills commands workflows hooks .agent; do [ -d ".claude/$d" ] && echo "- .claude/$d/: $(ls ".claude/$d" | tr '\n' ' ')"; done
  [ -f .claude/settings.json ] && { grep -q '"hooks"' .claude/settings.json && echo "- settings.json: has hooks" || echo "- settings.json: no hooks"; }
  if [ -f .claude/kit.json ]; then echo "- kit record: $(tr -d '\n' < .claude/kit.json | cut -c1-300)"
  else echo "- kit record: none (set up by hand or by an older kit — use the adoption rules in update mode)"; fi
else echo "- no .claude/ folder (fresh setup)"; fi

sec "Git"
if git rev-parse --git-dir >/dev/null 2>&1; then
  echo "- branch: $(git branch --show-current 2>/dev/null), commits: $(git rev-list --count HEAD 2>/dev/null), head: $(git rev-parse --short HEAD 2>/dev/null)"
  def=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
  [ -z "$def" ] && for b in main master develop; do git show-ref --verify --quiet "refs/heads/$b" && { def=$b; break; }; done
  echo "- default branch: ${def:-unknown}"
  pre=$(git for-each-ref --format='%(refname:short)' refs/heads refs/remotes 2>/dev/null | sed 's|^origin/||' | grep / | cut -d/ -f1 | sort | uniq -c | sort -rn | head -5 | awk '{printf "%s/ (%s) ", $2, $1}')
  echo "- branch name prefixes: ${pre:-none}"
  echo "- recent subjects:"; git log -8 --format='    %s' 2>/dev/null
  # Evidence for the git-flow module (last 200 commits).
  echo "- commit authors (last 200): $(git log -200 --format='%ae' 2>/dev/null | sort -u | wc -l | tr -d ' ')"
  echo "- PR merges (last 200): $(git log -200 --format='%s' 2>/dev/null | grep -cE '^Merge pull request #|\(#[0-9]+\)$')"
  host=$(git remote get-url origin 2>/dev/null | sed -E 's|^[a-z+]+://||; s|^[^@/]*@||; s|[:/].*$||')
  echo "- remote host: ${host:-none}"
  cli=""; for c in gh glab az; do command -v "$c" >/dev/null 2>&1 && cli="$cli $c"; done
  echo "- PR CLIs installed:${cli:- none}"
  for t in .github/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md docs/pull_request_template.md .gitlab/merge_request_templates; do [ -e "$t" ] && echo "- PR template: $t"; done

  # Evidence for the ticket module (last 200 commit subjects and branch names).
  sec "Tickets"
  subj=$(git log -200 --format='%s' 2>/dev/null)
  echo "- subjects with 'Trello #N': $(printf '%s\n' "$subj" | grep -ciE 'trello ?#[0-9]+')"
  keys=$(printf '%s\n' "$subj" | grep -oE '(^|[^A-Za-z0-9])[A-Z][A-Z0-9]{1,9}-[0-9]+' | sed -E 's/^[^A-Z]//; s/-[0-9]+$//' | sort | uniq -c | sort -rn | head -3 | awk '{printf "%s×%s ", $2, $1}')
  echo "- subjects with a KEY-123 code: $(printf '%s\n' "$subj" | grep -cE '(^|[^A-Za-z0-9])[A-Z][A-Z0-9]{1,9}-[0-9]+')${keys:+ — keys: $keys}"
  echo "- subjects with a bare #N (not Trello, not a PR merge): $(printf '%s\n' "$subj" | grep -viE 'trello ?#|^Merge pull request' | grep -cE '#[0-9]+')"
  echo "- branches with a ticket code: $(git for-each-ref --format='%(refname:short)' refs/heads refs/remotes 2>/dev/null | grep -cE '[A-Z][A-Z0-9]+-[0-9]+|/[0-9]+-')"
  ex=$(printf '%s\n' "$subj" | grep -iE 'trello ?#[0-9]+|[A-Z][A-Z0-9]+-[0-9]+|#[0-9]+' | head -2 | cut -c1-110 | sed 's/^/    /')
  [ -n "$ex" ] && { echo "- examples:"; echo "$ex"; }
else echo "- not a git repository"; fi
