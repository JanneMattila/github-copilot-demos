# Exercises — 00 Context, Sessions & Effective Prompting

Source doc: [../00_CONTEXT.md](../00_CONTEXT.md)

## Learning objectives

After these exercises you should be able to:

- Explain what the context window is and what competes for space in it.
- Use `/context`, `/compact`, `/new`, `/clear`, `/resume` confidently.
- Reference files, issues/PRs and shell output in a prompt with `@`, `#` and `!`.
- Choose between Suggest, Edit and Autopilot modes for a given task.
- Write specific, scoped prompts instead of vague one-liners.

---

## Part A — Comprehension

### A1. Why does the size of the context window matter?

<details>
<summary>Show answer</summary>

The model can only "see" what fits inside the context window. Too little
context and Copilot gives generic suggestions; too much and important details
get buried. Old conversation turns also consume tokens that could otherwise be
spent reasoning about your current code.
</details>

### A2. Name at least four things that compete for space in the context window.

<details>
<summary>Show answer</summary>

Any four of: system prompt, custom instructions (`copilot-instructions.md`,
`AGENTS.md`, etc.), loaded skills, conversation history, `@file` references,
`#issue` references, tool results (file reads, search, command output), and the
generated response itself.
</details>

### A3. What is the difference between `/new` and `/clear`?

<details>
<summary>Show answer</summary>

`/new` starts a fresh conversation **inside the same session** — useful when
pivoting within the same general area. `/clear` abandons the current session
entirely and starts from scratch.
</details>

### A4. What does `/compact` actually do, and when should you reach for it?

<details>
<summary>Show answer</summary>

It asks Copilot to summarize the conversation history into a condensed form,
freeing up space in the context window. Use it after ~10–15 turns, before
working with large files, when Copilot starts repeating itself, or between
distinct phases of a large task (e.g., after planning, before implementing).
</details>

### A5. What's the difference between `@file`, `#issue` and `!cmd` in a prompt?

<details>
<summary>Show answer</summary>

- `@file` — explicitly add a file to the context (more efficient than letting
  Copilot search for it).
- `#issue` / `#PR` — fetch a GitHub issue or PR and add its content to context.
- `!cmd` — run a shell command and add its output to context.
</details>

### A6. Which interaction mode is best for "I'm new to this codebase, I want to review every change"?

<details>
<summary>Show answer</summary>

**Suggest** mode — Copilot proposes actions and you approve each one before it
happens. (Cycle through modes with `Shift+Tab`.)
</details>

---

## Part B — Hands-on tasks

### B1. Inspect your current context

**Goal:** see how much of the window is already used before you've done anything.

Steps to attempt:

1. Start a fresh Copilot CLI session in this repo (`copilot` then `/new`).
2. Run `/context`.
3. Note: which categories use the most tokens?

<details>
<summary>Hint</summary>

Run the command literally — `/context` (no arguments). The output is a small
visualization showing instructions, conversation history, tool results and
remaining budget.
</details>

### B2. Use `@` to reference a file

**Goal:** Ask a question that *requires* Copilot to read `server.js`, but
provide the file via `@` so Copilot doesn't have to search for it.

Success criteria:

- Your prompt contains an `@server.js` reference.
- Copilot's answer shows it actually read the file (it should mention specifics
  like the route or port).

<details>
<summary>Hint</summary>

Try something like:

```
What HTTP routes does @server.js expose, and on which port does it listen?
```

Tab-completion works after typing `@`.
</details>

### B3. Force a compaction and observe the effect

**Goal:** Run `/context`, do a long-ish exploration, run `/context` again, then
`/compact`, and confirm the percentage drops.

Steps:

1. `/context` — note the % used.
2. Ask Copilot to read 3–4 of the markdown docs in this repo (`@00_CONTEXT.md`
   `@02_INSTRUCTIONS.md` `@03_AGENTS.md`) and summarize each.
3. `/context` — note the new % used.
4. `/compact` and answer the prompt to summarize.
5. `/context` — confirm the % dropped.

