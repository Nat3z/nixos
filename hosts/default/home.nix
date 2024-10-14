{ config, pkgs, flakeName, ... }:

let
  gitCredentials = import ../../credentials/git.nix;
in {

  imports = [
    ../../modules/home-manager/rebuild.nix
    ../../modules/home-manager/alacritty.nix
    ../../modules/home-manager/discord.nix
    ../../modules/home-manager/minecraft.nix
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

  home.packages = with pkgs; [
    jetbrains.idea-ultimate
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  fonts.fontconfig.enable = true;

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];

    };
    initExtra = ''
      export NIX_LD=$(nix eval --impure --raw --expr 'let pkgs = import <nixpkgs> {}; NIX_LD = pkgs.lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker"; in NIX_LD')
    '';
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

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

}
