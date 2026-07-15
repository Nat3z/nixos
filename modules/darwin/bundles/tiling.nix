{
  config,
  lib,
  pkgs,
  username,
  ...
}:

with lib;

let
  cfg = config.darwin.tiling;
  enabled = cfg.enable;
  use = name:
    (cfg.enable && cfg.${name}.enable);

  aerospaceConfigPath = "/Users/${username}/.config/aerospace/aerospace.toml";

  # Shared AeroSpace settings. Written to a user-writable path so fn-t can toggle
  # focus-follows-mouse (yabai's autoraise equivalent) without editing the nix store.
  aerospaceSettings = {
    config-version = 2;

    start-at-login = false;

    after-login-command = [ ];
    after-startup-command = [ ];

    enable-normalization-flatten-containers = true;
    enable-normalization-opposite-orientation-for-nested-containers = true;

    accordion-padding = 30;
    default-root-container-layout = "tiles";
    default-root-container-orientation = "auto";

    on-focus-changed = [ ];
    on-focused-monitor-changed = [ ];
    exec-on-workspace-change = [
      "/bin/bash"
      "-c"
      ''eval $(/opt/homebrew/bin/brew shellenv); ~/.config/skhd/aerospace_follow_facetime.sh "$AEROSPACE_FOCUSED_WORKSPACE"; ~/.config/skhd/aerospace_follow_discord_popout.sh "$AEROSPACE_FOCUSED_WORKSPACE"''
    ];

    automatically-unhide-macos-hidden-apps = false;

    focus-follows-mouse.enabled = true;

    on-window-detected = [
      {
        "if".app-id = "com.apple.FaceTime";
        run = [
          "layout floating"
          "exec-and-forget sleep 0.2; eval $(/opt/homebrew/bin/brew shellenv); ~/.config/skhd/aerospace_follow_facetime.sh"
        ];
      }
      {
        "if".app-id = "com.raycast.macos";
        run = "layout floating";
      }
      {
        "if".app-id = "com.wulkano.kap";
        run = "layout floating";
      }
      {
        "if".app-name-regex-substring = "^[Dd]iscord$";
        run = "exec-and-forget sleep 0.2; eval $(/opt/homebrew/bin/brew shellenv); ~/.config/skhd/aerospace_follow_discord_popout.sh";
      }
    ];

    key-mapping = {
      preset = "qwerty";
    };

    gaps = {
      inner = {
        horizontal = 0;
        vertical = 0;
      };
      outer = {
        left = 0;
        bottom = 0;
        top = 0;
        right = 0;
      };
    };
  };

  aerospaceToml = (pkgs.formats.toml { }).generate "aerospace.toml" aerospaceSettings;

  yabaiSkhdConfig = ''
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

    fn - r : ~/.config/skhd/focus_messages.sh
  '';

  aerospaceSkhdConfig = ''
    # -------- AeroSpace shortcuts --------

    fn - 1 : eval $(/opt/homebrew/bin/brew shellenv) && aerospace workspace 1 && ~/.config/skhd/aerospace_follow_facetime.sh 1 && ~/.config/skhd/aerospace_follow_discord_popout.sh 1 >/dev/null 2>&1 &
    fn - 2 : eval $(/opt/homebrew/bin/brew shellenv) && aerospace workspace 2 && ~/.config/skhd/aerospace_follow_facetime.sh 2 && ~/.config/skhd/aerospace_follow_discord_popout.sh 2 >/dev/null 2>&1 &
    fn - 3 : eval $(/opt/homebrew/bin/brew shellenv) && aerospace workspace 3 && ~/.config/skhd/aerospace_follow_facetime.sh 3 && ~/.config/skhd/aerospace_follow_discord_popout.sh 3 >/dev/null 2>&1 &
    fn - 4 : eval $(/opt/homebrew/bin/brew shellenv) && aerospace workspace 4 && ~/.config/skhd/aerospace_follow_facetime.sh 4 && ~/.config/skhd/aerospace_follow_discord_popout.sh 4 >/dev/null 2>&1 &
    fn - 5 : eval $(/opt/homebrew/bin/brew shellenv) && aerospace workspace 5 && ~/.config/skhd/aerospace_follow_facetime.sh 5 && ~/.config/skhd/aerospace_follow_discord_popout.sh 5 >/dev/null 2>&1 &

    fn + shift - 1 : eval $(/opt/homebrew/bin/brew shellenv) && aerospace move-node-to-workspace 1
    fn + shift - 2 : eval $(/opt/homebrew/bin/brew shellenv) && aerospace move-node-to-workspace 2
    fn + shift - 3 : eval $(/opt/homebrew/bin/brew shellenv) && aerospace move-node-to-workspace 3
    fn + shift - 4 : eval $(/opt/homebrew/bin/brew shellenv) && aerospace move-node-to-workspace 4
    fn + shift - 5 : eval $(/opt/homebrew/bin/brew shellenv) && aerospace move-node-to-workspace 5

    fn + shift - k : eval $(/opt/homebrew/bin/brew shellenv) && aerospace move up
    fn + shift - h : eval $(/opt/homebrew/bin/brew shellenv) && aerospace move left
    fn + shift - l : eval $(/opt/homebrew/bin/brew shellenv) && aerospace move right
    fn + shift - j : eval $(/opt/homebrew/bin/brew shellenv) && aerospace move down

    fn - j : eval $(/opt/homebrew/bin/brew shellenv) && aerospace focus down
    fn - h : eval $(/opt/homebrew/bin/brew shellenv) && aerospace focus left
    fn - l : eval $(/opt/homebrew/bin/brew shellenv) && aerospace focus right
    fn - k : eval $(/opt/homebrew/bin/brew shellenv) && aerospace focus up

    fn - f : eval $(/opt/homebrew/bin/brew shellenv) && aerospace layout floating tiling
    fn - g : ~/.config/skhd/aerospace_reorganizer.sh

    # AeroSpace workspaces are dynamic; there is no empty-space cleanup equivalent.
    fn + shift - d : true

    # Toggle focus-follows-mouse (yabai autoraise equivalent).
    fn - t : ~/.config/skhd/aerospace_toggle_ffm.sh

    fn - r : ~/.config/skhd/aerospace_focus_messages.sh

    # Temporarily hide/reveal the active FaceTime or Discord popout follow window.
    # 0x32 = ANSI grave/backtick (fn-`).
    fn - 0x32 : ~/.config/skhd/aerospace_toggle_follow_hide.sh
  '';

  appSkhdConfig = ''
    # -------- App shortcuts --------
    cmd - q : /bin/bash -lc '/Users/nat/Scripts/confirm-quit-front-app quit; ~/.config/skhd/aerospace_reflow.sh >/dev/null 2>&1 &'
    cmd - w [
        "FaceTime" : /bin/bash -lc '/Users/nat/Scripts/confirm-quit-front-app close; ~/.config/skhd/aerospace_reflow.sh >/dev/null 2>&1 &'
        "facetime" : /bin/bash -lc '/Users/nat/Scripts/confirm-quit-front-app close; ~/.config/skhd/aerospace_reflow.sh >/dev/null 2>&1 &'
    ]

    fn - 0 : killall Finder
    fn - q : pgrep -x "ghostty" && osascript -e 'tell application "System Events" to tell process "Ghostty" to click menu item "New Window" of menu "File" of menu bar item "File" of menu bar 1' || open -a "Ghostty"
    fn - e : osascript -e 'tell application "Finder" to make new Finder window to home'
    fn - b : pgrep -x "helium" && osascript -e 'tell application "System Events" to tell process "Helium" to click menu item "New Window" of menu "File" of menu bar item "File" of menu bar 1' || open -a "Helium"
  '';
  tilingOptions = {
    enable = mkEnableOption "tiling window-management bundle";

    yabai.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable yabai";
    };

    aerospace.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable AeroSpace";
    };

    skhd.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Skhd";
    };
  };
