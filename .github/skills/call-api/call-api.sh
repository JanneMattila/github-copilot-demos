#!/usr/bin/env bash
# call-api skill script — posts JSON to the echo API
set -euo pipefail

API_URL="https://echo.jannemattila.com/api/echo"
JSON_PAYLOAD="${1:?Usage: call-api.sh '<json-payload>'}"

echo "Posting to ${API_URL}..."
echo "Payload: ${JSON_PAYLOAD}"
echo "---"

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_URL}" \
  -H "Content-Type: application/json" \
  -d "${JSON_PAYLOAD}")

HTTP_CODE=$(echo "${RESPONSE}" | tail -1)
BODY=$(echo "${RESPONSE}" | sed '$d')

echo "HTTP Status: ${HTTP_CODE}"
echo "Response:"
echo "${BODY}"
