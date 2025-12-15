# modules/darwin/security.nix
# Sécurité macOS : TouchID pour sudo, Secretive pour SSH

{ pkgs, lib, config, ... }:

{
  # Permet d'utiliser TouchID pour la commande `sudo` dans le terminal
  security.pam.enableSudoTouchIdAuth = true;

  # Secretive pour les clés SSH stockées dans Secure Enclave
  homebrew.casks = [
    "secretive"
  ];

  # Configuration SSH pour utiliser Secretive
  # Note: La config SSH est gérée via Stow dans stow/common/.ssh/config
}
