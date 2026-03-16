# Shared tool lists for dotfiles scripts (bash/zsh compatible)

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

# Tools auto-installed from .zshrc on macOS if missing.
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
