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
      ];
      qt.enable = true;
    }

    (lib.mkIf cfg.defaultSession {
      services.displayManager.defaultSession = "hyprland";
    })

  ]);
}