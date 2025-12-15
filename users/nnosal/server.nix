# users/nnosal/server.nix
# Module serveur pour l'utilisateur nnosal
# Outils d'administration et monitoring

{ pkgs, lib, config, ... }:

{
  home.packages = with pkgs; [
    # Monitoring avancé
    htop
    btop
    iotop
    nethogs
    bandwhich  # Network monitor
    
    # Logs
    lnav       # Log navigator
    
    # Processus
    procs      # Modern ps
    
    # Réseau
    mtr        # Better traceroute
    nmap
    tcpdump
    
    # Disques
    ncdu       # Disk usage analyzer
    duf        # Better df
    
    # Fichiers
    rsync
    rclone     # Cloud sync
    
    # Backup
    restic
    
    # SSH
    mosh       # Mobile shell
    
    # Security
    fail2ban
  ];
}
