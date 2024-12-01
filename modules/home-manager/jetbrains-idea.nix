{ pkgs, ... }:
{
  home.packages = with pkgs; [
    jetbrains.idea-ultimate
    nerd-fonts.jetbrains-mono
  ];
  fonts.fontconfig.enable = true;

}
