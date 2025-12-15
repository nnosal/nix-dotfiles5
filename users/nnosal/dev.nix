# users/nnosal/dev.nix
# Module de développement pour l'utilisateur nnosal
# Outils et configurations pour le dev quotidien

{ pkgs, lib, config, ... }:

{
  # Langages et runtimes (gérés par Mise, mais fallback Nix)
  home.packages = with pkgs; [
    # Node.js ecosystem
    nodejs_22
    yarn
    pnpm
    
    # Python
    python312
    python312Packages.pip
    python312Packages.virtualenv
    
    # Rust
    rustup
    
    # Go
    go
    
    # Database clients
    postgresql_16
    sqlite
    
    # API Testing
    httpie
    curlie
    
    # Containers
    # docker  # Géré par OrbStack sur Mac
    # docker-compose
    
    # Cloud CLI
    # awscli2
    # google-cloud-sdk
    # azure-cli
    
    # Kubernetes
    kubectl
    kubectx
    k9s
    helm
    
    # Terraform / IaC
    # terraform
    # terragrunt
    
    # Code Quality
    pre-commit
    
    # Documentation
    mdbook
  ];

  # Configuration VS Code (si utilisé via CLI)
  # Note: VS Code lui-même est installé via Homebrew Cask
  programs.vscode = {
    enable = false;  # Géré par Homebrew
  };
}
