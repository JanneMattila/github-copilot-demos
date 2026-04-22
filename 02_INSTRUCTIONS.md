# Giving Instructions to GitHub Copilot

You can customize how GitHub Copilot behaves — across all your projects or just one — by writing instruction files. These are plain Markdown files placed in specific locations that Copilot reads automatically.

This guide covers:

1. [Types of Instructions](#types-of-instructions)
2. [Instruction File Locations & Lookup Order](#instruction-file-locations--lookup-order)
3. [How Instructions Are Loaded](#how-instructions-are-loaded)
4. [Writing Effective Instructions](#writing-effective-instructions)
5. [Tips & Tricks](#tips--tricks)
6. [What to Avoid](#what-to-avoid)
7. [Path-Specific Instructions](#path-specific-instructions)
8. [Useful Commands](#useful-commands)
9. [Further Reading](#further-reading)

---

## Types of Instructions

| Type | Purpose | Scope |
|---|---|---|
| **Repository-wide** | General coding standards, build steps, architecture notes | Every task in this repo |
| **Path-specific** | Language- or directory-specific guidance | Only when working on matching files |
| **Agent instructions** | Guidance for agentic workflows (Copilot CLI, cloud agent, VS Code agent mode) | Nearest file in directory tree |
| **Personal (global)** | Your personal preferences across all projects | All repos on your machine |

---

## Instruction File Locations & Lookup Order

Copilot discovers instructions from multiple locations. Here they are, roughly in the order they are loaded and merged:

### 1. Agent Instructions (in git root & current working directory)

| File | Description |
|---|---|
| `CLAUDE.md` | Agent instructions (originally Claude-specific, now cross-agent) |
| `GEMINI.md` | Agent instructions (Gemini-flavored, also read by Copilot) |
| `AGENTS.md` | Agent instructions (agent-neutral, open standard from [agentsmd/agents.md](https://github.com/agentsmd/agents.md)) |

These files are looked for in **both the git root and the current working directory**. If both exist, the nearest one in the directory tree takes precedence.

> **Tip:** You can place `AGENTS.md` files in subdirectories for context-specific agent instructions (e.g., `src/backend/AGENTS.md` for backend-specific guidance).

### 2. Path-Specific Instructions (in git root & cwd)

```
.github/instructions/**/*.instructions.md
```

These files use YAML frontmatter with an `applyTo` glob pattern to specify which files they apply to. They are only loaded when Copilot is working on files that match the pattern.

### 3. Repository-Wide Custom Instructions

```
.github/copilot-instructions.md
```

A single Markdown file in the `.github` directory. Always loaded for any task in this repository. This is the most common and straightforward place to put repo-level instructions.

### 4. Personal (Global) Instructions

```
~/.copilot/copilot-instructions.md
```

On Windows: `%USERPROFILE%\.copilot\copilot-instructions.md`

Instructions that apply to **all repositories** you work in. Great for personal style preferences.

### 5. Additional Directories (Environment Variable)

```
COPILOT_CUSTOM_INSTRUCTIONS_DIRS
```

You can point to additional instruction directories using this environment variable. Useful for team-shared instructions outside the repo.

### Summary Table

| Priority | Location | Scope | When Loaded |
|---|---|---|---|
| 1 | `CLAUDE.md` / `GEMINI.md` / `AGENTS.md` | Agent instructions | Always (nearest in tree) |
| 2 | `.github/instructions/**/*.instructions.md` | Path-specific | When working on matching files |
| 3 | `.github/copilot-instructions.md` | Repo-wide | Always |
| 4 | `~/.copilot/copilot-instructions.md` | Global (personal) | Always |
| 5 | `COPILOT_CUSTOM_INSTRUCTIONS_DIRS` paths | Custom | Always |

> **Note:** All instructions from applicable sources are **merged together** — they don't replace each other. If there's a conflict, more specific instructions (path-specific, nearest agent file) generally take precedence.

---

## How Instructions Are Loaded

1. When Copilot starts (CLI launch, VS Code session, cloud agent task), it scans the known locations
2. `AGENTS.md` / `CLAUDE.md` / `GEMINI.md` are read from the git root and current directory
3. `.github/copilot-instructions.md` is read if it exists
4. Path-specific `.instructions.md` files are matched against the files being worked on
5. Personal `~/.copilot/copilot-instructions.md` is read
6. All applicable instructions are injected into the agent's system context
7. The agent follows them as part of its working guidelines

You can verify which instructions are loaded using the `/instructions` or `/env` commands in Copilot CLI.

---

## Writing Effective Instructions

### Structure

Use clear Markdown with headings, lists, and code blocks:

```markdown
# Project Standards

## Language & Framework
- This is a Node.js project using Express
- Use TypeScript for all new files
- Target Node.js 20 LTS

## Code Style
- Use 2-space indentation
- Prefer `const` over `let`
- Use async/await, not callbacks

## Testing
- Write tests with Jest
- Run tests with `npm test`
- Always run tests before committing

## Build & Validation
- Build: `npm run build`
- Lint: `npm run lint`
- Always run lint before submitting changes
```

### What to Include

| Category | Examples |
|---|---|
| **Project overview** | What the repo does, key technologies, architecture |
| **Build commands** | How to build, test, lint, and run the project |
| **Code conventions** | Naming, formatting, patterns to follow |
| **File organization** | Where to put new files, directory structure |
| **Dependencies** | How to install, what package manager to use |
| **Testing strategy** | Test framework, how to run tests, coverage expectations |
| **Validation steps** | What to check before committing |
| **Common pitfalls** | Known issues, gotchas, workarounds |

### Be Declarative and Specific

```markdown
# Good ✅
- Always use `pnpm` instead of `npm` for package management
- Run `pnpm test` after every change to ensure nothing is broken
- Use the `src/utils/` directory for shared utility functions

# Bad ❌
- Use the right package manager
- Test your code
- Put files in the right place
```

---

## Tips & Tricks

### 1. Start with `/init`

Run `/init` in Copilot CLI to auto-generate a starting `copilot-instructions.md` for your repo. It inspects your project and creates sensible defaults.

### 2. Use the cloud agent to generate instructions

On GitHub.com, you can ask the Copilot cloud agent to generate comprehensive instructions by giving it a detailed prompt about your repo. It will analyze the codebase and create a PR with a `.github/copilot-instructions.md` file.

### 3. Keep instructions concise but complete

Aim for **1–2 pages**. Long enough to be useful, short enough that it doesn't waste context window tokens. Every token spent on instructions is a token not available for reasoning about your code.

### 4. Use `AGENTS.md` for subdirectory context

Place `AGENTS.md` files in subdirectories to give agents context specific to that area:

```
src/
├── backend/
│   ├── AGENTS.md    ← "This is an Express API. Use controllers in /controllers..."
│   └── ...
├── frontend/
│   ├── AGENTS.md    ← "This is a React app using Next.js..."
│   └── ...
```

### 5. Use path-specific instructions for language rules

```markdown
---
applyTo: "**/*.ts,**/*.tsx"
---

# TypeScript Guidelines
- Enable strict mode
- No `any` types — use `unknown` and narrow
- Prefer interfaces over type aliases for object shapes
```

### 6. Verify loaded instructions

Use `/instructions` in Copilot CLI to see exactly which instruction files are loaded and their contents. Use `/env` for a broader view of everything loaded (instructions, skills, MCP servers, etc.).

### 7. Use comments for hidden instructions

Markdown comments (`<!-- ... -->`) are still read by Copilot but won't render in GitHub's Markdown preview:

```markdown
<!-- Always validate user input before processing -->
```

### 8. Include explicit command sequences

Don't just say "build the project" — give the exact commands:

```markdown
## Build Steps (always follow this order)
1. `npm install` — install dependencies
2. `npm run lint` — check for errors
3. `npm run build` — compile TypeScript
4. `npm test` — run the test suite
```

### 9. Document error workarounds

If there are known build issues or flaky tests, document them:

```markdown
## Known Issues
- The `auth` tests may fail on first run due to missing env vars. Run `cp .env.example .env` first.
- On Windows, use `npx jest` instead of `npm test` if you get permission errors.
```

### 10. Use personal instructions for style preferences

Put personal preferences in `~/.copilot/copilot-instructions.md`:

```markdown
# My Preferences
- I prefer functional programming patterns
- Use descriptive variable names, not abbreviations
- Add JSDoc comments to all exported functions
- When explaining code, be concise
```

---

## What to Avoid

### ❌ Don't make instructions task-specific

Instructions should be **general-purpose** — they apply to any task in the repo. Don't write "when implementing the login feature, do X". Instead, write "authentication endpoints should follow the pattern in `src/auth/`".

### ❌ Don't include secrets or credentials

Instruction files are committed to git. Never put API keys, passwords, tokens, or other secrets in them.

### ❌ Don't be vague

"Write good code" or "follow best practices" wastes context tokens and gives Copilot nothing actionable.

### ❌ Don't contradict yourself

If you have instructions in multiple files, make sure they're consistent. Conflicting instructions confuse the agent.

### ❌ Don't write a novel

If your instructions file is more than ~2 pages, it's too long. Focus on what matters most. Every token of instructions is context the agent can't use for reasoning.

### ❌ Don't duplicate what's obvious from the code

Don't restate things Copilot can infer from `package.json`, `tsconfig.json`, or other config files. Focus on things that **aren't** obvious.

### ❌ Don't include prompt injection attacks

This should go without saying, but instructions should help Copilot do its job — not try to manipulate it into ignoring safety guidelines or doing unrelated things.

### ❌ Don't rely on instructions alone for critical validation

Instructions are guidance, not enforcement. Always have CI/CD pipelines, linters, and code review as safety nets.

---

## Path-Specific Instructions

Path-specific instructions let you scope guidance to certain file types or directories.

### File naming

```
.github/instructions/NAME.instructions.md
```

The `NAME` can be anything descriptive. The file must end with `.instructions.md`.

### Frontmatter format

```markdown
---
applyTo: "**/*.py"
---

# Python Guidelines
- Use type hints for all function signatures
- Follow PEP 8
- Use `pytest` for testing
```

### Multiple patterns

```markdown
---
applyTo: "src/api/**/*.ts,src/api/**/*.tsx"
---
```

### Excluding agents

You can exclude specific agents from reading the file:

```markdown
---
applyTo: "**"
excludeAgent: "code-review"
---

These instructions are only for Copilot cloud agent / CLI, not code review.
```

### Organizing instruction files

```
.github/
└── instructions/
    ├── python.instructions.md       ← applyTo: "**/*.py"
    ├── typescript.instructions.md   ← applyTo: "**/*.ts,**/*.tsx"
    ├── testing.instructions.md      ← applyTo: "**/*.test.*,**/*.spec.*"
    └── api/
        └── routes.instructions.md   ← applyTo: "src/api/routes/**"
```

---

## Useful Commands

| Command | Description |
|---|---|
| `/init` | Generate initial `copilot-instructions.md` for your repo |
| `/instructions` | View and toggle loaded instruction files |
| `/env` | Show full environment (instructions, skills, MCP servers, etc.) |

---

## VS Code (Copilot Chat) — Equivalents

The same instruction files work for the **CLI**, the **VS Code (stable)** GitHub Copilot Chat extension, and the **cloud agent**. You don't need a separate copy:

- `.github/copilot-instructions.md`
- `AGENTS.md` / `CLAUDE.md` / `GEMINI.md` (in the git root or any parent directory)
- `.github/instructions/*.instructions.md` (with `applyTo` glob)

### VS Code-specific settings

Open **Settings (UI)** and search, or edit `settings.json`:

| Setting | What it does |
|---|---|
| `github.copilot.chat.codeGeneration.useInstructionFiles` | Master switch — must be `true` for `.github/copilot-instructions.md` to apply |
| `chat.instructionsFilesLocations` | Add custom directories that should also be scanned for `*.instructions.md` files |
| `github.copilot.chat.codeGeneration.instructions` | Inline instructions (small list in settings, no file needed) |
| `github.copilot.chat.testGeneration.instructions` | Same, scoped to test generation |
| `github.copilot.chat.commitMessageGeneration.instructions` | Same, scoped to commit messages |
| `github.copilot.chat.reviewSelection.instructions` | Same, scoped to "review selection" |

### Personal / user-level instructions in VS Code

- Use **Settings sync** to share `github.copilot.chat.*Generation.instructions` across machines.
- Place a personal `*.instructions.md` in your VS Code user profile folder and add the folder to `chat.instructionsFilesLocations`.

### Verifying loaded instructions in VS Code

- **Chat: Show Used Instructions** (Command Palette, `Ctrl+Shift+P`) — lists files applied to the most recent request.
- Hover the "Used N instructions" indicator on any assistant reply to see which files were used for that turn.

### Quick mapping

| CLI | VS Code (Copilot Chat) |
|---|---|
| `/init` | "Generate Workspace Instructions File" command (where available); otherwise hand-write `.github/copilot-instructions.md` |
| `/instructions` | **Chat: Show Used Instructions** |
| `/env` | No single equivalent — combine "Show Used Instructions", "MCP: List Servers" and the Chat output channel |

---

## Further Reading

- [GitHub Docs: Adding Repository Custom Instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions)
- [VS Code Docs: Custom instructions for Copilot](https://code.visualstudio.com/docs/copilot/copilot-customization)
- [GitHub Docs: About Customizing Copilot Responses](https://docs.github.com/en/copilot/concepts/prompting/response-customization)
- [AGENTS.md Standard](https://github.com/agentsmd/agents.md)
- [Copilot CLI Documentation](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-copilot-cli)
