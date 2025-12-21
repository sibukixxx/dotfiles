#!/usr/bin/env bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Starting dotfiles setup..."
echo "    Dotfiles directory: $DOTFILES_DIR"

# =============================================================================
# Homebrew
# =============================================================================
install_homebrew() {
  if ! command -v brew &>/dev/null; then
    echo "==> Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for current session
    if [[ "$(uname -m)" == "arm64" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  else
    echo "==> Homebrew already installed"
  fi
}

# =============================================================================
# Install packages from Brewfile
# =============================================================================
install_packages() {
  echo "==> Installing packages from Brewfile..."
  if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
    brew bundle --file="$DOTFILES_DIR/Brewfile"
  else
    echo "    Brewfile not found, skipping..."
  fi
}

# =============================================================================
# Create symbolic links
# =============================================================================
create_symlinks() {
  echo "==> Creating symbolic links..."

  # Basic dotfiles
  ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
  ln -sf "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"
  ln -sf "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"

  # .config directory (alacritty, zellij, sheldon, nvim, etc.)
  if [[ -d "$DOTFILES_DIR/.config" ]]; then
    mkdir -p "$HOME/.config"
    for config in "$DOTFILES_DIR/.config"/*; do
      if [[ -e "$config" ]]; then
        config_name=$(basename "$config")
        ln -sf "$config" "$HOME/.config/$config_name"
        echo "    Linked .config/$config_name"
      fi
    done
  fi

  echo "    Symbolic links created"
}

# =============================================================================
# Setup bin directory
# =============================================================================
setup_bin() {
  echo "==> Setting up bin directory..."

  local bin_dir="$HOME/.local/bin"
  mkdir -p "$bin_dir"

  # Link scripts from dotfiles/bin
  if [[ -d "$DOTFILES_DIR/bin" ]]; then
    for script in "$DOTFILES_DIR/bin"/*; do
      if [[ -f "$script" ]]; then
        script_name=$(basename "$script")
        ln -sf "$script" "$bin_dir/$script_name"
        chmod +x "$script"
        echo "    Linked bin/$script_name"
      fi
    done
  fi

  echo "    bin directory setup complete"
}

# =============================================================================
# Setup zsh
# =============================================================================
setup_zsh() {
  echo "==> Setting up zsh..."

  # Create zsh-completions directory if not exists
  mkdir -p "$HOME/.zsh-completions"

  # Set zsh as default shell if not already
  if [[ "$SHELL" != *"zsh"* ]]; then
    echo "    Changing default shell to zsh..."
    chsh -s "$(which zsh)"
  fi

  echo "    zsh setup complete"
}

# =============================================================================
# Setup Sheldon (plugin manager)
# =============================================================================
setup_sheldon() {
  echo "==> Setting up Sheldon..."

  if command -v sheldon &>/dev/null; then
    echo "    Locking sheldon plugins..."
    sheldon lock
    echo "    Sheldon setup complete"
  else
    echo "    Sheldon not found, skipping..."
  fi
}

# =============================================================================
# Setup fzf
# =============================================================================
setup_fzf() {
  echo "==> Setting up fzf..."

  if command -v fzf &>/dev/null; then
    local fzf_install="$(brew --prefix)/opt/fzf/install"
    if [[ -f "$fzf_install" ]]; then
      echo "    Installing fzf key bindings..."
      "$fzf_install" --key-bindings --completion --no-update-rc --no-bash --no-fish
    fi
    echo "    fzf setup complete"
  else
    echo "    fzf not found, skipping..."
  fi
}

# =============================================================================
# Install fonts
# =============================================================================
install_fonts() {
  echo "==> Checking fonts..."

  # Check if HackGen is installed
  if ! fc-list 2>/dev/null | grep -qi "hackgen"; then
    echo "    HackGen font not found."
    echo "    To install HackGen Nerd Font:"
    echo "      brew tap homebrew/cask-fonts"
    echo "      brew install --cask font-hackgen-nerd"
    echo "    Or download from: https://github.com/yuru7/HackGen/releases"
  else
    echo "    HackGen font: OK"
  fi
}

# =============================================================================
# Verify installations
# =============================================================================
verify_tools() {
  echo "==> Verifying tool installations..."

  local tools=(
    "zsh"
    "nvim"
    "git"
    "sheldon"
    "zellij"
    "zoxide"
    "fzf"
    "ghq"
    "eza"
    "bat"
    "rg"
    "fd"
  )
  local missing=()

  for tool in "${tools[@]}"; do
    if command -v "$tool" &>/dev/null; then
      echo "    $tool: OK"
    else
      echo "    $tool: NOT FOUND"
      missing+=("$tool")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo ""
    echo "    Missing tools: ${missing[*]}"
    echo "    Run 'brew bundle --file=$DOTFILES_DIR/Brewfile' to install them"
  fi
}

# =============================================================================
# Print post-install instructions
# =============================================================================
print_instructions() {
  echo ""
  echo "============================================================================="
  echo "  Setup complete!"
  echo "============================================================================="
  echo ""
  echo "  Next steps:"
  echo ""
  echo "  1. Restart your terminal or run:"
  echo "       source ~/.zshrc"
  echo ""
  echo "  2. Install fonts (for Alacritty):"
  echo "       brew tap homebrew/cask-fonts"
  echo "       brew install --cask font-hackgen-nerd"
  echo ""
  echo "  3. (Optional) Setup Hammerspoon for Cmd+U transparency toggle:"
  echo "       Add to ~/.hammerspoon/init.lua:"
  echo "         hs.hotkey.bind({ \"cmd\" }, \"U\", function()"
  echo "           hs.execute(\"toggle_opacity\", true)"
  echo "         end)"
  echo ""
  echo "  Quick start:"
  echo "    zellij           # Start terminal multiplexer"
  echo "    zs main          # Attach to 'main' session"
  echo "    gcd              # Jump to ghq repository with fzf"
  echo "    z <dir>          # Smart directory jump with zoxide"
  echo ""
  echo "  Zellij keybindings (Prefix: Ctrl+x):"
  echo "    Ctrl+x |         # Split pane vertically"
  echo "    Ctrl+x -         # Split pane horizontally"
  echo "    Ctrl+x hjkl      # Navigate panes"
  echo "    Ctrl+x c         # New tab"
  echo "    Ctrl+x d         # Detach session"
  echo ""
  echo "============================================================================="
}

# =============================================================================
# Main
# =============================================================================
main() {
  install_homebrew
  install_packages
  create_symlinks
  setup_bin
  setup_zsh
  setup_sheldon
  setup_fzf
  install_fonts
  verify_tools
  print_instructions
}

main "$@"
