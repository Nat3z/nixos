{ lib, pkgs, ... }:
let
  appimage = pkgs.fetchurl {
    url = "https://github.com/Nat3z/OpenGameInstaller/releases/download/v1.6.3/OpenGameInstaller-linux-pt.AppImage";
    sha256 = "sha256-4hD+y4lsSo9jCtH9h/21BXsO2nNuy2bJBPSU3pXtwvA";
  };
in
  pkgs.appimageTools.wrapType2 {
    name = "OpenGameInstaller";
    version = "1.6.3";
    src = appimage;
    extraPkgs = pkgs: [ pkgs.bun ];
    meta = {
      description = "OpenGameInstaller is a game downloader and installer for Linux";
      homepage = "https://ogi.nat3z.com";
      author = "Nat3z";
      maintainers = [ "Nat3z" ];
    };
    desktopItems = [
      (lib.makeDesktopItem {
        name = "OpenGameInstaller";
        exec = "OpenGameInstaller-linux-pt.AppImage %U";
        icon = "opengameinstaller";
        desktopName = "OpenGameInstaller";
        comment = "OpenGameInstaller desktop";
        mimeTypes = [ ];
        categories = [ "Gaming" ];
        startupWMClass = "ogi";
      })
    ];
  }
