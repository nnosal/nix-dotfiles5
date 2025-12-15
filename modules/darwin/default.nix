# modules/darwin/default.nix
# Module spécifique macOS (nix-darwin)

{ pkgs, lib, config, ... }:

{
  imports = [
    ./security.nix
    ./apps.nix
  ];

  # Paramètres système macOS
  system = {
    # Version de compatibilité Darwin
    stateVersion = 5;
    
    # Paramètres Finder
    defaults = {
      finder = {
        AppleShowAllExtensions = true;
        ShowPathbar = true;
        ShowStatusBar = true;
        FXEnableExtensionChangeWarning = false;
        _FXShowPosixPathInTitle = true;
        FXPreferredViewStyle = "Nlsv"; # Liste
      };
      
      # Paramètres Dock
      dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.5;
        show-recents = false;
        tilesize = 48;
        orientation = "bottom";
        minimize-to-application = true;
        # persistent-apps = []; # Géré manuellement
      };
      
      # Paramètres globaux
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        AppleInterfaceStyle = "Dark";
        AppleKeyboardUIMode = 3; # Full keyboard access
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
        NSDocumentSaveNewDocumentsToCloud = false;
      };
      
      # Trackpad
      trackpad = {
        Clicking = true;
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = true;
      };
    };
    
    # Activation des changements
    activationScripts.postUserActivation.text = ''
      # Appliquer les changements Finder sans redémarrer
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';
  };

  # Services
  services = {
    # Nix Daemon
    nix-daemon.enable = true;
  };

  # Homebrew (pour les apps qui ne sont pas dans nixpkgs)
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap"; # Supprime les apps non déclarées
      upgrade = true;
    };
    global = {
      brewfile = true;
    };
  };
}
