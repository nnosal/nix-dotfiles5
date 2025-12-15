# modules/common/default.nix
# Module de base importé par tous les systèmes (Mac, Linux, WSL)

{ pkgs, lib, config, ... }:

{
  imports = [
    ./shell.nix
    ./style.nix
    ./packages.nix
  ];

  # Configuration Nix commune
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      warn-dirty = false;
    };
    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
  };

  # Permettre les paquets non-libres
  nixpkgs.config.allowUnfree = true;
}
