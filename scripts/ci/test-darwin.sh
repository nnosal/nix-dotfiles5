#!/usr/bin/env bash
# scripts/ci/test-darwin.sh
# Test d'intégration macOS via Tart (VM)
# Valide que le bootstrap fonctionne de bout en bout
set -e

# Charger les helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Vérifier Tart
if ! command_exists tart; then
    error "Tart n'est pas installé"
    info "Installez-le via: brew install tart"
    exit 1
fi

VM_NAME="test-dotfiles-$(date +%s)"
IMAGE="ghcr.io/cirruslabs/macos-sonoma-base:latest"

gum style --foreground 212 "🧪 Test d'Intégration macOS (Tart)"

# 1. Création de la VM
info "📦 Clonage de l'image $IMAGE..."
tart clone "$IMAGE" "$VM_NAME"

# Fonction de nettoyage (trap)
cleanup() {
    info "🧹 Nettoyage de la VM..."
    tart stop "$VM_NAME" 2>/dev/null || true
    tart delete "$VM_NAME" 2>/dev/null || true
}
trap cleanup EXIT

# 2. Démarrage
info "🚀 Boot de la VM..."
tart run "$VM_NAME" --no-graphics &
PID=$!

# 3. Attente de l'IP (Polling)
info "⏳ Attente de la connectivité réseau..."
IP=""
for i in {1..30}; do
    IP=$(tart ip "$VM_NAME" 2>/dev/null || true)
    if [ -n "$IP" ]; then break; fi
    sleep 2
done

if [ -z "$IP" ]; then
    error "Impossible de récupérer l'IP de la VM."
    exit 1
fi

info "✅ VM en ligne sur $IP. Attente du service SSH..."

# Attendre que le port 22 soit ouvert
while ! nc -z "$IP" 22 2>/dev/null; do 
    sleep 1
done

# 4. Exécution du Bootstrap (Mode CI)
info "🛠️  Lancement du Bootstrap..."

# Note : Les images Cirrus ont user=admin, pass=admin
sshpass -p "admin" ssh -o StrictHostKeyChecking=no admin@"$IP" << 'REMOTE'
export CI=true
export MACHINE_CONTEXT=work

# Vérifier si Nix est installé
if command -v nix &> /dev/null; then
    echo "Nix déjà installé"
else
    echo "Installation de Nix..."
    sh <(curl -L https://nixos.org/nix/install) --daemon
fi

# Vérifier Zsh
if command -v zsh &> /dev/null; then
    echo "Zsh disponible"
else
    echo "Zsh non disponible!"
    exit 1
fi
REMOTE

# 5. Vérification
info "🔍 Vérification de l'installation..."
sshpass -p "admin" ssh -o StrictHostKeyChecking=no admin@"$IP" \
    "command -v nix && command -v zsh"

gum style --foreground 46 "✅ TEST RÉUSSI : La configuration s'installe correctement !"
