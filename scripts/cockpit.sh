#!/usr/bin/env bash
# scripts/cockpit.sh
# Menu Principal TUI - Cockpit Ultimate Dotfiles
set -e

# Charger les helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Vérifier les dépendances
check_dependencies gum || exit 1

# Mode non-interactif (pour CI)
if [[ "$1" == "--apply-only" ]]; then
    info "Mode non-interactif: Application de la config..."
    mise run switch
    mise run stow
    success "Configuration appliquée !"
    exit 0
fi

# Bannière
gum style \
    --border double \
    --margin "1" \
    --padding "1 2" \
    --border-foreground 212 \
    "🎮 ULTIMATE COCKPIT" \
    "$(detect_os) / $(detect_arch)"

# Menu Principal
while true; do
    CHOICE=$(gum choose \
        "🔄 Appliquer (Switch Nix)" \
        "🔗 Relier Dotfiles (Stow)" \
        "✨ Ajouter (App/Host/User)" \
        "✏️  Éditer une config (Fuzzy)" \
        "🔒 Gérer Secrets (Fnox)" \
        "🚀 Sauvegarder (Git Push)" \
        "⬆️  Mettre à jour (Flake Update)" \
        "🧹 Nettoyer (Garbage Collect)" \
        "🗑️  Désinstaller une App" \
        "🚪 Quitter")

    case $CHOICE in
        "🔄 Appliquer"*)
            info "Application de la configuration Nix..."
            mise run switch
            success "Configuration appliquée !"
            ;;
            
        "🔗 Relier"*)
            info "Application des dotfiles via Stow..."
            mise run stow
            success "Dotfiles reliés !"
            ;;
            
        "✨ Ajouter"*)
            SUB=$(gum choose \
                "Application (Cask/Pkg)" \
                "Machine (Host)" \
                "Utilisateur" \
                "← Retour")
            case $SUB in
                "Application"*) "$SCRIPT_DIR/wizards/add-app.sh" ;;
                "Machine"*)     "$SCRIPT_DIR/wizards/add-host.sh" ;;
                "Utilisateur"*) "$SCRIPT_DIR/wizards/add-user.sh" ;;
                *) continue ;;
            esac
            ;;
            
        "✏️  Éditer"*)
            "$SCRIPT_DIR/wizards/edit.sh"
            ;;
            
        "🔒 Gérer"*)
            "$SCRIPT_DIR/wizards/secret.sh"
            ;;
            
        "🚀 Sauvegarder"*)
            mise run save
            ;;
            
        "⬆️  Mettre à jour"*)
            info "Mise à jour des inputs Flake..."
            mise run update
            success "Mise à jour terminée !"
            ;;
            
        "🧹 Nettoyer"*)
            info "Nettoyage du store Nix..."
            mise run gc
            success "Nettoyage terminé !"
            ;;
            
        "🗑️  Désinstaller"*)
            "$SCRIPT_DIR/wizards/remove-app.sh"
            ;;
            
        "🚪 Quitter")
            gum style --foreground 212 "👋 À bientôt !"
            exit 0
            ;;
    esac
    
    echo ""
    gum confirm "Retour au menu ?" || break
done
