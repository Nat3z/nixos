{ config, pkgs, flakeName, ... }:
let
  homeDir = config.home.homeDirectory;
  nixConfigDir = "${homeDir}/nix-config";
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "rebuild" ''
      if [ "$EUID" = 0 ]; then
        echo "Please don't run as root, you were about to break git."
        exit 1
      fi

      git -C ${nixConfigDir} add .

      if command -v darwin-rebuild >/dev/null 2>&1; then
        sudo darwin-rebuild switch --flake path:${nixConfigDir}/#${flakeName}
      elif command -v nixos-rebuild >/dev/null 2>&1; then
        sudo nixos-rebuild switch --flake path:${nixConfigDir}/#${flakeName}
      else
        echo "Unknown system: neither Darwin nor NixOS detected"
        exit 1
      fi

      echo "Rebuild successful, committing changes."
      git -C ${nixConfigDir} commit -m "Rebuild: ${flakeName} $(date)" || true
    '')

    (pkgs.writeShellScriptBin "update" ''
      if [ "$EUID" = 0 ]; then
        echo "Please don't run as root, you were about to break git."
        exit 1
      fi

      if [ -d "${homeDir}/Documents/Code/Bash/zen-browser-flake" ]; then
        cd "${homeDir}/Documents/Code/Bash/zen-browser-flake"
        echo "Updating Zen Browser flake..."
        bun run updateall.js
        echo "Updating Zen Browser flake... Done!"
      fi

      cd ${nixConfigDir}
      nix flake update
      rebuild
    '')
  ];
}
