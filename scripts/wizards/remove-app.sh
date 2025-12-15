#!/usr/bin/env bash
# scripts/wizards/remove-app.sh
# Wizard pour désinstaller une application
set -e

# Charger les helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils.sh"

DOTFILES_DIR="$(get_dotfiles_path)"

check_dependencies gum || exit 1

gum style --foreground 212 "🗑️ Wizard: Désinstaller une Application"

# 1. Choisir le type
TYPE=$(gum choose \
    "GUI App (Mac Cask)" \
    "CLI Tool (Nix Package)" \
    "Annuler")

[[ "$TYPE" == "Annuler" ]] && exit 0

# 2. Choisir le fichier source
if [[ "$TYPE" == "GUI App"* ]]; then
    TARGET="$DOTFILES_DIR/modules/darwin/apps.nix"
else
    TARGET="$DOTFILES_DIR/modules/common/packages.nix"
fi

if [ ! -f "$TARGET" ]; then
    error "Fichier non trouvé: $TARGET"
    exit 1
fi

# 3. Extraire la liste des apps
info "Extraction des applications installées..."

# Extraire les lignes qui ressemblent à des paquets
if [[ "$TYPE" == "GUI App"* ]]; then
    # Pour les casks, chercher les lignes avec des guillemets
    APPS=$(grep -E '^\s+"[a-z0-9-]+"' "$TARGET" | tr -d '"' | tr -d ' ' | sort)
else
    # Pour les packages, chercher les lignes avec pkgs. ou juste le nom
    APPS=$(grep -E '^\s+[a-z]' "$TARGET" | grep -v "#" | grep -v "with pkgs" | tr -d ' ' | sort)
fi

if [ -z "$APPS" ]; then
    warning "Aucune application trouvée dans $TARGET"
    exit 0
fi

# 4. Sélectionner l'app à supprimer
APP_TO_REMOVE=$(echo "$APPS" | gum filter --placeholder "Sélectionnez l'app à supprimer")

if [ -z "$APP_TO_REMOVE" ]; then
    info "Aucune sélection, annulation"
    exit 0
fi

# 5. Confirmation
if ! gum confirm "Supprimer $APP_TO_REMOVE ?"; then
    info "Annulation"
    exit 0
fi

# 6. Backup et suppression
backup_file "$TARGET"

info "Suppression de $APP_TO_REMOVE..."

# Supprimer la ligne contenant l'app
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "/\"$APP_TO_REMOVE\"/d" "$TARGET" 2>/dev/null || \
    sed -i '' "/$APP_TO_REMOVE/d" "$TARGET"
else
    sed -i "/\"$APP_TO_REMOVE\"/d" "$TARGET" 2>/dev/null || \
    sed -i "/$APP_TO_REMOVE/d" "$TARGET"
fi

success "$APP_TO_REMOVE supprimé de la configuration"

# 7. Appliquer
if gum confirm "Appliquer la configuration maintenant ?"; then
    mise run switch
    success "Configuration appliquée !"
else
    info "N'oubliez pas de lancer 'mise run switch' plus tard"
fi
