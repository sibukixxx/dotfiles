# =============================================================================
# Linux/WSL specific settings
# =============================================================================

# Detect if running in WSL
if grep -qi microsoft /proc/version 2>/dev/null; then
  export IS_WSL=1

  # WSL-specific settings
  # Access Windows home directory
  export WIN_HOME="/mnt/c/Users/$(cmd.exe /c 'echo %USERNAME%' 2>/dev/null | tr -d '\r')"

  # Open files/URLs with Windows default application
  alias open='wslview'
  alias xdg-open='wslview'

  # Clipboard integration (requires win32yank or similar)
  if command -v win32yank.exe &>/dev/null; then
    alias pbcopy='win32yank.exe -i'
    alias pbpaste='win32yank.exe -o'
  elif command -v clip.exe &>/dev/null; then
    alias pbcopy='clip.exe'
    alias pbpaste='powershell.exe -command "Get-Clipboard"'
  fi

  # Explorer integration
  alias explorer='explorer.exe'
  alias e.='explorer.exe .'
fi

# =============================================================================
# Nix integration
# =============================================================================
if [[ -d "$HOME/.nix-profile" ]]; then
  # fzf key bindings from Nix
  if [[ -f "$HOME/.nix-profile/share/fzf/shell/key-bindings.zsh" ]]; then
    source "$HOME/.nix-profile/share/fzf/shell/key-bindings.zsh"
  fi
  if [[ -f "$HOME/.nix-profile/share/fzf/shell/completion.zsh" ]]; then
    source "$HOME/.nix-profile/share/fzf/shell/completion.zsh"
  fi
fi

# =============================================================================
# Linux-specific paths
# =============================================================================
export PATH="$HOME/.local/bin:$PATH"

# Go (if installed via system package manager)
if [[ -d "/usr/local/go" ]]; then
  export GOROOT=/usr/local/go
  export PATH=$GOROOT/bin:$PATH
fi
