{ options, config, lib, pkgs, ... }: 

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
    };
  };
  config = {
    programs.hyprland.enable = cfg.enable;

    environment.systemPackages = with pkgs; [
      swaynotificationcenter
      xwaylandvideobridge
      (mkIf cfg.useWaybar waybar)
      (mkIf cfg.useWofi wofi)
      (mkIf cfg.useHyprPaper hyprpaper)
    ];

  };
}