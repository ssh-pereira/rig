#!/usr/bin/env bash
# Claude Code status line.
# Receives a JSON session payload on stdin; prints one line of ANSI-coloured text.
# Layout:  <model> │ <dir> │ <git branch +dirty> │ <k8s ctx/ns> │ <tf workspace>

set -uo pipefail

payload=$(cat)
j() { printf '%s' "$payload" | jq -r "$1 // empty" 2>/dev/null; }

model=$(j '.model.display_name')
dir=$(j '.workspace.current_dir')
[[ -z "$dir" ]] && dir="$PWD"

DIM='\033[2m'; RESET='\033[0m'
BLUE='\033[34m'; CYAN='\033[36m'; GREEN='\033[32m'
YELLOW='\033[33m'; RED='\033[31m'; MAGENTA='\033[35m'
SEP="${DIM} │ ${RESET}"

out=""

# --- model ---
[[ -n "$model" ]] && out+="${MAGENTA}${model}${RESET}"

# --- directory (basename, or repo-relative) ---
short=$(basename "$dir")
out+="${SEP}${BLUE}${short}${RESET}"

# --- git ---
if branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null); then
  dirty=""
  git -C "$dir" diff --quiet 2>/dev/null || dirty="*"
  git -C "$dir" diff --cached --quiet 2>/dev/null || dirty="${dirty}+"

  # mark when we're inside a worktree rather than the primary checkout
  wt=""
  common=$(git -C "$dir" rev-parse --git-common-dir 2>/dev/null)
  gitdir=$(git -C "$dir" rev-parse --git-dir 2>/dev/null)
  [[ -n "$common" && "$common" != "$gitdir" ]] && wt="⑂"

  out+="${SEP}${GREEN}${wt} ${branch}${YELLOW}${dirty}${RESET}"
fi

# --- kubernetes: only shown when a context is actually set ---
if command -v kubectl >/dev/null 2>&1; then
  ctx=$(kubectl config current-context 2>/dev/null)
  if [[ -n "$ctx" ]]; then
    ns=$(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
    [[ -z "$ns" ]] && ns="default"
    # production contexts render red
    if printf '%s' "$ctx" | grep -Eqi 'prd|prod'; then
      out+="${SEP}${RED}󱃾 ${ctx}/${ns}${RESET}"
    else
      out+="${SEP}${CYAN}󱃾 ${ctx}/${ns}${RESET}"
    fi
  fi
fi

# --- context window usage ---
# Claude Code hands us context_window.used_percentage pre-calculated, so there's
# no need to parse the transcript. Falls back to computing it from raw token
# counts if the field is missing (older CLI versions).
ctx=$(j '.context_window.used_percentage')
if [[ -z "$ctx" ]]; then
  tin=$(j '.context_window.total_input_tokens')
  tout=$(j '.context_window.total_output_tokens')
  size=$(j '.context_window.context_window_size')
  if [[ -n "$size" && "$size" -gt 0 ]] 2>/dev/null; then
    ctx=$(( ( ${tin:-0} + ${tout:-0} ) * 100 / size ))
  fi
fi

if [[ -n "$ctx" ]]; then
  pct=${ctx%.*}                       # drop any decimal part
  [[ -z "$pct" ]] && pct=0
  filled=$(( pct / 10 ))
  [[ $filled -gt 10 ]] && filled=10
  [[ $filled -lt 0 ]] && filled=0
  bar=""
  for ((i = 0; i < 10; i++)); do
    if [[ $i -lt $filled ]]; then bar+="█"; else bar+="░"; fi
  done

  if   [[ $pct -ge 85 ]]; then ccol="$RED"
  elif [[ $pct -ge 60 ]]; then ccol="$YELLOW"
  else                         ccol="$GREEN"
  fi
  out+="${SEP}${ccol}${bar} ${pct}%${RESET}"

  # Publish the percentage so `tmux-stats` can show it in the ^a S session list.
  # $TMUX_PANE is set by tmux in the pane's shell and inherited by Claude Code,
  # so this keys the value to the exact pane — no guessing from the working
  # directory, which would break with two agents in one repo or a worktree.
  # Failures are swallowed: the status line must never error.
  if [[ -n "${TMUX_PANE:-}" ]]; then
    ctxdir="$HOME/.cache/claude/ctx"
    mkdir -p "$ctxdir" 2>/dev/null && printf '%s' "$pct" > "$ctxdir/${TMUX_PANE#%}" 2>/dev/null
  fi
fi

# --- terraform workspace, only inside a terraform dir ---
if [[ -n "$(find "$dir" -maxdepth 1 -name '*.tf' -print -quit 2>/dev/null)" ]]; then
  ws=$(cd "$dir" && terraform workspace show 2>/dev/null)
  if [[ -n "$ws" ]]; then
    if printf '%s' "$ws" | grep -Eqi 'prd|prod'; then
      out+="${SEP}${RED}󱁢 ${ws}${RESET}"
    else
      out+="${SEP}${CYAN}󱁢 ${ws}${RESET}"
    fi
  fi
fi

printf '%b' "$out"
