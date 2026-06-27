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
        # -------- Yabai shortcuts --------

        fn - 1 : yabai -m space --focus 1
        fn - 2 : yabai -m space --focus 2
        fn - 3 : yabai -m space --focus 3
        fn - 4 : yabai -m space --focus 4
        fn - 5 : yabai -m space --focus 5

        fn + shift - 1 : yabai -m window --space 1
        fn + shift - 2 : yabai -m window --space 2
        fn + shift - 3 : yabai -m window --space 3
        fn + shift - 4 : yabai -m window --space 4
        fn + shift - 5 : yabai -m window --space 5

        fn + shift - k : yabai -m window --warp north
        fn + shift - h : yabai -m window --warp west
        fn + shift - l : yabai -m window --warp east
        fn + shift - j : yabai -m window --warp south

        fn - j : yabai -m window --focus south
        fn - h : yabai -m window --focus west
        fn - l : yabai -m window --focus east
        fn - k : yabai -m window --focus north

        fn - f : if [ "$(yabai -m query --spaces --space | jq -r '.type')" = "bsp" ]; then yabai -m space --layout float; else yabai -m space --layout bsp; fi
        fn - g : ~/.config/skhd/reorganizer.sh

        fn + shift - d : /bin/sh -c 'eval $(/opt/homebrew/bin/brew shellenv) && yabai -m query --spaces --display | jq -re "map(select(.\"is-native-fullscreen\" == false)) | length > 1" && yabai -m query --spaces | jq -re "map(select(.\"windows\" == [] and .\"has-focus\" == false).index) | reverse | .[]" | xargs -I % sh -c "yabai -m space % --destroy"'

        fn - t : eval $(/opt/homebrew/bin/brew shellenv) && if [ "$(yabai -m config focus_follows_mouse)" = "autoraise" ]; then yabai -m config focus_follows_mouse off; else yabai -m config focus_follows_mouse autoraise; fi

        # fn - t : osascript -e 'tell application "System Events" to keystroke "t" using {command down, option down, shift down, control down}' && echo 'tapped'

        # -------- App shortcuts --------
        cmd - q : /Users/nat/Scripts/confirm-quit-front-app quit
        cmd - w [
            "FaceTime" : /Users/nat/Scripts/confirm-quit-front-app close
            "facetime" : /Users/nat/Scripts/confirm-quit-front-app close
            *          ~
        ]

        fn - 0 : killall Finder
        fn - q : pgrep -x "ghostty" && osascript -e 'tell application "System Events" to tell process "Ghostty" to click menu item "New Window" of menu "File" of menu bar item "File" of menu bar 1' || open -a "Ghostty"
        fn - e : osascript -e 'tell application "Finder" to make new Finder window to home'
        fn - b : pgrep -x "helium" && osascript -e 'tell application "System Events" to tell process "Helium" to click menu item "New Window" of menu "File" of menu bar item "File" of menu bar 1' || open -a "Helium"

        fn - r : ~/.config/skhd/focus_messages.sh

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

      home.file.".config/skhd/focus_messages.sh" = {
        force = true;
        executable = true;
        text = ''
          #!/bin/bash
          eval $(/opt/homebrew/bin/brew shellenv)

          # Check if Messages is running
          if ! pgrep -x "Messages" > /dev/null; then
              open -a "Messages"
              exit 0
          fi

          # Get Messages window ID
          WINDOW_ID=$(yabai -m query --windows | jq -r '.[] | select(.app == "Messages") | .id')

          if [ -z "$WINDOW_ID" ] || [ "$WINDOW_ID" = "null" ]; then
              osascript -e 'tell application "Messages" to activate'
              exit 0
          fi

          # Get current space
          CURRENT_SPACE=$(yabai -m query --spaces --space | jq -r '.index')

          # Get Messages window space
          MESSAGES_SPACE=$(yabai -m query --windows | jq -r '.[] | select(.app == "Messages") | .space')

          # Move to current space if not already there
          if [ "$MESSAGES_SPACE" != "$CURRENT_SPACE" ]; then
              yabai -m window "$WINDOW_ID" --space "$CURRENT_SPACE"
          fi

          # Focus the window
          yabai -m window "$WINDOW_ID" --focus
        '';
      };

      home.file.".config/skhd/reorganizer.sh" = {
        force = true;
        executable = true;
        text = ''
          #!/opt/homebrew/bin/bash
          eval $(/opt/homebrew/bin/brew shellenv)

          # Function to ensure all required spaces exist
          create_required_spaces() {
              # Get current number of spaces
              local current_spaces=$(yabai -m query --spaces | jq length)
              # Get maximum space number needed
              local max_space=$(printf '%s\n' "''${app_spaces[@]}" | sort -nr | head -n1)

              # Create additional spaces if needed
              while [ "$current_spaces" -lt "$max_space" ]; do
                  yabai -m space --create
                  current_spaces=$((current_spaces + 1))
              done
          }

          # Function to check if a window ID exists
          window_exists() {
              local window_id=$1
              yabai -m query --windows | jq --arg id "$window_id" '.[] | select(.id == ($id|tonumber))' | grep -q "."
              return $?
          }

          # App to space mappings
          declare -A app_spaces=(
              ["DaVinci Resolve"]=1
              ["Zen Browser"]=1
              ["Code"]=2
              ["Cursor"]=2
              ["Ghostty"]=3
              ["kitty"]=3
              ["Discord"]=4
              ["Spotify"]=5
              ["Music"]=5
              ["Google Chrome"]=5
              ["GitHub Desktop"]=5
          )

          # Ensure all required spaces exist
          create_required_spaces

          # First pass: Handle only space moves for special apps
          echo "First pass: Moving spaces..."
          for app in "''${!app_spaces[@]}"; do
              space="''${app_spaces[$app]}"

              # Only process space-moving apps in this pass
              if [ "$app" = "DaVinci Resolve" ] || [ "$app" = "Zen Browser" ] || [ "$app" = "Music" ]; then
                  window_ids=$(yabai -m query --windows | jq --arg app "$app" '.[] | select(.app | test($app)).id')
                  if [ ! -z "$window_ids" ]; then
                      echo "Processing space moves for $app -> Space $space"
                      echo "$window_ids" | while read -r id; do
                          if [ ! -z "$id" ] && window_exists "$id"; then
                              current_space=$(yabai -m query --spaces | jq --arg id "$id" '.[] | select(.windows[] == ($id|tonumber)).index')
                              if [ ! -z "$current_space" ]; then
                                  echo "Moving space $current_space to position $space"
                                  yabai -m space "$current_space" --move "$space"
                              fi
                          fi
                      done
                  fi
              fi
          done

          # Second pass: Handle regular window moves
          echo "Second pass: Moving windows..."
          for app in "''${!app_spaces[@]}"; do
              space="''${app_spaces[$app]}"

              # Skip space-moving apps in this pass
              if [ "$app" != "DaVinci Resolve" ] && [ "$app" != "Zen Browser" ] || [ "$app" != "Music" ]; then
                  window_ids=$(yabai -m query --windows | jq --arg app "$app" '.[] | select(.app | test($app)).id')

                  if [ ! -z "$window_ids" ]; then
                      echo "Processing $app -> Space $space"

                      echo "$window_ids" | while read -r id; do
                          if [ ! -z "$id" ] && window_exists "$id"; then
                              echo "Moving $app (ID: $id) to space $space"
                              yabai -m window "$id" --space "$space"
                          fi
                      done
                  fi
              fi
          done

          # Balance spaces
          echo "Balancing all spaces..."
          spaces=$(yabai -m query --spaces | jq '.[].index')
          for space in $spaces; do
              echo "Balancing space $space"
              yabai -m space $space --balance
          done
        '';
      };
    };
  };
}
