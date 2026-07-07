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

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.fastDockAnimation {
      system.defaults.dock.autohide-delay = 0.0;
    })

    (mkIf cfg.disableAccentKeyboard {
      system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;
    })
  ]);
}
