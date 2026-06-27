{ config, lib, ... }:

with lib;

let
  legacy = config.bundles.devtools-brew;
  cfg = config.bundles.programming.homebrew;

  enabled = legacy.enable || cfg.enable;

  use = category:
    (legacy.enable && legacy.${category}.enable)
    || (cfg.enable && cfg.${category}.enable);

  extraTaps = legacy.extraTaps ++ cfg.extraTaps;
  extraBrews = legacy.extraBrews ++ cfg.extraBrews;
  extraCasks = legacy.extraCasks ++ cfg.extraCasks;

  devtoolsOptions = {
    enable = mkEnableOption "Homebrew-only developer and hardware tooling";

    shell.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install shell-related Homebrew tools.";
    };
    hardware.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install embedded/hardware tooling.";
    };
    network.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install networking/tunnel tooling.";
    };
    python.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install Homebrew Python-oriented tooling.";
    };
    cli.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install miscellaneous CLI developer tools.";
    };
    ai.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install AI CLI tools managed by Homebrew.";
    };
    anaconda.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install Anaconda cask.";
    };
    archives.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install archive utilities managed by Homebrew.";
    };

    extraTaps = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra Homebrew taps for this bundle.";
    };
    extraBrews = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra Homebrew formulae for this bundle.";
    };
    extraCasks = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra Homebrew casks for this bundle.";
    };
  };
in
{
  options = {
    # Preferred location: this is part of the programming/dev-tooling story.
    bundles.programming.homebrew = devtoolsOptions;

    # Backwards-compatible location. Prefer `bundles.programming.homebrew`.
    bundles.devtools-brew = devtoolsOptions;
  };

  config = mkIf enabled {
    homebrew = {
      taps =
        optionals (use "hardware") [
          "osx-cross/arm"
          "osx-cross/avr"
          "qmk/qmk"
        ]
        ++ optionals (use "cli") [
          "steipete/tap"
          "tw93/tap"
        ]
        ++ extraTaps;

      # Tools unavailable, awkward, or intentionally managed through Homebrew.
      brews =
        optionals (use "shell") [
          "bash"
        ]
        ++ optionals (use "hardware") [
          "arduino-cli"
          "esptool"
        ]
        ++ optionals (use "network") [
          "cloudflared"
        ]
        ++ optionals (use "ai") [
          "gemini-cli"
        ]
        ++ optionals (use "cli") [
          "gh"
          "gnupg"
          "markdownlint-cli"
          "ncdu"
          "pinentry-mac"
        ]
        ++ optionals (use "python") [
          "pipx"
          "pyinstaller"
          "python@3.13"
        ]
        ++ extraBrews;

      casks =
        optional (use "anaconda") "anaconda"
        ++ optional (use "network") "ngrok"
        ++ optional (use "archives") "rar"
        ++ extraCasks;
    };
  };
}
