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
  # vérifier si mise.toml est trust (vérifie plusieurs emplacements possibles)
  TRUSTED=false
  for f in "$HOME/dotfiles/mise.toml" "$PWD/mise.toml"; do
    if [ -f "$f" ]; then
      if mise trust "$f" >/dev/null 2>&1; then
        TRUSTED=true
        break
      fi
    fi
  done
  # tenter le root git si disponible
  if ! $TRUSTED && command -v git >/dev/null 2>&1; then
    if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
      if [ -f "$git_root/mise.toml" ]; then
        if mise trust "$git_root/mise.toml" >/dev/null 2>&1; then
          TRUSTED=true
        fi
      fi
    fi
  fi

  if $TRUSTED; then
    success "Le fichier mise.toml est trusté"
  else
    warning "Le fichier mise.toml n'est pas trusté — exécutez: mise trust ~/dotfiles/mise.toml (ou 'mise trust <chemin>')"
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

# Vérifier un ensemble d'outils courants
missing_tools=()
for t in gum hk fzf bat shfmt stylua pkl starship; do
  if command -v "$t" >/dev/null 2>&1; then
    success "$t trouvé"
  else
    missing_tools+=("$t")
    warning "$t introuvable"
  fi
done

# Si des outils sont manquants et que 'mise' est disponible, tenter une installation automatique
if [ ${#missing_tools[@]} -gt 0 ] && command -v mise >/dev/null 2>&1; then
  info "Des outils sont manquants: ${missing_tools[*]}. Tentative d'installation via 'mise install --verbose'..."
  if mise install --verbose; then
    info "Relancement du contrôle des outils..."
    for t in "${missing_tools[@]}"; do
      if command -v "$t" >/dev/null 2>&1; then
        success "$t installé"
      else
        warning "$t toujours manquant"
      fi
    done
  else
    warning "'mise install' a échoué — exécutez 'mise install --verbose' manuellement pour diagnostiquer"
  fi
fi

info "Si des éléments sont encore manquants, ré-exécutez 'mise install --verbose' ou suivez les conseils affichés ci-dessus."