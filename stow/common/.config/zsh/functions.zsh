# ~/.config/zsh/functions.zsh
# Fonctions Zsh custom

# ============================================
# UTILITAIRES
# ============================================

# Créer un dossier et y entrer
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extraire n'importe quelle archive
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)   tar xjf "$1"     ;;
      *.tar.gz)    tar xzf "$1"     ;;
      *.tar.xz)    tar xJf "$1"     ;;
      *.bz2)       bunzip2 "$1"     ;;
      *.rar)       unrar x "$1"     ;;
      *.gz)        gunzip "$1"      ;;
      *.tar)       tar xf "$1"      ;;
      *.tbz2)      tar xjf "$1"     ;;
      *.tgz)       tar xzf "$1"     ;;
      *.zip)       unzip "$1"       ;;
      *.Z)         uncompress "$1"  ;;
      *.7z)        7z x "$1"        ;;
      *)           echo "'$1' ne peut pas être extrait" ;;
    esac
  else
    echo "'$1' n'est pas un fichier valide"
  fi
}

# Trouver un fichier par nom
ff() {
  find . -type f -name "*$1*"
}

# Trouver un dossier par nom
fdir() {
  find . -type d -name "*$1*"
}

# Recherche dans les fichiers avec aperçu fzf
fg() {
  rg --color=always --line-number --no-heading --smart-case "$@" | \
    fzf --ansi --preview 'bat --color=always --highlight-line {2} {1}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3'
}

# ============================================
# GIT
# ============================================

# Clone et cd dans le repo
gclone() {
  git clone "$1" && cd "$(basename "$1" .git)"
}

# Créer une branche et switch dessus
gcb() {
  git checkout -b "$1"
}

# Commit tout avec message
gcam() {
  git add --all && git commit -m "$1"
}

# Push avec upstream tracking
gpush() {
  git push -u origin "$(git branch --show-current)"
}

# ============================================
# DOCKER
# ============================================

# Shell dans un container
dsh() {
  docker exec -it "$1" /bin/sh
}

# Bash dans un container
dbash() {
  docker exec -it "$1" /bin/bash
}

# Logs en temps réel
dlogs() {
  docker logs -f "$1"
}

# ============================================
# NIX
# ============================================

# Shell temporaire avec un paquet
nsh() {
  nix shell "nixpkgs#$1"
}

# Run un paquet sans l'installer
nrun() {
  nix run "nixpkgs#$1"
}

# Chercher un paquet
nfind() {
  nix search nixpkgs "$1"
}

# ============================================
# MACOS SPÉCIFIQUE
# ============================================

if [[ "$OSTYPE" == "darwin"* ]]; then
  # Flush DNS cache
  flushdns() {
    sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder
    echo "✅ DNS cache flushed"
  }
  
  # Ouvrir Finder dans le dossier courant
  o() {
    open "${1:-.}"
  }
  
  # Copier le chemin courant
  cpwd() {
    pwd | tr -d '\n' | pbcopy
    echo "✅ Chemin copié dans le presse-papier"
  }
fi

# ============================================
# AIDE MÉMOIRE
# ============================================

# Aide rapide sur les alias
help-aliases() {
  echo "\n📄 Alias disponibles:"
  echo "====================================="
  alias | grep "^alias" | sed 's/alias //' | column -t -s '='
}

# Cheatsheet des commandes courantes
cheat() {
  echo "\n📖 Cheatsheet Ultimate Dotfiles"
  echo "====================================="
  echo "cockpit       - Menu principal TUI"
  echo "nrs           - Nix rebuild switch"
  echo "ngc           - Nix garbage collect"
  echo "reload        - Recharger .zshrc"
  echo "lg            - LazyGit"
  echo "k9            - K9s (Kubernetes)"
  echo "====================================="
}
