# CLI Tools - Nix Module
# =====================
# Homebrew と Nix の両方で管理されていた CLI ツールを Nix に統一する。
# macOS でも Linux/WSL でもこのモジュールで CLI ツールを宣言的に管理。
#
# GUI アプリ（cask）は引き続き Brewfile で管理する。

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # =========================================================================
    # Shell & Terminal
    # =========================================================================
    zsh
    zellij

    # =========================================================================
    # Modern CLI Tools (grep/find/cat/ls replacements)
    # =========================================================================
    ripgrep      # rg  - fast grep
    fd           # fd  - fast find
    bat          # bat - cat with syntax highlighting
    eza          # eza - modern ls
    fzf          # fzf - fuzzy finder
    peco         # peco - interactive filtering

    # =========================================================================
    # Navigation & Repository Management
    # =========================================================================
    ghq          # ghq - remote repository management

    # =========================================================================
    # Development Core
    # =========================================================================
    git
    gh           # GitHub CLI
    neovim
    direnv       # per-directory environment variables
    sheldon      # zsh plugin manager
    jq           # JSON processor
    tree         # directory listing
    curl
    wget
    colordiff    # colorized diff

    # =========================================================================
    # Build Tools
    # =========================================================================
    gcc
    gnumake
  ];
}
