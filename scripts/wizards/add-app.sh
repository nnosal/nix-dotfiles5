#!/usr/bin/env bash
# scripts/wizards/add-app.sh
# Wizard pour ajouter une application (Cask macOS ou Package Nix)
set -e

# Charger les helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils.sh"

check_dependencies gum || exit 1

DOTFILES_DIR="$(get_dotfiles_path)"

gum style --foreground 212 "✨ Wizard: Ajouter une Application"

# 1. Choisir le type
TYPE=$(gum choose \
    "GUI App (Mac Cask)" \
    "CLI Tool (Tous OS)" \
    "Annuler")

[[ "$TYPE" == "Annuler" ]] && exit 0

# 2. Nom de l'app
APP_NAME=$(gum input --placeholder "Nom du paquet (ex: vlc, ripgrep)")

if [ -z "$APP_NAME" ]; then
    error "Nom vide, annulation"
    exit 1
fi

# 3. Déterminer la cible
if [[ "$TYPE" == "GUI App (Mac Cask)" ]]; then
    TARGET="$DOTFILES_DIR/modules/darwin/apps.nix"
    MARKER="# %% CASKS %%"
    LINE="    \"$APP_NAME\""
    DESCRIPTION="Cask macOS"
else
    TARGET="$DOTFILES_DIR/modules/common/packages.nix"
    MARKER="# %% PACKAGES %%"
    LINE="    $APP_NAME"
    DESCRIPTION="Package Nix (tous OS)"
fi

# 4. Vérifier que le fichier existe
if [ ! -f "$TARGET" ]; then
    error "Fichier cible non trouvé: $TARGET"
    exit 1
fi

# 5. Vérifier si déjà présent
if grep -q "$APP_NAME" "$TARGET"; then
    warning "$APP_NAME semble déjà présent dans $TARGET"
    gum confirm "Continuer quand même ?" || exit 0
fi

# 6. Vérifier que le marqueur existe
if ! grep -q "$MARKER" "$TARGET"; then
    error "Marqueur '$MARKER' non trouvé dans $TARGET"
    info "Ajoutez le marqueur manuellement dans le fichier"
    exit 1
fi

# 7. Injection via sed
info "Ajout de $APP_NAME dans $TARGET..."

# Backup
backup_file "$TARGET"

# Insert avant le marqueur
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS sed
    sed -i '' "/$MARKER/i\\
$LINE
" "$TARGET"
else
    # GNU sed
    sed -i "/$MARKER/i $LINE" "$TARGET"
fi

success "$APP_NAME ajouté comme $DESCRIPTION"

# 8. Proposer d'appliquer
if gum confirm "Appliquer la configuration maintenant ?"; then
    mise run switch
    success "Configuration appliquée !"
else
    info "N'oubliez pas de lancer 'mise run switch' plus tard"
fi
