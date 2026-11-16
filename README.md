# rig

My machine. Provisioning, configuration, and the notes on how to use it — one repo, managed by [chezmoi](https://chezmoi.io).

Setting up a new Mac is one command. Changing something is edit → push → `rig update` everywhere.

---

## Fresh Mac

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply ssh-pereira/rig
```

chezmoi downloads itself (no Homebrew needed), clones this repo, prompts for machine type and identity, then:

1. installs Xcode Command Line Tools and Homebrew
2. runs `brew bundle` against the [Brewfile](Brewfile)
3. writes every dotfile into place
4. installs tmux plugins

**Three things it can't do for you:** sign into your Apple ID (for `mas` apps), click through the Command Line Tools dialog, and sign into 1Password.

Two opt-in steps, kept out of the default run because they change system state:

```bash
RIG_APPLY_MACOS_DEFAULTS=1 chezmoi apply    # default apps, Finder, keyboard
RIG_CREATE_KIND_CLUSTER=1 chezmoi apply     # local 3-node Kubernetes cluster
```

---

## Daily use

| Command | Does |
|---|---|
| `rig update` | pull from GitHub and apply — **run this on every machine** |
| `rig diff` | what would change |
| `rig apply` | apply pending changes |
| `rig edit` | open this repo in the editor |
| `rig add ~/.foo` | start tracking a new file |
| `rig cd` | cd into this repo |

Changing something:

```bash
rig cd
$EDITOR dot_zshrc          # edit the SOURCE, not ~/.zshrc
chezmoi apply              # apply locally
git commit -am "..." && git push
# on every other machine:
rig update
```

Editing `~/.zshrc` directly works too — `chezmoi add ~/.zshrc` pulls the change back into the repo afterwards. `chezmoi diff` shows when the two have drifted apart.

---

## Docs, on every machine

The `dot_rig/` directory deploys to `~/.rig/`, so the documentation travels with the config:

| Command | Opens |
|---|---|
| `cheat` | quick lookup — key → action |
| `rigdoc` | the full explanation of how this setup works |
| `learn tmux` | capability guide for one tool |
| `learn` | fuzzy-pick a tool to read about |

Guides: `tmux` · `git` · `shell` · `kubernetes` · `terraform` · `networking` · `claude-code`.

The distinction: **cheatsheet** is for when you know what you want and forgot the key. **learn** is for finding out what exists.

---

## Layout

```
Brewfile                    everything Homebrew installs
.chezmoi.toml.tmpl          init prompts: machine type + git identity
.chezmoiignore              never-track list (secrets, caches, auth state)

.chezmoiscripts/
  run_once_before_00-install-homebrew.sh    bootstrap
  run_onchange_after_10-brew-bundle.sh.tmpl re-runs when the Brewfile changes
  run_onchange_after_20-tmux-plugins.sh.tmpl
  run_once_after_30-macos-defaults.sh       opt-in
  run_once_after_40-kind-cluster.sh         opt-in

dot_zshrc                   shell: history, plugins, ~90 aliases, functions
dot_tmux.conf               multiplexer: layouts, session picker, plugins
dot_gitconfig.tmpl          templated identity by machine type
dot_gitignore_global

dot_config/
  ghostty/config            terminal
  starship.toml             prompt (git, k8s context, terraform workspace)
  zed/                      editor settings + keymap
  kind/local-cluster.yaml   local Kubernetes

dot_claude/                 Claude Code: CLAUDE.md, agents, skills, hooks, statusline
dot_local/bin/              tmux-cpu, tmux-stats, tmux-sessions
dot_rig/                    → ~/.rig — the docs above
```

### chezmoi naming

| Prefix | Means |
|---|---|
| `dot_foo` | → `~/.foo` |
| `executable_foo` | → `~/foo`, chmod +x |
| `private_foo` | → `~/foo`, mode 600 |
| `foo.tmpl` | rendered as a Go template |
| `run_once_*` | script, runs once per machine |
| `run_onchange_*` | script, re-runs when its content hash changes |
| `run_*_before_` / `_after_` | ordering relative to writing dotfiles |

`run_onchange_` is why editing the Brewfile automatically triggers `brew bundle` on the next `rig update`: the script embeds the Brewfile's hash, so its content changes when the Brewfile does.

---

## Scope

**In:** anything true on *any* machine of mine.

**Out, deliberately:**
- Employer-specific config. `~/dev/hill/CLAUDE.md` lives beside that employer's code, not here.
- Anything in [`.chezmoiignore`](.chezmoiignore) — `~/.claude.json` (MCP auth tokens), shell history, SSH/GPG keys, kubeconfig, caches, `*.local.json`.
- Secrets. They belong in 1Password; chezmoi templates can pull them at apply time.

The test before adding something: *would this be wrong on a different machine?*

---

## Related

Work machines also run [hillmarkets/provisioner-macos](https://github.com/hillmarkets/provisioner-macos) for the company baseline — org apps, licensed fonts, internal tooling. Two commands, separate ownership: they update theirs, I update mine.

---

## Security model

| Area | Choice | Why |
|---|---|---|
| GitHub auth | `~/.ssh/github_auth` (ed25519), GitHub-only via `IdentitiesOnly` | never offered to other hosts |
| Commit signing | separate `~/.ssh/github_signing`, `commit.gpgsign = true` | every commit Verified; revoke independently of push access |
| Key storage | random passphrase → macOS login Keychain, never on disk | a copied key file is useless |
| Unattended use | LaunchAgent `local.rig.ssh-add` loads keys into the system ssh-agent at login | agents commit/push without prompts, but can't extract the keys |
| Host keys | GitHub's keys pinned in `known_hosts` from `api.github.com/meta` | no trust-on-first-use |
| SSH client | `ForwardAgent no`, `HashKnownHosts`, `StrictHostKeyChecking ask` | |
| git | `transfer.fsckObjects`, `protocol.file.allow = user` | reject malformed objects, block file:// submodule tricks |
| Homebrew | analytics off, `HOMEBREW_NO_INSECURE_REDIRECT` | |
| zsh | `compinit` audits completion dirs daily instead of never | catches world-writable fpath injection |

Upgrade path if you want keys that physically can't leave the machine: [Secretive](https://github.com/maxgoedjen/secretive) stores them in the Secure Enclave (`brew install --cask secretive`).

New machine: add both public keys to GitHub → Settings → SSH and GPG keys (one as **Authentication**, one as **Signing**):

```bash
gh ssh-key add ~/.ssh/github_auth.pub    --type authentication --title "$(scutil --get LocalHostName) auth"
gh ssh-key add ~/.ssh/github_signing.pub --type signing        --title "$(scutil --get LocalHostName) signing"
```
