#!/bin/bash
# Validate specific Bash commands usage

# Read JSON input from stdin
input=$(cat)

tool_name=$(echo "$input" | jq -r '.tool_name // ""')
command=$(echo "$input" | jq -r '.tool_input.command // ""')

# Only validate Bash tool
if [[ "$tool_name" != "Bash" ]]; then
  exit 0
fi

# Deny with JSON hookSpecificOutput
deny() {
  jq -n --arg reason "$1" '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": $reason
    }
  }'
  exit 0
}

# Check for forbidden commands
# Use word boundary matching to avoid false positives (e.g., "category" matching "cat")
if echo "$command" | grep -qE '\brm\s+-rf\b'; then
  deny "Use of 'rm -rf' is prohibited. Remove files individually or use a safer alternative."
fi

if echo "$command" | grep -qE '\bcurl\b'; then
  deny "Use of 'curl' is prohibited. Use dedicated tools (WebFetch, WebSearch) instead."
fi

if echo "$command" | grep -qE '\bwget\b'; then
  deny "Use of 'wget' is prohibited. Use dedicated tools (WebFetch, WebSearch) instead."
fi

if echo "$command" | grep -qE '\bchmod\s+777\b'; then
  deny "Use of 'chmod 777' is prohibited. Use more restrictive permissions (e.g., 755, 644)."
fi

exit 0
