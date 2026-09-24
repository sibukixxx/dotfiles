# =============================================================================
# Linux/WSL specific settings
# =============================================================================

# Detect if running in WSL
if grep -qi microsoft /proc/version 2>/dev/null; then
  export IS_WSL=1

  # WSL-specific settings
  # Access Windows home directory
  # (プロファイルのフォルダ名はユーザー名と一致しないことがあるため %USERPROFILE% から解決)
  if command -v cmd.exe &>/dev/null && command -v wslpath &>/dev/null; then
    export WIN_HOME="$(wslpath "$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')" 2>/dev/null)"
  fi

  # Open files/URLs with Windows default application
  if command -v wslview &>/dev/null; then
    alias open='wslview'
    alias xdg-open='wslview'
    [[ -z "$BROWSER" ]] && export BROWSER=wslview
  elif command -v explorer.exe &>/dev/null; then
    function open() {
      # explorer.exe は Windows パスを要求する。URL はそのまま渡す
      if [[ -e "$1" ]]; then
        explorer.exe "$(wslpath -w "$1")"
      else
        explorer.exe "$1"
      fi
      return 0  # explorer.exe は成功時も終了コード 1 を返す
    }
  fi

  # Clipboard integration
  # win32yank.exe / clip.exe (UTF-16LE 変換で日本語対応) / powershell.exe の選択は
  # ~/.local/bin/clipcopy / clippaste が行う (tmux のコピーも同じスクリプトを使う)
  alias pbcopy='clipcopy'
  alias pbpaste='clippaste'

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
