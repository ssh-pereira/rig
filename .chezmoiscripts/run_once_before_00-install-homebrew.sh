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
# NONINTERACTIVE skips the "Press RETURN" prompt but also refuses to ask for a
# password: it needs a sudo session that's already open, or it aborts with
# "Insufficient permissions to install Homebrew". So open one first. `sudo -v`
# asks for the password once in this terminal; the installer's own `sudo -n`
# calls then reuse that session (same tty, within sudo's 5-minute timeout).
if ! sudo -n true 2>/dev/null; then
  echo "  Homebrew needs admin rights to create /opt/homebrew — enter your password:"
  sudo -v
fi
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
