{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.darwin.patches;
in
{
  options.darwin.patches = {
    enable = mkEnableOption "quality of life patches for macOS";

    fastDockAnimation = mkOption {
      type = types.bool;
      default = true;
      description = "Faster Dock Animation";
    };
    disableAccentKeyboard = mkOption {
      type = types.bool;
      default = true;
      description = "Disable the Accent keyboard";
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts =
      mkIf cfg.fastDockAnimation {
        "fastDockAnimation" = {
          enable = true;
          text = ''
            defaults write com.apple.dock autohide-delay -float 0; killall Dock
            echo "Fast Dock Animation enabled"
          '';
        };
      }
      // optionalAttrs cfg.disableAccentKeyboard {
        "disableAccentKeyboard" = {
          enable = true;
          text = ''
            defaults write -g ApplePressAndHoldEnabled -bool false
            echo "Accent keyboard disabled"
          '';
        };
      };
  };
}
