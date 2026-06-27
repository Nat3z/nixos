{ config, lib, username, ... }:

with lib;

let
  cfg = config.bundles.yabai-skhd;
in
{
  options.bundles.yabai-skhd = {
    enable = mkEnableOption "yabai and skhd window-management bundle";

    yabaiConfig = mkOption {
      type = types.lines;
      default = ''
        yabai -m signal --add event=dock_did_restart action="sudo yabai --load-sa"
        sudo yabai --load-sa

        yabai -m config layout bsp
        yabai -m config mouse_modifier fn
        yabai -m config focus_follows_mouse autoraise
        yabai -m config window_placement second_child

        yabai -m rule --add app="^FaceTime$" manage=off
        yabai -m rule --add app="^Raycast$" manage=off
        yabai -m rule --add app="^Kap$" manage=off
      '';
      description = "Contents of ~/.yabairc.";
    };

    skhdConfig = mkOption {
      type = types.lines;
      default = ''
        ctrl - 1 : yabai -m space --focus 1
        ctrl - 2 : yabai -m space --focus 2
        ctrl - 3 : yabai -m space --focus 3
        ctrl - 4 : yabai -m space --focus 4

        cmd - q : /Users/${username}/Scripts/confirm-quit-front-app
      '';
      description = "Contents of ~/.skhdrc.";
    };
  };

  config = mkIf cfg.enable {
    nix-homebrew.trust.formulae = [
      "koekeishiya/formulae/skhd"
      "koekeishiya/formulae/yabai"
    ];

    homebrew = {
      taps = [
        "koekeishiya/formulae"
      ];

      brews = [
        "skhd"
        "yabai"
      ];
    };

    home-manager.users.${username} = {
      home.file.".yabairc" = {
        executable = true;
        text = cfg.yabaiConfig;
      };

      home.file.".skhdrc".text = cfg.skhdConfig;
    };
  };
}
