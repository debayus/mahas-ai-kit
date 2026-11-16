#!/usr/bin/env bash
# Deterministic repository scan. Prints a compact report for the setup skill.
# Read-only. Run from the repository root.
set -u
PRUNE='-name .git -o -name .claude -o -name node_modules -o -name build -o -name dist -o -name .dart_tool -o -name Pods -o -name .gradle -o -name vendor -o -name target -o -name .next -o -name coverage -o -name .venv -o -name venv -o -name __pycache__ -o -name .idea -o -name .symlinks -o -name ephemeral'
ff() { find . \( $PRUNE \) -prune -o -type f "$@" -print 2>/dev/null; }
sec() { printf '\n## %s\n' "$1"; }
CODE_EXT="-name *.dart -o -name *.ts -o -name *.tsx -o -name *.js -o -name *.py -o -name *.go -o -name *.rs -o -name *.kt -o -name *.swift -o -name *.php"
MANIFESTS='pubspec.yaml package.json pyproject.toml requirements.txt go.mod Cargo.toml composer.json Gemfile build.gradle build.gradle.kts pom.xml Package.swift'

echo "# Repo scan: $(basename "$(pwd)")"

sec "Manifests"
ROOT_HAS=0
for m in $MANIFESTS; do [ -e "$m" ] && { echo "- $m"; ROOT_HAS=1; }; done
for m in Makefile melos.yaml firebase.json; do [ -e "$m" ] && echo "- $m"; done
[ -d supabase ] && echo "- supabase/ ($(ls supabase/migrations 2>/dev/null | grep -c '\.sql$') migrations)"
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
TEXT='\.(dart|ts|tsx|js|jsx|mjs|py|go|rs|kt|swift|php|rb)$'
TST=$(ff \( -name '*_test.*' -o -name '*.test.*' -o -name '*.spec.*' -o -name 'test_*.py' \) | grep -cE "$TEXT")
echo "- source files: $SRC"
echo "- test files: $TST"
if   [ "$SRC" -lt 40 ] || [ "$TST" -eq 0 ]; then echo "- suggested tier: lite (add single pieces from a higher tier if the code has shared data or several roles)"
elif [ "$SRC" -gt 300 ]; then echo "- suggested tier: full"
else echo "- suggested tier: standard (full if persistent data with migrations/sync or multiple roles)"; fi

sec "Top-level folders"
ls -d */ 2>/dev/null | grep -vE '^(node_modules|dist|build|coverage)/$' | tr '\n' ' '; echo

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
    echo "- CI $w:"; grep -nE '^\s*-?\s*run:|^\s*-?\s*uses:.*(deploy|hosting|pages|vercel|netlify|upload-google-play|testflight)|^\s*branches:|channelId:' "$w" | head -14 | cut -c1-150 | sed 's/^/    /'
  done
fi

sec "Tests"
for d in test tests __tests__ integration_test e2e spec; do [ -d "$APP/$d" ] && echo "- $APP/$d/ ($(find "$APP/$d" -type f | wc -l | tr -d ' ') files)"; done
for d in test/helpers test/fakes test/mocks tests/fixtures tests/helpers; do [ -d "$APP/$d" ] && echo "- helpers: $APP/$d/"; done
[ "$TST" -eq 0 ] && echo "- no test files found"

