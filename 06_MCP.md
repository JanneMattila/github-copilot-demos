# MCP Servers (Model Context Protocol)

MCP servers extend what GitHub Copilot can do by connecting it to **external tools and data sources**. Think of MCP as a plugin system for AI tools — it's a standard protocol that lets any MCP-compatible server provide new capabilities to Copilot.

This guide covers:

1. [What Is MCP?](#what-is-mcp)
2. [How MCP Works with Copilot](#how-mcp-works-with-copilot)
3. [Configuration Locations](#configuration-locations)
4. [Configuring MCP Servers](#configuring-mcp-servers)
5. [Managing MCP Servers in Copilot CLI](#managing-mcp-servers-in-copilot-cli)
6. [Common MCP Server Examples](#common-mcp-server-examples)
7. [MCP in Custom Agents](#mcp-in-custom-agents)
8. [Precedence & Loading Order](#precedence--loading-order)
9. [Security Considerations](#security-considerations)
10. [Tips & Best Practices](#tips--best-practices)
11. [Further Reading](#further-reading)

---

## What Is MCP?

The **Model Context Protocol (MCP)** is an open standard that defines how AI agents communicate with external tool servers. It was created by Anthropic and has been widely adopted across the AI ecosystem.

An MCP server is a process (local or remote) that exposes **tools** — functions that the AI agent can call. For example:

- A database MCP server might expose `query`, `insert`, and `schema` tools
- A GitHub MCP server might expose `list_issues`, `create_pr`, and `search_code` tools
- A Slack MCP server might expose `send_message` and `list_channels` tools

**Copilot CLI ships with the GitHub MCP server built in**, giving it native access to your repos, issues, PRs, and more. You can add additional MCP servers to extend its capabilities.

---

## How MCP Works with Copilot

```
┌──────────────┐         ┌──────────────────┐
│  Copilot CLI │ ──MCP──▶│  MCP Server      │
│  (AI Agent)  │◀──────  │  (Tool Provider) │
└──────────────┘         └──────────────────┘
        │                         │
        │  "Call the query tool"  │
        │ ──────────────────────▶ │
        │                         │  Executes query
        │  Returns results        │
        │ ◀────────────────────── │
        │                         │
        │  Uses results in        │
        │  response to user       │
```

1. You configure MCP servers in a JSON config file
2. Copilot CLI starts the MCP server process (or connects to a remote one)
3. The server advertises its available tools
4. When relevant, Copilot calls these tools to accomplish tasks
5. Tool results are fed back into the conversation context

---

## Configuration Locations

| Scope | File | Description |
|---|---|---|
| **Project** | `.mcp.json` (repo root) | MCP servers for this repo only |
| **Project** (alt) | `.github/mcp.json` | Alternative project location |
| **Personal** | `~/.copilot/mcp-config.json` | Your global MCP servers |
| **Agent-specific** | Inside `.agent.md` frontmatter | MCP servers for one agent only |
| **Plugin** | Referenced in `plugin.json` | MCP servers bundled with a plugin |
| **CLI flag** | `--additional-mcp-config` | Override at launch time |

---

## Configuring MCP Servers

### Basic Configuration File (`.mcp.json`)

Create a `.mcp.json` file in your project root:

```json
{
  "mcpServers": {
    "my-server": {
      "command": "npx",
      "args": ["-y", "@example/mcp-server"],
      "env": {
        "API_KEY": "${MY_API_KEY}"
      }
    }
  }
}
```

### Configuration Fields

| Field | Type | Description |
|---|---|---|
| `command` | string | Command to run the server (for local/stdio servers) |
| `args` | string[] | Arguments passed to the command |
| `cwd` | string | Working directory for the server process |
| `env` | object | Environment variables (supports `${VAR}` expansion) |
| `url` | string | URL for HTTP/SSE remote servers |
| `headers` | object | HTTP headers for remote servers (e.g., auth tokens) |
| `tools` | string[] | Which tools to expose (`["*"]` for all) |
| `timeout` | number | Connection timeout in milliseconds |

### Server Types

**Local (stdio)** — runs as a subprocess:

```json
{
  "mcpServers": {
    "sqlite": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sqlite", "./mydb.db"]
    }
  }
}
```

**Remote (HTTP/SSE)** — connects to a URL:

```json
{
  "mcpServers": {
    "remote-api": {
      "url": "https://mcp.example.com/sse",
      "headers": {
        "Authorization": "Bearer ${API_TOKEN}"
      }
    }
  }
}
```

---

## Managing MCP Servers in Copilot CLI

### Interactive Management

Use the `/mcp` command in Copilot CLI:

```
/mcp
```

This lets you:
- View configured MCP servers and their status
- Add new MCP servers
- Remove servers
- Test connectivity

### Adding via CLI

```
/mcp add
```

Follow the interactive prompts to configure a new server.

### Verifying Configuration

Use `/env` to see all loaded MCP servers:

```
/env
```

This shows which servers are active, their tools, and the config source.

---

## Common MCP Server Examples

### GitHub MCP Server (built-in)

Copilot CLI ships with the GitHub MCP server by default. It provides tools like:
- `list_issues`, `create_issue`, `search_issues`
- `list_pull_requests`, `create_pull_request`, `get_pull_request_diff`
- `search_code`, `get_file_contents`
- `list_commits`, `get_commit`

No configuration needed — it's always available.

### Filesystem Server

Access files outside the working directory:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/allowed/dir"]
    }
  }
}
```

### Database Server (SQLite)

```json
{
  "mcpServers": {
    "sqlite": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sqlite", "./database.db"]
    }
  }
}
```

### Web Fetch / Brave Search

```json
{
  "mcpServers": {
    "brave-search": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "${BRAVE_API_KEY}"
      }
    }
  }
}
```

### Playwright MCP Server (Browser Automation & Testing)

The [Playwright MCP server](https://github.com/microsoft/playwright-mcp) (`@playwright/mcp`) gives Copilot the ability to **control a real web browser** — navigate pages, click elements, fill forms, take screenshots, and read page content. It uses Playwright's accessibility tree (not screenshots), making it fast, deterministic, and LLM-friendly.

#### Configuration

Add to your `.mcp.json` or `~/.copilot/mcp-config.json`:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

Or add it interactively in Copilot CLI:

```
/mcp add
```

#### Useful Options

Pass options as additional args:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": [
        "@playwright/mcp@latest",
        "--browser", "chrome",
        "--headless"
      ]
    }
  }
}
```

| Option | Description |
|---|---|
| `--browser` | Browser to use: `chrome`, `firefox`, `webkit`, `msedge` |
| `--headless` | Run headless (no visible window) — great for CI |
| `--device` | Emulate a device, e.g., `"iPhone 15"` |
| `--port` | Run as SSE server on a port (for remote use) |
| `--caps vision` | Enable screenshot/vision capabilities |
| `--isolated` | Keep browser profile in memory only |
| `--ignore-https-errors` | Useful for testing against self-signed certs |
| `--storage-state` | Load saved auth state (cookies, localStorage) |

#### Tools Provided by Playwright MCP

Once configured, Copilot gets access to browser automation tools:

| Tool | Description |
|---|---|
| `browser_navigate` | Navigate to a URL |
| `browser_snapshot` | Get accessibility snapshot of the page (structured) |
| `browser_click` | Click an element by reference |
| `browser_type` | Type text into an input field |
| `browser_fill_form` | Fill multiple form fields at once |
| `browser_select_option` | Select dropdown options |
| `browser_take_screenshot` | Capture a screenshot |
| `browser_press_key` | Press keyboard keys |
| `browser_hover` | Hover over an element |
| `browser_evaluate` | Run JavaScript on the page |
| `browser_wait_for` | Wait for text, element, or timeout |
| `browser_tabs` | Manage browser tabs |
| `browser_network_requests` | Inspect network traffic |
| `browser_console_messages` | Read browser console output |

#### Using Playwright MCP for Testing Web Apps

This is where Playwright MCP really shines. You can ask Copilot to **test your web application interactively** — like having a QA tester who can also write code.

##### Example 1: Smoke Test Your App

Start your server, then ask Copilot:

```
Start a browser, navigate to http://localhost:3000, and verify
the page shows "Hello, World!". Check there are no console errors.
```

Copilot will:
1. Use `browser_navigate` to open your app
2. Use `browser_snapshot` to read the page content
3. Use `browser_console_messages` to check for errors
4. Report the results

##### Example 2: Test a Login Flow

```
Test the login flow:
1. Navigate to http://localhost:3000/login
2. Fill in email "test@example.com" and password "secret123"
3. Click the "Sign In" button
4. Verify we're redirected to the dashboard
5. Check the page shows "Welcome, Test User"
```

Copilot uses `browser_fill_form`, `browser_click`, `browser_wait_for`, and `browser_snapshot` to execute each step.

##### Example 3: Responsive Design Testing

```
Test our homepage on iPhone 15:
1. Navigate to http://localhost:3000
2. Take a screenshot
3. Check that the navigation menu is a hamburger icon
4. Click the hamburger menu and verify the nav links appear
```

Use the `--device "iPhone 15"` option to emulate mobile viewport and user agent.

##### Example 4: Form Validation Testing

```
Test the signup form validation:
1. Go to /signup
2. Submit the form empty — verify error messages appear
3. Enter an invalid email — verify the email error
4. Fill everything correctly — verify successful submission
```

##### Example 5: API-Driven Testing with Network Inspection

```
Navigate to /dashboard and monitor network requests.
Verify that:
1. An API call is made to /api/user/profile
2. The response status is 200
3. The dashboard displays the user's name from the API response
```

Copilot uses `browser_network_requests` to inspect the traffic.

##### Example 6: End-to-End Test Generation

You can also ask Copilot to **write Playwright test files** based on what it discovers:

```
Navigate to our app at http://localhost:3000 and explore the main
user flows. Then write Playwright test files (using @playwright/test)
that cover:
1. Homepage loads correctly
2. Navigation works
3. Search functionality
Write the tests to tests/e2e/ directory.
```

Copilot will use the browser to explore your app, understand its structure via accessibility snapshots, and then generate proper Playwright test code.

#### Playwright MCP vs Playwright CLI + Skills

Microsoft also offers a [Playwright CLI with Skills](https://github.com/microsoft/playwright-cli) approach:

| | Playwright MCP | Playwright CLI + Skills |
|---|---|---|
| **Approach** | MCP tools, persistent browser session | CLI commands via skills |
| **Token efficiency** | Higher token usage (tool schemas + accessibility trees) | More token-efficient (concise CLI output) |
| **Best for** | Exploratory testing, long-running sessions, interactive debugging | High-throughput coding agents, large codebases |
| **Browser context** | Maintained across tool calls | Per-command |

**Recommendation:** Use MCP for interactive/exploratory testing and debugging. Use CLI + Skills for automated test generation in large projects.

#### Creating a Testing Agent with Playwright MCP

Combine a custom agent with the Playwright MCP server for a dedicated QA agent:

**`.github/agents/qa-tester.agent.md`:**

```markdown
---
name: qa-tester
description: QA testing agent that uses a real browser to test web applications
tools: ["playwright/*", "read", "edit", "shell"]
mcp-servers:
  playwright:
    command: npx
    args: ["@playwright/mcp@latest", "--headless"]
---

You are a QA testing specialist. You test web applications using a real browser.

## Your Workflow

1. Start the app if it's not running (check with a quick HTTP request first)
2. Navigate to the app in the browser
3. Systematically test all user-facing functionality
4. Check for console errors, broken links, and accessibility issues
5. Report findings with screenshots for any issues found
6. Write Playwright test files for the flows you tested

## Testing Priorities

1. Critical user paths (login, signup, main features)
2. Form validation and error handling
3. Responsive design (test at different viewports)
4. Console errors and network failures
5. Accessibility (check for proper ARIA labels, keyboard navigation)
```

Select this agent with `/agent` in Copilot CLI or from the VS Code agents dropdown.

### Custom Server (Your Own)

Write your own MCP server in any language:

```json
{
  "mcpServers": {
    "my-internal-tools": {
      "command": "node",
      "args": ["./tools/mcp-server.js"],
      "cwd": ".",
      "env": {
        "DATABASE_URL": "${DATABASE_URL}"
      }
    }
  }
}
```

---

## MCP in Custom Agents

You can attach MCP servers to specific custom agents via their `.agent.md` frontmatter:

```markdown
---
name: database-agent
description: Database specialist with direct SQL access
tools: ["sqlite/query", "sqlite/schema", "read", "edit"]
mcp-servers:
  sqlite:
    command: npx
    args: ["-y", "@modelcontextprotocol/server-sqlite", "./app.db"]
---

You are a database specialist...
```

This way, the MCP server only runs when this specific agent is selected.

---

## Precedence & Loading Order

When multiple configs define the same server name, **last wins**:

```
1. ~/.copilot/mcp-config.json        ← lowest priority
2. Plugin MCP configs                ← mid priority
3. .mcp.json / .github/mcp.json     ← project level
4. Agent-specific mcp-servers        ← agent level
5. --additional-mcp-config flag      ← highest priority (override)
```

This is the **opposite** of agents/skills (which use first-wins). The rationale: project-level configs should override global defaults.

---

## Security Considerations

### ⚠️ Environment Variables for Secrets

**Never hardcode API keys or tokens in `.mcp.json`.**  Use environment variable references:

```json
{
  "env": {
    "API_KEY": "${MY_SECRET_KEY}"
  }
}
```

### ⚠️ Review Third-Party Servers

MCP servers can execute arbitrary code. Before adding a server:

- Review its source code
- Check its npm/GitHub reputation
- Understand what tools it exposes
- Consider the principle of least privilege

### ⚠️ Restrict Tool Access

Use the `tools` field to limit which tools a server exposes:

```json
{
  "mcpServers": {
    "database": {
      "command": "...",
      "tools": ["query", "schema"]
    }
  }
}
```

This is safer than `"tools": ["*"]`.

### ⚠️ `.mcp.json` Is Committed to Git

If your `.mcp.json` references secrets via environment variables, that's fine. But don't commit actual secret values. Consider adding a `.mcp.json.example` and `.gitignore`-ing the real one if it contains sensitive paths.

---

## Tips & Best Practices

1. **Start with the built-in GitHub MCP server** — it's already configured and covers most GitHub workflows
2. **Use `npx -y` for official servers** — no installation needed, always up-to-date
3. **Scope MCP servers to agents** when possible — don't load database tools for every task
4. **Test connectivity with `/mcp`** — verify servers are running before relying on them
5. **Use environment variables** — never hardcode secrets
6. **Check `/env`** — see what's actually loaded in your session
7. **Use `--additional-mcp-config`** for temporary overrides without modifying project config

---

## Further Reading

- [GitHub Docs: Adding MCP Servers](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-mcp-servers)
- [GitHub Docs: Extending Cloud Agent with MCP](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent/extend-cloud-agent-with-mcp)
- [MCP Specification](https://modelcontextprotocol.io/)
- [MCP Server Registry](https://github.com/modelcontextprotocol/servers)
- [Copilot CLI Configuration Directory](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-config-dir-reference)
