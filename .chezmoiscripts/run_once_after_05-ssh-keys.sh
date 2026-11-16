#!/bin/bash
# Creates the two GitHub SSH keys on a new machine, if missing:
#   ~/.ssh/github_auth     push/pull           (GitHub → "Authentication key")
#   ~/.ssh/github_signing  commit signatures   (GitHub → "Signing key")
#
# Each key is encrypted with a random 33-byte passphrase that is never shown or
# written to disk: it goes straight into the macOS login Keychain via
# `ssh-add --apple-use-keychain`. The LaunchAgent local.rig.ssh-add reloads both
# keys into the system ssh-agent at every login, so git never prompts — which is
# what lets agents make hundreds of signed commits a day.
set -euo pipefail
echo "▶ SSH keys"
umask 077
mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"

ASK=$(mktemp -t askpass); trap 'rm -f "$ASK"' EXIT
printf '#!/bin/sh\nprintf "%%s\\n" "$KEYPASS"\n' > "$ASK"; chmod 700 "$ASK"
host=$(scutil --get LocalHostName 2>/dev/null || hostname -s)

for k in github_auth github_signing; do
  if [[ -f "$HOME/.ssh/$k" ]]; then echo "  $k exists"; continue; fi
  export KEYPASS; KEYPASS=$(openssl rand -base64 33)
  ssh-keygen -q -t ed25519 -a 100 -N "$KEYPASS" -C "$k@$host $(date +%F)" -f "$HOME/.ssh/$k"
  SSH_ASKPASS="$ASK" SSH_ASKPASS_REQUIRE=force DISPLAY=:0 \
    ssh-add -q --apple-use-keychain "$HOME/.ssh/$k" </dev/null
  unset KEYPASS
  chmod 644 "$HOME/.ssh/$k.pub"
  echo "  created $k — add ~/.ssh/$k.pub to GitHub"
done

launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/local.rig.ssh-add.plist" 2>/dev/null || true
