# Exercises — 08 Hooks

Source doc: [../08_HOOKS.md](../08_HOOKS.md)

## Learning objectives

- Recognise the six hook triggers and when each fires.
- Configure hooks via `hooks.json` for both Linux/macOS and Windows.
- Use `preToolUse` to *block* dangerous tool calls.
- Read the JSON event sent on stdin to a hook script and act on it.
- Test and debug hooks locally.

---

## Part A — Comprehension

### A1. List the six hook triggers and what each is good for.

<details>
<summary>Show answer</summary>

| Trigger | When | Good for |
|---|---|---|
| `sessionStart` | Session begins | Setup, logging |
| `sessionEnd` | Session ends | Cleanup, summary |
| `userPromptSubmitted` | User sends a prompt | Prompt logging, content filters |
| `preToolUse` | Before a tool runs | Policy enforcement (can block!) |
| `postToolUse` | After a tool runs | Audit logs, validation |
| `errorOccurred` | An error happens | Error logging, alerting |
</details>

### A2. Why is `preToolUse` "the most powerful hook"?

<details>
<summary>Show answer</summary>

It can **prevent** the tool from running by exiting with a non-zero status.
That makes it the natural enforcement point for blocking destructive
commands, writes to protected paths, etc.
</details>

### A3. Where are hook configs loaded from in (a) Copilot CLI and (b) the cloud agent?

<details>
<summary>Show answer</summary>

- (a) `hooks.json` in the current working directory.
- (b) `.github/hooks/*.json` on the default branch of the repo.

Plugins can also bundle hooks via `plugin.json`'s `hooks` field.
</details>

### A4. What gets passed to a hook script and how?

<details>
<summary>Show answer</summary>

A JSON object is sent on **stdin**. The shape depends on the trigger; for
`preToolUse` / `postToolUse` it includes `timestamp`, `cwd`, `toolName` and
`toolArgs` (the latter is itself a JSON-encoded string).
</details>

### A5. Why should hook scripts log to a file rather than stdout?

<details>
<summary>Show answer</summary>

Stdout is part of the hook protocol — anything you print there can interfere
with how the agent interprets the hook's response. Use stderr for debug
output (`echo "debug" >&2`) and write real logs to files.
</details>

---

## Part B — Hands-on tasks

> Do these in a scratch directory (`C:\temp\hooks-demo` or similar) so you
> don't pollute a real repo.

### B1. Session-start logging

**Goal:** write a `hooks.json` that appends a line to `sessions.log` every
time a Copilot session starts in this directory.

Success criteria:

- Cross-platform (`bash` *and* `powershell` keys).
- After running `copilot` in the directory once, `sessions.log` contains a
  line with a timestamp.

<details>
<summary>Solution</summary>

`hooks.json`:

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "type": "command",
        "bash": "mkdir -p logs && echo \"$(date -u +'%Y-%m-%dT%H:%M:%SZ') session start in $(pwd)\" >> logs/sessions.log",
        "powershell": "New-Item -ItemType Directory -Force -Path logs | Out-Null; Add-Content -Path logs/sessions.log -Value \"$([DateTime]::UtcNow.ToString('o')) session start in $PWD\"",
        "timeoutSec": 5
      }
    ]
  }
}
```

Then `copilot` once, exit, and `Get-Content logs\sessions.log`.
</details>

### B2. Block `rm -rf /` style commands

**Goal:** add a `preToolUse` hook that aborts when the agent tries to run a
clearly destructive command.

Success criteria:

- A separate script (`scripts/safety-check.sh` and `.ps1`).
- Reads the JSON event from stdin.
- Exits 1 with a descriptive message on stderr if `toolName == "bash"` (or
  `"shell"`) and `toolArgs` matches a destructive pattern.
- Exits 0 otherwise.
- When the agent is asked to `rm -rf /`, the hook blocks it and the agent
  reports failure.

<details>
<summary>Solution</summary>

`hooks.json`:

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

`scripts/safety-check.sh`:

```bash
#!/usr/bin/env bash
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.toolName')
ARGS=$(echo "$INPUT" | jq -r '.toolArgs')
if [[ "$TOOL" =~ ^(bash|shell|powershell)$ ]]; then
  if echo "$ARGS" | grep -Eq 'rm[[:space:]]+-rf?[[:space:]]+/|Remove-Item.*-Recurse.*-Force.*[A-Z]:\\'; then
    echo "BLOCKED: destructive filesystem command refused by hook" >&2
    exit 1
  fi
