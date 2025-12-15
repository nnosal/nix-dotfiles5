# modules/common/shell.nix
# Configure Zsh et assure que Fnox/Secretive sont chargés

{ pkgs, lib, config, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;

    # 🛡️ Injection des Secrets (Fnox) & SSH
    initExtra = ''
      # 1. Activer Fnox (Secrets en ENV)
      # On ne lance Fnox que si on est dans une session interactive
      # pour ne pas ralentir les scripts non-interactifs
      if [[ -o interactive ]] && command -v fnox &> /dev/null; then
        # "activate" génère les commandes 'export VAR=...'
        # Les secrets transitent par un pipe sécurisé, jamais écrits sur disque
        eval "$(fnox activate zsh)"
      fi

      # 2. Lier le Socket SSH (Secretive ou Agent)
      if [[ -S "$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh" ]]; then
        # Mac Secure Enclave (Secretive)
        export SSH_AUTH_SOCK="$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"
      elif [[ -S "$XDG_RUNTIME_DIR/ssh-agent.socket" ]]; then
        # Linux Standard Agent
        export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
      fi

      # 3. Charger les Alias Stow
      # Si stow/common est lié, ceci chargera les fichiers
      [ -f ~/.config/zsh/aliases.zsh ] && source ~/.config/zsh/aliases.zsh
      [ -f ~/.config/zsh/functions.zsh ] && source ~/.config/zsh/functions.zsh

      # 4. Variables d'environnement
      export EDITOR="nvim"
      export VISUAL="nvim"
      export PAGER="less -R"
    '';
  };

  # Starship Prompt
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
}
