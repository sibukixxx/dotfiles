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
# =============================================================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias pu="pushd"
alias po="popd"

# =============================================================================
# Git Shortcuts
# =============================================================================
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'

# =============================================================================
# Misc
# =============================================================================
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%Y-%m-%d %H:%M:%S"'
alias week='date +%V'
