{ config, lib, ... }:

with lib;

let
  legacy = config.bundles.desktop-apps;
  cfg = config.bundles.programming.desktop;
  enabled = legacy.enable || cfg.enable;
  use = category:
    (legacy.enable && legacy.${category}.enable)
    || (cfg.enable && cfg.${category}.enable);
  extraTaps = legacy.extraTaps ++ cfg.extraTaps;
  extraBrews = legacy.extraBrews ++ cfg.extraBrews;
  extraCasks = legacy.extraCasks ++ cfg.extraCasks;
  extraTrustedCasks = legacy.extraTrustedCasks ++ cfg.extraTrustedCasks;

  desktopOptions = {
    enable = mkEnableOption "Homebrew cask desktop apps, fonts, and media tools";

    windowManagers.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install desktop window-manager related GUI apps.";
    };
    media.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install media/audio/video tools.";
    };
    music.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install music tools.";
    };
    design.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install design/productivity GUI tools.";
    };
    cad.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install cad-related GUI tools.";
    };
    fonts.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install GUI fonts through Homebrew casks.";
    };

    sikarugir.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install Sikarugir.";
    };
    cursorcerer.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install Cursorcerer.";
    };
    figma.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install Figma.";
    };
    finetune.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install Finetune.";
    };
    vibeproxy.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install VibeProxy.";
    };
    kicad.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install KiCad.";
    };

    extraTaps = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra Homebrew taps for desktop apps.";
    };
    extraBrews = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra Homebrew formulae for desktop apps.";
    };
    extraCasks = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra Homebrew casks for desktop apps.";
    };
    extraTrustedCasks = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra trusted casks for nix-homebrew.";
    };
  };
in
{
  options = {
    # Preferred location: GUI/productivity apps that support the workstation
    # belong under the programming bundle instead of a separate top-level bundle.
    bundles.programming.desktop = desktopOptions;

    # Backwards-compatible location. Prefer `bundles.programming.desktop`.
    bundles.desktop-apps = desktopOptions;
  };

  config = mkIf enabled {
    nix-homebrew.trust.casks =
      optional (use "windowManagers" && use "sikarugir") "sikarugir-app/sikarugir/sikarugir"
      ++ extraTrustedCasks;

    homebrew = {
      taps =
        optional (use "windowManagers" && use "sikarugir") "sikarugir-app/sikarugir"
        ++ extraTaps;

      brews =
        optionals (use "windowManagers") [
          "cliclick"
        ]
        ++ optionals (use "media") [
          "ffmpeg"
          "imagesnap"
          "spicetify-cli"
        ]
        ++ extraBrews;

      casks =
        optional (use "media") "audacity"
        ++ optional (use "design" && use "figma") "figma"
        ++ optional (use "design" && use "finetune") "finetune"
        ++ optional (use "fonts") "font-jetbrains-mono-nerd-font"
        ++ optional (use "cad" && use "kicad") "kicad"
        ++ optional (use "sikarugir") "sikarugir"
        ++ optional (use "cursorcerer") "cursorcerer"
        ++ optional (use "vibeproxy") "vibeproxy"
        ++ optional (use "music") "musescore"
        ++ extraCasks;

    };
  };
}
