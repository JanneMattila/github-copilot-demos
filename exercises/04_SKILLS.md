# Exercises — 04 Skills

Source doc: [../04_SKILLS.md](../04_SKILLS.md)

## Learning objectives

- Explain what a skill is and how it differs from instructions and agents.
- Recognise when Copilot will (and won't) load a given skill.
- Create a minimal skill, including one with a script.
- Use the `allowed-tools` field responsibly.

---

## Part A — Comprehension

### A1. In one sentence: what is a skill?

<details>
<summary>Show answer</summary>

A folder containing a `SKILL.md` file (and optional scripts/resources) that
gives Copilot explicit, on-demand instructions for a specialized task.
</details>

### A2. When does Copilot load a particular skill?

<details>
<summary>Show answer</summary>

Only when it judges the skill to be relevant to the current prompt. The
decision is based on the `description` field in the skill's frontmatter —
so a clear, specific description matters a lot.
</details>

### A3. What's the security implication of `allowed-tools: shell`?

<details>
<summary>Show answer</summary>

Copilot will run shell commands referenced by the skill **without prompting
for confirmation**. Only set this on skills whose scripts you fully trust.
</details>

### A4. Where do skills live, and what's the difference between project and personal scope?

<details>
<summary>Show answer</summary>

Project: `.github/skills/` (also `.claude/skills/` or `.agents/skills/`) —
available only in that repo.
Personal: `~/.copilot/skills/` (also `~/.claude/skills/` or
`~/.agents/skills/`) — available in every project on your machine.
</details>

### A5. Skill or instruction? Where should each of these go?

1. "Always use 4-space indentation in this repo."
2. "When asked to deploy, run `./scripts/deploy.sh staging`."
3. "Use the project's preferred logger (`pino`) instead of `console.log`."
4. "When asked to call the echo API, POST a JSON body to https://echo.example/api/echo."

<details>
<summary>Show answer</summary>

- 1 → instruction (always relevant).
- 2 → skill (only when deploying).
- 3 → instruction (always relevant).
- 4 → skill (only when calling that specific API).

Rule of thumb: **always relevant ⇒ instruction; sometimes relevant ⇒ skill.**
</details>

---

## Part B — Hands-on tasks

### B1. Try the skills shipped with this repo

**Goal:** see on-demand loading in action.

Steps:

1. Run `copilot` in this repo, then `/skills` — note that `hello` and
   `call-api` are listed as *available* but not necessarily *loaded*.
2. Ask Copilot something unrelated (e.g. "summarize @server.js").
   `/skills` should still show them not loaded.
3. Ask Copilot to "say hello using the hello skill". Observe it loading and
   running.
4. Ask Copilot to "post `{\"hello\":\"world\"}` to the echo API". Observe the
   `call-api` skill being used.

<details>
<summary>Hint</summary>

If `/skills` doesn't appear to detect them, check the directory layout — the
file must be `.github/skills/<skill-name>/SKILL.md` (case-sensitive
`SKILL.md`).
</details>

### B2. Create a minimal `time` skill

**Goal:** build the smallest possible useful skill.

Success criteria:

- Path: `.github/skills/time/SKILL.md`
- No script — instructions only.
- `description` makes clear *when* Copilot should use it.
- Asking Copilot "what time is it in UTC?" causes the skill to load and
  produce a sensible answer.

<details>
<summary>Solution</summary>

`.github/skills/time/SKILL.md`:

```markdown
---
name: time
description: Reports the current date/time in UTC and (optionally) any IANA timezone the user requests. Use whenever the user asks about the current time.
---

# Current time

When the user asks for the current time:

1. Run `date -u +"%Y-%m-%dT%H:%M:%SZ"` (or PowerShell equivalent on Windows:
   `Get-Date -AsUTC -Format "yyyy-MM-ddTHH:mm:ssZ"`).
2. If the user names a timezone (e.g. "Europe/Helsinki"), additionally run
   `TZ=Europe/Helsinki date` (Linux/macOS) or
   `[System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId(...)` (PowerShell).
3. Reply with both the UTC time and the requested local time, in this format:

   ```
   UTC:  2026-04-22T17:45:00Z
   Local (Europe/Helsinki): 2026-04-22 20:45:00
   ```

Do not invent the time — always run the command.
```

Reload Copilot CLI (or run `/skills`), then test with:
> What time is it in UTC?
</details>

### B3. Add a script to a skill

**Goal:** convert the `time` skill from B2 to use a small shell script.

Steps:

1. Add `.github/skills/time/now.sh` (and `now.ps1` if you want cross-platform).
2. Reference it from `SKILL.md`.
3. Set `allowed-tools: shell` *only* if you genuinely trust the script.

<details>
<summary>Solution</summary>

`now.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
TZ_ARG="${1:-UTC}"
echo "UTC:   $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
if [ "$TZ_ARG" != "UTC" ]; then
  echo "Local ($TZ_ARG): $(TZ="$TZ_ARG" date '+%Y-%m-%d %H:%M:%S')"
fi
```

`now.ps1`:

```powershell
param([string]$TimeZone = "UTC")
$utc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
"UTC:   $utc"
if ($TimeZone -ne "UTC") {
    $tz = [System.TimeZoneInfo]::FindSystemTimeZoneById($TimeZone)
    $local = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((Get-Date).ToUniversalTime(), $tz)
    "Local ($TimeZone): $($local.ToString('yyyy-MM-dd HH:mm:ss'))"
}
```

Updated `SKILL.md` body:

```markdown
Run `now.sh` (or `now.ps1` on Windows) from this skill's directory. Pass
the IANA timezone as the first argument when the user requests a specific
zone (e.g. `Europe/Helsinki`).
```

Don't forget `chmod +x now.sh` on Linux/macOS.
</details>

### B4. Decide whether `allowed-tools: shell` is appropriate

**Goal:** apply the principle of least privilege.

For each skill below, decide *yes* (auto-approve shell), *no* (require
confirmation), or *no shell at all*:

1. The `time` skill from B3.
2. A `delete-stale-branches` skill that runs `git branch -D` for old branches.
3. A `count-todos` skill that greps `// TODO` lines and counts them.
4. A `deploy-prod` skill that runs Terraform apply against production.

<details>
<summary>Show answer</summary>

1. *Yes* — read-only, deterministic, harmless.
2. *No* — destructive; force confirmation by **omitting** `allowed-tools`.
3. *Yes* — read-only.
4. *No* — never auto-approve production changes. Some teams would even argue
   this shouldn't be a skill at all (use a deliberate deploy pipeline).
</details>

---

## Stretch goal

Pick one of these and build it:

- **`changelog`** — given a list of commit hashes (or "since v1.2.0"),
  produces a Keep-a-Changelog formatted entry.
- **`license-headers`** — adds (or fixes) a project's license header on every
  source file under `src/`.
- **`dep-tree`** — runs `npm ls --depth=0` (or your ecosystem's equivalent)
  and produces a Markdown summary of direct dependencies.

Constraints:

- ≤ 50 lines of `SKILL.md` body.
- A clear, specific `description` so Copilot only loads it when relevant.
- Cross-platform shell (`bash` + `powershell`) if you make scripts.
