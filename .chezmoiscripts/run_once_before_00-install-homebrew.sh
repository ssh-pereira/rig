#!/bin/bash
# run_once_before_ → runs ONCE per machine, BEFORE any dotfile is written.
#
# This is the bootstrap step. chezmoi installs itself via its own curl one-liner,
# so it does not need Homebrew — which means this script can be the thing that
# brings Homebrew into existence on a brand-new Mac.

set -euo pipefail

echo "▶ Homebrew"

if command -v brew >/dev/null 2>&1; then
  echo "  already installed at $(command -v brew)"
  exit 0
fi

# Xcode Command Line Tools. Homebrew's installer handles this itself, but doing
# it explicitly gives a clearer message about the GUI dialog macOS will show.
if ! xcode-select -p >/dev/null 2>&1; then
  echo "  installing Xcode Command Line Tools (macOS will show a dialog)…"
  xcode-select --install 2>/dev/null || true
  until xcode-select -p >/dev/null 2>&1; do
    sleep 10
    echo "  …waiting for Command Line Tools"
  done
fi

echo "  installing Homebrew…"
NONINTERACTIVE=1 /bin/bash -c \
  "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Put brew on PATH for the rest of THIS script run. ~/.zprofile handles new
# shells, but the scripts that follow need it immediately.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"      # Apple Silicon
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"         # Intel
fi

echo "  done: $(brew --version | head -1)"
