# templates/user-profile.nix
# Template pour un nouveau profil utilisateur
# Variables à remplacer: %USER%, %FULLNAME%, %EMAIL%

{ pkgs, lib, config, ... }:

{
  # Identité Git
  programs.git = {
    enable = true;
    userName = "%FULLNAME%";
    userEmail = "%EMAIL%";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  # Paquets CLI
  home.packages = with pkgs; [
    bat
    eza
    fzf
    ripgrep
    fd
    lazygit
    # %% PACKAGES %%
  ];

  # SSH
  programs.ssh.enable = true;

  # Neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  home.stateVersion = "24.05";
}
