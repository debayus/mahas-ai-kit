#!/usr/bin/env bash
# PreToolUse hook: block edits to paths listed in protected-paths.txt (one glob per line,
# relative to the project root; lines starting with # are comments). Exit 2 = blocked.
# A pattern that starts with **/ also matches at the root. Matching ignores letter case.
dir="$(cd "$(dirname "$0")" && pwd)"
list="$dir/protected-paths.txt"
[ -f "$list" ] || exit 0
f="$(bash "$dir/_file-path.sh")"
[ -n "$f" ] || exit 0
proj="${CLAUDE_PROJECT_DIR:-$(pwd)}"
case "$f" in /*) ;; *) f="$proj/$f" ;; esac

clean() { # absolute path -> the same path without "//", "/./", and "/../"
  local IFS=/ part r=
  local -a out=()
  set -f
  for part in $1; do
    case "$part" in
      ''|.) ;;
      ..) [ "${#out[@]}" -gt 0 ] && unset "out[$((${#out[@]}-1))]" ;;
      *) out[${#out[@]}]="$part" ;;
    esac
  done
  set +f
  for part in ${out[@]+"${out[@]}"}; do r="$r/$part"; done
  printf '%s' "${r:-/}"
}
phys() { # clean absolute path -> physical path. A new file has no folder yet: resolve the
  # deepest folder that exists, so /tmp and /private/tmp (or any symlink) spell the same file.
  local d="$1" tail=
  while [ ! -d "$d" ] && [ "$d" != / ]; do tail="/$(basename "$d")$tail"; d="$(dirname "$d")"; done
  d="$(cd "$d" 2>/dev/null && pwd -P)"
  [ "$d" = / ] && d=
  printf '%s' "$d$tail"
}

f="$(clean "$f")"
paths="$(phys "$f")"
if [ -L "$f" ]; then   # a link to a protected file is the protected file
  t="$(readlink "$f")"
  case "$t" in /*) ;; *) t="$(dirname "$f")/$t" ;; esac
  paths="$paths
$(phys "$(clean "$t")")"
fi

# Two roots: the file's own git checkout (it may sit in another worktree of this project)
# and the project folder (it may be a subfolder of a larger repository, or hold a nested one).
d="$(dirname "$f")"
while [ ! -d "$d" ] && [ "$d" != / ]; do d="$(dirname "$d")"; done
groot="$(cd "$d" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)"
[ -n "$groot" ] && [ -d "$groot" ] && groot="$(cd "$groot" && pwd -P)"
[ -d "$proj" ] && proj="$(cd "$proj" && pwd -P)"

shopt -s nocasematch
check() { # path relative to a root
  local rel="$1" pat
  while IFS= read -r pat || [ -n "$pat" ]; do
    pat="${pat%$'\r'}"
    pat="${pat#"${pat%%[![:space:]]*}"}"; pat="${pat%"${pat##*[![:space:]]}"}"
    case "$pat" in ''|'#'*) continue ;; esac
    # shellcheck disable=SC2254
    case "$rel" in
      $pat|${pat#\*\*/})
        echo "Blocked: '$rel' is a protected file (pattern: $pat). See .claude/hooks/protected-paths.txt. Do not edit it directly; explain the needed change to the user instead." >&2
        exit 2 ;;
    esac
  done < "$list"
}
while IFS= read -r p; do
  for root in "$groot" "$proj"; do
    [ -n "$root" ] || continue
    case "$p" in "$root"/*) check "${p#"$root"/}" ;; esac
  done
done <<EOF
$paths
EOF
exit 0
