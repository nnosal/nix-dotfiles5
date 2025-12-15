# modules/linux/default.nix
# Module spécifique Linux (NixOS)

{ pkgs, lib, config, ... }:

{
  # Bootloader standard
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  # Networking
  networking = {
    networkmanager.enable = lib.mkDefault true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ];
    };
  };

  # Localisation
  time.timeZone = lib.mkDefault "Europe/Paris";
  i18n.defaultLocale = "fr_FR.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "fr";
  };

  # Services de base
  services = {
    # SSH Server
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
  };

  # Paquets spécifiques Linux
  environment.systemPackages = with pkgs; [
    # Monitoring
    htop
    iotop
    
    # Réseau
    iproute2
    nettools
    dnsutils
    nmap
    
    # Système
    lsof
    strace
    pciutils
    usbutils
  ];

  # Docker (optionnel, activé par host si besoin)
  # virtualisation.docker.enable = true;

  # Version NixOS
  system.stateVersion = lib.mkDefault "24.05";
}
