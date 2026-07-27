#!/usr/bin/env bash
# PostToolUse hook — auto-format a file right after Claude writes or edits it.
# Reads the tool payload as JSON on stdin; the edited path is .tool_input.file_path.
# Always exits 0: a formatter failure must never block real work.

set -uo pipefail

payload=$(cat)
file=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

[[ -z "$file" || ! -f "$file" ]] && exit 0

case "$file" in
  *.tf|*.tfvars)
    command -v terraform >/dev/null 2>&1 && terraform fmt "$file" >/dev/null 2>&1
    ;;
  *.ts|*.tsx|*.js|*.jsx|*.json|*.jsonc|*.css)
    # Biome, resolved from the nearest project. Only runs if the repo actually uses it.
    root=$(cd "$(dirname "$file")" && git rev-parse --show-toplevel 2>/dev/null)
    if [[ -n "$root" && -f "$root/biome.json" ]] && command -v bun >/dev/null 2>&1; then
      (cd "$root" && bun run --silent biome format --write "$file" >/dev/null 2>&1)
    fi
    ;;
  *.py)
    command -v uv >/dev/null 2>&1 && uv run --quiet ruff format "$file" >/dev/null 2>&1
    ;;
  *.sh)
    command -v shfmt >/dev/null 2>&1 && shfmt -w "$file" >/dev/null 2>&1
    ;;
esac

exit 0