fi
exit 0
```

`scripts/safety-check.ps1`:

```powershell
$input = [Console]::In.ReadToEnd()
$evt = $input | ConvertFrom-Json
$dangerous = '(?i)(rm\s+-rf?\s+/|Remove-Item.*-Recurse.*-Force.*[A-Z]:\\)'
if ($evt.toolName -in @('bash','shell','powershell')) {
    if ($evt.toolArgs -match $dangerous) {
        [Console]::Error.WriteLine("BLOCKED: destructive filesystem command refused by hook")
        exit 1
    }
}
exit 0
```

Make the bash script executable: `chmod +x scripts/safety-check.sh`.
</details>

### B3. Test the hook locally without Copilot

**Goal:** verify exit codes and behaviour by piping fake input.

Steps (bash):

```bash
# Should pass
echo '{"timestamp":1,"cwd":"/tmp","toolName":"bash","toolArgs":"{\"command\":\"ls -la\"}"}' \
  | ./scripts/safety-check.sh
echo "exit=$?"

# Should block
echo '{"timestamp":1,"cwd":"/tmp","toolName":"bash","toolArgs":"{\"command\":\"rm -rf /\"}"}' \
  | ./scripts/safety-check.sh
echo "exit=$?"
```

Steps (PowerShell):

```powershell
'{"timestamp":1,"cwd":"C:\\","toolName":"bash","toolArgs":"{\"command\":\"ls -la\"}"}' `
  | .\scripts\safety-check.ps1
"exit=$LASTEXITCODE"

'{"timestamp":1,"cwd":"C:\\","toolName":"bash","toolArgs":"{\"command\":\"rm -rf /\"}"}' `
  | .\scripts\safety-check.ps1
