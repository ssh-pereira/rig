# Brewfile — everything Homebrew installs on my machines.
#
# Generated from a real machine with `brew bundle dump`, then grouped and
# commented by hand so it stays readable. Applied by
# .chezmoiscripts/run_onchange_after_10-brew-bundle.sh.tmpl, which re-runs
# automatically whenever this file changes.
#
#   brew bundle check     what's missing
#   brew bundle install   install it
#   brew bundle cleanup   list things installed but NOT in this file

# ═══════════════════════════════════════════════════════════════
#  Taps  (trusted: true is required for third-party taps)
# ═══════════════════════════════════════════════════════════════
tap "hashicorp/tap", trusted: true          # terraform
tap "supabase/tap", trusted: true           # supabase CLI
tap "teamookla/speedtest", trusted: true    # official speedtest
tap "terraform-linters/tap", trusted: true  # tflint

# ═══════════════════════════════════════════════════════════════
#  Shell
# ═══════════════════════════════════════════════════════════════
brew "starship"                 # the prompt (git, k8s ctx, terraform workspace)
brew "zsh-autosuggestions"      # greyed-out inline completion from history
brew "zsh-syntax-highlighting"  # green = real command, red = typo
brew "zsh-completions"          # ~200 extra tab-completion definitions
brew "atuin"                    # shell history as a searchable DB on Ctrl-R
brew "zoxide"                   # `z hill` jumps to any dir you've visited
brew "direnv"                   # auto-loads .envrc per directory
brew "mise"                     # per-project node/python/terraform versions
brew "tmux"                     # terminal multiplexer

# ═══════════════════════════════════════════════════════════════
#  Files & search
# ═══════════════════════════════════════════════════════════════
brew "fzf"                      # fuzzy finder everything else builds on
brew "fd"                       # fast file find, sane syntax
brew "ripgrep"                  # fast content search
brew "eza"                      # ls with icons, git status, tree mode
brew "bat"                      # cat with syntax highlighting
brew "yazi"                     # TUI file manager
brew "tree"
brew "jless"                    # interactive JSON viewer
brew "glow"                     # render markdown in the terminal
brew "jq"                       # JSON processor
brew "ast-grep"                 # search code by syntax pattern, not regex
brew "tealdeer"                 # `tldr` — examples instead of man pages

# ═══════════════════════════════════════════════════════════════
#  Git
# ═══════════════════════════════════════════════════════════════
brew "gh"                       # GitHub CLI
brew "lazygit"                  # git TUI — hunk staging, interactive rebase
brew "git-delta"                # syntax-highlighted diffs
brew "difftastic"               # structural diffs that ignore reformatting
brew "gitleaks"                 # secret scanning

# ═══════════════════════════════════════════════════════════════
#  Containers & Kubernetes
# ═══════════════════════════════════════════════════════════════
brew "kubernetes-cli"           # kubectl
brew "k9s"                      # Kubernetes TUI
brew "kubectx"                  # fuzzy context + namespace switching
brew "stern"                    # tail logs from every matching pod at once
brew "kind"                     # local Kubernetes clusters in Docker
brew "helm"
brew "dive"                     # inspect Docker image layers
brew "lazydocker"               # container TUI

# ═══════════════════════════════════════════════════════════════
#  Infrastructure
# ═══════════════════════════════════════════════════════════════
brew "hashicorp/tap/terraform"
brew "terragrunt"
brew "terraform-docs"           # generate module docs from variables/outputs
brew "infracost"                # monthly cost of a plan BEFORE applying
brew "trivy"                    # IaC + container vulnerability scanning
brew "cloud-sql-proxy"
brew "supabase/tap/supabase"

# ═══════════════════════════════════════════════════════════════
#  Networking
# ═══════════════════════════════════════════════════════════════
brew "doggo"                    # modern DNS client (replaces dig)
brew "gping"                    # ping with a live latency graph
brew "mtr"                      # continuous traceroute + per-hop loss
brew "xh"                       # modern HTTP client (replaces curl for APIs)
brew "oha"                      # load testing with a live TUI
brew "caddy"                    # local HTTPS reverse proxy
brew "cloudflared"
brew "dnsmasq"
brew "nss"
brew "teamookla/speedtest/speedtest"

# ═══════════════════════════════════════════════════════════════
#  Languages & runtimes
# ═══════════════════════════════════════════════════════════════
brew "bun"                      # JS runtime + package manager
brew "node@24"
brew "uv"                       # Python packaging, ~50x faster than pip

# ═══════════════════════════════════════════════════════════════
#  System
# ═══════════════════════════════════════════════════════════════
brew "btop"                     # system monitor
brew "chezmoi"                  # this repo's own manager
brew "mas"                      # Mac App Store CLI
brew "dockutil"                 # scripted Dock management
brew "defaultbrowser"           # set default browser from the CLI
brew "duti"                     # set default app per file type
brew "xcodegen"                 # generate .xcodeproj from project.yml
brew "stripe-cli"

# ═══════════════════════════════════════════════════════════════
#  Terminal & editors
# ═══════════════════════════════════════════════════════════════
cask "ghostty"                  # primary terminal — GPU-native, macOS-native
cask "warp"                     # kept as a secondary
cask "zed"                      # primary editor
cask "cursor"                   # for large agentic refactors

# ═══════════════════════════════════════════════════════════════
#  AI agents
# ═══════════════════════════════════════════════════════════════
cask "claude"                   # desktop app
cask "claude-code@latest"       # the CLI
cask "codex"                    # Codex CLI
cask "codex-app"
brew "opencode"

# ═══════════════════════════════════════════════════════════════
#  Dev tooling
# ═══════════════════════════════════════════════════════════════
cask "orbstack"                 # fast Docker/Linux VM for macOS
cask "docker-desktop"
cask "postman"
cask "tableplus"
cask "dbeaver-community"
cask "ngrok"
cask "gcloud-cli"
cask "terraform-linters/tap/tflint"
cask "gpg-suite"

# ═══════════════════════════════════════════════════════════════
#  Productivity
# ═══════════════════════════════════════════════════════════════
cask "1password"
cask "1password-cli"            # secret resolution for chezmoi templates
cask "raycast"                  # launcher
cask "rectangle"                # window snapping
cask "alt-tab"                  # real Windows-style alt-tab
cask "maccy"                    # clipboard history
cask "hammerspoon"              # scriptable macOS automation

# ═══════════════════════════════════════════════════════════════
#  Comms & apps
# ═══════════════════════════════════════════════════════════════
cask "slack"
cask "linear"
cask "notion"
cask "obsidian"
cask "granola"
cask "superhuman"
cask "figma"
cask "google-chrome"
cask "google-drive"
cask "discord"
cask "signal"
cask "beeper"
cask "zoom"
cask "utm"                      # virtual machines

# ═══════════════════════════════════════════════════════════════
#  Fonts
# ═══════════════════════════════════════════════════════════════
cask "font-geist"
cask "font-geist-mono"                  # terminal + editor typeface
cask "font-symbols-only-nerd-font"      # icon fallback for the prompt glyphs
cask "font-inter"
cask "font-inter-tight"

# ═══════════════════════════════════════════════════════════════
#  Mac App Store  (requires being signed in)
# ═══════════════════════════════════════════════════════════════
mas "WireGuard", id: 1451685025
mas "Xcode", id: 497799835
mas "Keynote", id: 409183694
mas "Numbers", id: 409203825
mas "Pages", id: 409201541
mas "iMovie", id: 408981434
mas "GarageBand", id: 682658836
