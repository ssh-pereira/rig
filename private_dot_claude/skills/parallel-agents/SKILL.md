---
name: parallel-agents
description: Set up and run several coding agents in parallel on isolated git worktrees with a tmux layout. Use when Hugo wants to work on multiple independent tasks at once, or asks to "run these in parallel" / "spin up agents for these".
---

# Running agents in parallel

The rule: **one agent, one worktree, one branch.** Agents sharing a working directory will overwrite each other's edits and corrupt each other's builds. Worktrees make that structurally impossible.

## When this applies

Good fit — genuinely independent tasks:
- Three unrelated bugfixes across different modules.
- A refactor in one place, a feature in another.
- Trying two different approaches to the same problem and comparing.

Bad fit — do these sequentially instead:
- Tasks that touch the same files.
- A task whose design depends on the outcome of another.
- Anything with fewer than ~15 minutes of work in it; setup overhead dominates.

## Setup

From inside the repo, one worktree per task:

```bash
gwt fix-auth-redirect      # creates ../<repo>-worktrees/fix-auth-redirect + branch, cds there
gwt add-csv-export
gwt bump-node-24
```

Each is a real directory on its own branch, sharing one `.git` object store. Cheap to make, cheap to throw away.

Note: worktrees do **not** copy gitignored files. Node projects need `bun install` in each new worktree, and `.env` files must be copied over manually:

```bash
cp .env ../<repo>-worktrees/<name>/.env && (cd ../<repo>-worktrees/<name> && bun install)
```

## The tmux layout

```bash
tn agents                  # new session
^a A                       # 3-pane layout
```

Then in each pane, cd to a worktree and start an agent:

```bash
cd ../myrepo-worktrees/fix-auth-redirect && claude
```

`^a m` zooms one pane fullscreen when you need to actually read output; press it again to see all three. `^a d` detaches and leaves everything running.

## Briefing the agents

Each agent starts with zero knowledge of the others. Give each one:
- A single, self-contained objective.
- The explicit instruction not to touch files outside its scope.
- Whether it should commit (usually yes — it keeps the branch clean for review).

Do not ask two agents to coordinate. They cannot. If work needs coordination, it is one task, not two.

## Collecting the work

Review each branch separately — this is the part people skip and regret:

```bash
gwl                                    # list the worktrees
cd ../myrepo-worktrees/fix-auth-redirect
git diff main...HEAD | delta           # or: lg
```

Then either merge or open a PR per branch:

```bash
gh pr create --fill
```

Clean up when merged:

```bash
gwtrm fix-auth-redirect                # removes worktree + deletes branch
```

## Failure modes to watch for

- **Port collisions.** Three dev servers all want port 4000. Assign each worktree a different port, or only run one dev server at a time.
- **Shared external state.** Agents pointed at the same dev database will fight. Give each its own, or keep them to work that doesn't touch it.
- **Silent divergence.** All three branched from the same `main`. If one lands a change the others depend on, rebase the rest before merging.
- **Losing track.** Name branches after the task, not `test` or `wip`. `gwl` is your index.
