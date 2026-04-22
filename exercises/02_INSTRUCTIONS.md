# Exercises — 02 Instructions

Source doc: [../02_INSTRUCTIONS.md](../02_INSTRUCTIONS.md)

## Learning objectives

- List the four types of instructions and where each lives.
- Explain how multiple instruction sources are merged.
- Write a focused `copilot-instructions.md` and a path-specific `.instructions.md`.
- Verify which instructions are actually loaded in a session.

---

## Part A — Comprehension

### A1. What are the four broad types of instructions, and the scope of each?

<details>
<summary>Show answer</summary>

- **Repository-wide** (`.github/copilot-instructions.md`) — every task in the repo.
- **Path-specific** (`.github/instructions/*.instructions.md`) — only when
  working on files matching a glob.
- **Agent instructions** (`AGENTS.md` / `CLAUDE.md` / `GEMINI.md`) — nearest
  one in the directory tree.
- **Personal / global** (`~/.copilot/copilot-instructions.md`) — every repo on
  your machine.
</details>

### A2. What happens when multiple instruction sources apply at the same time?

<details>
<summary>Show answer</summary>

They are **merged**, not replaced. If they conflict, more specific sources
(path-specific, nearest agent file) generally take precedence.
</details>

### A3. How does a path-specific instruction file restrict where it applies?

<details>
<summary>Show answer</summary>

Through YAML frontmatter with an `applyTo` glob, e.g.
`applyTo: "**/*.py"` or `applyTo: "src/api/**/*.ts,src/api/**/*.tsx"`.
The file is only loaded when Copilot is working on files matching the glob.
</details>

### A4. Which slash command do you use to verify which instruction files are currently loaded?

<details>
<summary>Show answer</summary>

`/instructions` — and `/env` for the broader view (instructions + skills + MCP
servers + ...).
</details>

### A5. List three things you should *not* put in an instruction file.

<details>
<summary>Show answer</summary>

