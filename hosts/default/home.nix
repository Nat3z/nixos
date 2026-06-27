{ config, pkgs, flakeName, lib, username, ... }@inputs:

let
  gitCredentials = import ../../credentials/git.nix;
  opengameinstaller = import ../../modules/nixos/apps/opengameinstaller.nix { inherit lib pkgs; };
in {

  imports = [
    ../../modules/home-manager/rebuild.nix
    ../../modules/home-manager/alacritty.nix
    ../../modules/home-manager/discord.nix
    ../../modules/home-manager/minecraft.nix
    ../../modules/home-manager/jetbrains-idea.nix
    ../../modules/home-manager/tmux.nix
    ../../modules/home-manager/kitty.nix
    ../../modules/home-manager/fuzzy-in.nix
   ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "${username}";
  home.homeDirectory = "/home/${username}";

  home.stateVersion = "24.05"; # Please read the comment before changing.

  # Extra Packages
  home.packages = [
    opengameinstaller 
    pkgs.steamtinkerlaunch
  ];
  
  # set source to be the dotfiles directory/the flake's name
  home.file.".config" = {
    source = ../../dotfiles/${flakeName};
    recursive = true;
  };


  programs.git = with gitCredentials; {
    enable = true;
    settings.user = {
      name = name;
      email = email;
    };
  };
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

}
