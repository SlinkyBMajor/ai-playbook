#!/usr/bin/env bash
#
# PostToolUse hook (matched on Write|Edit|MultiEdit): mark the project as
# having pending distillation candidates. The UserPromptSubmit hook reads
# this sentinel and injects a soft reminder for the agent to surface
# /playbook:distil when the work appears to be wrapping up.
#
# Exits 0 silently on any failure — never disrupt the agent's flow.

set -uo pipefail

input=$(cat 2>/dev/null || true)
cwd=""
if [[ -n "$input" ]]; then
  cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)
fi
cwd="${cwd:-$PWD}"

state_dir="$cwd/.claude/.playbook"
mkdir -p "$state_dir" 2>/dev/null || exit 0

if [[ ! -f "$state_dir/.gitignore" ]]; then
  printf '*\n' > "$state_dir/.gitignore" 2>/dev/null || true
fi

touch "$state_dir/distillation-pending" 2>/dev/null || true
exit 0
