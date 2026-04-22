# Copilot Agent Skills

**Skills** are markdown-driven instruction sets that extend what GitHub Copilot (CLI, VS Code agent mode, and the cloud coding agent) can do. They let you teach Copilot new tasks — from running scripts to calling APIs — without writing an MCP server.

## Table of Contents

- [What Are Skills?](#what-are-skills)
- [How Skills Work](#how-skills-work)
- [Skill File Format](#skill-file-format)
- [Where Skills Live](#where-skills-live)
- [Creating a Skill](#creating-a-skill)
- [Running Scripts from Skills](#running-scripts-from-skills)
- [Skills in This Repo](#skills-in-this-repo)
- [Skills vs Custom Instructions](#skills-vs-custom-instructions)
- [Further Reading](#further-reading)

---

## What Are Skills?

Skills are folders containing a `SKILL.md` file (and optionally scripts, templates, or other resources) that give Copilot explicit instructions for specialized tasks. They follow an [open standard](https://agentskills.io/home) adopted by multiple AI coding agents.

**Key properties:**

- **Declarative** — you write Markdown instructions, not code
- **Contextual** — Copilot loads a skill only when it's relevant to the current task
- **Portable** — the same skill works in Copilot CLI, VS Code agent mode, and the cloud coding agent
- **Composable** — skills can include scripts, reference other files, and chain with tools

## How Skills Work

1. You (or a third party) create a skill folder with a `SKILL.md` file
2. When you launch Copilot, it discovers skills in known locations
3. Based on your prompt and the skill's `description`, Copilot decides whether to load it
4. If loaded, the `SKILL.md` instructions are injected into the agent's context
5. Copilot follows the instructions — including running any referenced scripts

You can see loaded skills with the `/skills` command in Copilot CLI, or `/env` to see the full environment.

## Skill File Format

Every skill must contain a `SKILL.md` file (case-sensitive) with YAML frontmatter:

```markdown
---
name: my-skill-name
description: What this skill does and when Copilot should use it.
allowed-tools: shell
---

# Instructions for Copilot

Step-by-step instructions go here...
```

### Frontmatter Fields

| Field | Required | Description |
|---|---|---|
| `name` | ✅ | Unique ID — lowercase, hyphen-separated, usually matches the folder name |
| `description` | ✅ | Tells Copilot **what** the skill does and **when** to use it |
| `license` | ❌ | License info (recommended for shared skills) |
| `allowed-tools` | ❌ | Pre-approved tools (e.g., `shell`, `bash`) — use with caution |

> ⚠️ **Security note:** Only add `shell` or `bash` to `allowed-tools` if you fully trust the skill and its scripts. Without this field, Copilot will prompt for confirmation before running commands.

### Body Content

The Markdown body contains instructions for Copilot — step-by-step procedures, examples, guidelines, or anything else the agent needs to perform the task. You can reference scripts and files in the skill's directory.

## Where Skills Live

| Scope | Location | Description |
|---|---|---|
| **Project** | `.github/skills/` | Available only in this repository |
| **Project** (alt) | `.claude/skills/` or `.agents/skills/` | Alternative project locations (cross-agent compatible) |
| **Personal** | `~/.copilot/skills/` | Available in all your projects |
| **Personal** (alt) | `~/.claude/skills/` or `~/.agents/skills/` | Alternative personal locations |

### Directory Structure

```
.github/
└── skills/
    ├── hello/
    │   ├── SKILL.md         ← Required: instructions + metadata
    │   └── hello.sh         ← Optional: script referenced by instructions
    └── call-api/
        ├── SKILL.md
        └── call-api.sh
```

## Creating a Skill

### Step 1: Create the folder structure

```bash
mkdir -p .github/skills/my-skill
```

### Step 2: Write `SKILL.md`

```markdown
---
name: my-skill
description: Describe when Copilot should use this skill.
---

# My Skill Instructions

1. Do this first
2. Then do this
3. Finally, do this
```

### Step 3: (Optional) Add scripts

Place any scripts in the skill folder and reference them in the instructions:

```markdown
Run the `setup.sh` script from this skill's directory to configure the environment.
```

### Step 4: Verify

Launch Copilot CLI and run `/skills` to confirm your skill was discovered.

## Running Scripts from Skills

Skills can include executable scripts. Copilot discovers all files in the skill directory automatically. To use a script:

1. Add the script file to your skill's folder
2. Reference it in your `SKILL.md` instructions
3. Optionally add `allowed-tools: shell` to skip confirmation prompts

Example skill structure with a script:

```
.github/skills/deploy/
├── SKILL.md
└── deploy.sh
```

In `SKILL.md`:

```markdown
---
name: deploy
description: Deploy the application to staging. Use when asked to deploy.
allowed-tools: shell
---

To deploy, run the `deploy.sh` script from this skill's directory.
Pass the target environment as the first argument (e.g., `staging` or `production`).
```

## Skills in This Repo

This repository includes two example skills:

### 🟢 `hello`

**Location:** `.github/skills/hello/`

A minimal "Hello, World!" skill that runs a shell script to print a greeting. Great as a starting template for your own skills.

```bash
# Usage: just ask Copilot to "say hello" or "run the hello skill"
```

### 🔵 `call-api`

**Location:** `.github/skills/call-api/`

Posts a JSON payload to an echo API endpoint (`https://echo.jannemattila.com/api/echo`). Demonstrates how skills can interact with external APIs.

```bash
# Usage: ask Copilot to "call the echo API" or "post JSON to the API"
```

## Skills vs Custom Instructions

| | Skills | Custom Instructions |
|---|---|---|
| **Scope** | Loaded only when relevant | Always loaded |
| **Detail** | Detailed, task-specific procedures | General coding standards and preferences |
| **Location** | `.github/skills/` | `.github/copilot-instructions.md`, `COPILOT.md`, etc. |
| **Use case** | Specialized tasks (deploy, test, API calls) | Repo-wide conventions (style, naming, patterns) |

**Rule of thumb:** Use custom instructions for things that apply to every task. Use skills for things that only apply sometimes.

## Skills in VS Code

Skills work in **VS Code (stable)** GitHub Copilot Chat **Agent mode** as well as in Copilot CLI and the cloud agent. They are loaded from the same locations:

- Workspace: `.github/skills/`
- Personal: `~/.copilot/skills/` (also `~/.claude/skills/` etc.)

### Trying a skill in VS Code

1. Open the Chat view and switch to **Agent** mode.
2. Make sure the workspace contains the skill folder (e.g. `.github/skills/hello/`).
3. Send a prompt that matches the skill's `description` — for example *"say hello using the hello skill"*.
4. The agent loads the skill and follows its instructions, including running any referenced scripts (with confirmation, unless `allowed-tools: shell` is set).

### Verifying that skills are discovered

- Use the chat overflow (`…`) menu on a recent reply to see the "Used N skills" indicator.
- Run **Chat: Show Used Skills** from the Command Palette (where available) to list which skills were applied to the most recent turn.

### Caveats

- `allowed-tools: shell` carries the same security trade-off in VS Code as in the CLI — scripts will run without prompting. Only use it on skills you fully trust.
- Skills load on demand; a vague `description` will cause Chat to ignore them just like the CLI does.

### Quick mapping

| CLI | VS Code (Copilot Chat) |
|---|---|
| `/skills` to list available skills | "Chat: Show Used Skills" / overflow menu on a reply |
| Trigger by relevant prompt in any mode | Trigger by relevant prompt in **Agent** mode |

---

## Further Reading

- [GitHub Docs: Adding Agent Skills](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/add-skills)
- [VS Code Docs: Use chat in agent mode](https://code.visualstudio.com/docs/copilot/chat/chat-agent-mode)
- [About Agent Skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)
- [Agent Skills Standard](https://agentskills.io/home)
- [Awesome Copilot Skills](https://awesome-copilot.github.com/skills/)
- [Copilot CLI Documentation](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-copilot-cli)
