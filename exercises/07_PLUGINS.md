# Exercises — 07 Plugins

Source doc: [../07_PLUGINS.md](../07_PLUGINS.md)

## Learning objectives

- Explain what a plugin bundles and how it differs from individual agents,
  skills, hooks or MCP configs.
- Install plugins from a marketplace, GitHub repo, URL or local path.
- Author a minimal plugin with a `plugin.json` manifest.
- Understand precedence and where installed plugins live on disk.

---

## Part A — Comprehension

### A1. What can a plugin contain?

<details>
<summary>Show answer</summary>

Any combination of:

- Custom agents (`*.agent.md`)
- Skills (`SKILL.md` directories)
- Hooks (`hooks.json`)
- MCP server definitions (`.mcp.json`)
- Commands and LSP servers

…plus a `plugin.json` manifest that describes the plugin and points at the
component folders.
</details>

### A2. List four distinct ways to install a plugin.

<details>
<summary>Show answer</summary>

Any four of:

1. From a marketplace: `copilot plugin install my-plugin@my-marketplace`
2. From a GitHub repo: `copilot plugin install owner/repo`
3. From a subdirectory: `copilot plugin install owner/repo:path/to/plugin`
4. Pinned to a tag/branch: `copilot plugin install owner/repo@v2.0.0`
5. From a Git URL: `copilot plugin install https://github.com/owner/repo.git`
6. From a local path: `copilot plugin install ./my-local-plugin`
7. Interactively via `/plugin` inside Copilot CLI.
</details>

### A3. Which is the only required field in `plugin.json`?

<details>
<summary>Show answer</summary>

`name` — kebab-case, ≤ 64 chars. Everything else is optional metadata or
component paths (which default to `agents/`, `skills/`, etc.).
</details>

### A4. Precedence: a plugin ships an agent named `roast-agent`, and your repo also has a `.github/agents/roast-agent.agent.md`. Which wins?

<details>
<summary>Show answer</summary>

For agents and skills, **first found wins** — and project-level definitions
load before plugin-provided ones. So your repo's `roast-agent` overrides the
plugin's. (For MCP servers it's the opposite — last wins.)
</details>

### A5. Where do installed plugins live on disk?

<details>
<summary>Show answer</summary>

- Marketplace installs: `~/.copilot/installed-plugins/MARKETPLACE/PLUGIN/`
- Direct installs (URL/local/etc.): `~/.copilot/installed-plugins/_direct/SOURCE-ID/`
</details>

---

## Part B — Hands-on tasks

### B1. Browse the default marketplace

**Goal:** find one plugin you might actually use.

Steps:

1. Run `/plugin` in Copilot CLI.
2. Browse the Awesome GitHub Copilot marketplace (default).
3. Pick one plugin, read its description, and *don't* install it yet — just
   note what it bundles (agents? skills? MCP servers?).

<details>
<summary>Hint</summary>

Marketplace browsing is also available from the shell:

```bash
copilot plugin marketplace list
copilot plugin marketplace browse <name>
```
</details>

### B2. Install, list, uninstall

**Goal:** practice the full lifecycle on a low-risk plugin.

Steps:

1. Pick a small, read-only plugin (or use a local one — see B3 for a
   ready-made one).
2. `copilot plugin install <spec>`
3. `copilot plugin list` — confirm it's there.
4. `/env` inside Copilot CLI — see what new agents/skills/MCP servers it
   contributed.
5. `copilot plugin uninstall <name>`.
6. `copilot plugin list` again — confirm it's gone.

<details>
<summary>Hint</summary>

If you don't want to install anything from the internet, build the local
plugin from B3 first and install that with `copilot plugin install ./hello-plugin`.
</details>

### B3. Build a minimal local plugin

**Goal:** scaffold the smallest possible plugin and install it from a local
path.

Success criteria:

