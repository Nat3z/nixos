{ config, pkgs, flakeName, ... }:
{
   home.packages = [
    (pkgs.writeShellScriptBin "rebuild" ''
      git -C /home/${config.home.username}/nix-config add .
      sudo nixos-rebuild switch --flake path:/home/${config.home.username}/nix-config/#${flakeName}
    '')
   ];
}
