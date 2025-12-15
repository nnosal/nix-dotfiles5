# hosts/perso/gaming-rig/wsl.nix
# Configuration Home Manager pour WSL2 sur le PC Gaming
# C'est une config STANDALONE (pas NixOS complet)

{ pkgs, inputs, ... }:

{
  imports = [
    ../../../modules/wsl
  ];

  # Identité WSL
  home.username = "dt";
  home.homeDirectory = "/home/dt";

  # Programmes de base
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git = {
    enable = true;
    userName = "Nicolas Nosal";
    userEmail = "nicolas.nosal@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      # Credential helper Windows
      credential.helper = "/mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe";
    };
  };

  # Paquets CLI Linux
  home.packages = with pkgs; [
    # Essentiels
    git
    curl
    wget
    unzip
    
    # Développement
    gcc
    gnumake
    
    # Outils modernes
    bat
    eza
    fzf
    ripgrep
    fd
    lazygit
    neovim
    
    # WSL utils
    wslu
  ];

  # Variables d'environnement
  home.sessionVariables = {
    MACHINE_CONTEXT = "personal";
    MACHINE_NAME = "gaming-rig";
    EDITOR = "nvim";
  };

  home.stateVersion = "24.05";
}
