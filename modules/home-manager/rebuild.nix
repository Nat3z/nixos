{ config, pkgs, flakeName, ... }:
{
   home.packages = [
    (pkgs.writeShellScriptBin "rebuild" ''
      git -C /home/${config.home.username}/nix-config add .
      nixos-rebuild switch --flake /home/${config.home.username}/nix-config/#${flakeName}
    '')
   ];
}