<details>
<summary>Hint</summary>

If `/compact` doesn't seem to drop the number much, your conversation may
still be short. Add another large file read first (`@06_MCP.md` is the
biggest in this repo) before compacting.
</details>

### B4. Rewrite a vague prompt into a specific one

**Goal:** Take this bad prompt and turn it into a good one for *this* repo:

> "Add tests."

Success criteria:

- Your improved prompt names the file(s) under test.
- It specifies the test framework (or asks Copilot to choose one).
- It states what should be covered and how success is measured.

<details>
<summary>Solution</summary>

```
Add unit tests for @server.js using Node's built-in `node:test` runner.
Cover at least:
- the happy path for each HTTP route,
- a 404 for an unknown route,
- correct Content-Type headers.
Put the tests in `server.test.js`. Run them with `node --test` and make sure
they all pass before finishing.
```

The improvement: it names the file (`@server.js`), pins the framework, lists
explicit cases, says where the file goes, and states a success check.
</details>

### B5. Practise session hygiene

**Goal:** Use `/rename` to give your current session a meaningful name, then
prove you can come back to it.

Steps:

1. `/rename` — call this session `context-exercises`.
2. `/clear` to abandon it.
3. `/session` (or `/resume`) — find your `context-exercises` session and resume
   it.
4. Confirm the conversation history is intact.

<details>
<summary>Hint</summary>

`/session` lists all sessions. `/resume` accepts a session ID or name. If the
list is long, look for the name you set in step 1.
</details>

## Part C — In VS Code

> Use **VS Code (stable)** with the GitHub Copilot Chat extension. Open this repo as the workspace.

### C1. Comprehension — Map CLI to VS Code

Match each CLI action to its VS Code Chat equivalent:

| CLI | VS Code Chat |
|---|---|
| `/new` | ? |
| `@server.js` | ? |
| Autopilot mode | ? |
| `!git status` then use the output | ? |

<details>
<summary>Show answer</summary>

| CLI | VS Code Chat |
|---|---|
| `/new` | "New Chat" button at the top of the Chat view |
| `@server.js` | `#file:server.js`, or the **Add Context…** (📎) picker |
| Autopilot mode | **Agent** mode in the chat input mode dropdown |
| `!git status` then use the output | Run `git status` in the integrated terminal, then attach `#terminalLastCommand` |
</details>

### C2. Hands-on — context references in VS Code Chat

**Goal:** answer the same question you used in B2, but in VS Code Chat — and use at least three different context references.

Steps:

1. Open this repo in VS Code.
2. Open the Chat view (`Ctrl+Alt+I` / `Cmd+Ctrl+I`) and switch to **Ask** mode.
3. Open `server.js` and select a few lines.
4. Send a prompt that uses `#file:server.js`, `#selection`, and `#codebase` together — e.g.
   *"Using `#file:server.js`, the `#selection` I have open, and `#codebase` for context, what HTTP routes are exposed and how could a new `/healthz` route be added?"*
5. Look at the "Used N references" indicator on the reply to verify Chat actually attached all three.

<details>
<summary>Hint</summary>

Type `#` in the chat input to get autocomplete for available references — including `#file`, `#folder`, `#codebase`, `#selection`, `#editor`, `#problems`, `#changes`, `#terminalLastCommand`.
</details>

<details>
<summary>Solution</summary>

The point isn't a single right answer — it's that you saw Chat respect explicit references the way the CLI respects `@file`. Compare with Part B2: in CLI you used one `@server.js`; here you can layer references for richer context.
</details>

---

## Stretch goal

Pick a real (small) task in your own project — e.g., "add input validation to
one route" — and execute it end-to-end while:

1. Starting a named session for the task.
2. Using `@` to load only the files you actually need.
3. Calling `/context` at least twice during the task.
4. Calling `/compact` once, ideally between planning and implementation.
5. Switching modes deliberately (e.g., Suggest while planning, Autopilot while
   making a series of small edits).

Afterwards, write 2–3 sentences in your own notes about what you'd do
differently next time.
