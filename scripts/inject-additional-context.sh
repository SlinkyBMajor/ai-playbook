#!/usr/bin/env bash
#
# Generic helper: read a markdown file and emit the JSON envelope Claude Code
# expects for injecting additionalContext from a hook.
#
# Usage: inject-additional-context.sh <text-file> <hook-event-name>
#
# Exits silently with code 0 if the text file is missing — the session continues
# without the injection rather than failing.

set -euo pipefail

text_file="${1:?missing text file argument}"
hook_event_name="${2:?missing hook event name argument}"

if [[ ! -f "$text_file" ]]; then
  exit 0
fi

contents=$(cat "$text_file")

jq -n \
  --arg event "$hook_event_name" \
  --arg ctx "$contents" \
  '{hookSpecificOutput: {hookEventName: $event, additionalContext: $ctx}}'
