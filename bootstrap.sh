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
            if nix --extra-experimental-features 'nix-command flakes' profile install nixpkgs#nh; then
                success "nh installé via Nix"
            else
                warning "Échec de l'installation de 'nh' via Nix. Vous pouvez utiliser 'nix shell nixpkgs#nh -c nh' en attendant."
            fi
        else
            warning "nh introuvable et Nix absent en CI — installez 'nh' manuellement."
        fi
    fi

    # Pour les commandes 'nh' (et 'nix' modernes), activer les features expérimentales si possible
    if command -v nix >/dev/null 2>&1; then
        export NIX_CONFIG="experimental-features = nix-command flakes"
        info "Activé NIX_CONFIG pour permettre les commandes 'nh' et 'nix' modernes"
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

# Détection du shell et persistance de l'activation de 'mise' dans le(s) fichier(s) de démarrage approprié(s)
SHELL_NAME="$(basename "${SHELL:-sh}")"
info "Shell utilisateur détecté: $SHELL_NAME"

# Exports persistants et pour la session courante
export_line='export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"'
activate_line='eval "$("$HOME/.local/bin/mise" activate $SHELL_NAME 2>/dev/null)"'

# Ajouter les lignes aux fichiers de démarrage appropriés (sans dupliquer)
add_line_if_missing() {
    file="$1"
    line="$2"
    if [ -f "$file" ]; then
        if ! grep -qF "$line" "$file" 2>/dev/null; then
            echo "" >> "$file"
            echo "$line" >> "$file"
            info "Ajouté à $file"
        fi
    else
        # Créer le fichier et écrire la ligne
        printf "%s\n" "$line" > "$file"
        info "Fichier $file créé et mise en place"
    fi
}

case "$SHELL_NAME" in
    zsh)
        add_line_if_missing "$HOME/.zprofile" "$export_line"
        add_line_if_missing "$HOME/.zshrc" "$activate_line"
        ;;
    bash)
        add_line_if_missing "$HOME/.bash_profile" "$export_line"
        add_line_if_missing "$HOME/.bashrc" "$activate_line"
        ;;
    *)
        # Generic fallback
        add_line_if_missing "$HOME/.profile" "$export_line"
        add_line_if_missing "$HOME/.profile" "$activate_line"
        ;;
esac

# Tenter une activation immédiate dans la session courante — attendre que 'mise' soit réellement exécutable
max_wait=30
waited=0
while [ "$waited" -lt "$max_wait" ]; do
    if command -v "$HOME/.local/bin/mise" >/dev/null 2>&1 || command -v mise >/dev/null 2>&1; then
        # Exécuter activation (silencieusement si possible)
        if "$HOME/.local/bin/mise" activate "$SHELL_NAME" >/dev/null 2>&1; then
            info "mise activé pour le shell $SHELL_NAME"
            break
        fi
    fi
    sleep 1
    waited=$((waited+1))
done
if [ "$waited" -ge "$max_wait" ]; then
    warning "Impossible d'activer 'mise' dans la session courante après ${max_wait}s; ouvrez un nouveau terminal ou exécutez manuellement: $export_line && $activate_line"

    # Si le binaire n'existe vraiment pas, créer un wrapper temporaire qui relance l'installeur
    if [ ! -x "$HOME/.local/bin/mise" ]; then
        info "Création d'un wrapper temporaire ~/.local/bin/mise pour récupérer l'installateur si nécessaire"
        mkdir -p "$HOME/.local/bin"
        cat > "$HOME/.local/bin/mise" <<'EOF'
#!/usr/bin/env bash
set -e
# Wrapper temporaire: si le binaire 'mise' n'est pas présent, ré-exécute l'installeur puis exec
if command -v mise >/dev/null 2>&1; then
  exec mise "$@"
fi
if [ -x "$HOME/.local/share/mise/shims/mise" ]; then
  exec "$HOME/.local/share/mise/shims/mise" "$@"
fi
# Lancer l'installeur pour tenter de restaurer le binaire
printf "\033[0;34mℹ️  Tentative d'installation de 'mise' (wrapper)...\033[0m\n"
if curl -fsSL https://mise.run | sh; then
  # Rafraîchir PATH
  export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
  # attendre un peu
  waited=0
  while [ $waited -lt 15 ]; do
    if command -v mise >/dev/null 2>&1; then
      exec mise "$@"
    fi
    sleep 1
    waited=$((waited+1))
  done
fi
printf "\033[0;31m❌ 'mise' introuvable après tentative d'installation.\033[0m\n" >&2
exit 2
EOF
        chmod +x "$HOME/.local/bin/mise"
        info "Wrapper créé: ~/.local/bin/mise"
        # Tenter d'utiliser ce wrapper pour activer/réinstaller les outils
        export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
        if "$HOME/.local/bin/mise" --version >/dev/null 2>&1; then
            info "Wrapper mis en place et 'mise' répond"
        else
            warning "Le wrapper n'a pas pu activer 'mise' immédiatement. Réessayez: source votre rc (ex: $export_line && $activate_line) ou relancez le bootstrap."
        fi
    fi
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
    # Si Nix est présent, activer les features expérimentales pour NH/nix
    if command -v nix >/dev/null 2>&1; then
        export NIX_CONFIG="experimental-features = nix-command flakes"
        info "Export NIX_CONFIG pour permettre les commandes 'nh' et 'nix' modernes"
    fi
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
case "$SHELL_NAME" in
    zsh) rc_hint="source ~/.zshrc (ou ouvrir un nouveau terminal)" ;;
    bash) rc_hint="source ~/.bashrc (ou ouvrir un nouveau terminal)" ;;
    *) rc_hint="ouvrez un nouveau terminal ou sourcez votre fichier de démarrage" ;;
esac
echo "  1. $rc_hint"
echo "  2. Lancez le Cockpit: cockpit (ou mise run ui)"
echo ""
