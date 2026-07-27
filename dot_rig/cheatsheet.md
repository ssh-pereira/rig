# 🛩️ Cockpit Cheatsheet

Run `cheat` anytime to open this.

---

## tmux — the window manager for your terminal

**Prefix is `Ctrl-a`.** Press it, release, then press the next key.
Notation: `^a |` means "Ctrl-a, release, then `|`".

### Sessions (one per project)
| Key | Does |
|---|---|
| `tn hill` | new session named `hill` — **from outside tmux** |
| `ta hill` | attach to it — **from outside tmux** |
| `^a N` | new named session — **from inside tmux** (prompts for the name) |
| `^a S` | **session picker with live CPU / mem / Claude context** (fzf popup) |
| `^a s` | tmux's plain built-in picker (fallback) |
| `^a R` | rename the current session |
| `tls` | list sessions |
| `^a d` | **detach** — leave it running in the background |
| `^a W` | tree of every session / window / pane |
| `^a X` | kill current session |

> `attach` only works from **outside** tmux. Inside, you *switch* — `^a S`.
> Sessions are **flat** — `^a N` makes a sibling, never a child.

### Nesting (only useful for tmux-over-SSH)
| Command | Does |
|---|---|
| `TMUX= tmux new -s inner` | force a nested client on the same server |
| `tmux -L other new -s inner` | separate server on its own socket (cleaner) |
| `^a ^a <key>` | send the key to the **inner** session (double-tap) |
| `^a <key>` | goes to the **outer** session |

### Windows (tabs inside a session)
| Key | Does |
|---|---|
| `^a c` | new window |
| `^a 1..9` | jump to window N |
| `Shift+Left/Right` | prev / next window |
| `^a Tab` | last window |
| `^a ,` | rename window |
| `^a &` | kill window |

### Panes (splits inside a window)
| Key | Does |
|---|---|
| `^a \` | split vertical (side by side) — **no Shift needed** |
| `^a \|` | same (`\|` is Shift+`\`) |
| `^a -` | split horizontal (stacked) |
| `Ctrl+h/j/k/l` | move between panes — **no prefix needed** |
| `^a H/J/K/L` | resize (hold to repeat) |
| `^a m` | **zoom** current pane fullscreen / back |
| `^a x` | kill pane |
| `^a v` | scroll/copy mode — `v` select, `y` copy, `Esc` exit |

### Your custom layouts
| Key | Does |
|---|---|
| `^a A` | 3 panes for 3 parallel agents |
| `^a C` | Claude Code left, free shell right |
| `^a G` | lazygit in a new window |
| `^a C-k` | k9s in a new window (plain `K` is resize-up) |

### Plugins
`^a I` install · `^a U` update · `^a r` reload config
Sessions auto-save every 15 min and restore after reboot (resurrect + continuum).

---

## Monitoring

### CPU per pane
| Command | Does |
|---|---|
| `tcpu` | CPU% and memory **per tmux pane**, summed over each pane's whole process tree |
| `tcpuw` | same, live, refreshing every 2s |
| `tcpuw 5` | live, every 5s |
| `btop` | whole-machine monitor |

CPU% is **per-core**: 100% = one full core saturated. You have 16 cores, so 400% is
four cores busy, not "4× overloaded". Rows go yellow above 30%, red above 80%.

The tmux status bar shows the **1-minute load average** top-right. Rule of thumb on
16 cores: under 8 is comfortable, ~16 is fully busy, sustained above 20 means queueing.

### Per-session view — `^a S`
An fzf popup listing every session with live CPU, memory and Claude context %.

```
  SESSION            WIN    CPU%    MEM   CTX
→ bedrock              2w   97.2%   412M   73%
  hill                 3w    0.4%    88M   21%
  infra                1w    0.0%     5M      -
