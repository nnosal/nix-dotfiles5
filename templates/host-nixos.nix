# templates/host-nixos.nix
# Template pour un nouveau Host NixOS (Linux)
# Variables à remplacer: %HOSTNAME%, %CONTEXT%, %USER%

{ pkgs, inputs, lib, ... }:

{
  imports = [
    ../../../modules/common
    ../../../modules/linux
  ];

  # Configuration réseau
  networking.hostName = "%HOSTNAME%";
  networking.firewall.enable = true;

  # Utilisateur principal
  users.users.%USER% = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # openssh.authorizedKeys.keys = [ "ssh-ed25519 ..." ];
  };

  # Home Manager
  home-manager.users.%USER% = {
    imports = [ ../../../users/%USER%/default.nix ];
    
    home.sessionVariables = {
      MACHINE_CONTEXT = "%CONTEXT%";
      MACHINE_NAME = "%HOSTNAME%";
    };
  };

  system.stateVersion = "24.05";
}
