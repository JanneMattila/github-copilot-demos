# Git Worktrees: A Practical Guide

Git worktrees let you check out multiple branches of the same repository **simultaneously**, each in its own directory on disk. Instead of stashing or committing half-finished work to switch branches, you simply `cd` into another folder.

This guide covers:

1. [What Are Git Worktrees?](#what-are-git-worktrees)
2. [CLI Commands](#cli-commands)
3. [Merging Across Worktrees / Branches](#merging-across-worktrees--branches)
4. [Practical Workflow Example](#practical-workflow-example)
5. [Agentic Development with GitHub Copilot CLI & VS Code Insiders](#agentic-development-with-github-copilot-cli--vs-code-insiders)

---

## What Are Git Worktrees?

A normal Git clone has **one working tree** tied to one branch. When you run `git worktree add`, Git creates an additional working directory linked to the **same `.git` database**. All worktrees share:

- The object store (commits, blobs, trees)
- Refs (branches, tags, remotes)
- Configuration (`.git/config`)

But each worktree has its own:

- Working directory (files on disk)
- Index / staging area
- `HEAD` (the currently checked-out branch)

**Key rule:** Two worktrees cannot have the same branch checked out at the same time. Git enforces this to prevent confusion.

### Why Use Them?

| Scenario | Without Worktrees | With Worktrees |
|---|---|---|
| Quick hotfix while mid-feature | Stash → switch → fix → switch → pop | `cd ../hotfix` and work |
| Run tests on main while coding | Wait or use a second clone | Both directories exist simultaneously |
| Compare behavior across branches | Checkout ping-pong | Open two terminals side-by-side |
| Parallel AI agent development | One agent at a time, or multiple clones | Each agent gets its own worktree |

---

## CLI Commands

### Create a Worktree

```bash
# Create a new worktree AND a new branch
git worktree add ../feature-x -b feature-x

# Create a worktree for an existing branch
git worktree add ../hotfix hotfix/critical-bug

# Create a worktree from a specific commit (detached HEAD)
git worktree add ../experiment abc1234
```

The first argument is the **path** for the new working directory. By convention, sibling directories work well:

```
C:\repos\
├── my-project/            ← main worktree (main branch)
├── my-project-feature-x/  ← worktree (feature-x branch)
└── my-project-hotfix/     ← worktree (hotfix branch)
```

### List Worktrees

```bash
git worktree list
```

Output:

```
C:/repos/my-project            abc1234 [main]
C:/repos/my-project-feature-x  def5678 [feature-x]
C:/repos/my-project-hotfix     ghi9012 [hotfix/critical-bug]
```

### Remove a Worktree

```bash
# Remove after you're done (branch is NOT deleted)
git worktree remove ../my-project-feature-x

# Force remove if there are uncommitted changes
git worktree remove --force ../my-project-feature-x
```

### Prune Stale Worktrees

If a worktree directory was deleted manually (e.g., `rm -rf`), clean up the metadata:

```bash
git worktree prune
```

### Move a Worktree

```bash
git worktree move ../old-path ../new-path
```

---

## Merging Across Worktrees / Branches

This is the most common question: *"How do I get changes from one worktree into another?"*

**The answer is simple: worktrees share the same repository.** Every commit you make in any worktree is immediately visible to all other worktrees. You merge **branches**, not worktrees — using the same `git merge`, `git rebase`, and `git cherry-pick` commands you already know.

### Method 1: Merge (Recommended Default)

From the main worktree, merge a feature branch:

```bash
# In your main worktree (on branch 'main')
cd C:\repos\my-project

git merge feature-x
```

That's it. Since both worktrees share the same `.git`, the `feature-x` branch and all its commits are already local. No fetch, no remote — just merge.

### Method 2: Rebase

If you prefer a linear history, rebase the feature branch onto main:

```bash
# In the feature-x worktree
cd C:\repos\my-project-feature-x

git rebase main
```

Or, if you want to rebase without switching worktrees, you can do it from anywhere because the branches are shared:

```bash
# From any worktree — rebase feature-x onto main
git rebase main feature-x
```

> **Note:** After rebasing, the feature-x worktree's working directory updates automatically since its HEAD follows the branch.

### Method 3: Cherry-Pick

Pull individual commits from one branch into another:

```bash
# In the main worktree
cd C:\repos\my-project

# Cherry-pick a specific commit from any branch
git cherry-pick abc1234
```

### Method 4: Merge via Pull Request (Team Workflow)

In a team setting, you'll usually:

1. Push the feature branch to the remote: `git push origin feature-x`
2. Open a Pull Request on GitHub
3. Review and merge on GitHub
4. Pull the updated main: `git pull` (from the main worktree)

### Quick Reference Table

| Goal | Command | Run From |
|---|---|---|
| Merge feature into main | `git merge feature-x` | Main worktree |
| Rebase feature onto main | `git rebase main` | Feature worktree |
| Cherry-pick one commit | `git cherry-pick <sha>` | Target worktree |
| Get latest from remote | `git pull` | Any worktree |
| Push feature branch | `git push origin feature-x` | Feature worktree |

### Important: Updating a Worktree After External Changes

If you merge or rebase a branch from a **different** worktree than the one that has it checked out, the on-disk files in that worktree won't update until you do:

```bash
# In the affected worktree
cd C:\repos\my-project-feature-x
git checkout feature-x   # re-checkout to refresh working tree
# or simply
git reset --hard feature-x
```

---

## Practical Workflow Example

Let's walk through a complete workflow using this demo project:

### Step 1: Initialize and Make an Initial Commit

```bash
cd C:\temp\demo-with-worktrees
git init
git add -A
git commit -m "Initial commit: hello world app"
```

### Step 2: Create a Worktree for a Feature Branch

```bash
# Create a sibling directory with a new branch
git worktree add ../demo-feature-dark-mode -b feature/dark-mode
```

### Step 3: Make Changes in the Feature Worktree

```bash
cd C:\temp\demo-feature-dark-mode

# Edit server.js to add dark mode CSS
# ... make your changes ...

git add -A
git commit -m "Add dark mode support"
```

### Step 4: Merge Back into Main

```bash
# Go back to the main worktree
cd C:\temp\demo-with-worktrees

# Merge the feature branch
git merge feature/dark-mode

# Optionally delete the branch
git branch -d feature/dark-mode
```

### Step 5: Clean Up the Worktree

```bash
git worktree remove ../demo-feature-dark-mode
```

### Verify

```bash
git worktree list
# Should show only the main worktree now

git log --oneline
# Should show the merge commit
```

---

## Agentic Development with GitHub Copilot CLI & VS Code Insiders

Git worktrees become especially powerful when combined with AI coding agents. Here's why and how.

### The Problem with Single-Directory Development

When an AI agent (like GitHub Copilot's coding agent) works on your code, it typically needs to:

- Read files, make changes, run tests
- Operate on a branch without interfering with your work
- Work in parallel with other agents or with you

With a single working directory, only one entity — you or an agent — can comfortably work at a time. You'd need to stash your changes, switch branches, or wait for the agent to finish.

### The Worktree Solution

**Give each agent its own worktree.** Each worktree is an isolated workspace with its own branch, staging area, and files on disk — but they all share the same Git history.

```
C:\repos\
├── my-app/                    ← YOUR worktree (main branch) — you work here
├── my-app-agent-auth/         ← Agent 1's worktree (feature/auth branch)
├── my-app-agent-tests/        ← Agent 2's worktree (feature/add-tests branch)
└── my-app-agent-refactor/     ← Agent 3's worktree (feature/refactor branch)
```

### Setting Up Worktrees for Agents

```bash
# From your main worktree
cd C:\repos\my-app

# Create worktrees for each agent task
git worktree add ../my-app-agent-auth -b feature/auth
git worktree add ../my-app-agent-tests -b feature/add-tests
git worktree add ../my-app-agent-refactor -b feature/refactor-utils
```

### Using GitHub Copilot CLI with Worktrees

GitHub Copilot CLI (the `copilot` command or `github-copilot-cli`) can operate in any directory. Point it at a worktree and let it work:

```bash
# Open a terminal in the agent's worktree
cd C:\repos\my-app-agent-auth

# Start a Copilot CLI session scoped to this worktree
# Copilot CLI sees this as a normal git repo and can make changes freely
copilot

# Or use VS Code Insiders' integrated terminal
# The agent works on feature/auth without touching your main branch
```

**Key pattern:** Launch separate Copilot CLI sessions in separate worktrees. Each session operates on its own branch. You continue working in your main worktree undisturbed.

### Using VS Code Insiders with Multiple Worktrees

VS Code Insiders supports **multi-root workspaces**, which pairs perfectly with worktrees:

1. **Open each worktree as a folder** — `File > Add Folder to Workspace`
2. **Or open each in a separate window** — `code-insiders C:\repos\my-app-agent-auth`

With Copilot Chat or Copilot Edits in VS Code Insiders:

- Open a worktree folder in VS Code Insiders
- Use Copilot Chat's agent mode (`@workspace`) to make changes scoped to that worktree
- The changes happen on the worktree's branch, isolated from your main work
- You can have multiple VS Code windows open — one per worktree — each with its own Copilot session

### The Agentic Workflow

Here's a complete workflow for parallel agentic development:

#### 1. Plan your tasks

Identify independent features or fixes that can be worked on in parallel.

#### 2. Create worktrees

```bash
git worktree add ../app-agent-1 -b feature/task-1
git worktree add ../app-agent-2 -b feature/task-2
```

#### 3. Launch agents

- **Copilot CLI:** Open terminals in each worktree directory, start `copilot` sessions
- **VS Code Insiders:** Open each worktree in a separate window, use Copilot Chat/Edits
- **GitHub Copilot Coding Agent (cloud):** For remote workflows, create branches and let the cloud agent work via PRs — worktrees are most useful for *local* agent workflows

#### 4. Review agent work

```bash
# From your main worktree, inspect what agents did
git log --oneline feature/task-1
git diff main..feature/task-1
git diff main..feature/task-2
```

#### 5. Merge completed work

```bash
# Merge task-1
git merge feature/task-1

# Merge task-2 (resolve conflicts if any)
git merge feature/task-2
```

#### 6. Clean up

```bash
git worktree remove ../app-agent-1
git worktree remove ../app-agent-2
git branch -d feature/task-1 feature/task-2
```

### Benefits of Worktrees for Agentic Development

| Benefit | Explanation |
|---|---|
| **Isolation** | Each agent works on its own branch and file system — no conflicts with your work or other agents |
| **Parallelism** | Multiple agents can work simultaneously on different features |
| **Easy review** | You can `git diff` and `git log` any agent's branch from your main worktree |
| **Safe rollback** | Don't like an agent's work? Just delete the branch. Your main branch is untouched |
| **No clone overhead** | Worktrees share the object store — creating one is nearly instant and uses minimal extra disk space |
| **Standard Git workflow** | Merging agent work uses the same `git merge` / `git rebase` you already know |

### Tips for Agentic Worktree Workflows

1. **Name worktrees clearly** — include "agent" or the task name so you know which is which
2. **Keep agent branches focused** — one task per branch/worktree for clean merges
3. **Review before merging** — always inspect agent changes with `git diff` before merging
4. **Use short-lived worktrees** — create for a task, merge, remove. Don't let them accumulate
5. **Commit frequently in agent worktrees** — if an agent session crashes, you don't lose progress
6. **Leverage VS Code's Source Control view** — it shows changes per-worktree when using multi-root workspaces

---

### Per-worktree VS Code settings

Each worktree is a normal directory, so you can give each its own `.vscode/settings.json` (just `.gitignore` it if you don't want to commit it). This is especially useful when running multiple Copilot chat sessions in parallel on different worktrees:

- A different **window color** (`workbench.colorCustomizations`) so you can tell agent windows apart at a glance.
- A different **default chat mode** (`chat.defaultMode`) — e.g. force "Agent" in agent worktrees and "Ask" in your main one.
- A different **MCP config** per worktree via `.vscode/mcp.json` (see [06_MCP.md](./06_MCP.md)).

> **Note:** the section above mentions VS Code Insiders, but everything in this doc works on **VS Code stable** with the GitHub Copilot Chat extension. Insiders is only required for Copilot features still in preview.

---

## Further Reading

- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
- [GitHub Copilot CLI](https://docs.github.com/en/copilot/using-github-copilot/using-github-copilot-in-the-command-line)
- [VS Code Insiders](https://code.visualstudio.com/insiders/)
- [Multi-root Workspaces in VS Code](https://code.visualstudio.com/docs/editor/multi-root-workspaces)
