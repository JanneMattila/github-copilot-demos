# Hooks for GitHub Copilot

Hooks let you run **custom shell commands at key points** during Copilot agent execution. They're the automation layer — use them for logging, validation, policy enforcement, notifications, and workflow integration.

This guide covers:

1. [What Are Hooks?](#what-are-hooks)
2. [Hook Triggers](#hook-triggers)
3. [Configuration](#configuration)
4. [Hook Syntax](#hook-syntax)
5. [Practical Examples](#practical-examples)
6. [Debugging Hooks](#debugging-hooks)
7. [Tips & Best Practices](#tips--best-practices)
8. [Further Reading](#further-reading)

---

> ⚠️ **Not a VS Code chat feature.** Hooks fire only inside **Copilot CLI** (`hooks.json` in the working directory) and the **cloud agent** (`.github/hooks/*.json` on the default branch). VS Code's GitHub Copilot Chat extension does **not** run these hooks.
>
> If you need similar behaviour in VS Code, the closest alternatives are:
>
> | Hook use case | VS Code-friendly alternative |
> |---|---|
> | Logging tool calls | "Output → GitHub Copilot Chat" log channel; chat usage extensions |
> | Blocking destructive shell commands | Pre-commit / pre-push hooks (Husky, `pre-commit`), shell aliases, branch protection |
> | Notifying on session start/end | VS Code tasks that run on workspace open; status-bar extensions |
> | Audit trail for compliance | Source-control-driven audit (require PRs, branch protection, signed commits) + CI checks |
>
> The rest of this doc is CLI / cloud-agent specific.

---

## What Are Hooks?

Hooks are event-driven shell commands that execute at specific points in the Copilot agent lifecycle. They let you:

- 📝 **Log** session activity and tool usage
- 🔒 **Enforce policies** (block dangerous commands before execution)
- 🔔 **Send notifications** (Slack, email, webhooks)
- ✅ **Validate** outputs after tool execution
- 🔧 **Set up / tear down** environments at session start/end
- 📊 **Collect metrics** on agent usage

Hooks work in both **Copilot CLI** (loaded from current directory) and **Copilot cloud agent** (loaded from `.github/hooks/` on the default branch).

---

## Hook Triggers

There are six lifecycle events you can hook into:

| Trigger | When It Fires | Use Cases |
|---|---|---|
| `sessionStart` | When a Copilot session begins | Environment setup, logging, notifications |
| `sessionEnd` | When a session ends | Cleanup, summary logging, metrics |
| `userPromptSubmitted` | When the user sends a prompt | Prompt logging, content filtering |
| `preToolUse` | **Before** a tool executes | Policy enforcement, blocking dangerous ops |
| `postToolUse` | **After** a tool executes | Audit logging, validation, notifications |
| `errorOccurred` | When an error happens | Error logging, alerting, recovery |

### The Power of `preToolUse`

`preToolUse` is the most powerful hook — it can **prevent** tool execution by returning a non-zero exit code. This is your enforcement point:

- Block `rm -rf` commands
- Prevent writes to protected directories
- Require confirmation for destructive operations
- Enforce coding standards before file edits

### `postToolUse` for Audit

`postToolUse` runs after a tool completes. It **cannot** block the result, but it's perfect for:

- Logging what tools were used and their results
- Triggering follow-up actions
- Collecting usage statistics

---

## Configuration

### File Location

| Environment | Location | Notes |
|---|---|---|
| **Copilot CLI** | `hooks.json` in current working directory | Auto-discovered |
| **Cloud Agent** | `.github/hooks/*.json` | Must be on default branch |
| **Plugin** | Referenced in `plugin.json` via `hooks` field | Bundled with plugin |

### Basic Structure

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [...],
    "sessionEnd": [...],
    "userPromptSubmitted": [...],
    "preToolUse": [...],
    "postToolUse": [...],
    "errorOccurred": [...]
  }
}
```

Each trigger contains an **array** of hook definitions. You can have multiple hooks per trigger — they run in order.

---

## Hook Syntax

Each hook in the array is an object with these fields:

| Field | Type | Required | Description |
|---|---|---|---|
| `type` | string | ✅ | Always `"command"` |
| `bash` | string | ✅* | Shell command for Linux/macOS |
| `powershell` | string | ✅* | Shell command for Windows |
| `cwd` | string | ❌ | Working directory for the command |
| `timeoutSec` | number | ❌ | Timeout in seconds (default: 30) |
| `env` | object | ❌ | Additional environment variables |

*At least one of `bash` or `powershell` is required. Provide both for cross-platform support.

### Inline Commands

```json
{
  "type": "command",
  "bash": "echo \"Tool: $TOOL_NAME\" >> /tmp/copilot.log",
  "powershell": "Add-Content -Path $env:TEMP\\copilot.log -Value \"Tool: $env:TOOL_NAME\"",
  "timeoutSec": 5
}
```

### Script References

```json
{
  "type": "command",
  "bash": "./scripts/pre-check.sh",
  "powershell": ".\\scripts\\pre-check.ps1",
  "cwd": ".",
  "timeoutSec": 10
}
```

### Input Data

Hooks receive a JSON object on **stdin** with context about the event. The shape depends on the trigger:

**`preToolUse` / `postToolUse` input:**
```json
{
  "timestamp": 1704614400000,
  "cwd": "/path/to/project",
  "toolName": "bash",
  "toolArgs": "{\"command\":\"ls -la\"}"
}
```

**`sessionStart` input:**
```json
{
  "timestamp": 1704614400000,
  "cwd": "/path/to/project"
}
```

---

## Practical Examples

### Example 1: Session Logging

Log session start and end times:

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "type": "command",
        "bash": "echo \"Session started: $(date)\" >> logs/copilot-sessions.log",
        "powershell": "Add-Content -Path logs/copilot-sessions.log -Value \"Session started: $(Get-Date)\"",
        "timeoutSec": 5
      }
    ],
    "sessionEnd": [
      {
        "type": "command",
        "bash": "echo \"Session ended: $(date)\" >> logs/copilot-sessions.log",
        "powershell": "Add-Content -Path logs/copilot-sessions.log -Value \"Session ended: $(Get-Date)\"",
        "timeoutSec": 5
      }
    ]
  }
}
```

### Example 2: Block Dangerous Commands

Prevent `rm -rf /` and other dangerous patterns:

```json
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      {
        "type": "command",
        "bash": "./scripts/safety-check.sh",
        "powershell": ".\\scripts\\safety-check.ps1",
        "cwd": ".",
        "timeoutSec": 5
      }
    ]
  }
}
```

**`scripts/safety-check.sh`:**
```bash
#!/bin/bash
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName')
TOOL_ARGS=$(echo "$INPUT" | jq -r '.toolArgs')

if [ "$TOOL_NAME" = "bash" ]; then
  if echo "$TOOL_ARGS" | grep -qE 'rm\s+-rf\s+/'; then
    echo "BLOCKED: Dangerous rm -rf command" >&2
    exit 1  # Non-zero exit blocks the tool
  fi
fi

exit 0  # Allow the tool to proceed
```

### Example 3: Audit Trail

Log every tool invocation for compliance:

```json
{
  "version": 1,
  "hooks": {
    "postToolUse": [
      {
        "type": "command",
        "bash": "./scripts/audit-log.sh",
        "timeoutSec": 5
      }
    ]
  }
}
```

**`scripts/audit-log.sh`:**
```bash
#!/bin/bash
INPUT=$(cat)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TOOL=$(echo "$INPUT" | jq -r '.toolName')
echo "$TIMESTAMP | Tool: $TOOL | Args: $(echo "$INPUT" | jq -c '.toolArgs')" >> logs/audit.log
```

### Example 4: Slack Notification on Session Start

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "type": "command",
        "bash": "curl -s -X POST $SLACK_WEBHOOK -H 'Content-type: application/json' -d '{\"text\":\"Copilot session started in '$(pwd)'\"}'",
        "timeoutSec": 10,
        "env": {
          "SLACK_WEBHOOK": "${SLACK_WEBHOOK_URL}"
        }
      }
    ]
  }
}
```

### Example 5: Prompt Logging

```json
{
  "version": 1,
  "hooks": {
    "userPromptSubmitted": [
      {
        "type": "command",
        "bash": "./scripts/log-prompt.sh",
        "powershell": ".\\scripts\\log-prompt.ps1",
        "cwd": "scripts",
        "env": {
          "LOG_LEVEL": "INFO"
        }
      }
    ]
  }
}
```

---

## Debugging Hooks

### Enable Verbose Logging in Scripts

```bash
#!/bin/bash
set -x  # Enable bash debug mode
INPUT=$(cat)
echo "DEBUG: Received input:" >&2
echo "$INPUT" >&2
# ... rest of script
```

### Test Hooks Locally

Pipe test input into your hook script:

```bash
# Simulate a preToolUse event
echo '{"timestamp":1704614400000,"cwd":"/tmp","toolName":"bash","toolArgs":"{\"command\":\"ls\"}"}' | ./scripts/safety-check.sh

# Check exit code
echo $?

# Validate JSON output
./scripts/my-hook.sh < test-input.json | jq .
```

### Common Issues

| Issue | Solution |
|---|---|
| Hook not executing | Check JSON syntax, verify `version: 1`, check file location |
| Hook timing out | Increase `timeoutSec`, optimize script performance |
| Invalid JSON output | Use `jq -c` (bash) or `ConvertTo-Json -Compress` (PowerShell) |
| Script not found | Verify path, check `cwd` setting, ensure script is executable (`chmod +x`) |
| Permission denied | Run `chmod +x script.sh`, check shebang line (`#!/bin/bash`) |

---

## Tips & Best Practices

1. **Start simple** — begin with logging hooks before building enforcement
2. **Always provide both `bash` and `powershell`** — for cross-platform teams
3. **Keep hooks fast** — they run synchronously and delay the agent; keep `timeoutSec` low
4. **Use `preToolUse` sparingly** — blocking hooks slow down the workflow
5. **Log to files, not stdout** — hook stdout may interfere with agent communication
6. **Use stderr for debug output** — `echo "debug" >&2` won't affect the hook protocol
7. **Test locally before committing** — pipe test JSON into scripts to verify behavior
8. **Use environment variables for secrets** — webhook URLs, API keys, etc.
9. **Version your hooks** — always include `"version": 1` for forward compatibility
10. **Document your hooks** — explain what each hook does and why in comments or a README

---

## Further Reading

- [GitHub Docs: Using Hooks](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/use-hooks)
- [GitHub Docs: Hooks Configuration Reference](https://docs.github.com/en/copilot/reference/hooks-configuration)
- [GitHub Docs: About Hooks](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-hooks)