# Evidence for the testing module: which test levels the repo already has. Counts are files.
sec "Test levels"
tg() { grep -rIlE "$1" "$APP" --include='*.dart' --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' --include='*.py' --include='*.go' --exclude-dir=node_modules --exclude-dir=build --exclude-dir=dist --exclude-dir=.dart_tool --exclude-dir=.next --exclude-dir=.venv --exclude-dir=venv --exclude-dir=Pods 2>/dev/null | wc -l | tr -d ' '; }
cnt() { wc -l | tr -d ' '; }
ALLT=$(cd "$APP" && ff \( -name '*_test.*' -o -name '*.test.*' -o -name '*.spec.*' -o -name 'test_*.py' \) | grep -E "$TEXT")
E2EP='(^|/)(e2e[^/]*|end-to-end|end_to_end|playwright|cypress)/|[._]e2e[._]'
E2EF=$(printf '%s\n' "$ALLT" | grep -cE "$E2EP")
INTEG=$(printf '%s\n' "$ALLT" | grep -vE "$E2EP" | grep -cE '(^|/)(integration_test|integration|integration_tests|it)/|[._]integration[._]|_integration_test\.')
TOTAL=$(printf '%s\n' "$ALLT" | grep -c .)
echo "- unit and component: $((TOTAL - INTEG - E2EF)) test files"
echo "- integration: $INTEG test files"
GOLD=$(tg 'matchesGoldenFile|toMatchSnapshot|toMatchInlineSnapshot|toMatchImageSnapshot|toHaveScreenshot|assert_match_snapshot')
GDIR=$(cd "$APP" && find . \( $PRUNE \) -prune -o -type d \( -name goldens -o -name __snapshots__ -o -name '__image_snapshots__' \) -print 2>/dev/null | cnt)
echo "- golden or snapshot: $GOLD files with assertions, $GDIR reference folders"
e2e=""
for f in playwright.config.ts playwright.config.js cypress.config.ts cypress.config.js .detoxrc.js .detoxrc.json wdio.conf.js; do [ -e "$APP/$f" ] && e2e="$e2e $f"; done
for d in .maestro maestro "$APP/.maestro" "$APP/maestro"; do [ -d "$d" ] && { e2e="$e2e $d/"; break; }; done
[ -f "$APP/pubspec.yaml" ] && grep -qE '^\s+patrol:' "$APP/pubspec.yaml" && e2e="$e2e patrol"
[ -d "$APP/integration_test" ] && e2e="$e2e integration_test/(Flutter, runs on a device — files there are counted under integration above)"
echo "- end-to-end: $E2EF test files; tools:${e2e:- none}"
LOADF=$( { cd "$APP" && ff \( -name 'locustfile*.py' -o -name '*.jmx' -o -name '*.k6.js' -o -name 'artillery*.y*ml' \); } | cnt)
LOADK=$(tg "from ['\"]k6(/|['\"])|from locust import|import locust")
ldir=""; for d in load loadtest load-test load_tests k6 perf performance stress; do [ -d "$APP/$d" ] && ldir="$ldir $d/"; done
lcli=""; for c in k6 locust artillery jmeter; do command -v "$c" >/dev/null 2>&1 && lcli="$lcli $c"; done
echo "- load or stress: $((LOADF + LOADK)) script files; folders:${ldir:- none}; CLIs on this machine (not repo evidence):${lcli:- none}"
cov=""
for f in .nycrc .nycrc.json .coveragerc codecov.yml .codecov.yml coverage/lcov.info lcov.info; do [ -e "$APP/$f" ] && cov="$cov $f"; done
for f in "$APP/package.json" "$APP"/jest.config.* "$APP"/vitest.config.* "$APP/pyproject.toml" "$APP/pubspec.yaml"; do
  [ -f "$f" ] && grep -qE 'coverageThreshold|"coverage"|--coverage|pytest-cov|fail_under|@vitest/coverage|thresholds' "$f" && cov="$cov $(basename "$f")(coverage settings)"
done
ls .github/workflows/*.y*ml >/dev/null 2>&1 && grep -lE -- '--coverage|lcov|codecov|coverage report' .github/workflows/*.y*ml >/dev/null 2>&1 && cov="$cov CI"
echo "- coverage signals:${cov:- none}"

# Evidence for the database module. Names, counts, and paths only — never a connection string value.
sec "Database"
DBN=0
dbl() { echo "- $*"; DBN=$((DBN+1)); }
mig() { # label dir pattern
  [ -d "$2" ] || return 0
  n=$(find "$2" -type f -name "$3" 2>/dev/null | wc -l | tr -d ' ')
  [ "$n" -gt 0 ] && dbl "$1: $2/ ($n files, latest: $(find "$2" -type f -name "$3" 2>/dev/null | sort | tail -1 | sed 's|.*/||' | cut -c1-70))"
}
for r in . "$APP"; do
  mig "supabase migrations" "$r/supabase/migrations" '*.sql'
  [ -f "$r/supabase/config.toml" ] && dbl "supabase config: $r/supabase/config.toml"
  for f in firestore.rules firestore.indexes.json database.rules.json storage.rules; do [ -f "$r/$f" ] && dbl "firebase file: $r/$f"; done
  if [ -f "$r/prisma/schema.prisma" ]; then dbl "prisma schema: $r/prisma/schema.prisma ($(grep -m1 -E '^\s*provider\s*=' "$r/prisma/schema.prisma" | grep -v prisma-client | tr -d ' ' | cut -c1-40))"; fi
  mig "prisma migrations" "$r/prisma/migrations" 'migration.sql'
  for f in drizzle.config.ts drizzle.config.js knexfile.js knexfile.ts ormconfig.json alembic.ini flyway.conf liquibase.properties; do [ -f "$r/$f" ] && dbl "migration tool config: $r/$f"; done
  for d in drizzle migrations db/migrate db/migration db/migrations database/migrations alembic/versions src/migrations Migrations sql; do
    mig "migrations folder" "$r/$d" '*.sql'; mig "migrations folder" "$r/$d" '*.py'; mig "migrations folder" "$r/$d" '*.cs'; mig "migrations folder" "$r/$d" '*.ts'; mig "migrations folder" "$r/$d" '*.rb'; mig "migrations folder" "$r/$d" '*.php'
  done
  [ "$APP" = . ] && break
