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
  use = name: (cfg.enable && cfg.${name}.enable);

  aerospaceConfigPath = "/Users/${username}/.config/aerospace/aerospace.toml";

  # 0.21.3 fixes Wispr Flow's status popup being treated as a focusable window.
  aerospacePackage = pkgs.aerospace.overrideAttrs (_: rec {
    version = "0.21.3-Beta";
    src = pkgs.fetchzip {
      url = "https://github.com/nikitabobko/AeroSpace/releases/download/v${version}/AeroSpace-v${version}.zip";
      hash = "sha256-JHXtF3IKUbge7z2cMBi4L9IruiByNPCIKugLe4ymvys=";
    };
  });

  # Shared AeroSpace settings. Written to a user-writable path so the runtime
  # focus-follows-mouse helper can update it without editing the nix store.
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

    on-focus-changed = [
      "exec-and-forget ~/.config/skhd/aerospace_guard_cap_focus.sh"
    ];
    # Keep focus-follows-mouse from immediately returning to the previous monitor
    # after a keyboard-driven workspace switch.
    on-focused-monitor-changed = [
      "move-mouse monitor-lazy-center"
    ];
    # SKHD passes the requested workspace directly to the follower scripts. Running
    # them from this callback races AeroSpace's transiently empty window inventory.
    exec-on-workspace-change = [ ];

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
        "if".app-id = "com.apple.ScreenContinuity";
        run = "layout floating";
      }
      {
        "if".app-id = "com.wulkano.kap";
        run = "layout floating";
      }
      {
        "if".app-id = "so.cap.desktop";
        run = [
          "layout floating"
          "exec-and-forget sleep 0.2; eval $(/opt/homebrew/bin/brew shellenv); ~/.config/skhd/aerospace_follow_cap.sh"
        ];
      }
      # Pinned apps land on their fn-key workspace (no fn + shift binding needed).
      {
        "if".app-id = "com.cron.electron";
        run = "move-node-to-workspace 7";
      }
      {
        "if".app-id = "com.apple.Music";
        run = "move-node-to-workspace M";
      }
      {
        "if".app-id = "com.openai.codex";
        run = "move-node-to-workspace O";
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
    fn - 6 : yabai -m space --focus 6
    fn - c : yabai -m space --focus 7
    fn - v : yabai -m space --focus 8
    fn - f : yabai -m space --focus 9
    fn - 0 : yabai -m space --focus 10
    # Music gets its own space after 1-10.
    fn - m : yabai -m space --focus 11

    fn + shift - 1 : yabai -m window --space 1
    fn + shift - 2 : yabai -m window --space 2
    fn + shift - 3 : yabai -m window --space 3
    fn + shift - 4 : yabai -m window --space 4
    fn + shift - 5 : yabai -m window --space 5
    fn + shift - 6 : yabai -m window --space 6
    fn + shift - 7 : yabai -m window --space 7
    fn + shift - 8 : yabai -m window --space 8
    fn + shift - 9 : yabai -m window --space 9
    fn + shift - 0 : yabai -m window --space 10
    fn + shift - m : yabai -m window --space 11

    fn + shift - k : yabai -m window --warp north
    fn + shift - h : yabai -m window --warp west
    fn + shift - l : yabai -m window --warp east
    fn + shift - j : yabai -m window --warp south

    fn - j : yabai -m window --focus south
    fn - h : yabai -m window --focus west
    fn - l : yabai -m window --focus east
    fn - k : yabai -m window --focus north

    fn - g : ~/.config/skhd/reorganizer.sh

    fn + shift - d : /bin/sh -c 'eval $(/opt/homebrew/bin/brew shellenv) && yabai -m query --spaces --display | jq -re "map(select(.\"is-native-fullscreen\" == false)) | length > 1" && yabai -m query --spaces | jq -re "map(select(.\"windows\" == [] and .\"has-focus\" == false).index) | reverse | .[]" | xargs -I % sh -c "yabai -m space % --destroy"'

    fn - y : eval $(/opt/homebrew/bin/brew shellenv) && if [ "$(yabai -m config focus_follows_mouse)" = "autoraise" ]; then yabai -m config focus_follows_mouse off; else yabai -m config focus_follows_mouse autoraise; fi

    # fn - t : osascript -e 'tell application "System Events" to keystroke "t" using {command down, option down, shift down, control down}' && echo 'tapped'

    fn - r : ~/.config/skhd/focus_messages.sh
  '';

  aerospaceSkhdConfig = ''
    # -------- AeroSpace shortcuts --------

    # Switch immediately; the wrapper moves follow windows off the hot path.
    fn - 1 : ~/.config/skhd/aerospace_switch_workspace.sh 1
    fn - 2 : ~/.config/skhd/aerospace_switch_workspace.sh 2
    fn - 3 : ~/.config/skhd/aerospace_switch_workspace.sh 3
    fn - 4 : ~/.config/skhd/aerospace_switch_workspace.sh 4
    fn - 5 : ~/.config/skhd/aerospace_switch_workspace.sh 5
    fn - 6 : ~/.config/skhd/aerospace_switch_workspace.sh 6
    fn - c : ~/.config/skhd/aerospace_switch_workspace.sh 7
    fn - v : ~/.config/skhd/aerospace_switch_workspace.sh 8
    fn - f : ~/.config/skhd/aerospace_switch_workspace.sh 9
    fn - 0 : ~/.config/skhd/aerospace_switch_workspace.sh 10
    # Music and ChatGPT get their own named workspaces.
    fn - m : ~/.config/skhd/aerospace_switch_workspace.sh M
    fn - o : ~/.config/skhd/aerospace_switch_workspace.sh O

    fn + shift - 1 : eval $(/opt/homebrew/bin/brew shellenv) && aerospace move-node-to-workspace 1
    fn + shift - 2 : eval $(/opt/homebrew/bin/brew shellenv) && aerospace move-node-to-workspace 2
    fn + shift - 3 : eval $(/opt/homebrew/bin/brew shellenv) && aerospace move-node-to-workspace 3
    fn + shift - 4 : eval $(/opt/homebrew/bin/brew shellenv) && aerospace move-node-to-workspace 4
    fn + shift - 5 : eval $(/opt/homebrew/bin/brew shellenv) && aerospace move-node-to-workspace 5
    fn + shift - 6 : eval $(/opt/homebrew/bin/brew shellenv) && aerospace move-node-to-workspace 6
    fn + shift - v : eval $(/opt/homebrew/bin/brew shellenv) && aerospace move-node-to-workspace 8
    fn + shift - f : eval $(/opt/homebrew/bin/brew shellenv) && aerospace move-node-to-workspace 9
    fn + shift - 0 : eval $(/opt/homebrew/bin/brew shellenv) && aerospace move-node-to-workspace 10

    fn + shift - k : eval $(/opt/homebrew/bin/brew shellenv) && aerospace move up
    fn + shift - h : eval $(/opt/homebrew/bin/brew shellenv) && aerospace move left
    fn + shift - l : eval $(/opt/homebrew/bin/brew shellenv) && aerospace move right
    fn + shift - j : eval $(/opt/homebrew/bin/brew shellenv) && aerospace move down

    fn - j : eval $(/opt/homebrew/bin/brew shellenv) && aerospace focus down
    fn - h : eval $(/opt/homebrew/bin/brew shellenv) && aerospace focus left
    fn - l : eval $(/opt/homebrew/bin/brew shellenv) && aerospace focus right
    fn - k : eval $(/opt/homebrew/bin/brew shellenv) && aerospace focus up

    fn - g : ~/.config/skhd/aerospace_reorganizer.sh

    # AeroSpace workspaces are dynamic; there is no empty-space cleanup equivalent.
    fn + shift - d : true

    # Toggle iPhone Mirroring on the focused workspace.
    fn - t : ${
      config.home-manager.users.${username}.home.file.".config/skhd/aerospace_toggle_iphone_mirroring.sh".source
    }

    # Toggle automatic focus without colliding with iPhone Mirroring.
    fn - y : ~/.config/skhd/aerospace_toggle_ffm.sh

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

    # Re-read /etc/skhdrc after nix-darwin swaps its symlink target.
    system.activationScripts.postActivation.text = mkIf (use "skhd") (mkAfter ''
      skhd_uid=$(/usr/bin/id -u ${escapeShellArg username})
      /usr/bin/pkill -USR1 -u "$skhd_uid" -x skhd >/dev/null 2>&1 || true
    '');

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
      package = aerospacePackage;
      settings = aerospaceSettings;
    };

    # Prefer a user-writable config so runtime helpers can update it and reload.
    # Seed the file here in case home-manager activation has not run yet.
    launchd.user.agents.aerospace = mkIf (use "aerospace") {
      command = mkForce (
        pkgs.writeShellScript "aerospace-with-writable-config" ''
          set -euo pipefail
          mkdir -p /Users/${username}/.config/aerospace
          if [ ! -f ${aerospaceConfigPath} ]; then
            cp ${aerospaceToml} ${aerospaceConfigPath}
            chmod u+w ${aerospaceConfigPath}
          fi
          exec ${config.services.aerospace.package}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace --config-path ${aerospaceConfigPath}
        ''
      );
    };

    # Submodule so we get home-manager's lib (lib.hm), not nix-darwin's.
    home-manager.users.${username} = { lib, ... }: {
      # Writable copy (not a store symlink) for runtime configuration helpers.
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
            /usr/bin/sed -i "" '/^\[focus-follows-mouse\]/,/^\[/{s/^enabled = true/enabled = false/;}' "$HOME/.config/aerospace/aerospace.toml"
            /usr/bin/sed -i "" -E 's/^(focus-follows-mouse\.enabled[[:space:]]*=[[:space:]]*)true/\1false/' "$HOME/.config/aerospace/aerospace.toml"
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
              /usr/bin/sed -i "" -E 's/^(focus-follows-mouse\.enabled[[:space:]]*=[[:space:]]*)true/\1false/' "$CONFIG"
              /usr/bin/sed -i "" '/^\[focus-follows-mouse\]/,/^\[/{s/^enabled = true/enabled = false/;}' "$CONFIG"
              echo false > "$STATE"
          else
              /usr/bin/sed -i "" -E 's/^(focus-follows-mouse\.enabled[[:space:]]*=[[:space:]]*)false/\1true/' "$CONFIG"
              /usr/bin/sed -i "" '/^\[focus-follows-mouse\]/,/^\[/{s/^enabled = false/enabled = true/;}' "$CONFIG"
              if ! grep -qE '^focus-follows-mouse\.enabled[[:space:]]*=' "$CONFIG" \
                  && ! /usr/bin/awk '/^\[focus-follows-mouse\]/{found=1} END{exit !found}' "$CONFIG"; then
                  printf '\nfocus-follows-mouse.enabled = true\n' >> "$CONFIG"
              fi
              echo true > "$STATE"
          fi

          aerospace reload-config --no-gui
        '';
      };

      home.file.".config/skhd/aerospace_guard_cap_focus.sh" = mkIf (use "aerospace") {
        force = true;
        executable = true;
        text = ''
          #!/bin/bash
          # Let Cap receive deliberate clicks, but undo same-workspace focus-follows-mouse raises.
          eval "$(/opt/homebrew/bin/brew shellenv)"

          PREVIOUS_FILE="''${TMPDIR:-/tmp}/aerospace-cap-previous-focus"
          WINDOW_ID="''${AEROSPACE_WINDOW_ID:-}"
          [ -n "$WINDOW_ID" ] || exit 0

          APP_ID=$(aerospace list-windows --all --format '%{window-id}|%{app-bundle-id}' 2>/dev/null \
              | awk -F'|' -v id="$WINDOW_ID" '$1 == id { print $2; exit }')

          if [ "$APP_ID" != "so.cap.desktop" ]; then
              printf '%s\n' "$WINDOW_ID" > "$PREVIOUS_FILE"
              exit 0
          fi

          CLICKING=$(/usr/bin/osascript -l JavaScript <<'JXA' 2>/dev/null || true
          ObjC.import("ApplicationServices");
          const source = $.kCGEventSourceStateCombinedSessionState;
          ($.CGEventSourceButtonState(source, 0) || $.CGEventSourceButtonState(source, 1)) ? "true" : "false";
          JXA
          )
          [ "$CLICKING" = "true" ] && exit 0

          PREVIOUS=$(cat "$PREVIOUS_FILE" 2>/dev/null || true)
          [ -n "$PREVIOUS" ] || exit 0

          CURRENT_WORKSPACE=$(aerospace list-windows --all --format '%{window-id}|%{workspace}' 2>/dev/null \
              | awk -F'|' -v id="$WINDOW_ID" '$1 == id { print $2; exit }')
          PREVIOUS_WORKSPACE=$(aerospace list-windows --all --format '%{window-id}|%{workspace}' 2>/dev/null \
              | awk -F'|' -v id="$PREVIOUS" '$1 == id { print $2; exit }')
          [ -n "$CURRENT_WORKSPACE" ] && [ "$PREVIOUS_WORKSPACE" = "$CURRENT_WORKSPACE" ] || exit 0

          aerospace focus --window-id "$PREVIOUS" 2>/dev/null || true
        '';
      };

      home.file.".config/skhd/aerospace_toggle_iphone_mirroring.sh" = mkIf (use "aerospace") {
        force = true;
        executable = true;
        text = ''
          #!/bin/bash
          # Hide iPhone Mirroring when focused; otherwise reveal it on this workspace.
          eval $(/opt/homebrew/bin/brew shellenv)

          APP_ID="com.apple.ScreenContinuity"

          FRONTMOST=$(/usr/bin/osascript <<'APPLESCRIPT' 2>/dev/null || true
          tell application "System Events"
              set matches to every application process whose bundle identifier is "com.apple.ScreenContinuity"
              if (count of matches) is 0 then return false
              set appProcess to item 1 of matches
              return (visible of appProcess) and (frontmost of appProcess)
          end tell
          APPLESCRIPT
          )

          if [ "$FRONTMOST" = "true" ]; then
              /usr/bin/osascript <<'APPLESCRIPT' >/dev/null 2>&1
          tell application "System Events" to set visible of first application process whose bundle identifier is "com.apple.ScreenContinuity" to false
          APPLESCRIPT
              exit 0
          fi

          CURRENT_WORKSPACE=$(aerospace list-workspaces --focused 2>/dev/null || true)
          MONITOR_NAME=$(aerospace list-monitors --focused --format '%{monitor-name}' 2>/dev/null || true)
          [ -n "$CURRENT_WORKSPACE" ] || exit 1

          /usr/bin/open -g -b "$APP_ID"
          /usr/bin/osascript <<'APPLESCRIPT' >/dev/null 2>&1 || true
          tell application "System Events"
              set matches to every application process whose bundle identifier is "com.apple.ScreenContinuity"
              if (count of matches) > 0 then
                  set appProcess to item 1 of matches
                  set visible of appProcess to true
                  repeat with appWindow in windows of appProcess
                      try
                          set value of attribute "AXMinimized" of appWindow to false
                      end try
                  end repeat
              end if
          end tell
          APPLESCRIPT

          WINDOW_ID=""
          for _ in {1..50}; do
              WINDOW_ID=$(aerospace list-windows --all --format '%{window-id}|%{app-bundle-id}' 2>/dev/null \
                  | awk -F'|' -v app="$APP_ID" '$2 == app { print $1; exit }')
              [ -n "$WINDOW_ID" ] && break
              sleep 0.1
          done

          if [ -z "$WINDOW_ID" ]; then
              /usr/bin/osascript -e 'tell application "iPhone Mirroring" to activate' >/dev/null 2>&1 || true
              exit 1
          fi

          aerospace move-node-to-workspace --window-id "$WINDOW_ID" "$CURRENT_WORKSPACE" 2>/dev/null || true
          aerospace layout --window-id "$WINDOW_ID" floating 2>/dev/null || true
          aerospace workspace "$CURRENT_WORKSPACE" 2>/dev/null || true

          /usr/bin/osascript -l JavaScript - "$APP_ID" "$MONITOR_NAME" <<'JXA' >/dev/null 2>&1 || true
          ObjC.import("AppKit");

          function run(argv) {
              const appId = argv[0];
              const monitorName = argv[1];
              const systemEvents = Application("System Events");
              const processes = systemEvents.applicationProcesses.whose({ bundleIdentifier: appId })();
              if (processes.length === 0) return;

              const windows = processes[0].windows();
              if (windows.length === 0) return;

              const screens = $.NSScreen.screens.js;
              const screen = screens.find(candidate => candidate.localizedName.js === monitorName) || screens[0];
              const frame = screen.visibleFrame;
              const mainScreenHeight = Number(screens[0].frame.size.height);
              const size = windows[0].size();
              const x = Number(frame.origin.x) + (Number(frame.size.width) - size[0]) / 2;
              const top = mainScreenHeight - Number(frame.origin.y) - Number(frame.size.height);
              const y = top + (Number(frame.size.height) - size[1]) / 2;

              windows[0].position = [Math.round(x), Math.round(y)];
          }
          JXA

          aerospace focus --window-id "$WINDOW_ID" 2>/dev/null || true
          /usr/bin/osascript -e 'tell application "System Events" to set frontmost of first application process whose bundle identifier is "com.apple.ScreenContinuity" to true' >/dev/null 2>&1 || true
          aerospace move-mouse monitor-force-center 2>/dev/null || true
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
          FRAME_FILE="/Users/${username}/Library/Caches/aerospace-discord-popout-frame"
          SWITCH_TARGET_FILE="/Users/${username}/Library/Caches/aerospace-switch-workspace.target"
          LAST_FRAME=$(cat "$FRAME_FILE" 2>/dev/null || true)

          while true; do
              WINDOW_ID=$(/run/current-system/sw/bin/aerospace list-windows --all --json 2>/dev/null \
                  | /run/current-system/sw/bin/jq -r '
                    map(select((."app-name" | ascii_downcase) == "discord"))
                    | map(select(((."window-title" // "") | test(" - Discord$")) | not))
                    | .[0]."window-id" // empty
                  ')

              SAMPLE=$(/usr/bin/osascript -l JavaScript - "$WINDOW_ID" <<'JXA' 2>/dev/null || true
          ObjC.import("ApplicationServices");
          ObjC.import("CoreGraphics");

          function run(argv) {
            if (argv.length === 0 || argv[0] === "") return "";
            const windowId = Number(argv[0]);
            const windowList = ObjC.castRefToObject(
              $.CGWindowListCopyWindowInfo($.kCGWindowListOptionAll, $.kCGNullWindowID)
            );

            for (let index = 0; index < windowList.count; index++) {
              const info = ObjC.deepUnwrap(windowList.objectAtIndex(index));
              if (Number(info.kCGWindowNumber) !== windowId) continue;
              const bounds = info.kCGWindowBounds;
              const dragAge = Number(
                $.CGEventSourceSecondsSinceLastEventType($.kCGEventSourceStateCombinedSessionState, 6)
              );
              return `''${bounds.X},''${bounds.Y},''${bounds.Width},''${bounds.Height}|''${dragAge}`;
            }
            return "";
          }
          JXA
              )
              FRAME="''${SAMPLE%%|*}"
              DRAG_AGE="''${SAMPLE#*|}"

              SWITCHING=false
              if [ -f "$SWITCH_TARGET_FILE" ]; then
                  SWITCH_AGE=$(( $(date +%s) - $(stat -f %m "$SWITCH_TARGET_FILE" 2>/dev/null || echo 0) ))
                  [ "$SWITCH_AGE" -le 10 ] && SWITCHING=true
              fi

              # A recent drag is the only event allowed to redefine the pinned frame.
              # The switch target exists before AeroSpace exposes transient coordinates.
              if [ "$SWITCHING" = false ] \
                  && echo "$FRAME" | grep -Eq '^[0-9-]+,[0-9-]+,[0-9]+,[0-9]+$' \
                  && [ "$FRAME" != "$LAST_FRAME" ] \
                  && echo "$DRAG_AGE" | awk '$1 >= 0 && $1 <= 5 { found=1 } END { exit !found }'; then
                  FRAME_TMP="$FRAME_FILE.$$.$RANDOM"
                  if printf '%s\n' "$FRAME" > "$FRAME_TMP" && mv -f "$FRAME_TMP" "$FRAME_FILE"; then
                      LAST_FRAME="$FRAME"
                  fi
              fi

              sleep 0.1
          done
        '';
      };

      launchd.agents.discord-popout-frame-watcher = mkIf (use "aerospace") {
        enable = true;
        config = {
          ProgramArguments = [
            "/bin/bash"
            "${config.home-manager.users.${username}.home.file.".config/skhd/aerospace_watch_discord_popout_frame.sh".source
            }"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/Users/${username}/Library/Logs/discord-popout-frame-watcher.log";
          StandardErrorPath = "/Users/${username}/Library/Logs/discord-popout-frame-watcher.err";
        };
      };

      home.file.".config/skhd/aerospace_switch_workspace.sh" = mkIf (use "aerospace") {
        force = true;
        executable = true;
        text = ''
          #!/bin/bash

          REQUESTED="''${1:-}"
          [ -n "$REQUESTED" ] || exit 0

          TARGET_FILE="/Users/${username}/Library/Caches/aerospace-switch-workspace.target"
          TARGET_TMP="$TARGET_FILE.$$.$RANDOM"
          printf '%s\n' "$REQUESTED" > "$TARGET_TMP" || exit 0
          mv -f "$TARGET_TMP" "$TARGET_FILE" || exit 0

          # Avoid brew shellenv startup and the old 30 ms debounce on the critical path.
          aerospace workspace "$REQUESTED" 2>/dev/null || exit 0

          # Following auxiliary windows can involve several AeroSpace queries and
          # AppleScript. Run it after the visible switch so SKHD is immediately ready
          # for another keypress. Each stage checks that this is still the newest switch.
          (
              ~/.config/skhd/aerospace_follow_facetime.sh "$REQUESTED"

              LATEST=$(cat "$TARGET_FILE" 2>/dev/null || true)
              [ "$LATEST" = "$REQUESTED" ] || exit 0
              ~/.config/skhd/aerospace_follow_cap.sh "$REQUESTED"

              LATEST=$(cat "$TARGET_FILE" 2>/dev/null || true)
              [ "$LATEST" = "$REQUESTED" ] || exit 0
              ~/.config/skhd/aerospace_follow_discord_popout.sh "$REQUESTED"

              LATEST=$(cat "$TARGET_FILE" 2>/dev/null || true)
              [ "$LATEST" = "$REQUESTED" ] || exit 0
              aerospace workspace "$REQUESTED" 2>/dev/null || true

              LATEST=$(cat "$TARGET_FILE" 2>/dev/null || true)
              [ "$LATEST" != "$REQUESTED" ] || rm -f "$TARGET_FILE"
          ) >/dev/null 2>&1 &
        '';
      };

      home.file.".config/skhd/aerospace_follow_cap.sh" = mkIf (use "aerospace") {
        force = true;
        executable = true;
        text = ''
          #!/bin/bash
          eval "$(/opt/homebrew/bin/brew shellenv)"

          HIDDEN_WS="hidden"
          SWITCH_TARGET_FILE="/Users/${username}/Library/Caches/aerospace-switch-workspace.target"

          CURRENT_WORKSPACE="''${1:-$(aerospace list-workspaces --focused)}"
          sleep 0.08
          SWITCH_TARGET=$(cat "$SWITCH_TARGET_FILE" 2>/dev/null || true)
          if [ -n "$SWITCH_TARGET" ]; then
              CURRENT_WORKSPACE="$SWITCH_TARGET"
          fi
          if [ -z "$CURRENT_WORKSPACE" ] || [ "$CURRENT_WORKSPACE" = "$HIDDEN_WS" ]; then
              exit 0
          fi

          WINDOW_IDS=$(aerospace list-windows --all --format '%{window-id}|%{app-bundle-id}' \
              | awk -F'|' '$2 == "so.cap.desktop" { print $1 }')
          [ -n "$WINDOW_IDS" ] || exit 0

          PREV_FOCUS=$(aerospace list-windows --focused --format '%{window-id}' 2>/dev/null || true)
          PREV_FOCUS_WORKSPACE=$(aerospace list-windows --all --format '%{window-id}|%{workspace}' \
              | awk -F'|' -v id="$PREV_FOCUS" '$1 == id { print $2; exit }')

          echo "$WINDOW_IDS" | while read -r id; do
              [ -n "$id" ] || continue
              WINDOW_WORKSPACE=$(aerospace list-windows --all --format '%{window-id}|%{workspace}' \
                  | awk -F'|' -v window_id="$id" '$1 == window_id { print $2; exit }')
              if [ "$WINDOW_WORKSPACE" != "$CURRENT_WORKSPACE" ]; then
                  aerospace move-node-to-workspace --window-id "$id" "$CURRENT_WORKSPACE"
              fi
              aerospace layout --window-id "$id" floating
          done

          FOCUSED_NOW=$(aerospace list-workspaces --focused 2>/dev/null || true)
          if [ "$FOCUSED_NOW" != "$CURRENT_WORKSPACE" ]; then
              aerospace workspace "$CURRENT_WORKSPACE"
          fi
          if [ -n "$PREV_FOCUS" ] && [ "$PREV_FOCUS_WORKSPACE" = "$CURRENT_WORKSPACE" ]; then
              aerospace focus --window-id "$PREV_FOCUS" 2>/dev/null || true
          fi
        '';
      };

      home.file.".config/skhd/aerospace_follow_discord_popout.sh" = {
        force = true;
        executable = true;
        text = ''
          #!/bin/bash
          eval "$(/opt/homebrew/bin/brew shellenv)"

          # SKHD switches and window-detected hooks can overlap. Always record the latest
          # target; the lock holder coalesces so rapid switches still follow.
          # Use mkdir locking — macOS has no flock(1).
          TARGET_FILE="/Users/${username}/Library/Caches/aerospace-follow-discord.target"
          LOCK_DIR="/Users/${username}/Library/Caches/aerospace-follow-discord.lockdir"
          FRAME_FILE="/Users/${username}/Library/Caches/aerospace-discord-popout-frame"
          SWITCH_TARGET_FILE="/Users/${username}/Library/Caches/aerospace-switch-workspace.target"

          HIDE_STATE="/Users/${username}/Library/Caches/aerospace-follow-hidden"
          HIDDEN_WS="hidden"
          WINDOW_DETECTED=false
          [ "$#" -eq 0 ] && WINDOW_DETECTED=true

          # fn-grave hide: do not drag the popout back onto the focused workspace.
          if [ -f "$HIDE_STATE" ] && grep -q '^kind=discord$' "$HIDE_STATE" 2>/dev/null; then
              exit 0
          fi

          REQUESTED="''${1:-$(aerospace list-workspaces --focused)}"
          SWITCH_TARGET=$(cat "$SWITCH_TARGET_FILE" 2>/dev/null || true)
          if [ -n "$SWITCH_TARGET" ]; then
              REQUESTED="$SWITCH_TARGET"
          fi
          if [ -z "$REQUESTED" ]; then
              exit 0
          fi
          # Never treat the hide scratch workspace as a follow destination.
          if [ "$REQUESTED" = "$HIDDEN_WS" ]; then
              exit 0
          fi
          # Publish without exposing a truncated target to the active worker.
          publish_target() {
              local VALUE="$1"
              local TARGET_TMP="$TARGET_FILE.$$.$RANDOM"
              if ! printf '%s\n' "$VALUE" > "$TARGET_TMP" || ! mv -f "$TARGET_TMP" "$TARGET_FILE"; then
                  rm -f "$TARGET_TMP"
                  return 1
              fi
          }

          publish_target "$REQUESTED" || exit 0

          # Wait for the current worker instead of assuming it will observe a target
          # published during its final read/lock-release window.
          LOCK_OWNER="$LOCK_DIR/owner"
          while ! mkdir "$LOCK_DIR" 2>/dev/null; do
              # Older queued invocations can leave once a newer target supersedes them.
              LATEST=$(cat "$TARGET_FILE" 2>/dev/null || true)
              if [ "$LATEST" != "$REQUESTED" ]; then
                  exit 0
              fi

              OWNER=$(cat "$LOCK_OWNER" 2>/dev/null || true)
              if echo "$OWNER" | grep -Eq '^[0-9]+$' && kill -0 "$OWNER" 2>/dev/null; then
                  sleep 0.05
                  continue
              fi

              # A newly created lock may not have its owner file yet. Only reclaim an
              # ownerless lock after a grace period; dead recorded owners are safe now.
              LOCK_AGE=$(( $(date +%s) - $(stat -f %m "$LOCK_DIR" 2>/dev/null || echo 0) ))
              if [ -z "$OWNER" ] && [ "$LOCK_AGE" -le 2 ]; then
                  sleep 0.05
                  continue
              fi

              STALE_LOCK="$LOCK_DIR.stale.$$.$RANDOM"
              if mv "$LOCK_DIR" "$STALE_LOCK" 2>/dev/null; then
                  rm -rf "$STALE_LOCK"
              else
                  sleep 0.05
              fi
          done
          printf '%s\n' "$$" > "$LOCK_OWNER"

          cleanup_lock() {
              OWNER=$(cat "$LOCK_OWNER" 2>/dev/null || true)
              if [ "$OWNER" = "$$" ]; then
                  rm -rf "$LOCK_DIR"
              fi
          }
          trap cleanup_lock EXIT

          # Collapse bursts before taking focus/frame snapshots and moving the popout.
          sleep 0.08

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

          hold_frame_until_settled() {
              local X="$1" Y="$2" W="$3" H="$4"
              /usr/bin/osascript >/dev/null 2>&1 <<APPLESCRIPT || true
          tell application "System Events"
            if not (exists process "Discord") then return
            tell process "Discord"
              repeat 20 times
                repeat with w in windows
                  if name of w does not end with " - Discord" then
                    set size of w to {$W, $H}
                    set position of w to {$X, $Y}
                    exit repeat
                  end if
                end repeat
                delay 0.15
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

              # Follow only a secondary/popout Discord window. The main client title
              # ends in " - Discord" and must remain on its assigned workspace.
              # AeroSpace can briefly report an empty window list from inside its
              # workspace-change callback. Retry long enough for its inventory to settle.
              WINDOW_ID=""
              for _ in 1 2 3 4 5; do
                  WINDOW_ID=$(aerospace list-windows --all --json | jq -r '
                    map(select((."app-name" | ascii_downcase) == "discord"))
                    | map(select(((."window-title" // "") | test(" - Discord$")) | not))
                    | .[0]."window-id" // empty
                  ')
                  [ -n "$WINDOW_ID" ] && break
                  sleep 0.1
              done

              if [ -z "$WINDOW_ID" ]; then
                  NEW=$(cat "$TARGET_FILE" 2>/dev/null || true)
                  [ "$NEW" = "$CURRENT_WORKSPACE" ] && break
                  continue
              fi

              # Keep whatever was focused on the destination so Discord never steals focus.
              PREV_FOCUS=$(aerospace list-windows --focused --format '%{window-id}' 2>/dev/null || true)
              PREV_FOCUS_WORKSPACE=$(aerospace list-windows --all --format '%{window-id}|%{workspace}' \
                  | awk -F'|' -v id="$PREV_FOCUS" '$1 == id { print $2; exit }')

              WINDOW_WORKSPACE=$(aerospace list-windows --all --format '%{window-id}|%{workspace}' | awk -F'|' -v id="$WINDOW_ID" '$1 == id { print $2; exit }')

              # The saved frame is authoritative. AeroSpace and Discord both expose
              # transient coordinates while a floating popout changes workspaces.
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
                  # Discord applies its own bottom-right placement after creating an
                  # Electron popout. Hold the saved frame until that startup settles.
                  if [ "$WINDOW_DETECTED" = true ]; then
                      hold_frame_until_settled "$X" "$Y" "$W" "$H"
                  fi
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

              NEW=$(cat "$TARGET_FILE" 2>/dev/null || true)
              if [ "$NEW" != "$CURRENT_WORKSPACE" ]; then
                  continue
              fi

              if [ -n "$PREV_FOCUS" ] \
                  && [ "$PREV_FOCUS" != "$WINDOW_ID" ] \
                  && [ "$PREV_FOCUS_WORKSPACE" = "$CURRENT_WORKSPACE" ]; then
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
          eval "$(/opt/homebrew/bin/brew shellenv)"

          HIDE_STATE="/Users/${username}/Library/Caches/aerospace-follow-hidden"
          HIDDEN_WS="hidden"
          SWITCH_TARGET_FILE="/Users/${username}/Library/Caches/aerospace-switch-workspace.target"

          # fn-grave hide: keep FaceTime on the scratch workspace until revealed.
          if [ -f "$HIDE_STATE" ] && grep -q '^kind=facetime$' "$HIDE_STATE" 2>/dev/null; then
              exit 0
          fi

          # Debounce without replacing the explicit event target with a potentially
          # unrelated workspace focused by another monitor or focus-follows-mouse.
          CURRENT_WORKSPACE="''${1:-$(aerospace list-workspaces --focused)}"
          sleep 0.08
          SWITCH_TARGET=$(cat "$SWITCH_TARGET_FILE" 2>/dev/null || true)
          if [ -n "$SWITCH_TARGET" ]; then
              CURRENT_WORKSPACE="$SWITCH_TARGET"
          fi
          if [ -z "$CURRENT_WORKSPACE" ] || [ "$CURRENT_WORKSPACE" = "$HIDDEN_WS" ]; then
              exit 0
          fi

          WINDOW_IDS=$(aerospace list-windows --all --format '%{window-id}|%{app-name}' | awk -F'|' 'tolower($2) == "facetime" { print $1 }')

          if [ -z "$WINDOW_IDS" ]; then
              exit 0
          fi

          PREV_FOCUS=$(aerospace list-windows --focused --format '%{window-id}' 2>/dev/null || true)
          PREV_FOCUS_WORKSPACE=$(aerospace list-windows --all --format '%{window-id}|%{workspace}' \
              | awk -F'|' -v id="$PREV_FOCUS" '$1 == id { print $2; exit }')

          echo "$WINDOW_IDS" | while read -r id; do
              if [ -n "$id" ]; then
                  WINDOW_WORKSPACE=$(aerospace list-windows --all --format '%{window-id}|%{workspace}' \
                      | awk -F'|' -v window_id="$id" '$1 == window_id { print $2; exit }')
                  if [ "$WINDOW_WORKSPACE" != "$CURRENT_WORKSPACE" ]; then
                      aerospace move-node-to-workspace --window-id "$id" "$CURRENT_WORKSPACE"
                  fi
                  aerospace layout --window-id "$id" floating
              fi
          done

          FOCUSED_NOW=$(aerospace list-workspaces --focused 2>/dev/null || true)
          if [ "$FOCUSED_NOW" != "$CURRENT_WORKSPACE" ]; then
              aerospace workspace "$CURRENT_WORKSPACE"
          fi
          if [ -n "$PREV_FOCUS" ] && [ "$PREV_FOCUS_WORKSPACE" = "$CURRENT_WORKSPACE" ]; then
              aerospace focus --window-id "$PREV_FOCUS" 2>/dev/null || true
          fi
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
          STATE_FILE="/Users/${username}/Library/Caches/aerospace-follow-hidden"
          HIDDEN_WS="hidden"
          FRAME_FILE="/Users/${username}/Library/Caches/aerospace-discord-popout-frame"

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
              ["Spotify"]=11
              ["Music"]=11
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
              ["Spotify"]=M
              ["Music"]=M
              ["Notion Calendar"]=7
              ["ChatGPT"]=O
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
