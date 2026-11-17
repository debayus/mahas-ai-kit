#!/usr/bin/env bash
# PreToolUse hook: block edits to paths listed in protected-paths.txt (one glob per line,
# relative to the project root; lines starting with # are comments). Exit 2 = blocked.
dir="$(cd "$(dirname "$0")" && pwd)"
list="$dir/protected-paths.txt"
[ -f "$list" ] || exit 0
f="$(bash "$dir/_file-path.sh")"
[ -n "$f" ] || exit 0
# The file may sit in another git worktree of this project, so take the root from the
# file's own checkout first. A new file has no folder yet: walk up to one that exists.
d="$(dirname "$f")"
while [ ! -d "$d" ] && [ "$d" != / ] && [ "$d" != . ]; do d="$(dirname "$d")"; done
root="$(cd "$d" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)"
[ -n "$root" ] || root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
# Compare physical paths, so /tmp and /private/tmp (or any symlink) spell the same file.
[ -d "$d" ] && f="$(cd "$d" && pwd -P)${f#"$d"}"
[ -d "$root" ] && root="$(cd "$root" && pwd -P)"
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
