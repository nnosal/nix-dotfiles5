# hosts/infra/rpi5-maison/default.nix
# Configuration du Raspberry Pi 5 - Homelab

{ pkgs, inputs, lib, ... }:

{
  imports = [
    ../../../modules/common
    ../../../modules/linux
  ];

  # 1. Configuration
  networking.hostName = "rpi5-maison";
  
  # Réseau local
  networking.networkmanager.enable = true;

  # 2. Boot spécifique Raspberry Pi
  # Le module nixos-hardware s'en occupe
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # 3. Services Homelab
  services = {
    # SSH
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };

    # Serveur DNS local (optionnel)
    # dnsmasq.enable = true;

    # Home Assistant (optionnel)
    # home-assistant.enable = true;
  };

  # 4. Utilisateur
  users.users.nnosal = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "gpio" ];
    openssh.authorizedKeys.keys = [
      # "ssh-ed25519 AAAAC3... nnosal@macbook-pro"
    ];
  };

  # 5. Home Manager
  home-manager.users.nnosal = {
    imports = [ ../../../users/nnosal/default.nix ];
    
    home.sessionVariables = {
      MACHINE_CONTEXT = "infra";
      MACHINE_NAME = "rpi5-maison";
    };
  };

  system.stateVersion = "24.05";
}