Any three of: secrets/credentials, task-specific guidance ("when implementing
the login feature, do X"), vague platitudes ("write good code"), contradictory
rules across files, novel-length content, things obvious from `package.json` /
`tsconfig.json`, prompt-injection content.
</details>

---

## Part B — Hands-on tasks

### B1. Generate a starter `copilot-instructions.md`

**Goal:** use Copilot's own `/init` to bootstrap repo-wide instructions.

Steps:

1. In a scratch repo (or this one in a worktree — see [05_WORKTREES](./05_WORKTREES.md)),
   run `copilot` and then `/init`.
2. Review the generated `.github/copilot-instructions.md`.
3. Trim or rewrite anything that isn't true or isn't useful.

<details>
<summary>Hint</summary>

`/init` inspects the repo and produces sensible defaults. It is a *starting
point*, not a final document — keep it under ~2 pages and remove things
Copilot could already infer from `package.json`.
</details>

### B2. Write a path-specific instruction file

**Goal:** add a `.instructions.md` that only applies to JavaScript files.

Success criteria:

- File path: `.github/instructions/javascript.instructions.md`
- Frontmatter: `applyTo: "**/*.js"`
- Body: at least 3 specific, actionable rules (not platitudes).

<details>
<summary>Solution</summary>

`.github/instructions/javascript.instructions.md`:

```markdown
---
applyTo: "**/*.js"
---

# JavaScript Guidelines

- Use ES module syntax (`import` / `export`), not CommonJS `require`.
- Prefer `const`; only use `let` when reassignment is required.
- Use `async`/`await` instead of raw Promise chains.
- Run `node --test` before considering a change done.
```

Now open a `.js` file in that repo and run `/instructions` — your file should
appear in the loaded list. Open a `.md` file instead and re-run `/instructions`
— it should *not* be loaded.
</details>

### B3. Convert a vague rule into a specific one

**Goal:** Rewrite each of these into a "good" instruction line.

| Vague | Your rewrite |
|---|---|
| "Use the right package manager" | ? |
| "Test your code" | ? |
| "Put files in the right place" | ? |

<details>
<summary>Show answer</summary>

| Vague | Specific |
|---|---|
| "Use the right package manager" | "Always use `pnpm` (not `npm` or `yarn`). Lockfile is `pnpm-lock.yaml`." |
| "Test your code" | "Run `pnpm test` after every change. CI fails on any failing test or skipped test." |
| "Put files in the right place" | "Shared utilities go in `src/utils/`; HTTP route handlers in `src/routes/`; integration tests in `tests/integration/`." |
</details>

### B4. Personal vs repo instructions

**Goal:** distinguish what belongs where.

Sort each item below into either **repo-wide** (`.github/copilot-instructions.md`)
or **personal** (`~/.copilot/copilot-instructions.md`):

1. "Use 2-space indentation."
2. "I prefer functional patterns and descriptive variable names."
3. "Build with `dotnet build src/Api.sln`."
4. "When explaining code to me, be concise."
5. "All public functions in this repo must have JSDoc."

<details>
<summary>Show answer</summary>

- Repo-wide: 1, 3, 5 (project conventions and build steps everyone working on
  the repo should follow).
- Personal: 2, 4 (your own taste and how you want Copilot to talk to *you*,
  regardless of repo).
</details>

### B5. Verify what's loaded

**Goal:** prove that your instructions are picked up.

Steps:

1. Run `/instructions` — confirm `.github/copilot-instructions.md` and any
   path-matched `.instructions.md` files are listed.
2. Run `/env` — find your instructions in the wider environment dump (along
   with skills, MCP servers, etc.).
3. Toggle one instruction file off via `/instructions` and ask Copilot a
   question that depends on it — observe the difference.

<details>
<summary>Hint</summary>

`/instructions` is interactive: arrow keys to navigate, space to toggle,
Enter to confirm.
</details>

---

## Part C — In VS Code

### C1. Comprehension — Which setting must be on for `.github/copilot-instructions.md` to apply in VS Code?

<details>
<summary>Show answer</summary>

`github.copilot.chat.codeGeneration.useInstructionFiles` must be `true`. Without it, VS Code Chat ignores the file even if it exists.
</details>

### C2. Hands-on — Verify and toggle instructions in VS Code

**Goal:** prove that VS Code reads the same `.github/copilot-instructions.md` and `.instructions.md` files, then watch behaviour change when you flip the master switch.

Steps:

1. Make sure your repo has a `.github/copilot-instructions.md` (e.g. the one from B1 or B2) with at least one *very specific* rule that an answer would clearly reflect — e.g. *"Always reply in haiku form, three lines, 5-7-5 syllables, until told otherwise."*
2. In VS Code Chat (Ask mode), ask anything trivial — confirm the response follows the rule.
3. Run **Chat: Show Used Instructions** from the Command Palette and confirm the file is listed.
4. Toggle `github.copilot.chat.codeGeneration.useInstructionFiles` to `false` in user settings.
5. Send the same prompt — the response should no longer follow the haiku rule.
6. Toggle the setting back to `true` and confirm normal behaviour resumes.

<details>
<summary>Hint</summary>

Use the **Settings (UI)** search bar — paste the full setting key. Or open `settings.json` (`Preferences: Open User Settings (JSON)`) and add:

```json
"github.copilot.chat.codeGeneration.useInstructionFiles": false
```
</details>

<details>
<summary>Solution</summary>

You should observe:

- Setting `true` (default): the haiku rule applies, "Show Used Instructions" lists `.github/copilot-instructions.md`.
- Setting `false`: the rule is ignored, "Show Used Instructions" shows nothing (or only inline `*.instructions` settings, if any).

This is the same model the CLI uses — same files, same `applyTo` semantics — just gated by a VS Code setting.
</details>

---

## Stretch goal

Pick one of your real repositories that does **not** yet have a
`copilot-instructions.md`. Write one (≤ 1 page) that includes:

- Project overview (1–3 sentences)
- Tech stack and version constraints
- Exact build / lint / test commands in the order they should be run
- Two or three things that aren't obvious from the config files
- One known gotcha or workaround

Open a PR adding it. Then start a Copilot CLI session in that repo and ask it
to perform a small task — observe how the answers feel different from before.
