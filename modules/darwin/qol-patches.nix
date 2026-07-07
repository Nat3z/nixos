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
      # `autohide-delay` removes the wait before the Dock appears;
      # `autohide-time-modifier` removes the slide animation itself.
      system.defaults.dock.autohide-delay = 0.0;
      system.defaults.dock.autohide-time-modifier = 0.0;
    })

    (mkIf cfg.disableAccentKeyboard {
      system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;
    })

    {
      # Refresh the preferences cache after nix-darwin writes defaults. Dock is
      # already restarted by nix-darwin when Dock defaults change, but cfprefsd
      # can otherwise keep stale global defaults around until logout/reboot.
      system.activationScripts.userDefaults.text = mkAfter ''
        echo >&2 "refreshing macOS defaults cache..."
        killall cfprefsd >/dev/null 2>&1 || true
      '';
    }
  ]);
}
