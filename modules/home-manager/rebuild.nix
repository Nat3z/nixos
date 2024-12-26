{ config, pkgs, flakeName, ... }:
{
   home.packages = [
    (pkgs.writeShellScriptBin "rebuild" ''
      if [ "$EUID" = 0 ]; then
        echo "Please don't run as root, you were about to break git."
      else
        git -C /Users/${config.home.username}/nix-config add . || git -C /home/${config.home.username}/nix-config add . 
        if darwin-rebuild switch --flake path:/Users/${config.home.username}/nix-config/#${flakeName} || sudo nixos-rebuild switch --flake path:/home/${config.home.username}/nix-config/#${flakeName}; then
          echo "Rebuild successful, committing changes."
          git -C /Users/${config.home.username}/nix-config commit -m "Rebuild: ${flakeName} $(date)" || git -C /home/${config.home.username}/nix-config commit -m "Rebuild: ${flakeName} $(date)"
        else
          echo "Rebuild failed, please check the logs."
        fi
      fi
    '')

    (pkgs.writeShellScriptBin "update" ''
      if [ "$EUID" = 0 ]; then
        echo "Please don't run as root, you were about to break git."
      else
        cd /home/${config.home.username}/Documents/Code/Bash/zen-browser-flake/
        echo "Updating Zen Browser flake..."
        bun run updateall.js
        echo "Updating Zen Browser flake... Done!"
        cd /home/${config.home.username}/nix-config
        nix flake update
        rebuild
      fi 
    '')
   ];
}
