# hosts/infra/contabo1/default.nix
# Configuration du VPS Contabo - Serveur Linux headless

{ pkgs, inputs, lib, ... }:

{
  imports = [
    ../../../modules/common
    ../../../modules/linux
  ];

  # 1. Configuration Réseau
  networking.hostName = "contabo1";
  
  # Firewall strict
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 80 443 ];
    allowedUDPPorts = [ ];
  };

  # 2. Services
  services = {
    # SSH durci
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        X11Forwarding = false;
      };
    };

    # Fail2ban pour bloquer les attaques
    fail2ban = {
      enable = true;
      maxretry = 5;
      bantime = "1h";
    };
  };

  # 3. Virtualisation Docker
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # 4. Paquets spécifiques serveur
  environment.systemPackages = with pkgs; [
    docker-compose
    nginx
    certbot
    tmux
    screen
  ];

  # 5. Utilisateur root
  users.users.root = {
    hashedPassword = "!"; # Désactivé - SSH keys only
  };

  # Utilisateur admin
  users.users.nnosal = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keys = [
      # Ajouter ta clé publique ici
      # "ssh-ed25519 AAAAC3... nnosal@macbook-pro"
    ];
  };

  # 6. Home Manager pour l'admin
  home-manager.users.nnosal = {
    imports = [ ../../../users/nnosal/default.nix ];
    
    home.sessionVariables = {
      MACHINE_CONTEXT = "infra";
      MACHINE_NAME = "contabo1";
    };
  };

  home-manager.users.root = {
    imports = [ ../../../users/root/default.nix ];
  };

  system.stateVersion = "24.05";
}
