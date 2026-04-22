# Exercises — 01 Models

Source doc: [../01_MODELS.md](../01_MODELS.md)

## Learning objectives

- Switch models inside a session and from the command line.
- Match a model to a task (speed vs quality vs cost).
- Understand premium-request multipliers and how to monitor your usage.
- Know which models sub-agents typically use and why.

---

## Part A — Comprehension

### A1. Which model does Copilot CLI use by default?

<details>
<summary>Show answer</summary>

Claude Sonnet 4.5 (`claude-sonnet-4.5`) — chosen as a balance of speed and
quality.
</details>

### A2. What are two ways to switch models?

<details>
<summary>Show answer</summary>

1. The `/model` slash command inside a session (interactive picker).
2. The `--model <id>` flag when launching: `copilot --model claude-sonnet-4`.
</details>

### A3. Why might you choose Haiku for a task even though Opus is "smarter"?

<details>
<summary>Show answer</summary>

Haiku is much faster and cheaper, and for simple file operations / lookups /
quick questions the extra reasoning power of Opus is wasted. Premium models
also consume more requests from your monthly quota.
</details>

### A4. Which command shows your premium-request usage?

<details>
<summary>Show answer</summary>

`/usage`.
</details>

### A5. If your custom agent absolutely needs deep reasoning, can you pin it to Opus inside the agent definition?

<details>
<summary>Show answer</summary>

Not in Copilot CLI — the model used is always the one selected in the active
session. The doc suggests adding a hint inside the agent's instructions like
*"For best results, switch to Claude Opus 4.6 (`/model`) before using this
agent."*

(VS Code / JetBrains agent profiles do support a `model` field.)
</details>

---

## Part B — Hands-on tasks

### B1. List the models available to you

**Goal:** find out which models your account can actually use.

Steps:

1. Open Copilot CLI in any folder.
2. Run `/model`.
3. Note the list — which providers and tiers do you have access to?

<details>
<summary>Hint</summary>

The list is interactive — use arrow keys to navigate, Enter to select, Esc to
cancel without changing.
</details>

### B2. Compare two models on the same prompt

**Goal:** see for yourself how two models differ on a non-trivial task.

Steps:

1. Pick a small but ambiguous prompt, e.g.
   *"Refactor @server.js to use async/await everywhere and add a 1-paragraph
   explanation of what you changed."*
2. Run it with the default Sonnet 4.5.
3. `/undo` (or `/rewind`) to revert the changes.
4. `/model` → switch to a different tier (e.g., Haiku 4.5 or Opus 4.6).
5. Run the *exact same prompt* again.
6. Compare: how do the two responses differ in length, depth, choices?

<details>
<summary>Hint</summary>

Resist the temptation to reword the prompt between runs — keeping it
identical is what makes the comparison meaningful.
</details>

<details>
<summary>Solution sketch</summary>

You'll typically see:

- **Haiku** — fastest, smaller diff, less commentary, may miss subtleties.
- **Sonnet 4.5** — balanced diff, reasonable explanation.
- **Opus 4.6** — slower, more thorough reasoning, often catches edge cases the
  others miss; uses more premium request budget.

There's no single "right" answer — the lesson is that *different models give
different solutions to the same problem*, so it pays to experiment.
</details>

### B3. Launch with a specific model from the shell

**Goal:** start Copilot pinned to a model without going through `/model`.

Success criteria:

- You can show that the session opened on the model you asked for (use
  `/model` once inside to verify the current selection).

<details>
<summary>Hint</summary>

```bash
copilot --model claude-haiku-4.5
```

(Substitute any ID listed by `/model`.)
</details>

### B4. Check your premium-request budget

**Goal:** find out how much of your monthly quota is left.

Steps:

1. Run `/usage`.
2. Identify: total quota, used, and any per-model multipliers shown.
3. If you've been experimenting heavily with a premium model, note the impact.

<details>
<summary>Hint</summary>

If `/usage` doesn't exist on your version of the CLI, look at the GitHub
billing page → Copilot usage. The doc also links to *About premium requests*
in the further-reading section.
</details>

---

## Part C — In VS Code

### C1. Comprehension — Where is the VS Code model picker?

<details>
<summary>Show answer</summary>

In the **chat input bar** — click the model name in the lower-right of the chat input box to open the picker. The selection is remembered per chat mode (Ask / Edit / Agent), so you can default to a cheap model for Ask and a more capable one for Agent.
</details>

### C2. Hands-on — Compare two models in VS Code

**Goal:** repeat exercise B2, but inside VS Code Chat, and additionally pin different models per chat mode.

Steps:

1. Open the Chat view in VS Code, switch to **Ask** mode and pick the cheapest model available (e.g. Haiku 4.5 or GPT-5 mini).
2. Switch to **Edit** mode and pick the default Sonnet 4.5.
3. Switch to **Agent** mode and pick the most capable model you have (e.g. Opus 4.6 or GPT-5).
4. Ask a small refactor question in each mode, on the same file. Note how the answers differ.

<details>
<summary>Hint</summary>

The picker remembers each mode's choice independently. Open the dropdown in each mode and confirm — switching modes shouldn't reset your selection.
</details>

---

## Stretch goal

Design a small "model routing" personal rule for yourself: write 5–8 lines
describing which model you'll default to for each of these task categories:

- Quick file edit / rename / single-line fix
- Day-to-day coding & refactoring
- Multi-file / architectural changes
- Research & analysis with lots of reading
- Code review

Stick it in your `~/.copilot/copilot-instructions.md` so you remember to
follow it. (You'll learn more about that file in [02_INSTRUCTIONS](./02_INSTRUCTIONS.md).)
