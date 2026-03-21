{
  description = "sibukixxx dotfiles - Home Manager configuration via Nix Flakes";

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

      # Home Manager 設定を生成する関数
      mkHome = { system, username ? builtins.getEnv "USER", homeDirectory ? builtins.getEnv "HOME" }:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./nix/home.nix
            {
              home.username = username;
              home.homeDirectory = homeDirectory;
            }
          ];
        };
    in
    {
      # =======================================================================
      # Home Manager configurations
      # =======================================================================
      # Usage:
      #   home-manager switch --flake .
      #   home-manager switch --flake .#aarch64-darwin  (explicit system)
      # =======================================================================
      homeConfigurations = {
        # macOS Apple Silicon (default for most users)
        "aarch64-darwin" = mkHome {
          system = "aarch64-darwin";
        };

        # macOS Intel
        "x86_64-darwin" = mkHome {
          system = "x86_64-darwin";
        };

        # Linux x86_64 (WSL / native)
        "x86_64-linux" = mkHome {
          system = "x86_64-linux";
        };

        # Linux ARM64
        "aarch64-linux" = mkHome {
          system = "aarch64-linux";
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
