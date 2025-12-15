# hosts/perso/mba-clientele/default.nix
# Configuration du MacBook Air M2 - Contexte PERSONNEL

{ pkgs, inputs, ... }:

{
  imports = [
    ../../../modules/common
    ../../../modules/darwin
  ];

  # 1. Configuration Matérielle / Système
  networking.hostName = "mba-clientele";

  # Apps Système (plus orientées perso)
  homebrew.casks = [
    # Jeux et divertissement
    "steam"
    "battle-net"
    # Créatif
    "affinity-photo"
    "affinity-designer"
  ];

  # 2. Définition des Utilisateurs
  users.users.nnosal = {
    name = "nnosal";
    home = "/Users/nnosal";
  };

  # Utilisateur invité (limité)
  users.users.guest = {
    name = "guest";
    home = "/Users/guest";
  };

  # 3. Import des Profils Humains
  home-manager.users.nnosal = {
    imports = [ ../../../users/nnosal/default.nix ];

    home.sessionVariables = {
      MACHINE_CONTEXT = "personal";
      MACHINE_NAME = "mba-clientele";
    };
  };

  home-manager.users.guest = {
    imports = [ ../../../users/guest/default.nix ];
  };
}
