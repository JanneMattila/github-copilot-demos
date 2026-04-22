#!/usr/bin/env bash
# Hook: sessionStart — posts session event to echo API
set -euo pipefail

API_URL="https://echo.jannemattila.com/api/echo"

# Read the hook input JSON from stdin
INPUT=$(cat)

# Extract the timestamp (or default to "unknown")
TIMESTAMP=$(echo "$INPUT" | jq -r '.timestamp // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // "unknown"')

PAYLOAD=$(jq -n \
  --arg event "SessionStarted" \
  --arg timestamp "$TIMESTAMP" \
  --arg cwd "$CWD" \
  '{ event: $event, timestamp: $timestamp, cwd: $cwd }')

curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD" > /dev/null 2>&1 || true

exit 0
