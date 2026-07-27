# tmux

Prefix is `Ctrl-a`. Notation `^a d` = Ctrl-a, release, then `d`.

## What it's for

- **Long-lived sessions.** A workspace that survives the terminal closing, an SSH drop, or a reboot. Start something, walk away, come back to it.
- **Detach and reattach from anywhere.** `^a d` leaves it running; `ta name` picks it up — from a different terminal, a different SSH connection, a different computer.
- **Many things visible at once.** Split one window into panes so three agents, a log tail, and a shell are all on screen.
- **Scriptable layouts.** A whole dev environment can be built by a script and reattached later.

## The 10 things worth memorising

| Keys | Does |
|---|---|
| `^a d` | detach — everything keeps running |
| `^a \` / `^a -` | split vertical / horizontal |
| `Ctrl+hjkl` | move between panes, no prefix |
| `^a m` | zoom one pane fullscreen, press again to restore |
| `^a S` | session picker with live CPU + Claude context |
| `^a N` | new named session, from inside tmux |
| `^a c` | new window (tab) |
| `^a 1..9` | jump to window N |
| `^a v` | scroll/copy mode — `/` searches, `y` copies |
| `^a ?` | **list every binding**, searchable |

## Things you probably don't know it does

- **Type into a pane from outside it.**
  ```bash
  tmux send-keys -t api:2.1 "npm test" C-m
  ```
  This is how you script a whole layout, or drive a pane from another script. `C-m` is Enter.

- **`^a ?` lists every binding**, including defaults you never set. Searchable with `/`, quit with `q`. This is the answer to "I forgot the key".

- **`^a :` is a command prompt** (like vim). Any tmux command works there — `new -s foo`, `kill-session -t bar`, `resize-pane -Z`. Every keybinding is just a shortcut for one of these.

- **Sessions are flat, not nested.** There's no parent/child. One server holds a flat list of sessions; a client (terminal window) attaches to one at a time. Creating a session from inside tmux makes a *sibling*.

- **`^a !`** breaks the current pane out into its own window. `^a J` (in some configs) joins it back. Useful when a pane's output outgrows its split.

- **Capture a pane's scrollback to a file.**
  ```bash
  tmux capture-pane -p -S -10000 -t api:1.1 > /tmp/out.txt
  ```
  Grab 10k lines of history from any pane without touching it.

- **`^a q`** flashes pane numbers; press a number to jump straight there. Faster than `Ctrl+hjkl` across four panes.

- **`^a z`** is the stock zoom binding (this config also uses `^a m`).

- **`^a {` / `^a }`** swap the current pane with the previous/next one — rearrange a layout without closing anything.

- **Kill everything except one session:**
  ```bash
  tmux kill-session -a -t keepthis
  ```
  `-a` means "all except the target". The cure for accumulated unnamed sessions.

- **`^a ^a`** sends a literal `Ctrl-a` through — how you reach a *nested* tmux (local outer, remote inner over SSH), and how you get "jump to line start" back in the shell.

- **Sessions auto-save.** tmux-resurrect + tmux-continuum snapshot every 15 minutes and restore after a reboot, including pane contents.

## Custom to this setup

| Keys | Does |
|---|---|
| `^a A` | 3 panes for 3 parallel agents |
| `^a C` | Claude Code left, free shell right |
| `^a G` | lazygit in a new window |
| `^a C-k` | k9s in a new window |
| `^a R` | rename current session |
| `^a r` | reload config |

## Gotchas

- `^a K` is resize-up, **not** k9s — tmux silently lets a later binding overwrite an earlier one, so duplicates fail quietly. Check with `^a ?`.
- Plugins load **last**, so they override anything in `.tmux.conf`. tmux-resurrect owns `^a C-s`.
- Reloading Ghostty does **not** reload tmux. The tmux server is a separate process — use `^a r`.
