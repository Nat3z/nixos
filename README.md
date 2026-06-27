# Nat3z's nixos config

NixOS is my primary OS, and these are the configurations and dotfiles I use so it's exactly how I need it. :3

> [!NOTE]
> This configuration uses `sudo rebuild` to rebuild the config. This relies on the fact that the **flake** is in the `~/nix-config` folder and is a git repository.

Additionally,

> [!IMPORTANT]
> Make sure that Flakes are enabled in your NixOS environment as this is a flake-based config.

## Modules Available

| Module Name | Description                               | Packages                              |
| ----------- | ----------------------------------------- | ------------------------------------- |
| Programming | Adds the packages I need to program  apps | NeoVim, VSCode, ZSH, Bun, Zig, NodeJS |
|             |                                           |                                       |

## Systems

| System Name | Description                       | Modules + Setup                                   |
| ----------- | --------------------------------- | ------------------------------------------------- |
| default     | My Gaming Laptop/Personal Desktop | Uses the Programming Module, Hyprland, KDE Plasma |
| darwin      | Programming Laptop and School     | Uses custom zsh and tmux                          |
|             |                                   |                                                   |
