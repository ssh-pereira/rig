#!/bin/bash
# macOS defaults and default-app handlers.
#
# DISABLED BY DEFAULT. This is the only script here that changes system-wide
# behaviour rather than just installing things, so it's opt-in: set
# RIG_APPLY_MACOS_DEFAULTS=1 to let it run.
#
#   RIG_APPLY_MACOS_DEFAULTS=1 chezmoi apply
#
# Reasoning: reinstalling a tool is harmless, but silently reassigning which app
# opens every .ts file on a machine is the kind of surprise that makes you
# distrust your own automation.

set -euo pipefail

if [[ "${RIG_APPLY_MACOS_DEFAULTS:-0}" != "1" ]]; then
  echo "▶ macOS defaults — skipped (set RIG_APPLY_MACOS_DEFAULTS=1 to apply)"
  exit 0
fi

echo "▶ macOS defaults"

# ---------- Default browser ----------
if command -v defaultbrowser >/dev/null 2>&1; then
  defaultbrowser chrome 2>/dev/null && echo "  default browser → Chrome"
fi

# ---------- Default terminal ----------
# Ghostty, not Warp: Ghostty is the daily driver in this setup.
if command -v duti >/dev/null 2>&1 && [[ -d /Applications/Ghostty.app ]]; then
  duti -s com.mitchellh.ghostty public.unix-executable all 2>/dev/null
  duti -s com.mitchellh.ghostty public.shell-script all 2>/dev/null
  echo "  terminal handler → Ghostty"
fi

# ---------- Default editor for source files ----------
if command -v duti >/dev/null 2>&1 && [[ -d /Applications/Zed.app ]]; then
  ZED_ID="dev.zed.Zed"
  for ext in ts tsx js jsx json jsonc md markdown yml yaml toml tf tfvars hcl \
             sh bash zsh py rb go rs swift sql graphql css scss html xml \
             txt log conf ini env lock mjs cjs mts cts vue svelte astro; do
    duti -s "$ZED_ID" ".$ext" all 2>/dev/null || true
  done
  echo "  source-file handler → Zed"
fi

# ---------- Finder ----------
defaults write com.apple.finder AppleShowAllFiles -bool true          # show dotfiles
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true  # no .DS_Store on network shares

# ---------- Keyboard ----------
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false    # key repeat instead of accent menu
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# ---------- Screenshots ----------
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location "$HOME/Screenshots"
defaults write com.apple.screencapture disable-shadow -bool true

# ---------- Misc ----------
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001          # instant window resize
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.15

killall Finder 2>/dev/null || true
killall Dock 2>/dev/null || true

echo "  done — some changes need a logout to fully apply"
