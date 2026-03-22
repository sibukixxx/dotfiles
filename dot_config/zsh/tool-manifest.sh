# Shared tool lists for dotfiles scripts (bash/zsh compatible)
#
# CLI ツールは nix/cli-tools.nix で宣言的に管理。
# このファイルは検証・フォールバック用のマニフェスト。

# Core tools expected in day-to-day shell usage.
DOTFILES_CORE_TOOLS=(
  zsh
  nvim
  git
  direnv
  sheldon
  zellij
  fzf
  ghq
  eza
  bat
  rg
  fd
)

# Extra tools checked by full setup verification.
DOTFILES_VERIFY_EXTRA_TOOLS=(
  gcloud
  aws
  opencode
  agent-browser
  rtk
  agent-skills
  actrun
)

# Fallback: macOS で home-manager 未導入時に brew でインストールするツール。
# home-manager 導入後はこのリストは不要。
DOTFILES_BREW_ESSENTIAL_TOOLS=(
  eza
  bat
  rg
  fd
  fzf
  peco
  ghq
  sheldon
  zellij
)

# Homebrew formula names corresponding to DOTFILES_BREW_ESSENTIAL_TOOLS.
DOTFILES_BREW_FORMULAS=(
  eza
  bat
  ripgrep
  fd
  fzf
  peco
  ghq
  sheldon
  zellij
)
