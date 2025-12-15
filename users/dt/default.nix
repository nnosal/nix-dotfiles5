# users/dt/default.nix  
# Profil utilisateur Gamer - Pour le PC Gaming Windows/WSL

{ pkgs, lib, config, ... }:

{
  # Git
  programs.git = {
    enable = true;
    userName = "DT";
    userEmail = "user@github.com"; # Placeholder
    
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  # Paquets orientés gaming/dev perso
  home.packages = with pkgs; [
    # CLI moderne
    bat
    eza
    fzf
    ripgrep
    fd
    
    # Git
    lazygit
    gh
    
    # Dev
    neovim
    
    # Fun
    neofetch
    cowsay
    lolcat
  ];

  # Neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Zsh personnalisé
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;
    
    shellAliases = {
      # Alias gaming/perso
      update = "sudo apt update && sudo apt upgrade -y"; # Pour WSL Ubuntu
      cls = "clear";
    };
  };

  # Starship
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # Variables
  home.sessionVariables = {
    EDITOR = "nvim";
    MACHINE_CONTEXT = "personal";
  };

  home.stateVersion = "24.05";
}
