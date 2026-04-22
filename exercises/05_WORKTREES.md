# Exercises — 05 Git Worktrees

Source doc: [../05_WORKTREES.md](../05_WORKTREES.md)

## Learning objectives

- Create, list, and remove worktrees.
- Move changes between branches/worktrees with merge, rebase and cherry-pick.
- Run multiple Copilot CLI sessions in parallel, one per worktree.
- Recognise the gotchas (shared branches, refresh after external rebase, etc.).

---

## Part A — Comprehension

### A1. What do worktrees share, and what does each have its own copy of?

<details>
<summary>Show answer</summary>

**Shared:** the `.git` object store (commits, blobs, trees), refs (branches /
tags / remotes), and `.git/config`.

**Per-worktree:** working directory (files on disk), index/staging area, and
`HEAD` (the currently checked-out branch).
</details>

### A2. Why can two worktrees not have the same branch checked out simultaneously?

<details>
<summary>Show answer</summary>

Because they all share the same refs. If two worktrees both moved `HEAD` of
the same branch independently, the refs would conflict. Git enforces
"one branch, one worktree" to prevent that confusion.
</details>

### A3. You merged `feature-x` into `main` from the main worktree, but the `feature-x` worktree still shows the old files. Why, and how do you fix it?

<details>
<summary>Show answer</summary>

The `feature-x` worktree's `HEAD` still points at the old commit on disk —
merging happened *to* `main`, not *to* `feature-x`. To refresh the working
files in the `feature-x` worktree, run inside it:

```bash
git checkout feature-x   # re-checkout to refresh
# or
git reset --hard feature-x
```
</details>

### A4. Why are worktrees especially nice for *agentic* development?

<details>
<summary>Show answer</summary>

Each agent gets its own isolated working directory + branch, so multiple
agents (and you) can work in parallel without stashing or conflicting. They
all share the same `.git`, so reviewing/merging their work uses the standard
`git diff` and `git merge` commands.
</details>

---

## Part B — Hands-on tasks

> **Setup:** these tasks operate in a *scratch* directory, not in this repo,
> so that you can experiment freely. Pick somewhere like `C:\temp\wt-demo`
> (Windows) or `/tmp/wt-demo` (Unix).

### B1. The basic lifecycle

**Goal:** create, list, work in, and remove a worktree.

Steps:

1. ```bash
   git init wt-demo && cd wt-demo
   echo "# demo" > README.md
   git add . && git commit -m "init"
   ```
2. Create a worktree on a new branch:
   ```bash
   git worktree add ../wt-demo-feature -b feature/x
   ```
3. `git worktree list` — confirm both directories are listed.
4. `cd ../wt-demo-feature`, add a file, commit.
5. From the main worktree, `git log --oneline feature/x` — your commit is
   visible (worktrees share the object store).
6. Merge it back: `cd ../wt-demo && git merge feature/x`.
7. Remove the worktree: `git worktree remove ../wt-demo-feature`.
8. Optionally delete the merged branch: `git branch -d feature/x`.

<details>
<summary>Hint</summary>

If step 7 complains about uncommitted changes, either commit them first or
use `git worktree remove --force`.
</details>

### B2. Practice each merge strategy

**Goal:** do the same change three times — once via merge, once via rebase,
once via cherry-pick — and observe the resulting history.

Steps:

1. From the scratch repo, create three worktrees: `wt-merge`, `wt-rebase`,
   `wt-cherry`, each on its own branch from `main`.
2. In each, make one identical commit (e.g. add a `NOTES.md`).
3. Bring them back into `main` using:
   - `git merge feature/merge` (from the main worktree)
   - `git rebase main feature/rebase` then `git merge feature/rebase`
     (fast-forward)
   - `git cherry-pick <sha>` (from the main worktree)
4. `git log --oneline --graph --all` — describe the difference.

<details>
<summary>Show answer</summary>

- **Merge** creates a merge commit (or fast-forwards if no new commits on
  main).
- **Rebase + ff merge** rewrites the feature commit on top of main and the
  merge becomes a fast-forward — linear history, but the commit SHA changed.
- **Cherry-pick** copies the commit's *content* under a new SHA on main,
  while the original branch still has the old SHA.

All three move the change; they differ in what the history looks like
afterwards.
</details>

### B3. Recover from a manually-deleted worktree directory

**Goal:** experience why `git worktree prune` exists.

Steps:

1. Create a worktree (`git worktree add ../wt-demo-oops -b feature/oops`).
2. Delete the directory directly with PowerShell / `rm -rf` instead of
   `git worktree remove`.
3. `git worktree list` — note the stale entry.
4. `git worktree prune`.
5. `git worktree list` — entry is gone.

<details>
<summary>Hint</summary>

PowerShell: `Remove-Item -Recurse -Force ..\wt-demo-oops`.
</details>

### B4. Run two Copilot CLI sessions in parallel

**Goal:** one agent works on `feature/auth`, another on `feature/tests`,
neither disturbs your main worktree.

Steps:

1. From your main worktree, create two worktrees:
   ```bash
   git worktree add ../app-agent-auth  -b feature/auth
   git worktree add ../app-agent-tests -b feature/tests
   ```
2. Open *two* terminal windows. In each, `cd` into one of the new worktrees
   and run `copilot`.
3. In one session, ask Copilot to add a (fake) auth helper file. In the other,
   ask it to add a test scaffold.
4. Both should be working *simultaneously* without colliding.
5. From your main worktree, `git diff main..feature/auth` and
   `git diff main..feature/tests` to inspect.
6. Merge whichever is good, discard the other (`git branch -D feature/tests`
   and `git worktree remove ../app-agent-tests`).

<details>
<summary>Hint</summary>

Don't try to share the same branch between two worktrees — Git will refuse.
One branch per worktree is the rule.
</details>

---

## Stretch goal

Set up a long-running "agent garden": a sibling-directory layout where every
parallel task you give Copilot lives in its own worktree, named consistently
(e.g. `myrepo-task-001-add-cache`). Add a tiny shell function `wtnew` that
takes a slug and creates the worktree + branch in one go. Use it for at least
one real task and merge the result via PR.

Bonus: combine with [hooks](./08_HOOKS.md) so that `sessionStart` logs which
worktree the agent is operating in.
