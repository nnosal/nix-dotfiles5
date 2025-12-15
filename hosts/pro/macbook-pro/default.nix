# hosts/pro/macbook-pro/default.nix
# Configuration du MacBook Pro M3 - Contexte PROFESSIONNEL

{ pkgs, inputs, ... }:

{
  imports = [
    ../../../modules/common
    ../../../modules/darwin
  ];

  # 1. Configuration Matérielle / Système
  networking.hostName = "macbook-pro";

  # Apps Système supplémentaires (spécifiques à cette machine)
  homebrew.casks = [
    # Outils pro supplémentaires
    "figma"
    "postman"
    "tableplus"
    "sequel-ace"
  ];

  # 2. Définition des Utilisateurs
  users.users.nnosal = {
    name = "nnosal";
    home = "/Users/nnosal";
  };

  # 3. Import du Profil Humain (Home Manager)
  home-manager.users.nnosal = {
    imports = [ ../../../users/nnosal/default.nix ];

    # Surcharge spécifique à cette machine
    home.sessionVariables = {
      MACHINE_CONTEXT = "work";
      MACHINE_NAME = "macbook-pro";
    };
  };
}
