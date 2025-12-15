# ~/.config/zsh/aliases.zsh
# Alias Zsh - Modifiables sans rebuild Nix

# ============================================
# NAVIGATION
# ============================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

# ============================================
# LS MODERNE (eza)
# ============================================
if command -v eza &> /dev/null; then
  alias ls='eza --icons'
  alias ll='eza -la --icons --git'
  alias la='eza -a --icons'
  alias lt='eza -T --icons --level=2'
  alias llt='eza -laT --icons --level=2 --git'
else
  alias ll='ls -la'
  alias la='ls -a'
fi

# ============================================
# CAT MODERNE (bat)
# ============================================
if command -v bat &> /dev/null; then
  alias cat='bat --paging=never'
  alias catp='bat --plain'
fi

# ============================================
# GIT
# ============================================
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gco='git checkout'
alias gb='git branch'
alias gp='git push'
alias gpl='git pull'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph --decorate'
alias gla='git log --oneline --graph --decorate --all'
alias glp='git log --pretty=format:"%C(yellow)%h%Creset %s %C(red)(%an)%Creset"'

# LazyGit
if command -v lazygit &> /dev/null; then
  alias lg='lazygit'
fi

# ============================================
# EDITEUR
# ============================================
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias e='$EDITOR'

# ============================================
# RECHERCHE
# ============================================
alias rg='rg --smart-case'
alias fd='fd --hidden'
alias grep='grep --color=auto'

# ============================================
# SYSTEME
# ============================================
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps aux'
alias top='htop'

# ============================================
# NIX & DOTFILES
# ============================================
alias nrs='nh os switch .'
alias nrb='nh os boot .'
alias nfu='nix flake update'
alias nfc='nix flake check'
alias ngc='nh clean all --keep 3'

# Cockpit
alias cockpit='mise run ui'
alias c='mise run ui'

# ============================================
# DOCKER / ORBSTACK
# ============================================
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias drm='docker rm'
alias drmi='docker rmi'
alias dprune='docker system prune -af'

# ============================================
# KUBERNETES
# ============================================
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kga='kubectl get all'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias kx='kubectl exec -it'

# K9s
if command -v k9s &> /dev/null; then
  alias k9='k9s'
fi

# ============================================
# DIVERS
# ============================================
alias cls='clear'
alias c='clear'
alias h='history'
alias j='jobs -l'
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%Y-%m-%d %H:%M:%S"'
alias week='date +%V'

# Reload shell
alias reload='source ~/.zshrc'
alias rl='source ~/.zshrc'

# Edit configs rapidement
alias zshrc='$EDITOR ~/.zshrc'
alias vimrc='$EDITOR ~/.config/nvim/init.lua'
alias aliases='$EDITOR ~/.config/zsh/aliases.zsh'
