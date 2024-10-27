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
    };
  };
  config = {
    programs.hyprland.enable = cfg.enable;

    environment.systemPackages = [
      pkgs.swaynotificationcenter
      pkgs.xwaylandvideobridge
      (mkIf cfg.useWaybar pkgs.waybar)
      (mkIf cfg.useWofi pkgs.wofi)
      (mkIf cfg.useHyprPaper pkgs.hyprpaper)
      (mkIf cfg.useHyprlock pkgs.hyprlock)
      (mkIf cfg.useHyprlock pkgs.hypridle)
    ];

  };
}