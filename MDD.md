# DOSSIER DE CONCEPTION : DOTFILES "ZERO-TO-HERO" (NIX + MISE + TUI)

C'est parti. Voici la **Version Définitive et Exhaustive** de la **Partie 1** du Master Design Document.

Elle intègre la totalité de nos arbitrages : le bootstrapping éphémère (sans clone manuel), la stratégie Stow granulaire (Profils), la dualité Windows (Natif/WSL), le choix de `hk` pour la qualité, et la sécurité hardware via Secretive/Fnox.

---

# 📘 MASTER DESIGN DOCUMENT - PARTIE 1/6

## Philosophie, Architecture & Expérience Utilisateur

### 1. Vision et Objectifs Stratégiques

L'objectif est de déployer une infrastructure personnelle **"Ultimate"** unifiée, capable de piloter le cycle de vie numérique d'un développeur sur **macOS**, **Linux** et **Windows**.

**Les 5 Piliers Fondateurs :**

1. **Universalité Sans Compromis :** Un seul dépôt Git pilote un MacBook Pro M3, un serveur VPS Linux headless et une tour Gaming Windows.

2. **Cloisonnement Contextuel (Multi-Tenancy) :**
   
   - Séparation stricte des contextes : **Pro** (Secrets clients, AWS) vs **Perso** (Jeux, Projets labo).
   
   - Séparation des identités : **Admin** (Toi) vs **Guest** (Limité) vs **Root** (Infra).

3. **Expérience "Live Editing" :** La configuration des logiciels (Nvim, Zsh) doit être mutable et éditable instantanément (via **Stow**) sans nécessiter de recompilation système lourde (Nix).

4. **Sécurité "Zero-Trust Repository" :** Le dépôt Git est considéré comme public. Aucun secret (même chiffré) n'y réside. Les secrets sont injectés dynamiquement (Fnox) depuis le matériel (Secure Enclave).

5. **Bootstrapping Éphémère :** L'installation démarre par une URL unique (`curl`). Aucune dépendance préalable (ni Git, ni Gum) n'est requise sur la machine cible.

---

### 2. La "Stack" Technologique Validée

Tout écart par rapport à cette stack doit être justifié. Nous avons éliminé les dettes techniques classiques (Makefiles, Python venv, Scripts Bash épars).

