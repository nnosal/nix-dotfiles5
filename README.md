# 🚀 Ultimate Dotfiles - Nix + Mise + Stow

[![CI](https://github.com/nnosal/nix-dotfiles5/actions/workflows/ci.yml/badge.svg)](https://github.com/nnosal/nix-dotfiles5/actions/workflows/ci.yml)

Infrastructure personnelle **"Ultimate"** unifiée, pilotant le cycle de vie numérique d'un développeur sur **macOS**, **Linux** et **Windows**.

## ✨ Caractéristiques

- 🍎 **macOS** (nix-darwin) - MacBook Pro M3, MacBook Air M2
- 🐧 **Linux** (NixOS) - VPS, Raspberry Pi, Serveurs
- 🪟 **Windows** (WSL + Winget) - PC Gaming hybride
- 🔒 **Zero-Trust** - Aucun secret dans le repo (Fnox)
- ⚡ **Live Editing** - Configs mutables via Stow
- 🎮 **Cockpit TUI** - Interface Gum pour tout piloter

## 🛠️ Stack Technologique

| Composant | Solution | Rôle |
|-----------|----------|------|
| OS Manager | **Nix (Flakes)** | Paquets système, drivers, fonts |
| Task Runner | **Mise** | CLI tools et tâches |
| Dotfiles | **GNU Stow** | Symlinks configs mutables |
| Secrets | **Fnox** | Injection depuis Keychain |
| Git Hooks | **Hk** | Linting Rust/Pkl |
| Interface | **Gum** | TUI interactive |
| SSH Auth | **Secretive** | Secure Enclave (Mac) |

## 🚀 Installation

### macOS / Linux

```bash
sh <(curl -L https://raw.githubusercontent.com/nnosal/nix-dotfiles5/main/bootstrap.sh)
```

> ⚠️ Si `mise install` renvoie une erreur indiquant qu'un outil (ex: `nh`) n'est pas trouvé dans le registre, exécutez `mise install --verbose` pour obtenir plus d'informations.

> Pour `nh` (Nix Helper) : si vous avez Nix installé, installez-le de façon permanente avec :
>
> ```bash
> nix profile install nixpkgs#nh
> ```
>
> Ou utilisez-le temporairement (sans installation permanente) :
>
> ```bash
> nix shell nixpkgs#nh -c nh
> ```
>
> Le `task.install` dans `mise.toml` tentera automatiquement `nix profile install nixpkgs#nh` lors de `mise install` si Nix est présent, et affichera des instructions alternatives en cas d'échec.

> ⚠️ Si `mise` se plaint que le fichier de config n'est pas *trusted* (erreur « Config files in ~/dotfiles/mise.toml are not trusted »), exécutez :
>
> ```bash
> mise trust ~/dotfiles/mise.toml
> ```
>
> Le bootstrap tente désormais d'ajouter l'activation de `mise` dans `~/.zshrc` et d'exécuter `mise trust` automatiquement pour éviter ce blocage. Si `mise` n'est toujours pas trouvable dans votre session, ouvrez un nouveau terminal ou exécutez `source ~/.zshrc`. 


### Windows

```powershell
irm https://raw.githubusercontent.com/nnosal/nix-dotfiles5/main/bootstrap.ps1 | iex
```

## 📁 Structure

```
~/dotfiles/
├── flake.nix              # Cerveau Nix
├── mise.toml              # Task Runner
├── fnox.toml              # Secrets Map
├── hk.pkl                 # Git Hooks
│
├── lib/                   # Factory Nix
│   ├── mkSystem.nix       # Builder Host
│   └── mkHome.nix         # Builder User
│
├── modules/               # Briques LEGO
│   ├── common/            # Shell, Style, Packages
│   ├── darwin/            # macOS (Dock, TouchID)
│   ├── linux/             # NixOS (Systemd)
│   └── wsl/               # Windows Interop
│
├── stow/                  # Configs Mutables
│   ├── common/            # .zshrc, .config/
│   ├── work/              # SSH Pro
│   └── personal/          # SSH Perso
│
├── hosts/                 # Machines
│   ├── pro/macbook-pro/
│   ├── perso/mba-clientele/
│   ├── perso/gaming-rig/
│   └── infra/contabo1/
│
├── users/                 # Profils Humains
│   ├── nnosal/
│   ├── guest/
│   └── root/
│
└── scripts/               # Automation
    ├── cockpit.sh
    └── wizards/
```

## 🎮 Utilisation

### Cockpit (Menu Principal)

```bash
cockpit
# ou
mise run ui
```

### Commandes Rapides

```bash
# Appliquer la config Nix
mise run switch

# Relier les dotfiles (Stow)
mise run stow

# Sauvegarder (Git push)
mise run save

# Mettre à jour
mise run update

# Nettoyer le store Nix
mise run gc
```

### Wizards

```bash
# Ajouter une app
./scripts/wizards/add-app.sh

# Ajouter une machine
./scripts/wizards/add-host.sh

# Gérer les secrets
./scripts/wizards/secret.sh

# Éditer une config (fuzzy)
./scripts/wizards/edit.sh
```

## 🔒 Gestion des Secrets (Zero-Trust)

Aucun secret n'est stocké dans ce repo. Fnox injecte les variables depuis le Keychain système.

```toml
# fnox.toml - Contient uniquement des RÉFÉRENCES
OPENAI_API_KEY = "keychain://openai_api_key"
GITHUB_TOKEN = "keychain://github_token"
```

### Ajouter un secret

```bash
# Via le Wizard
./scripts/wizards/secret.sh

# Ou manuellement (Mac)
fnox set OPENAI_API_KEY "sk-xxx"

# Ou (Linux)
secret-tool store --label="Fnox OPENAI" service fnox key openai_api_key
```

## 🖥️ Machines Configurées

| Hostname | Type | Contexte | Description |
|----------|------|----------|-------------|
| `macbook-pro` | Darwin | Pro | MacBook Pro M3 |
| `mba-clientele` | Darwin | Perso | MacBook Air M2 |
| `gaming-rig` | WSL | Perso | PC Gaming Windows |
| `contabo1` | NixOS | Infra | VPS Linux |
| `rpi5-maison` | NixOS | Infra | Raspberry Pi 5 |
| `agent-test` | NixOS | Test | Tests CI/CD |

## 👤 Profils Utilisateurs

| User | Type | Description |
|------|------|-------------|
| `nnosal` | Admin | Profil principal complet |
| `guest` | Limité | Accès basique, pas de secrets |
| `root` | Server | Administration serveurs |
| `dt` | Gamer | Profil WSL gaming |

## 🔧 Personnalisation

### Ajouter une App GUI (Mac)

```bash
# Via Wizard
./scripts/wizards/add-app.sh
# Choisir "GUI App (Mac Cask)"
# Entrer le nom (ex: obsidian)

# Ou manuellement dans modules/darwin/apps.nix
homebrew.casks = [
  "obsidian"  # Ajouter avant le marqueur
  # %% CASKS %%
];
```

### Ajouter un Package CLI

Dans `modules/common/packages.nix` :

```nix
environment.systemPackages = with pkgs; [
  jq  # Ajouter avant le marqueur
  # %% PACKAGES %%
];
```

### Modifier les Alias Zsh

Éditer directement `stow/common/.config/zsh/aliases.zsh` - les changements sont instantanés !

```bash
source ~/.zshrc  # Recharger
```

## 🧪 Tests

```bash
# Vérifier le Flake
nix flake check

# Test d'intégration Mac (VM Tart)
mise run test-mac
```

## 📚 Documentation

- [AGENTS.md](./AGENTS.md) - Instructions pour l'IA
- [MDD.md](./MDD.md) - Master Design Document complet

## 🤝 Contribution

Ce repo est personnel mais les PRs sont bienvenues pour :
- Corrections de bugs
- Améliorations de la documentation
- Nouveaux modules utiles

## 📜 Licence

MIT - Utilisez librement comme base pour vos propres dotfiles !

---

**Créé avec ❤️ par Nicolas Nosal**

```
     ___           ___           ___     
    /\__\         /\  \         /\__\    
   /::|  |       /::\  \       /:/ _/_   
  /:|:|  |      /:/\:\  \     /:/ /\__\  
 /:/|:|  |__   /::\~\:\  \   /:/ /:/ _/_ 
/:/ |:| /\__\ /:/\:\ \:\__\ /:/_/:/ /\__\
\/__|:|/:/  / \/__\:\/:/  / \:\/:/ /:/  /
    |:/:/  /       \::/  /   \::/_/:/  / 
    |::/  /        /:/  /     \:\/:/  /  
    /:/  /        /:/  /       \::/  /   
    \/__/         \/__/         \/__/    
```
