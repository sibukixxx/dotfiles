# =============================================================================
# Environment Variables
# =============================================================================
export LANG=ja_JP.UTF-8
export LC_CTYPE=ja_JP.UTF-8
export DOTFILES=$HOME/dotfiles
export XDG_CONFIG_HOME=$HOME/.config

# Editor (prefer nvim)
if command -v nvim &>/dev/null; then
  export EDITOR=nvim
elif command -v vim &>/dev/null; then
  export EDITOR=vim
fi

# =============================================================================
# PATH Configuration (consolidated)
# =============================================================================
typeset -U path  # Remove duplicates from PATH

# Base paths
path=(
  $HOME/.local/bin
  $HOME/.cargo/bin
  /opt/homebrew/bin
  /usr/local/bin
  $path
)

# Homebrew (Apple Silicon vs Intel)
if [[ -d /opt/homebrew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null)"
elif [[ -d /usr/local/Homebrew ]]; then
  eval "$(/usr/local/bin/brew shellenv 2>/dev/null)"
fi

# Go
if command -v go &>/dev/null; then
  export GOPATH=$HOME/godev
  path=($GOPATH/bin $path)
  if [[ "$(uname)" == "Darwin" ]] && command -v brew &>/dev/null; then
    export GOROOT="$(brew --prefix go)/libexec"
  elif [[ -d /usr/local/go ]]; then
    export GOROOT=/usr/local/go
  fi
fi

# Node.js (nodebrew)
[[ -d $HOME/.nodebrew/current/bin ]] && path=($HOME/.nodebrew/current/bin $path)

# pyenv
if [[ -d $HOME/.pyenv ]]; then
  export PYENV_ROOT="$HOME/.pyenv"
  path=($PYENV_ROOT/bin $path)
  eval "$(pyenv init -)" 2>/dev/null
fi

# Google Cloud SDK
if [[ -d /opt/homebrew/Caskroom/google-cloud-sdk ]]; then
  gcloud_bin="$(ls -d /opt/homebrew/Caskroom/google-cloud-sdk/*/google-cloud-sdk/bin 2>/dev/null | head -1)"
  [[ -n "$gcloud_bin" ]] && path=($gcloud_bin $path)
fi

# NVM
export NVM_DIR="$HOME/.config/nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

# Nix (for WSL/Linux)
[[ -f /etc/profile.d/nix.sh ]] && source /etc/profile.d/nix.sh
[[ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]] && source "$HOME/.nix-profile/etc/profile.d/nix.sh"

# =============================================================================
# Zsh Options
# =============================================================================
setopt nonomatch
setopt transient_rprompt
setopt prompt_subst
setopt autopushd
setopt pushd_ignore_dups
setopt auto_cd
setopt list_packed
setopt list_types
setopt no_hup

# Emacs-like key bindings
bindkey -e

# =============================================================================
# Completion
# =============================================================================
autoload -Uz compinit
compinit -u

fpath=(~/.zsh-completions $fpath)

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*:default' menu select=1
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin \
                             /usr/sbin /usr/bin /sbin /bin

# =============================================================================
# History
# =============================================================================
HISTFILE=$HOME/.zsh-history
HISTSIZE=1000000
SAVEHIST=1000000

setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_reduce_blanks
setopt extended_history
setopt share_history

autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

function history-all { history -E 1 }

# =============================================================================
# Prompt
# =============================================================================
gcloud_project_prompt() {
  local dir="$PWD" marker="" project=""
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.gcloud-project" ]]; then
      marker="$dir/.gcloud-project"
      break
    fi
    dir="${dir:h}"
  done
  [[ -z "$marker" ]] && return 0
  project="$(<"$marker")"
  [[ -z "$project" ]] && project="$(gcloud config get-value project 2>/dev/null)"
  [[ -z "$project" ]] && return 0
  print -r "%F{cyan}(gcloud:${project})%f"
}

PS1='[@${HOST%%.*} %1~] $(gcloud_project_prompt)%(!.#.$) '

# VCS info for RPROMPT
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git svn hg
zstyle ':vcs_info:git:*' formats '(%s)-[%b]'
zstyle ':vcs_info:git:*' actionformats '(%s)-[%b|%a]'
zstyle ':vcs_info:*' formats '(%s)-[%b]'
zstyle ':vcs_info:*' actionformats '(%s)-[%b|%a]'
precmd() {
  psvar=()
  LANG=en_US.UTF-8 vcs_info
  [[ -n "$vcs_info_msg_0_" ]] && psvar[1]="$vcs_info_msg_0_"
}
RPROMPT="%1(v|%F{magenta}%1v%f%F{green}[%~]%f|%F{green}[%~]%f)%T"

# =============================================================================
# Auto-install missing CLI tools (macOS only)
# =============================================================================
if [[ "$(uname)" == "Darwin" ]] && command -v brew &>/dev/null; then
  _essential_tools=(eza bat rg fd zoxide fzf ghq sheldon zellij)
  _brew_names=(eza bat ripgrep fd zoxide fzf ghq sheldon zellij)
  _missing_tools=()
  for i in {1..${#_essential_tools[@]}}; do
    command -v "${_essential_tools[$i]}" &>/dev/null || _missing_tools+=("${_brew_names[$i]}")
  done
  if [[ ${#_missing_tools[@]} -gt 0 ]]; then
    echo "Installing missing tools: ${_missing_tools[*]}"
    brew install "${_missing_tools[@]}"
  fi
  unset _essential_tools _brew_names _missing_tools i
fi

# =============================================================================
# Sheldon - Plugin Manager
# =============================================================================
if command -v sheldon &>/dev/null; then
  case "$(uname)" in
    Darwin) eval "$(sheldon --profile macos source)" ;;
    Linux)  eval "$(sheldon --profile linux source)" ;;
    *)      eval "$(sheldon source)" ;;
  esac
else
  # Fallback: Load local scripts if sheldon is not available
  [[ -f ${DOTFILES}/zsh/tools.zsh ]] && source ${DOTFILES}/zsh/tools.zsh
  [[ -f ${DOTFILES}/zsh/peco.zsh ]] && source ${DOTFILES}/zsh/peco.zsh
  [[ -f ${DOTFILES}/zsh/fzf-worktree.zsh ]] && source ${DOTFILES}/zsh/fzf-worktree.zsh
  [[ -f ${DOTFILES}/zsh/alias/common_alias.zsh ]] && source ${DOTFILES}/zsh/alias/common_alias.zsh
  if [[ "$(uname)" == "Darwin" ]]; then
    [[ -f ${DOTFILES}/zsh/mac.zsh ]] && source ${DOTFILES}/zsh/mac.zsh
    [[ -f ${DOTFILES}/zsh/alias/mac_alias.zsh ]] && source ${DOTFILES}/zsh/alias/mac_alias.zsh
  fi
fi

# =============================================================================
# Google Cloud SDK
# =============================================================================
[[ -f '/usr/local/bin/google-cloud-sdk/path.zsh.inc' ]] && source '/usr/local/bin/google-cloud-sdk/path.zsh.inc'
[[ -f '/usr/local/bin/google-cloud-sdk/completion.zsh.inc' ]] && source '/usr/local/bin/google-cloud-sdk/completion.zsh.inc'

# =============================================================================
# Aliases (basic, non-tool-specific)
# =============================================================================
alias vi="nvim"
alias vim="nvim"
alias view="nvim -R"

# Zellij
if command -v zellij &>/dev/null; then
  alias zj="zellij"
  alias zja="zellij attach"
  alias zjl="zellij list-sessions"
  alias zjk="zellij kill-session"
  alias zjka="zellij kill-all-sessions"
  zs() { zellij attach "${1:-main}" 2>/dev/null || zellij -s "${1:-main}" }
fi

# Haskell (via stack)
alias ghc='stack ghc --'
alias ghci='stack ghci --'
alias runhaskell='stack runhaskell --'

# =============================================================================
# Local overrides (optional)
# =============================================================================
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
