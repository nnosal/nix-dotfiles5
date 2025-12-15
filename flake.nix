{
  description = "Ultimate Dotfiles - Unified Infrastructure";

  inputs = {
    # 1. Nix Packages (La base de tout)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # 2. Gestionnaire macOS
    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # 3. Gestionnaire Utilisateur (Dotfiles manager)
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # 4. Esthétique (Harmonisation des couleurs)
    stylix.url = "github:danth/stylix";

    # 5. Hardware Tweaks (Pour Raspberry Pi / Apple Silicon)
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, darwin, home-manager, ... }@inputs:
    let
      # On charge notre librairie perso pour éviter de répéter le code
      lib = import ./lib { inherit inputs; };
    in
    {
      # --- 🍎 MAC OS CONFIGURATIONS ---
      darwinConfigurations = {

        # PRO (MacBook Pro M3)
        "macbook-pro" = lib.mkSystem {
          system = "aarch64-darwin";
          modules = [ ./hosts/pro/macbook-pro/default.nix ];
        };

        # PERSO (MacBook Air M2)
        "mba-clientele" = lib.mkSystem {
          system = "aarch64-darwin";
          modules = [ ./hosts/perso/mba-clientele/default.nix ];
        };
      };

      # --- 🐧 LINUX SERVER CONFIGURATIONS ---
      nixosConfigurations = {

        # INFRA (VPS Contabo)
        "contabo1" = lib.mkSystem {
          system = "x86_64-linux";
          modules = [ ./hosts/infra/contabo1/default.nix ];
        };

        # LABO (Raspberry Pi 5)
        "rpi5-maison" = lib.mkSystem {
          system = "aarch64-linux";
          modules = [
            inputs.nixos-hardware.nixosModules.raspberry-pi-4
            ./hosts/infra/rpi5-maison/default.nix
          ];
        };

        # TEST (Agent AI Linux)
        "agent-test" = lib.mkSystem {
          system = "x86_64-linux";
          modules = [ ./hosts/infra/agent-test/default.nix ];
        };
      };

      # --- 🪟 WINDOWS / STANDALONE HOME ---
      homeConfigurations = {

        # GAMING (WSL2 Debian/Ubuntu)
        "dt@gaming-rig" = lib.mkHome {
          system = "x86_64-linux";
          modules = [ ./hosts/perso/gaming-rig/wsl.nix ];
        };
      };
    };
}
