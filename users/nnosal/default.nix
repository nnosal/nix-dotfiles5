# users/nnosal/default.nix
# Profil utilisateur principal - Nicolas Nosal (Admin/Dev)

{ pkgs, lib, config, ... }:

{
  # Identité Git
  programs.git = {
    enable = true;
    userName = "Nicolas Nosal";
    userEmail = "nicolas.nosal@gmail.com";
    
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      
      # Signature avec clé SSH (pas GPG)
      gpg.format = "ssh";
      commit.gpgsign = false; # Activer si clé configurée
      # user.signingkey = "ssh-ed25519 AAAAC3..."; # Clé Secretive
      
      # Delta pour les diffs
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate = true;
        light = false;
        side-by-side = true;
        line-numbers = true;
      };
      
      # Merge
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
      
      # Aliases Git
      alias = {
        co = "checkout";
        br = "branch";
        ci = "commit";
        st = "status";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        visual = "!gitk";
        lg = "log --oneline --graph --decorate";
        lga = "log --oneline --graph --decorate --all";
      };
    };
    
    # Ignorer globalement
    ignores = [
      ".DS_Store"
      "*.swp"
      "*.swo"
      ".idea/"
      ".vscode/"
      "node_modules/"
      "__pycache__/"
      ".env.local"
      "*.log"
    ];
  };

  # Paquets CLI portables (Marche sur Mac et Linux !)
  home.packages = with pkgs; [
    # Outils modernes
    bat       # Cat sous stéroïdes
    eza       # Ls sous stéroïdes
    fzf       # Fuzzy finder
    ripgrep   # Grep ultra rapide
    fd        # Find moderne
    zoxide    # cd intelligent
    delta     # Diff viewer
    
    # Git
    lazygit   # Git TUI
    gh        # GitHub CLI
    
    # DevOps
    # k9s       # Kubernetes UI
    # kubectl
    
    # Nix
    nh        # Nix Helper (Clean & Switch)
    
    # JSON/YAML
    jq
    yq
    
    # Monitoring
    htop
    btop
  ];

  # SSH (utilise Secretive sur Mac)
  programs.ssh = {
    enable = true;
    # La config SSH principale est gérée par Stow
    # stow/common/.ssh/config
  };

  # Neovim (config gérée par Stow)
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Variables de session
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    PAGER = "less -R";
  };

  home.stateVersion = "24.05";
}
