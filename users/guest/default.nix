# users/guest/default.nix
# Profil utilisateur limité - Invité
# Accès basique sans secrets ni configs sensibles

{ pkgs, lib, config, ... }:

{
  # Git basique (sans identité personnalisée)
  programs.git = {
    enable = true;
    userName = "Guest User";
    userEmail = "user@github.com"; # Placeholder
    
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  # Paquets minimaux
  home.packages = with pkgs; [
    # Essentiels uniquement
    bat
    eza
    fzf
    ripgrep
    
    # Éditeur
    neovim
    
    # Pas de:
    # - Outils DevOps (k9s, kubectl)
    # - GitHub CLI
    # - Outils d'infra
  ];

  # Pas de SSH avancé
  programs.ssh.enable = false;

  # Éditeur basique
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  # Variables de session limitées
  home.sessionVariables = {
    EDITOR = "nvim";
    PAGER = "less";
    # Pas de MACHINE_CONTEXT (non défini = guest)
  };

  # NOTE: Ce profil ne charge PAS:
  # - Fnox (pas d'accès aux secrets)
  # - SSH Secretive (pas d'accès aux clés)
  # - Configs Stow work/personal

  home.stateVersion = "24.05";
}
