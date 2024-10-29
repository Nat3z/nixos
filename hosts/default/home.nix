{ config, pkgs, flakeName, ... }:

let
  gitCredentials = import ../../credentials/git.nix;
in {

  imports = [
    ../../modules/home-manager/rebuild.nix
    ../../modules/home-manager/alacritty.nix
    ../../modules/home-manager/discord.nix
    ../../modules/home-manager/minecraft.nix
    ../../modules/home-manager/jetbrains-idea.nix
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

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };
  };

  programs.git = with gitCredentials; {
    enable = true;
    userName = name;
    userEmail = email;
  };

  programs.kitty = {
    enable = true;
    settings = {
      confirm_os_window_close = 0;
    };
  };
  home.file.".config/hypr/kwallet.conf".text = ''
    exec-once = ${pkgs.kwallet-pam}/libexec/pam_kwallet_init 
  '';
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

}
