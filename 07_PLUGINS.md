# Plugins for GitHub Copilot CLI

Plugins are **distributable packages** that bundle agents, skills, hooks, MCP servers, and commands into a single installable unit. They're how you share and consume reusable Copilot extensions.

This guide covers:

1. [What Are Plugins?](#what-are-plugins)
2. [Installing Plugins](#installing-plugins)
3. [Managing Plugins](#managing-plugins)
4. [Plugin Marketplaces](#plugin-marketplaces)
5. [Creating Your Own Plugin](#creating-your-own-plugin)
6. [The `plugin.json` Manifest](#the-pluginjson-manifest)
7. [Creating a Marketplace](#creating-a-marketplace)
8. [Loading Order & Precedence](#loading-order--precedence)
9. [File Locations](#file-locations)
10. [Tips & Best Practices](#tips--best-practices)
11. [Further Reading](#further-reading)

---

## What Are Plugins?

A plugin is a directory containing a `plugin.json` manifest and one or more components:

```
my-plugin/
├── plugin.json           ← Manifest (required)
├── agents/               ← Custom agent profiles (.agent.md)
├── skills/               ← Skills (SKILL.md + scripts)
├── hooks.json            ← Hook configurations
└── .mcp.json             ← MCP server definitions
```

**Think of plugins as the distribution mechanism:**
- **Agents** = who (personas)
- **Skills** = how (procedures)
- **Hooks** = when (lifecycle events)
- **MCP Servers** = what (external tools)
- **Plugins** = all of the above, packaged together

---

## Installing Plugins

### From a Marketplace

```bash
copilot plugin install my-plugin@my-marketplace
```

### From a GitHub Repository

```bash
# Root of a repo
copilot plugin install owner/repo

# Subdirectory in a repo
copilot plugin install owner/repo:path/to/plugin

# Specific branch or tag
copilot plugin install owner/repo@v2.0.0
```

### From a Git URL

```bash
copilot plugin install https://github.com/owner/repo.git
```

### From a Local Path

```bash
copilot plugin install ./my-local-plugin
copilot plugin install /absolute/path/to/plugin
```

### Interactive Installation

In Copilot CLI, use the `/plugin` command:

```
/plugin
```

This opens an interactive interface to browse, install, and manage plugins.

---

## Managing Plugins

### CLI Commands

| Command | Description |
|---|---|
| `copilot plugin install SPEC` | Install a plugin |
| `copilot plugin uninstall NAME` | Remove a plugin |
| `copilot plugin list` | List installed plugins |
| `copilot plugin update NAME` | Update a plugin to latest version |

### Interactive

Use `/plugin` in Copilot CLI for a guided experience.

### Listing What's Loaded

Use `/env` to see all active components from plugins:

```
/env
```

---

## Plugin Marketplaces

Marketplaces are curated collections of plugins that you can browse and install from.

### Default Marketplace

The [Awesome GitHub Copilot](https://awesome-copilot.github.com) marketplace is available by default.

### Managing Marketplaces

| Command | Description |
|---|---|
| `copilot plugin marketplace add SPEC` | Register a marketplace |
| `copilot plugin marketplace list` | List registered marketplaces |
| `copilot plugin marketplace browse NAME` | Browse plugins in a marketplace |
| `copilot plugin marketplace remove NAME` | Unregister a marketplace |

### Adding a Marketplace

```bash
# From a GitHub repo
copilot plugin marketplace add owner/repo

# From a URL
copilot plugin marketplace add https://github.com/org/marketplace-repo.git

# From a local path
copilot plugin marketplace add /path/to/marketplace
```

---

## Creating Your Own Plugin

### Step 1: Create the directory structure

```bash
mkdir -p my-plugin/agents my-plugin/skills
```

### Step 2: Create `plugin.json`

```json
{
  "name": "my-plugin",
  "description": "A collection of useful Copilot extensions",
  "version": "1.0.0",
  "author": {
    "name": "Your Name",
    "email": "you@example.com"
  },
  "license": "MIT",
  "keywords": ["productivity", "devtools"],
  "agents": "agents/",
  "skills": "skills/"
}
```

### Step 3: Add components

Add agent files to `agents/`, skills to `skills/`, etc.

### Step 4: Test locally

```bash
copilot plugin install ./my-plugin
```

### Step 5: Publish

Push to a GitHub repo. Others can install with:

```bash
copilot plugin install your-username/my-plugin
```

---

## The `plugin.json` Manifest

### Required Fields

| Field | Type | Description |
|---|---|---|
| `name` | string | Kebab-case name (letters, numbers, hyphens). Max 64 chars |

### Optional Metadata

| Field | Type | Description |
|---|---|---|
| `description` | string | What the plugin does. Max 1024 chars |
| `version` | string | Semantic version (e.g., `1.0.0`) |
| `author` | object | `{ name, email?, url? }` |
| `homepage` | string | Plugin homepage URL |
| `repository` | string | Source repo URL |
| `license` | string | License identifier (e.g., `MIT`) |
| `keywords` | string[] | Search keywords |
| `category` | string | Plugin category |
| `tags` | string[] | Additional tags |

### Component Paths

| Field | Type | Default | Description |
|---|---|---|---|
| `agents` | string \| string[] | `agents/` | Path(s) to agent `.agent.md` files |
| `skills` | string \| string[] | `skills/` | Path(s) to skill `SKILL.md` directories |
| `commands` | string \| string[] | — | Path(s) to command directories |
| `hooks` | string \| object | — | Path to hooks config or inline hooks |
| `mcpServers` | string \| object | — | Path to MCP config or inline definitions |
| `lspServers` | string \| object | — | Path to LSP config or inline definitions |

### Full Example

```json
{
  "name": "fullstack-toolkit",
  "description": "Full-stack development agents, skills, and tools",
  "version": "2.1.0",
  "author": {
    "name": "Jane Dev",
    "email": "jane@example.com",
    "url": "https://janedev.com"
  },
  "license": "MIT",
  "keywords": ["fullstack", "react", "node", "testing"],
  "agents": "agents/",
  "skills": ["skills/", "extra-skills/"],
  "hooks": "hooks.json",
  "mcpServers": ".mcp.json",
  "lspServers": "lsp.json"
}
```

---

## Creating a Marketplace

A marketplace is a GitHub repo with a `marketplace.json` file.

### Structure

```
my-marketplace/
├── .github/plugin/
│   └── marketplace.json
└── plugins/
    ├── plugin-a/
    │   └── plugin.json
    └── plugin-b/
        └── plugin.json
```

### `marketplace.json`

```json
{
  "name": "my-marketplace",
  "owner": {
    "name": "My Org",
    "email": "plugins@myorg.com"
  },
  "metadata": {
    "description": "Curated plugins for our team",
    "version": "1.0.0"
  },
  "plugins": [
    {
      "name": "plugin-a",
      "description": "Does thing A",
      "version": "1.0.0",
      "source": "plugins/plugin-a"
    },
    {
      "name": "plugin-b",
      "description": "Does thing B",
      "version": "2.0.0",
      "source": "plugins/plugin-b"
    }
  ]
}
```

Others register it with:

```bash
copilot plugin marketplace add your-org/my-marketplace
```

---

## Loading Order & Precedence

### Agents & Skills: First Found Wins

Project-level agents/skills always take priority over plugin-provided ones with the same name. Plugins cannot override your local configs.

### MCP Servers: Last Wins

Plugin MCP servers override earlier-loaded ones with the same name. Use `--additional-mcp-config` for highest priority overrides.

### Built-in Components

Built-in tools and agents (bash, view, explore, task, etc.) are always present and cannot be overridden.

### Full Loading Order

```
Built-in tools & agents (always present)
    ↓
User-level agents/skills (~/.copilot/)
    ↓
Project-level agents/skills (.github/)
    ↓
Inherited from parent directories
    ↓
Plugin agents/skills (by install order)
    ↓
Remote org/enterprise agents
```

---

## File Locations

| Item | Path |
|---|---|
| Installed plugins (marketplace) | `~/.copilot/installed-plugins/MARKETPLACE/PLUGIN/` |
| Installed plugins (direct) | `~/.copilot/installed-plugins/_direct/SOURCE-ID/` |
| Marketplace cache | Platform cache dir (`~/.cache/copilot/marketplaces/` on Linux) |
| Plugin manifest | `plugin.json` or `.github/plugin/plugin.json` |
| Marketplace manifest | `marketplace.json` or `.github/plugin/marketplace.json` |

---

## Tips & Best Practices

1. **Browse before building** — check [Awesome Copilot](https://awesome-copilot.github.com) and other marketplaces first
2. **Keep plugins focused** — one purpose per plugin, don't bundle unrelated things
3. **Version your plugins** — use semantic versioning so users can pin versions
4. **Include a README** — help users understand what the plugin does
5. **Test locally first** — install from local path before publishing
6. **Use keywords and descriptions** — make your plugin discoverable
7. **Pin versions in teams** — use `owner/repo@v1.0.0` for reproducible setups
8. **Don't put secrets in plugins** — use environment variable references
9. **Update regularly** — `copilot plugin update` keeps things fresh

---

## Further Reading

- [GitHub Docs: CLI Plugin Reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference)
- [GitHub Docs: Creating Plugins](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/plugins-creating)
- [GitHub Docs: Creating a Marketplace](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/plugins-marketplace)
- [Awesome GitHub Copilot](https://awesome-copilot.github.com)