```

| Key | Does |
|---|---|
| `Enter` | switch to that session |
| `Ctrl-X` | kill it |
| `Ctrl-R` | rename it |
| `Esc` | cancel |

`ctx` only appears for sessions actually running Claude Code, and disappears
~2 min after the agent exits. `cheat`'s numbers come from a background daemon
(`tmux-stats`) that refreshes every 3s.

| Command | Does |
|---|---|
| `tmux-stats --show` | same data as a plain table |

### AI token usage
`ccusage` reads Claude Code **and** Codex from their local logs.

| Command | Does |
|---|---|
| `usage` | tokens + cost per day, split by agent and model |
| `usagew` / `usagem` | by week / by month |
| `usages` | by session — finds which conversation was expensive |
| `usagelive` | **live burn-rate monitor** with projected block cost |
| `usagecc` / `usagecx` | Claude Code only / Codex only |

Inside Claude Code itself: `/usage` for plan limits, `/cost` for the current session.

---

## Navigation & files
| Command | Does |
|---|---|
| `z hill` | jump to any dir you've visited by fuzzy name (zoxide) |
| `fcd` | fuzzy-pick a project under `~/dev` and cd there |
| `y` | yazi file manager — exits into whatever dir you're in |
| `Ctrl-T` | fuzzy-insert a file path into the current command |
| `Alt-C` | fuzzy cd into a subdirectory |
| `Ctrl-R` | fuzzy search your entire shell history (atuin) |
| `ll` / `la` / `lt` | eza listings — long / all / tree |
| `cat f` | bat — syntax-highlighted cat |
| `rg foo` | ripgrep — search file contents fast |
| `fd foo` | find files by name fast |
| `mkcd d` | mkdir + cd in one |
| `fkill` | fuzzy-pick a process and kill it |

---

## Git
| Command | Does |
|---|---|
| `lg` | **lazygit** — stage, commit, branch, rebase in a TUI. Live here. |
| `gs` | short status |
| `gd` / `gds` | diff / staged diff (rendered by delta) |
| `git dft` | semantic diff — compares syntax trees, not lines (difftastic) |
| `gl` | pretty commit graph |
| `ghd` | **gh dash** — all your PRs and issues in one TUI |

### Worktrees — the key to parallel agents
| Command | Does |
|---|---|
| `gwt feature-x` | create branch + worktree at `../<repo>-worktrees/feature-x`, cd there |
| `gwl` | list worktrees |
| `gwtrm feature-x` | remove the worktree and delete the branch |

Each worktree is a separate directory on its own branch sharing one `.git`.
Point one agent at each — they can never collide.

---

## Kubernetes
| Command | Does |
|---|---|
| `k9s` | **the cockpit** — browse pods/logs/exec/events in a TUI |
| `kx` | switch cluster context (fuzzy) |
| `kn` | switch namespace (fuzzy) |
| `k get pods` | kubectl shorthand |
| `stern api` | tail logs from *every* pod matching `api` at once |
| `kind create cluster` | spin up a local k8s cluster in Docker |
| `lzd` | lazydocker — container TUI |
| `dive <image>` | inspect a Docker image layer by layer |

Your prompt shows the current cluster + namespace. **Production contexts turn red.**

### Your local cluster
A 3-node kind cluster named `local` is running, with nginx ingress on ports 80/443.

| Command | Does |
|---|---|
| `kubectl get nodes` | see your 3 nodes |
| `kind get clusters` | list local clusters |
| `kind delete cluster -n local` | tear it down |
| `kind create cluster --config ~/.config/kind/local-cluster.yaml` | rebuild it |
| `kind load docker-image myimg:tag -n local` | push a local image into the cluster (no registry needed) |

Try it:
```bash
kubectl create deployment web --image=nginx --replicas=3
kubectl expose deployment web --port=80
kubectl get pods -o wide          # watch them spread across nodes
stern web                         # tail all 3 at once
k9s                               # then browse it visually
kubectl delete deployment web svc/web
```

---

## Terraform
| Command | Does |
|---|---|
| `tfi` / `tfp` / `tfa` | init / plan / apply |
| `tff` | format everything recursively |
| `terraform-docs markdown .` | auto-generate module docs |
| `infracost breakdown --path .` | **cost of your plan before you apply it** |
| `trivy config .` | scan IaC for misconfigurations |
| `tg` | terragrunt |

---

## Networking
| Command | Does |
|---|---|
| `ports` | what's listening on this machine |
| `myip` / `localip` | public / LAN IP |
| `doggo example.com` | modern DNS lookup (replaces dig) |
| `gping 1.1.1.1` | ping with a live graph |
| `mtr example.com` | traceroute + ping combined, continuously |
| `xh GET api.com/x` | modern curl — pretty JSON by default |
| `oha -n 1000 url` | load-test an endpoint |

---

## Misc
| Command | Does |
|---|---|
| `tldr tar` | practical examples instead of a man page |
| `jless data.json` | interactive JSON viewer |
| `glow README.md` | render markdown in the terminal |
| `btop` | system monitor |
| `reload` | re-source `.zshrc` |
| `ast-grep -p 'useState($A)'` | search code by **syntax pattern**, not regex |

---

## Environment
- **direnv** — drop a `.envrc` in a project, it auto-loads on cd. Run `direnv allow` once.
- **mise** — drop a `.mise.toml`, it pins node/python/terraform versions per project.
- **uv** — instant Python envs: `uv venv`, `uv pip install`, `uv run script.py`.