- Folder `hello-plugin/` (anywhere outside this repo's `.github/`).
- `hello-plugin/plugin.json` with `name`, `description`, `version`, `author`,
  `license`, and pointers to `agents/` and `skills/`.
- One trivial agent in `hello-plugin/agents/greeter.agent.md`.
- One trivial skill in `hello-plugin/skills/greet/SKILL.md`.
- `copilot plugin install ./hello-plugin` succeeds; `/env` shows the new
  agent and skill; `/agent` lists `greeter`.

<details>
<summary>Solution</summary>

`hello-plugin/plugin.json`:

```json
{
  "name": "hello-plugin",
  "description": "Tiny demo plugin: a greeter agent and a greet skill.",
  "version": "0.1.0",
  "author": { "name": "You" },
  "license": "MIT",
  "keywords": ["demo", "hello"],
  "agents": "agents/",
  "skills": "skills/"
}
```

`hello-plugin/agents/greeter.agent.md`:

```markdown
---
name: greeter
description: A friendly agent that opens with a personalised greeting before answering anything.
tools: ["read", "search"]
---

You are a warm, friendly assistant. Always start your first reply in a
session with: "Hi there 👋 — happy to help!" Then answer the user's question
normally. Keep the greeting to one line; do not repeat it on follow-up turns.
```

`hello-plugin/skills/greet/SKILL.md`:

```markdown
---
name: greet
description: Produces a personalised greeting given a name. Use when the user explicitly asks to "greet" someone.
---

When the user asks to greet `<name>`, reply with exactly:

```
Hello, <name>! 🎉
```

Do nothing else.
```

Install it:

```bash
copilot plugin install ./hello-plugin
copilot plugin list
```

Then in Copilot CLI run `/agent` (you should see `greeter`) and ask
"please greet Alice".
</details>

### B4. Scaffold a marketplace (read-only)

**Goal:** create a `marketplace.json` that *would* host your plugin from B3.

Success criteria:

- Folder `my-marketplace/.github/plugin/marketplace.json` exists.
- Contains a `plugins` array listing `hello-plugin` with a `source` path.
- (Optional) `copilot plugin marketplace add ./my-marketplace` works locally.

<details>
<summary>Solution</summary>

`my-marketplace/.github/plugin/marketplace.json`:

```json
{
  "name": "my-marketplace",
  "owner": { "name": "You" },
  "metadata": {
    "description": "My personal demo marketplace.",
    "version": "0.1.0"
  },
  "plugins": [
    {
      "name": "hello-plugin",
      "description": "Tiny demo greeter plugin.",
      "version": "0.1.0",
      "source": "plugins/hello-plugin"
    }
  ]
}
```

Move (or copy) `hello-plugin/` into `my-marketplace/plugins/hello-plugin/`,
then:

```bash
copilot plugin marketplace add ./my-marketplace
copilot plugin marketplace browse my-marketplace
copilot plugin install hello-plugin@my-marketplace
```
</details>

### B5. Demonstrate precedence

**Goal:** confirm "first found wins" for agents.

Steps:

1. Have your `hello-plugin` installed (B3) so the `greeter` agent is
   available.
2. Add a `.github/agents/greeter.agent.md` in this repo with a *different*
   personality (e.g., grumpy instead of friendly).
3. Run `/agent` from this repo, select `greeter`, ask anything.
4. Verify the *project* version wins.
5. Now `cd` to a folder *outside* this repo and try again — the *plugin*
   version should be active.

<details>
<summary>Hint</summary>

If both seem to load at the same time, double-check the names are
identical and that the project file ends in exactly `.agent.md`.
</details>

---

## Part C — In VS Code

> ⚠️ Plugins are a **CLI-only** distribution mechanism. VS Code's GitHub Copilot Chat extension does not install or manage Copilot plugins. This part teaches you the *equivalent VS Code workflow*.

### C1. Comprehension — How would you ship the same agent + skill + MCP combo to a VS Code teammate?

<details>
<summary>Show answer</summary>

There's no single installable artifact. You assemble it from the pieces VS Code already understands:

- **Agents → custom chat modes:** put `*.chatmode.md` files in `.github/chatmodes/` of the shared repo (or in the user's profile `prompts/` for personal-only).
- **Skills:** keep them in `.github/skills/` as usual — VS Code Agent mode loads them.
- **MCP servers:** put a `.vscode/mcp.json` in the shared repo (or, for personal, use **Settings sync** to share `mcp.servers` in user settings).
- **Instructions:** `.github/copilot-instructions.md` and `.github/instructions/*.instructions.md` work as-is.

Anyone who clones the repo and opens it in VS Code with the GitHub Copilot Chat extension gets all four — no install step.
</details>

### C2. Hands-on — Replicate `hello-plugin` (B3) for VS Code

**Goal:** take the `hello-plugin` you built in Part B3 and reproduce its *capabilities* in a single repo that a VS Code user can clone.

Success criteria:

- A scratch repo with:
  - `.github/chatmodes/greeter.chatmode.md` — the VS Code analogue of the `greeter` agent.
  - `.github/skills/greet/SKILL.md` — same as the plugin's skill.
  - `.github/copilot-instructions.md` — at least one short rule.
  - (Optional) `.vscode/mcp.json` if you want to bundle a server.
- A teammate cloning the repo and opening it in VS Code can:
  - Pick `greeter` from the chat mode dropdown.
  - Trigger the `greet` skill with a relevant prompt in Agent mode.

<details>
<summary>Solution</summary>

`.github/chatmodes/greeter.chatmode.md`:

```markdown
---
description: A friendly chat mode that opens with a personalised greeting before answering anything.
tools: ["codebase", "search"]
---

You are a warm, friendly assistant. Always start your first reply in a chat
with: "Hi there 👋 — happy to help!" Then answer the user's question normally.
Keep the greeting to one line; do not repeat it on follow-up turns.
```

`.github/skills/greet/SKILL.md`:

```markdown
---
name: greet
description: Produces a personalised greeting given a name. Use when the user explicitly asks to "greet" someone.
---

When the user asks to greet `<name>`, reply with exactly:

```
Hello, <name>! 🎉
```

Do nothing else.
```

Add a `README.md` explaining how to use it. The result: a *repo-shaped plugin* — no `plugin.json`, no `copilot plugin install`, just `git clone` and `code .`.
</details>

---

## Stretch goal

Take one of your favourite combinations of agent + skill + hooks from
earlier exercises (e.g. the `commit-msg` agent + a `time` skill + a
`postToolUse` audit hook) and bundle them into a single installable plugin.
Push it to a personal GitHub repo, install it on a fresh machine with
`copilot plugin install your-name/your-plugin`, and verify everything works
end to end.

Bonus: pin a version (`@v0.1.0`) and try a `copilot plugin update` after
publishing `v0.2.0`.
