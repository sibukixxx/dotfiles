# =============================================================================
# Brewfile - macOS GUI Apps & macOS-only Tools
# =============================================================================
# CLI ツールは nix/cli-tools.nix で管理。
# このファイルは Homebrew cask (GUI) と macOS 固有ツールのみ。
# =============================================================================

# Mac App Store CLI
brew "mas"

# =============================================================================
# macOS-only CLI Tools (Nix で提供困難 or cask 依存)
# =============================================================================
brew "chezmoi"           # dotfiles manager (bootstrap 時に必要)
brew "age"               # encryption for secrets

# Development tools (platform-specific or version-managed)
brew "go"                # Go (brew の方がバージョン管理しやすい)
brew "pyenv"             # Python version manager
brew "nodebrew"          # Node.js version manager
brew "fastlane"          # iOS automation
brew "gogcli"            # GOG.com game library CLI

# Cloud CLI Tools (cask or brew tap 依存)
brew "awscli"
cask "gcloud-cli"

# Infrastructure as Code
brew "terraform"
brew "tflint"
brew "terraform-docs"
brew "tfsec"
brew "pre-commit"

# Database
brew "mysql"

# macOS system dependencies
brew "gibo"              # .gitignore boilerplates
brew "openssl"
brew "readline"

# =============================================================================
# Terminal Emulators (GUI)
# =============================================================================
tap "manaflow-ai/cmux"
cask "cmux"              # Agent-first terminal workspace manager
cask "ghostty"           # Modern GPU-accelerated terminal (primary)
cask "alacritty"         # GPU-accelerated terminal emulator (backup)

# =============================================================================
# Browsers
# =============================================================================
cask "google-chrome"

# =============================================================================
# Communication
# =============================================================================
cask "slack"
cask "discord"

# =============================================================================
# Development - IDEs & Editors
# =============================================================================
cask "visual-studio-code"
cask "jetbrains-toolbox"

# =============================================================================
# Development - Containers & Virtualization
# =============================================================================
cask "orbstack"

# =============================================================================
# Productivity
# =============================================================================
cask "alfred"
cask "clipy"
cask "obsidian"
cask "dropbox"
cask "1password-cli"

# =============================================================================
# AI Tools
# =============================================================================
brew "agent-browser"
cask "claude"

# =============================================================================
# Entertainment
# =============================================================================
cask "steam"

# =============================================================================
# Fonts
# =============================================================================
cask "font-hackgen-nerd"

# =============================================================================
# Mac App Store
# =============================================================================
mas "Kindle", id: 302584613
