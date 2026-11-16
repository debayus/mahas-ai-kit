#!/usr/bin/env bash
# PostToolUse hook: format the file Claude just edited. Never blocks (always exits 0).
# Setup removes the branches for languages this repo does not use.
dir="$(cd "$(dirname "$0")" && pwd)"
f="$(bash "$dir/_file-path.sh")"
[ -n "$f" ] && [ -f "$f" ] || exit 0
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
case "$f" in "$root"/*) ;; *) exit 0 ;; esac   # only files inside the project
has() { command -v "$1" >/dev/null 2>&1; }
case "$f" in
  *.g.dart|*.freezed.dart|*.gr.dart) ;;                       # generated: leave alone
  *.dart) has dart && dart format "$f" >/dev/null 2>&1 ;;
  *.ts|*.tsx|*.js|*.jsx|*.css|*.scss|*.vue)
    [ -x "$root/node_modules/.bin/prettier" ] && "$root/node_modules/.bin/prettier" --write "$f" >/dev/null 2>&1 ;;
  *.py) if has ruff; then ruff format "$f" >/dev/null 2>&1; elif has black; then black -q "$f" >/dev/null 2>&1; fi ;;
  *.go) has gofmt && gofmt -w "$f" >/dev/null 2>&1 ;;
  *.rs) has rustfmt && rustfmt "$f" >/dev/null 2>&1 ;;
esac
exit 0
