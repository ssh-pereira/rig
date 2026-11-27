#!/bin/bash
# Pins GitHub's SSH host keys in ~/.ssh/known_hosts from api.github.com/meta.
#
# ~/.ssh/config sets `StrictHostKeyChecking ask`, so without this the first
# `git push` on a new machine either prompts to trust an unknown key
# (trust-on-first-use) or, non-interactively, fails with "Host key verification
# failed". Fetching the keys over HTTPS from GitHub's API means the TLS
# certificate vouches for them instead.
#
# run_onchange_: bump the line below to force a re-pin (e.g. after GitHub
# rotates a key). Safe to re-run: old github.com entries are replaced, nothing
# else in known_hosts is touched.
# pin version: 1
set -euo pipefail
echo "▶ GitHub host keys"

JQ=$(command -v jq || echo /usr/bin/jq) # macOS ships /usr/bin/jq; brew's may not exist yet
keys=$(curl -fsSL https://api.github.com/meta | "$JQ" -r '.ssh_keys[]')
[[ -n "$keys" ]] || {
  echo "  ⚠ no keys returned from api.github.com/meta — skipped"
  exit 0
}

umask 077
mkdir -p "$HOME/.ssh"
kh="$HOME/.ssh/known_hosts"
touch "$kh"
ssh-keygen -R github.com -f "$kh" >/dev/null 2>&1 || true # also matches hashed entries
rm -f "$kh.old"
while IFS= read -r k; do printf 'github.com %s\n' "$k"; done <<<"$keys" >>"$kh"
chmod 644 "$kh"
echo "  pinned $(wc -l <<<"$keys" | tr -d ' ') keys"
