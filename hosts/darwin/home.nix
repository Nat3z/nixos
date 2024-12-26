{ config, pkgs, flakeName, lib, system, ... }@inputs:
{
  imports = [
    ../../modules/home-manager/rebuild.nix
    ../../modules/home-manager/tmux.nix
    ../../modules/home-manager/zsh.nix
    ../../modules/home-manager/fuzzy-in.nix
    ../../modules/home-manager/kitty.nix
  ];

  programs.oh-my-posh = {
    enable = true;
    enableZshIntegration = true;
    useTheme = "catppuccin_mocha";
  };
  programs.zsh.initExtra = ''
    eval "$(/opt/homebrew/bin/brew shellenv)"
    export PATH="/opt/homebrew/opt/node@22/bin:/Applications/Ghostty.app/Contents/MacOS:$PATH"
  '';

  home.packages = with pkgs; [
    fzf
  ];

  programs.lazygit.enable = true;
  programs.home-manager.enable = true;
  home.stateVersion = "25.05"; 
}
