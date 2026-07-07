{ config, lib, username, ... }:

with lib;

let
  legacy = config.bundles.homebrew-core;
  cfg = config.bundles.programming.homebrew.core;
  enabled = legacy.enable || cfg.enable;
  pick = name: if cfg.enable then cfg.${name} else legacy.${name};

  coreOptions = {
    enable = mkEnableOption "base nix-homebrew/homebrew integration";

    enableRosetta = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Rosetta support for nix-homebrew.";
    };
    mutableTaps = mkOption {
      type = types.bool;
      default = true;
      description = "Allow Homebrew taps to be mutable.";
    };
    autoMigrate = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically migrate existing Homebrew installation.";
    };
    onActivation = {
      autoUpdate = mkOption {
        type = types.bool;
        default = false;
        description = "Run brew update during activation.";
      };
      cleanup = mkOption {
        type = types.enum [ "none" "uninstall" "zap" ];
        default = "uninstall";
        description = "Homebrew cleanup mode during activation.";
      };
      upgrade = mkOption {
        type = types.bool;
        default = false;
        description = "Run brew upgrade during activation.";
      };
    };
  };
in
{
  options = {
    # Preferred location: Homebrew is support infrastructure for the
    # Darwin programming bundle, so keep it nested there.
    bundles.programming.homebrew.core = coreOptions;

    # Backwards-compatible location. Prefer `bundles.programming.homebrew.core`.
    bundles.homebrew-core = coreOptions;
  };

  config = mkIf enabled {
    nix-homebrew = {
      enable = true;
      enableRosetta = pick "enableRosetta";
      user = username;
      mutableTaps = pick "mutableTaps";
      autoMigrate = pick "autoMigrate";
    };

    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = (pick "onActivation").autoUpdate;
        cleanup = (pick "onActivation").cleanup;
        upgrade = (pick "onActivation").upgrade;
      };
    };
  };
}
