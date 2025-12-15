# modules/wsl/default.nix
# Module d'intégration WSL (Windows Subsystem for Linux)
# C'est le "pont" qui rend l'expérience transparente entre WSL et Windows

{ pkgs, lib, config, ... }:

{
  # 1. Utilitaires WSL (wslview, wslact, etc.)
  home.packages = with pkgs; [
    wslu
    xdg-utils
  ];

  # 2. Variables d'environnement critiques
  home.sessionVariables = {
    # Ouvre les liens (xdg-open) avec le navigateur par défaut de Windows
    BROWSER = "wslview";
    # Utilise l'affichage XServer (si installé sur Windows, optionnel)
    DISPLAY = ":0";
    # Pas de GUI par défaut dans WSL
    TERM = "xterm-256color";
  };

  # 3. Alias pratiques
  programs.zsh.shellAliases = {
    # Ouvre l'explorateur Windows dans le dossier courant
    explorer = "explorer.exe .";
    # Copie dans le presse-papier Windows (via clip.exe)
    clip = "clip.exe";
    # Ouvre un fichier avec l'app Windows par défaut
    open = "wslview";
    # PowerShell depuis WSL
    pwsh = "powershell.exe";
    # Accès rapide au dossier Windows home
    cdwin = "cd /mnt/c/Users/$USER";
  };

  # 4. Configuration Git pour WSL
  programs.git.extraConfig = {
    # Utilise le credential helper de Windows pour l'auth HTTPS
    credential.helper = "/mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe";
  };

  # 5. Intégration SSH (utilise l'agent Windows si disponible)
  programs.zsh.initExtra = ''
    # Détecter si on peut utiliser l'agent SSH de Windows
    # Sinon utiliser l'agent Linux standard
    if [[ -n "$WSL_DISTRO_NAME" ]]; then
      # On est dans WSL
      export WSL_INTEROP_ENABLED=1
    fi
  '';
}
