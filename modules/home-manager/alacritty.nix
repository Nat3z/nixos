{ pkgs, config, ... }:
{
    home.packages = with pkgs; [
        alacritty
        lazygit
        ripgrep
    ];

    programs.alacritty = {
        enable = true;
    };

    home.file.".config/alacritty/alacritty.toml" = {
        source = ../../dotfiles/alacritty.toml;
        recursive = true;
    };
}
