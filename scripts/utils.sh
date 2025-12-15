#!/usr/bin/env bash
# scripts/utils.sh
# Fonctions utilitaires pour les scripts du Cockpit
set -e

# ============================================
# COULEURS ET STYLES
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================
# FONCTIONS D'AFFICHAGE
# ============================================
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# ============================================
# VÉRIFICATIONS
# ============================================

# Vérifie si une commande existe
command_exists() {
    command -v "$1" &> /dev/null
}

# Vérifie les dépendances requises
check_dependencies() {
    local missing=()
    for cmd in "$@"; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        error "Dépendances manquantes: ${missing[*]}"
        info "Lancez 'mise install' pour les installer"
        return 1
    fi
}

# Détecte l'OS
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
        msys*|cygwin*) echo "windows" ;;
        *)        echo "unknown" ;;
    esac
}

# Détecte l'architecture
detect_arch() {
    case "$(uname -m)" in
        x86_64)  echo "x86_64" ;;
        arm64|aarch64) echo "aarch64" ;;
        *)       echo "unknown" ;;
    esac
}

# ============================================
# HELPERS NIX
# ============================================

# Vérifie si Nix est installé
nix_installed() {
    command_exists nix
}

# Vérifie si c'est un système NixOS
is_nixos() {
    [ -f /etc/NIXOS ]
}

# Vérifie si nix-darwin est actif
is_darwin() {
    [[ "$(detect_os)" == "darwin" ]]
}

# ============================================
# GUM HELPERS (SI DISPONIBLE)
# ============================================

# Confirmation avec fallback
confirm() {
    local message="${1:-Continuer ?}"
    
    if command_exists gum; then
        gum confirm "$message"
    else
        read -p "$message [y/N] " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]]
    fi
}

# Input avec fallback
ask_input() {
    local placeholder="${1:-Entrez une valeur}"
    
    if command_exists gum; then
        gum input --placeholder "$placeholder"
    else
        read -p "$placeholder: " value
        echo "$value"
    fi
}

# Choix avec fallback
ask_choice() {
    local header="$1"
    shift
    local options=("$@")
    
    if command_exists gum; then
        gum choose --header "$header" "${options[@]}"
    else
        echo "$header"
        select opt in "${options[@]}"; do
            echo "$opt"
            break
        done
    fi
}

# ============================================
# HELPERS FICHIERS
# ============================================

# Retourne le chemin absolu du repo dotfiles
get_dotfiles_path() {
    # On suppose qu'on est dans le repo
    cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd
}

# Backup un fichier avant modification
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "${file}.bak.$(date +%Y%m%d_%H%M%S)"
    fi
}
