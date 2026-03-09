# =============================================================================
# Modern CLI Tool Aliases
# =============================================================================

# eza (modern ls replacement)
if command -v eza &>/dev/null; then
  alias ls='eza --icons'
  alias ll='eza -la --icons --git'
  alias la='eza -a --icons'
  alias lt='eza --tree --icons --level=2'
  alias lta='eza --tree --icons -a --level=2'
else
  alias ls='ls -G'
  alias ll='ls -la'
  alias la='ls -A'
fi

# bat (modern cat replacement)
if command -v bat &>/dev/null; then
  alias cat='bat --paging=never'
  alias catp='bat'  # with pager
fi

# fd (modern find replacement)
if command -v fd &>/dev/null; then
  alias find='fd'
fi

# ripgrep (modern grep replacement)
if command -v rg &>/dev/null; then
  alias grep='rg'
fi

# =============================================================================
# Safe Operations
# =============================================================================
alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"

# =============================================================================
# Diff
# =============================================================================
if command -v colordiff &>/dev/null; then
  alias diff='colordiff -u'
else
  alias diff='diff -u'
fi

# =============================================================================
# Navigation
# NOTE: .., ..., .... are now zeno.zsh abbreviations
# =============================================================================
alias pu="pushd"
alias po="popd"

# =============================================================================
# Git Shortcuts
# NOTE: Most git shortcuts are now zeno.zsh abbreviations (see ~/.config/zeno/config.yml)
# Only keeping 'g' as alias since single-char abbr can conflict with zeno
# =============================================================================
alias g='git'

# =============================================================================
# Misc
# =============================================================================
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%Y-%m-%d %H:%M:%S"'
alias week='date +%V'

# =============================================================================
# Codex + Claude Commands Bridge
# =============================================================================
if command -v codex-claude-command &>/dev/null; then
  # Direct command names (Claude custom commands compatibility)
  alias ship='codex-claude-command ship'
  alias commit-push='codex-claude-command commit-push'

  ccmd() { codex-claude-command "$@"; }
  cask() { codex-claude-command ask "$@"; }
  cplan() { codex-claude-command plan "$@"; }
  cspec() { codex-claude-command spec "$@"; }
  cimpl() { codex-claude-command impl "$@"; }
  ctdd() { codex-claude-command tdd "$@"; }
  creview() { codex-claude-command review "$@"; }
  cinterview() { codex-claude-command interview "$@"; }
  cship() { codex-claude-command ship "$@"; }
  ccommit() { codex-claude-command commit-push "$@"; }
  ccreate-skill() { codex-claude-command create-skill "$@"; }
fi
