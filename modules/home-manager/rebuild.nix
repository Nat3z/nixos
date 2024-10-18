{ config, pkgs, flakeName, ... }:
{
   home.packages = [
    (pkgs.writeShellScriptBin "rebuild" ''
      if [ "$EUID" = 0 ]; then
        echo "Please don't run as root, you were about to break git."
      else
        git -C /home/${config.home.username}/nix-config add .
        sudo nixos-rebuild switch --flake path:/home/${config.home.username}/nix-config/#${flakeName}
      fi
    '')
   ];
}
