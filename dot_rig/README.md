# 🛩️ The Cockpit

My terminal and AI development setup. What's installed, why it's there, how to use it, and how it all fits together.

Written 2026-07-27. Machine: MacBook M4 Max, macOS 26.5.

> **Quick reference:** run `cheat` in any terminal for the condensed command tables.
> This document is the *explanation*; the cheatsheet is the *lookup*.

---

## Table of contents

1. [The idea](#1-the-idea)
2. [Architecture: what lives where](#2-architecture-what-lives-where)
3. [The terminal layer](#3-the-terminal-layer)
4. [tmux — from zero](#4-tmux--from-zero)
   - [Monitoring: CPU per pane & token usage](#4b-monitoring)
5. [The shell layer](#5-the-shell-layer)
6. [Git](#6-git)
7. [Kubernetes](#7-kubernetes)
8. [Terraform](#8-terraform)
9. [Networking](#9-networking)
10. [The Claude Code layer](#10-the-claude-code-layer)
11. [Running agents in parallel](#11-running-agents-in-parallel)
12. [Every tool, one line each](#12-every-tool-one-line-each)
13. [Learning path](#13-learning-path)
14. [Maintenance and rebuilding](#14-maintenance-and-rebuilding)

---

## 1. The idea

Three principles behind every choice here.

**Personal first, project second.** Everything global is generic and works on any codebase — my machine, my client work, side projects, whatever. Anything specific to one employer or one project lives *next to that project*, never in the global config. Configuration should follow the code it describes, not the person.

**The terminal is the cockpit, not a text box.** A single shell prompt can only do one thing at a time. The point of tmux plus a fast terminal is that several things run at once, stay running when you walk away, and are all visible without switching windows.

**Agents need isolation, not supervision.** Running three AI agents in one directory means they overwrite each other. Running them in three git worktrees means they structurally cannot. The tooling exists to make that isolation cheap.

---

## 2. Architecture: what lives where

The most important thing to understand — three layers, each overriding the one above.

```
┌──────────────────────────────────────────────────────────────┐
│  GLOBAL (~/.claude/, ~/.zshrc, ~/.tmux.conf)                 │
│  Generic. Works on any project. No employer specifics.       │
│  → tool preferences, working style, safety rules             │
└──────────────────────────────────────────────────────────────┘
                            ↓ overridden by
┌──────────────────────────────────────────────────────────────┐
│  DIRECTORY (~/dev/hill/CLAUDE.md)                            │
│  Sits ABOVE the repos, inside no repo. Personal, uncommitted.│
│  → cross-repo context: cloud, environments, repo map         │
└──────────────────────────────────────────────────────────────┘
                            ↓ overridden by
┌──────────────────────────────────────────────────────────────┐
│  PROJECT (<repo>/CLAUDE.md, <repo>/.claude/)                 │
│  Committed. Shared with the team.                            │
│  → build commands, conventions, project agents               │
└──────────────────────────────────────────────────────────────┘
```

**Why this matters:** Claude Code reads `CLAUDE.md` from the current directory upward, plus the global one. All of them apply, with the most specific winning. So a rule like "GCP secrets are named `hill-{descriptor}-{env}`" belongs in the Hill layer — putting it in global would apply it to unrelated projects and produce nonsense.

**The rule I follow:** if a fact would be wrong on a different project, it does not go in global.

### File map

| Path | Layer | Purpose |
|---|---|---|
| `~/.zshrc` | global | shell config, aliases, functions |
| `~/.tmux.conf` | global | multiplexer config |
| `~/.config/ghostty/config` | global | terminal |
| `~/.config/starship.toml` | global | prompt |
| `~/.gitconfig` | global | git defaults + delta |
| `~/.claude/CLAUDE.md` | global | AI working preferences, generic |
| `~/.claude/agents/` | global | 3 generic subagents |
| `~/.claude/skills/` | global | 3 generic workflows |
| `~/.claude/hooks/` | global | 2 deterministic scripts |
| `~/.claude/statusline.sh` | global | Claude Code status bar |
| `~/dev/hill/CLAUDE.md` | directory | Hill cross-repo context |
| `~/dev/hugo/rig/` | — | this documentation |

---

## 3. The terminal layer

### Ghostty

A GPU-accelerated terminal written in Zig, with a genuinely native macOS UI (Swift/AppKit, Metal rendering). It replaced Warp as my default.

**Why over Warp:** Warp is good, but it's an opinionated IDE-like product with its own AI layer that I don't need — I have Claude Code. Ghostty is faster, native, and gets out of the way. **Why over iTerm2:** speed and modern defaults. **Why over WezTerm:** WezTerm wins on cross-platform, but on macOS specifically it doesn't feel native.

**What it does not do:** session persistence. Close the window and your processes die. That's tmux's job — which is by design, not a gap.

**Config:** `~/.config/ghostty/config`

Key settings and why:
- `macos-option-as-alt = true` — makes Option send Alt to the terminal. Needs a full Ghostty **restart**, not just a config reload. Only matters for the secondary `Option+hjkl` pane bindings; the primary ones are `Ctrl+hjkl`.
- `theme = light:Catppuccin Latte,dark:Catppuccin Mocha` — follows macOS appearance automatically.
- `keybind = global:cmd+grave_accent=toggle_quick_terminal` — a drop-down terminal from anywhere, like Guake. Genuinely useful for one-off commands.
- `scrollback-limit = 100000` — long agent output stays readable.

⚠️ **Ghostty does not allow trailing comments on a value line.** `foo = true # comment` is a parse error. Comments must be on their own line. Validate after editing:
```bash
ghostty +validate-config
```

---

## 4. tmux — from zero

I had never used tmux before this setup, so this section is deliberately thorough.

### What problem it solves

Without tmux, one terminal window = one shell = one running thing. Close the window and it dies. With tmux you get many shells inside one window, arranged how you like, that **keep running when you disconnect**.

### The three nouns

```
Session  ──  one per project. Survives closing the terminal entirely.
  └─ Window  ──  a tab inside a session.
       └─ Pane  ──  a split inside a window.
```

A typical day: session `hill` with window 1 = editor, window 2 = split into three agent panes, window 3 = k9s.

### The prefix key

Every tmux command starts with a **prefix**: press `Ctrl-a`, *release*, then press the command key. Written `^a c` = Ctrl-a, release, then `c`.

Default is `Ctrl-b`, which is awkward. I remapped to `Ctrl-a` (the most common choice — most tutorials assume it).

**Side effect:** `Ctrl-a` in the shell normally jumps to line start. Now that needs a **double tap** — `^a ^a`. That's the standard trade and you stop noticing it in a few days.

### The five keys that matter on day one

| Key | Does |
|---|---|
| `^a \` | split left/right |
| `^a -` | split top/bottom |
| `Ctrl+h/j/k/l` | move between panes — **no prefix**, just hold Ctrl |
| `^a m` | zoom one pane fullscreen; press again to restore |
| `^a d` | **detach** — everything keeps running in the background |

> **On the split keys:** the mnemonic pair is `|` (vertical divider) and `-`
> (horizontal), but `|` is **Shift+`\`** on a standard layout — awkward for the most
> frequent operation there is. So `\` and `_` are bound to the same two actions as
> unshifted aliases. Use `^a \` and `^a -` and never reach for Shift.
>
> **On pane navigation:** `Ctrl+hjkl` comes from the **vim-tmux-navigator** plugin
> and is the de-facto standard. The cost is that it takes over `Ctrl+h`, which is
> readline's backspace — use the Delete key instead. `Option+hjkl` is also bound as
> a fallback, but it needs `macos-option-as-alt = true` **plus a full Ghostty
> restart**. Beware `Cmd+H` while reaching for it: that's macOS "hide application".

**Detach is the whole point.** `^a d` drops you back to a normal shell while your agents keep working. Close the terminal. Reboot even. Then `ta hill` and you're exactly where you were.

Why `hjkl` for movement: vim convention — left/down/up/right. Your fingers already rest there.

### Sessions

| Command | Does |
|---|---|
| `tn hill` | new session named `hill` |
| `ta hill` | attach to it |
| `tls` | list all sessions |
| `^a d` | detach from current |
| `^a S` | visual session picker |
| `^a W` | tree of every session/window/pane |

### Windows (tabs)

| Key | Does |
|---|---|
| `^a c` | new window |
| `^a 1`…`9` | jump to window N |
| `Shift+Left/Right` | previous / next window |
| `^a Tab` | last window (toggle) |
| `^a ,` | rename window |

### Panes (splits)

| Key | Does |
|---|---|
| `^a \` / `^a -` | split vertical / horizontal (unshifted; `\|` and `_` also work) |
| `Ctrl+hjkl` | navigate |
| `^a H/J/K/L` | resize (hold to repeat) |
| `^a m` | zoom toggle |
| `^a x` | kill pane |
| `^a v` | copy mode — `v` select, `y` copy, `Esc` exit |

**Copy mode** is how you scroll back. The mouse wheel also works (mouse is on), but copy mode lets you search with `/` like in vim.

### My custom layouts

| Key | Does |
|---|---|
| `^a A` | three panes, for three parallel agents |
| `^a C` | Claude Code left (60%), free shell right |
| `^a G` | lazygit in a new window |
| `^a K` | k9s in a new window |

### Plugins

Managed by **TPM** (tmux plugin manager). `^a I` installs, `^a U` updates, `^a r` reloads config.

- **tmux-sensible** — uncontroversial defaults everyone agrees on.
- **tmux-resurrect** — saves and restores sessions, including pane contents.
- **tmux-continuum** — auto-saves every 15 min and auto-restores after reboot.
- **tmux-yank** — proper macOS clipboard integration.
- **vim-tmux-navigator** — seamless pane navigation.

Together, resurrect + continuum mean **a reboot doesn't lose your layout**.

### First 10 minutes

```bash
tn practice      # new session
^a |             # split
Option+l         # move right
^a m             # zoom
^a m             # unzoom
^a c             # new window
^a 1             # back to window 1
^a d             # detach
tls              # confirm it's still alive
ta practice      # reattach
```

---

### Targets: `-s` vs `-t`

An asymmetry worth internalising, because nearly every tmux subcommand uses it:

| Flag | Meaning | Example |
|---|---|---|
| `-s` | the **name you're giving** something new | `tmux new -s bedrock` |
| `-t` | the **target** — which existing thing to act on | `tmux attach -t bedrock` |

`-t` accepts increasing specificity: `-t bedrock` (session), `-t bedrock:2` (window 2),
`-t bedrock:2.1` (window 2, pane 1). That addressing is what makes tmux scriptable —
`tmux send-keys -t bedrock:2.1 "ls" C-m` types into a specific pane from outside it.

### Sessions are flat — there is no nesting

A common misconception: creating a session from *inside* tmux does **not** make a
child. There is no parent/child relationship anywhere in tmux. Three concepts:

```
        ┌─────────────────── tmux SERVER ───────────────────┐
        │  one background process, holds everything          │
        │                                                    │
        │   session "bedrock"   session "hill"   session "6" │
        │        │                   │                │      │
        │     window 1            window 1        window 1   │
        │      /    \                                        │
        │  pane1   pane2                                     │
        └────────────────────────────────────────────────────┘
                          ▲
                          │ attached to ONE session at a time
                  ┌───────┴────────┐
                  │  CLIENT        │  = a terminal window
                  └────────────────┘
```

| Thing | What it is |
|---|---|
| **Server** | one background process. Survives every terminal closing. |
| **Session** | a workspace. Flat list, no hierarchy. |
| **Client** | a terminal window viewing one session at a time. |

`^a N` runs `new-session` on the server and repoints your client. The old session
goes to `attached_clients=0` and keeps running — which is why unnamed sessions
accumulate if you're not paying attention. `tmux kill-session -a -t <keep>` kills
everything except one.

### Creating and reaching sessions

**It depends on whether you're already inside tmux.**

| Action | Outside tmux | Inside tmux |
|---|---|---|
| Create named session | `tn hill` | `^a N` (prompts; starts in current dir) |
| Go to another session | `ta hill` | `^a S` (picker) |
| Rename current | `tmux rename-session hill` | `^a R` |
| List | `tls` | `^a S` / `^a W` |

`attach` only works from **outside**. Inside you *switch* — tmux refuses to attach
to avoid exactly the confusion below. Forget a binding? `^a :` opens a command
prompt for any tmux command, and `^a ?` lists every binding.

### Real nesting (and when you'd want it)

Actual nesting means running a tmux **client** inside a pane. Same-server nesting
is blocked by default; you have to force it:

```bash
TMUX= tmux new -s inner        # same server, forced — you'll see the same session list
tmux -L other new -s inner     # SEPARATE server on its own socket — cleaner
```

`-L` picks a different socket, so it's a genuinely independent server with its own
sessions. That's the tidier way to experiment.

Once nested, keystrokes are ambiguous and the **outer** session always wins. To
reach the inner one, **double-tap the prefix**:

| Keys | Goes to |
|---|---|
| `^a d` | outer session (detaches it) |
| `^a ^a d` | inner session |

That's what `bind C-a send-prefix` is for.

**The one case that genuinely needs it:** you SSH to a server and run tmux there.
Outer = local, inner = remote. `^a` drives local, `^a ^a` drives remote. Locally,
nesting has no benefit — sessions are already flat, so just make another one.

### Proving detach works

The exercise that makes it click:

```bash
cd ~/dev/hill/bedrock
tmux new -s bedrock
i=0; while true; do i=$((i+1)); echo "still alive: $i"; sleep 1; done
```

Let it reach ~10, then press **Ctrl+a**, release, **d**. You'll see
`[detached (from session bedrock)]`. Now **close the terminal entirely**, open a new
one, and:

```bash
tmux ls              # bedrock: 1 windows   ← no "(attached)" marker
tmux attach -t bedrock
```

The counter is at 40 or 60. It never stopped. That's the whole value proposition:
your work is decoupled from any terminal window.

---

## 4b. Monitoring

Running several agents at once means you need to know what's actually burning CPU.

### CPU per pane — `tmux-cpu`

`top` and `btop` show processes, but they have no idea which tmux pane a process
belongs to. A pane running `claude` is really `zsh → node → children`, so the useful
number is the **sum over each pane's process tree**. That's what `~/.local/bin/tmux-cpu`
does: it snapshots `ps`, builds a parent→child map, then walks the tree from each
pane's PID.

```bash
tcpu           # snapshot
tcpuw          # live, every 2s
tcpuw 5        # live, every 5s
```

```
  PANE                 CMD             CPU%   MEM(MB)  PROCS  TOP PROCESS
  ──────────────────────────────────────────────────────────────────────
▸ cputest:1.1        zsh            198.1      18.2      3  bash
▸ bedrock:1.1        zsh              0.0       4.7      1  -zsh
```

**Reading CPU%:** it's **per-core**. 100% = one core fully saturated. On 16 cores,
400% means four cores busy — not "4× overloaded". Rows turn yellow above 30% and red
above 80%. `▸` marks the active pane in each session.

**Load average** is in the tmux status bar, top right. It's the 1-minute figure. On
16 cores: under 8 is comfortable, ~16 is fully busy, sustained above 20 means work is
queueing and everything feels slow.

> **awk gotcha found while writing this**, worth remembering: an uninitialised awk
> variable used as an array subscript is the **string `""`**, not `0`. So
> `rows[nr] = x` on the first iteration silently writes to `rows[""]`, and `rows[0]`
> stays empty. Always `BEGIN { nr = 0 }`.

### Per-session cockpit view — `^a S`

An fzf popup listing every session with live CPU, memory and Claude context usage:

```
  SESSION            WIN    CPU%    MEM   CTX
→ bedrock              2w   97.2%   412M   73%
  hill                 3w    0.4%    88M   21%
  infra                1w    0.0%     5M      -
```

`Enter` switches · `Ctrl-X` kills · `Ctrl-R` renames · `Esc` cancels.

**Two design decisions worth remembering:**

**Why not tmux's `choose-session -F`.** Its format is expanded *once* when the
list is drawn, and `#(shell command)` in tmux is asynchronous — the value lands
on a later redraw that never happens for a static list, so the columns stayed
permanently blank. (`#()` also doesn't work in `display-message -p` at all, which
makes it easy to mis-diagnose.) An fzf popup renders real values immediately and
gives kill/rename bindings for free.

**Why a daemon.** `tmux-stats --daemon` walks every pane's process tree once
every 3s and writes `~/.cache/tmux/stats`. The picker just reads that file.
Computing per-row on demand would mean one `ps` sweep per visible session on
every keystroke. The daemon self-locks (so re-sourcing the config can't spawn a
second one) and exits when the tmux server does.

**How context % is attributed.** `~/.claude/statusline.sh` writes its
already-computed percentage to `~/.cache/claude/ctx/<pane-id>` on every render.
Keying by **pane id** — from `$TMUX_PANE`, which Claude Code inherits — makes it
exact. The obvious alternative, matching the working directory to the newest
transcript, breaks precisely where you need it most: two agents in one repo, or
agents in git worktrees. A session displays the **highest** reading among its
panes, i.e. the agent closest to running out of room. Readings older than 2
minutes are dropped, so a finished agent stops showing a stale number.

```bash
tmux-stats --show     # the same data as a plain table
```

### Token usage — `ccusage`

One tool covers both agents. It reads Claude Code's session logs
(`~/.claude/projects/**/*.jsonl`) and Codex's local store, and reports them in one
table split by agent and model.

```bash
usage          # per day
usagew         # per week
usagem         # per month
usages         # per session — finds the expensive conversation
usagelive      # live burn-rate monitor with projected block cost
usagecc        # Claude Code only
usagecx        # Codex only
```

`usages` is the one to reach for when a day looks expensive — it attributes cost to
individual sessions so you can see *which* piece of work cost what.

Inside Claude Code there's also `/usage` (plan limits and rate-limit windows) and
`/cost` (current session only). Those are live; `ccusage` is historical.

---

## 5. The shell layer

`~/.zshrc`, rebuilt from 2 lines.

### History

`SHARE_HISTORY` means every open terminal sees commands from every other, immediately. `HIST_IGNORE_ALL_DUPS` prevents the same command filling the buffer. 100k entries.

### The tools initialised, and why each

**starship** — the prompt. Config at `~/.config/starship.toml`. Two lines: context above, a clean caret below, so long commands don't wrap awkwardly. It shows the k8s context and namespace whenever one is set, and **production contexts render red**. That's a safety feature — the prompt tells you what you're pointed at before you type a destructive command.

**zoxide** — a smarter `cd` that learns. After visiting `~/dev/hill/infrastructure` once, `z infra` jumps there from anywhere. It ranks by frequency × recency. This replaces most `cd ../../..` chains.

**atuin** — replaces `Ctrl-R`. Your shell history becomes a searchable SQLite database with timestamps, working directory, exit code, and duration. Fuzzy search across everything you've ever run. Configured with `--disable-up-arrow` so Up-arrow still does normal prefix search — atuin only takes `Ctrl-R`.

**direnv** — per-directory environment. Drop a `.envrc` in a project and it loads on `cd` in, unloads on `cd` out. Run `direnv allow` once per file (a security gate — it won't auto-run a file you haven't approved).

**mise** — per-project runtime versions. A `.mise.toml` pins node/python/terraform per repo and switches automatically. Replaces nvm/pyenv/tfenv with one tool.

**fzf** — the fuzzy finder everything else builds on:
- `Ctrl-T` — insert a file path into the current command
- `Alt-C` — cd into a subdirectory
- Previews are wired up: files render through `bat`, directories through `eza --tree`

### Functions worth knowing

| Function | Does |
|---|---|
| `mkcd <dir>` | mkdir + cd in one |
| `fcd` | fuzzy-pick a project under `~/dev`, cd there |
| `fkill` | fuzzy-pick a process, kill it |
| `y` | yazi file manager; **exits into whatever directory you navigated to** |
| `extract <file>` | unpack any archive format |
| `gwt <branch>` | create a worktree + branch, cd there |
| `gwtrm <branch>` | remove worktree, delete branch |

`y` is subtle but great: normally a file manager exits and leaves you where you started. This wrapper writes the final directory to a temp file and cds the shell there.

---

## 6. Git

### delta

Every `git diff`, `git show`, and `git log -p` now renders through **delta** — syntax highlighting, line numbers, and readable word-level highlighting within changed lines. `n`/`N` jump between files.

### difftastic

A **structural** diff — it parses both sides into syntax trees and compares those. Reformatting a file, changing indentation, or moving a function shows as *no semantic change*. Invoke with `git dft`. Use it when a diff is full of noise and you need to see what actually changed.

### lazygit

A full terminal UI for git — `lg`. Stage individual hunks (or individual lines), interactive rebase by moving items up and down, resolve conflicts side by side, browse branches and stashes.

**Worth learning properly.** It teaches you what git can do faster than the CLI does, because the operations are visible instead of memorised.

### Defaults I set, and why

| Setting | Why |
|---|---|
| `pull.rebase = true` | linear history, no noise merge commits |
| `rebase.autoStash` | stop "cannot pull with uncommitted changes" |
| `push.autoSetupRemote` | no more `--set-upstream` on first push |
| `fetch.prune` | delete local refs to branches deleted on the remote |
| `diff.algorithm = histogram` | noticeably better diffs than the default |
| `merge.conflictstyle = zdiff3` | conflict markers show the **original** too, not just both sides — makes resolution far easier |
| `rerere.enabled` | remembers how you resolved a conflict and replays it next time |
| `branch.sort = -committerdate` | `git branch` lists most-recent first |

### Worktrees

The most important git feature for AI work. Explained in [§11](#11-running-agents-in-parallel).

---

## 7. Kubernetes

### The local cluster

A **kind** cluster ("Kubernetes in Docker") named `local` — 1 control-plane + 2 workers, running in OrbStack, with nginx ingress on ports 80/443.

Config: `~/.config/kind/local-cluster.yaml`

```bash
kind get clusters                                              # list
kind delete cluster -n local                                   # destroy
kind create cluster --config ~/.config/kind/local-cluster.yaml # rebuild (~90s)
kind load docker-image myimg:tag -n local                      # load a local image, no registry
```

`kind load docker-image` is the one that isn't obvious: normally a cluster pulls from a registry. This injects an image you built locally straight into the nodes, so the dev loop is build → load → apply, with no push.

**Two workers, not one, on purpose** — so you can see scheduling actually happen: pods spreading across nodes, node affinity, what a drain does.

⚠️ **`kind-local` looks identical to a production cluster in your prompt.** Always check `kubectl config current-context`. The starship prompt shows it, and production contexts turn red.

### Tools

| Tool | What it's for |
|---|---|
| `k9s` | the cockpit — browse pods, tail logs, exec, view events, all keyboard-driven |
| `kubectx` / `kubens` | fuzzy-switch cluster and namespace |
| `stern <pattern>` | tail logs from **every** matching pod at once, colour-coded per pod |
| `kind` | local clusters |
| `dive <image>` | inspect a Docker image layer by layer to find bloat |
| `lazydocker` | container TUI |

`stern` is the daily-driver upgrade: `kubectl logs` handles one pod. With three replicas you don't know which served the failing request. `stern api` tails all three.

### Learn-by-breaking exercises

```bash
# 1. Watch scheduling
kubectl create deployment web --image=nginx --replicas=3
kubectl get pods -o wide          # note the NODE column

# 2. Watch self-healing
kubectl delete pod <one-of-them>  # a replacement appears immediately

# 3. Cause an OOMKill on purpose
kubectl set resources deployment web --limits=memory=8Mi
kubectl get pods                  # CrashLoopBackOff
kubectl describe pod <p>          # Last State: Terminated, Reason: OOMKilled, exit 137

# 4. Break a Service the most common way
kubectl expose deployment web --port=80
kubectl get endpoints web         # has endpoints
kubectl label pods -l app=web app=broken --overwrite
kubectl get endpoints web         # EMPTY — selector no longer matches

# cleanup
kubectl delete deployment web svc/web
```

Exercise 4 is the single most common "the service is down" cause in real clusters, and it's invisible unless you check `endpoints`.

---

## 8. Terraform

| Tool | Purpose |
|---|---|
| `terraform` / `terragrunt` | the IaC itself |
| `terraform-docs` | generate module docs from variables and outputs |
| `infracost` | **monthly cost of a plan, before applying** |
| `trivy config .` | scan IaC for misconfigurations |
| `tflint` | Terraform-specific linting |

### The workflow I follow

Encoded as the `infra-change` skill so Claude follows it too:

```
0. Read the repo's conventions      (they differ per project — never assume)
1. Name the target environment      (ambiguity here is the expensive mistake)
2. terraform fmt && validate
3. terraform plan -out=tfplan       (then enumerate the destroys, see below)
4. infracost breakdown --path .
5. trivy config .
6. Review — hand to terraform-reviewer subagent
7. terraform apply tfplan           (the SAVED plan, never a bare apply)
8. terraform plan again             (must come back clean)
```

**Step 3, the destroy check** — the command worth memorising:
```bash
terraform show -json tfplan | jq -r '.resource_changes[] | select(.change.actions[] | . == "delete") | .address'
```
Anything stateful in that list (database, disk, bucket, secret, static IP) means stop. A `-/+` replace on a database is **data loss**, not a change, and it's easy to miss in a long plan.

**Step 7, why the saved plan file matters:** a bare `terraform apply` re-plans at apply time. If anything changed in between — someone else's apply, a data source resolving differently — you apply something you never reviewed. `apply tfplan` applies exactly what you read.

---

## 9. Networking

| Tool | Replaces | Why |
|---|---|---|
| `doggo` | `dig` | readable output, JSON mode, DoH/DoT support |
| `gping` | `ping` | live scrolling latency graph; compare multiple hosts at once |
| `mtr` | `traceroute` + `ping` | continuous per-hop loss and latency — *the* tool for "where is the packet loss" |
| `xh` | `curl` | sane syntax, pretty JSON by default |
| `oha` | `ab` / `wrk` | load testing with a live TUI of latency percentiles |
| `ports` (alias) | — | what's listening on this machine |

**mtr is the one to actually learn.** `traceroute` shows the path once; `mtr` runs continuously and shows loss percentage per hop. When something is "slow sometimes", mtr finds the hop that's dropping packets. Read it carefully though: loss shown at a middle hop that doesn't persist to later hops is usually just that router deprioritising ICMP, not real loss. **Only loss that continues to the final hop is real.**

---

## 10. The Claude Code layer

Five extension surfaces. Knowing which to use for what is most of the skill.

| Surface | Use when | Nature |
|---|---|---|
| **CLAUDE.md** | always-on guidance | context, loaded every session — keep it short |
| **Skills** | contextual knowledge for a task type | loaded on demand |
| **Subagents** | delegation with its own context window | isolation |
| **Hooks** | a rule must be *enforced* | deterministic code, cannot hallucinate |
| **MCP** | connecting to an external system | tools |

The decision rule: **if it must happen, it's a hook. If it's knowledge, it's a skill. If it's a delegation boundary, it's a subagent.**

### CLAUDE.md — `~/.claude/CLAUDE.md`

Generic. Tool preferences, working style, cloud-agnostic infra safety rules, git and secrets policy.

Deliberately contains **no** employer-specific facts. It tells Claude to *detect* the project's toolchain from lockfiles rather than assume one, and to read and defer to the repo's own conventions.

### Subagents — `~/.claude/agents/`

Each runs in a **separate context window** and reports back a summary. That's the real value: a noisy investigation doesn't fill up your main conversation.

- **`terraform-reviewer`** — reads a plan, reports blast radius, IAM widening, cost delta, and convention violations. Reads the repo's conventions first rather than assuming any.
- **`k8s-debugger`** — diagnoses outside-in (events → pod state → describe → logs → resources → networking → config). Read-only by default; proposes destructive commands rather than running them. Always reports the current context first.
- **`pr-reviewer`** — correctness and security bugs in a diff. Requires a concrete failure scenario for every finding, and is explicitly told not to nitpick style.

The diagnostic *order* in `k8s-debugger` is the valuable part: people jump to logs, but events and `describe` hold the answer more often.

### Skills — `~/.claude/skills/`

Folder-based instruction packs loaded when relevant.

- **`infra-change`** — the 8-step Terraform/k8s workflow from §8.
- **`incident-response`** — stabilise before diagnosing; rollback before forward-fix.
- **`parallel-agents`** — worktree setup, briefing, collection, and the failure modes.

### Hooks — `~/.claude/hooks/`

Shell scripts on lifecycle events. **They execute deterministically — they cannot hallucinate or be argued out of.**

**`format-after-edit.sh`** (PostToolUse on Write|Edit) — auto-formats after every file write: `terraform fmt` for `.tf`, Biome for TS/JS *only if the repo has a `biome.json`*, ruff for Python, shfmt for shell. **Always exits 0** — a formatter failure must never block real work.

**`infra-guard.sh`** (PreToolUse on Bash) — warns on:
- kubectl writes against a production context
- `terraform apply`/`destroy` in a prod path
- `-auto-approve`
- force push without `--force-with-lease`
- `git reset --hard` / `git clean -f`
- gitleaks finding a secret in staged changes

**Currently advisory** — it prints to stderr and exits 0, so it never blocks. The warning lands in Claude's context, so the model sees it and can raise it. To make it actually blocking, change the warn path to `exit 2`.

Hooks receive the tool payload as JSON on stdin; `.tool_input.file_path` and `.tool_input.command` are the fields these use.

### Status line — `~/.claude/statusline.sh`

`model │ dir │ git branch (⑂ = worktree) │ k8s ctx/ns │ context bar │ tf workspace`

**Context window bar** — a 10-block meter plus a percentage, green under 60%,
yellow 60–85%, red above 85%. That's your cue to `/compact` or start fresh.

Claude Code passes the statusline a JSON payload on stdin that already contains
`context_window.used_percentage` **pre-calculated**, so there's no transcript
parsing involved. Other useful fields in the same payload:

| Field | What it holds |
|---|---|
| `context_window.used_percentage` | % of the window consumed |
| `context_window.remaining_percentage` | inverse of the above |
| `context_window.context_window_size` | 200,000 — or 1,000,000 on extended-context models |
| `context_window.total_input_tokens` | tokens **currently in context**, not cumulative |
| `exceeds_200k_tokens` | boolean flag |
| `cost.total_cost_usd` | running cost for this session |
| `session_id`, `transcript_path` | identify the conversation |

The script falls back to computing the percentage from raw token counts if
`used_percentage` is absent, and renders nothing at all if there's no context data
— so it can't break on an older CLI.

Production contexts and workspaces render **red**. The `⑂` marker matters when running parallel agents — it tells you at a glance that you're in a worktree rather than the primary checkout.

### MCP servers

Local, user-scope:
- **terraform** — HashiCorp registry docs (via Docker)
- **kubernetes** — cluster access
- **context7** — up-to-date library documentation, which is how you avoid the model writing against an API version from its training data

Plus the claude.ai connectors (Linear, Slack, PostHog, Sentry, Notion, Gmail, Calendar, Drive, Postman) which are account-level, not machine-level.

```bash
claude mcp list                              # check status
claude mcp add --scope user <name> -- <cmd>  # add one
```

### Permissions

`skipDangerousModePermissionPrompt: true` — deliberately on. Maximum speed, no confirmation gate. `infra-guard.sh` provides advisory warnings instead of hard blocks. This is a considered trade, not an oversight; the escape hatch is the `exit 2` change above.

---

## 11. Running agents in parallel

The highest-leverage thing in this whole setup.

### The problem

Two agents in one directory: agent A edits `foo.ts` while agent B is reading it. B's build breaks from A's half-finished change. They fight over the dev server port. Neither produces reliable work.

### The solution: git worktrees

A worktree is **a second working directory for the same repository**, on a different branch, sharing one `.git` object store. Cheap to create, cheap to delete, and structurally isolated.

```bash
gwt fix-auth        # creates ../<repo>-worktrees/fix-auth + branch, cds there
gwt add-export
gwt bump-deps
```

### The workflow

```bash
tn agents           # new tmux session
^a A                # three panes

# in each pane:
cd ../myrepo-worktrees/fix-auth && claude
```

`^a m` zooms a pane when you need to read output properly. `^a d` detaches and leaves all three running.

### Gotchas that will bite you

**Worktrees do not copy gitignored files.** No `node_modules`, no `.env`. Every new worktree needs:
```bash
cp .env ../myrepo-worktrees/fix-auth/.env
(cd ../myrepo-worktrees/fix-auth && bun install)
```

**Port collisions.** Three dev servers all want the same port. Assign different ports per worktree, or only run one at a time.

**Shared external state.** Agents pointed at the same dev database will corrupt each other's test data. Give each its own, or restrict parallel work to tasks that don't touch it.

**Silent divergence.** All three branched from the same `main`. If one lands a change the others depend on, rebase before merging.

### When NOT to do this

- Tasks touching the same files → sequential.
- Task B's design depends on task A's outcome → sequential.
- Anything under ~15 minutes → setup overhead dominates.

Parallelism is for **genuinely independent** work. Agents cannot coordinate; if work needs coordination, it's one task, not several.

### Collecting

```bash
gwl                                    # list worktrees
cd ../myrepo-worktrees/fix-auth
git diff main...HEAD                   # review, rendered by delta
gh pr create --fill
gwtrm fix-auth                         # remove worktree + delete branch
```

Review each branch **separately**. This is the step people skip and regret — three agents producing unreviewed code is worse than one producing reviewed code.

---

## 12. Every tool, one line each

### Terminal
- **Ghostty** — GPU-native macOS terminal, fast, no config archaeology.
- **tmux** — persistent sessions/windows/panes inside one terminal.
- **TPM** — tmux plugin manager (resurrect, continuum, sensible, yank, navigator).

### Shell
- **starship** — fast prompt showing git, k8s context, terraform workspace.
- **zoxide** — `cd` that learns; `z infra` jumps anywhere you've been.
- **atuin** — shell history as a searchable database on `Ctrl-R`.
- **fzf** — fuzzy finder underlying file/dir/history pickers.
- **direnv** — auto-loads `.envrc` per directory.
- **mise** — per-project runtime versions (node, python, terraform).
- **uv** — Python packaging, ~50× faster than pip.

### Files & search
- **fd** — fast file find with sane syntax.
- **rg** (ripgrep) — fast content search.
- **eza** — `ls` with icons, git status, tree mode.
- **bat** — `cat` with syntax highlighting.
- **yazi** — terminal file manager that cds your shell on exit.
- **jless** — interactive JSON viewer.
- **glow** — renders markdown in the terminal.
- **ast-grep** — search code by syntax pattern, not regex.
- **tealdeer** (`tldr`) — practical examples instead of man pages.

### Git
- **lazygit** — full git TUI; hunk staging, interactive rebase, conflict resolution.
- **git-delta** — syntax-highlighted diffs.
- **difftastic** — structural diffs that ignore reformatting.
- **gh** + **gh-dash** — GitHub CLI and a PR/issue dashboard TUI.
- **gitleaks** — secret scanning.

### Containers & Kubernetes
- **OrbStack** — fast Docker/Linux VM for macOS.
- **kind** — local Kubernetes clusters in Docker.
- **k9s** — Kubernetes TUI.
- **kubectx / kubens** — fuzzy context and namespace switching.
- **stern** — multi-pod log tailing.
- **dive** — Docker image layer inspection.
- **lazydocker** — container TUI.
- **helm** — Kubernetes package manager.

### Infrastructure
- **terraform / terragrunt** — IaC.
- **terraform-docs** — module documentation generator.
- **infracost** — monthly cost of a plan before applying.
- **trivy** — IaC and container vulnerability scanning.
- **tflint** — Terraform linting.

### Networking
- **doggo** — modern DNS client.
- **gping** — ping with a live graph.
- **mtr** — continuous traceroute + per-hop loss.
- **xh** — modern HTTP client.
- **oha** — load testing with a live TUI.

### AI
- **Claude Code** — primary agent.
- **Codex CLI** — secondary agent.
- **context7 MCP** — current library docs, avoids stale-training-data APIs.

---

## 13. Learning path

Deliberately sequential. Each step is a prerequisite for the next feeling easy.

**Week 1 — tmux only.** Five keys: `^a |`, `^a -`, `Ctrl+hjkl`, `^a m`, `^a d`. Nothing else. Done when detach/attach is automatic and you stop thinking about the prefix.

**Week 2 — lazygit.** Use `lg` instead of git commands. It will teach you hunk staging and interactive rebase faster than the CLI, because the operations are visible.

**Week 3 — break the kind cluster.** Run the exercises in §7. Delete pods, cause OOMKills, break a Service selector. Then point `k8s-debugger` at each and compare its diagnosis to your own. **This is the step that actually builds infra intuition** — it's free, local, and nobody gets paged.

**Week 4 — worktrees.** `gwt` a branch, run one agent in it, review, merge. Then three at once with `^a A`.

**Ongoing — Terraform on something real.** Build something small in your own cloud account: a bucket, a DNS record, a VM. Run the full 8-step workflow including infracost and trivy even though it's trivially small. The workflow is a habit, and habits are built on small changes, not big ones.

---

## 14. Maintenance and rebuilding

### Everyday

```bash
cheat                 # this setup's quick reference
reload                # re-source ~/.zshrc
^a r                  # reload tmux config
ghostty +validate-config
claude mcp list       # check MCP server health
brew update && brew upgrade
^a U                  # update tmux plugins
```

### Rebuilding on a new machine

```bash
# 1. Homebrew, then:
brew install fd zoxide lazygit git-delta atuin direnv mise uv difftastic ast-grep \
  yazi tealdeer kubectx stern kind dive oha doggo mtr gping terraform-docs \
  infracost xh jless glow bat eza fzf ripgrep gh jq btop tmux gitleaks trivy
brew install --cask ghostty

# 2. tmux plugin manager
git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# 3. Copy configs
#    ~/.zshrc  ~/.tmux.conf  ~/.config/ghostty/config  ~/.config/starship.toml
#    ~/.claude/{CLAUDE.md,settings.json,statusline.sh,agents/,skills/,hooks/}
chmod +x ~/.claude/hooks/*.sh ~/.claude/statusline.sh

# 4. Local cluster
kind create cluster --config ~/.config/kind/local-cluster.yaml
kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml

# 5. MCP servers
claude mcp add --scope user terraform -- docker run -i --rm hashicorp/terraform-mcp-server
claude mcp add --scope user kubernetes -- npx -y kubernetes-mcp-server@latest
claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp@latest

# 6. Inside tmux: ^a I to install plugins
```

### Adding to this setup

Keep the layering honest:

- **A tool preference that's true everywhere** → `~/.claude/CLAUDE.md`
- **A repeatable workflow** → a skill in `~/.claude/skills/`
- **A rule that must be enforced** → a hook
- **Anything specific to one employer or project** → that project's directory, never global

The test: *would this be wrong on a different project?* If yes, it does not go in global.
