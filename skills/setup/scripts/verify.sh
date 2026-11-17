#!/usr/bin/env bash
# Checks a generated setup. Run from the repository root. Exit 1 if anything fails.
set -u
fail=0
bad() { echo "FAIL: $*"; fail=1; }
ok() { echo "ok:   $*"; }
# --existing: checking a setup the kit did not generate (update mode). Size overruns
# become warnings to act on with the user instead of failures.
EXISTING=0; [ "${1:-}" = "--existing" ] && EXISTING=1
warns=0
warn() { echo "WARN: $*"; warns=$((warns+1)); }
# soft: a failure in a fresh setup, a warning in a setup the kit did not generate
soft() { if [ "$EXISTING" -eq 1 ]; then warn "$*"; else bad "$*"; fi; }
limit() { # file max
  [ -f "$1" ] || return 0
  n=$(wc -l < "$1" | tr -d ' ')
  if [ "$n" -le "$2" ]; then ok "$1 ($n lines)"
  elif [ "$EXISTING" -eq 1 ]; then warn "$1 has $n lines (kit limit $2) — propose moving sections into .claude/.agent/"
  else bad "$1 has $n lines (limit $2)"; fi
}

if [ -f CLAUDE.md ]; then limit CLAUDE.md 40; else bad "CLAUDE.md missing"; fi
[ -d .claude ] || { bad ".claude/ missing"; exit 1; }
# Only the folders a setup consists of. Other things under .claude/ (worktrees, run logs,
# memory) belong to the tools that wrote them.
SCOPE="CLAUDE.md .claude/README.md .claude/kit.json .claude/settings.json .claude/agents .claude/commands .claude/skills .claude/.agent .claude/hooks .claude/workflows"

# 0. hot rules: at most 6, each with a link to the file that proves it
if [ -f CLAUDE.md ]; then
  hot=$(awk '/^## /{on=0} tolower($0) ~ /^## hot rules/{on=1; next} on && /^([0-9]+\.|[-*]) /' CLAUDE.md)
  nh=$(printf '%s\n' "$hot" | grep -c .)
  if [ "$nh" -le 6 ]; then ok "$nh hot rules"; else soft "$nh hot rules in CLAUDE.md (max 6) — move the rest into a stack skill or .claude/.agent/"; fi
  nl=$(printf '%s\n' "$hot" | grep . | grep -vc '](')
  [ "$nl" -eq 0 ] || soft "$nl hot rule(s) in CLAUDE.md without a link to the file that proves them"
fi

# 1. no leftover placeholders
left=$(grep -rnE '\{\{[A-Z][A-Z0-9_]*\}\}' $SCOPE --exclude='._*' --include='*.md' --include='*.js' --include='*.json' --include='*.sh' 2>/dev/null)
[ -z "$left" ] && ok "no leftover placeholders" || { bad "leftover placeholders:"; echo "$left" | head -20; }

# 2. frontmatter + size limits
for f in .claude/agents/*.md; do [ -e "$f" ] || continue
  head -1 "$f" | grep -q '^---$' && grep -q '^name:' "$f" && grep -q '^description:' "$f" || bad "$f: frontmatter needs name + description"
  case "$(basename "$f" .md)" in
    planner|architect|developer|tester|reviewer) limit "$f" 45 ;;
    *) limit "$f" 80 ;;   # operations agents (deployers, crash-fixer, ...)
  esac
done
for f in .claude/skills/*/SKILL.md; do [ -e "$f" ] || continue
  head -1 "$f" | grep -q '^---$' && grep -q '^name:' "$f" && grep -q '^description:' "$f" || bad "$f: frontmatter needs name + description"
  d=$(basename "$(dirname "$f")"); grep -q "^name: $d\$" "$f" || bad "$f: name must equal folder name '$d'"
  case "$d" in stack-*) limit "$f" 50 ;; *) limit "$f" 60 ;; esac
  case "$d" in stack-*) nr=$(grep -cE '^[0-9]+\. \*\*' "$f"); [ "$nr" -le 8 ] || soft "$f has $nr hard rules (max 8)" ;; esac
done
for f in .claude/commands/*.md; do [ -e "$f" ] || continue; limit "$f" 30; done
n=$(ls -d .claude/skills/stack-* 2>/dev/null | wc -l | tr -d ' ')
if [ "$n" -le 4 ]; then ok "$n stack skills"; else soft "$n stack skills (max 4)"; fi

# 2b. kit record, option markers, skill cap
if [ -f .claude/kit.json ] && grep -qE '"kit": *"[0-9]+\.[0-9]+\.[0-9]+"' .claude/kit.json; then ok "kit record present"
elif [ "$EXISTING" -eq 1 ]; then warn "no .claude/kit.json — adopt this setup (SKILL.md Step 6)"
else bad ".claude/kit.json missing or has no \"kit\" version"; fi
mark=$(grep -rnE '<!-- /?option' $SCOPE --exclude='._*' --include='*.md' 2>/dev/null)
[ -z "$mark" ] && ok "no leftover option markers" || { bad "leftover option markers:"; echo "$mark" | head -10; }
ns=$(ls -d .claude/skills/*/ 2>/dev/null | wc -l | tr -d ' ')
if [ "$ns" -le 10 ]; then ok "$ns skills in total"
elif [ "$EXISTING" -eq 1 ]; then warn "$ns skills in total (kit cap 10)"
else bad "$ns skills in total (max 10)"; fi

