---
name: call-api
description: Posts a JSON payload to the echo API at https://echo.jannemattila.com/api/echo. Use this skill when the user asks to call the echo API, post JSON to an endpoint, or test an API call.
allowed-tools: shell
---

# Call API Skill

This skill sends a JSON payload to the echo API endpoint using `curl` (Linux/macOS/Windows) or `Invoke-RestMethod` (Windows PowerShell).

## Endpoint

```
POST https://echo.jannemattila.com/api/echo
Content-Type: application/json
```

The API echoes back whatever JSON you send it.

## Usage

### Using the script

Run the `call-api.sh` script (Linux/macOS) or `call-api.ps1` script (Windows) from this skill's directory, passing the JSON payload as the first argument.

```bash
# Linux/macOS
bash call-api.sh '{"message": "Hello from Copilot!", "timestamp": "2026-01-01T00:00:00Z"}'

# Windows PowerShell
powershell -File call-api.ps1 -Json '{"message": "Hello from Copilot!", "timestamp": "2026-01-01T00:00:00Z"}'
```

### Using curl directly

If the scripts are not available, use curl:

```bash
curl -s -X POST https://echo.jannemattila.com/api/echo \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello from Copilot!"}'
```

## Guidelines

1. Always set `Content-Type: application/json`
2. The JSON payload should come from the user — ask them what data to send if they haven't specified
3. Display the API response to the user after the call
4. If the call fails, show the HTTP status code and error message
