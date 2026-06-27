{ config, lib, username, ... }:

with lib;

let
  cfg = config.bundles.homebrew-core;
in
{
  options.bundles.homebrew-core = {
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

  config = mkIf cfg.enable {
    nix-homebrew = {
      enable = true;
      enableRosetta = cfg.enableRosetta;
      user = username;
      mutableTaps = cfg.mutableTaps;
      autoMigrate = cfg.autoMigrate;
    };

    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = cfg.onActivation.autoUpdate;
        cleanup = cfg.onActivation.cleanup;
        upgrade = cfg.onActivation.upgrade;
      };
    };
  };
}
