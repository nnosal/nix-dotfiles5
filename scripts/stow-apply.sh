#!/usr/bin/env bash
# scripts/stow-apply.sh
# Applique les dotfiles via GNU Stow avec gestion des profils
set -e

# Charger les helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Vérifier stow
if ! command_exists stow; then
    error "GNU Stow n'est pas installé"
    info "Installez-le via: nix-shell -p stow"
    exit 1
fi

DOTFILES_DIR="$(get_dotfiles_path)"
STOW_DIR="$DOTFILES_DIR/stow"

info "Application des dotfiles depuis $STOW_DIR"

# 1. Créer les dossiers cibles si nécessaires
mkdir -p "$HOME/.config/zsh"
mkdir -p "$HOME/.ssh/config.d"
chmod 700 "$HOME/.ssh" 2>/dev/null || true

# 2. Nettoyage des liens morts (sécurité)
info "Nettoyage des anciens liens..."
stow --dir="$STOW_DIR" --target="$HOME" --delete common 2>/dev/null || true
stow --dir="$STOW_DIR" --target="$HOME" --delete work 2>/dev/null || true
stow --dir="$STOW_DIR" --target="$HOME" --delete personal 2>/dev/null || true

# 3. Application du socle commun (Critique)
info "🌍 Application du profil COMMON..."
stow --dir="$STOW_DIR" --target="$HOME" --restow common
success "Profil COMMON appliqué"

# 4. Détection du Profil Machine (via variable ENV ou Gum)
# Cette variable peut être définie dans hosts/.../default.nix -> home.sessionVariables
PROFIL="${MACHINE_CONTEXT:-}"

if [ -z "$PROFIL" ]; then
    # Si non défini, on demande (Interactif)
    if command_exists gum; then
        PROFIL=$(gum choose "work" "personal" "none" --header "Quel profil Stow appliquer ?")
    else
        info "Variable MACHINE_CONTEXT non définie"
        read -p "Profil (work/personal/none): " PROFIL
    fi
fi

# 5. Application conditionnelle
case "$PROFIL" in
    work)
        info "💼 Application du profil WORK..."
        stow --dir="$STOW_DIR" --target="$HOME" --restow work
        success "Profil WORK appliqué"
        ;;
    personal)
        info "🏠 Application du profil PERSONAL..."
        stow --dir="$STOW_DIR" --target="$HOME" --restow personal
        success "Profil PERSONAL appliqué"
        ;;
    none)
        info "Aucun profil supplémentaire appliqué"
        ;;
    *)
        warning "Profil '$PROFIL' inconnu, ignoré"
        ;;
esac

# 6. Permissions SSH
chmod 600 "$HOME/.ssh/config" 2>/dev/null || true
chmod 600 "$HOME/.ssh/config.d/"* 2>/dev/null || true

success "✅ Configuration déployée !"