"exit=$LASTEXITCODE"
```

<details>
<summary>Hint</summary>

If the Bash tests fail with "jq: command not found", install jq
(`winget install jqlang.jq` on Windows, `apt install jq` / `brew install jq`
elsewhere) — or rewrite the hook in pure shell using `grep -o`.
</details>

### B4. Add a `postToolUse` audit log

**Goal:** record every tool the agent uses, with timestamp and arguments.

Success criteria:

- Appends to `logs/audit.log`.
- Each line is JSON or a clearly delimited line containing the timestamp,
  `toolName`, and (truncated) `toolArgs`.
- Doesn't interfere with the agent (writes to file, not stdout).

<details>
<summary>Solution</summary>

`hooks.json` (add alongside any existing hooks):

```json
{
  "postToolUse": [
    {
      "type": "command",
      "bash": "./scripts/audit-log.sh",
      "powershell": ".\\scripts\\audit-log.ps1",
      "timeoutSec": 5
    }
  ]
}
```

`scripts/audit-log.sh`:

```bash
#!/usr/bin/env bash
INPUT=$(cat)
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TOOL=$(echo "$INPUT" | jq -r '.toolName')
ARGS=$(echo "$INPUT" | jq -c '.toolArgs' | cut -c1-200)
mkdir -p logs
echo "$TS | $TOOL | $ARGS" >> logs/audit.log
```

`scripts/audit-log.ps1`:

```powershell
$input = [Console]::In.ReadToEnd()
$evt = $input | ConvertFrom-Json
$ts = [DateTime]::UtcNow.ToString('o')
$args = ($evt.toolArgs | Out-String).Trim()
if ($args.Length -gt 200) { $args = $args.Substring(0, 200) }
New-Item -ItemType Directory -Force -Path logs | Out-Null
Add-Content -Path logs/audit.log -Value "$ts | $($evt.toolName) | $args"
```
</details>

### B5. Spot the bug

**Goal:** read this hook and explain why it sometimes silently lets bad
commands through.

```json
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      {
        "type": "command",
        "bash": "grep -q 'rm -rf' /dev/stdin && exit 1",
        "timeoutSec": 5
      }
    ]
  }
}
```

<details>
<summary>Show answer</summary>

A few problems:

1. The implicit exit code when `grep` does *not* match is non-zero (1) for
   `grep -q`, which the agent treats as "blocked" — so this *over*-blocks,
   refusing every command that doesn't contain "rm -rf".
2. Even if you fix that, it only checks for the exact string `rm -rf`; an
   attacker could write `rm  -rf` (two spaces) or `rm -r -f` and slip past.
3. There's no PowerShell variant, so on Windows the hook doesn't run at all.
4. It reads stdin directly, but the JSON wrapping means the actual command
   string is inside `.toolArgs`, not at the top level — a robust check needs
   to parse the JSON (e.g. with `jq`).

The fix is the structured script approach used in B2 (parse JSON, regex
properly, explicit `exit 0` on the happy path, both shells provided).
</details>

---

## Part C — In VS Code

> ⚠️ Hooks **do not run** in VS Code's GitHub Copilot Chat extension. They only fire in Copilot CLI and the cloud agent. This part teaches you the *equivalent VS Code workflow*.

### C1. Comprehension — Match each hook use case to its closest VS Code-friendly equivalent

| Hook use case | Best VS Code-friendly replacement |
|---|---|
| Log every shell tool call to a file | ? |
| Block `git push --force` to `main` | ? |
| Send a Slack notification when a session starts | ? |
| Audit trail of all agent actions for compliance | ? |

<details>
<summary>Show answer</summary>

| Hook use case | VS Code-friendly equivalent |
|---|---|
| Log every shell tool call to a file | "Output: GitHub Copilot Chat" log channel; or a small chat-usage extension |
| Block `git push --force` to `main` | Repo branch protection rule on the remote, or a local `pre-push` hook (Husky / `pre-commit`) |
| Send a Slack notification when a session starts | A VS Code task that runs on workspace open; or a status-bar extension |
| Audit trail of all agent actions for compliance | Source-control-driven audit (require PRs, branch protection, signed commits) + CI checks |

The big mental shift: in VS Code you can't *intercept* the agent itself, so you push the policy out to the **edges** — the editor lifecycle, the local git hooks, and the remote (GitHub) protections.
</details>

### C2. Hands-on — Implement a "no force-push to main" policy without Copilot hooks

**Goal:** replicate the spirit of B-style policy enforcement using VS Code-friendly tools.

Pick **one** of the following:

**Option A — Local `pre-push` hook (works everywhere):**

1. In a scratch repo:
   ```bash
   mkdir -p .githooks
   ```
2. Create `.githooks/pre-push`:
   ```bash
   #!/usr/bin/env bash
   while read local_ref local_sha remote_ref remote_sha; do
     if [[ "$remote_ref" == "refs/heads/main" ]]; then
       if git rev-list --left-right --count "$remote_sha...$local_sha" | awk '{exit ($1 != 0)}'; then
         echo "BLOCKED: force-push to main refused by pre-push hook" >&2
         exit 1
       fi
     fi
   done
   exit 0
   ```
3. `chmod +x .githooks/pre-push && git config core.hooksPath .githooks`
4. Try `git push --force origin main` — it should be blocked, regardless of whether Copilot, you, or any IDE issued the push.

**Option B — Remote branch protection (works for the team):**

1. On GitHub, open the repo → Settings → Branches → "Add branch protection rule".
2. Pattern: `main`. Enable "Restrict force pushes" (and "Require pull request reviews").
3. Try `git push --force origin main` — GitHub rejects it server-side.
4. Document this in the repo's `README.md` so VS Code users know the rule exists.

<details>
<summary>Hint</summary>

The pre-push hook approach is **defence in depth** — you can stack it with branch protection. Keep `.githooks/` in the repo and document the `git config core.hooksPath .githooks` step in your README so teammates opt in.
</details>

<details>
<summary>Solution</summary>

You should observe:

- A normal `git push origin main` (fast-forward) succeeds.
- `git push --force origin main` is refused either locally (Option A: by your hook script) or remotely (Option B: by GitHub).
- Crucially, this works regardless of whether the push came from Copilot CLI, VS Code Chat in Agent mode, or you typing in a terminal — because the policy lives **outside** the agent.

That's the right mental model for VS Code: when you can't hook the agent, hook the *workflow*.
</details>

---

## Stretch goal

Build a small "policy pack" `hooks.json` for a real repo of yours that:

1. Blocks `git push --force` on protected branches (parse `toolArgs`).
2. Logs every `bash`/`shell` invocation to `logs/audit.log` with a SHA so
   you can correlate later.
3. Sends a Slack notification on `errorOccurred` (read the webhook URL from
   an env var, never hardcode).
4. On `sessionStart`, prints the current git branch and warns if it's
   `main` (gentle nudge to use a feature branch / worktree).

Run a real Copilot session with these hooks active and confirm:
- The audit log fills up.
- Trying to force-push to `main` is blocked.
- A deliberately broken command triggers the Slack notification.
