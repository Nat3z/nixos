{ pkgs, ... }:
{
  services.gvfs.enable = true; # for thunar
  environment.systemPackages = with pkgs; [
    xfce.thunar
  ];
}