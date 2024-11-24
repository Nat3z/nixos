{ config, pkgs, flakeName, builtins, ... }:

let
  gitCredentials = import ../../credentials/git.nix;
in {

  imports = [
    ../../modules/home-manager/rebuild.nix
    ../../modules/home-manager/alacritty.nix
    ../../modules/home-manager/discord.nix
    ../../modules/home-manager/minecraft.nix
    ../../modules/home-manager/jetbrains-idea.nix
    ../../modules/home-manager/tmux.nix
    ../../modules/home-manager/zsh.nix
    ../../modules/home-manager/kitty.nix
   ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "nat";
  home.homeDirectory = "/home/nat";

  home.stateVersion = "24.05"; # Please read the comment before changing.

  # set source to be the dotfiles directory/the flake's name
  home.file.".config" = {
    source = ../../dotfiles/${flakeName};
    recursive = true;
  };

  programs.oh-my-posh = {
    enable = true;
    enableZshIntegration = true;
    useTheme = "catppuccin_mocha";
  };

  programs.git = with gitCredentials; {
    enable = true;
    userName = name;
    userEmail = email;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

}
