# templates/host-darwin.nix
# Template pour un nouveau Host macOS
# Variables à remplacer: %HOSTNAME%, %CONTEXT%, %USER%

{ pkgs, inputs, ... }:

{
  imports = [
    ../../../modules/common
    ../../../modules/darwin
  ];

  # Configuration système
  networking.hostName = "%HOSTNAME%";

  # Apps spécifiques à cette machine
  homebrew.casks = [
    # Ajouter vos apps ici
    # %% CASKS %%
  ];

  # Utilisateur principal
  users.users.%USER% = {
    name = "%USER%";
    home = "/Users/%USER%";
  };

  # Home Manager
  home-manager.users.%USER% = {
    imports = [ ../../../users/%USER%/default.nix ];

    home.sessionVariables = {
      MACHINE_CONTEXT = "%CONTEXT%";
      MACHINE_NAME = "%HOSTNAME%";
    };
  };
}
