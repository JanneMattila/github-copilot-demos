# 01 — Models

> Choose the right AI model for the task at hand.

## Overview

GitHub Copilot CLI supports **multiple AI models** from different providers. By default, Copilot uses **Claude Sonnet 4.5**, but you can switch models at any time during a session.

## Switching Models

### Using the `/model` Slash Command

```
/model
```

This opens an interactive picker listing all models available to your account. Select one and all subsequent prompts in the session use that model.

### From the Command Line

```bash
copilot --model claude-sonnet-4
```

## Available Models

Models change over time as providers release new versions and GitHub negotiates access. As of early 2026, the lineup includes:

| Provider | Model | ID | Notes |
|----------|-------|----|-------|
| Anthropic | **Claude Sonnet 4.5** | `claude-sonnet-4.5` | Default model — great all-rounder |
| Anthropic | Claude Sonnet 4 | `claude-sonnet-4` | Slightly faster, still very capable |
| Anthropic | Claude Opus 4.6 | `claude-opus-4.6` | Premium — deepest reasoning |
| Anthropic | Claude Opus 4.5 | `claude-opus-4.5` | Premium — strong reasoning |
| Anthropic | Claude Haiku 4.5 | `claude-haiku-4.5` | Fast and cheap — good for simple tasks |
| OpenAI | GPT-5 | `gpt-5` | OpenAI's latest flagship |
| OpenAI | GPT-5 mini | `gpt-5-mini` | Smaller, faster GPT-5 variant |
| OpenAI | GPT-4.1 | `gpt-4.1` | Fast and affordable |
| Google | Gemini | various | Available in some plans |

> **Note:** Available models depend on your Copilot subscription tier (Individual, Business, Enterprise) and any organization-level restrictions. Run `/model` to see what's available to you.

## Premium Requests

Each prompt you send to Copilot CLI consumes **one premium request** from your monthly quota. Different models may consume different amounts:

- **Standard models** (Sonnet 4.5, GPT-4.1, Haiku) — 1× multiplier
- **Premium models** (Opus 4.6, GPT-5) — higher multiplier (check your plan details)

Monitor your usage:

```
/usage
```

See [About premium requests](https://docs.github.com/copilot/managing-copilot/monitoring-usage-and-entitlements/about-premium-requests) for details.

## Choosing the Right Model

### By Task Type

| Task | Recommended Model | Why |
|------|-------------------|-----|
| Quick file edits, renames, simple scripts | **Haiku 4.5** or **GPT-4.1** | Fast, cheap, good enough |
| General coding, refactoring, debugging | **Sonnet 4.5** (default) | Best balance of speed and quality |
| Complex architecture, multi-file changes | **Opus 4.6** or **GPT-5** | Deeper reasoning, better planning |
| Research and analysis | **Opus 4.6** | Strong at synthesizing large contexts |
| Code review | **Sonnet 4** or **Sonnet 4.5** | Good at spotting issues quickly |

### By Priority

| Priority | Model Choice |
|----------|-------------|
| 💰 Save quota | Haiku 4.5, GPT-4.1, GPT-5 mini |
| ⚡ Speed | Haiku 4.5, GPT-4.1 |
| 🎯 Quality | Opus 4.6, GPT-5 |
| ⚖️ Balance | Sonnet 4.5 (default) |

## Model Behavior Differences

Different models have different strengths. Here's what to expect:

### Anthropic Claude Models

- **Opus** — Excellent at long, multi-step reasoning. Best for complex refactors and architectural decisions. Takes longer but produces more thoughtful output.
- **Sonnet** — The workhorse. Fast enough for interactive use, smart enough for most tasks. Great at following instructions precisely.
- **Haiku** — Lightning fast. Use for simple lookups, file operations, and quick questions. May struggle with complex multi-step tasks.

### OpenAI GPT Models

- **GPT-5** — Strong at code generation and creative problem-solving. Good at understanding intent from vague prompts.
- **GPT-5 mini / GPT-4.1** — Budget-friendly options that handle straightforward tasks well.

## Sub-Agents and Models

When Copilot CLI delegates work to **sub-agents** (e.g., explore agents, task agents), those sub-agents may use different models than your main session:

- **Explore agents** — Typically use Haiku (fast, for code search)
- **Task agents** — Typically use Haiku (for running builds/tests)
- **General-purpose agents** — Use Sonnet (for complex sub-tasks)

You can override sub-agent models in the `task` tool using the `model` parameter when working with custom agents.

## Custom Agents and Model Preferences

When creating custom agents (`.github/agents/*.agent.md`), you cannot currently pin a specific model in the agent definition. The model used is always the one selected in the active session.

**Tip:** If an agent's task requires deep reasoning (e.g., a code review agent), suggest in the agent's instructions that the user switch to a premium model:

```markdown
> 💡 For best results, switch to Claude Opus 4.6 (`/model`) before using this agent.
```

## Model Selection in CI/CD and Automation

When using Copilot programmatically (e.g., in GitHub Actions via the coding agent), the model is configured at the organization or repository level through Copilot settings, not in the CLI.

## Tips

1. **Start with the default** — Sonnet 4.5 handles 90% of tasks well
2. **Upgrade for complexity** — Switch to Opus/GPT-5 when you hit a wall on complex reasoning
3. **Downgrade for speed** — Use Haiku for bulk operations or simple file searches
4. **Watch your quota** — Run `/usage` periodically, especially with premium models
5. **Experiment** — Different models sometimes give surprisingly different solutions to the same problem. If one model's answer isn't great, try another
6. **Match model to mode** — In autopilot mode, a smarter model reduces the chance of getting stuck in loops

## Switching Models in VS Code

In **VS Code (stable)** with the GitHub Copilot Chat extension, the model picker lives in the chat input bar:

1. Open the Chat view (`Ctrl+Alt+I` / `Cmd+Ctrl+I`).
2. Click the **model name** in the lower-right of the chat input box.
3. Pick from the list of models available to your account.

The same model IDs apply (`claude-sonnet-4.5`, `gpt-5`, etc.). Availability depends on your Copilot subscription and any organization policy.

### Per-mode model preferences

You can pick a different model for **Ask**, **Edit** and **Agent** modes. The picker remembers each one independently — handy if you want, say, Haiku for quick Asks and Opus for longer Agent runs.

### Verifying which model is in use

- Hover the chat input model picker — it shows the current selection.
- The chat header indicates the active model on the most recent assistant message.

## Quick Reference

| Surface | How to switch | How to check usage |
|---|---|---|
| **CLI** | `/model` (interactive) or `copilot --model <id>` at launch | `/usage` |
| **VS Code (Copilot Chat)** | Click the model name in the chat input bar | GitHub.com → Settings → Copilot → Usage |

```
/model                    # CLI: pick a model interactively
/usage                    # CLI: check premium request usage
copilot --model <id>      # CLI: start with a specific model
```
