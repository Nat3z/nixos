{ config, pkgs, flakeName, ... }:
{
   home.packages = [
    (pkgs.writeShellScriptBin "rebuild" ''
      if [ "$EUID" = 0 ]; then
        echo "Please don't run as root, you were about to break git."
      else
        git -C /home/${config.home.username}/nix-config add .
        if sudo nixos-rebuild switch --flake path:/home/${config.home.username}/nix-config/#${flakeName}; then
          echo "Rebuild successful, committing changes."
          git -C /home/${config.home.username}/nix-config commit -m "Rebuild: ${flakeName} $(date)"
        else
          echo "Rebuild failed, please check the logs."
        fi
      fi
    '')
   ];
}