| **Composant**      | **Solution Retenue** | **Rôle & Justification (vs Alternatives Rejetées)**                                                                            |
| ------------------ | -------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| **OS Manager**     | **Nix (Flakes)**     | Gère les paquets système, drivers, fonts. **Rejeté :** Ansible (impératif), Homebrew Bundle (limité).                          |
| **Task Runner**    | **Mise (jdx)**       | Installe les CLI (Node, Go, Gum) et exécute les tâches. **Rejeté :** Make (archaïque), Just (pas d'install tools).             |
| **Dotfiles**       | **GNU Stow**         | Lie symboliquement les configs (`.zshrc`) pour édition directe. **Rejeté :** Home-Manager pur (read-only, trop lent à itérer). |
| **Secrets**        | **Fnox (jdx)**       | Injecte les ENV vars depuis Keychain/Pass. **Rejeté :** SOPS/Agenix (secrets stockés dans Git, risque de fuite).               |
| **Git Hooks**      | **Hk (jdx)**         | Linter rapide en Rust/Pkl. **Rejeté :** Pre-commit (lourd, dépendance Python).                                                 |
| **Interface (UI)** | **Gum**              | Scripts interactifs (Wizards) pour piloter l'infra sans connaître les commandes.                                               |
| **SSH Auth**       | **Secretive** (Mac)  | Clés stockées dans Secure Enclave (TouchID). **Rejeté :** Clés fichiers (`id_ed25519`).                                        |
| **Shell**          | **Zsh + Starship**   | Standard, performant, prompt unifié cross-platform.                                                                            |

---

### 3. Concepts Architecturaux Détaillés

#### A. Le "Ephemeral Bootstrapping" (Zero-Install)

L'utilisateur ne clone pas le repo manuellement.

1. **Entrée :** Une commande `curl` (Unix) ou `irm` (Windows).

2. **Phase Volatile :** Le script installe le moteur (Nix ou Mise) et lance un shell temporaire (`nix shell` / `mise x`) contenant **Git** et **Gum**.

3. **Exécution :** C'est ce shell temporaire qui affiche l'UI, demande où cloner, et lance l'installation définitive.

#### B. Matrice "Host" vs "User"

Nous découplons le matériel de l'humain pour la portabilité.

- **Hosts (`hosts/`) :** Définition de la machine physique.
  
  - *Responsabilité :* Drivers, WiFi, GPU, Dock macOS, Casks système (VLC, Chrome).
  
  - *Exemple :* `hosts/pro/macbook-pro`.

- **Users (`users/`) :** Définition de l'environnement de travail.
  
  - *Responsabilité :* Shell, Alias, Git Config, Outils CLI (K9s, Bat).
  
  - *Exemple :* `users/nnosal` (Dev), `users/guest` (Limité).

- **Assemblage :** Un Host "invite" un ou plusieurs Users. Le MacBook Air contient `nnosal` + `guest`.

#### C. Gestion Granulaire via "Stow Profiles"

Pour éviter de polluer une machine perso avec des configs pro, Stow est piloté par profils.

- **Structure :**
  
  - `stow/common` : Base (Zsh, Starship). Installé partout.
  
  - `stow/work` : Configs Pro (`.ssh/config.d/work.conf`, `.aws/`). Installé uniquement sur machines Pro.
  
  - `stow/personal` : Configs Perso (`.steam/`, serveurs homelab).

- **Mécanisme :** Le script d'installation détecte le contexte ou demande via Gum quel profil appliquer.

#### D. Stratégie Windows "Hybride" (Le Centaure)

Windows est traité spécifiquement pour contourner ses limitations POSIX.

- **Tête (Native) :** **Mise** (installé via Winget) gère l'environnement PowerShell, les outils Windows (VSCode, Steam) et les runtimes Dev (Node, Python).

- **Corps (WSL) :** **Nix** tourne dans WSL2 pour fournir un terminal Zsh identique à macOS.

- **Lien :** Le module `modules/wsl` assure l'interopérabilité (presse-papier partagé, ouverture de navigateur Windows depuis Linux).

---

### 4. Expérience Utilisateur (DX) & Flux de Données

Ces diagrammes illustrent le comportement attendu du système.

#### Diagramme 1 : Le Parcours Utilisateur (De 0 à 100%)

Extrait de code

```
journey
    title DX : Du Zero-Install au Cockpit Quotidien
    section 🚀 Bootstrap (J-0)
      Curl One-Liner: 5: User
      Shell Éphémère (Nix/Gum): 5: System
      Clone Auto & Setup: 5: System
      Login Shell (Prêt): 5: User
    section ⚡️ Quotidien
      Ouvrir Cockpit (mise run ui): 5: User
      Ajouter App (Wizards): 5: Cockpit
      Switch Nix (Auto): 4: System
    section 🔧 Config & Secrets
      Edit .zshrc (Stow Live): 5: User
      Fnox Set Secret: 5: User
      Auth TouchID: 5: User
      Git Save & Push: 5: Cockpit
```

#### Diagramme 2 : Architecture Fonctionnelle (Data Flow)

Extrait de code

```
flowchart TD
    subgraph "🗄️ SOURCE (Repo)"
        Flake[❄️ flake.nix]
        MiseConf[🔧 mise.toml]
        StowDir[📂 stow/ (common/work)]
        FnoxConf[🛡️ fnox.toml]
        HkConf[🪝 hk.pkl]
    end

    subgraph "⚙️ MOTEURS"
        NixEngine[Moteur Nix <br/> (Darwin/NixOS)]
        MiseEngine[Moteur Mise <br/> (Task Runner)]
        StowEngine[Moteur Stow <br/> (Symlinks)]
        FnoxEngine[Moteur Fnox <br/> (Env Injection)]
    end

    subgraph "🖥️ ÉTAT MACHINE"
        Sys[📦 System Apps]
        Dev[🛠️ Dev Tools]
        Home[🏠 User Configs]
        Env[🔑 Env Vars (RAM)]
    end

    Flake -->|Build| NixEngine -->|Installs| Sys
    MiseConf -->|Runs| MiseEngine -->|Installs| Dev
    MiseEngine -->|Triggers| StowEngine
    StowDir -->|Links| StowEngine -->|Deploys| Home

    FnoxConf -->|Reads| FnoxEngine -->|Injects| Env
    Hardware((🔒 Secure Enclave)) -.->|Unlock| FnoxEngine

    HkConf -->|Configures| MiseEngine
```

---

### 5. Directives Strictes pour l'Agent IA

Dans les étapes suivantes de génération de code, tu dois respecter ces règles impératives :

1. **Interdiction de cloner manuellement :** Les scripts d'entrée (`bootstrap.sh/.ps1`) doivent gérer la logique d'installation des pré-requis (Nix/Mise) et cloner eux-mêmes.

2. **Respect de la granularité Stow :** Ne jamais faire un `stow .` global. Toujours cibler `common` + le profil choisi (`work`/`personal`).

3. **Pas de secrets dans Git :** Ne génère jamais de fichiers `.sops.yaml` ou `.age`. Utilise uniquement `fnox.toml` avec des pointeurs `keychain://`.

4. **Priorité Hk :** Pour la qualité du code, configure `hk.pkl` et non `.pre-commit-config.yaml`.

5. **Windows Natif :** Sur Windows, utilise `winget` via Mise pour les apps graphiques. N'essaie pas d'installer Steam via Nix dans WSL.

---

Cette **Partie 1** est désormais la source de vérité absolue pour la structure et la logique du projet. Passons à la **Partie 2** pour cartographier chaque fichier.

C'est noté. Voici la **Partie 2** du Master Design Document.

Cette section est le **Plan Cadastral** du projet. Elle est exhaustive : chaque fichier, chaque dossier a une raison d'être précise. Rien n'est laissé au hasard.

L'agent IA qui lira ceci devra suivre cette structure à la lettre pour garantir que les scripts d'automatisation (Cockpit) et le moteur Nix trouvent les ressources au bon endroit.

---

# 📘 MASTER DESIGN DOCUMENT - PARTIE 2/6

## La Cartographie du Système (Filesystem)

### 1. Vue Satellitaire (Arborescence Complète)

Ceci est la structure de fichiers **cible** que le script de bootstrap doit générer ou valider.

Plaintext

```
~/dotfiles/
├── 📄 README.md                 # Documentation (Install, Cheatsheet)
├── 📄 .gitignore                # Ignore: result, .DS_Store, *.local.toml
│
├── 🚀 bootstrap.sh              # Entrypoint (Mac/Linux) -> Installe Nix/Mise
├── 🚀 bootstrap.ps1             # Entrypoint (Windows)   -> Installe Mise/Winget
│
├── ⚙️ CORE CONFIGURATION
│   ├── ❄️ flake.nix             # Le Cerveau Nix (Inputs/Outputs)
│   ├── 🔒 flake.lock            # Versions figées
│   ├── 🔧 mise.toml             # Task Runner (Install tools, Run scripts)
│   ├── 🛡️ fnox.toml             # Secrets Map (Pointeurs uniquement)
│   └── 🪝 hk.pkl                # Git Hooks (Linting/Quality)
│
├── 📚 NIX LIBRARY
│   └── 📂 lib/
│       ├── mkSystem.nix         # Factory pour créer un Host
│       └── mkHome.nix           # Factory pour créer une Config Home
│
├── 📦 NIX MODULES (Briques LEGO)
│   ├── 📂 common/               # (Zsh, Fonts, Starship, Mise, Fnox, Stylix)
│   ├── 📂 darwin/               # (Dock, Homebrew, Secretive, Finder)
│   ├── 📂 linux/                # (Systemd, Docker, Hardening)
│   └── 📂 wsl/                  # (WslView, Interop, Clipboard)
│
├── 📂 STOW (Configs Mutables)
│   ├── 🌍 common/               # (.zshrc, .config/nvim, .config/ghostty)
│   ├── 💼 work/                 # (.ssh/config.d/work.conf, .aws/)
│   └── 🏠 personal/             # (.ssh/config.d/perso.conf, .steam/)
│
├── 🖥️ HOSTS (Matériel & OS)
│   ├── 📂 pro/
│   │   └── 📂 macbook-pro/      # default.nix (Imports: darwin, users/nnosal)
│   ├── 📂 perso/
│   │   ├── 📂 mba-clientele/    # default.nix (Imports: darwin, users/nnosal+guest)
│   │   └── 📂 gaming-rig/       # wsl.nix (NixOS) + windows.toml (Winget)
│   └── 📂 infra/
│       └── 📂 contabo1/         # default.nix (Imports: linux, users/root)
│
├── 👤 USERS (Profils Humains)
│   ├── 📂 nnosal/               # default.nix, dev.nix, server.nix
│   ├── 📂 guest/                # default.nix (Restreint)
│   ├── 📂 root/                 # default.nix (Admin)
│   └── 📂 dt/                   # default.nix (Gamer)
│
├── 📜 AUTOMATION (Scripts & TUI)
│   ├── cockpit.sh               # Menu Principal (Gum)
│   ├── utils.sh                 # Helpers Bash
│   └── 📂 wizards/              # Assistants (Add Host, Add App, Secrets)
│
└── 📝 TEMPLATES (Modèles pour les Wizards)
    ├── host-darwin.nix
    ├── host-nixos.nix
    └── user-profile.nix
```

---

### 2. Dictionnaire des Fichiers (Rôles & Contenus Clés)

Pour chaque section, voici ce que l'IA doit savoir implémenter.

#### A. Racine & Bootstrapping

| **Fichier**     | **Rôle Technique**  | **Contenu Clé Indispensable**                                                         |
| --------------- | ------------------- | ------------------------------------------------------------------------------------- |
| `flake.nix`     | Point d'entrée Nix  | Imports de `nix-darwin`, `home-manager`. Définition des `outputs` via `lib.mkSystem`. |
| `mise.toml`     | Chef d'orchestre    | Tools: `gum`, `hk`, `fzf`. Tasks: `install`, `ui` (Cockpit), `stow`, `save`.          |
| `fnox.toml`     | Carte des Secrets   | `OPENAI_API_KEY = "keychain://openai"`. Pas de valeurs réelles !                      |
| `hk.pkl`        | Qualité du Code     | Config Pkl pour `hk`. Vérifie: `nixfmt`, `shellcheck`, `detect-private-key`.          |
| `bootstrap.sh`  | Zero-Install (Unix) | `nix shell nixpkgs#gum` -> Clone Repo -> `mise install`.                              |
| `bootstrap.ps1` | Zero-Install (Win)  | `winget install jdx.mise` -> `mise x gum` -> Clone Repo.                              |

#### B. La Librairie (`lib/`)

C'est ici qu'on évite la répétition de code dans le `flake.nix`.

| **Fichier**    | **Rôle**     | **Logique Interne**                                                                                                  |
| -------------- | ------------ | -------------------------------------------------------------------------------------------------------------------- |
| `mkSystem.nix` | Wrapper Host | Accepte `system` (arch), `modules` (liste), `user` (principal). Configure automatiquement `nixpkgs` et les overlays. |
| `mkHome.nix`   | Wrapper User | Simplifie la création d'une config Home-Manager autonome (utile pour WSL).                                           |

#### C. Les Modules (`modules/`)

Ce sont les traits de fonctionnalités activables.

| **Dossier** | **Module**     | **Fonctionnalités Activées**                                                         |
| ----------- | -------------- | ------------------------------------------------------------------------------------ |
| `common/`   | `shell.nix`    | Active Zsh, Starship. **Critique :** Injecte le script de chargement Fnox/Secretive. |
| `common/`   | `style.nix`    | (Stylix) Définit le wallpaper et le colorscheme global (Catppuccin/Dracula).         |
| `darwin/`   | `security.nix` | Configure TouchID pour sudo (`pam_tid`). Installe Secretive.                         |
| `darwin/`   | `apps.nix`     | Liste des Casks (`homebrew.casks`).                                                  |
| `wsl/`      | `interop.nix`  | Installe `wslu`. Crée l'alias `open` -> `wslview`.                                   |

#### D. Le Système Stow (`stow/`)

Les fichiers ici sont des "Link Targets". Ils doivent reproduire exactement la structure attendue dans `$HOME`.

| **Profil**   | **Chemin Source**                   | **Chemin Cible**            | **Note Spéciale**                                                |
| ------------ | ----------------------------------- | --------------------------- | ---------------------------------------------------------------- |
| **common**   | `stow/common/.zshrc`                | `~/.zshrc`                  | Source `source $HOME/.config/zsh/*.zsh` pour charger les extras. |
| **common**   | `stow/common/.ssh/config`           | `~/.ssh/config`             | Contient `Include config.d/*`.                                   |
| **work**     | `stow/work/.ssh/config.d/work.conf` | `~/.ssh/config.d/work.conf` | Contient les IPs des serveurs Pro.                               |
| **personal** | `stow/personal/.steam/`             | `~/.steam/`                 | Configs Steam/Jeux.                                              |

#### E. Les Machines (`hosts/`) et Utilisateurs (`users/`)

**Structure d'un fichier Host (`hosts/pro/macbook-pro/default.nix`) :**

Nix

```
{ pkgs, ... }: {
  imports = [
    ../../modules/darwin      # Capacités Mac
    ../../modules/common      # Capacités Base
  ];

  # Spécifique Machine
  networking.hostName = "macbook-pro";
  homebrew.casks = [ "vlc" "docker" ]; # Apps liées au GPU/Hardware

  # Import des Humains
  home-manager.users.nnosal = import ../../../users/nnosal/default.nix;
}
```

**Structure d'un fichier User (`users/nnosal/default.nix`) :**

Nix

```
{ pkgs, ... }: {
  # Outils portables (CLI)
  home.packages = with pkgs; [ k9s bat fzf ripgrep ];

  # Config Git (Identité)
  programs.git = {
    enable = true;
    userName = "Nicolas Nosal";
    userEmail = "n.nosal@exemple.com";
  };
}
```

#### F. Le Dossier Windows Spécial (`hosts/perso/gaming-rig/`)

C'est le seul dossier "Hybride".

| **Fichier**    | **Rôle**           | **Contenu**                                                       |
| -------------- | ------------------ | ----------------------------------------------------------------- |
| `wsl.nix`      | Config NixOS (WSL) | Importe `users/nnosal`. Configure Zsh.                            |
| `windows.toml` | Config Mise Native | `[tools]` winget:Steam, winget:Discord. `[tasks]` update-windows. |

---

### 3. Les Relations Critiques (Cross-Reference)

L'agent IA doit vérifier ces liens lors de la génération du code :

1. Le Lien Flake -> Host :
   
   Dans flake.nix, la clé darwinConfigurations."macbook-pro" doit pointer vers ./hosts/pro/macbook-pro.

2. Le Lien Host -> User :
   
   Chaque fichier Host doit définir home-manager.users.<username>.

3. Le Lien Cockpit -> Templates :
   
   Le script scripts/wizards/add-host.sh doit lire templates/host-darwin.nix pour générer un nouveau dossier.

4. Le Lien Fnox -> Shell :
   
   Le fichier modules/common/shell.nix doit contenir eval "$(fnox activate zsh)" pour que les secrets définis dans fnox.toml soient chargés.

---

Cette Partie 2 fournit la carte complète.

Si l'architecture est le squelette (Partie 1), cette cartographie est le système nerveux.

Passons à la Partie 3 : Le Cœur Technique Nix pour coder les rouages internes (lib, flake).

C'est parti pour la **Partie 3**. C'est le "Moteur V12" de ton infrastructure.

Ici, nous passons de la théorie au code pur. Cette section est dense car elle contient la logique qui permet à une seule commande (`nix switch`) de configurer un Mac, un Serveur Linux ou un sous-système Windows sans conflit.

L'agent IA doit générer ces fichiers **exactement** comme décrit pour que la mécanique fonctionne.

---

# 📘 MASTER DESIGN DOCUMENT - PARTIE 3/6

## Le Cœur Technique (Nix Flake & Library)

### 1. Le Fichier Maître (`flake.nix`)

C'est le point d'entrée unique. Il verrouille les versions de toutes les dépendances et expose les configurations machines.

**Chemin :** `~/dotfiles/flake.nix`

Nix

```
{
  description = "Ultimate Dotfiles - Unified Infrastructure";

  inputs = {
    # 1. Nix Packages (La base de tout)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # 2. Gestionnaire macOS
    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    # 3. Gestionnaire Utilisateur (Dotfiles manager)
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # 4. Esthétique (Harmonisation des couleurs)
    stylix.url = "github:danth/stylix";

    # 5. Hardware Tweaks (Pour Raspberry Pi / Apple Silicon)
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, darwin, home-manager, ... }@inputs:
    let
      # On charge notre librairie perso pour éviter de répéter le code
      lib = import ./lib { inherit inputs; };
    in
    {
      # --- 🍎 MAC OS CONFIGURATIONS ---
      darwinConfigurations = {

        # PRO (MacBook Pro M3)
        "macbook-pro" = lib.mkSystem {
          system = "aarch64-darwin";
          modules = [ ./hosts/pro/macbook-pro/default.nix ];
        };

        # PERSO (MacBook Air M2)
        "mba-clientele" = lib.mkSystem {
          system = "aarch64-darwin";
          modules = [ ./hosts/perso/mba-clientele/default.nix ];
        };
      };

      # --- 🐧 LINUX SERVER CONFIGURATIONS ---
      nixosConfigurations = {

        # INFRA (VPS Contabo)
        "contabo1" = lib.mkSystem {
          system = "x86_64-linux";
          modules = [ ./hosts/infra/contabo1/default.nix ];
        };

        # LABO (Raspberry Pi 5)
        "rpi5-maison" = lib.mkSystem {
          system = "aarch64-linux";
          modules = [ 
            inputs.nixos-hardware.nixosModules.raspberry-pi-4 # (Adapté Pi5 si dispo)
            ./hosts/infra/rpi5-maison/default.nix 
          ];
        };
      };

      # --- 🪟 WINDOWS / STANDALONE HOME ---
      homeConfigurations = {

        # GAMING (WSL2 Debian/Ubuntu)
        "dt@gaming-rig" = lib.mkHome {
          system = "x86_64-linux";
          modules = [ ./hosts/perso/gaming-rig/wsl.nix ];
        };
      };
    };
}
```

---

### 2. La Factory (`lib/mkSystem.nix`)

Cette fonction est **critique**. Elle détecte si on construit pour Mac (`darwin`) ou Linux (`nixos`) et appelle la bonne fonction système. Elle injecte automatiquement `home-manager` et `stylix`.

**Chemin :** `~/dotfiles/lib/mkSystem.nix`

Nix

```
{ inputs }:

{ system, modules, ... }:

let
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true; # Autoriser Spotify, VSCode, etc.
  };

  # Détection automatique de l'OS
  isDarwin = builtins.match ".*darwin" system != null;

  # Sélection du builder (nix-darwin vs nixos)
  systemBuilder = if isDarwin then inputs.darwin.lib.darwinSystem else inputs.nixpkgs.lib.nixosSystem;

  # Modules de base toujours présents
  commonModules = [
    inputs.home-manager.${if isDarwin then "darwinModules" else "nixosModules"}.home-manager
    inputs.stylix.${if isDarwin then "darwinModules" else "nixosModules"}.stylix
    {
      # Configuration globale de Home Manager
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = { inherit inputs; }; # Passe les inputs aux users
    }
  ];

in
systemBuilder {
  inherit system;
  # On passe les inputs à tous les modules système
  specialArgs = { inherit inputs; };
  modules = commonModules ++ modules;
}
```

### 3. La Factory Home (`lib/mkHome.nix`)

Pour WSL ou les systèmes non-NixOS où l'on veut juste configurer l'utilisateur.

**Chemin :** `~/dotfiles/lib/mkHome.nix`

Nix

```
{ inputs }:

{ system, modules, ... }:

let
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
in
inputs.home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  extraSpecialArgs = { inherit inputs; };
  modules = [
    inputs.stylix.homeManagerModules.stylix 
  ] ++ modules;
}
```

---

### 4. Les Modules "Lego" (`modules/`)

C'est ici qu'on définit les fonctionnalités réutilisables.

#### A. Module Commun : Shell & Bootstrapping Fnox

**Chemin :** `~/dotfiles/modules/common/shell.nix` *Role :* Configure Zsh et assure que Fnox/Secretive sont chargés.

Nix

```
{ pkgs, ... }: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;

    # 🛡️ Injection des Secrets (Fnox) & SSH
    initExtra = ''      # 1. Activer Fnox (Secrets en ENV)      if command -v fnox &> /dev/null; then        eval "$(fnox activate zsh)"      fi      # 2. Lier le Socket SSH (Secretive ou Agent)      if [[ -S /Users/$USER/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh ]]; then        export SSH_AUTH_SOCK=/Users/$USER/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh      elif [[ -S $XDG_RUNTIME_DIR/ssh-agent.socket ]]; then        export SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent.socket      fi      # 3. Charger les Alias Stow      # Si stow/common est lié, ceci chargera les fichiers      [ -f ~/.config/zsh/aliases.zsh ] && source ~/.config/zsh/aliases.zsh    '';
  };

  programs.starship.enable = true;
}
```

#### B. Module Darwin : Sécurité Hardware

**Chemin :** `~/dotfiles/modules/darwin/security.nix` *Role :* Active TouchID pour sudo.

Nix

```
{ pkgs, ... }: {
  # Permet d'utiliser TouchID pour la commande `sudo` dans le terminal
  security.pam.enableSudoTouchIdAuth = true;

  # Installe l'app Secretive via Homebrew (si non présente)
  homebrew.casks = [ "secretive" ];
}
```

---

### 5. Implémentation Concrète : Host & User

C'est ici que l'assemblage se fait. L'IA doit comprendre que le fichier `default.nix` d'un Host est le "chef d'orchestre" de la machine.

#### A. Le Host (`hosts/pro/macbook-pro/default.nix`)

Nix

```
{ pkgs, ... }: {
  imports = [
    ../../../modules/common      # Base (Zsh, Fonts)
    ../../../modules/darwin      # Base Mac (Dock, Finder)
  ];

  # 1. Configuration Matérielle / Système
  networking.hostName = "macbook-pro";
  system.stateVersion = 5;

  # Apps Système (installées dans /Applications)
  homebrew.casks = [
    "visual-studio-code"
    "docker"
    "slack"
    "raycast"
  ];

  # 2. Définition des Utilisateurs
  users.users.nnosal.home = "/Users/nnosal";

  # 3. Import du Profil Humain (Home Manager)
  home-manager.users.nnosal = {
    imports = [ ../../../users/nnosal/default.nix ];

    # Surcharge spécifique à cette machine (Optionnel)
    home.sessionVariables = {
      MACHINE_CONTEXT = "work";
    };
  };
}
```

#### B. L'User (`users/nnosal/default.nix`)

Nix

```
{ pkgs, ... }: {
  imports = [ 
    ../../modules/common/shell.nix  # On veut Zsh
    ../../modules/common/style.nix  # On veut le thème Stylix
  ];

  # Identité Git
  programs.git = {
    enable = true;
    userName = "Nicolas Nosal";
    userEmail = "n.nosal@exemple.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  # Paquets CLI portables (Marche sur Mac et Linux !)
  home.packages = with pkgs; [
    bat       # Cat sous stéroïdes
    eza       # Ls sous stéroïdes
    fzf       # Fuzzy finder
    ripgrep   # Grep ultra rapide
    k9s       # Kubernetes UI
    lazygit   # Git UI
    nh        # Nix Helper (Clean & Switch)
  ];

  home.stateVersion = "24.05";
}
```

---

### 6. Résumé de la Mécanique (Data Flow)

Pour l'agent IA, voici le chemin d'exécution lors d'un `nix switch` :

1. **Input :** L'utilisateur tape `nh os switch`.

2. **Flake :** Nix lit `flake.nix`, trouve l'entrée correspondant au hostname (`macbook-pro`).

3. **Library :** `lib.mkSystem` est appelé. Il prépare `pkgs` (aarch64) et injecte `home-manager`.

4. **Host Module :** `hosts/pro/macbook-pro/default.nix` est évalué. Il demande l'installation de `docker` (système).

5. **User Module :** Home Manager prend le relais pour `nnosal`. Il lit `users/nnosal/default.nix`.

6. **Output :**
   
   - Nix installe les binaires (`k9s`, `bat`).
   
   - Home Manager génère `~/.zshrc` (avec le hook Fnox).
   
   - Nix-Darwin configure TouchID (`security.nix`).

Cette **Partie 3** est complète et fonctionnelle. Elle respecte scrupuleusement l'architecture définie. Passons à la **Partie 4** pour la gestion Windows Hybride et Stow.

C'est parti pour la **Partie 4**.

Cette section est souvent le point faible des dotfiles classiques. Ici, nous allons détailler comment ton système gère le "Grand Écart" entre Windows et Unix, et comment Stow applique chirurgicalement les configs sans tout écraser.

L'agent IA doit suivre ces directives pour que ton expérience sur le PC Gaming soit aussi fluide que sur le Mac Pro.

---

# 📘 MASTER DESIGN DOCUMENT - PARTIE 4/6

## Stratégie Hybride & Cross-Platform (Windows + Stow)

### 1. Le Modèle "Centaure" (Windows Hybride)

Sur Windows, nous refusons le dogme "Tout WSL" ou "Tout PowerShell". Nous utilisons le bon outil pour la bonne tâche.

**L'Architecture Bicéphale :**

1. **Cerveau Gauche (Natif/GUI) :** Géré par **Mise** + **Winget**. Installe les jeux, les navigateurs, les IDEs.

2. **Cerveau Droit (CLI/Dev) :** Géré par **Nix** (dans WSL). Installe Zsh, Git, K9s.

#### A. La Config Native (`hosts/perso/gaming-rig/windows.toml`)

Ce fichier est lu par Mise sur Windows (via `bootstrap.ps1`). Il remplace Ansible/Chocolatey.

Ini, TOML

```
# hosts/perso/gaming-rig/windows.toml

[env]
# Définition des variables d'environnement Windows globales
EDITOR = "code --wait"

[tools]
# Runtimes pour le dev Windows natif (Unity, Unreal, Scripts)
python = "latest"
node = "lts"
go = "latest"

# 📦 WINGET (Applications Graphiques)
# Mise supporte l'installation Winget nativement
"winget:Microsoft.VisualStudioCode" = "latest"
"winget:Valve.Steam" = "latest"
"winget:Discord.Discord" = "latest"
"winget:Google.Chrome" = "latest"
"winget:Docker.DockerDesktop" = "latest"
"winget:Microsoft.PowerShell" = "latest" # PowerShell 7 Core

[tasks.update]
description = "Met à jour toutes les apps Windows"
run = "winget upgrade --all --include-unknown"
```

#### B. La Config WSL (`hosts/perso/gaming-rig/wsl.nix`)

Ce fichier est une config **Home Manager Standalone**. Il est lancé *dans* Ubuntu WSL.

Nix

```
{ pkgs, ... }: {
  imports = [
    ../../../modules/common      # Zsh, Starship, Atuin
    ../../../modules/wsl         # Module spécifique (voir ci-dessous)
  ];

  home.username = "dt";
  home.homeDirectory = "/home/dt";

  # On installe les outils CLI Linux
  home.packages = with pkgs; [
    gcc       # Pour compiler des trucs si besoin
    gnumake
    wget
    curl
  ];

  # Git doit utiliser le credential helper de Windows pour l'auth HTTPS
  programs.git.extraConfig.credential.helper = "/mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe";

  home.stateVersion = "24.05";
}
```

---

### 2. Le Module d'Intégration WSL (`modules/wsl/default.nix`)

C'est le "pont" qui rend l'expérience transparente.

Nix

```
{ pkgs, ... }: {

  # 1. Utilitaires WSL (wslview, wslact)
  home.packages = [ pkgs.wslu ];

  # 2. Variables d'environnement critiques
  home.sessionVariables = {
    # Ouvre les liens (xdg-open) avec le navigateur par défaut de Windows
    BROWSER = "wslview"; 
    # Utilise l'affichage XServer (si installé sur Windows, optionnel)
    DISPLAY = ":0";
  };

  # 3. Alias pratiques
  programs.zsh.shellAliases = {
    # Ouvre l'explorateur Windows dans le dossier courant
    explorer = "explorer.exe .";
    # Copie dans le presse-papier Windows (via clip.exe)
    clip = "clip.exe";
  };
}
```

---

### 3. La Stratégie Stow (Gestion Granulaire)

Stow est notre outil de déploiement de "Configs Pures" (text files). L'IA doit comprendre que nous n'utilisons pas `stow` en mode bourrin ("tout ou rien").

#### A. Structure des Dossiers (`stow/`)

- **`stow/common/`** : Doit être appliqué sur **TOUTES** les machines.
  
  - `.zshrc` : Squelette qui source les modules.
  
  - `.config/starship.toml` : Prompt.
  
  - `.config/nvim/` : Config Neovim complète.

- **`stow/work/`** : Uniquement pour les machines Pro.
  
  - `.ssh/config.d/work.conf` : IPs sensibles.
  
  - `.aws/config` : Profils SSO d'entreprise.
  
  - `.npmrc` : Auth tokens registry privé.

- **`stow/personal/`** : Uniquement pour les machines Perso.
  
  - `.ssh/config.d/perso.conf` : Accès Github Perso / Homelab.
  
  - `.steam/steam_appid.txt` : Configs jeux (si Linux).

#### B. Le Script d'Application Intelligent

Ce script doit être généré dans `scripts/stow-apply.sh` (et appelé par Mise).

Bash

```
#!/usr/bin/env bash
# scripts/stow-apply.sh

# 1. Nettoyage des liens morts (sécurité)
stow --dir=stow --target=$HOME --delete common 2>/dev/null

# 2. Application du socle commun (Critique)
echo "🌍 Application du profil COMMON..."
stow --dir=stow --target=$HOME --restow common

# 3. Détection du Profil Machine (via variable ENV ou Gum)
# Cette variable peut être définie dans hosts/.../default.nix -> home.sessionVariables
PROFIL=${MACHINE_CONTEXT:-""}

if [ -z "$PROFIL" ]; then
    # Si non défini, on demande (Interactif)
    PROFIL=$(gum choose "work" "personal" "none" --header "Quel profil Stow appliquer ?")
fi

# 4. Application conditionnelle
if [ "$PROFIL" == "work" ]; then
    echo "💼 Application du profil WORK..."
    stow --dir=stow --target=$HOME --restow work
elif [ "$PROFIL" == "personal" ]; then
    echo "🏠 Application du profil PERSONAL..."
    stow --dir=stow --target=$HOME --restow personal
fi

echo "✅ Configuration déployée."
```

---

### 4. Les "Edge Cases" Cross-Platform (Détails Techniques)

L'agent IA doit gérer ces subtilités lors de la génération des fichiers.

#### A. Gestion des Fins de Ligne (CRLF vs LF)

Windows utilise CRLF, Linux LF. Si on ne gère pas ça, les scripts Bash casseront sous WSL.

**Fichier : `.gitattributes` (à la racine)**

Plaintext

```
# Force LF (Unix style) pour tous les fichiers textuels, même sur Windows
* text=auto eol=lf

# Exceptions binaires
*.png binary
*.pkl binary
```

#### B. Gestion des Fonts (Nerd Fonts)

Sur Mac/Linux, Nix installe les fonts. Sur Windows Natif, Nix ne peut pas le faire.

- **Solution :** Dans `bootstrap.ps1`, on ajoute une étape pour télécharger et installer la Nerd Font (ex: JetBrainsMono) dans le dossier Fonts de Windows, ou on utilise `winget install Delugia.NerdFont`.

#### C. Chemins SSH (Include)

Le fichier `~/.ssh/config` géré par Stow doit être résilient si le dossier `config.d/` est vide (cas où aucun profil n'est appliqué).

**Contenu de `stow/common/.ssh/config` :**

Extrait de code

```
# Options globales
Host *
    AddKeysToAgent yes
    Compression yes

# Include tolérant : Si le fichier n'existe pas, SSH ne plante pas.
Include config.d/*.conf
```

---

### 5. Directives d'Implémentation pour l'IA

Lors de la génération du code, respecte ces règles :

1. **Isolation Windows :** Ne mélange jamais de code NixOS (`services.xserver...`) dans la config `wsl.nix`. WSL est un Linux sans noyau graphique (headless) du point de vue de Nix.

2. **Symlinks Stow :** Vérifie que les dossiers cibles existent (`mkdir -p ~/.config/nvim`) avant de lancer `stow`, sinon Stow crée un lien symbolique vers le dossier entier au lieu du contenu (ce qui est sale).

3. **Winget Idempotency :** Dans `windows.toml`, utilise bien la syntaxe `"winget:Package.Id"` pour que Mise délègue correctement.

4. **WSL User :** Assure-toi que le `username` dans `wsl.nix` correspond bien à l'utilisateur Linux créé lors de l'install WSL (souvent le même que Windows, mais pas garanti).

Cette **Partie 4** verrouille la complexité multi-OS.
Ton PC Gaming, ton Mac Pro et ton serveur Linux partagent maintenant le même ADN, mais chacun exprime ses gènes de manière adaptée.

Passons à la **Partie 5** pour bétonner la sécurité (Secretive/Fnox).

C'est parti pour la **Partie 5**.

C'est la section la plus critique. Ici, nous définissons comment ton infrastructure reste sécurisée même si ton laptop est volé ou si tu commites ton dossier `dotfiles` en public par erreur.

L'agent IA doit comprendre que nous n'utilisons **PAS** la méthode standard Nix (SOPS/Agenix) qui stocke des fichiers chiffrés dans le repo. Nous utilisons une approche **"Zero-Knowledge Repo"**.

---

# 📘 MASTER DESIGN DOCUMENT - PARTIE 5/6

## Sécurité, Secrets & Identité (Zero-Trust Architecture)

### 1. Philosophie de Sécurité "Zero-Trust"

Contrairement aux dotfiles classiques qui chiffrent les secrets pour les stocker dans Git (via `git-crypt` ou `sops`), notre architecture pose un interdit strict :

> **Règle d'Or :** Le dépôt Git ne contient **AUCUNE** donnée sensible, même chiffrée. Il ne contient que des **pointeurs** vers des coffres-forts externes (Hardware ou System Keychain).

**Pourquoi ?**

1. **Multi-Tenancy :** Si tu clones ton repo sur une machine "Guest", les secrets chiffrés sont physiquement présents sur le disque. C'est un risque inutile.

2. **Rotation :** Changer une clé compromise ne nécessite pas de "re-chiffrer" le repo et de faire un commit. Il suffit de mettre à jour le coffre local.

---

### 2. Gestion des Secrets d'Environnement (Fnox)

Nous utilisons **Fnox** (de jdx) pour injecter les secrets en mémoire RAM uniquement au lancement du shell.

#### A. La Carte des Secrets (`fnox.toml`)

Ce fichier est public. Il dit "Où chercher", pas "Ce que c'est".

**Chemin :** `~/dotfiles/fnox.toml`

Ini, TOML

```
[#] Configuration Globale
# Si un secret manque, Fnox ne doit pas faire planter le shell, juste avertir.
error_mode = "warn"

[secrets]
# --- API KEYS (Dev) ---
# Format: VAR_ENV = "provider://nom_clé"

# Sur Mac, ça cherche dans le Keychain "login"
# Sur Linux, ça cherche dans le Secret Service (Gnome Keyring / KWallet) ou Pass
OPENAI_API_KEY = "keychain://openai_api_key"
ANTHROPIC_API_KEY = "keychain://anthropic_api_key"

# --- INFRASTRUCTURE ---
# Token pour que Terraform puisse parler à Cloudflare
CLOUDFLARE_API_TOKEN = "keychain://cloudflare_token"

# --- BACKUPS ---
# Mot de passe du repo Restic (Backup)
RESTIC_PASSWORD = "keychain://restic_backup_pw"
```

#### B. L'Intégration Shell (`modules/common/shell.nix`)

C'est le mécanisme qui déverrouille les secrets.

Nix

```
# Extrait de modules/common/shell.nix
programs.zsh.initExtra = ''  # On ne lance Fnox que si on est dans une session interactive pour ne pas ralentir les scripts  if [[ -o interactive ]] && command -v fnox &> /dev/null; then      # "activate" génère les commandes 'export VAR=...'      # Les secrets transitent par un pipe sécurisé, jamais écrits sur disque.      eval "$(fnox activate zsh)"  fi'';
```

#### C. Workflow : Ajouter un Secret

L'agent IA doit savoir générer le script assistant pour cela.

**Script :** `scripts/wizards/secret.sh`

Bash

```
#!/usr/bin/env bash
# Wizard pour ajouter un secret Fnox

KEY=$(gum input --placeholder "Nom de la variable (ex: STRIPE_KEY)")
VAL=$(gum input --password --placeholder "Valeur du secret")
NOTE=$(gum input --placeholder "Note pour le Keychain (optionnel)")

# Détection OS pour choisir le bon backend de stockage
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac: On écrit dans le Keychain via l'outil 'security' ou fnox directement
    fnox set "$KEY" "$VAL"
else
    # Linux: On utilise 'pass' ou le keyring system
    # Exemple avec 'pass' si fnox est configuré pour l'utiliser
    echo "$VAL" | pass insert -m "$KEY"
fi

gum style --foreground 212 "🔒 Secret $KEY enregistré localement !"
gum style --foreground 240 "N'oublie pas de l'ajouter dans fnox.toml si ce n'est pas fait."
```

---

### 3. Gestion de l'Identité SSH (Hardware-Backed)

L'accès aux serveurs et à GitHub ne se fait plus via des fichiers `~/.ssh/id_rsa`.

#### A. Architecture macOS (Secretive)

Nous utilisons l'enclave sécurisée (Secure Enclave) de la puce Apple Silicon. La clé privée est **in-exfiltrable**.

- **Outil :** `Secretive` (installé via `modules/darwin/security.nix`).

- **Fonctionnement :** Secretive expose un socket SSH. À chaque utilisation (git push, ssh server), macOS demande une confirmation TouchID.

- **Config (`~/.ssh/config` via Stow) :**
  
  Extrait de code
  
  ```
  Host *
      IdentityAgent /Users/nnosal/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
  ```

#### B. Architecture Fallback (Linux / Windows)

Sur les machines sans Secure Enclave, nous utilisons l'agent standard, mais cloisonné.

- **Outil :** `ssh-agent` standard (ou YubiKey si dispo).

- **Chargement Dynamique :** Le script Zsh (`modules/common/shell.nix`) doit être assez malin pour trouver le bon socket.

Bash

```
# Dans modules/common/shell.nix

# Logique de détection du Socket SSH (Ordre de priorité)
if [[ -S "$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh" ]]; then
    # 1. Priorité Mac Secure Enclave
    export SSH_AUTH_SOCK="$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"
elif [[ -S "$XDG_RUNTIME_DIR/ssh-agent.socket" ]]; then
    # 2. Linux Standard Agent
    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
fi
```

---

### 4. Signature Git (Verified Commits)

Pour que tes commits soient marqués "Verified" sur GitHub sans gérer de clés GPG complexes.

**Configuration (`users/nnosal/default.nix`) :**

Nix

```
programs.git = {
  enable = true;

  # On utilise la clé SSH pour signer (Feature moderne de Git)
  # Plus besoin de GPG !
  extraConfig = {
    gpg.format = "ssh";
    commit.gpgsign = true;

    # Sur Mac, on pointe vers la clé publique Secretive
    # Sur Linux, vers la clé publique ~/.ssh/id_ed25519.pub
    # Astuce : On peut utiliser un chemin conditionnel ou laisser l'agent gérer
    user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..."; 
  };
};
```

---

### 5. Prévention des Fuites (Leak Prevention)

C'est le dernier filet de sécurité. L'outil `hk` doit empêcher tout commit contenant une clé privée.

**Configuration (`hk.pkl`) :**

Extrait de code

```
// hk.pkl
amends "package://github.com/jdx/hk/releases/download/v1.27.0/hk@1.27.0#/Config.pkl"
import "package://github.com/jdx/hk/releases/download/v1.27.0/hk@1.27.0#/Builtins.pkl"

local linters = new Mapping<String, Step> {
    // 🛑 ARRET D'URGENCE si une clé privée est détectée
    ["detect-private-key"] = Builtins.detect_private_key
}

hooks {
    ["pre-commit"] {
        steps {
            ...linters
        }
    }
}
```

---

### 6. Résumé pour l'Agent IA

Lors de l'implémentation :

1. **Ne jamais** créer de fichiers `.sops.yaml` ou `.age`. Si tu vois ça dans un template, supprime-le.

2. **Fnox est le roi :** Toutes les variables d'environnement sensibles doivent passer par `fnox.toml`.

3. **SSH Dynamique :** Ne hardcode jamais le chemin du socket SSH dans `.zshrc` sans vérifier si le fichier existe (sinon ça casse sur Linux).

4. **Hardware First :** Sur macOS, configure toujours `Secretive` par défaut dans le module `darwin`.

Cette **Partie 5** garantit que ton infrastructure est une forteresse. Tes secrets sont dans ta tête (mots de passe) ou dans ta puce de sécurité (clés), jamais dans ton code.

Passons à la dernière étape, la **Partie 6**, pour assembler le Cockpit de pilotage.

C'est la dernière ligne droite. La **Partie 6** est celle qui transforme ce système complexe en une "boîte noire" simple à utiliser.

C'est ici que nous définissons **"L'Interface Homme-Machine"** de ton infrastructure. L'agent IA doit générer ces scripts avec une précision chirurgicale, car c'est eux que tu utiliseras 99% du temps.

---

# 📘 MASTER DESIGN DOCUMENT - PARTIE 6/6

## L'Expérience "Cockpit", Automation & Maintenance

### 1. Le Chef d'Orchestre (`mise.toml`)

Nous avons éliminé `Makefile` et `Justfile`. C'est **Mise** qui gère tout : l'installation des outils (Gum, Hk, Nh) et l'exécution des tâches.

**Chemin :** `~/dotfiles/mise.toml`

Ini, TOML

```
[meta]
name = "ultimate-dotfiles"

[tools]
# Outils indispensables au Cockpit
gum = "latest"      # UI Interactif
fzf = "latest"      # Recherche floue
bat = "latest"      # Cat avec syntax highlight
hk = "latest"       # Git Hooks manager
pkl = "latest"      # Config language pour hk
nh = "latest"       # Nix Helper (Speed up builds & GC)
stylua = "latest"   # Formatter Lua (Neovim)
shfmt = "latest"    # Formatter Bash

[tasks.install]
description = "Bootstrap initial post-clone"
run = """#!/usr/bin/env bash# 1. Installe les hooks githk install# 2. Applique la config Nix initiale./scripts/cockpit.sh --apply-only"""

[tasks.ui]
description = "🖥️  Ouvre le Cockpit Principal"
alias = "cockpit"
run = "./scripts/cockpit.sh"

[tasks.switch]
description = "🔄 Applique la config Nix (Rebuild)"
run = "nh os switch ." # nh détecte auto si c'est Darwin ou NixOS

[tasks.stow]
description = "🔗 Applique les dotfiles (Symlinks)"
run = "./scripts/stow-apply.sh"

[tasks.save]
description = "☁️  Snapshot : Git Add + Commit + Push"
run = """#!/usr/bin/env bashgit add .MSG=$(gum input --placeholder "Message de commit...")git commit -m "$MSG"git push"""

[tasks.gc]
description = "🧹 Nettoyage du Store Nix"
run = "nh clean all --keep 3" # Garde les 3 dernières générations
```

---

### 2. Le Cockpit (`scripts/cockpit.sh`)

C'est le menu principal. Il remplace la connaissance des commandes par une interface visuelle.

**Chemin :** `~/dotfiles/scripts/cockpit.sh`

Bash

```
#!/usr/bin/env bash
set -e

# Import des helpers (couleurs, check dependencies)
source ./scripts/utils.sh

# Bannière
gum style --border double --margin "1" --padding "1 2" --border-foreground 212 "🎛️  ULTIMATE COCKPIT"

# Menu Principal
CHOICE=$(gum choose \
    "🔄 Appliquer (Switch Nix)" \
    "🔗 Relier Dotfiles (Stow)" \
    "✨ Ajouter (App/Host/User)" \
    "✏️  Éditer une config (Fuzzy)" \
    "🔒 Gérer Secrets (Fnox)" \
    "🚀 Sauvegarder (Git Push)" \
    "🧹 Nettoyer (Garbage Collect)" \
    "🗑️  Désinstaller une App" \
    "🚪 Quitter")

case $CHOICE in
    "🔄 Appliquer"*)  mise run switch ;;
    "🔗 Relier"*)     mise run stow ;;
    "✨ Ajouter"*)
        SUB=$(gum choose "Application (Cask/Pkg)" "Machine (Host)" "Utilisateur")
        case $SUB in
            "Application"*) ./scripts/wizards/add-app.sh ;;
            "Machine"*)     ./scripts/wizards/add-host.sh ;;
            "Utilisateur"*) ./scripts/wizards/add-user.sh ;;
        esac
        ;;
    "✏️  Éditer"*)      ./scripts/wizards/edit.sh ;;
    "🔒 Gérer"*)       ./scripts/wizards/secret.sh ;;
    "🚀 Sauvegarder"*)  mise run save ;;
    "🧹 Nettoyer"*)     mise run gc ;;
    "🗑️  Désinstaller"*) ./scripts/wizards/remove-app.sh ;;
    "🚪 Quitter")      exit 0 ;;
esac
```

---

### 3. Les Assistants Magiques (Wizards)

L'IA doit implémenter ces scripts pour manipuler les fichiers Nix sans casser la syntaxe.

#### A. L'Injecteur d'Apps (`scripts/wizards/add-app.sh`)

Ce script repose sur des **Marqueurs** (`MARKER`) placés dans les fichiers Nix.

Bash

```
#!/usr/bin/env bash
# 1. Choisir le type
TYPE=$(gum choose "GUI App (Mac Cask)" "CLI Tool (Tous OS)")
APP_NAME=$(gum input --placeholder "Nom du paquet (ex: vlc, ripgrep)")

if [ "$TYPE" == "GUI App (Mac Cask)" ]; then
    # Cible : modules/darwin/apps.nix
    TARGET="modules/darwin/apps.nix"
    MARKER="# %% CASKS %%"
    LINE="\"$APP_NAME\""
else
    # Cible : modules/common/packages.nix
    TARGET="modules/common/packages.nix"
    MARKER="# %% PACKAGES %%"
    LINE="pkgs.$APP_NAME"
fi

# 2. Injection (sed)
# On insère la ligne AVANT le marqueur, ou APRES selon la stratégie
# Ici on utilise une astuce perl ou sed pour insérer dans la liste
sed -i "/$MARKER/a \    $LINE" "$TARGET"

gum style --foreground 212 "✅ $APP_NAME ajouté ! Lancement du switch..."
mise run switch
```

#### B. Le Navigateur Intelligent (`scripts/wizards/edit.sh`)

Plus besoin de chercher dans l'arborescence.

Bash

```
#!/usr/bin/env bash
# Liste tous les fichiers .nix, .toml, .lua en ignorant le dossier .git et result
FILE=$(find . -type f \( -name "*.nix" -o -name "*.toml" -o -name "*.lua" \) \
    -not -path "*/.git/*" -not -path "*/result/*" | \
    gum filter --placeholder "🔍 Quel fichier modifier ?")

# Ouvre avec l'éditeur par défaut ($EDITOR ou vim)
if [ -n "$FILE" ]; then
    ${EDITOR:-vim} "$FILE"

    # Propose d'appliquer après fermeture
    if gum confirm "Voulez-vous appliquer les changements maintenant ?"; then
        # Détecte si c'est un fichier Stow (dans stow/) ou Nix
        if [[ "$FILE" == *"stow/"* ]]; then
            mise run stow
        else
            mise run switch
        end
    fi
fi
```

---

### 4. Qualité Automatisée (CI/CD & Hooks)

#### A. Le Gardien Local (`hk` + `hk.pkl`)

Empêche de commiter du code cassé ou des clés privées.

Extrait de code

```
// hk.pkl
amends "package://github.com/jdx/hk/releases/download/v1.27.0/hk@1.27.0#/Config.pkl"
import "package://github.com/jdx/hk/releases/download/v1.27.0/hk@1.27.0#/Builtins.pkl"

local linters = new Mapping<String, Step> {
    // Formatteur Nix
    ["nixfmt"] {
        glob = List("**.nix")
        check = "nixfmt --check {{files}}"
        fix = "nixfmt {{files}}"
    }
    // Formatteur Shell
    ["shfmt"] {
        glob = List("**.sh")
        check = "shfmt -d {{files}}"
        fix = "shfmt -w {{files}}"
    }
    // Sécurité critique
    ["detect-private-key"] = Builtins.detect_private_key
}

hooks {
    ["pre-commit"] {
        fix = true
        steps { ...linters }
    }
}
```

#### B. Le Gardien Distant (GitHub Actions)

Vérifie que le Flake est valide sur le cloud.

**Fichier :** `.github/workflows/ci.yml`

YAML

```
name: CI
on: [push, pull_request]
jobs:
  check-flake:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - uses: cachix/install-nix-action@v2
    - name: Check Flake Syntax
      run: nix flake check
    - name: Dry Run Build (Linux)
      # Tente de construire la config VPS pour vérifier les erreurs Nix
      run: nix build .#nixosConfigurations.contabo1.config.system.build.toplevel --dry-run
```

---

### 5. Maintenance & Self-Healing

L'outil **`nh`** (Nix Helper) est configuré pour gérer le cycle de vie.

- **Logs améliorés :** `nh` affiche une barre de progression et un arbre de diff visuel lors des mises à jour ("Ce qui a changé : +vlc, -firefox").

- **Nettoyage (`gc`) :** Nix garde toutes les versions précédentes. `nh clean all --keep 3` supprime tout sauf les 3 dernières générations actives. C'est vital pour ne pas saturer le disque du MacBook Air.

---

### 6. Directives Finales pour l'Agent IA

Lors de la génération du code de cette partie :

1. **Templates avec Marqueurs :** Tu DOIS inclure `# %% CASKS %%` dans `modules/darwin/apps.nix` et `# %% PACKAGES %%` dans `modules/common/packages.nix`. Sans ces commentaires, le script `add-app.sh` échouera.

2. **Dépendances Mise :** Vérifie que `gum` est bien listé dans `[tools]` de `mise.toml`. C'est le moteur du Cockpit.

3. **Permissions :** Tous les scripts dans `scripts/` doivent être rendus exécutables (`chmod +x`) par le script de bootstrap.

4. **Idempotence :** Le script `stow-apply.sh` doit gérer le cas où des fichiers existent déjà (conflit Stow) en proposant (via Gum) de les écraser ou de les backuper (`--adopt`).

---

### 🏁 Conclusion du Master Design Document

Nous avons maintenant une spécification complète en 6 parties.

1. **Philosophie :** Zero-Trust, Hybrid Windows, Stow Profiles.

2. **Cartographie :** Structure de fichiers précise.

3. **Cœur Nix :** `mkSystem` et Flake modulaire.

4. **Cross-Platform :** Gestion Windows/WSL et Stow.

5. **Sécurité :** Fnox, Secretive, Hk.

6. **Cockpit :** Interface TUI et Scripts Wizards.

Tu disposes de tout le nécessaire pour construire l'infrastructure ultime. 
**Exécution !** 🚀

----

C'est parti. Voici l'**Annexe A Étendue** avec plus de **20 Cas d'Usage (User Cases)** ultra-détaillés.

Ces scénarios couvrent l'intégralité du cycle de vie de ton infrastructure, du simple alias à la gestion de crise sur un serveur de prod. Ils servent de "Cahier de Recette" pour valider que ton système répond à tout.

---

# 📂 ANNEXES DU MASTER DESIGN DOCUMENT

## 📑 Annexe A : 22 Cas d'Usage (User Cases) Réalistes & Précis

### 🟢 GROUPE 1 : INITIALISATION & BOOTSTRAP

#### 🆔 UC-01 : Bootstrap d'un MacBook Pro (M3 Max) vierge

- **Contexte :** Tu sors le Mac du carton. Aucun outil installé. Tu veux ton env complet.

- **Action :**
  
  1. Ouvrir Terminal.app.
  
  2. `sh <(curl -L https://dotfiles.nnosal.com)`

- **Système :**
  
  - Télécharge Nix (daemon multi-user).
  
  - Lance un shell éphémère (`nix shell`) avec Git et Gum.
  
  - Clone le repo dans `~/dotfiles`.
  
  - Lance `mise install` pour setup Hk, Nh, Bat.
  
  - Lance `nh os switch` (applique le profil `hosts/pro/macbook-pro`).

- **Résultat :** En ~15min, tu as Zsh, Starship, tes Apps (Raycast, Docker), tes Fonts et ta clé SSH Secretive prête à être enrôlée.

#### 🆔 UC-02 : Bootstrap d'un Serveur Linux (VPS Contabo)

- **Contexte :** Tu as un VPS Debian 12 tout nu. Tu veux tes dotfiles + Docker + K9s.

- **Action :**
  
  1. SSH root@ip.
  
  2. `sh <(curl -L https://dotfiles.nnosal.com)`
  
  3. Le script détecte Linux, installe Nix.
  
  4. Demande : *"Quel Host appliquer ?"* -> Choisir **infra/contabo1**.

- **Système :**
  
  - Applique la config NixOS (ou Home-Manager standalone si non-NixOS).
  
  - Installe Docker, Zsh, Neovim.
  
  - Configure le firewall et SSH (désactive root login password).

- **Résultat :** Un serveur durci, avec ton shell habituel, prêt à héberger.

#### 🆔 UC-03 : Bootstrap Windows Gaming (Le Centaure)

- **Contexte :** Tu viens de réinstaller Windows 11 pour jouer. Tu veux Steam + un terminal décent.

- **Action :**
  
  1. Powershell (Admin) : `irm https://dotfiles.nnosal.com/win | iex`

- **Système :**
  
  - Installe `mise` via Winget.
  
  - Mise lit `windows.toml` et installe : Steam, Discord, VSCode, WSL.
  
  - Mise lance l'installation d'Ubuntu WSL et y injecte le bootstrap Linux (UC-02).

- **Résultat :** Windows a tes jeux. WSL a ton Zsh. Les deux se parlent.

---

### 🟡 GROUPE 2 : GESTION QUOTIDIENNE (COCKPIT)

#### 🆔 UC-04 : Installation d'un outil CLI (ex: `jq`)

- **Contexte :** Tu as besoin de parser du JSON. `jq` n'est pas là.

- **Action :**
  
  1. `cockpit` (ou `mise run ui`) -> **✨ Ajouter** -> **Application** -> "jq".

- **Système :**
  
  - Script `add-app.sh` édite `modules/common/packages.nix`.
  
  - Ajoute `pkgs.jq` dans la liste.
  
  - Lance `nh os switch` pour l'installer.

- **Résultat :** `jq` est dispo partout. Le changement est versionné dans Git.

#### 🆔 UC-05 : Installation d'une App GUI Mac (ex: `Obsidian`)

- **Contexte :** Tu veux Obsidian sur ton Mac.

- **Action :**
  
  1. `cockpit` -> **✨ Ajouter** -> **Application (Cask)** -> "obsidian".

- **Système :**
  
  - Script cible `modules/darwin/apps.nix` (spécifique Mac).
  
  - Ajoute `"obsidian"` dans `homebrew.casks`.
  
  - Lance le switch. Homebrew installe l'app.

- **Résultat :** Obsidian est dans `/Applications` et indexé par Spotlight/Raycast.

#### 🆔 UC-06 : Mise à jour globale du système

- **Contexte :** C'est lundi matin, tu veux tout mettre à jour.

- **Action :**
  
  1. `cockpit` -> **🔄 Appliquer (Switch)**.

- *Alternative :* `mise run update` (alias de `nix flake update && nh os switch`).

- **Système :**
  
  - Nix télécharge les dernières versions de `nixpkgs`.
  
  - Met à jour `flake.lock`.
  
  - Reconstruit le système.
  
  - Met à jour les Casks Homebrew et les plugins Neovim.

- **Résultat :** Tout est à jour. Si ça casse, tu as le lock précédent pour rollback.

#### 🆔 UC-07 : Nettoyage du Disque (Garbage Collection)

- **Contexte :** Ton SSD est plein à cause des vieilles versions de Nix.

- **Action :**
  
  1. `cockpit` -> **🧹 Nettoyer**.

- **Système :**
  
  - Exécute `nh clean all --keep 3`.
  
  - Supprime toutes les générations système sauf les 3 dernières.
  
  - Optimise le store Nix.

- **Résultat :** Tu récupères 20-50 Go d'espace disque.

---

### 🔵 GROUPE 3 : CONFIGURATION & ÉDITION (LIVE EDITING)

#### 🆔 UC-08 : Modification d'un Alias Zsh

- **Contexte :** Tu veux ajouter `alias g=git`.

- **Action :**
  
  1. `cockpit` -> **✏️ Éditer** -> Taper "alias" -> Sélectionner `.config/zsh/aliases.zsh`.
  
  2. Ajouter `alias g=git`.
  
  3. Sauvegarder et quitter.

- **Système :**
  
  - Le fichier est dans `stow/common/...`.
  
  - Comme il est symlinké, la modif est immédiate.
  
  - Le script propose de `source ~/.zshrc`.

- **Résultat :** L'alias fonctionne tout de suite. Pas de rebuild Nix nécessaire.

#### 🆔 UC-09 : Ajout d'un Plugin Neovim

- **Contexte :** Tu veux tester `harpoon` sur Neovim.

- **Action :**
  
  1. Ouvrir `stow/common/.config/nvim/lua/plugins.lua`.
  
  2. Ajouter le bloc Lazy.nvim pour Harpoon.
  
  3. Relancer Neovim.

- **Résultat :** Neovim installe le plugin au démarrage. Nix gère le binaire `nvim`, mais Stow gère ta config Lua mutable.

#### 🆔 UC-10 : Changement de Thème (Stylix)

- **Contexte :** Tu en as marre de "Catppuccin", tu veux "Dracula".

- **Action :**
  
  1. `cockpit` -> **✏️ Éditer** -> "style.nix".
  
  2. Changer `base16Scheme` vers `.../dracula.yaml`.
  
  3. `mise run switch`.

- **Système :**
  
  - Nix régénère les fichiers de config pour Ghostty, Zsh, Bat, Fzf avec les codes hexa de Dracula.

- **Résultat :** Tout ton OS change de couleur harmonieusement.

---

### 🔴 GROUPE 4 : SÉCURITÉ & SECRETS (ZERO-TRUST)

#### 🆔 UC-11 : Ajout d'une Clé API (Projet Client)

- **Contexte :** Nouveau projet, tu as une `STRIPE_SECRET_KEY`.

- **Action :**
  
  1. `cockpit` -> **🔒 Gérer Secrets**.
  
  2. Nom : `STRIPE_KEY`, Valeur : `sk_test_...`.

- **Système :**
  
  - Détecte macOS -> Ajoute dans le Keychain "login" via `security`.
  
  - (Ou) Détecte Linux -> Ajoute dans Gnome Keyring via `secret-tool`.
  
  - Ajoute la référence `STRIPE_KEY = "keychain://STRIPE_KEY"` dans `fnox.toml`.

- **Résultat :** `echo $STRIPE_KEY` fonctionne. Le secret n'est **jamais** écrit dans un fichier.

#### 🆔 UC-12 : Rotation de Clé SSH Compromise

- **Contexte :** Tu penses que ta clé Github est compromise.

- **Action :**
  
  1. Ouvrir l'app **Secretive** (Mac).
  
  2. Supprimer l'ancienne clé. Créer une nouvelle.
  
  3. Copier la nouvelle clé publique dans GitHub UI.

- **Système :**
  
  - Rien à changer dans les dotfiles !
  
  - La config SSH pointe toujours vers le socket Secretive.

- **Résultat :** L'accès est rétabli. Aucun commit nécessaire.

#### 🆔 UC-13 : Empêcher un Commit Dangereux

- **Contexte :** Tu es fatigué, tu as hardcodé un password dans un script `test.sh` et tu fais `git commit`.

- **Action :**
  
  1. `git commit -m "debug"`

- **Système :**
  
  - **Hk** se lance.
  
  - Linter `detect-private-key` scanne les fichiers stagés.
  
  - Trouve le pattern du mot de passe.

- **Résultat :** Le commit est **bloqué** avec un message d'alerte rouge. Tu es sauvé.

---

### 🟣 GROUPE 5 : CROSS-PLATFORM & AVANCÉ

#### 🆔 UC-14 : Switch Contexte "Perso" sur Mac Pro

- **Contexte :** Tu utilises ton Mac Pro (Config Work par défaut) pour un hackathon le week-end. Tu veux tes configs perso.

- **Action :**
  
  1. `mise run stow` -> Choisir **🏠 Personal**.

- **Système :**
  
  - Délie `~/.ssh/config.d/work.conf` (plus d'accès aux serveurs boulot).
  
  - Lie `~/.ssh/config.d/perso.conf` (accès au Raspberry Pi).
  
  - Lie `~/.steam` (si applicable).

- **Résultat :** Environnement isolé. Pas de risque de `git push` pro sur un repo perso.

#### 🆔 UC-15 : Ouvrir un lien depuis WSL (Interop)

- **Contexte :** Tu es dans le terminal WSL, tu fais `open http://localhost:3000`.

- **Action :**
  
  1. Commande : `open http://localhost:3000`

- **Système :**
  
  - L'alias `open` pointe vers `wslview` (installé par `modules/wsl`).
  
  - `wslview` appelle le navigateur par défaut de Windows (Chrome/Edge).

- **Résultat :** La page s'ouvre sur Windows, pas dans un navigateur texte Linux.

#### 🆔 UC-16 : Ajout d'un Nouveau Host (Nouveau PC Portable)

- **Contexte :** Tu achètes un Dell XPS 13 (Linux).

- **Action :**
  
  1. `cockpit` -> **✨ Ajouter** -> **Machine (Host)**.
  
  2. Nom : `xps-13`. OS : `nixos`.

- **Système :**
  
  - Crée `hosts/perso/xps-13/default.nix` depuis le template.
  
  - Ajoute l'entrée dans `flake.nix` via `lib.mkSystem`.

- **Résultat :** Tu n'as plus qu'à commiter, puller sur le Dell, et lancer le bootstrap.

#### 🆔 UC-17 : Rollback après une config cassée

- **Contexte :** Tu as modifié `flake.nix` et ton système ne boot plus correctement (ou l'affichage bug).

- **Action :**
  
  1. Rebooter.
  
  2. Dans le menu de boot (Grub/Systemd-boot), choisir "NixOS - Generation X-1".

- *Sur Mac :* `nh os switch --rollback`.

- **Résultat :** Retour instantané à la config d'hier qui marchait.

#### 🆔 UC-18 : Partage de Config avec un Invité

- **Contexte :** Un ami utilise ton Mac. Tu veux qu'il ait un terminal propre mais PAS accès à tes secrets.

- **Action :**
  
  1. Créer un user macOS "Guest".
  
  2. Appliquer le profil `users/guest` (défini dans Nix).

- **Système :**
  
  - Installe Zsh, Starship.
  
  - **N'injecte PAS** Fnox (donc pas d'ENV vars).
  
  - **Ne lie PAS** le socket Secretive (donc pas de SSH).

- **Résultat :** Il a un beau terminal, mais il ne peut rien casser ni voler.

#### 🆔 UC-19 : Debugging d'une lenteur Shell

- **Contexte :** Zsh met 2 secondes à s'ouvrir.

- **Action :**
  
  1. Lancer `zsh --sourcetrace` ou utiliser un outil de profiling.
  
  2. Se rendre compte que `nvm` (Node Version Manager) est lent.
  
  3. Remplacer `nvm` par `mise` (qui est lazy-loaded) dans `modules/common/packages.nix`.

- **Résultat :** Zsh démarre en 50ms.

#### 🆔 UC-20 : Fixer un conflit de Lockfile (Git)

- **Contexte :** `flake.lock` est en conflit après un merge.

- **Action :**
  
  1. `cockpit` -> **🔄 Appliquer**.
  
  2. Nix détecte l'erreur.
  
  3. Lancer `nix flake update` pour régénérer le lock proprement.
  
  4. `mise run save` -> "Fix lockfile".

#### 🆔 UC-21 : Installation d'une Font Custom

- **Contexte :** Tu veux utiliser "Monaspace Krypton".

- **Action :**
  
  1. Ajouter le `.otf` dans `modules/common/fonts/`.
  
  2. Déclarer dans `modules/common/style.nix` : `fonts.packages = [ ./fonts/Monaspace.otf ];`.
  
  3. Switch.

- **Résultat :** La font est installée système et dispo pour ton terminal et VSCode.

#### 🆔 UC-22 : Sauvegarde Rapide "Fin de Journée"

- **Contexte :** Tu as fait plein de petits tweaks (alias, config nvim, ajout app). Tu veux tout save avant de partir.

- **Action :**
  
  1. `mise run save`.
  
  2. Message : "WIP: Tweaks du mardi".

- **Système :**
  
  - Git Add All + Commit + Push.
  
  - Vérification Hk (Linting) au passage.

- **Résultat :** Tout est sur GitHub. Tu peux éteindre sereinement.

C'est parti. Je prends une grande inspiration 😤.

Voici **l'Annexe 2 : La "Bible Visuelle"**.

Ce document contient l'intégralité de mon contexte architectural traduit en diagrammes. J'ai repris tous ceux validés précédemment et j'ai généré les diagrammes **manquants** pour couvrir la mécanique interne de chaque feature (Stow, Hk, Cockpit, Flake).

C'est le plan d'assemblage complet pour l'Agent IA.

---

# 📂 ANNEXES DU MASTER DESIGN DOCUMENT

## 📐 Annexe B : Cartographie Visuelle Intégrale (Mermaid)

### 1. 🌍 La "Big Picture" (Architecture Système)

*Ce diagramme pose les fondations : Un repo unique pour 3 mondes.*

Extrait de code

```
graph TD
    Repo[📁 ~/dotfiles <br/> Single Source of Truth]

    subgraph "🍎 Ecosystem Apple"
        MacPro[MacBook Pro / Studio]
        BootstrapMac[🚀 bootstrap.sh]
        NixDarwin[❄️ nix-darwin]
        Secretive[🔒 Secretive <br/> TouchID]
    end

    subgraph "🐧 Ecosystem Linux"
        VPS[Contabo / RPi]
        BootstrapLin[🚀 bootstrap.sh]
        NixOS[❄️ NixOS]
        Agent[🔒 SSH Agent]
    end

    subgraph "🪟 Ecosystem Windows"
        GamingRig[Gaming PC]
        BootstrapWin[🚀 bootstrap.ps1]

        subgraph "Hybrid Strategy"
            Native[Powershell Host]
            WSL[WSL2 Guest]
        end

        Winget[📦 Winget + Mise]
        NixWSL[❄️ Nix Home-Manager]
    end

    Repo --> BootstrapMac
    BootstrapMac --> NixDarwin
    NixDarwin --> Secretive

    Repo --> BootstrapLin
    BootstrapLin --> NixOS
    NixOS --> Agent

    Repo --> BootstrapWin
    BootstrapWin --> Native
    Native -- "Installs & Boots" --> WSL
    WSL --> NixWSL
```

---

### 2. 🚀 Le Bootstrapping "Zero-Install" (Sequence)

*Comment on passe de "Rien" à "Tout installé" sans cloner manuellement.*

Extrait de code

```
sequenceDiagram
    participant User as 👤 Toi
    participant Web as 🌐 Curl/Web
    participant Temp as ⚡ Shell Éphémère
    participant NixMise as ⚙️ Nix / Mise
    participant Repo as 📁 ~/dotfiles

    User->>Web: 1. "One-Liner" (curl ... | sh)
    Web->>Temp: Télécharge script d'entrée

    rect rgb(30, 30, 30)
        note right of Temp: Phase Volatile (RAM)
        Temp->>NixMise: Installe le Moteur (Nix ou Mise)
        Temp->>NixMise: "Donne-moi Gum temporairement" (nix shell / mise x)
        NixMise-->>User: 2. Affiche le TUI (Gum)
    end

    User->>Temp: Valide l'installation
    Temp->>Repo: 3. git clone https://github...

    rect rgb(0, 50, 0)
        note right of Repo: Phase État Stable (Disk)
        Repo->>NixMise: "mise run install" (Setup final)
        NixMise->>User: 4. Shell prêt (Zsh/Starship)
    end
```

---

### 3. 🧠 Le Cœur Nix : Assemblage Flake (Data Flow)

*Nouveau diagramme : Comment `lib.mkSystem` transforme les briques `modules` en un système bootable.*

Extrait de code

```
flowchart LR
    subgraph INPUTS
        NixPkgs[NixPkgs Unstable]
        Darwin[Nix-Darwin]
        HM[Home-Manager]
        Stylix[Stylix Theme]
    end

    subgraph LIBRARY
        MkSystem[⚙️ lib.mkSystem]
        MkHome[⚙️ lib.mkHome]
    end

    subgraph CONFIG_BLOCKS
        ModCommon[📦 modules/common]
        ModOS[📦 modules/darwin|linux]
        HostDef[🖥️ hosts/pro/macbook]
        UserDef[👤 users/nnosal]
    end

    subgraph OUTPUTS
        Result[❄️ System Closure]
    end

    NixPkgs --> MkSystem
    Darwin --> MkSystem
    HM --> MkSystem
    Stylix --> MkSystem

    ModCommon --> HostDef
    ModOS --> HostDef
    UserDef --> HostDef

    HostDef --> MkSystem
    MkSystem --> Result
```

---

### 4. 🪟 La Stratégie Windows "Centaure" (Architecture)

*Détail de la séparation des pouvoirs entre Windows Natif et WSL.*

Extrait de code

```
flowchart TB
    subgraph "🪟 Windows 11 Host"
        Entry[🚀 bootstrap.ps1]
        MiseWin[🔧 Mise (Windows Binary)]
        Winget[📦 Winget]

        AppsWin[🎮 Native Apps <br/> Steam, Discord, VSCode]
        Runtimes[🐍 Node, Python, Go <br/> (Windows Native Dev)]
    end

    subgraph "🐧 WSL2 (Linux Subsystem)"
        Nix[❄️ Nix Package Manager]
        Zsh[🐚 Zsh + Starship]
        ToolsCLI[🛠️ CLI Tools <br/> Git, K9s, Bat, Fzf]

        Integration[🔗 Modules/WSL <br/> (Clipboard, Browser Open)]
    end

    Entry --> MiseWin
    MiseWin -- "Installs" --> Winget
    Winget --> AppsWin
    MiseWin -- "Installs" --> Runtimes

    Entry -- "Bootstraps" --> Nix
    Nix --> Zsh
    Nix --> ToolsCLI
    Nix --> Integration

    Integration -.->|wslview| AppsWin
```

---

### 5. 🔗 La Mécanique Stow & Profils (Algorithme)

*Nouveau diagramme : La logique du script `stow-apply.sh`.*

Extrait de code

```
flowchart TD
    Start(🚀 mise run stow) --> Clean[🧹 Clean Dead Links]
    Clean --> Common[🌍 Apply 'common' profile <br/> .zshrc, .config/nvim]

    Common --> CheckEnv{ENV: MACHINE_CONTEXT?}

    CheckEnv -- Defined (Work) --> ApplyWork[💼 Apply 'work' profile <br/> .ssh/work.conf, .aws/]
    CheckEnv -- Defined (Perso) --> ApplyPerso[🏠 Apply 'personal' profile <br/> .ssh/perso.conf, .steam/]

    CheckEnv -- Undefined --> Gum{❓ Gum Choose}
    Gum -- User picks Work --> ApplyWork
    Gum -- User picks Perso --> ApplyPerso

    ApplyWork --> Done(✅ Done)
    ApplyPerso --> Done
```

---

### 6. 🛡️ Flux de Sécurité Zero-Trust (Séquence)

*Comment Fnox et Secretive interagissent sans jamais écrire sur le disque.*

Extrait de code

```
sequenceDiagram
    participant Hardware as 🔑 Secure Enclave
    participant Fnox as 🛡️ Fnox
    participant Shell as 🐚 Zsh (RAM)
    participant Repo as 📁 fnox.toml

    Note over Repo: Contient uniquement:<br/>KEY="keychain://ref"

    Shell->>Fnox: eval $(fnox activate)
    Fnox->>Repo: Lit les références

    par Parallel Fetch
        Fnox->>Hardware: Request 'openai_key'
        Hardware-->>Fnox: 🔓 Decrypted Value (TouchID)
    end

    Fnox->>Shell: export OPENAI_KEY="sk-..."
    Note over Shell: Secret vivant uniquement<br/>dans la session active
```

---

### 7. 🪝 Qualité & Git Hooks avec Hk (Flow)

*Nouveau diagramme : Ce qui se passe quand tu fais `git commit`.*

Extrait de code

```
flowchart LR
    User[👤 Developer] -->|git commit| Git
    Git -->|Triggers| Hook[🪝 .git/hooks/pre-commit]
    Hook -->|Executes| Hk[🦀 Hk Binary]

    subgraph Hk_Pipeline
        Config[📄 Read hk.pkl]
        Lint1[🔍 Nixfmt Check]
        Lint2[🔍 Shellcheck]
        Sec[🛑 Detect Private Key]
    end

    Hk --> Config
    Config --> Lint1
    Lint1 --> Lint2
    Lint2 --> Sec

    Sec -- Success --> Commit[✅ Commit Created]
    Sec -- Fail --> Reject[❌ Commit Rejected <br/> (Error Message)]
```

---

### 8. 🎛️ Logique du Cockpit (State Machine)

*Nouveau diagramme : L'arbre de décision du script `cockpit.sh`.*

Extrait de code

```
stateDiagram-v2
    [*] --> MenuPrincipal

    state MenuPrincipal {
        [*] --> GumChoose
        GumChoose --> Ajouter
        GumChoose --> Editer
        GumChoose --> Secrets
        GumChoose --> Switch
        GumChoose --> Save
    }

    state Ajouter {
        [*] --> Type?
        Type? --> AppCask: Mac GUI
        Type? --> AppPkg: CLI Tool
        Type? --> Host: Machine

        AppCask --> EditNix: apps.nix
        AppPkg --> EditNix: packages.nix
        Host --> CP_Template: host-darwin.nix
    }

    state Secrets {
        [*] --> InputKey
        InputKey --> InputValue
        InputValue --> DetectOS
        DetectOS --> WriteKeychain: Mac
        DetectOS --> WriteSecretService: Linux
    }

    EditNix --> Switch
    CP_Template --> Switch
    WriteKeychain --> [*]

    state Switch {
        [*] --> Nh_OS_Switch
    }
```

---

### 9. 🧠 Mindmap des Décisions (Keep/Out/Insight)

*Synthèse des choix architecturaux face aux `src_`.*

Extrait de code

```
mindmap
  root((Ultimate
  Architecture))
    Structure & Nix
      ::icon(fa fa-sitemap)
      src_8 MitchellH
        (Keep)
          lib mkSystem
          Separation Host/User
        (Out)
          Makefile
          Monolithic Configs
        (Insight)
          L'User doit être portable entre les Hosts.
    Config Management
      ::icon(fa fa-file-code)
      src_7 Omerxx
        (Keep)
          Stow
          Live Editing
        (Out)
          Home-Manager Pur (Read-Only)
        (Insight)
          Vitesse d'itération > Pureté absolue.
    Automation
      ::icon(fa fa-robot)
      src_1 DustinLyons
        (Keep)
          Mise (jdx)
        (Out)
          Bash Scripts Eparpillés
          Justfile
        (Insight)
          Un seul outil pour Tâches + Tools.
    Secrets
      ::icon(fa fa-user-secret)
      src_9 Zynh0722
        (Keep)
          Fnox (Zero-Trust)
          Secretive (Hardware)
        (Out)
          SOPS / Agenix
          Secrets in Git
        (Insight)
          Repo Public-Safe par design.
```

---

### 10. 🛤️ User Journey Étendu (DX)

*Le ressenti utilisateur au fil du temps.*

Extrait de code

```
journey
    title DX : Du Zero-Install au Disaster Recovery
    section 🚀 J-0 : Installation
      Curl One-Liner: 5: User
      Shell Volatile (Nix/Gum): 5: System
      Clone & Setup Auto: 5: System
      Login Shell Prêt: 5: User
    section ⚡️ J-1 : Quotidien
      Ouvrir Cockpit: 5: User
      Ajouter App (Wizard): 5: Cockpit
      Switch Nix (Auto): 4: System
      App dispo: 5: User
    section 🔧 J-7 : Tweak
      Edit .zshrc (Stow Live): 5: User
      Test immédiat: 5: User
      Save (Mise): 5: Cockpit
    section 🚨 J-300 : Crash
      Mac Volé/Cassé: 1: User
      Nouveau Mac: 3: User
      Bootstrap One-Liner: 5: User
      Retour à la normale (15min): 5: System
```

---

Cette **Annexe 2** est maintenant complète. Elle traduit chaque ligne de code et chaque décision philosophique en une représentation visuelle claire. L'Agent IA ne peut plus se tromper sur l'intention.

C'est parti. Voici l'**Annexe 3 : La Bible des Séquences Techniques**.

Ce document contient **22 Diagrammes de Séquence Mermaid** couvrant chaque fonctionnalité critique de l'architecture. C'est la documentation "Low-Level" qui explique exactement *qui appelle qui*, avec quels arguments et quel flux de données.

L'Agent IA doit s'y référer pour comprendre la mécanique interne invisible du Cockpit.

---

# 📂 ANNEXES DU MASTER DESIGN DOCUMENT

## 📐 Annexe C : Séquenciers Techniques Détaillés (20+ Features)

### 🟢 GROUPE 1 : BOOTSTRAP & CYCLE DE VIE (LIFECYCLE)

#### 1. Zero-Install Bootstrap (Unix)

*La mécanique exacte du "One-Liner" curl.*

Extrait de code

```
sequenceDiagram
    participant User as 👤 Toi
    participant Curl as 🌐 Curl
    participant Nix as ❄️ Nix Daemon
    participant Shell as ⚡ Shell Éphémère
    participant Git as 📦 Git (Nix Store)
    participant Repo as 📁 ~/dotfiles

    User->>Curl: sh <(curl dotfiles...)
    Curl->>Nix: Installe Nix (si absent)
    Nix-->>Shell: Prépare env (nix shell nixpkgs#git nixpkgs#gum)

    rect rgb(30, 30, 30)
        Note right of Shell: Environnement Volatile
        Shell->>User: Gum Confirm "Cloner ici ?"
        User->>Shell: OUI
        Shell->>Git: git clone https://github...
        Git-->>Repo: Télécharge les fichiers
    end

    Shell->>Repo: cd ~/dotfiles
    Shell->>Repo: ./scripts/cockpit.sh --apply
    Repo->>User: "Bienvenue dans Zsh"
```

#### 2. Zero-Install Bootstrap (Windows)

*L'approche native via PowerShell et Winget.*

Extrait de code

```
sequenceDiagram
    participant User as 👤 Toi
    participant PS as 🟦 PowerShell
    participant Winget as 📦 Winget
    participant Mise as 🔧 Mise.exe
    participant Repo as 📁 ~/dotfiles

    User->>PS: irm dotfiles.../win | iex
    PS->>Winget: install jdx.mise
    Winget-->>Mise: Binaire installé

    PS->>Mise: mise x gum -- gum confirm
    Mise->>User: Affiche UI Gum
    User->>Mise: Valide

    Mise->>Mise: mise x git -- git clone ...
    Mise-->>Repo: Clone effectué

    PS->>Repo: mise install (Setup Windows)
    Repo->>Winget: Installe Steam, Discord, VSCode
```

#### 3. Update Global (Switch)

*Comment `nh` orchestre la mise à jour.*

Extrait de code

```
sequenceDiagram
    participant User as 👤 Toi
    participant Cockpit as 🎛️ Scripts
    participant Nh as ❄️ Nh (Helper)
    participant Nix as ❄️ Nix Core
    participant Flake as 📄 flake.nix
    participant HM as 🏠 Home-Manager

    User->>Cockpit: "Appliquer Config"
    Cockpit->>Nh: nh os switch .
    Nh->>Flake: Évalue les outputs
    Flake->>Nix: Construit la dérivation

    alt Build Success
        Nix->>HM: Active le profil User
        HM->>User: Relance les services / Zsh
        Nix->>User: Active le profil Système (Sudo)
        Nh-->>User: ✅ Succès (Diff affiché)
    else Build Fail
        Nix-->>Nh: ❌ Erreur Log
        Nh-->>User: Affiche l'erreur (Pas de modif)
    end
```

#### 4. Garbage Collection (Nettoyage)

*Le nettoyage intelligent pour ne pas saturer le disque.*

Extrait de code

```
sequenceDiagram
    participant User as 👤 Toi
    participant Nh as ❄️ Nh
    participant Store as 📦 /nix/store
    participant Boot as 👢 Bootloader

    User->>Nh: nh clean all --keep 3
    Nh->>Boot: Liste les générations actives
    Boot-->>Nh: Gen 45, 46, 47 (Active)

    loop Pour chaque Gen < 45
        Nh->>Store: Marque pour suppression
    end

    Nh->>Store: nix-collect-garbage -d
    Store-->>User: "24.5 GB libérés"
```

#### 5. Rollback Système (Disaster Recovery)

*Le retour en arrière instantané.*

Extrait de code

```
sequenceDiagram
    participant User as 👤 Toi
    participant Nh as ❄️ Nh
    participant Profile as 🔗 /nix/var/nix/profiles/system

    User->>Nh: nh os switch --rollback
    Nh->>Profile: Bascule lien symbolique (Gen N -> N-1)
    Profile->>Profile: Activation script N-1

    Profile->>User: Restaure Kernel/Kexts
    Profile->>User: Restaure Binaires
    User-->>User: Le système est réparé
```

---

### 🟡 GROUPE 2 : COCKPIT & WIZARDS

#### 6. Ajout d'une App GUI (Mac Cask)

*L'insertion chirurgicale dans le code Nix.*

Extrait de code

```
sequenceDiagram
    participant User as 👤 Toi
    participant Script as 📜 add-app.sh
    participant File as 📄 apps.nix
    participant Nix as ❄️ Nix Engine

    User->>Script: Input "obsidian"
    Script->>File: Grep "obsidian" (Vérifie doublon)

    Script->>File: Sed (Insert "obsidian" before MARKER)
    Note over File: Ajoute la ligne dans homebrew.casks

    Script->>User: "Ajouté ! On applique ?"
    User->>Script: OUI
    Script->>Nix: nh os switch
    Nix->>User: Homebrew installe Obsidian.app
```

#### 7. Ajout d'un Package CLI (Commun)

*L'ajout d'un outil portable Linux/Mac.*

Extrait de code

```
sequenceDiagram
    participant User as 👤 Toi
    participant Script as 📜 add-app.sh
    participant File as 📄 packages.nix
    participant Git as 📦 Git

    User->>Script: Input "ripgrep"
    Script->>File: Sed (Insert "pkgs.ripgrep")

    Script->>Git: git diff modules/common/packages.nix
    Script-->>User: Affiche le diff

    Script->>User: Apply ?
    User->>Script: Confirm
    Script->>Nix: Switch...
```

#### 8. Création d'un Host (Templating)

*Comment on ajoute une nouvelle machine.*

Extrait de code

```
sequenceDiagram
    participant User as 👤 Toi
    participant Wizard as 🧙 add-host.sh
    participant Tpl as 📝 templates/
    participant Flake as 📄 flake.nix
    participant FS as 📂 FileSystem

    User->>Wizard: Nom: "dell-xps", Type: "NixOS"

    Wizard->>Tpl: Lit host-nixos.nix
    Wizard->>FS: mkdir hosts/perso/dell-xps
    Wizard->>FS: cp template -> hosts/perso/dell-xps/default.nix

    Wizard->>FS: Sed (Remplace %HOSTNAME% par "dell-xps")

    Wizard->>Flake: Sed (Injecte l'entrée dans nixosConfigurations)
    Wizard-->>User: "Machine créée ! Git add ?"
```

#### 9. Édition de Config (Fuzzy Find)

*Navigation rapide sans connaître l'arborescence.*

Extrait de code

```
sequenceDiagram
    participant User as 👤 Toi
    participant Edit as ✏️ edit.sh
    participant Fzf as 🔍 Gum Filter
    participant Editor as 📝 Neovim

    User->>Edit: Lance le script
    Edit->>Fzf: find . -name "*.nix"
    Fzf-->>User: Affiche liste interactive
    User->>Fzf: Tape "zsh" -> Selectionne "modules/common/shell.nix"

    Edit->>Editor: nvim modules/common/shell.nix
    User->>Editor: Modifie et Sauvegarde
    Editor->>Edit: Exit 0

    Edit->>User: "Appliquer maintenant ?"
```

#### 10. Désinstallation d'App

*Le nettoyage propre.*

Extrait de code

```
sequenceDiagram
    participant User as 👤 Toi
    participant Script as 🗑️ remove-app.sh
    participant File as 📄 apps.nix
    participant Gum as 🍬 Gum UI

    Script->>File: Grep (Extrait liste paquets installés)
    Script->>Gum: Affiche liste filtrable
    User->>Gum: Sélectionne "firefox"

    Script->>File: Sed (Supprime la ligne "firefox")
    Script->>User: "Ligne supprimée. Appliquer ?"

    User->>Script: OUI
    Script->>Nix: Switch (Nix désinstalle le binaire)
```

---

### 🔵 GROUPE 3 : CONFIGURATION & STOW

#### 11. Application Profil "Work"

*Le déploiement contextuel.*

Extrait de code

```
sequenceDiagram
    participant User as 👤 Toi
    participant Task as 📜 stow-apply.sh
    participant Stow as 🔗 GNU Stow
    participant FS as 🏠 $HOME

    User->>Task: mise run stow (Select: Work)

    Task->>Stow: stow -D common (Clean old)
    Task->>Stow: stow -R common (Refresh base)

    Task->>Stow: stow -R work
    Stow->>FS: Link stow/work/.ssh/config.d/work.conf -> ~/.ssh/...
    Stow->>FS: Link stow/work/.aws/ -> ~/.aws/

    Task-->>User: "Profil Work Actif"
```

#### 12. Application Profil "Personal"

*L'isolation des données.*

Extrait de code

```
sequenceDiagram
    participant User as 👤 Toi
    participant Task as 📜 stow-apply.sh
    participant Stow as 🔗 GNU Stow
    participant FS as 🏠 $HOME

    User->>Task: mise run stow (Select: Personal)

    Task->>Stow: stow -D work (Supprime liens Work)
    Note right of FS: ~/.aws/ n'existe plus

    Task->>Stow: stow -R personal
    Stow->>FS: Link stow/personal/.steam -> ~/.steam

    Task-->>User: "Profil Personal Actif"
```

#### 13. Live Editing (Comportement Stow)

*Pourquoi on n'a pas besoin de rebuild.*

Extrait de code

```
sequenceDiagram
    participant User as 👤 Toi
    participant Editor as 📝 Neovim
    participant Link as 🔗 Symlink (~/.zshrc)
    participant Real as 📄 Real File (stow/common/.zshrc)
    participant Shell as 🐚 Zsh

    User->>Editor: Edit ~/.zshrc
    Editor->>Link: Write bytes
    Link->>Real: Update content on disk

    User->>Shell: source ~/.zshrc
    Shell->>Real: Read new content
    Real-->>Shell: New aliases loaded
    Note over Shell: Instantané (0s)
```

---

### 🔴 GROUPE 4 : SECRETS & SÉCURITÉ (FNOX)

#### 14. Lecture d'un Secret (Shell Init)

*Comment les variables arrivent dans ton terminal.*

Extrait de code

```
sequenceDiagram
    participant Shell as 🐚 Zsh
    participant Fnox as 🛡️ Fnox
    participant Config as 📄 fnox.toml
    participant Keychain as 🔑 OS Keychain

    Shell->>Fnox: eval $(fnox activate)
    Fnox->>Config: Parse (STRIPE_KEY = keychain://stripe)

    Fnox->>Keychain: Get "fnox-stripe"
    Keychain-->>Fnox: "sk_live_12345" (Decrypted)

    Fnox-->>Shell: export STRIPE_KEY="sk_live_12345"
    Note over Shell: Variable en mémoire RAM uniquement
```

#### 15. Écriture d'un Secret (Mac)

*L'enrôlement sécurisé.*

Extrait de code

```
sequenceDiagram
    participant User as 👤 Toi
    participant Wizard as 🧙 secret.sh
    participant Fnox as 🛡️ Fnox
    participant Sec as 🍏 /usr/bin/security

    User->>Wizard: Key="GH_TOKEN", Val="ghp_..."
    Wizard->>Fnox: fnox set GH_TOKEN "ghp_..."

    Fnox->>Sec: add-generic-password -s "fnox-GH_TOKEN" -w "ghp_..."
    Sec-->>Fnox: OK

    Fnox->>User: "Secret stocké dans Keychain 'Login'"
```

#### 16. Écriture d'un Secret (Linux)

*Le fallback sur standards ouverts.*

Extrait de code

```
sequenceDiagram
    participant User as 👤 Toi
    participant Wizard as 🧙 secret.sh
    participant Tool as 🐧 secret-tool (libsecret)
    participant Keyring as 💍 Gnome Keyring

    User->>Wizard: Key="GH_TOKEN", Val="ghp_..."

    Wizard->>Tool: store --label="Fnox GH_TOKEN" service fnox key GH_TOKEN
    Tool->>Keyring: Write Encrypted
    Keyring-->>User: OK
```

#### 17. Authentification SSH (Hardware)

*Le flux Secretive.*

Extrait de code

```
sequenceDiagram
    participant Git as 📦 Git Push
    participant SSH as 🔒 SSH Client
    participant Socket as 🔌 Socket File
    participant Secretive as 📱 Secretive.app
    participant Enclave as 🛡️ Secure Enclave

    Git->>SSH: Connect git@github.com
    SSH->>Socket: Sign Challenge (KeyID)
    Socket->>Secretive: Request Sign

    Secretive->>User: Pop-up TouchID
    User->>Enclave: Fingerprint OK

    Enclave->>Secretive: Signed Data
    Secretive->>SSH: Signature
    SSH->>Git: Auth Success
```

---

### 🟣 GROUPE 5 : GIT & QUALITÉ (HK)

#### 18. Pre-commit Hook (Linting)

*L'exécution de `hk`.*

Extrait de code

```
sequenceDiagram
    participant User as 👤 Toi
    participant Git as 📦 Git
    participant Hk as 🦀 Hk (Binary)
    participant Pkl as 📄 hk.pkl
    participant Nixfmt as 🛠️ Nixfmt

    User->>Git: git commit
    Git->>Hk: .git/hooks/pre-commit
    Hk->>Pkl: Read Configuration

    par Parallel Checks
        Hk->>Nixfmt: Check *.nix files
        Hk->>Hk: Internal Check (Private Keys)
    end

    alt Error
        Nixfmt-->>Hk: Exit 1 (Bad Format)
        Hk-->>Git: Exit 1
        Git-->>User: "Commit Aborted. Run 'hk fix'"
    else Success
        Hk-->>Git: Exit 0
        Git->>Git: Create Commit
    end
```

#### 19. Détection Fuite Clé Privée

*Le filet de sécurité.*

Extrait de code

```
sequenceDiagram
    participant Hk as 🦀 Hk
    participant File as 📄 New File (staged)
    participant Regex as 🔍 Private Key Regex

    Hk->>File: Scan content
    File->>Regex: Match "-----BEGIN OPENSSH PRIVATE KEY-----"?

    alt Match Found
        Regex-->>Hk: TRUE
        Hk->>User: 🚨 CRITICAL: Private Key detected in 'secrets.txt'
        Hk->>Hk: Abort
    end
```

#### 20. Save Task (Git Push)

*Le "Save Game" rapide.*

Extrait de code

```
sequenceDiagram
    participant User as 👤 Toi
    participant Mise as 🔧 Mise Task
    participant Gum as 🍬 Gum Input
    participant Git as 📦 Git

    User->>Mise: mise run save
    Mise->>Git: git add .

    Mise->>Gum: Input "Commit Message?"
    User->>Gum: "update zsh aliases"

    Mise->>Git: git commit -m "update zsh aliases"
    Git->>Mise: Hook Hk (voir #18)

    Mise->>Git: git push
    Git-->>User: "☁️ Config sauvegardée"
```

---

### 🪟 GROUPE 6 : WINDOWS HYBRID

#### 21. Interopérabilité (Ouvrir Lien)

*Comment WSL parle à Windows.*

Extrait de code

```
sequenceDiagram
    participant User as 👤 Toi (WSL)
    participant Zsh as 🐚 Zsh
    participant WslView as 🐧 wslu/wslview
    participant WinHost as 🪟 Windows Host
    participant Chrome as 🌐 Chrome.exe

    User->>Zsh: open https://google.com
    Zsh->>WslView: Alias open -> wslview

    WslView->>WinHost: RPC Call (ShellExecute)
    WinHost->>Chrome: Launch URL
    Chrome-->>User: Affiche la page (sur Windows)
```

#### 22. Winget Install (Mise Native)

*Installation d'app graphique.*

Extrait de code

```
sequenceDiagram
    participant User as 👤 Toi
    participant Mise as 🔧 Mise.exe
    participant Config as 📄 windows.toml
    participant Winget as 📦 Winget.exe

    User->>Mise: mise install
    Mise->>Config: Parse [tools]
    Note right of Mise: Trouve "winget:Valve.Steam"

    Mise->>Winget: list (Check if installed)
    Winget-->>Mise: Not Found

    Mise->>Winget: install -e --id Valve.Steam
    Winget->>User: GUI Installer (Silent)
    Winget-->>Mise: Success
```

---

Ceci conclut **l'Annexe 3**.
Chaque flèche a un sens. Chaque interaction est supportée par les outils choisis (`hk`, `mise`, `fnox`, `nix`). L'architecture est verrouillée.

## 📏 Annexe D : Guide de Style & Conventions (Coding Standards)

*Objectif : Garantir que le code généré passe les linters (`hk`, `nixfmt`) et reste maintenable.*

### 1. Conventions de Nommage

| **Élément**       | **Convention** | **Exemple Correct**          | **Exemple Incorrect** |
| ----------------- | -------------- | ---------------------------- | --------------------- |
| **Fichiers Nix**  | `kebab-case`   | `hardware-configuration.nix` | `HardwareConfig.nix`  |
| **Variables Nix** | `camelCase`    | `myCustomPackage`            | `my_custom_package`   |
| **Attributs**     | `camelCase`    | `extraGroups`                | `extragroups`         |
| **Users/Hosts**   | `kebab-case`   | `macbook-pro`, `guest-user`  | `MacBookPro`, `Guest` |

### 2. Structure d'un Fichier Nix (Ordre Canonique)

L'IA doit toujours structurer ses modules dans cet ordre pour éviter la confusion :

1. **En-tête des arguments :** `{ pkgs, lib, config, inputs, ... }:`

2. **Bloc `let` (Optionnel) :** Définition des variables locales.

3. **Bloc `in` (Principal) :**
   
   - `imports = [ ... ];` (Toujours en premier).
   
   - `options = { ... };` (Si déclaration d'options).
   
   - `config = { ... };` (Si utilisation de `mkIf` ou `mkMerge`).
   
   - *Ou directement la configuration si pas de bloc `config`.*

### 3. Idiomes Nix Obligatoires

- **Utiliser `inherit` :** Au lieu de `foo = inputs.foo;`, écrire `inherit (inputs) foo;`.

- **Chemins Relatifs :** Toujours `./modules/foo` (relatif au fichier) ou `self + /modules/foo` (relatif à la racine Flake), **jamais** de chemins absolus `/home/nnosal/...`.

- **Pureté :** Interdiction d'utiliser `builtins.currentSystem` ou `import <nixpkgs>`. Toujours passer par les `inputs` du Flake.

---

## 📝 Annexe E : Bibliothèque de Templates (Squelettes)

*Objectif : Fournir des blocs "prêts à copier-coller" pour que l'IA ne réinvente pas la syntaxe.*

### 1. Squelette de Nouveau Module (`templates/module.nix`)

Nix

```
{ pkgs, lib, config, ... }:

with lib;

let
  cfg = config.modules.my-feature;
in
{
  options.modules.my-feature = {
    enable = mkEnableOption "Enable my-feature";
  };

  config = mkIf cfg.enable {
    # 1. Paquets
    home.packages = with pkgs; [ ];

    # 2. Configs
    programs.zsh.shellAliases = { };

    # 3. Variables d'env
    home.sessionVariables = { };
  };
}
```

### 2. Squelette de Nouveau Host (`templates/host-nixos.nix`)

Nix

```
{ pkgs, inputs, ... }: {
  imports = [
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    ../../modules/linux
    ../../modules/common
  ];

  networking.hostName = "%HOSTNAME%"; # À remplacer par le Wizard

  # Bootloader standard
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Import User Admin
  users.users.root.hashedPassword = "!"; # Désactivé (SSH Keys only)
  home-manager.users.nnosal = import ../../../users/nnosal/default.nix;

  system.stateVersion = "24.05";
}
```

### 3. Squelette de Script Wizard (`templates/wizard.sh`)

Bash

```
#!/usr/bin/env bash
set -e
source ./scripts/utils.sh

# 1. Collecte d'infos (Gum)
VAR=$(gum input --placeholder "Votre valeur")

# 2. Validation
if [ -z "$VAR" ]; then
    gum style --foreground 196 "Erreur : Valeur vide !"
    exit 1
fi

# 3. Action
echo "Traitement de $VAR..."
# ... logique métier ...

# 4. Feedback & Suite
gum confirm "Appliquer maintenant ?" && mise run switch
```

---

## 🚫 Annexe F : Les "Anti-Patterns" (Interdits Absolus)

*Objectif : Liste noire des erreurs courantes que font les IA sur Nix.*

### 🛑 1. Le "Impure State"

- **Ne jamais faire :** Utiliser des chemins `/home/user` dans la config Nix.

- **Pourquoi :** Ça casse sur un autre utilisateur (ex: `guest`) ou un autre OS.

- **Faire :** Utiliser `config.home.homeDirectory` ou `pkgs.writeScript`.

### 🛑 2. Le "Secret Leak"

- **Ne jamais faire :** `environment.variables.API_KEY = "sk-12345";`

- **Pourquoi :** Le secret finit dans `/nix/store` lisible par tout le monde en clair !

- **Faire :** Utiliser **Fnox** (`fnox.toml`) + injection dynamique dans le shell.

### 🛑 3. Le "Home-Manager Chaos"

- **Ne jamais faire :** Lancer `home-manager switch` directement.

- **Pourquoi :** Ça désynchronise l'état du système global et de l'utilisateur.

- **Faire :** Toujours passer par `nh os switch` (NixOS/Darwin) qui pilote Home-Manager en interne module.

### 🛑 4. Le "Stow Overwrite"

- **Ne jamais faire :** `stow .` (Stower la racine du repo).

- **Pourquoi :** Ça lie le `.git` et le `flake.nix` dans le home. Catastrophe.

- **Faire :** `stow --dir stow --target $HOME ...` (Cibler uniquement le dossier `stow/`).

---

## 🛠️ Annexe G : Guide de Dépannage (Troubleshooting)

*Objectif : Donner à l'IA la logique pour réparer ses propres erreurs.*

| **Symptôme / Erreur**                                  | **Cause Probable**                                    | **Solution à Appliquer**                                                                              |
| ------------------------------------------------------ | ----------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `error: infinite recursion encountered`                | Un module s'importe lui-même ou `imports` circulaire. | Vérifier les `imports = []` dans `default.nix`. Utiliser `lib.mkIf` pour casser les boucles.          |
| `error: hash mismatch in fixed-output derivation`      | Le SHA256 d'un paquet ou d'un `fetchUrl` a changé.    | Mettre le hash à `lib.fakeSha256` (ou zéros), lancer le build, copier le bon hash depuis l'erreur.    |
| `error: experimental Nix feature 'flakes' is disabled` | Nix n'est pas configuré pour les Flakes.              | Ajouter `--extra-experimental-features 'nix-command flakes'` à la commande ou dans `nix.conf`.        |
| `read-only file system` lors d'un `git pull`           | Permissions cassées sur le dossier `~/dotfiles`.      | `sudo chown -R $USER ~/dotfiles`.                                                                     |
| `stow: target ... is not owned by stow`                | Un fichier config existe déjà (conflit).              | Utiliser `stow --adopt` pour que Stow s'approprie le fichier existant (ou le supprimer manuellement). |
| `Fnox secret not found`                                | Le secret n'est pas dans le Keychain.                 | Lancer `cockpit` -> Secrets -> Ajouter la clé manquante.                                              |

---

### Résumé de l'Impact de ces Annexes

Avec ces 4 documents supplémentaires :

1. **Annexe D :** Le code généré sera propre et uniforme.

2. **Annexe E :** L'IA ne devinera pas la structure, elle remplira les trous.

3. **Annexe F :** Elle évitera les pièges de sécurité critiques (Secrets dans /nix/store).

4. **Annexe G :** Elle saura proposer des commandes de réparation (`--adopt`, `fakeSha256`).

C'est le "Kit de Survie" complet pour ton agent développeur.

## 🤖 Annexe H : Le "System Prompt" (Instructions Meta)

*Objectif : Copie-colle ce bloc en PREMIER dans la fenêtre de chat de l'IA Codeuse. Cela conditionne son "cerveau" pour respecter l'architecture.*

Plaintext

```
### ROLE
Tu es un Architecte Système Senior spécialisé en NixOS, macOS (Darwin) et DevOps. Tu possèdes une expertise approfondie de l'écosystème "Modern Nix" (Flakes, Home-Manager, Nix-Darwin).

### MISSION
Ta tâche est de générer le code d'une infrastructure dotfiles "Ultimate" en suivant STRICTEMENT le "Master Design Document" (MDD) fourni ci-après.

### CONTRAINTES CRITIQUES (DO NOT BREAK)
1.  **Zero-Trust :** Ne génère JAMAIS de secrets en clair ou chiffrés (SOPS/Age) dans le dépôt. Utilise uniquement le mapping Fnox (`keychain://`).
2.  **Pureté vs Pragmastisme :** Utilise Nix pour les paquets, mais GNU Stow pour les fichiers de config (~/.zshrc, ~/.config/nvim). Ne hardcode pas de chemins absolus (/home/user).
3.  **Cross-Platform :** Le code doit fonctionner sur Darwin (aarch64), NixOS (x86_64) et WSL sans modification manuelle. Utilise `lib.mkSystem` pour l'abstraction.
4.  **Style :** Respecte les conventions de nommage (kebab-case pour les fichiers, camelCase pour les variables).
5.  **Hooks :** Configure `hk` (Rust) via `hk.pkl` pour le linting. N'utilise pas `pre-commit` (Python).

### FORMAT DE SORTIE
Tu dois fournir le code fichier par fichier, en précisant le chemin complet (ex: `~/dotfiles/flake.nix`). Si un script nécessite d'être exécutable, précise la commande `chmod +x`.

### CONTEXTE
Je vais maintenant te fournir le Master Design Document (Parties 1-6 + Annexes). Analyse-le entièrement avant de générer la moindre ligne de code.
```

---

## 🔗 Annexe I : La "Liste des Courses" (Inputs Flake)

*Objectif : Fixer les versions pour éviter que l'IA ne mélange `nixos-23.11` et `unstable`.*

Pour garantir la stabilité, instruis l'IA d'utiliser **exactement** ces entrées dans le `flake.nix`.

| **Input**          | **URL Cible**                         | **Raison**                                                                           |
| ------------------ | ------------------------------------- | ------------------------------------------------------------------------------------ |
| **nixpkgs**        | `github:nixos/nixpkgs/nixos-unstable` | On veut les derniers paquets pour le Dev (Neovim, Go, Node).                         |
| **nix-darwin**     | `github:LnL7/nix-darwin`              | Gestionnaire macOS. `inputs.nixpkgs.follows = "nixpkgs"`.                            |
| **home-manager**   | `github:nix-community/home-manager`   | Gestionnaire User. `inputs.nixpkgs.follows = "nixpkgs"`.                             |
| **stylix**         | `github:danth/stylix`                 | Engine de thèmes (harmonisation couleurs).                                           |
| **nixos-hardware** | `github:NixOS/nixos-hardware/master`  | Optimisations Raspberry Pi / Apple Silicon.                                          |
| **hk**             | `github:jdx/hk`                       | (Optionnel si dispo dans nixpkgs, sinon via input) Pour récupérer le binaire latest. |
| **fnox**           | `github:jdx/fnox`                     | (Optionnel si dispo dans nixpkgs) Pour la gestion secrets.                           |

## 🧪 Annexe J (bonus) : Tests d'Intégration Automatisés (Virtualisation Mac avec Tart)

*Objectif : Vérifier que le bootstrap et la compilation Nix fonctionnent de bout en bout dans une VM macOS vierge avant de toucher à la machine physique.*

### 1. Pré-requis Techniques

- **Hôte :** Apple Silicon (M1/M2/M3).

- **Outil :** `tart` (installé sur l'hôte Admin).

- **Image Base :** Images officielles Cirrus Labs (déjà optimisées pour CI, sudo sans mot de passe).

**Ajout dans `hosts/pro/macbook-pro/default.nix` (Hôte Admin) :**

Nix

```
homebrew.casks = [ "tart" ];
```

### 2. Stratégie de Test "Ephémère"

Le script de test va réaliser le cycle suivant :

1. **Clone :** Récupère une image macOS Sonoma fraîche (`ghcr.io/cirruslabs/macos-sonoma-base`).

2. **Boot :** Démarre la VM en mode headless.

3. **Inject :** Lance le script de bootstrap (en mode non-interactif).

4. **Verify :** Vérifie que Zsh et Nix sont bien installés.

5. **Destroy :** Supprime la VM immédiatement après.

### 3. Le Script de Test Automatisé (`scripts/ci/test-darwin.sh`)

Ce script doit être généré par l'IA. Il gère l'attente du réseau (IP) et l'exécution SSH.

Bash

```
#!/usr/bin/env bash
set -e
source ./scripts/utils.sh

VM_NAME="test-dotfiles-$(date +%s)"
IMAGE="ghcr.io/cirruslabs/macos-sonoma-base:latest"

gum style --foreground 212 "🧪 Démarrage du test d'intégration macOS (Tart)..."

# 1. Création de la VM
echo "📦 Clonage de l'image $IMAGE..."
tart clone "$IMAGE" "$VM_NAME"

# Fonction de nettoyage (trap) pour toujours supprimer la VM à la fin
cleanup() {
    echo "🧹 Nettoyage de la VM..."
    tart stop "$VM_NAME" || true
    tart delete "$VM_NAME" || true
}
trap cleanup EXIT

# 2. Démarrage
echo "🚀 Boot de la VM..."
tart run "$VM_NAME" --no-graphics &
PID=$!

# 3. Attente de l'IP (Polling)
echo "⏳ Attente de la connectivité réseau..."
IP=""
for i in {1..30}; do
    IP=$(tart ip "$VM_NAME" 2>/dev/null || true)
    if [ -n "$IP" ]; then break; fi
    sleep 2
done

if [ -z "$IP" ]; then
    echo "❌ Impossible de récupérer l'IP de la VM."
    exit 1
fi

echo "✅ VM en ligne sur $IP. Attente du service SSH..."
# On attend que le port 22 soit ouvert
while ! nc -z "$IP" 22; do sleep 1; done

# 4. Exécution du Bootstrap (Mode CI)
# Note : Les images Cirrus ont user=admin, pass=admin
echo "🛠️  Lancement du Bootstrap..."

# On injecte une variable d'env CI=true pour que le bootstrap
# passe en mode non-interactif (voir section Modifications requises)
sshpass -p "admin" ssh -o StrictHostKeyChecking=no admin@"$IP" \
    "export CI=true && export MACHINE_CONTEXT=work && sh <(curl -L https://dotfiles.nnosal.com)"

# 5. Vérification
echo "🔍 Vérification de l'installation..."
sshpass -p "admin" ssh -o StrictHostKeyChecking=no admin@"$IP" \
    "command -v nix && command -v zsh && [ -f ~/.zshrc ]"

gum style --foreground 46 "✅ TEST RÉUSSI : La configuration s'installe et boot correctement !"
```

### 4. Modifications Requises sur le Bootstrap

Pour que ce test fonctionne, le script `bootstrap.sh` doit accepter un mode silencieux.

**Dans `bootstrap.sh` (à instruire à l'IA) :**

Bash

```
# ...
if [ "$CI" = "true" ]; then
    # Mode Automatique pour Tart/CI
    TARGET="$HOME/dotfiles"
    git clone "https://github.com/nnosal/dotfiles.git" "$TARGET"
    cd "$TARGET"
    # On force l'installation sans interaction Gum
    ./scripts/cockpit.sh --apply-only --profile "$MACHINE_CONTEXT"
else
    # Mode Interactif (Gum) normal...
fi
# ...
```

### 5. Intégration dans Mise

Ajoute cette tâche dans `mise.toml` pour lancer le test facilement.

Ini, TOML

```
[tasks.test-mac]
description = "🧪 Lance une VM Tart et teste l'installation complète"
depends = ["install"] # Besoin de sshpass éventuellement
run = "./scripts/ci/test-darwin.sh"
```

---

### Pourquoi cette Annexe J est cruciale ?

Avec cette annexe, tu boucles la boucle de la **qualité logicielle** :

1. **Hk :** Vérifie la syntaxe (Linting).

2. **Tart :** Vérifie l'installation réelle (Integration).

3. **GitHub Actions :** Vérifie la compilation cloud (CI).
