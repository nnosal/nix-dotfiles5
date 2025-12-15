#!/usr/bin/env bash
# templates/wizard.sh
# Template pour créer un nouveau script Wizard
# Variables à remplacer: %WIZARD_NAME%, %DESCRIPTION%
set -e

# Charger les helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils.sh"

DOTFILES_DIR="$(get_dotfiles_path)"

# Vérifier les dépendances
check_dependencies gum || exit 1

# Bannière
gum style --foreground 212 "%DESCRIPTION%"

# --- VOTRE LOGIQUE ICI ---

# 1. Collecter les inputs
# INPUT=$(gum input --placeholder "Entrez une valeur")

# 2. Choisir une option
# CHOICE=$(gum choose "Option 1" "Option 2" "Annuler")
# [[ "$CHOICE" == "Annuler" ]] && exit 0

# 3. Confirmer
# if ! gum confirm "Continuer ?"; then
#     info "Annulation"
#     exit 0
# fi

# 4. Effectuer l'action
# ...

# 5. Proposer d'appliquer
# if gum confirm "Appliquer maintenant ?"; then
#     mise run switch
#     success "Appliqué !"
# fi

success "Wizard %WIZARD_NAME% terminé !"
