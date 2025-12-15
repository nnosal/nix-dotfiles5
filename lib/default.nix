# lib/default.nix
# Point d'entrée de la librairie custom
# Charge mkSystem et mkHome et les expose

{ inputs }:

{
  mkSystem = import ./mkSystem.nix { inherit inputs; };
  mkHome = import ./mkHome.nix { inherit inputs; };
}
