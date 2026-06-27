{ pkgs, ... }:
{
  home.packages = with pkgs; [
    jetbrains.idea
  ];

  fonts.fontconfig.enable = true;

}