# 3. JSON validity
for f in .claude/settings.json .claude/kit.json .mcp.json; do [ -f "$f" ] || continue
  if command -v python3 >/dev/null 2>&1; then python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f" 2>/dev/null && ok "$f valid JSON" || bad "$f is not valid JSON"
  elif command -v jq >/dev/null 2>&1; then jq empty "$f" 2>/dev/null && ok "$f valid JSON" || bad "$f is not valid JSON"; fi
done

# 4. workflow syntax
for f in .claude/workflows/*.js; do [ -e "$f" ] || continue
  if grep -q "agentType: 'planner'" "$f"; then ok "$f present"
  elif [ "$EXISTING" -eq 1 ]; then ok "$f present (not a kit pipeline)"
  else bad "$f looks incomplete"; fi
  if command -v node >/dev/null 2>&1; then node -e 'const s=require("fs").readFileSync(process.argv[1],"utf8").replace(/^export /gm,""); new (Object.getPrototypeOf(async function(){}).constructor)(s)' "$f" 2>/dev/null || bad "$f has a JavaScript syntax error (an unescaped quote in a command?)"; fi
done

# 5. hooks executable and wired
for f in .claude/hooks/*.sh; do [ -e "$f" ] || continue
  [ -x "$f" ] && bash -n "$f" 2>/dev/null && ok "$f executable, syntax ok" || bad "$f not executable or has a syntax error"
done
for f in .claude/hooks/*.sh; do [ -e "$f" ] || continue
  h=$(basename "$f"); case "$h" in _*) continue ;; esac   # _*.sh are helpers sourced by the hooks
  grep -q "$h" .claude/settings.json 2>/dev/null && ok "$h wired in settings.json" || bad "$h exists but is not wired in .claude/settings.json"
done

if ls .claude/hooks/*.sh >/dev/null 2>&1 && [ ! -f .claude/hooks/_file-path.sh ]; then bad ".claude/hooks/_file-path.sh is missing: without it the hooks do nothing"; fi

# 6. relative Markdown links resolve
broken=0
while IFS= read -r f; do
  base=$(dirname "$f")
  for link in $(grep -oE '\]\([^)#: ]+(#[^)]*)?\)' "$f" | sed -E 's/^\]\(//; s/\)$//; s/#.*$//' | sort -u); do
    case "$link" in http*|mailto*|'') continue ;; esac
    # agents and commands are prompts read from the repo root, so a root-relative link is valid too
    [ -e "$base/$link" ] || [ -e "$link" ] || { bad "$f → broken link: $link"; broken=1; }
  done
done < <(find $SCOPE -name '*.md' ! -name '._*' 2>/dev/null)
[ "$broken" -eq 0 ] && ok "all relative links resolve"

# 7. agents only reference skills that exist
for s in $(grep -rhoE '`(stack|process)-[a-z0-9-]+`' .claude/agents .claude/commands .claude/skills 2>/dev/null | tr -d '`' | sort -u); do
  [ -d ".claude/skills/$s" ] || bad "skill '$s' is referenced but does not exist"
done

# 7b. commands and agents that are named must exist
builtin=' add-dir agents bug clear compact config context cost doctor exit export fast help hooks ide init login logout loop mcp memory model permissions plugin pr-comments release-notes resume review rewind schedule status statusline terminal-setup todos usage vim dev etc tmp usr var bin opt home '
# Only a name that opens a code span counts (`/plan`, `/plan <request>`); a root folder of that name is a path.
for c in $(grep -rhoE '(^|[ (])`/[a-z][a-z0-9-]*[ `]' CLAUDE.md .claude/agents .claude/commands .claude/skills .claude/README.md 2>/dev/null | tr -d '`/ (' | sort -u); do
  case "$builtin" in *" $c "*) continue ;; esac
  [ -e "$c" ] && continue
  [ -f ".claude/commands/$c.md" ] || [ -d ".claude/skills/$c" ] || soft "command '/$c' is named but .claude/commands/$c.md does not exist"
done
for a in $(grep -rhoE '`[a-z][a-z0-9-]+` agent' .claude/agents .claude/commands .claude/skills 2>/dev/null | sed -E 's/`([^`]+)`.*/\1/' | sort -u); do
  [ -f ".claude/agents/$a.md" ] || [ -d ".claude/$a" ] || soft "agent '$a' is named but .claude/agents/$a.md does not exist"
done

# 7c. MCP tools that are named: is their server in .mcp.json? A server may also be connected
# at user level, which this script cannot see, so this is a warning in every mode.
for m in $(grep -rhoE 'mcp__[A-Za-z0-9-]+(_[A-Za-z0-9-]+)*__' .claude/agents .claude/commands .claude/skills 2>/dev/null | sed -E 's/^mcp__//; s/__$//' | sort -u); do
  if [ -f .mcp.json ] && grep -qE "\"$m\" *:" .mcp.json; then ok "MCP server '$m' is in .mcp.json"
  else warn "tools of MCP server '$m' are named, but '$m' is not in .mcp.json — fine only if it is connected at user level"; fi
done

# 8. no secret-looking values
sec=$(grep -rnIE '(sk_live_|sk-[A-Za-z0-9]{20,}|AIza[0-9A-Za-z_-]{30,}|eyJ[A-Za-z0-9_-]{20,}\.eyJ|-----BEGIN [A-Z ]*PRIVATE KEY)' $SCOPE --exclude='._*' 2>/dev/null)
[ -z "$sec" ] && ok "no secret-looking values" || { bad "possible secrets in generated files:"; echo "$sec" | cut -c1-120; }

[ "$warns" -gt 0 ] && echo "$warns warning(s)"
[ "$fail" -eq 0 ] && echo "RESULT: PASS" || echo "RESULT: FAIL"
exit "$fail"
