{ config, lib, ... }:

with lib;

let
  cfg = config.bundles.desktop-apps;
in
{
  options.bundles.desktop-apps = {
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

    aerospace.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install Aerospace.";
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

  config = mkIf cfg.enable {
    nix-homebrew.trust.casks =
      optional (cfg.windowManagers.enable && cfg.sikarugir.enable) "sikarugir-app/sikarugir/sikarugir"
      ++ cfg.extraTrustedCasks;

    homebrew = {
      taps =
        optional (cfg.windowManagers.enable && cfg.sikarugir.enable) "sikarugir-app/sikarugir"
        ++ cfg.extraTaps;

      brews =
        optionals cfg.windowManagers.enable [
          "cliclick"
        ]
        ++ optionals cfg.media.enable [
          "ffmpeg"
          "imagesnap"
          "spicetify-cli"
        ]
        ++ cfg.extraBrews;

      casks =
        optional (cfg.windowManagers.enable && cfg.aerospace.enable) "aerospace"
        ++ optional (cfg.media.enable) "audacity"
        ++ optional (cfg.design.enable && cfg.figma.enable) "figma"
        ++ optional (cfg.design.enable && cfg.finetune.enable) "finetune"
        ++ optional cfg.fonts.enable "font-jetbrains-mono-nerd-font"
        ++ optional (cfg.cad.enable && cfg.kicad.enable) "kicad"
        ++ optional (cfg.sikarugir.enable) "sikarugir"
        ++ optional (cfg.cursorcerer.enable) "cursorcerer"
        ++ cfg.extraCasks;

    };
  };
}
