# lib/mkHome.nix
# Factory pour créer une config Home-Manager standalone
# Utile pour WSL ou les systèmes non-NixOS

{ inputs }:

{ system, modules, ... }:

let
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };
in
inputs.home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  extraSpecialArgs = { inherit inputs; };
  modules = [
    inputs.stylix.homeManagerModules.stylix
  ] ++ modules;
}
