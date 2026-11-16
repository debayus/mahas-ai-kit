#!/usr/bin/env bash
# Checks a generated setup. Run from the repository root. Exit 1 if anything fails.
set -u
fail=0
bad() { echo "FAIL: $*"; fail=1; }
ok() { echo "ok:   $*"; }
limit() { # file max
  [ -f "$1" ] || return 0
  n=$(wc -l < "$1" | tr -d ' ')
  [ "$n" -le "$2" ] && ok "$1 ($n lines)" || bad "$1 has $n lines (limit $2)"
}

[ -f CLAUDE.md ] && limit CLAUDE.md 40 || bad "CLAUDE.md missing"
[ -d .claude ] || { bad ".claude/ missing"; exit 1; }

# 1. no leftover placeholders
left=$(grep -rnE '\{\{[A-Z_]+\}\}' CLAUDE.md .claude --include='*.md' --include='*.js' --include='*.json' --include='*.sh' 2>/dev/null)
[ -z "$left" ] && ok "no leftover placeholders" || { bad "leftover placeholders:"; echo "$left" | head -20; }

# 2. frontmatter + size limits
for f in .claude/agents/*.md; do [ -e "$f" ] || continue
  head -1 "$f" | grep -q '^---$' && grep -q '^name:' "$f" && grep -q '^description:' "$f" || bad "$f: frontmatter needs name + description"
  limit "$f" 45
done
for f in .claude/skills/*/SKILL.md; do [ -e "$f" ] || continue
  head -1 "$f" | grep -q '^---$' && grep -q '^name:' "$f" && grep -q '^description:' "$f" || bad "$f: frontmatter needs name + description"
  d=$(basename "$(dirname "$f")"); grep -q "^name: $d\$" "$f" || bad "$f: name must equal folder name '$d'"
  case "$d" in stack-*) limit "$f" 50 ;; *) limit "$f" 60 ;; esac
done
for f in .claude/commands/*.md; do [ -e "$f" ] || continue; limit "$f" 30; done
n=$(ls -d .claude/skills/stack-* 2>/dev/null | wc -l | tr -d ' ')
[ "$n" -le 4 ] && ok "$n stack skills" || bad "$n stack skills (max 4)"

# 3. JSON validity
for f in .claude/settings.json .mcp.json; do [ -f "$f" ] || continue
  if command -v python3 >/dev/null 2>&1; then python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f" 2>/dev/null && ok "$f valid JSON" || bad "$f is not valid JSON"
  elif command -v jq >/dev/null 2>&1; then jq empty "$f" 2>/dev/null && ok "$f valid JSON" || bad "$f is not valid JSON"; fi
done

# 4. workflow syntax
for f in .claude/workflows/*.js; do [ -e "$f" ] || continue
  grep -q "agentType: 'planner'" "$f" && ok "$f present" || bad "$f looks incomplete"
done

# 5. hooks executable and wired
for f in .claude/hooks/*.sh; do [ -e "$f" ] || continue
  [ -x "$f" ] && bash -n "$f" 2>/dev/null && ok "$f executable, syntax ok" || bad "$f not executable or has a syntax error"
done
if ls .claude/hooks/*.sh >/dev/null 2>&1; then
  grep -q 'format-on-edit.sh' .claude/settings.json 2>/dev/null && ok "format hook wired in settings.json" || bad "hooks exist but are not wired in .claude/settings.json"
fi

# 6. relative Markdown links resolve
broken=0
while IFS= read -r f; do
  base=$(dirname "$f")
  for link in $(grep -oE '\]\([^)#: ]+(#[^)]*)?\)' "$f" | sed -E 's/^\]\(//; s/\)$//; s/#.*$//' | sort -u); do
    case "$link" in http*|mailto*|'') continue ;; esac
    [ -e "$base/$link" ] || { bad "$f → broken link: $link"; broken=1; }
  done
done < <(find CLAUDE.md .claude -name '*.md' -not -path '*/worktrees/*' 2>/dev/null)
[ "$broken" -eq 0 ] && ok "all relative links resolve"

# 7. agents only reference skills that exist
for s in $(grep -rhoE '`(stack|process)-[a-z0-9-]+`' .claude/agents .claude/commands 2>/dev/null | tr -d '`' | sort -u); do
  [ -d ".claude/skills/$s" ] || bad "skill '$s' is referenced but does not exist"
done

# 8. no secret-looking values
sec=$(grep -rnIE '(sk_live_|sk-[A-Za-z0-9]{20,}|AIza[0-9A-Za-z_-]{30,}|eyJ[A-Za-z0-9_-]{20,}\.eyJ|-----BEGIN [A-Z ]*PRIVATE KEY)' CLAUDE.md .claude 2>/dev/null)
[ -z "$sec" ] && ok "no secret-looking values" || { bad "possible secrets in generated files:"; echo "$sec" | cut -c1-120; }

[ "$fail" -eq 0 ] && echo "RESULT: PASS" || echo "RESULT: FAIL"
exit "$fail"