in
{
  options = {
    # Preferred location: window-management is part of the workstation/programming setup.
    darwin.tiling = tilingOptions;
  };

  config = mkIf enabled {
    assertions = [
      {
        assertion = !(use "yabai" && use "aerospace");
        message = "Only one of yabai or aerospace may be enabled under bundles.programming.tiling.";
      }
      {
        assertion = (use "yabai") || (use "aerospace");
        message = "Enable either bundles.programming.tiling.yabai or bundles.programming.tiling.aerospace when tiling is enabled.";
      }
    ];

    services.skhd = mkIf (use "skhd") {
      enable = true;
      skhdConfig = concatStringsSep "\n" (
        optional (use "yabai") yabaiSkhdConfig
        ++ optional (use "aerospace") aerospaceSkhdConfig
        ++ [ appSkhdConfig ]
      );
    };


    services.yabai = mkIf (use "yabai") {
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
        yabai -m signal --add event=window_created action="/bin/bash -lc '~/.config/skhd/follow_discord_popout.sh >/dev/null 2>&1 &'"
        yabai -m signal --add event=space_changed action="/bin/bash -lc '~/.config/skhd/follow_discord_popout.sh >/dev/null 2>&1 &'"
        yabai -m signal --add event=application_launched action="/bin/bash -lc '~/.config/skhd/follow_discord_popout.sh >/dev/null 2>&1 &'"
        yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"
      '';
    };

    services.aerospace = mkIf (use "aerospace") {
      enable = true;
      settings = aerospaceSettings;
    };

    # Prefer a user-writable config so fn-t can toggle focus-follows-mouse and reload.
    # Seed the file here in case home-manager activation has not run yet.
    launchd.user.agents.aerospace = mkIf (use "aerospace") {
      command = mkForce (pkgs.writeShellScript "aerospace-with-writable-config" ''
        set -euo pipefail
        mkdir -p /Users/${username}/.config/aerospace
        if [ ! -f ${aerospaceConfigPath} ]; then
          cp ${aerospaceToml} ${aerospaceConfigPath}
          chmod u+w ${aerospaceConfigPath}
        fi
        exec ${config.services.aerospace.package}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace --config-path ${aerospaceConfigPath}
      '');
    };

    # Submodule so we get home-manager's lib (lib.hm), not nix-darwin's.
    home-manager.users.${username} = { lib, ... }: {
      # Writable copy (not a store symlink) so fn-t can toggle focus-follows-mouse.
      home.activation.aerospaceWritableConfig = mkIf (use "aerospace") (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "$HOME/.config/aerospace"
          state_file="$HOME/.config/aerospace/ffm-enabled"
          if [ -f "$HOME/.config/aerospace/aerospace.toml" ]; then
            if grep -qE '^(focus-follows-mouse\.enabled|[[:space:]]*enabled)[[:space:]]*=[[:space:]]*false' "$HOME/.config/aerospace/aerospace.toml" \
              || /usr/bin/awk '/^\[focus-follows-mouse\]/{f=1;next} /^\[/{f=0} f && /^enabled[[:space:]]*=[[:space:]]*false/{found=1} END{exit !found}' "$HOME/.config/aerospace/aerospace.toml"; then
              echo false > "$state_file"
            else
              echo true > "$state_file"
            fi
          fi
          cp ${aerospaceToml} "$HOME/.config/aerospace/aerospace.toml"
          chmod u+w "$HOME/.config/aerospace/aerospace.toml"
          if [ -f "$state_file" ] && [ "$(cat "$state_file")" = "false" ]; then
            /usr/bin/sed -i '''' '/^\[focus-follows-mouse\]/,/^\[/{s/^enabled = true/enabled = false/;}' "$HOME/.config/aerospace/aerospace.toml"
            /usr/bin/sed -i '''' -E 's/^(focus-follows-mouse\.enabled[[:space:]]*=[[:space:]]*)true/\1false/' "$HOME/.config/aerospace/aerospace.toml"
          fi
        ''
      );

      home.file.".config/skhd/aerospace_toggle_ffm.sh" = mkIf (use "aerospace") {
        force = true;
        executable = true;
        text = ''
          #!/bin/bash
          # Toggle AeroSpace focus-follows-mouse (yabai autoraise equivalent).
          eval $(/opt/homebrew/bin/brew shellenv)

          CONFIG="''${HOME}/.config/aerospace/aerospace.toml"
          STATE="''${HOME}/.config/aerospace/ffm-enabled"

          if [ ! -f "$CONFIG" ]; then
              echo "aerospace config not found: $CONFIG" >&2
              exit 1
          fi

          is_enabled() {
              grep -qE '^focus-follows-mouse\.enabled[[:space:]]*=[[:space:]]*true([[:space:]]|$)' "$CONFIG" \
                  || /usr/bin/awk '/^\[focus-follows-mouse\]/{f=1;next} /^\[/{f=0} f && /^enabled[[:space:]]*=[[:space:]]*true/{found=1} END{exit !found}' "$CONFIG"
          }

          if is_enabled; then
              /usr/bin/sed -i '''' -E 's/^(focus-follows-mouse\.enabled[[:space:]]*=[[:space:]]*)true/\1false/' "$CONFIG"
              /usr/bin/sed -i '''' '/^\[focus-follows-mouse\]/,/^\[/{s/^enabled = true/enabled = false/;}' "$CONFIG"
              echo false > "$STATE"
          else
              /usr/bin/sed -i '''' -E 's/^(focus-follows-mouse\.enabled[[:space:]]*=[[:space:]]*)false/\1true/' "$CONFIG"
              /usr/bin/sed -i '''' '/^\[focus-follows-mouse\]/,/^\[/{s/^enabled = false/enabled = true/;}' "$CONFIG"
              if ! grep -qE '^focus-follows-mouse\.enabled[[:space:]]*=' "$CONFIG" \
                  && ! /usr/bin/awk '/^\[focus-follows-mouse\]/{found=1} END{exit !found}' "$CONFIG"; then
                  printf '\nfocus-follows-mouse.enabled = true\n' >> "$CONFIG"
              fi
              echo true > "$STATE"
          fi

          aerospace reload-config --no-gui
        '';
      };

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

      home.file.".config/skhd/aerospace_focus_messages.sh" = {
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
          WINDOW_ID=$(aerospace list-windows --all --format '%{window-id}|%{app-name}' | awk -F'|' '$2 == "Messages" { print $1; exit }')

          if [ -z "$WINDOW_ID" ]; then
              osascript -e 'tell application "Messages" to activate'
              exit 0
          fi

          # Get current workspace
          CURRENT_WORKSPACE=$(aerospace list-workspaces --focused)

          # Move to current workspace
          aerospace move-node-to-workspace --window-id "$WINDOW_ID" "$CURRENT_WORKSPACE"

          # Focus the window
          aerospace focus --window-id "$WINDOW_ID"
        '';
      };

      home.file.".config/skhd/follow_discord_popout.sh" = {
        force = true;
        executable = true;
        text = ''
          #!/bin/bash
          eval $(/opt/homebrew/bin/brew shellenv)

          WINDOW_ID=$(yabai -m query --windows | jq -r '
            sort_by(.id) | map(select((.app | ascii_downcase) == "discord")) as $wins |
            ($wins | map(select((((.title // "") | test(" - Discord$")) | not))) | .[0].id) //
            ($wins | .[1].id) //
            empty
          ')

          if [ -z "$WINDOW_ID" ]; then
              exit 0
          fi

          WINDOW_JSON=$(yabai -m query --windows --window "$WINDOW_ID")

          if [ "$(echo "$WINDOW_JSON" | jq -r '.["is-floating"]')" != "true" ]; then
              yabai -m window "$WINDOW_ID" --toggle float
          fi

          if [ "$(echo "$WINDOW_JSON" | jq -r '.["is-sticky"]')" != "true" ]; then
              yabai -m window "$WINDOW_ID" --toggle sticky
          fi

          if [ "$(echo "$WINDOW_JSON" | jq -r '.["is-topmost"]')" != "true" ]; then
              yabai -m window "$WINDOW_ID" --toggle topmost
          fi
        '';
      };

      home.file.".config/skhd/aerospace_watch_discord_popout_frame.sh" = {
        force = true;
        executable = true;
        text = ''
          #!/bin/bash
          FRAME_FILE="''${TMPDIR:-/tmp}/discord-popout-frame"
          LAST_FRAME=""

          while true; do
              FRAME=$(/usr/bin/osascript 2>/dev/null <<'APPLESCRIPT' || true
          tell application "Finder" to set screenBounds to bounds of window of desktop
          set screenW to item 3 of screenBounds
          set screenH to item 4 of screenBounds
          tell application "System Events"
            if not (exists process "Discord") then return ""
            tell process "Discord"
              repeat with w in windows
                if name of w does not end with " - Discord" then
                  set p to position of w
                  set s to size of w
                  return (item 1 of p as text) & "," & (item 2 of p as text) & "," & (item 1 of s as text) & "," & (item 2 of s as text) & "," & (screenW as text) & "," & (screenH as text)
                end if
              end repeat
            end tell
          end tell
          APPLESCRIPT
              )

              if echo "$FRAME" | grep -Eq '^[0-9-]+,[0-9-]+,[0-9]+,[0-9]+,[0-9]+,[0-9]+$'; then
                  IFS=, read -r X Y W H SW SH <<< "$FRAME"
                  if [ "$X" -lt $((SW - 80)) ] && [ "$Y" -lt $((SH - 80)) ]; then
                      GOOD_FRAME="$X,$Y,$W,$H"
                      if [ "$GOOD_FRAME" != "$LAST_FRAME" ]; then
                          printf '%s\n' "$GOOD_FRAME" > "$FRAME_FILE"
                          LAST_FRAME="$GOOD_FRAME"
                      fi
                  fi
              fi

              sleep 0.15
          done
        '';
      };

      home.file."Library/LaunchAgents/com.user.discord-popout-frame-watcher.plist" = mkIf (use "aerospace") {
        force = true;
        text = ''
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
            <key>Label</key>
            <string>com.user.discord-popout-frame-watcher</string>
            <key>ProgramArguments</key>
            <array>
              <string>/bin/bash</string>
              <string>/Users/${username}/.config/skhd/aerospace_watch_discord_popout_frame.sh</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
            <key>StandardOutPath</key>
            <string>/Users/${username}/Library/Logs/discord-popout-frame-watcher.log</string>
            <key>StandardErrorPath</key>
            <string>/Users/${username}/Library/Logs/discord-popout-frame-watcher.err</string>
          </dict>
          </plist>
        '';
      };

      home.file.".config/skhd/aerospace_follow_discord_popout.sh" = {
        force = true;
        executable = true;
        text = ''
          #!/bin/bash
          eval "$(/opt/homebrew/bin/brew shellenv)"

          # skhd + exec-on-workspace-change both invoke this. Always record the latest
          # target; the lock holder coalesces so rapid switches still follow.
          # Use mkdir locking — macOS has no flock(1).
          TARGET_FILE="''${TMPDIR:-/tmp}/aerospace-follow-discord.target"
          LOCK_DIR="''${TMPDIR:-/tmp}/aerospace-follow-discord.lockdir"
          FRAME_FILE="''${TMPDIR:-/tmp}/discord-popout-frame"

          HIDE_STATE="''${TMPDIR:-/tmp}/aerospace-follow-hidden"
          HIDDEN_WS="hidden"

          # fn-grave hide: do not drag the popout back onto the focused workspace.
          if [ -f "$HIDE_STATE" ] && grep -q '^kind=discord$' "$HIDE_STATE" 2>/dev/null; then
              exit 0
          fi

          REQUESTED="''${1:-$(aerospace list-workspaces --focused)}"
          if [ -z "$REQUESTED" ]; then
              exit 0
          fi
          # Never treat the hide scratch workspace as a follow destination.
          if [ "$REQUESTED" = "$HIDDEN_WS" ]; then
              exit 0
          fi
          printf '%s\n' "$REQUESTED" > "$TARGET_FILE"

          if ! mkdir "$LOCK_DIR" 2>/dev/null; then
              # Stale lock from a killed run: steal if older than 10s.
              LOCK_AGE=$(( $(date +%s) - $(stat -f %m "$LOCK_DIR" 2>/dev/null || echo 0) ))
              if [ "$LOCK_AGE" -gt 10 ]; then
                  rm -rf "$LOCK_DIR"
                  mkdir "$LOCK_DIR" 2>/dev/null || exit 0
              else
                  # Holder will re-read TARGET_FILE and move to the latest workspace.
                  exit 0
              fi
          fi
          trap 'rm -rf "$LOCK_DIR"' EXIT

          restore_frame() {
              local X="$1" Y="$2" W="$3" H="$4"
              /usr/bin/osascript >/dev/null 2>&1 <<APPLESCRIPT || true
          tell application "System Events"
            if not (exists process "Discord") then return
            tell process "Discord"
              repeat with w in windows
                if name of w does not end with " - Discord" then
                  set size of w to {$W, $H}
                  set position of w to {$X, $Y}
                  exit repeat
                end if
              end repeat
            end tell
          end tell
          APPLESCRIPT
          }

          while true; do
              if [ -f "$HIDE_STATE" ] && grep -q '^kind=discord$' "$HIDE_STATE" 2>/dev/null; then
                  break
              fi

              CURRENT_WORKSPACE=$(cat "$TARGET_FILE" 2>/dev/null || true)
              if [ -z "$CURRENT_WORKSPACE" ] || [ "$CURRENT_WORKSPACE" = "$HIDDEN_WS" ]; then
                  break
              fi

              # Only real popouts (titles that do not end with " - Discord"). Never fall
              # back to another Discord window — moving the main client snaps focus back.
              WINDOW_ID=$(aerospace list-windows --all --json | jq -r '
                map(select((."app-name" | ascii_downcase) == "discord"))
                | map(select(((."window-title" // "") | test(" - Discord$")) | not))
                | .[0]."window-id" // empty
              ')

              if [ -z "$WINDOW_ID" ]; then
                  NEW=$(cat "$TARGET_FILE" 2>/dev/null || true)
                  [ "$NEW" = "$CURRENT_WORKSPACE" ] && break
                  continue
              fi

              # Keep whatever was focused on the destination so Discord never steals focus.
              PREV_FOCUS=$(aerospace list-windows --focused --format '%{window-id}' 2>/dev/null || true)

              WINDOW_WORKSPACE=$(aerospace list-windows --all --format '%{window-id}|%{workspace}' | awk -F'|' -v id="$WINDOW_ID" '$1 == id { print $2; exit }')

              if [ -s "$FRAME_FILE" ]; then
                  DESIRED_FRAME=$(cat "$FRAME_FILE")
              else
                  DESIRED_FRAME="100,100,420,320"
              fi

              # Move first while the popout is unfocused. Floating it on the old workspace
              # activates Discord and AeroSpace follows back to that workspace.
              if [ "$WINDOW_WORKSPACE" != "$CURRENT_WORKSPACE" ]; then
                  aerospace move-node-to-workspace --window-id "$WINDOW_ID" "$CURRENT_WORKSPACE"
              fi
              aerospace layout --window-id "$WINDOW_ID" floating

              if echo "$DESIRED_FRAME" | grep -Eq '^[0-9-]+,[0-9-]+,[0-9]+,[0-9]+$'; then
                  IFS=, read -r X Y W H <<< "$DESIRED_FRAME"
                  restore_frame "$X" "$Y" "$W" "$H"
              fi

              NEW=$(cat "$TARGET_FILE" 2>/dev/null || true)
              # A newer switch arrived while we worked — loop and follow that instead.
              if [ "$NEW" != "$CURRENT_WORKSPACE" ]; then
                  continue
              fi

              # Pin destination + restore prior focus only if this is still the latest target.
              FOCUSED_NOW=$(aerospace list-workspaces --focused 2>/dev/null || true)
              if [ "$FOCUSED_NOW" != "$CURRENT_WORKSPACE" ]; then
                  aerospace workspace "$CURRENT_WORKSPACE"
              fi
              if [ -n "$PREV_FOCUS" ] && [ "$PREV_FOCUS" != "$WINDOW_ID" ]; then
                  aerospace focus --window-id "$PREV_FOCUS" 2>/dev/null || true
              fi

              NEW=$(cat "$TARGET_FILE" 2>/dev/null || true)
              [ "$NEW" = "$CURRENT_WORKSPACE" ] && break
          done
        '';
      };

      home.file.".config/skhd/aerospace_follow_facetime.sh" = {
        force = true;
        executable = true;
        text = ''
          #!/bin/bash
          eval $(/opt/homebrew/bin/brew shellenv)

          HIDE_STATE="''${TMPDIR:-/tmp}/aerospace-follow-hidden"
          HIDDEN_WS="hidden"

          # fn-grave hide: keep FaceTime on the scratch workspace until revealed.
          if [ -f "$HIDE_STATE" ] && grep -q '^kind=facetime$' "$HIDE_STATE" 2>/dev/null; then
              exit 0
          fi

          CURRENT_WORKSPACE="''${1:-$(aerospace list-workspaces --focused)}"
          if [ -z "$CURRENT_WORKSPACE" ] || [ "$CURRENT_WORKSPACE" = "$HIDDEN_WS" ]; then
              exit 0
          fi

          WINDOW_IDS=$(aerospace list-windows --all --format '%{window-id}|%{app-name}' | awk -F'|' 'tolower($2) == "facetime" { print $1 }')

          if [ -z "$WINDOW_IDS" ]; then
              exit 0
          fi

          echo "$WINDOW_IDS" | while read -r id; do
              if [ -n "$id" ]; then
                  aerospace layout --window-id "$id" floating
                  aerospace move-node-to-workspace --window-id "$id" "$CURRENT_WORKSPACE"
              fi
          done
        '';
      };

      home.file.".config/skhd/aerospace_toggle_follow_hide.sh" = mkIf (use "aerospace") {
        force = true;
        executable = true;
        text = ''
          #!/bin/bash
          eval "$(/opt/homebrew/bin/brew shellenv)"

          # fn-grave: park the active FaceTime / Discord popout on a scratch workspace
          # and leave it there until pressed again (follow scripts respect the state file).
          STATE_FILE="''${TMPDIR:-/tmp}/aerospace-follow-hidden"
          HIDDEN_WS="hidden"
          FRAME_FILE="''${TMPDIR:-/tmp}/discord-popout-frame"

          restore_discord_frame() {
              local X="$1" Y="$2" W="$3" H="$4"
              /usr/bin/osascript >/dev/null 2>&1 <<APPLESCRIPT || true
          tell application "System Events"
            if not (exists process "Discord") then return
            tell process "Discord"
              repeat with w in windows
                if name of w does not end with " - Discord" then
                  set size of w to {$W, $H}
                  set position of w to {$X, $Y}
                  exit repeat
                end if
              end repeat
            end tell
          end tell
          APPLESCRIPT
          }

          reveal_ids() {
              local kind="$1"
              local ids="$2"
              local current prev id
              current=$(aerospace list-workspaces --focused 2>/dev/null || true)
              if [ -z "$current" ] || [ "$current" = "$HIDDEN_WS" ]; then
                  return 0
              fi
              prev=$(aerospace list-windows --focused --format '%{window-id}' 2>/dev/null || true)

              for id in $ids; do
                  [ -n "$id" ] || continue
                  aerospace move-node-to-workspace --window-id "$id" "$current" 2>/dev/null || true
                  aerospace layout --window-id "$id" floating 2>/dev/null || true
              done

              if [ "$kind" = "discord" ]; then
                  if [ -s "$FRAME_FILE" ] && grep -Eq '^[0-9-]+,[0-9-]+,[0-9]+,[0-9]+$' "$FRAME_FILE"; then
                      IFS=, read -r X Y W H < "$FRAME_FILE"
                      restore_discord_frame "$X" "$Y" "$W" "$H"
                  fi
              fi

              if [ -n "$prev" ]; then
                  aerospace focus --window-id "$prev" 2>/dev/null || true
              fi
          }

          # Reveal if we have saved hide state, or anything parked on the scratch workspace.
          if [ -f "$STATE_FILE" ]; then
              KIND=$(awk -F= '/^kind=/{print $2; exit}' "$STATE_FILE")
              IDS=$(awk -F= '/^ids=/{print $2; exit}' "$STATE_FILE" | tr ',' ' ')
              rm -f "$STATE_FILE"
              reveal_ids "$KIND" "$IDS"
              exit 0
          fi

          PARKED=$(aerospace list-windows --workspace "$HIDDEN_WS" --format '%{window-id}|%{app-name}|%{window-title}' 2>/dev/null || true)
          if [ -n "$PARKED" ]; then
              FT_IDS=$(printf '%s\n' "$PARKED" | awk -F'|' 'tolower($2) == "facetime" { print $1 }' | tr '\n' ' ')
              DC_IDS=$(printf '%s\n' "$PARKED" | awk -F'|' '
                tolower($2) == "discord" && $3 !~ / - Discord$/ { print $1 }
              ' | tr '\n' ' ')
              if [ -n "$FT_IDS" ]; then
                  reveal_ids facetime "$FT_IDS"
              elif [ -n "$DC_IDS" ]; then
                  reveal_ids discord "$DC_IDS"
              fi
              exit 0
          fi

          FOCUSED_WS=$(aerospace list-workspaces --focused 2>/dev/null || true)
          [ -z "$FOCUSED_WS" ] && exit 0

          # Prefer FaceTime when present, else Discord popout. Prefer the focused workspace.
          FT_FOCUSED=$(aerospace list-windows --workspace "$FOCUSED_WS" --format '%{window-id}|%{app-name}' 2>/dev/null \
            | awk -F'|' 'tolower($2) == "facetime" { print $1 }' | tr '\n' ' ')
          FT_ANY=$(aerospace list-windows --all --format '%{window-id}|%{app-name}' 2>/dev/null \
            | awk -F'|' 'tolower($2) == "facetime" { print $1 }' | tr '\n' ' ')

          DC_ID=$(aerospace list-windows --all --json 2>/dev/null | jq -r '
            map(select((."app-name" | ascii_downcase) == "discord"))
            | map(select(((."window-title" // "") | test(" - Discord$")) | not))
            | .[0]."window-id" // empty
          ')

          KIND=""
          IDS=""
          if [ -n "$FT_FOCUSED" ]; then
              KIND=facetime
              IDS="$FT_FOCUSED"
          elif [ -n "$FT_ANY" ]; then
              KIND=facetime
              IDS="$FT_ANY"
          elif [ -n "$DC_ID" ]; then
              KIND=discord
              IDS="$DC_ID"
          else
              exit 0
          fi

          PREV_FOCUS=$(aerospace list-windows --focused --format '%{window-id}' 2>/dev/null || true)

          ID_CSV=$(echo "$IDS" | awk '{$1=$1; gsub(/ /,","); print}')
          {
              echo "kind=$KIND"
              echo "ids=$ID_CSV"
          } > "$STATE_FILE"

          for id in $IDS; do
              [ -n "$id" ] || continue
              aerospace move-node-to-workspace --window-id "$id" "$HIDDEN_WS" 2>/dev/null || true
          done

          # Stay on the current workspace; moving a window can steal focus.
          aerospace workspace "$FOCUSED_WS" 2>/dev/null || true
          if [ -n "$PREV_FOCUS" ]; then
              aerospace focus --window-id "$PREV_FOCUS" 2>/dev/null || true
          fi
        '';
      };

      home.file.".config/skhd/aerospace_reflow.sh" = {
        force = true;
        executable = true;
        text = ''
          #!/bin/bash
          eval $(/opt/homebrew/bin/brew shellenv)

          if ! command -v aerospace > /dev/null 2>&1; then
              exit 0
          fi

          sleep 0.2

          CURRENT_WORKSPACE=$(aerospace list-workspaces --focused 2>/dev/null || true)

          if [ -z "$CURRENT_WORKSPACE" ]; then
              exit 0
          fi

          aerospace flatten-workspace-tree --workspace "$CURRENT_WORKSPACE" 2>/dev/null || true
          aerospace balance-sizes --workspace "$CURRENT_WORKSPACE" 2>/dev/null || true
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

      home.file.".config/skhd/aerospace_reorganizer.sh" = {
        force = true;
        executable = true;
        text = ''
          #!/opt/homebrew/bin/bash
          eval $(/opt/homebrew/bin/brew shellenv)

          # App to workspace mappings
          declare -A app_workspaces=(
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

          # Function to check if a window ID exists
          window_exists() {
              local window_id=$1
              aerospace list-windows --all --format '%{window-id}' | grep -qx "$window_id"
              return $?
          }

          echo "Moving windows..."
          for app in "''${!app_workspaces[@]}"; do
              workspace="''${app_workspaces[$app]}"
              window_ids=$(aerospace list-windows --all --format '%{window-id}|%{app-name}' | awk -F'|' -v app="$app" '$2 ~ app { print $1 }')

              if [ ! -z "$window_ids" ]; then
                  echo "Processing $app -> Workspace $workspace"

                  echo "$window_ids" | while read -r id; do
                      if [ ! -z "$id" ] && window_exists "$id"; then
                          echo "Moving $app (ID: $id) to workspace $workspace"
                          aerospace move-node-to-workspace --window-id "$id" "$workspace"
                      fi
                  done
              fi
          done
        '';
      };
    };
  };
}
