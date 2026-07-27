# git

## What the setup gives you

- **delta** renders every diff with syntax highlighting and line numbers.
- **difftastic** (`git dft`) compares *syntax trees* — reformatting shows as no change.
- **lazygit** (`lg`) is a TUI for staging hunks, interactive rebase, and conflicts.
- **worktrees** (`gwt`) give each parallel agent its own directory on its own branch.

## Worktrees — the one to actually learn

A worktree is a second working directory for the same repo, on a different branch, sharing one `.git`.

```bash
gwt feature-x      # create branch + worktree at ../<repo>-worktrees/feature-x, cd there
gwl                # list them
gwtrm feature-x    # remove worktree and delete branch
```

Why it matters: two agents in one directory overwrite each other. Two worktrees structurally cannot.

**Gotcha:** worktrees don't copy gitignored files. No `node_modules`, no `.env`:
```bash
cp .env ../repo-worktrees/feature-x/.env
(cd ../repo-worktrees/feature-x && bun install)
```

## Things you probably don't know

- **`git rerere`** (enabled here) records how you resolved a conflict and replays it automatically next time. Invisible until you rebase a long branch twice and the second one just works.

- **`zdiff3` conflict markers** (enabled here) show the **original** text alongside both sides, not just the two conflicting versions. Makes resolution dramatically easier.

- **Three-dot vs two-dot diff.**
  ```bash
  git diff main..HEAD     # difference between the two tips
  git diff main...HEAD    # only YOUR changes since branching  ← usually what you want
  ```

- **`git log -S "functionName"`** — find every commit that added or removed that string. The way to answer "when did this line appear?"

- **`git log -p -- path/to/file`** — full history of one file, with diffs.

- **`git bisect`** — binary search for the commit that broke something.
  ```bash
  git bisect start; git bisect bad; git bisect good <old-sha>
  # test, then: git bisect good | git bisect bad ... until it names the commit
  git bisect reset
  ```

- **`git reflog`** — every position HEAD has held, including "lost" commits. Almost nothing is truly unrecoverable after a bad reset:
  ```bash
  git reflog
  git reset --hard HEAD@{2}
  ```

- **`git stash -p`** — interactively choose what to stash, hunk by hunk.

- **`git add -p`** — stage hunk by hunk. `lazygit` does this better, but know the CLI exists.

- **`git commit --fixup <sha>`** then `git rebase -i --autosquash` — mark a commit as a fix for an earlier one and have rebase merge them automatically. `autoSquash` is on here, so the flag is implied.

- **`git switch` and `git restore`** replace the overloaded `git checkout`. `switch` changes branch, `restore` changes files. Less footgun.

- **`git maintenance start`** — schedules background gc/prefetch. Noticeably faster on big monorepos.

- **`git blame -w -C`** — ignore whitespace and follow code moved between files. Regular blame lies after a refactor.

- **`git diff --word-diff`** — word-level instead of line-level. Good for prose and long lines.

## Conditional identity

`~/.gitconfig` includes a second file for repos under a specific directory:
```
[includeIf "gitdir:~/dev/hill/"]
    path = ~/.gitconfig-hill
```
So work repos get the work email automatically and personal ones don't. In this repo that's templated by machine type.

## Aliases here

| Alias | Full |
|---|---|
| `git st` | `status -sb` |
| `git lg` | pretty graph, all branches, last 30 |
| `git last` | last commit with stats |
| `git undo` | `reset --soft HEAD~1` — uncommit, keep changes |
| `git wt` | `worktree` |
| `git dft` | difftastic structural diff |
