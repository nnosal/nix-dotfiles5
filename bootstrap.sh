#!/usr/bin/env bash
# bootstrap.sh
# Script d'installation "Zero-Install" pour macOS et Linux
# Usage: sh <(curl -L https://raw.githubusercontent.com/nnosal/nix-dotfiles5/main/bootstrap.sh)
set -e

# ============================================
# CONFIGURATION
# ============================================
REPO_URL="https://github.com/nnosal/nix-dotfiles5.git"
DOTFILES_DIR="$HOME/dotfiles"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

# ============================================
# DÉTECTION OS
# ============================================
detect_os() {
    case "$OSTYPE" in
        darwin*)  echo "darwin" ;;
        linux*)   
            if grep -q Microsoft /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        *)        echo "unknown" ;;
    esac
}

OS=$(detect_os)
info "Système détecté: $OS"

# ============================================
# BANNIÈRE
# ============================================
echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  🚀 ULTIMATE DOTFILES BOOTSTRAP${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# ============================================
# INSTALLATION DE NIX
# ============================================
if ! command -v nix &> /dev/null; then
    info "Installation de Nix..."
    
    if [[ "$OS" == "darwin" ]]; then
        # macOS: Nix daemon multi-user
        sh <(curl -L https://nixos.org/nix/install)
    else
        # Linux: Nix daemon
        sh <(curl -L https://nixos.org/nix/install) --daemon
    fi
    
    # Sourcer Nix pour cette session
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
    
    success "Nix installé !"
else
    success "Nix déjà installé"
fi

# ============================================
# MODE CI (NON-INTERACTIF)
# ============================================
if [[ "$CI" == "true" ]]; then
    info "Mode CI détecté: Installation non-interactive"
    
    # Cloner directement
    if [ ! -d "$DOTFILES_DIR" ]; then
        git clone "$REPO_URL" "$DOTFILES_DIR"
    fi
    
    cd "$DOTFILES_DIR"
    
    # Installer mise
    if ! command -v mise &> /dev/null; then
        curl https://mise.run | sh
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    # Setup
    mise install
    ./scripts/cockpit.sh --apply-only
    
    success "Installation CI terminée !"
    exit 0
fi

# ============================================
# SHELL ÉPHÉMÈRE AVEC GUM
# ============================================
info "Lancement du shell éphémère avec Git et Gum..."

# Créer un script temporaire pour l'installation interactive
TEMP_SCRIPT=$(mktemp)
cat > "$TEMP_SCRIPT" << 'EPHEMERAL'
#!/usr/bin/env bash
set -e

REPO_URL="https://github.com/nnosal/nix-dotfiles5.git"
DEFAULT_DIR="$HOME/dotfiles"

# Bannière Gum
gum style \
    --border double \
    --margin "1" \
    --padding "1 2" \
    --border-foreground 212 \
    "🚀 Ultimate Dotfiles Installer"

# Confirmer l'installation
if ! gum confirm "Installer les dotfiles ?"; then
    echo "❌ Installation annulée"
    exit 0
fi

# Demander le chemin
DOTFILES_DIR=$(gum input \
    --placeholder "Chemin d'installation" \
    --value "$DEFAULT_DIR")

# Cloner
if [ -d "$DOTFILES_DIR" ]; then
    gum style --foreground 226 "⚠️ Le dossier existe déjà"
    if gum confirm "Mettre à jour (git pull) ?"; then
        cd "$DOTFILES_DIR"
        git pull
    fi
else
    gum spin --spinner dot --title "Clonage du repo..." -- \
        git clone "$REPO_URL" "$DOTFILES_DIR"
fi

cd "$DOTFILES_DIR"

# Installer Mise
if ! command -v mise &> /dev/null; then
    gum spin --spinner dot --title "Installation de Mise..." -- \
        bash -c 'curl -fsSL https://mise.run | sh'
    export PATH="$HOME/.local/bin:$PATH"
fi

# Setup
gum spin --spinner dot --title "Installation des outils (Mise)..." -- \
    mise install

# Choisir le profil
PROFIL=$(gum choose "work" "personal" "none" --header "Quel profil appliquer ?")
export MACHINE_CONTEXT="$PROFIL"

# Appliquer
gum style --foreground 212 "🛠️ Application de la configuration..."
./scripts/cockpit.sh --apply-only

gum style --foreground 46 "
✅ Installation terminée !

Lancez un nouveau terminal ou:
  source ~/.zshrc

Pour accéder au Cockpit:
  cockpit
  # ou
  mise run ui
"
EPHEMERAL

chmod +x "$TEMP_SCRIPT"

# Exécuter dans un shell éphémère avec Git et Gum
nix shell nixpkgs#git nixpkgs#gum --command bash "$TEMP_SCRIPT"

# Cleanup
rm -f "$TEMP_SCRIPT"

success "Bootstrap terminé !"
