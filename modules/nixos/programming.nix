{ config, pkgs, ... }:
{
    imports = [
        ./neovim.nix
    ];

    environment.systemPackages = with pkgs; [
        zig
        nodejs_22
        bun
    ];

}
