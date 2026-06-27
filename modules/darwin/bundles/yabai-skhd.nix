{
  config,
  lib,
  username,
  ...
}:

with lib;

let
  cfg = config.bundles.yabai-skhd;
in
{
  options.bundles.yabai-skhd = {
    enable = mkEnableOption "yabai and skhd window-management bundle";

    yabai.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable yabai";
    };

    skhd.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Skhd";
    };
  };

  config = mkIf cfg.enable {
    services.skhd = mkIf cfg.skhd.enable {
      enable = true;
      skhdConfig = ''
        ctrl - 1 : yabai -m space --focus 1
        ctrl - 2 : yabai -m space --focus 2
        ctrl - 3 : yabai -m space --focus 3
        ctrl - 4 : yabai -m space --focus 4

        cmd - q : /Users/${username}/Scripts/confirm-quit-front-app
      '';
    };

    services.yabai = mkIf cfg.yabai.enable {
      enable = true;
      enableScriptingAddition = true;
      config = {
        layout = "bsp";
        mouse_modifier = "fn";
        focus_follows_mouse = "autoraise";
        window_placement = "second_child";
      };
      extraConfig = ''
        yabai -m rule --add app="^FaceTime$" manage=off
        yabai -m rule --add app="^Raycast$" manage=off
        yabai -m rule --add app="^Kap$" manage=off
        yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"
      '';
    };

    home-manager.users.${username} = {
      home.file."Scripts/confirm-quit-front-app" = {
        force = true;
        executable = true;
        text = ''
          #!/bin/zsh

          set -u

          action="''${1:-quit}"
          front_app=$(/usr/bin/osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null || true)

          case "$front_app" in
            FaceTime|facetime)
              button=$(/usr/bin/osascript 2>/dev/null <<'APPLESCRIPT'
          display dialog "Close FaceTime?" buttons {"Cancel", "Close FaceTime"} default button "Cancel" cancel button "Cancel" with icon caution
          button returned of result
          APPLESCRIPT
          )

              if [[ "''${button:-}" == "Close FaceTime" ]]; then
                if [[ "$action" == "close" ]]; then
                  /usr/bin/osascript -e 'tell application "System Events" to tell process "FaceTime" to click button 1 of window 1' 2>/dev/null
                else
                  /usr/bin/osascript -e 'tell application "FaceTime" to quit'
                fi
              fi
              ;;
            "")
              exit 0
              ;;
            *)
              app_id=$(/usr/bin/osascript -e "id of application \"$front_app\"" 2>/dev/null || true)
              if [[ -n "$app_id" ]]; then
                if [[ "$action" == "close" ]]; then
                  /usr/bin/osascript -e "tell application \"System Events\" to tell process \"$front_app\" to click menu item \"Close Window\" of menu \"File\" of menu bar item \"File\" of menu bar 1" 2>/dev/null
                else
                  /usr/bin/osascript -e "tell application id \"$app_id\" to quit" 2>/dev/null
                fi
              fi
              ;;
          esac
        '';

      };
    };
  };
}