done
DJ=$(cd "$APP" && ff -path '*/migrations/0*.py' | wc -l | tr -d ' '); [ "$DJ" -gt 0 ] && dbl "django-style migrations: $DJ files"
EF=$(cd "$APP" && ff -name '*.csproj' | xargs grep -lE 'EntityFrameworkCore|Microsoft\.Data\.SqlClient|System\.Data\.SqlClient|Npgsql|Dapper' 2>/dev/null | head -3 | tr '\n' ' '); [ -n "$EF" ] && dbl ".NET data access in: $EF"
CS=$(cd "$APP" && ff \( -name 'appsettings*.json' -o -name 'web.config' -o -name 'Web.config' \) | xargs grep -liE 'ConnectionStrings|<connectionStrings' 2>/dev/null | head -4 | tr '\n' ' '); [ -n "$CS" ] && dbl "connection strings declared in (values not read): $CS"
drv=""
for m in "$APP/pubspec.yaml" "$APP/package.json" "$APP/pyproject.toml" "$APP/requirements.txt" "$APP/go.mod" "$APP/Cargo.toml" "$APP/composer.json" "$APP/Gemfile"; do
  [ -f "$m" ] && drv="$drv $(grep -oE '(^|[^A-Za-z0-9_-])(supabase_flutter|firebase_core|@supabase/supabase-js|supabase|cloud_firestore|firebase_database|firebase-admin|firebase|sqflite|drift|isar|hive|objectbox|realm|"pg"|postgres|psycopg[0-9]?|asyncpg|pgx|"mssql"|tedious|pyodbc|pymssql|go-mssqldb|mysql2?|pymysql|mongoose|mongodb|pymongo|redis|sqlalchemy|typeorm|sequelize|drizzle-orm|@prisma/client|knex|gorm|sqlx|diesel|better-sqlite3|sqlite3)([^A-Za-z0-9_-]|$)' "$m" | sed -E 's/^[^A-Za-z@]+//; s/[^A-Za-z0-9]+$//' | sort -u | tr '\n' ' ')"
