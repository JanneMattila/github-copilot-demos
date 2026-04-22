# Exercises — 03 Custom Agents

Source doc: [../03_AGENTS.md](../03_AGENTS.md)

## Learning objectives

- Describe what a custom agent is and how it differs from a skill or an
  instruction file.
- Create, install and select a custom agent in Copilot CLI.
- Restrict an agent's tool surface and attach an MCP server to it.
- Decide where an agent profile should live (repo / org / personal).

---

## Part A — Comprehension

### A1. In one sentence, what is a custom agent?

<details>
<summary>Show answer</summary>

A Markdown file (`*.agent.md`) defining a reusable AI persona — its role,
tools and behaviour — that you can select on demand instead of re-prompting
from scratch every time.
</details>

### A2. Where can agent profiles live, and what's the scope of each location?

<details>
<summary>Show answer</summary>

| Scope | Location |
|---|---|
| Repository | `.github/agents/` |
| Organization | `agents/` in the org's `.github` repo |
| Personal | `~/.copilot/agents/` |
| VS Code user | VS Code user profile folder |
</details>

### A3. Which frontmatter field is required, and what's the maximum body length?

<details>
<summary>Show answer</summary>

`description` is required. The Markdown body can be up to **30,000 characters**.
</details>

### A4. What happens if you omit the `tools` field in an agent profile?

<details>
<summary>Show answer</summary>

The agent gets access to **all** available tools. Use the `tools` array to
restrict (principle of least privilege).
</details>

### A5. Agents vs Skills vs Instructions — give the one-word "rule of thumb" for each.

<details>
<summary>Show answer</summary>

- Agents = **who**
- Skills = **how**
- Instructions = **what**
</details>

---

## Part B — Hands-on tasks

### B1. Inspect the example agents shipped with this repo

**Goal:** understand a real agent profile by reading one.

Steps:

1. Look at `.github/agents/roast-agent.agent.md` (and `emoji-agent.agent.md`).
2. Identify the frontmatter, the persona description, and any tool restrictions.
3. Run `copilot`, then `/agent`, and select `roast-agent`. Ask it to review
   one of your own files. Notice the tone change.

<details>
<summary>Hint</summary>

If `/agent` doesn't list them, confirm the files exist with the right
extension (`*.agent.md`) and that you're running Copilot from the repo root.
</details>

### B2. Build a minimal "commit-message" agent

**Goal:** create a tiny custom agent that writes Conventional Commits messages
based on staged changes.

Success criteria:

- File at `.github/agents/commit-msg.agent.md`.
- `description` clearly says when to use it.
- `tools` restricted to read-only + shell (no `edit`).
- Body explains the format (`type(scope): summary`) and gives 1–2 examples.
- You can select it via `/agent` and it produces a sensible message for
  `git diff --cached`.

<details>
<summary>Hint</summary>

Restricting tools means listing only what's needed. For this agent, something
like `tools: ["read", "search", "shell"]` is enough — it doesn't need `edit`.
</details>

<details>
<summary>Solution</summary>

`.github/agents/commit-msg.agent.md`:

```markdown
---
name: commit-msg
description: Writes Conventional Commits messages from currently staged changes. Select before running `git commit`.
tools: ["read", "search", "shell"]
---

You write **Conventional Commits**-formatted commit messages from the user's
currently staged Git changes.

## Workflow

1. Run `git diff --cached --stat` to see which files changed.
2. Run `git diff --cached` to read the actual change.
3. Pick the right type (`feat`, `fix`, `docs`, `refactor`, `test`, `chore`,
   `perf`, `ci`, `build`).
4. Pick a scope from the top-level folder of the changes (e.g. `api`,
   `ui`, `docs`).
5. Write a `<= 72 char` summary in the imperative mood ("add" not "added").
6. Optionally add a body explaining *why* the change was needed.
7. Print the final message in a fenced code block. Do **not** run `git
   commit` yourself.

## Examples

- `feat(api): add /healthz endpoint`
- `fix(ui): handle empty user list without crashing`
- `docs(readme): explain new --watch flag`

If nothing is staged, say so and stop.
```

Then in Copilot CLI:

```
/agent
→ commit-msg
> Suggest a commit message for my staged changes.
```
</details>

### B3. Tighten an agent's tool surface

**Goal:** take an existing agent (e.g. the one from B2) and verify the tool
restriction actually bites.

Steps:

1. With the `commit-msg` agent selected, ask it to *edit* a file — e.g.
   "Add a comment at the top of @server.js".
2. Observe that it cannot make the edit (no `edit` tool granted).
3. Loosen the restriction (`tools: ["read","search","shell","edit"]`) and try
   again — now it can.
4. Restore the strict version and commit only that.

<details>
<summary>Hint</summary>

You may need `/agent` again to re-select the agent after editing its profile,
so the new tool list is loaded.
</details>

### B4. Personal vs repo agent

**Goal:** decide where one of your own agents should live.

For each scenario, choose `.github/agents/`, `~/.copilot/agents/`, or "either":

1. A code-review agent that enforces *this* project's coding conventions.
2. An "explain in plain English" agent you want available everywhere.
3. A QA tester agent that uses Playwright MCP to test *this* web app.
4. A personal "daily standup" agent that summarizes yesterday's commits.

<details>
<summary>Show answer</summary>

1. `.github/agents/` — tied to this repo's conventions; everyone on the team
   benefits.
2. `~/.copilot/agents/` — personal, useful in any repo.
3. `.github/agents/` — depends on this app's tech and probably this app's MCP
   config.
4. `~/.copilot/agents/` — personal habit, not project-specific.
</details>

---

## Stretch goal

Build a more ambitious agent of your own choice. Suggestions:

- **`pr-reviewer`** — reads the diff against `main` and produces a concise PR
  review (no nitpicks about formatting, focus on bugs and design).
- **`docs-writer`** — given a function or file, writes (or updates) the
  matching Markdown docs and JSDoc/Pydoc comments.
- **`bug-hunter`** — given a stack trace, traces it through the codebase and
  proposes a minimal reproduction + fix.

Constraints to challenge yourself:

1. Tools restricted to the *minimum* necessary.
2. Body ≤ 1500 characters.
3. Includes at least one explicit "do NOT" rule.
4. Includes one example of expected output.

Then have a colleague (or another agent) try to break it with adversarial
prompts.
