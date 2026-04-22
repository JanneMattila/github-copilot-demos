# Exercises

Hands-on exercises that match each topic doc in this repo. Work through them in
order, or jump straight to a topic you want to practice.

| # | Topic | Exercise |
|---|-------|----------|
| 00 | Context, sessions & prompting | [00_CONTEXT.md](./00_CONTEXT.md) |
| 01 | Models | [01_MODELS.md](./01_MODELS.md) |
| 02 | Instructions | [02_INSTRUCTIONS.md](./02_INSTRUCTIONS.md) |
| 03 | Custom Agents | [03_AGENTS.md](./03_AGENTS.md) |
| 04 | Skills | [04_SKILLS.md](./04_SKILLS.md) |
| 05 | Worktrees | [05_WORKTREES.md](./05_WORKTREES.md) |
| 06 | MCP Servers | [06_MCP.md](./06_MCP.md) |
| 07 | Plugins | [07_PLUGINS.md](./07_PLUGINS.md) |
| 08 | Hooks | [08_HOOKS.md](./08_HOOKS.md) |

## How each exercise file is organized

Every exercise mirrors the same shape:

1. **Learning objectives** — what you should be able to do afterwards.
2. **Part A — Comprehension (Q&A)** — short questions about the concepts.
3. **Part B — Hands-on tasks (CLI)** — small things to do in **Copilot CLI**.
4. **Part C — In VS Code** — a comprehension question and a hands-on task in **VS Code (stable)** + GitHub Copilot Chat. For topics that are CLI-only (plugins, hooks), Part C explains the gap and suggests the closest VS Code workflow.
5. **Stretch goal** — one open-ended challenge with no provided solution.

## Hints, answers, solutions

Anything that would spoil the learning is hidden behind a collapsible block.
Try to answer / do the task first — only expand when you're stuck:

```markdown
<details>
<summary>Hint</summary>
The hint appears here when you click.
</details>
```

This renders on GitHub and most Markdown previewers as a clickable triangle.
You'll see three kinds of collapsible blocks:

- **Hint** — a nudge in the right direction.
- **Show answer** — the expected answer to a Q&A item.
- **Solution** — a worked walkthrough for a hands-on task.

## Prerequisites

- A working install of GitHub Copilot CLI (`copilot --version`).
- **VS Code (stable)** with the **GitHub Copilot Chat** extension installed and signed in to your Copilot account — used in every exercise's *Part C*.
- A scratch git repo you don't mind experimenting in (or use this one — most
  exercises only create files under `exercises-sandbox/` or your own
  `~/.copilot/` folder).
- Some exercises (worktrees, MCP, plugins) need network access and `git`.

## Recommended order

`00 → 01 → 02 → 03 → 04 → 06 → 07 → 08 → 05`

Worktrees (05) is independent of Copilot itself, so do it whenever you like —
but it pairs especially well with custom agents (03) and hooks (08) when you
start running multiple agent sessions in parallel.
