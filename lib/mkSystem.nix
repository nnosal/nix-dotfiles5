# lib/mkSystem.nix
# Factory pour créer un Host (Darwin ou NixOS)
# Détecte automatiquement l'OS et injecte home-manager + stylix

{ inputs }:

{ system, modules, ... }:

let
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true; # Autoriser Spotify, VSCode, etc.
  };

  # Détection automatique de l'OS
  isDarwin = builtins.match ".*darwin" system != null;

  # Sélection du builder (nix-darwin vs nixos)
  systemBuilder = if isDarwin 
    then inputs.darwin.lib.darwinSystem 
    else inputs.nixpkgs.lib.nixosSystem;

  # Modules de base toujours présents
  commonModules = [
    inputs.home-manager.${if isDarwin then "darwinModules" else "nixosModules"}.home-manager
    inputs.stylix.${if isDarwin then "darwinModules" else "nixosModules"}.stylix
    {
      # Configuration globale de Home Manager
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = { inherit inputs; }; # Passe les inputs aux users
    }
  ];

in
systemBuilder {
  inherit system;
  # On passe les inputs à tous les modules système
  specialArgs = { inherit inputs; };
  modules = commonModules ++ modules;
}
