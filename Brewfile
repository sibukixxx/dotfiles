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
brew "jq"                # JSON processor (Claude hooks validate-bash.sh / validate-read.sh が依存)

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
# terraform は BSL ライセンス化で homebrew/core から外れたため HashiCorp 公式 tap から入れる。
# Homebrew 7 は公式以外の tap を信頼するまで読み込まないので、terraform だけを信頼する
tap "hashicorp/tap", trusted: { formula: ["terraform"] }
brew "hashicorp/tap/terraform"
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
cask "cmux"              # Agent-first terminal workspace manager (公式 homebrew/cask にあるので tap 不要)
cask "ghostty"           # Modern GPU-accelerated terminal (primary)
# Homebrew が 2026-09-01 に Gatekeeper 非対応で無効化。brew bundle 全体が失敗するため外す（インストール済みの 0.16.1 はそのまま使える）
# cask "alacritty"         # GPU-accelerated terminal emulator (backup)

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
