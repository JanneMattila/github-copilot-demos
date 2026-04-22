# Exercises — 06 MCP Servers

Source doc: [../06_MCP.md](../06_MCP.md)

## Learning objectives

- Explain what MCP is and how Copilot uses it.
- Configure both a local (stdio) and a remote (HTTP/SSE) MCP server.
- Inspect, add, and remove servers from inside Copilot CLI.
- Apply the precedence rules and security considerations correctly.
- Drive a real browser via the Playwright MCP server.

---

## Part A — Comprehension

### A1. What does MCP stand for, and what is it for?

<details>
<summary>Show answer</summary>

**Model Context Protocol** — an open standard (created by Anthropic) for how
AI agents talk to external tool servers. An MCP server exposes *tools* the
agent can call.
</details>

### A2. Which MCP server is built into Copilot CLI by default?

<details>
<summary>Show answer</summary>

The **GitHub MCP server** — it provides tools for issues, PRs, search,
commits, file contents, etc., with no setup required.
</details>

### A3. Name the six common configuration locations for MCP servers, in roughly increasing precedence.

<details>
<summary>Show answer</summary>

1. `~/.copilot/mcp-config.json` (personal)
2. Plugin MCP configs
3. `.mcp.json` (project root)
4. `.github/mcp.json` (project alt)
5. Agent-specific `mcp-servers` in `.agent.md` frontmatter
6. `--additional-mcp-config` CLI flag (highest)

When the same server name is defined in multiple places, **last wins** (the
opposite of agents/skills).
</details>

### A4. Why is "MCP precedence is last-wins" the opposite of agents/skills?

<details>
<summary>Show answer</summary>

For agents/skills you usually want your *local* definition to win so that
your project's specific persona/skill overrides anything inherited globally
(first-wins).

For MCP servers, project-level configuration should override personal
defaults — e.g. a repo that needs a specific database server should beat
your global SQLite config.
</details>

### A5. Spot two security mistakes in this snippet:

```json
{
  "mcpServers": {
    "secret-api": {
      "command": "npx",
      "args": ["-y", "some-random-mcp"],
      "env": { "API_KEY": "sk-live-9f8a7b2c..." },
      "tools": ["*"]
    }
  }
}
```

<details>
<summary>Show answer</summary>

1. The API key is hardcoded — should be `"${SECRET_API_KEY}"` so it comes
   from an environment variable (and never gets committed).
2. `tools: ["*"]` exposes every tool the server provides; better to list
   only the ones you actually need (least privilege).

Bonus: "some-random-mcp" hasn't been vetted — review third-party servers
before installing.
</details>

---

## Part B — Hands-on tasks

### B1. List what's loaded right now

**Goal:** see the built-in GitHub MCP server in action.

Steps:

1. Run `copilot`, then `/mcp` — note configured servers and their status.
2. Run `/env` — look at the wider environment dump and find the GitHub
   MCP tools.
3. Ask Copilot something that obviously uses a GitHub tool, e.g.
   *"List the last 5 commits on the default branch of this repo using a
   GitHub MCP tool, not the local git client."*

<details>
<summary>Hint</summary>

`/mcp` is interactive — arrow keys to navigate, Enter to act on a server.
</details>

### B2. Add a local MCP server via `.mcp.json`

**Goal:** add the official filesystem MCP server, scoped to one specific
directory.

Steps:

1. Create `.mcp.json` in this repo (or a scratch repo):
   ```json
   {
     "mcpServers": {
       "fs-readonly": {
         "command": "npx",
         "args": [
           "-y",
           "@modelcontextprotocol/server-filesystem",
           "C:\\temp\\mcp-sandbox"
         ]
       }
     }
   }
   ```
2. Make sure `C:\temp\mcp-sandbox` exists and contains a couple of test files.
3. Restart Copilot CLI, run `/mcp` — confirm `fs-readonly` is connected.
4. Ask: *"Use the fs-readonly MCP server to list the files in the sandbox
   and show me the first 10 lines of any `.txt` file."*

<details>
<summary>Hint</summary>

On Windows, double-escape backslashes in JSON (`\\`) or use forward slashes.
If `/mcp` shows "failed to start", run the same `npx` command manually to
see the real error.
</details>

### B3. Add the Playwright MCP server and smoke-test a web page

**Goal:** drive a real browser through Copilot.

Steps:

1. Add to `.mcp.json` (or use `/mcp add`):
   ```json
   {
     "mcpServers": {
       "playwright": {
         "command": "npx",
         "args": ["@playwright/mcp@latest", "--headless"]
       }
     }
   }
   ```
2. Restart Copilot CLI, `/mcp` — confirm `playwright` is up.
3. Start the demo server: `node server.js` in another terminal.
4. Ask Copilot:
   > Use the Playwright MCP server to navigate to http://localhost:3000,
   > take a snapshot, and tell me what text appears on the page. Also report
   > any console errors.

<details>
<summary>Hint</summary>

If browsers haven't been installed before, `@playwright/mcp` will download
them on first run (this can take a minute). Use `--headless` to avoid a
browser window popping up.
</details>

### B4. Scope an MCP server to a single agent

**Goal:** make a server available *only* when a specific agent is selected.

Success criteria:

- New file `.github/agents/qa-tester.agent.md`.
- Frontmatter declares the Playwright server inline, plus restricts the
  agent's `tools` to Playwright + read.
- The Playwright server does NOT show up in `/mcp` until that agent is
  selected with `/agent`.

<details>
<summary>Solution</summary>

```markdown
---
name: qa-tester
description: QA agent that uses a real browser (Playwright) to test web apps. Use when the user asks for end-to-end / browser-driven testing.
tools: ["playwright/*", "read"]
mcp-servers:
  playwright:
    command: npx
    args: ["@playwright/mcp@latest", "--headless"]
---

You are a QA testing specialist. Use the Playwright tools to:

1. Navigate to the URL the user gives you.
2. Take an accessibility snapshot to understand the page structure.
3. Exercise the user-facing flows the user describes.
4. Report findings (including console messages and network failures) in a
   bulleted list.
```

After saving, remove `playwright` from any global `.mcp.json` so you can
verify the agent-scoped one only loads on selection.
</details>

### B5. Apply precedence

**Goal:** prove "last wins" for MCP.

Steps:

1. Define a server named `demo` in `~/.copilot/mcp-config.json` pointing at
   one command.
2. Define a server named `demo` in this repo's `.mcp.json` pointing at a
   *different* command.
3. Run `/mcp` and `/env` from this repo and confirm the project-level
   definition wins.
4. Now launch with `--additional-mcp-config ./override.json` defining `demo`
   yet again — verify the CLI flag wins.

<details>
<summary>Hint</summary>

The simplest "different command" is just a different `args` array (e.g. one
points at directory `A`, the other at `B`). Use `/env` to see which command
line is actually being used.
</details>

---

## Stretch goal

Pick a small internal API or database you're allowed to play with and either:

1. Find an existing MCP server for it (start from
   <https://github.com/modelcontextprotocol/servers>), wire it up via
   environment-variable secrets, restrict its `tools` array, and use it from
   a custom `data-analyst` agent.
2. Or write a tiny custom MCP server (Node or Python) that exposes one or two
   tools specific to your workflow, and add it to `.mcp.json`.

Either way, document in your repo's `README.md` what the server does and how
to set up the secrets.
