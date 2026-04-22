# Custom Agents for GitHub Copilot

Custom agents let you create **specialized AI personas** with tailored expertise, tools, and behavior. Instead of prompting Copilot from scratch every time, you define an agent profile once and select it whenever you need that expertise.

This guide covers:

1. [What Are Custom Agents?](#what-are-custom-agents)
2. [Where Agent Profiles Live](#where-agent-profiles-live)
3. [Agent Profile Format](#agent-profile-format)
4. [Configuring Tools & MCP Servers](#configuring-tools--mcp-servers)
5. [Creating an Agent Step-by-Step](#creating-an-agent-step-by-step)
6. [Example Agents in This Repo](#example-agents-in-this-repo)
7. [Agents vs Skills vs Instructions](#agents-vs-skills-vs-instructions)
8. [Tips & Best Practices](#tips--best-practices)
9. [Further Reading](#further-reading)

---

## What Are Custom Agents?

A custom agent is a Markdown file (`.agent.md`) that defines:

- **Who** the agent is — its name, persona, and expertise
- **What** it can do — which tools it has access to
- **How** it behaves — detailed instructions in the Markdown body

When you select an agent, its profile is loaded into Copilot's context. The agent then follows its instructions for the duration of the session.

**Where they work:**
- ✅ GitHub Copilot CLI (`/agent` command)
- ✅ VS Code / VS Code Insiders (agent mode in Copilot Chat)
- ✅ Copilot cloud agent (GitHub.com)
- ✅ JetBrains IDEs, Eclipse, Xcode (public preview)

---

## Where Agent Profiles Live

| Scope | Location | Available In |
|---|---|---|
| **Repository** | `.github/agents/` | This repo only |
| **Organization** | `agents/` (root of `.github` repo) | All repos in the org |
| **Personal** | `~/.copilot/agents/` | All your projects |
| **VS Code user** | User profile folder | All VS Code workspaces |

### File naming rules

- Filename must end with `.agent.md`
- Allowed characters: `a-z`, `A-Z`, `0-9`, `-`, `_`, `.`
- The filename (without `.agent.md`) becomes the default agent name
- Examples: `roast-agent.agent.md`, `emoji-agent.agent.md`, `test-specialist.agent.md`

### Directory structure

```
.github/
└── agents/
    ├── roast-agent.agent.md
    ├── emoji-agent.agent.md
    └── test-specialist.agent.md
```

---

## Agent Profile Format

Agent profiles are Markdown files with YAML frontmatter:

```markdown
---
name: my-agent
description: A brief description of what this agent does and its expertise.
tools: ["read", "edit", "search", "shell"]
---

# Agent Instructions

You are a [role]. Your responsibilities:

- Do this
- Do that
- Never do this other thing

## How to Work

Detailed behavioral instructions go here...
```

### Frontmatter Fields

| Field | Required | Description |
|---|---|---|
| `name` | ❌ | Display name. Defaults to filename if omitted |
| `description` | ✅ | What the agent does — helps Copilot and users understand when to use it |
| `tools` | ❌ | List of tools the agent can use. Omit to allow all tools |
| `mcp-servers` | ❌ | MCP server configurations specific to this agent |
| `model` | ❌ | AI model to use (VS Code / JetBrains only) |
| `target` | ❌ | Restrict to `vscode` or `github-copilot` only |

### The Markdown Body (Prompt)

The body is where you define the agent's behavior. This is injected as system context when the agent is selected. It can be up to **30,000 characters**.

Write it as if you're briefing a new team member:
- What is their role?
- What should they focus on?
- What should they avoid?
- What patterns or conventions should they follow?
- What tools should they use and how?

---

## Configuring Tools & MCP Servers

### Built-in Tools

You can restrict which tools an agent has access to:

```yaml
tools: ["read", "edit", "search"]
```

Common tool names:
- `read` — read files
- `edit` — edit files
- `search` — search codebase
- `shell` / `bash` — run terminal commands
- `fetch` — make HTTP requests

If you **omit** the `tools` field entirely, the agent gets access to **all** available tools.

### MCP Servers

You can attach MCP servers to give agents access to external tools:

```yaml
mcp-servers:
  my-server:
    command: npx
    args: ["-y", "my-mcp-server"]
```

Or reference MCP tools by server name:

```yaml
tools: ["my-mcp-server/specific-tool"]
```

---

## Creating an Agent Step-by-Step

### 1. Create the directory

```bash
mkdir -p .github/agents
```

### 2. Create the agent file

```bash
touch .github/agents/my-agent.agent.md
```

### 3. Write the profile

```markdown
---
name: my-agent
description: Describe what this agent specializes in.
---

You are a [role] who [does what]. Your responsibilities:

- ...
- ...
```

### 4. Commit and use

```bash
git add .github/agents/my-agent.agent.md
git commit -m "Add my-agent custom agent"
```

### 5. Select the agent

- **Copilot CLI:** Run `/agent` and select from the list
- **VS Code:** Open Copilot Chat → select from agents dropdown
- **GitHub.com:** Select from the agents tab dropdown

---

## Example Agents in This Repo

This repository includes two fun example agents to demonstrate the concept:

### 🔥 `roast-agent`

**Location:** `.github/agents/roast-agent.agent.md`

A brutally honest code reviewer that roasts your code and work with sarcastic humor. It still provides useful feedback — just with extra spice.

```
# In Copilot CLI
/agent
→ Select "roast-agent"
→ Ask it to review your code
```

### 😂 `emoji-agent`

**Location:** `.github/agents/emoji-agent.agent.md`

An agent that uses emojis way too much in every response. Every sentence gets multiple emojis. Every explanation is peppered with them. It's enthusiastic to a fault.

```
# In Copilot CLI
/agent
→ Select "emoji-agent"
→ Ask it anything
```

---

## Agents vs Skills vs Instructions

| | Custom Agents | Skills | Instructions |
|---|---|---|---|
| **What** | Full AI persona with role, tools, and behavior | Task-specific procedures with optional scripts | General coding guidelines |
| **When loaded** | When explicitly selected by the user | When Copilot decides it's relevant to the task | Always (or when path matches) |
| **File format** | `.agent.md` with frontmatter | `SKILL.md` with frontmatter | `.md` files in known locations |
| **Location** | `.github/agents/` | `.github/skills/` | `.github/copilot-instructions.md`, etc. |
| **Tool control** | Can restrict which tools are available | Can pre-approve tools | No tool control |
| **Use case** | Specialized roles (tester, reviewer, planner) | Specialized tasks (deploy, API calls) | Repo-wide conventions |

**Rule of thumb:**
- **Agents** = "who" — a persona with expertise and tool access
- **Skills** = "how" — procedures for specific tasks
- **Instructions** = "what" — coding standards and project context

They all complement each other. An agent can use skills, and instructions apply on top of everything.

---

## Tips & Best Practices

### ✅ Do

1. **Write clear descriptions** — the description helps both users and Copilot understand when to use the agent
2. **Be specific in the prompt** — vague instructions like "be helpful" waste context; say exactly what the agent should do
3. **Restrict tools when appropriate** — a documentation agent doesn't need `shell` access
4. **Include examples** — show the agent what good output looks like
5. **Set boundaries** — explicitly state what the agent should NOT do
6. **Keep prompts focused** — one agent, one role. Don't make a "does everything" agent
7. **Test your agent** — select it and try various prompts to make sure it behaves as expected
8. **Use personal agents for personal workflows** — put them in `~/.copilot/agents/` so they're available everywhere

### ❌ Don't

1. **Don't put secrets in agent profiles** — they're committed to git
2. **Don't make the prompt too long** — 30,000 chars is the max, but shorter is usually better
3. **Don't duplicate instructions** — if it belongs in `copilot-instructions.md`, put it there instead
4. **Don't grant unnecessary tool access** — principle of least privilege applies to AI agents too
5. **Don't create agents for one-off tasks** — use a regular prompt instead; agents are for recurring roles

---

## VS Code Equivalent — Custom Chat Modes

**VS Code (stable)** doesn't load `*.agent.md` files directly; instead it has **custom chat modes**, which serve the same purpose: a reusable persona with its own instructions, allowed tools and (optionally) preferred model.

### File location and naming

| Scope | Location | Filename |
|---|---|---|
| Workspace | `.github/chatmodes/` | `*.chatmode.md` |
| User profile | VS Code user data dir → `prompts/` | `*.chatmode.md` |

### File format

```markdown
---
description: A brief description of when to pick this mode.
tools: ["codebase", "search", "editFiles", "runCommands"]
model: claude-sonnet-4.5
---

You are a [role]. Your responsibilities…
```

### Selecting a chat mode

1. Open the Chat view.
2. Click the mode dropdown next to the chat input.
3. The list shows built-in modes (Ask / Edit / Agent) **and** your custom modes from `.github/chatmodes/` and your user profile.

### Cross-targeting agents and chat modes

If you want one Markdown body to serve both surfaces:

- Use `.agent.md` for CLI/cloud agent and `.chatmode.md` for VS Code, sharing the body content via a templating step or a symlink.
- Use the `target:` frontmatter on `.agent.md` to restrict it to a single surface (`target: github-copilot` or `target: vscode`).

### When to choose which

| Need | Use |
|---|---|
| Persona used in CLI + cloud agent | `.agent.md` |
| Persona used in VS Code chat | `.chatmode.md` |
| Same persona on both surfaces | Both files (or a build step that produces both) |

### Quick mapping

| CLI | VS Code (Copilot Chat) |
|---|---|
| `/agent` to pick an agent | Chat input mode dropdown |
| `.github/agents/*.agent.md` | `.github/chatmodes/*.chatmode.md` |
| `~/.copilot/agents/*.agent.md` | User-profile `prompts/*.chatmode.md` |

---

## Further Reading

- [GitHub Docs: Creating Custom Agents](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/create-custom-agents)
- [VS Code Docs: Custom chat modes](https://code.visualstudio.com/docs/copilot/chat/chat-modes)
- [GitHub Docs: Custom Agents Configuration Reference](https://docs.github.com/en/copilot/reference/custom-agents-configuration)
- [GitHub Docs: About Custom Agents](https://docs.github.com/en/copilot/concepts/agents/cloud-agent/about-custom-agents)
- [GitHub Blog: How to Write a Great agents.md](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/)
- [Awesome Copilot Agents Collection](https://github.com/github/awesome-copilot/tree/main/agents)
- [Custom Agents in VS Code](https://code.visualstudio.com/docs/copilot/customization/custom-agents)
