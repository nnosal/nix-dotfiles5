#!/usr/bin/env bash
# scripts/check_env.sh
# Vérifie la présence de mise / nh / gum et affiche des conseils d'action
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Import utils si disponible
if [ -f "$SCRIPT_DIR/utils.sh" ]; then
  # shellcheck source=/dev/null
  . "$SCRIPT_DIR/utils.sh"
else
  info() { printf '\033[0;34mℹ️  %s\033[0m\n' "$1"; }
  success() { printf '\033[0;32m✅ %s\033[0m\n' "$1"; }
  warning() { printf '\033[0;33m⚠️  %s\033[0m\n' "$1"; }
  error() { printf '\033[0;31m❌ %s\033[0m\n' "$1"; }
fi

info "Vérification de l'environnement post-bootstrap..."

# Mise
if command -v mise >/dev/null 2>&1; then
  ver=$(mise --version 2>/dev/null || true)
  success "mise trouvé${ver:+ — $ver}"
  # vérifier si mise.toml est trust
  if mise trust "$HOME/dotfiles/mise.toml" >/dev/null 2>&1; then
    success "Le fichier mise.toml est trusté"
  else
    warning "Le fichier mise.toml n'est pas trusté — exécutez: mise trust ~/dotfiles/mise.toml"
  fi
else
  warning "mise introuvable — installez avec: curl https://mise.run | sh, puis ouvrez un nouveau terminal ou 'source ~/.zshrc'"
fi

# NH
if command -v nh >/dev/null 2>&1; then
  ver=$(nh --version 2>/dev/null || true)
  success "nh trouvé${ver:+ — $ver}"
else
  if command -v nix >/dev/null 2>&1; then
    warning "nh introuvable — installez-le via Nix: 'nix profile install nixpkgs#nh'"
    info "Commande temporaire: 'nix shell nixpkgs#nh -c nh'"
  else
    warning "nh introuvable et Nix absent — installez 'nh' manuellement (voir README)"
  fi
fi

# Gum
if command -v gum >/dev/null 2>&1; then
  success "gum trouvé"
else
  warning "gum introuvable — certains prompts interactifs pourraient ne pas fonctionner (installer via 'mise install' ou votre gestionnaire de paquets)"
fi

# HK
if command -v hk >/dev/null 2>&1; then
  success "hk trouvé"
else
  warning "hk introuvable — les hooks git peuvent ne pas être installés"
fi

info "Si des éléments sont manquants, ré-exécutez 'mise install --verbose' ou suivez les conseils affichés ci-dessus."