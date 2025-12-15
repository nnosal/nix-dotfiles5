# modules/common/style.nix
# Configuration Stylix pour l'harmonisation des couleurs

{ pkgs, lib, config, inputs, ... }:

{
  # Stylix - Thème global
  stylix = {
    enable = true;
    
    # Thème de base (Catppuccin Mocha)
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    
    # Polices
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      serif = {
        package = pkgs.noto-fonts;
        name = "Noto Serif";
      };
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        terminal = 14;
        applications = 12;
        desktop = 12;
        popups = 12;
      };
    };

    # Curseur
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };

    # Opacité pour les terminaux
    opacity = {
      terminal = 0.95;
      applications = 1.0;
      desktop = 1.0;
      popups = 0.95;
    };
  };
}
