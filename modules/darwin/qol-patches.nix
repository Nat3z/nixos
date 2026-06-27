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

    fastDockAnimation = mkEnableOption "Faster Dock Animation";
    disableAccentKeyboard = mkEnableOption "Disable the Accent keyboard";
  };

  config = mkIf cfg.enable {
    system.activationScripts =
      mkIf cfg.fastDockAnimation {
        "fastDockAnimation" = {
          enable = true;
          text = ''
            defaults write com.apple.dock autohide-delay -float 0; killall Dock
          '';
        };
      }
      // optionalAttrs cfg.disableAccentKeyboard {
        "disableAccentKeyboard" = {
          enable = true;
          text = ''
            defaults write -g ApplePressAndHoldEnabled -bool false
          '';
        };
      };
  };
}
