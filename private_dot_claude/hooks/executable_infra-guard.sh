#!/usr/bin/env bash
# PreToolUse hook on Bash — advisory only.
#
# Prints a warning to stderr when a command looks like it targets production or is
# irreversible. It does NOT block: exit code is always 0, by Hugo's explicit choice
# to keep the workflow unprompted. The warning lands in Claude's context so the model
# sees it and can raise it before proceeding.
#
# To make this actually blocking later, exit 2 instead of 0 in the warn path.

set -uo pipefail

payload=$(cat)
cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null)

[[ -z "$cmd" ]] && exit 0

warn() { printf '⚠️  INFRA GUARD: %s\n    command: %s\n' "$1" "$cmd" >&2; }

# --- production context detection ---
if printf '%s' "$cmd" | grep -Eq '\b(kubectl|helm|k9s)\b'; then
  ctx=$(kubectl config current-context 2>/dev/null || echo "")
  if printf '%s' "$ctx" | grep -Eqi 'prd|prod'; then
    if printf '%s' "$cmd" | grep -Eq '\b(delete|apply|patch|scale|replace|drain|cordon|rollout restart|exec)\b'; then
      warn "WRITE against a PRODUCTION cluster context ($ctx)"
    fi
  fi
fi

# --- terraform apply/destroy targeting prd ---
if printf '%s' "$cmd" | grep -Eq 'terraform.*\b(apply|destroy)\b|terragrunt.*\b(apply|destroy)\b'; then
  if printf '%s' "$cmd" | grep -Eqi 'prd|prod' || pwd | grep -Eqi '/prd|/prod'; then
    warn "terraform apply/destroy in a PRODUCTION path"
  fi
  if printf '%s' "$cmd" | grep -Eq '\-auto\-approve'; then
    warn "terraform -auto-approve skips the plan review"
  fi
fi

# --- irreversible git ---
if printf '%s' "$cmd" | grep -Eq 'git push .*(--force|-f)( |$)' && \
   ! printf '%s' "$cmd" | grep -q 'force-with-lease'; then
  warn "force push without --force-with-lease can destroy a teammate's commits"
fi

if printf '%s' "$cmd" | grep -Eq 'git (reset --hard|clean -[a-z]*f)'; then
  warn "this discards uncommitted work irreversibly"
fi

# --- secrets about to be committed ---
if printf '%s' "$cmd" | grep -Eq 'git commit'; then
  if command -v gitleaks >/dev/null 2>&1; then
    if ! gitleaks protect --staged --no-banner --redact >/dev/null 2>&1; then
      warn "gitleaks flagged a potential secret in the staged changes"
    fi
  fi
fi

exit 0
