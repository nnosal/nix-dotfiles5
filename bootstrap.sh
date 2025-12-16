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

    # Faire confiance au fichier de config pour que 'mise install' puisse s'exécuter non interactif
    if command -v mise >/dev/null 2>&1; then
        info "Confiance du fichier de configuration mise.toml (CI)..."
        mise trust "$DOTFILES_DIR/mise.toml" || true
    fi

    # Setup
    if ! mise install; then
        warning "La commande 'mise install' a échoué en CI — exécutez 'mise install --verbose' pour plus de détails."
    fi

    # Si 'nh' est toujours absent, tenter une installation via Nix
    if ! command -v nh >/dev/null 2>&1; then
        if command -v nix >/dev/null 2>&1; then
            info "nh introuvable (CI) — tentative d'installation via Nix (nix profile install nixpkgs#nh)..."
            if nix profile install nixpkgs#nh; then
                success "nh installé via Nix"
            else
                warning "Échec de l'installation de 'nh' via Nix. Vous pouvez utiliser 'nix shell nixpkgs#nh -c nh' en attendant."
            fi
        else
            warning "nh introuvable et Nix absent en CI — installez 'nh' manuellement."
        fi
    fi

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
    # Export immédiat pour éviter les problèmes de timing
    export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
    # Attendre que le binaire soit disponible (race condition fix)
    timeout=15
    elapsed=0
    while [ ! -x "$HOME/.local/bin/mise" ] && [ "$elapsed" -lt "$timeout" ]; do
        sleep 1
        elapsed=$((elapsed+1))
    done
    if [ ! -x "$HOME/.local/bin/mise" ]; then
        warning "mise installé mais binaire introuvable après ${timeout}s; continuer et tenter l'activation"
    fi
fi

# s'assurer que les shims sont dans le PATH
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"

success "Mise installé"

# Activer 'mise' pour le shell courant et persister dans le rc (zsh)
SHELL_NAME="$(basename "$SHELL")"
if [ "$SHELL_NAME" = "zsh" ]; then
    if [ -f "$HOME/.zshrc" ] && ! grep -q "mise activate zsh" "$HOME/.zshrc" 2>/dev/null; then
        echo 'eval "$($HOME/.local/bin/mise activate zsh)"' >> "$HOME/.zshrc"
    fi
    # Activer maintenant pour la session courante
    eval "$($HOME/.local/bin/mise activate zsh)" || true
else
    # Fallback: écrire dans .zshrc si présent
    if [ -f "$HOME/.zshrc" ] && ! grep -q "mise activate zsh" "$HOME/.zshrc" 2>/dev/null; then
        echo 'eval "$($HOME/.local/bin/mise activate zsh)"' >> "$HOME/.zshrc"
    fi
    eval "$($HOME/.local/bin/mise activate zsh)" || true
fi

# Faire confiance au fichier de config pour que 'mise install' puisse s'exécuter non interactif
if command -v mise >/dev/null 2>&1; then
    info "Confiance du fichier de configuration mise.toml..."
    mise trust "$DOTFILES_DIR/mise.toml" || true
fi

# ============================================
# INSTALLER LES OUTILS VIA MISE (retry + doctor)
# ============================================
info "Installation des outils (gum, hk, etc.)..."
# Essayer jusqu'à 3 fois pour laisser le temps aux shims d'apparaître
attempts=0
max_attempts=3
while [ "$attempts" -lt "$max_attempts" ]; do
    if mise install --verbose; then
        # Vérifier l'état général via doctor (retour 0 = OK)
        if mise doctor --quiet >/dev/null 2>&1; then
            success "Outils installés et mise OK"
            break
        else
            warning "mise install réussi mais 'mise doctor' signale des problèmes — retry..."
        fi
    else
        warning "La commande 'mise install' a échoué — retry..."
    fi
    attempts=$((attempts+1))
    sleep 2
done
if [ "$attempts" -ge "$max_attempts" ]; then
    warning "mise install échoue encore — exécutez 'mise install --verbose' manuellement pour diagnostiquer"
fi

# Si 'nh' est toujours absent, tenter une installation via Nix (plus robuste)
if ! command -v nh >/dev/null 2>&1; then
    if command -v nix >/dev/null 2>&1; then
        info "nh introuvable — tentative d'installation via Nix (profile install)..."
        if nix --extra-experimental-features 'nix-command flakes' profile install nixpkgs#nh >/dev/null 2>&1; then
            success "nh installé via Nix"
        else
            warning "Installation de 'nh' via Nix profile échouée — création d'un wrapper 'nh' utilisant 'nix shell' (fallback temporaire)."
            mkdir -p "$HOME/.local/bin"
            cat > "$HOME/.local/bin/nh" <<'EOF'
#!/usr/bin/env bash
# Wrapper temporaire qui invoque nh via nix shell
exec nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#nh -c nh "$@"
EOF
            chmod +x "$HOME/.local/bin/nh"
            success "Wrapper créé dans ~/.local/bin/nh (utilise 'nix shell nixpkgs#nh -c nh')"
            info "Pour installer de façon permanente, réessayez: nix --extra-experimental-features 'nix-command flakes' profile install nixpkgs#nh"
        fi
    else
        warning "nh introuvable et Nix absent — installez 'nh' manuellement (ex: 'nix shell nixpkgs#nh')."
    fi
fi

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
# Vérification finale de l'environnement (diagnostic utile)
if [ -x "./scripts/check_env.sh" ]; then
    ./scripts/check_env.sh || true
else
    bash ./scripts/check_env.sh || true
fi

success "Installation terminée !"
echo ""
printf '\033[0;36mProchaines étapes:\033[0m\n'
echo "  1. Ouvrez un nouveau terminal ou: source ~/.zshrc"
echo "  2. Lancez le Cockpit: cockpit (ou mise run ui)"
echo ""
