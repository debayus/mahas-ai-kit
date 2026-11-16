#!/usr/bin/env bash
# Shared helper: prints the file path of the tool call read from stdin (hook JSON).
input="$(cat)"
if command -v jq >/dev/null 2>&1; then
  printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null
elif command -v python3 >/dev/null 2>&1; then
  printf '%s' "$input" | python3 -c 'import json,sys
try:
    t=json.load(sys.stdin).get("tool_input",{})
    print(t.get("file_path") or t.get("notebook_path") or "")
except Exception:
    pass'
fi
