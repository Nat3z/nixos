{ config, pkgs, ... }:
{
   home.packages = [
    (pkgs.writeShellScriptBin "rebuild" ''
      nixos-rebuild switch --flake /home/${config.home.username}/nix-config/#default
    '')
   ];
}
