# Context, Sessions & Effective Prompting

Understanding how GitHub Copilot manages context is the single most important thing for getting great results. This guide covers how the context window works, how to manage sessions, and best practices for effective agentic development.

This guide covers:

1. [How Copilot Uses Context](#how-copilot-uses-context)
2. [The Context Window](#the-context-window)
3. [What Goes Into Context](#what-goes-into-context)
4. [Session Management](#session-management)
5. [The `/compact` Command](#the-compact-command)
6. [Referencing Files and Issues](#referencing-files-and-issues)
7. [Interaction Modes](#interaction-modes)
8. [Effective Prompting Patterns](#effective-prompting-patterns)
9. [Advanced Features](#advanced-features)
10. [Best Practices Summary](#best-practices-summary)
11. [Further Reading](#further-reading)

---

## How Copilot Uses Context

Every time you send a message to Copilot, the agent assembles a **context window** — a bundle of information that includes your conversation history, relevant files, instructions, skills, and more. The AI model reads this entire context to generate its response.

**The quality of Copilot's output is directly proportional to the quality of its context.**

Think of it like briefing a new developer: the more relevant information they have, the better their work will be. But give them too much irrelevant information and they'll get confused or miss what matters.

---

## The Context Window

The context window has a **fixed size** measured in tokens (roughly 3/4 of a word per token). Everything Copilot needs to understand must fit in this window:

```
┌─────────────────────────────────────────────┐
│              CONTEXT WINDOW                 │
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │ System prompt & instructions        │    │
│  │ (copilot-instructions.md, AGENTS.md │    │
│  │  path-specific instructions, etc.)  │    │
│  └─────────────────────────────────────┘    │
│  ┌─────────────────────────────────────┐    │
│  │ Loaded skills (when relevant)       │    │
│  └─────────────────────────────────────┘    │
│  ┌─────────────────────────────────────┐    │
│  │ Conversation history                │    │
│  │ (your messages + Copilot responses) │    │
│  └─────────────────────────────────────┘    │
│  ┌─────────────────────────────────────┐    │
│  │ Referenced files (@file mentions)   │    │
│  └─────────────────────────────────────┘    │
│  ┌─────────────────────────────────────┐    │
│  │ Tool results                        │    │
│  │ (file reads, search results,        │    │
│  │  command output, etc.)              │    │
│  └─────────────────────────────────────┘    │
│  ┌─────────────────────────────────────┐    │
│  │ AI response (generated)             │    │
│  └─────────────────────────────────────┘    │
└─────────────────────────────────────────────┘
```

### Why Context Size Matters

- **Too little context** → Copilot doesn't understand your codebase and makes generic suggestions
- **Too much context** → Important details get buried, responses become less focused
- **Stale context** → Old conversation turns consume tokens that could be used for current work
- **Right context** → Copilot understands exactly what you need and delivers precise, relevant results

### Checking Context Usage

Use the `/context` command to see how much of your context window is being used:

```
/context
```

This shows a visualization of token usage — how much is consumed by instructions, conversation history, tool results, and how much is still available.

---

## What Goes Into Context

### Automatically loaded (always present)

| Source | Description |
|---|---|
| System prompt | Copilot's base behavior and capabilities |
| `copilot-instructions.md` | Your repo-wide custom instructions |
| `AGENTS.md` / `CLAUDE.md` / `GEMINI.md` | Agent instructions (nearest in directory tree) |
| `~/.copilot/copilot-instructions.md` | Your personal global instructions |
| Path-specific instructions | `.instructions.md` files matching current files |
| Agent profile | If you've selected a custom agent via `/agent` |

### Loaded on demand

| Source | How it's triggered |
|---|---|
| Skills (`SKILL.md`) | When Copilot decides a skill is relevant to your prompt |
| `@file` mentions | When you explicitly reference files with `@` |
| `#issue` / `#PR` mentions | When you reference GitHub issues or PRs with `#` |
| Tool results | When Copilot reads files, searches code, runs commands |
| Conversation history | Accumulates with each turn in the session |

### The key insight

Everything in the context window competes for space. Long conversation histories push out room for file contents and tool results. This is why `/compact` exists.

---

## Session Management

A **session** is a conversation with Copilot that persists across turns. Sessions keep your conversation history, so Copilot remembers what you discussed and what changes were made.

### Key Session Commands

| Command | What it does |
|---|---|
| `/new` | Start a fresh conversation (within the same session) |
| `/clear` | Abandon the current session entirely and start fresh |
| `/resume` | Switch to a different session (by ID or task ID) |
| `/rename` | Give your session a meaningful name |
| `/session` | View and manage sessions |
| `/share` | Export session to Markdown, HTML, or GitHub gist |
| `/compact` | Summarize history to free up context space |
| `/undo` or `/rewind` | Undo the last turn and revert file changes |

### When to Start a New Session

Start a new session (`/clear`) when:

- ✅ You're switching to a completely different task
- ✅ The conversation has gotten long and unfocused
- ✅ Copilot seems "confused" or giving irrelevant responses
- ✅ You want a clean slate without any prior context

Use `/new` (lighter) when:

- ✅ You want to start a new conversation but keep the session for reference
- ✅ You're pivoting within the same general area of work

### When to Resume a Session

Use `/resume` when:

- ✅ You closed the CLI but want to continue where you left off
- ✅ You have multiple active tasks and want to switch between them
- ✅ You delegated work and want to check on it

### Session Lifecycle Best Practices

1. **One task per session** — Don't mix unrelated tasks in one session. Start fresh for each major task.
2. **Name your sessions** — Use `/rename` so you can find them later with `/resume`
3. **Compact regularly** — Use `/compact` when conversation gets long (see next section)
4. **Review before resuming** — When resuming an old session, re-read the context to orient yourself

---

## The `/compact` Command

`/compact` is one of the most important commands for long-running sessions. It tells Copilot to **summarize the conversation history** into a condensed form, freeing up context window space.

### How it works

1. You run `/compact`
2. Copilot reads the full conversation history
3. It generates a concise summary capturing key decisions, changes made, and current state
4. The verbose history is replaced with this summary
5. You now have more room in the context window for new work

### When to use `/compact`

- 🕐 **After 10-15 turns** — conversation history starts consuming significant context
- 📄 **Before working on large files** — free up room so Copilot can read more of the file
- 🔄 **When Copilot starts "forgetting"** — if it repeats itself or loses track, the context is probably full
- 🏗️ **Between phases of a large task** — compact after planning, before implementing

### Example workflow

```
# Start a task
> Analyze the authentication module and suggest improvements

# ... several turns of discussion ...

# Context is getting full, compact before implementing
/compact

# Now there's room for implementation
> Implement the improvements we discussed
```

### What `/compact` preserves

- Key decisions and conclusions
- File changes that were made
- Current state of the task
- Important technical details

### What `/compact` drops

- Verbose back-and-forth discussion
- Intermediate reasoning and exploration
- Redundant file contents that were read multiple times
- Tool output from earlier turns

---

## Referencing Files and Issues

### `@` — Mention Files

Use `@` to explicitly add files to the context:

```
> Look at @server.js and add error handling
> Compare @src/auth.js with @src/auth.test.js
```

This is more efficient than waiting for Copilot to search for files — you're directly telling it what to look at.

**Tips:**
- Reference only the files Copilot needs — don't dump everything
- Use `@` for files Copilot might not find on its own
- Tab completion works for file paths after `@`

### `#` — Mention Issues and PRs

Use `#` to reference GitHub issues and pull requests:

```
> Implement the feature described in #42
> Review the changes in #108
```

Copilot will fetch the issue/PR details from GitHub and include them in the context.

### `!` — Run Shell Commands

Use `!` to quickly run a shell command:

```
> !git log --oneline -5
> !npm test
```

The output is added to the context for Copilot to reference.

---

## Interaction Modes

Copilot CLI has different interaction modes. Cycle through them with `Shift+Tab`:

| Mode | Description | Best For |
|---|---|---|
| **Suggest** | Copilot proposes actions, you approve each one | Careful, step-by-step work |
| **Edit** | Copilot edits files directly with your approval | Focused code changes |
| **Autopilot** | Copilot works autonomously until the task is done | Complex multi-step tasks (experimental) |

### Choosing the Right Mode

- **New to a codebase?** Use **Suggest** mode so you can review each action
- **Making specific changes?** Use **Edit** mode for focused work
- **Confident in the task?** Use **Autopilot** for hands-off execution
- **Not sure?** Start with Suggest, switch to Autopilot once you trust the approach

---

## Effective Prompting Patterns

### 1. Be Specific About What You Want

```
# Bad ❌
> Fix the bug

# Good ✅
> The /api/users endpoint returns 500 when the email field is missing.
> Add input validation to return a 400 with a descriptive error message.
```

### 2. Provide Context Up Front

```
# Bad ❌
> Add tests

# Good ✅
> Add unit tests for the authentication middleware in @src/middleware/auth.js.
> Use Jest. Test both valid and expired JWT tokens.
```

### 3. Break Large Tasks Into Steps

```
# Bad ❌
> Refactor the entire application to use TypeScript

# Good ✅
> Let's migrate to TypeScript in phases:
> 1. First, add tsconfig.json and install dependencies
> 2. Then convert src/utils/ files one at a time
> Start with step 1.
```

### 4. Use `/plan` for Complex Work

The `/plan` command tells Copilot to create a structured implementation plan before writing code:

```
/plan
> Add user authentication with JWT tokens, bcrypt password hashing,
> login/logout endpoints, and middleware for protected routes
```

Copilot will outline the plan, then implement it step by step.

### 5. Use `/research` for Investigation

The `/research` command launches a deep research investigation:

```
/research
> What are the best practices for rate limiting in Express.js?
> Compare express-rate-limit vs custom middleware approaches.
```

### 6. Use `/review` for Code Quality

```
/review
```

Runs a code review agent to analyze changes in the current directory.

### 7. Use `/diff` to See Changes

```
/diff
```

Shows all changes Copilot has made in the current session — great for reviewing before committing.

---

## Advanced Features

### Fleet Mode — Parallel Subagents

`/fleet` enables parallel subagent execution. Copilot can spin up multiple subagents to work on independent tasks simultaneously:

```
/fleet
> Create unit tests for all files in src/utils/
```

Copilot may create separate subagents for each file, running in parallel.

Use `/tasks` to view and manage running background tasks.

### Delegate to Cloud Agent

`/delegate` sends your current session to GitHub's cloud agent, which will create a PR:

```
/delegate
```

This is useful when:
- The task is well-defined and you don't need to supervise
- You want to continue other work while Copilot finishes
- You want a PR-based review workflow

### Model Selection

Use `/model` to switch between available AI models:

```
/model
```

Different models have different strengths:
- **Claude Sonnet** — great all-rounder for coding tasks
- **GPT-5** — strong at reasoning and planning
- Choose based on the task at hand

### IDE Integration

Use `/ide` to connect Copilot CLI to a VS Code workspace:

```
/ide
```

This gives the CLI access to VS Code's language intelligence (diagnostics, go-to-definition, etc.).

---

## Best Practices Summary

### Context Management

| Practice | Why |
|---|---|
| **One task per session** | Keeps context focused and relevant |
| **Use `/compact` every 10-15 turns** | Prevents context overflow |
| **Reference files with `@`** | More efficient than letting Copilot search |
| **Check `/context` regularly** | Know how much space you have left |
| **Start fresh when switching tasks** | Don't carry stale context |

### Prompting

| Practice | Why |
|---|---|
| **Be specific** | Reduces back-and-forth and exploration |
| **Provide relevant files** | Copilot works better with explicit context |
| **Break large tasks into steps** | Better results, easier to review |
| **Use `/plan` for complex work** | Structured approach produces better code |
| **Use `/research` before implementing** | Informed decisions lead to better architecture |

### Session Hygiene

| Practice | Why |
|---|---|
| **Name sessions with `/rename`** | Easy to find and resume later |
| **Use `/diff` before committing** | Verify changes before they're permanent |
| **Use `/undo` when something goes wrong** | Revert mistakes without manual cleanup |
| **Share sessions with `/share`** | Create records of decisions and approaches |
| **Don't mix unrelated tasks** | Confuses context and produces worse results |

### Security

| Practice | Why |
|---|---|
| **Don't paste secrets into prompts** | They become part of the session |
| **Review `/diff` before committing** | Catch any generated credentials or sensitive data |
| **Use `.gitignore` properly** | Prevent Copilot from reading sensitive files |
| **Be cautious with `/allow-all`** | Only enable when you trust all tools and paths |

---

## Further Reading

- [GitHub Copilot CLI Documentation](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-copilot-cli)
- [About Copilot CLI](https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli)
- [About Premium Requests](https://docs.github.com/en/copilot/managing-copilot/monitoring-usage-and-entitlements/about-premium-requests)
- [Customizing Copilot Responses](https://docs.github.com/en/copilot/concepts/prompting/response-customization)
