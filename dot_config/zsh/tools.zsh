# =============================================================================
# zoxide - smarter cd command
# =============================================================================
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
  # Aliases
  alias cd="z"
  alias cdi="zi"  # interactive selection
fi

# =============================================================================
# fzf - fuzzy finder
# =============================================================================
if command -v fzf &>/dev/null; then
  # fzf default options
  export FZF_DEFAULT_OPTS='
    --height 60%
    --reverse
    --border
    --preview-window=right:50%
    --bind=ctrl-k:kill-line
    --bind=ctrl-u:half-page-up
    --bind=ctrl-d:half-page-down
  '

  # Use fd for faster file finding if available
  if command -v fd &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi

  # Load fzf key bindings and completion (platform-specific paths)
  local fzf_base=""
  if [[ "$(uname)" == "Darwin" ]] && command -v brew &>/dev/null; then
    fzf_base="$(brew --prefix)/opt/fzf/shell"
  elif [[ -d "$HOME/.nix-profile/share/fzf/shell" ]]; then
    fzf_base="$HOME/.nix-profile/share/fzf/shell"
  elif [[ -d "/usr/share/doc/fzf/examples" ]]; then
    fzf_base="/usr/share/doc/fzf/examples"
  fi

  if [[ -n "$fzf_base" ]]; then
    [[ -f "$fzf_base/key-bindings.zsh" ]] && source "$fzf_base/key-bindings.zsh"
    [[ -f "$fzf_base/completion.zsh" ]] && source "$fzf_base/completion.zsh"
  fi

  # Preview with bat if available
  if command -v bat &>/dev/null; then
    export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
  fi
fi

# =============================================================================
# ghq - remote repository management
# =============================================================================
if command -v ghq &>/dev/null; then
  # Set ghq root (default: ~/ghq)
  export GHQ_ROOT="${GHQ_ROOT:-$HOME/ghq}"

  # ghq + fzf: fuzzy find and cd to repository
  function ghq-fzf() {
    local selected
    selected=$(ghq list | fzf --preview "bat --color=always --style=plain $(ghq root)/{}/README.md 2>/dev/null || ls -la $(ghq root)/{}")
    if [[ -n "$selected" ]]; then
      cd "$(ghq root)/$selected"
      zle reset-prompt
    fi
  }
  zle -N ghq-fzf
  bindkey '^g' ghq-fzf

  # ghq get with auto-cd
  function gg() {
    ghq get "$@"
    local repo=$(ghq list | grep -E "$(echo "$1" | sed 's|.*/||')" | head -1)
    if [[ -n "$repo" ]]; then
      cd "$(ghq root)/$repo"
    fi
  }

  # ghq list with fzf (simpler version, works without zle)
  function gcd() {
    local selected
    selected=$(ghq list --full-path | fzf --height 40% --reverse)
    if [[ -n "$selected" ]]; then
      cd "$selected"
    fi
  }
fi

# =============================================================================
# Combined fzf functions
# =============================================================================

# History search with fzf
function fzf-history-widget() {
  local selected
  selected=$(fc -rl 1 | fzf --no-sort --query="$LBUFFER" | sed 's/^ *[0-9]* *//')
  if [[ -n "$selected" ]]; then
    LBUFFER="$selected"
  fi
  zle redisplay
}
zle -N fzf-history-widget
bindkey '^r' fzf-history-widget

# Find and edit file with fzf
function fe() {
  local file
  file=$(fzf --preview 'bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || cat {}')
  if [[ -n "$file" ]]; then
    ${EDITOR:-nvim} "$file"
  fi
}

# Find and cd to directory with fzf
function fcd() {
  local dir
  dir=$(find . -type d 2>/dev/null | fzf --preview 'ls -la {}')
  if [[ -n "$dir" ]]; then
    cd "$dir"
  fi
}

# Git branch checkout with fzf
function fbr() {
  local branch
  branch=$(git branch -a | fzf | sed 's/^[ *]*//' | sed 's|remotes/origin/||')
  if [[ -n "$branch" ]]; then
    git checkout "$branch"
  fi
}

# Git log with fzf
function flog() {
  git log --oneline --color=always | fzf --ansi --preview 'git show --color=always {1}'
}
