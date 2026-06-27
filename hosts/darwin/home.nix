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

  programs.zen-browser = {
    enable = true;
  };
  programs.home-manager.enable = true;
  home.stateVersion = "25.05";
}
