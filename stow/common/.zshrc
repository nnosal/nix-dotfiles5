# ~/.zshrc
# Fichier principal Zsh - Géré par GNU Stow
# Permet l'édition directe sans rebuild Nix

# ============================================
# ENVIRONMENT
# ============================================
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less -R"
export LANG="fr_FR.UTF-8"
export LC_ALL="fr_FR.UTF-8"

# XDG Base Directories
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# ============================================
# PATH
# ============================================
# Ajouter les binaires locaux
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

# ============================================
# HISTORY
# ============================================
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=50000
setopt EXTENDED_HISTORY       # Timestamps dans l'historique
setopt HIST_EXPIRE_DUPS_FIRST # Expire les doublons d'abord
setopt HIST_IGNORE_DUPS       # Ignore les doublons consécutifs
setopt HIST_IGNORE_SPACE      # Ignore les commandes qui commencent par espace
setopt HIST_VERIFY            # Vérifie avant exécution depuis historique
setopt SHARE_HISTORY          # Partage l'historique entre sessions

# ============================================
# OPTIONS ZSH
# ============================================
setopt AUTO_CD                # cd sans taper cd
setopt AUTO_PUSHD             # pushd automatique
setopt PUSHD_IGNORE_DUPS      # Pas de doublons dans la pile
setopt CORRECT                # Correction orthographique
setopt INTERACTIVE_COMMENTS   # Commentaires en mode interactif

# ============================================
# COMPLETION
# ============================================
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors '${(s.:.)LS_COLORS}'

# ============================================
# KEY BINDINGS
# ============================================
bindkey -e                    # Mode Emacs
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char

# ============================================
# INTEGRATIONS
# ============================================

# Fnox (Secrets injection) - Géré aussi par Nix mais safe to have ici
if command -v fnox &> /dev/null; then
  eval "$(fnox activate zsh)"
fi

# Starship prompt
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi

# Zoxide (cd intelligent)
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

# Mise (runtime manager)
if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
fi

# fzf
if command -v fzf &> /dev/null; then
  source <(fzf --zsh)
fi

# ============================================
# SSH AGENT (Secretive ou standard)
# ============================================
if [[ -S "$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh" ]]; then
  # Mac Secure Enclave (Secretive)
  export SSH_AUTH_SOCK="$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"
elif [[ -S "$XDG_RUNTIME_DIR/ssh-agent.socket" ]]; then
  # Linux Standard Agent
  export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
fi

# ============================================
# LOAD MODULAR CONFIGS
# ============================================
# Charge les fichiers supplémentaires depuis ~/.config/zsh/
for file in ~/.config/zsh/*.zsh(N); do
  source "$file"
done
