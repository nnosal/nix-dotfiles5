#!/usr/bin/env bash
# scripts/wizards/add-user.sh
# Wizard pour créer un nouveau profil utilisateur
set -e

# Charger les helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils.sh"

DOTFILES_DIR="$(get_dotfiles_path)"

gum style --foreground 212 "👤 Wizard: Ajouter un Utilisateur"

# 1. Nom d'utilisateur
USER_NAME=$(gum input --placeholder "Nom d'utilisateur (ex: john)")

if [ -z "$USER_NAME" ]; then
    error "Nom vide, annulation"
    exit 1
fi

# Vérifier si existe déjà
USER_DIR="$DOTFILES_DIR/users/$USER_NAME"
if [ -d "$USER_DIR" ]; then
    error "L'utilisateur $USER_NAME existe déjà"
    exit 1
fi

# 2. Type de profil
PROFILE_TYPE=$(gum choose \
    "complet (admin/dev)" \
    "limité (guest)" \
    "minimal (server)" \
    "Annuler")

[[ "$PROFILE_TYPE" == "Annuler" ]] && exit 0

# 3. Infos Git
GIT_NAME=$(gum input --placeholder "Nom complet Git (ex: John Doe)" --value "$USER_NAME")
GIT_EMAIL=$(gum input --placeholder "Email Git" --value "user@github.com")

# 4. Créer le dossier
info "Création de $USER_DIR..."
mkdir -p "$USER_DIR"

# 5. Générer selon le type
case "$PROFILE_TYPE" in
    "complet"*)
        cat > "$USER_DIR/default.nix" << EOF
# users/$USER_NAME/default.nix
# Profil utilisateur complet - Créé par le Wizard

{ pkgs, lib, config, ... }:

{
  # Identité Git
  programs.git = {
    enable = true;
    userName = "$GIT_NAME";
    userEmail = "$GIT_EMAIL";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  # Paquets CLI
  home.packages = with pkgs; [
    bat
    eza
    fzf
    ripgrep
    fd
    lazygit
    gh
    nh
  ];

  # SSH
  programs.ssh.enable = true;

  # Neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  home.stateVersion = "24.05";
}
EOF
        ;;
        
    "limité"*)
        cat > "$USER_DIR/default.nix" << EOF
# users/$USER_NAME/default.nix
# Profil utilisateur limité - Créé par le Wizard

{ pkgs, lib, config, ... }:

{
  programs.git = {
    enable = true;
    userName = "$GIT_NAME";
    userEmail = "$GIT_EMAIL";
  };

  # Paquets minimaux
  home.packages = with pkgs; [
    bat
    eza
    fzf
    neovim
  ];

  programs.neovim = {
    enable = true;
    viAlias = true;
  };

  home.stateVersion = "24.05";
}
EOF
        ;;
        
    "minimal"*)
        cat > "$USER_DIR/default.nix" << EOF
# users/$USER_NAME/default.nix
# Profil utilisateur minimal (serveur) - Créé par le Wizard

{ pkgs, lib, config, ... }:

{
  programs.git = {
    enable = true;
    userName = "$GIT_NAME";
    userEmail = "$GIT_EMAIL";
  };

  home.packages = with pkgs; [
    htop
    neovim
  ];

  programs.neovim = {
    enable = true;
    viAlias = true;
  };

  home.stateVersion = "24.05";
}
EOF
        ;;
esac

success "Utilisateur $USER_NAME créé !"
info "Fichier: $USER_DIR/default.nix"

if gum confirm "Éditer le fichier maintenant ?"; then
    ${EDITOR:-nvim} "$USER_DIR/default.nix"
fi
