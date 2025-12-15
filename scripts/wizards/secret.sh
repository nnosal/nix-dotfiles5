#!/usr/bin/env bash
# scripts/wizards/secret.sh
# Wizard pour gérer les secrets Fnox
set -e

# Charger les helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils.sh"

DOTFILES_DIR="$(get_dotfiles_path)"

gum style --foreground 212 "🔒 Wizard: Gérer les Secrets"

# Menu
ACTION=$(gum choose \
    "➕ Ajouter un secret" \
    "📝 Lister les secrets (fnox.toml)" \
    "🔍 Vérifier un secret" \
    "← Retour")

case "$ACTION" in
    "➕ Ajouter"*)
        # Collecte d'infos
        KEY=$(gum input --placeholder "Nom de la variable (ex: STRIPE_KEY)")
        
        if [ -z "$KEY" ]; then
            error "Nom vide, annulation"
            exit 1
        fi
        
        VAL=$(gum input --password --placeholder "Valeur du secret")
        
        if [ -z "$VAL" ]; then
            error "Valeur vide, annulation"
            exit 1
        fi
        
        # Détection OS pour choisir le bon backend
        OS=$(detect_os)
        
        case "$OS" in
            darwin)
                info "macOS détecté: Stockage dans Keychain..."
                # Utiliser fnox si disponible, sinon security
                if command_exists fnox; then
                    fnox set "$KEY" "$VAL"
                else
                    security add-generic-password -s "fnox-$KEY" -a "$USER" -w "$VAL"
                fi
                ;;
            linux|wsl)
                info "Linux détecté: Stockage via secret-tool ou pass..."
                if command_exists secret-tool; then
                    echo "$VAL" | secret-tool store --label="Fnox $KEY" service fnox key "$KEY"
                elif command_exists pass; then
                    echo "$VAL" | pass insert -m "fnox/$KEY"
                else
                    error "Aucun gestionnaire de secrets trouvé (secret-tool ou pass)"
                    exit 1
                fi
                ;;
            *)
                error "OS non supporté: $OS"
                exit 1
                ;;
        esac
        
        success "Secret $KEY enregistré localement !"
        
        # Vérifier si déjà dans fnox.toml
        FNOX_FILE="$DOTFILES_DIR/fnox.toml"
        if ! grep -q "$KEY" "$FNOX_FILE"; then
            warning "$KEY n'est pas référencé dans fnox.toml"
            if gum confirm "Ajouter la référence dans fnox.toml ?"; then
                echo "$KEY = \"keychain://${KEY,,}\"" >> "$FNOX_FILE"
                success "Référence ajoutée dans fnox.toml"
            fi
        fi
        ;;
        
    "📝 Lister"*)
        info "Secrets référencés dans fnox.toml:"
        echo ""
        grep -E "^[A-Z_]+\s*=" "$DOTFILES_DIR/fnox.toml" | \
            while read line; do
                KEY=$(echo "$line" | cut -d'=' -f1 | tr -d ' ')
                REF=$(echo "$line" | cut -d'=' -f2 | tr -d ' "')
                echo "  🔑 $KEY -> $REF"
            done
        ;;
        
    "🔍 Vérifier"*)
        KEY=$(gum input --placeholder "Nom de la variable à vérifier")
        
        if [ -z "$KEY" ]; then
            exit 0
        fi
        
        info "Vérification de $KEY..."
        
        # Tester si le secret existe dans l'env (via fnox)
        if command_exists fnox; then
            eval "$(fnox activate bash)"
            if [ -n "${!KEY}" ]; then
                success "$KEY est défini (valeur masquée)"
            else
                warning "$KEY n'est pas défini ou inaccessible"
            fi
        else
            warning "fnox non disponible pour la vérification"
        fi
        ;;
        
    *)
        exit 0
        ;;
esac
