{
  config,
  pkgs,
  flakeName,
  lib,
  system,
  inputs,
  ...
}@extra:
{
  imports = [
    ../../modules/home-manager/rebuild.nix
    ../../modules/home-manager/tmux.nix
    ../../modules/home-manager/fuzzy-in.nix
    ../../modules/home-manager/screenshot-keeper.nix
    inputs.zen-browser.homeModules.beta
  ];

  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    extraConfig = ''
      Host ucla
        HostName lnxsrv.seas.ucla.edu
        Port 22
        User natronq
        IdentityFile ~/.ssh/id_ed25519
        ForwardAgent yes
    '';
  };

  # programs.zen-browser = {
  #   enable = true;
  # };

  programs.home-manager.enable = true;
  home.stateVersion = "25.05";
}
