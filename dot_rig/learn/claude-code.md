# Claude Code

## The five extension surfaces

Knowing which to reach for is most of the skill.

| Surface | Use when | Nature |
|---|---|---|
| **CLAUDE.md** | always-on guidance | context, loaded every session — keep it short |
| **Skills** | knowledge for a task type | loaded on demand |
| **Subagents** | delegation with its own context window | isolation |
| **Hooks** | a rule must be *enforced* | deterministic code, can't hallucinate |
| **MCP** | connecting to an external system | tools |

The rule: **if it must happen, it's a hook. If it's knowledge, it's a skill. If it's a delegation boundary, it's a subagent.**

## CLAUDE.md layering

Files are read from the current directory **upward**, plus the global one. All apply; the most specific wins.

```
~/.claude/CLAUDE.md          generic, every project
~/dev/hill/CLAUDE.md         cross-repo, employer-specific
~/dev/hill/hill/CLAUDE.md    that repo's own (committed, shared with the team)
```

**The test before adding anything global:** *would this be wrong on a different project?* If yes, it doesn't go in global.

## Your subagents

Each runs in a **separate context window** and reports back a summary — the point is that a noisy investigation doesn't fill up your main conversation.

| Agent | Does |
|---|---|
| `terraform-reviewer` | plan blast radius, IAM widening, cost delta, conventions |
| `k8s-debugger` | outside-in cluster diagnosis, read-only by default |
| `pr-reviewer` | correctness + security bugs, concrete failure scenario required |

## Your skills

| Skill | Does |
|---|---|
| `infra-change` | the 8-step Terraform/k8s workflow |
| `incident-response` | stabilise before diagnosing; rollback before forward-fix |
| `parallel-agents` | worktree setup, briefing, collection, failure modes |

## Your hooks

| Hook | Fires |
|---|---|
| `format-after-edit.sh` | PostToolUse on Write/Edit — terraform fmt, Biome, ruff, shfmt |
| `infra-guard.sh` | PreToolUse on Bash — warns on prod kubectl writes, `-auto-approve`, force push, gitleaks hits |

`infra-guard` is **advisory** — it prints to stderr and exits 0, so it never blocks. To make it blocking, change the warn path to `exit 2`.

## Things you probably don't know

- **`/context`** — see exactly what's consuming your context window, broken down.
- **`/compact`** — summarise the conversation and keep going, instead of starting over. Do it around 70–80%.
- **`/clear`** — wipe context entirely. Cheaper and cleaner than `/compact` when starting an unrelated task.
- **`/resume`** — reopen a past conversation. `claude --resume` from the shell.
- **`claude --continue`** — pick up the most recent conversation in this directory. Aliased to `ccc`.
- **`/cost`** — spend for the current session. **`/usage`** — plan limits and rate-limit windows.
- **`/agents`** — create and edit subagents interactively instead of writing frontmatter.
- **`/hooks`** — inspect what hooks are registered and when they fire.
- **`/doctor`** — diagnose an unhealthy installation.
- **`claude -p "prompt"`** — headless, prints and exits. Pipe it: `git diff | claude -p "review this"`.
- **`claude mcp list`** — MCP server health. `claude mcp add --scope user <name> -- <cmd>` to add one.
- **`#` at the start of a message** — Claude adds that fact to CLAUDE.md for you.
- **`Esc`** interrupts. **`Esc Esc`** rewinds to edit an earlier message and re-run from there.
- **`Shift+Tab`** cycles permission modes.
- **Drag a file onto the terminal** to insert its path. Paste an image directly for screenshots.

## Your status line

```
Opus 5 │ bedrock │  main │ ☸ kind-local/default │ ██████░░░░ 67%
```

Model · directory · git branch (`⑂` = worktree) · k8s context · **context window bar**.

Green under 60%, yellow 60–85%, red above 85% — that's your cue to `/compact`.

Claude Code passes the statusline JSON on stdin with `context_window.used_percentage` **pre-calculated**. Other fields available: `context_window.context_window_size`, `total_input_tokens` (current context, not cumulative), `exceeds_200k_tokens`, `cost.total_cost_usd`, `session_id`, `transcript_path`.

## Token usage

`ccusage` reads Claude Code **and** Codex.

| Command | Does |
|---|---|
| `usage` | per day, split by agent and model |
| `usages` | per session — finds the expensive conversation |
| `usagelive` | live burn-rate with projected block cost |

## Parallel agents

One agent, one worktree, one branch. See [tmux.md](tmux.md) and [git.md](git.md).

```bash
gwt fix-auth && claude      # in each of three panes (^a A)
```

Don't parallelise tasks that touch the same files, or where one depends on another's outcome. Agents cannot coordinate — if work needs coordination, it's one task.
