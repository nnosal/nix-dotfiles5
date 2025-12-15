# users/root/default.nix
# Profil utilisateur root - Administration serveurs
# Minimaliste et sécurisé

{ pkgs, lib, config, ... }:

{
  # Git pour les ops
  programs.git = {
    enable = true;
    userName = "Root Admin";
    userEmail = "root@infra.local";
    
    extraConfig = {
      init.defaultBranch = "main";
      safe.directory = "*"; # Autoriser tous les répertoires
    };
  };

  # Paquets sysadmin
  home.packages = with pkgs; [
    # Monitoring
    htop
    btop
    iotop
    
    # Réseau
    curl
    wget
    dnsutils
    nettools
    
    # Fichiers
    tree
    ncdu  # Disk usage
    
    # Éditeur
    neovim
    
    # Logs
    lnav  # Log navigator
  ];

  # SSH
  programs.ssh.enable = true;

  # Neovim basique
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  # Variables
  home.sessionVariables = {
    EDITOR = "nvim";
    PAGER = "less -R";
  };

  home.stateVersion = "24.05";
}
