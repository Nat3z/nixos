{ lib, pkgs, ... }:
let
  appimage = pkgs.fetchurl {
    url = "https://github.com/Nat3z/OpenGameInstaller/releases/download/v1.6.4/OpenGameInstaller-linux-pt.AppImage";
    sha256 = "sha256-htuyCOdaRRMhinab6JDc5zoXABY0UhgvM/jUKZyE2qE=";
  };
in
  pkgs.appimageTools.wrapType2 {
    pname = "OpenGameInstaller";
    version = "1.6.4";
    src = appimage;
    extraPkgs = pkgs: [ pkgs.bun pkgs.unzip pkgs.unrar pkgs.wineWowPackages.stable ];
    meta = {
      description = "OpenGameInstaller is a game downloader and installer for Linux";
      homepage = "https://ogi.nat3z.com";
      author = "Nat3z";
      maintainers = [ "Nat3z" ];
    };
    desktopItems = [
      (lib.makeDesktopItem {
        name = "OpenGameInstaller";
        exec = "OpenGameInstaller %U";
        icon = "opengameinstaller";
        desktopName = "OpenGameInstaller";
        comment = "OpenGameInstaller desktop";
        mimeTypes = [ ];
        categories = [ "Gaming" ];
        startupWMClass = "ogi";
      })
    ];
    extraInstallCommands = ''
    '';
  }
