{ config, lib, pkgs, ... }: 
with lib;
let
  cfg = config.hyprland;
in
{
  options = {
    hyprland = {
      enable = lib.mkEnableOption "Is Hyperland enabled";
      useWaybar = lib.mkEnableOption "Use Waybar";
      useWofi = lib.mkEnableOption "Use Wofi";  
      useHyprPaper = lib.mkEnableOption "Use HyprPaper";
      useHyprlock = lib.mkEnableOption "Use Hyprlock";
      useScreenshots = lib.mkEnableOption "Use Screenshots";
      autoLayout = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Hyprland Auto Layout Script";
      };
      defaultSession = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Should Hyprland Be Default";
      };
    };
  };
  config = mkIf cfg.enable (lib.mkMerge [
    {
      programs.hyprland.enable = cfg.enable;

      environment.systemPackages = [
        pkgs.swaynotificationcenter
        pkgs.xwaylandvideobridge
        pkgs.kdePackages.qtstyleplugin-kvantum
        (mkIf cfg.useWaybar pkgs.waybar)
        (mkIf cfg.useWofi pkgs.wofi)
        (mkIf cfg.useHyprPaper pkgs.hyprpaper)
        (mkIf cfg.useHyprlock pkgs.hyprlock)
        (mkIf cfg.useHyprlock pkgs.hypridle)
        (mkIf cfg.useScreenshots pkgs.hyprshot)
      ];
      qt.enable = true;
    }

    (lib.mkIf cfg.defaultSession {
      services.displayManager.defaultSession = "hyprland";
    })

    (lib.mkIf cfg.autoLayout {
      environment.systemPackages = [
        pkgs.jq
        (pkgs.writeShellScriptBin "hypr-layout" ''
          # Function to move windows by class to a specified workspace
          move_windows_to_workspace() {
            local WINDOW_CLASS=$1
            local WORKSPACE_ID=$2

            # Get the PIDs of windows with the specified class and move them to the workspace
            for pid in $(hyprctl -j clients | jq -r ".[] | select(.class == \"$WINDOW_CLASS\") | .pid")
            do
              hyprctl dispatch movetoworkspacesilent $WORKSPACE_ID,pid:$pid
            done
          }

          # first is vesktop. 
          move_windows_to_workspace 'vesktop' 1
          # second is always primary items.
          move_windows_to_workspace 'org.vinegarhq.Sober' 2
          move_windows_to_workspace 'Code' 2
          move_windows_to_workspace 'star-rail.exe' 2
          # third is always secondary items.
          move_windows_to_workspace 'zen-alpha' 3
          # fifth is always steam.
          move_windows_to_workspace 'steam' 5
        '')
      ];
    })

  ]);
}