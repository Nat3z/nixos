{
  config,
  pkgs,
  flakeName,
  lib,
  ...
}:
let
  homeDir = config.home.homeDirectory;
  nixConfigDir = "${homeDir}/nix-config";
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "rebuild" ''
      set -euo pipefail

      if [ "$EUID" = 0 ]; then
        echo "Please don't run as root, you were about to break git."
        exit 1
      fi

      squash=false
      case "''${1:-}" in
        "") ;;
        --squash) squash=true ;;
        *)
          echo "Usage: rebuild [--squash]"
          exit 1
          ;;
      esac

      git -C ${nixConfigDir} add .

      if command -v darwin-rebuild >/dev/null 2>&1; then
        sudo darwin-rebuild switch --flake path:${nixConfigDir}/#${flakeName}
      elif command -v nixos-rebuild >/dev/null 2>&1; then
        sudo nixos-rebuild switch --flake path:${nixConfigDir}/#${flakeName}
      else
        echo "Unknown system: neither Darwin nor NixOS detected"
        exit 1
      fi

      if [ "$squash" = true ]; then
        upstream="$(git -C ${nixConfigDir} rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)"
        if [ -z "$upstream" ]; then
          echo "No upstream branch found; cannot squash commits safely."
          exit 1
        fi

        git -C ${nixConfigDir} reset --soft "$upstream"
        git -C ${nixConfigDir} add .

        read -r -p "Squash commit name: " commit_name
        if [ -z "$commit_name" ]; then
          echo "Commit name cannot be empty."
          exit 1
        fi

        if git -C ${nixConfigDir} diff --cached --quiet; then
          echo "No changes to commit."
        else
          git -C ${nixConfigDir} commit -m "chore(rebuild): $commit_name at $(date)"
        fi
      else
        git -C ${nixConfigDir} commit -m "chore(rebuild): switch ${flakeName} at $(date)" || true
      fi

      ${lib.optionalString pkgs.stdenv.isDarwin ''
        echo "Restarting skhd.."
        skhd --uninstall-service
        killall skhd
        skhd --install-service
      ''}
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
