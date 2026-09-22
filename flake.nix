{
  description = "Portable Home Manager configuration via Nix Flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      # 対応するシステム一覧
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      # 各システムで関数を実行するヘルパー
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # `--impure` で実行し、利用中のアカウント情報を環境から取得する。
      # これによりユーザー名やホームパスをリポジトリへ固定しない。
      requireEnv = name:
        let value = builtins.getEnv name;
        in if value == ""
        then throw "${name} is required; run Home Manager with --impure"
        else value;
      currentUsername = requireEnv "USER";
      currentHomeDirectory = requireEnv "HOME";
      currentSystem = builtins.currentSystem;

      # Home Manager 設定を生成する関数
      mkHome = { system, username, homeDirectory ? null }:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          # macOS は /Users, Linux は /home
          defaultHomeDir = if pkgs.stdenv.isDarwin
            then "/Users/${username}"
            else "/home/${username}";
          actualHomeDir = if homeDirectory != null then homeDirectory else defaultHomeDir;
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./nix/home.nix
            {
              home.username = username;
              home.homeDirectory = actualHomeDir;
            }
          ];
        };
    in
    {
      # =======================================================================
      # Home Manager configurations
      # =======================================================================
      # Usage:
      #   home-manager switch --impure --flake .#current
      # =======================================================================
      homeConfigurations = {
        current = mkHome {
          system = currentSystem;
          username = currentUsername;
          homeDirectory = currentHomeDirectory;
        };
      };

      # =======================================================================
      # Dev shell for working on dotfiles themselves
      # =======================================================================
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              chezmoi
              shellcheck
              yamllint
              taplo
            ];
          };
        }
      );
    };
}
