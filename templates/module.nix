# templates/module.nix
# Template pour un nouveau module Nix
# Variables à remplacer: %MODULE_NAME%

{ pkgs, lib, config, ... }:

with lib;

let
  cfg = config.modules.%MODULE_NAME%;
in
{
  options.modules.%MODULE_NAME% = {
    enable = mkEnableOption "Enable %MODULE_NAME%";
  };

  config = mkIf cfg.enable {
    # 1. Paquets
    home.packages = with pkgs; [
      # Ajouter les paquets ici
    ];

    # 2. Configs programmes
    # programs.foo = { };

    # 3. Variables d'environnement
    home.sessionVariables = {
      # VAR = "value";
    };

    # 4. Aliases shell
    # programs.zsh.shellAliases = { };
  };
}
