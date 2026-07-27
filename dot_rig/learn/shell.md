# shell — zsh, fzf, and friends

## The three history mechanisms (they're different)

| Key | Does |
|---|---|
| type + **→** | accept the grey inline suggestion (zsh-autosuggestions) |
| **↑** | previous command **starting with what you typed** |
| **Ctrl-R** | fuzzy search *everything you've ever run* (atuin) |

`Ctrl-R` is the powerful one — a SQLite database with timestamps, working directory, exit code, and duration per command.

## fzf — the engine under everything

| Key | Does |
|---|---|
| `Ctrl-T` | fuzzy-pick a file, insert its path into the current command |
| `Alt-C` | fuzzy cd into a subdirectory |
| `**<Tab>` | fuzzy-complete after any command — `vim **<Tab>` |

**Search syntax inside fzf** (most people never learn this):

| Pattern | Matches |
|---|---|
| `foo bar` | fuzzy match both terms |
| `'foo` | exact substring |
| `^foo` | starts with |
| `foo$` | ends with |
| `!foo` | does NOT contain |
| `foo \| bar` | either |

## Navigation

- **`z <partial>`** — zoxide. Jumps to any directory you've visited, ranked by frequency × recency. `z infra` from anywhere.
- **`zi`** — interactive zoxide picker.
- **`fcd`** — fuzzy-pick a project under `~/dev` and cd there.
- **`y`** — yazi file manager; **exits into whatever directory you navigated to**.
- **`cd -`** — back to the previous directory.
- **`..`, `...`, `....`** — up one, two, three levels.
- **`dirs -v`** then `cd -2` — jump to any recent directory by number (`AUTO_PUSHD` is on).

## Things you probably don't know

- **`!!`** — the previous command. `sudo !!` after a permission error.
- **`!$`** — last argument of the previous command. `mkdir foo && cd !$`.
- **`Alt-.`** — cycle through the last arguments of previous commands. Faster than `!$`.
- **`Ctrl-X Ctrl-E`** — open the current command line in `$EDITOR` (Zed). For when a one-liner grew too long.
- **`fc`** — edit and re-run the last command in an editor.
- **`Ctrl-U` / `Ctrl-K`** — delete to start / end of line. **`Ctrl-W`** deletes the previous word. **`Ctrl-Y`** pastes it back.
- **`Ctrl-A` / `Ctrl-E`** — start / end of line. Here `Ctrl-A` needs a **double tap**, because tmux owns it.
- **`Ctrl-Z`** then **`fg`** — suspend a foreground process, do something else, resume it. Works on anything, including a running `claude`.
- **`command foo`** — bypass an alias. `command cat` gives real `cat`, not `bat`.
- **`= foo`** — where does this resolve to? Same as `which`, shorter.
- **`take foo/bar`** — not defined here, but `mkcd foo/bar` does it: mkdir -p plus cd.
- **`extract file.tar.gz`** — unpacks any archive format without remembering flags.
- **`fkill`** — fuzzy-pick a process and kill it.
- **Globbing zsh can do that bash can't:**
  ```bash
  ls **/*.ts          # recursive
  ls *.ts~*test*      # .ts files EXCEPT ones matching test
  ls *(.)             # regular files only
  ls *(/)             # directories only
  ls *(om[1,5])       # 5 most recently modified
  ```

## Per-project environment

- **direnv** — drop a `.envrc` in a project; it loads on `cd` in, unloads on the way out. `direnv allow` once per file (a deliberate security gate).
- **mise** — drop a `.mise.toml`; it pins node/python/terraform versions per project and switches automatically. Replaces nvm/pyenv/tfenv.
- **uv** — Python: `uv venv`, `uv pip install`, `uv run script.py`. Roughly 50× faster than pip.

## Reading files

| Command | Does |
|---|---|
| `cat f` | bat — syntax highlighted (aliased) |
| `catn f` | bat with line numbers and decorations |
| `rg foo` | search contents; `rg -l` filenames only; `rg -A3 -B3` with context |
| `fd foo` | find by name; `fd -e ts` by extension |
| `jless f.json` | interactive JSON — fold, search, navigate |
| `glow f.md` | rendered markdown |
| `tldr tar` | practical examples instead of a man page |
| `ast-grep -p 'useState($A)'` | search by **syntax pattern**, not regex |
