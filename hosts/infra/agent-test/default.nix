# hosts/infra/agent-test/default.nix
# Configuration de test pour les Agents AI
# Machine Linux x86_64 pour validation automatique

{ pkgs, inputs, lib, ... }:

{
  imports = [
    ../../../modules/common
    ../../../modules/linux
  ];

  # 1. Configuration
  networking.hostName = "agent-test";
  
  # Firewall minimal pour les tests
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # 2. Services minimaux
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes"; # Pour les tests automatisés
      PasswordAuthentication = true; # Pour les tests
    };
  };

  # 3. Utilisateur de test pour les agents AI
  users.users.agent = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "agent-test-123"; # Mot de passe de test
    description = "Agent AI Test User";
  };

  # Utilisateur root pour tests
  users.users.root.initialPassword = "root-test-123";

  # 4. Home Manager pour l'agent
  home-manager.users.agent = {
    imports = [ ../../../users/guest/default.nix ];
    
    home.sessionVariables = {
      MACHINE_CONTEXT = "test";
      MACHINE_NAME = "agent-test";
      CI = "true";
    };
  };

  # 5. Paquets de test
  environment.systemPackages = with pkgs; [
    # Outils de test
    curl
    jq
    yq
    
    # Pour validation du bootstrap
    git
    gum
  ];

  # 6. Configuration spéciale pour CI/CD
  # Permettre les opérations sans interaction
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "24.05";
}
