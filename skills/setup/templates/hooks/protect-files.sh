#!/usr/bin/env bash
# PreToolUse hook: block edits to paths listed in protected-paths.txt (one glob per line,
# relative to the project root; lines starting with # are comments). Exit 2 = blocked.
dir="$(cd "$(dirname "$0")" && pwd)"
list="$dir/protected-paths.txt"
[ -f "$list" ] || exit 0
f="$(bash "$dir/_file-path.sh")"
[ -n "$f" ] || exit 0
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
rel="${f#"$root"/}"
while IFS= read -r pat || [ -n "$pat" ]; do
  pat="${pat%$'\r'}"
  case "$pat" in ''|'#'*) continue ;; esac
  # shellcheck disable=SC2254
  case "$rel" in
    $pat)
      echo "Blocked: '$rel' is a protected file (pattern: $pat). See .claude/hooks/protected-paths.txt. Do not edit it directly; explain the needed change to the user instead." >&2
      exit 2 ;;
  esac
done < "$list"
exit 0
