#!/usr/bin/env bash

# usage: ./dotfilesLink.sh {DOTFILES_PATH}
# example: ./dotfilesLink.sh $(pwd)

set -e

DOTFILES_PATH="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

if [[ ! -d "$DOTFILES_PATH" ]]; then
  echo "Error: Invalid dotfiles path: $DOTFILES_PATH" >&2
  exit 1
fi

# =============================================================================
# OS Detection
# =============================================================================
detect_os() {
  case "$(uname -s)" in
    Darwin)
      echo "macos"
      ;;
    Linux)
      echo "linux"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

OS=$(detect_os)

echo "==> Creating symbolic links..."
echo "    Dotfiles: $DOTFILES_PATH"
echo "    OS: $OS"

# =============================================================================
# Helper function
# =============================================================================
link_file() {
  local src="$1"
  local dest="$2"
  local name="${3:-$dest}"

  if [[ -e "$src" ]]; then
    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    echo "    Linked $name"
  fi
}

link_dir() {
  local src="$1"
  local dest="$2"
  local name="${3:-$dest}"

  if [[ -d "$src" ]]; then
    mkdir -p "$(dirname "$dest")"
    # Remove existing symlink or directory
    if [[ -L "$dest" ]]; then
      rm "$dest"
    elif [[ -d "$dest" ]]; then
      rm -rf "$dest"
    fi
    ln -sf "$src" "$dest"
    echo "    Linked $name (directory)"
  fi
}

# =============================================================================
# Common: Basic dotfiles
# =============================================================================
echo ""
echo "==> Basic dotfiles..."
link_file "$DOTFILES_PATH/.zshrc" ~/.zshrc ".zshrc"
link_file "$DOTFILES_PATH/.vimrc" ~/.vimrc ".vimrc"
link_file "$DOTFILES_PATH/.tmux.conf" ~/.tmux.conf ".tmux.conf"
link_file "$DOTFILES_PATH/.psqlrc" ~/.psqlrc ".psqlrc"
link_file "$DOTFILES_PATH/.screenrc" ~/.screenrc ".screenrc"

# =============================================================================
# Common: XDG Base Directory configs (~/.config/*)
# =============================================================================
echo ""
echo "==> XDG Config (~/.config/*)..."

# Git
mkdir -p ~/.config/git
for file in config ignore message; do
  link_file "$DOTFILES_PATH/.config/git/$file" ~/.config/git/$file ".config/git/$file"
done

# Neovim
link_dir "$DOTFILES_PATH/.config/nvim" ~/.config/nvim ".config/nvim"

# Sheldon (zsh plugin manager)
link_dir "$DOTFILES_PATH/.config/sheldon" ~/.config/sheldon ".config/sheldon"

# Zellij (terminal multiplexer)
link_dir "$DOTFILES_PATH/.config/zellij" ~/.config/zellij ".config/zellij"

# Alacritty (terminal emulator)
link_dir "$DOTFILES_PATH/.config/alacritty" ~/.config/alacritty ".config/alacritty"

# Ghostty (terminal emulator)
link_dir "$DOTFILES_PATH/.config/ghostty" ~/.config/ghostty ".config/ghostty"

# Crossnote
link_dir "$DOTFILES_PATH/.config/crossnote" ~/.config/crossnote ".config/crossnote"

# REST Client
link_dir "$DOTFILES_PATH/.config/rest-client" ~/.config/rest-client ".config/rest-client"

# =============================================================================
# Common: Claude Code settings
# =============================================================================
echo ""
echo "==> Claude Code..."
link_dir "$DOTFILES_PATH/.claude" ~/.claude ".claude"

# =============================================================================
# macOS Only: Karabiner-Elements
# =============================================================================
if [[ "$OS" == "macos" ]]; then
  echo ""
  echo "==> macOS specific..."

  # Karabiner-Elements
  if [[ -d "$DOTFILES_PATH/.config/karabiner" ]]; then
    mkdir -p ~/.config/karabiner
    link_file "$DOTFILES_PATH/.config/karabiner/karabiner.json" ~/.config/karabiner/karabiner.json ".config/karabiner/karabiner.json"
    link_dir "$DOTFILES_PATH/.config/karabiner/assets" ~/.config/karabiner/assets ".config/karabiner/assets"
  fi
fi

# =============================================================================
# Cleanup legacy files
# =============================================================================
echo ""
echo "==> Cleanup..."

# Remove legacy ~/.gitconfig if it's a symlink
if [[ -L ~/.gitconfig ]]; then
  rm ~/.gitconfig
  echo "    Removed legacy ~/.gitconfig"
fi

echo ""
echo "==> Done!"
