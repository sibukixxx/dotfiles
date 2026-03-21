{ config, pkgs, ... }:

{
  # home.username と home.homeDirectory は flake.nix から注入される。
  # 非 flake 環境では home-manager switch 時に --extra-experimental-features
  # を使うか、呼び出し元で設定すること。

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # =============================================================================
  # Module Imports
  # =============================================================================
  imports = [
    ./cli-tools.nix
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

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;  # faster nix-shell integration
  };

  # =============================================================================
  # Environment
  # =============================================================================
  home.sessionVariables = {
    EDITOR = "nvim";
    LANG = "en_US.UTF-8";
  };
}
