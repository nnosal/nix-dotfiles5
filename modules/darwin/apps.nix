# modules/darwin/apps.nix
# Applications GUI macOS via Homebrew Casks

{ pkgs, lib, config, ... }:

{
  homebrew.casks = [
    # 💻 Développement
    "visual-studio-code"
    "orbstack"          # Docker alternative légère
    "iterm2"
    "ghostty"           # Terminal moderne
    
    # 🌐 Navigateurs
    "arc"
    "firefox"
    
    # 💬 Communication
    "slack"
    "discord"
    "zoom"
    
    # 🎨 Productivité
    "raycast"           # Spotlight on steroids
    "obsidian"          # Notes
    "notion"
    
    # 🎥 Média
    "vlc"
    "spotify"
    
    # 🛠️ Utilitaires
    "1password"         # Gestionnaire de mots de passe
    "rectangle"         # Window management
    "stats"             # Monitoring système
    "the-unarchiver"
    
    # %% CASKS %%
    # ↑ Ne pas supprimer ce marqueur - utilisé par le Wizard add-app.sh
  ];

  # Taps Homebrew supplémentaires
  homebrew.taps = [
    "homebrew/bundle"
  ];

  # Formules Homebrew (CLI tools pas dans nixpkgs ou plus récents)
  homebrew.brews = [
    "mas" # Mac App Store CLI
  ];

  # Apps du Mac App Store (via mas)
  homebrew.masApps = {
    # "Xcode" = 497799835;
    # Ajouter ici les apps du Mac App Store
  };
}
