#!/usr/bin/env bash
# scripts/wizards/add-host.sh
# Wizard pour créer une nouvelle machine (Host)
set -e

# Charger les helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils.sh"

DOTFILES_DIR="$(get_dotfiles_path)"

gum style --foreground 212 "💻 Wizard: Ajouter une Machine"

# 1. Contexte (pro/perso/infra)
CONTEXT=$(gum choose \
    "pro" \
    "perso" \
    "infra" \
    "Annuler")

[[ "$CONTEXT" == "Annuler" ]] && exit 0

# 2. Nom de la machine
HOST_NAME=$(gum input --placeholder "Nom de la machine (ex: dell-xps)")

if [ -z "$HOST_NAME" ]; then
    error "Nom vide, annulation"
    exit 1
fi

# Vérifier si existe déjà
HOST_DIR="$DOTFILES_DIR/hosts/$CONTEXT/$HOST_NAME"
if [ -d "$HOST_DIR" ]; then
    error "Le host $CONTEXT/$HOST_NAME existe déjà"
    exit 1
fi

# 3. Type d'OS
OS_TYPE=$(gum choose \
    "darwin (macOS)" \
    "nixos (Linux)" \
    "wsl (Windows)" \
    "Annuler")

[[ "$OS_TYPE" == "Annuler" ]] && exit 0

# 4. Utilisateur principal
MAIN_USER=$(gum input --placeholder "Utilisateur principal (ex: nnosal)" --value "nnosal")

# 5. Créer le dossier
info "Création de $HOST_DIR..."
mkdir -p "$HOST_DIR"

# 6. Générer le fichier de config selon l'OS
case "$OS_TYPE" in
    "darwin"*)
        cat > "$HOST_DIR/default.nix" << EOF
# hosts/$CONTEXT/$HOST_NAME/default.nix
# Configuration $HOST_NAME - Créé par le Wizard

{ pkgs, inputs, ... }:

{
  imports = [
    ../../../modules/common
    ../../../modules/darwin
  ];

  networking.hostName = "$HOST_NAME";

  # Apps spécifiques à cette machine
  homebrew.casks = [
    # Ajouter vos apps ici
  ];

  # Utilisateur principal
  users.users.$MAIN_USER = {
    name = "$MAIN_USER";
    home = "/Users/$MAIN_USER";
  };

  # Home Manager
  home-manager.users.$MAIN_USER = {
    imports = [ ../../../users/$MAIN_USER/default.nix ];

    home.sessionVariables = {
      MACHINE_CONTEXT = "$CONTEXT";
      MACHINE_NAME = "$HOST_NAME";
    };
  };
}
EOF
        SYSTEM="aarch64-darwin"
        CONFIG_TYPE="darwinConfigurations"
        ;;
        
    "nixos"*)
        cat > "$HOST_DIR/default.nix" << EOF
# hosts/$CONTEXT/$HOST_NAME/default.nix
# Configuration $HOST_NAME - Créé par le Wizard

{ pkgs, inputs, lib, ... }:

{
  imports = [
    ../../../modules/common
    ../../../modules/linux
  ];

  networking.hostName = "$HOST_NAME";

  # Utilisateur principal
  users.users.$MAIN_USER = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  # Home Manager
  home-manager.users.$MAIN_USER = {
    imports = [ ../../../users/$MAIN_USER/default.nix ];
    
    home.sessionVariables = {
      MACHINE_CONTEXT = "$CONTEXT";
      MACHINE_NAME = "$HOST_NAME";
    };
  };

  system.stateVersion = "24.05";
}
EOF
        SYSTEM="x86_64-linux"
        CONFIG_TYPE="nixosConfigurations"
        ;;
        
    "wsl"*)
        cat > "$HOST_DIR/wsl.nix" << EOF
# hosts/$CONTEXT/$HOST_NAME/wsl.nix
# Configuration WSL $HOST_NAME - Créé par le Wizard

{ pkgs, inputs, ... }:

{
  imports = [
    ../../../modules/wsl
  ];

  home.username = "$MAIN_USER";
  home.homeDirectory = "/home/$MAIN_USER";

  programs.zsh.enable = true;
  programs.starship.enable = true;

  home.sessionVariables = {
    MACHINE_CONTEXT = "$CONTEXT";
    MACHINE_NAME = "$HOST_NAME";
  };

  home.stateVersion = "24.05";
}
EOF
        # Aussi créer windows.toml
        cat > "$HOST_DIR/windows.toml" << EOF
# hosts/$CONTEXT/$HOST_NAME/windows.toml
# Configuration Windows Native

[env]
EDITOR = "code --wait"

[tools]
python = "latest"
node = "lts"

[tasks.update]
run = "winget upgrade --all"
EOF
        SYSTEM="x86_64-linux"
        CONFIG_TYPE="homeConfigurations"
        ;;
esac

success "Host $CONTEXT/$HOST_NAME créé !"

# 7. Rappeler d'ajouter au flake.nix
warning "N'oubliez pas d'ajouter l'entrée dans flake.nix:"
echo ""
if [[ "$CONFIG_TYPE" == "homeConfigurations" ]]; then
    echo "  $CONFIG_TYPE = {"
    echo "    \"$MAIN_USER@$HOST_NAME\" = lib.mkHome {"
    echo "      system = \"$SYSTEM\";"
    echo "      modules = [ ./hosts/$CONTEXT/$HOST_NAME/wsl.nix ];"
    echo "    };"
    echo "  };"
else
    echo "  $CONFIG_TYPE = {"
    echo "    \"$HOST_NAME\" = lib.mkSystem {"
    echo "      system = \"$SYSTEM\";"
    echo "      modules = [ ./hosts/$CONTEXT/$HOST_NAME/default.nix ];"
    echo "    };"
    echo "  };"
fi
echo ""

if gum confirm "Ouvrir flake.nix pour ajouter l'entrée ?"; then
    ${EDITOR:-nvim} "$DOTFILES_DIR/flake.nix"
fi
