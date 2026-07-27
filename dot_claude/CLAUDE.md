# Global preferences — Hugo

These apply to every project on this machine. **Project-level `CLAUDE.md` and `AGENTS.md` always win over this file.** When they conflict, follow the project.

## Environment

- macOS, zsh, Ghostty + tmux. Editor is `zed --wait`.
- Modern CLI is installed and preferred: `rg` over grep, `fd` over find, `eza` over ls, `bat` over cat, `delta` for diffs, `doggo` over dig, `xh` over curl, `jless` for JSON.
- **Detect the project's toolchain before assuming one.** Check for a lockfile: `bun.lock` → bun, `pnpm-lock.yaml` → pnpm, `uv.lock` → uv, and so on. Never introduce a second package manager into a repo.
- Same for linting: if `biome.json` exists use Biome, if `.eslintrc*` exists use ESLint. Don't switch a project's tooling as a side effect of another task.
- My personal default for a *new* project: bun + Biome for TS, uv for Python.

## Working style

- Be concise. Lead with the answer, then the reasoning if it's needed.
- Don't re-explain code you just wrote unless asked.
- When something is ambiguous in a way that changes the output, ask. Otherwise pick the sensible default and say which one you picked.
- Report failures plainly with the actual output. Never describe partial work as done.
- I'm learning infrastructure deliberately — when you run a non-obvious infra command, say in one line *why* that step exists, not just what it does.

## Infrastructure safety

Cloud-agnostic rules. Specific conventions (naming, labels, environments, module layout) live in each repo's own `CLAUDE.md` — **read that first and defer to it.**

### Before any `terraform apply` / `terragrunt apply`
1. State which environment is targeted. If that's ambiguous, stop and ask — applying to the wrong environment is the most expensive available mistake.
2. Show me the plan before applying. Apply a saved plan file (`-out=tfplan`), never a bare re-plan.
3. List every destroy and replace separately. A `-/+` on anything stateful is data loss, not a change.
4. Run `infracost breakdown --path .` if the plan creates or resizes resources.
5. Run `trivy config .` on changed IaC.

### Before any `kubectl` write
State the current context and namespace first (`kubectl config current-context`). Never assume it's correct — I switch clusters often, and a local `kind` cluster and a remote one look identical in a prompt.

Treat any context or path matching `prd`/`prod` as production regardless of what else it says.

## Git

- Branch before committing if on `main`. Never push without being asked.
- Small, focused commits. Match the repo's existing commit style.
- For parallel work use worktrees: `gwt <branch>` creates one at `../<repo>-worktrees/<branch>`.

## Secrets

Never write real credentials into files, logs, or commit messages. `.env`, `*.pem`, and `*.log` are globally gitignored — keep it that way.
