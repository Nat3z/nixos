{ pkgs, ... }:
{
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  environment.systemPackages = with pkgs; [
    seahorse
    networkmanagerapplet
  ];
}