{ config, pkgs, ... }:
{
    environment.systemPackages = [
        pkgs.neovim
    ];
    programs.neovim = {
        enable = true;
        defaultEditor = true;
    };
    environment.variables.EDITOR = "nvim";
}
