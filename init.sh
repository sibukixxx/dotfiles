#!/usr/bin/env bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Starting dotfiles setup..."
echo "    Dotfiles directory: $DOTFILES_DIR"

# Detect OS
detect_os() {
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "macos"
  elif grep -qi microsoft /proc/version 2>/dev/null; then
    echo "wsl"
  elif [[ "$(uname)" == "Linux" ]]; then
    echo "linux"
  else
    echo "unknown"
  fi
}

OS_TYPE=$(detect_os)
echo "    Detected OS: $OS_TYPE"

# =============================================================================
# Nix (for WSL/Linux)
# =============================================================================
install_nix() {
  if [[ "$OS_TYPE" != "wsl" && "$OS_TYPE" != "linux" ]]; then
    return 0
  fi

  if command -v nix &>/dev/null; then
    echo "==> Nix already installed"
    return 0
  fi

  echo "==> Installing Nix..."
  sh <(curl -L https://nixos.org/nix/install) --daemon

  # Source nix for current session
  if [[ -f /etc/profile.d/nix.sh ]]; then
    . /etc/profile.d/nix.sh
  elif [[ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]]; then
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi
}

# =============================================================================
# Home Manager (for Nix)
# =============================================================================
install_home_manager() {
  if [[ "$OS_TYPE" != "wsl" && "$OS_TYPE" != "linux" ]]; then
    return 0
  fi

  if ! command -v nix &>/dev/null; then
    echo "    Nix not found, skipping home-manager..."
    return 1
  fi

  if command -v home-manager &>/dev/null; then
    echo "==> Home Manager already installed"
    return 0
  fi

  echo "==> Installing Home Manager..."

  # Add home-manager channel
  nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
  nix-channel --update

  # Install home-manager
  nix-shell '<home-manager>' -A install
}

# =============================================================================
# Setup Home Manager configuration
# =============================================================================
setup_home_manager() {
  if [[ "$OS_TYPE" != "wsl" && "$OS_TYPE" != "linux" ]]; then
    return 0
  fi

  if ! command -v home-manager &>/dev/null; then
    echo "    Home Manager not found, skipping..."
    return 1
  fi

  echo "==> Setting up Home Manager..."

  # Link home.nix
  mkdir -p "$HOME/.config/home-manager"
  ln -sf "$DOTFILES_DIR/nix/home.nix" "$HOME/.config/home-manager/home.nix"

  # Apply configuration
  echo "    Applying home-manager configuration..."
  home-manager switch

  echo "    Home Manager setup complete"
}

# =============================================================================
# Install packages via apt (basic dependencies for WSL/Linux)
# =============================================================================
install_apt_packages() {
  if [[ "$OS_TYPE" != "wsl" && "$OS_TYPE" != "linux" ]]; then
    return 0
  fi

  echo "==> Installing basic packages via apt..."

  local packages=(
    build-essential
    curl
    git
    zsh
    peco
  )

  sudo apt-get update
  sudo apt-get install -y "${packages[@]}"

  echo "    apt packages installed"
}

# =============================================================================
# Homebrew (for macOS)
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
# Rustup & Cargo
# =============================================================================
install_rustup() {
  if ! command -v rustup &>/dev/null; then
    echo "==> Installing Rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
  else
    echo "==> Rustup already installed"
  fi
}

# =============================================================================
# Install Rust CLI tools via Cargo
# =============================================================================
install_rust_tools() {
  echo "==> Installing Rust tools via Cargo..."

  # Ensure cargo is in PATH
  if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
  fi

  if ! command -v cargo &>/dev/null; then
    echo "    Cargo not found. Please install Rustup first."
    return 1
  fi

  local rust_tools=(
    "ripgrep"      # rg - fast grep
    "fd-find"      # fd - fast find
    "bat"          # cat with syntax highlighting
    "eza"          # modern ls replacement
    "zoxide"       # smarter cd
    "sheldon"      # shell plugin manager
    "zellij"       # terminal multiplexer
  )

  for tool in "${rust_tools[@]}"; do
    echo "    Installing $tool..."
    cargo install "$tool" --locked 2>/dev/null || cargo install "$tool"
  done

  echo "    Rust tools installation complete"
}

# =============================================================================
# Create symbolic links
# =============================================================================
create_symlinks() {
  echo "==> Creating symbolic links..."

  # Basic dotfiles
  ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
  ln -sf "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"

  # .config directory (alacritty, zellij, sheldon, nvim, etc.)
  if [[ -d "$DOTFILES_DIR/.config" ]]; then
    mkdir -p "$HOME/.config"
    for config in "$DOTFILES_DIR/.config"/*; do
      if [[ -e "$config" ]]; then
        config_name=$(basename "$config")
        # For git, link individual files (XDG Base Directory)
        if [[ "$config_name" == "git" ]]; then
          mkdir -p "$HOME/.config/git"
          for git_file in "$config"/*; do
            if [[ -f "$git_file" ]]; then
              git_file_name=$(basename "$git_file")
              ln -sf "$git_file" "$HOME/.config/git/$git_file_name"
              echo "    Linked .config/git/$git_file_name"
            fi
          done
        else
          ln -sf "$config" "$HOME/.config/$config_name"
          echo "    Linked .config/$config_name"
        fi
      fi
    done
  fi

  # Remove legacy ~/.gitconfig symlink if exists
  if [[ -L "$HOME/.gitconfig" ]]; then
    rm "$HOME/.gitconfig"
    echo "    Removed legacy ~/.gitconfig symlink"
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

  if ! command -v fzf &>/dev/null; then
    echo "    fzf not found, skipping..."
    return 0
  fi

  local fzf_install=""

  case "$OS_TYPE" in
    macos)
      fzf_install="$(brew --prefix)/opt/fzf/install"
      ;;
    wsl|linux)
      # Nix installs fzf, check for its install script
      if [[ -f "$HOME/.nix-profile/share/fzf/shell/key-bindings.zsh" ]]; then
        echo "    fzf key bindings available via Nix"
        return 0
      fi
      # Fallback to system fzf
      fzf_install="/usr/share/doc/fzf/examples/key-bindings.zsh"
      ;;
  esac

  if [[ -n "$fzf_install" && -f "$fzf_install" ]]; then
    echo "    Installing fzf key bindings..."
    "$fzf_install" --key-bindings --completion --no-update-rc --no-bash --no-fish 2>/dev/null || true
  fi

  echo "    fzf setup complete"
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
  case "$OS_TYPE" in
    macos)
      install_homebrew
      install_packages
      install_rustup
      install_rust_tools
      ;;
    wsl|linux)
      install_apt_packages
      install_nix
      install_home_manager
      setup_home_manager
      install_rustup
      install_rust_tools
      ;;
    *)
      echo "Unknown OS type: $OS_TYPE"
      exit 1
      ;;
  esac

  # Common setup for all platforms
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
