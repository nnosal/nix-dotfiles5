#!/usr/bin/env bash
# scripts/wizards/edit.sh
# Wizard pour éditer rapidement une config avec fuzzy finder
set -e

# Charger les helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils.sh"

DOTFILES_DIR="$(get_dotfiles_path)"

gum style --foreground 212 "✏️ Wizard: Éditer une Configuration"

# Liste tous les fichiers éditables
FILE=$(find "$DOTFILES_DIR" -type f \( \
    -name "*.nix" -o \
    -name "*.toml" -o \
    -name "*.lua" -o \
    -name "*.sh" -o \
    -name "*.zsh" -o \
    -name "*.yaml" -o \
    -name "*.yml" -o \
    -name "*.json" -o \
    -name "*.pkl" \
\) -not -path "*/.git/*" -not -path "*/result/*" | \
    sed "s|$DOTFILES_DIR/||" | \
    gum filter --placeholder "🔍 Quel fichier modifier ?")

if [ -z "$FILE" ]; then
    info "Aucun fichier sélectionné"
    exit 0
fi

FULL_PATH="$DOTFILES_DIR/$FILE"

info "Édition de: $FILE"

# Ouvre avec l'éditeur par défaut
${EDITOR:-nvim} "$FULL_PATH"

# Après fermeture, proposer d'appliquer
if gum confirm "Appliquer les changements maintenant ?"; then
    # Détecte si c'est un fichier Stow (dans stow/) ou Nix
    if [[ "$FILE" == stow/* ]]; then
        info "Fichier Stow détecté, re-liaison..."
        mise run stow
    else
        info "Fichier Nix détecté, reconstruction..."
        mise run switch
    fi
    success "Changements appliqués !"
fi
