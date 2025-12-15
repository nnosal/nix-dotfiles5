#!/bin/sh
# bootstrap.sh
# Script d'installation "Zero-Install" pour macOS et Linux
# Usage: curl -fsSL https://raw.githubusercontent.com/nnosal/nix-dotfiles5/main/bootstrap.sh | sh
# Ou:    sh -c "$(curl -fsSL https://raw.githubusercontent.com/nnosal/nix-dotfiles5/main/bootstrap.sh)"
#
# Ce script est POSIX-compatible (sh) pour fonctionner partout

set -e

# ============================================
# CONFIGURATION
# ============================================
REPO_URL="https://github.com/nnosal/nix-dotfiles5.git"
DOTFILES_DIR="$HOME/dotfiles"

# ============================================
# FONCTIONS (POSIX compatible)
# ============================================
info() { printf '\033[0;34mℹ️  %s\033[0m\n' "$1"; }
success() { printf '\033[0;32m✅ %s\033[0m\n' "$1"; }
warning() { printf '\033[0;33m⚠️  %s\033[0m\n' "$1"; }
error() { printf '\033[0;31m❌ %s\033[0m\n' "$1"; }

# ============================================
# DÉTECTION OS (POSIX compatible)
# ============================================
detect_os() {
    case "$(uname -s)" in
        Darwin*)  echo "darwin" ;;
        Linux*)   
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
printf '\033[0;32m======================================\033[0m\n'
printf '\033[0;32m  🚀 ULTIMATE DOTFILES BOOTSTRAP\033[0m\n'
printf '\033[0;32m======================================\033[0m\n'
echo ""

# ============================================
# INSTALLATION DE NIX
# ============================================
if ! command -v nix >/dev/null 2>&1; then
    info "Installation de Nix..."
    
    # Télécharger et exécuter l'installeur Nix
    curl -L https://nixos.org/nix/install -o /tmp/nix-install.sh
    
    if [ "$OS" = "darwin" ]; then
        # macOS: Nix daemon multi-user
        sh /tmp/nix-install.sh
    else
        # Linux: Nix daemon
        sh /tmp/nix-install.sh --daemon
    fi
    
    rm -f /tmp/nix-install.sh
    
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
if [ "$CI" = "true" ]; then
    info "Mode CI détecté: Installation non-interactive"
    
    # Cloner directement
    if [ ! -d "$DOTFILES_DIR" ]; then
        git clone "$REPO_URL" "$DOTFILES_DIR"
    fi
    
    cd "$DOTFILES_DIR"
    
    # Installer mise
    if ! command -v mise >/dev/null 2>&1; then
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
# INSTALLATION INTERACTIVE
# ============================================
info "Lancement de l'installation interactive..."

# Vérifier si git est disponible
if ! command -v git >/dev/null 2>&1; then
    info "Git non trouvé, installation via Nix..."
    # Utiliser nix-shell pour avoir git temporairement
    nix-shell -p git --run "git clone $REPO_URL $DOTFILES_DIR"
else
    # Cloner ou mettre à jour
    if [ -d "$DOTFILES_DIR" ]; then
        warning "Le dossier $DOTFILES_DIR existe déjà"
        printf "Mettre à jour (git pull) ? [y/N] "
        read -r REPLY
        if [ "$REPLY" = "y" ] || [ "$REPLY" = "Y" ]; then
            cd "$DOTFILES_DIR"
            git pull
        fi
    else
        info "Clonage du repo..."
        git clone "$REPO_URL" "$DOTFILES_DIR"
    fi
fi

cd "$DOTFILES_DIR"

# ============================================
# INSTALLER MISE
# ============================================
if ! command -v mise >/dev/null 2>&1; then
    info "Installation de Mise..."
    curl -fsSL https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

success "Mise installé"

# ============================================
# INSTALLER LES OUTILS VIA MISE
# ============================================
info "Installation des outils (gum, hk, nh, etc.)..."
mise install

# ============================================
# CHOIX DU PROFIL (si gum disponible)
# ============================================
if command -v gum >/dev/null 2>&1; then
    # Mode interactif avec Gum
    gum style \
        --border double \
        --margin "1" \
        --padding "1 2" \
        --border-foreground 212 \
        "🎮 Configuration Ultimate Dotfiles"
    
    PROFIL=$(gum choose "work" "personal" "none" --header "Quel profil Stow appliquer ?")
    export MACHINE_CONTEXT="$PROFIL"
    
    # Appliquer
    info "Application de la configuration..."
    ./scripts/cockpit.sh --apply-only
else
    # Mode texte basique
    printf "Quel profil appliquer ? (work/personal/none) [none]: "
    read -r PROFIL
    PROFIL="${PROFIL:-none}"
    export MACHINE_CONTEXT="$PROFIL"
    
    info "Application de la configuration..."
    ./scripts/cockpit.sh --apply-only
fi

# ============================================
# FIN
# ============================================
echo ""
success "Installation terminée !"
echo ""
printf '\033[0;36mProchaines étapes:\033[0m\n'
echo "  1. Ouvrez un nouveau terminal ou: source ~/.zshrc"
echo "  2. Lancez le Cockpit: cockpit (ou mise run ui)"
echo ""
