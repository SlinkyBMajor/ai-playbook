#!/usr/bin/env bash
#
# UserPromptSubmit hook: if a distillation-pending sentinel exists for this
# project, inject a reminder for the agent to surface /ai-playbook:distil when
# the developer's current turn appears to be wrapping up.
#
# Exits 0 silently with no output if the sentinel is absent or the reminder
# file is missing.
#
# Usage: check-distillation-sentinel.sh <reminder-text-file>

set -uo pipefail

reminder_file="${1:-}"
[[ -f "$reminder_file" ]] || exit 0

input=$(cat 2>/dev/null || true)
cwd=""
if [[ -n "$input" ]]; then
  cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)
fi
cwd="${cwd:-$PWD}"

sentinel="$cwd/.claude/.ai-playbook/distillation-pending"
[[ -f "$sentinel" ]] || exit 0

contents=$(cat "$reminder_file")

jq -n \
  --arg event "UserPromptSubmit" \
  --arg ctx "$contents" \
  '{hookSpecificOutput: {hookEventName: $event, additionalContext: $ctx}}'
