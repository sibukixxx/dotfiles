#!/bin/bash
# Validate Read tool: block access to sensitive files

# Read JSON input from stdin
input=$(cat)

tool_name=$(echo "$input" | jq -r '.tool_name // ""')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')

# Only validate Read tool
if [[ "$tool_name" != "Read" ]]; then
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

# Block .env files
if echo "$file_path" | grep -qE '(^|/)\.env($|\.)'; then
  deny "Access to .env files is blocked for security reasons."
fi

# Block private keys and certificates
if echo "$file_path" | grep -qE '\.(pem|key)$'; then
  deny "Access to private key/certificate files (.pem, .key) is blocked."
fi

# Block credentials files
if echo "$file_path" | grep -qiE '(^|/)credentials\.json$'; then
  deny "Access to credentials.json is blocked for security reasons."
fi

# Block secrets directory
if echo "$file_path" | grep -qE '(^|/)secrets/'; then
  deny "Access to secrets/ directory is blocked for security reasons."
fi

exit 0