done
drv=$(echo $drv | tr ' ' '\n' | sort -u | tr '\n' ' ')
[ -n "${drv// /}" ] && dbl "data libraries in manifests: $drv"
FSU=$(tg "firebase/firestore|cloud_firestore|firebase-admin/firestore|firebase/database|firebase_database|getFirestore|FirebaseFirestore")
[ "$FSU" -gt 0 ] && dbl "Firestore or Realtime Database used in code: $FSU files"
for f in firebase.json .firebaserc; do [ -f "$f" ] && echo "- $f present (hosting or project config; not by itself a database)"; done
for e in .env.example .env.sample .env.template "$APP/.env.example" "$APP/.env.sample"; do
  [ "$APP" = . ] && case "$e" in ./*) continue ;; esac
  [ -f "$e" ] && { v=$(grep -oE '^[A-Z0-9_]*(DATABASE|DB_|SUPABASE|POSTGRES|PG|MSSQL|SQLSERVER|MYSQL|MONGO|FIREBASE|REDIS)[A-Z0-9_]*' "$e" | sort -u | head -10 | tr '\n' ' '); [ -n "$v" ] && dbl "env variable names in $e: $v"; }
done
if [ -f .mcp.json ] && command -v python3 >/dev/null 2>&1; then
  ms=$(python3 -c 'import json,re;print(", ".join(k for k in json.load(open(".mcp.json")).get("mcpServers",{}) if re.search("supabase|postgres|firebase|firestore|sql|mongo|db|database",k,re.I)))' 2>/dev/null)
  [ -n "$ms" ] && dbl "database servers in .mcp.json: $ms"
fi
dcli=""; for c in supabase firebase psql sqlcmd mysql mongosh az; do command -v "$c" >/dev/null 2>&1 && dcli="$dcli $c"; done
echo "- database CLIs on this machine (not repo evidence):${dcli:- none}"
[ -f .claude/hooks/protected-paths.txt ] && echo "- protected paths already listed: $(grep -cvE '^\s*(#|$)' .claude/hooks/protected-paths.txt)"
[ "$DBN" -eq 0 ] && echo "- no database evidence found"

sec "Env and secret files (names only)"
for d in . "$APP"; do
  ls -a "$d" 2>/dev/null | grep -E '^\.env|key\.properties|service-account|adminsdk|\.jks$|\.keystore$' | sed "s|^|- $d/|"
  [ "$APP" = . ] && break
done
trk=$(git ls-files 2>/dev/null | grep -E '(^|/)(\.env(\.json)?|key\.properties|[^/]*service-account[^/]*\.json|[^/]*\.jks|[^/]*\.keystore)$' | head -5 | tr '\n' ' ')
[ -n "$trk" ] && echo "- TRACKED IN GIT (values not read; ask the user whether this is intended): $trk"
[ -f .gitignore ] && { grep -qE '^\s*\.env' .gitignore && echo "- .env ignored by git: yes" || echo "- .env ignored by git: NO (check with the user before assuming this is a mistake)"; }

sec "Invariant markers in code (count)"
N=$(grep -rIiE '(^|[^A-Za-z])(NEVER|JANGAN|WAJIB|DO NOT|MUST NOT|HACK|WORKAROUND)([^A-Za-z]|$)' --exclude-dir=dist --include='*.dart' --include='*.ts' --include='*.tsx' --include='*.py' --include='*.go' --exclude-dir=node_modules --exclude-dir=build --exclude-dir=.dart_tool . 2>/dev/null | wc -l | tr -d ' ')
echo "- $N lines; list them with: grep -rnIiwE '(NEVER|JANGAN|WAJIB|DO NOT|MUST NOT|HACK|WORKAROUND)' <src dir> | head -40"

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
if [ -d "$APP/android" ] || [ -d "$APP/ios" ]; then command -v fastlane >/dev/null 2>&1 && echo "- fastlane CLI: installed" || echo "- fastlane CLI: not installed"; fi
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
  oth=$(ls -A .claude | grep -vE '^(agents|skills|commands|workflows|hooks|\.agent|kit\.json|\.DS_Store|\._.*)$' | tr '\n' ' '); [ -n "$oth" ] && echo "- other entries in .claude/: $oth"
  if [ -f .claude/kit.json ]; then echo "- kit record: $(tr -d '\n' < .claude/kit.json | cut -c1-300)"
  elif [ -d .claude/agents ] || [ -d .claude/skills ] || [ -d .claude/commands ]; then echo "- kit record: none (set up by hand or by an older kit — use the adoption rules in update mode)"
  else echo "- no agents, skills, or commands: treat as a fresh setup and keep the files already in .claude/"; fi
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
  an=$(git log -200 --format='%an' 2>/dev/null | tr 'A-Z' 'a-z' | sort -u)
  echo "- human commit authors by name (last 200): $(printf '%s\n' "$an" | grep -vciE '^$|claude|\[bot\]|dependabot|github-actions|copilot|renovate'); automated authors: $(printf '%s\n' "$an" | grep -ciE 'claude|\[bot\]|dependabot|github-actions|copilot|renovate')"
  ls200=$(git log -200 --format='%s' 2>/dev/null)
  echo "- 'Merge pull request #N' commits (last 200): $(printf '%s\n' "$ls200" | grep -cE '^Merge pull request #')"
  echo "- subjects ending in '(#N)' (last 200; a squash-merged PR or a ticket number — check against the Tickets section): $(printf '%s\n' "$ls200" | grep -cE '\(#[0-9]+\)$')"
  echo "- local branch merges, 'Merge branch ...' (last 200): $(printf '%s\n' "$ls200" | grep -cE "^Merge (remote-tracking )?branch ")"
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
  ex=$(printf '%s\n' "$subj" | grep -iE 'trello ?#[0-9]+|[A-Z][A-Z0-9]+-[0-9]+|#[0-9]+' | head -2 | cut -c1-160 | sed 's/^/    /')
  [ -n "$ex" ] && { echo "- examples:"; echo "$ex"; }
else echo "- not a git repository"; fi
exit 0
