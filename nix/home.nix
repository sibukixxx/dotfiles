{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should manage.
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # =============================================================================
  # Packages
  # =============================================================================
  home.packages = with pkgs; [
    # Shell & Terminal
    zsh
    zellij

    # Modern CLI tools
    ripgrep      # rg - fast grep
    fd           # fast find
    bat          # cat with syntax highlighting
    eza          # modern ls replacement
    zoxide       # smarter cd
    fzf          # fuzzy finder

    # Development
    git
    gh           # GitHub CLI
    ghq          # remote repository management
    neovim

    # Shell plugin manager
    sheldon

    # Utils
    jq
    tree
    curl
    wget
    peco

    # Build tools
    gcc
    gnumake
  ];

  # =============================================================================
  # Programs configuration
  # =============================================================================

  programs.zsh = {
    enable = true;
    # Don't manage zshrc - we use our own from dotfiles
    initExtra = "";
  };

  programs.git = {
    enable = true;
    # Don't manage gitconfig - we use our own from dotfiles
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = false;  # We handle this in our zshrc
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = false;  # We handle this in our zshrc
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      pager = "less -FR";
    };
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = false;  # We handle aliases ourselves
  };

  # =============================================================================
  # Environment
  # =============================================================================
  home.sessionVariables = {
    EDITOR = "nvim";
    LANG = "en_US.UTF-8";
  };
}
