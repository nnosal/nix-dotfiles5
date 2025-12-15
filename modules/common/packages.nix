# modules/common/packages.nix
# Paquets CLI communs à tous les systèmes

{ pkgs, lib, config, ... }:

{
  environment.systemPackages = with pkgs; [
    # 🛠️ Outils CLI de base
    coreutils
    findutils
    gnugrep
    gnused
    gawk
    
    # 📁 Gestion de fichiers
    tree
    fd
    eza       # ls moderne
    bat       # cat moderne
    ripgrep   # grep ultra rapide
    fzf       # fuzzy finder
    zoxide    # cd intelligent
    
    # 📝 Éditeurs et outils texte
    neovim
    jq        # JSON processor
    yq        # YAML processor
    
    # 🔗 Réseau et HTTP
    curl
    wget
    httpie
    
    # 🐙 Git et versioning
    git
    lazygit
    delta     # diff viewer
    gh        # GitHub CLI
    
    # 📦 Archives
    unzip
    zip
    p7zip
    
    # 🚀 DevOps et Cloud
    # k9s       # Kubernetes TUI
    # kubectl
    # terraform
    
    # 🎨 Divers
    htop
    btop
    neofetch
    tldr
    
    # 🧹 Linting et formatage
    nixfmt-rfc-style
    shellcheck
    shfmt
    
    # %% PACKAGES %%
    # ↑ Ne pas supprimer ce marqueur - utilisé par le Wizard add-app.sh
  ];
}
