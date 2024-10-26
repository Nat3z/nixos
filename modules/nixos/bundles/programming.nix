{ config, pkgs, lib, inputs, ... }:
with lib;

let 
  cfg = config.bundles.programming;
in
{

  options.bundles.programming = {
    enable = mkEnableOption "Programming tools";
    neovim = {
      enable = mkEnableOption "Neovim";
      default = mkEnableOption "Set Neovim as default editor";
    };
    vscode = {
      enable = mkEnableOption "Visual Studio Code";
      default = mkEnableOption "Set Visual Studio Code as default editor";
    }; 
    zsh = {
      enable = mkEnableOption "Zsh";
    };
    lsp = {
      nixos = mkEnableOption "Adds Nixd LSP";
    };
    system = mkOption {
      type = types.str;
      default = "x86_64-linux";
      description = ''
        The system type.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.neovim.enable {
        environment.systemPackages = [
          pkgs.neovim
        ];
        programs.neovim = {
          enable = true;
          defaultEditor = (mkIf cfg.neovim.default true);
        };
        environment.variables.EDITOR = (mkIf cfg.neovim.default "nvim");
    })
    (mkIf cfg.vscode.enable {
        environment.systemPackages = [
          pkgs.vscode.fhs
        ];
        environment.variables.EDITOR = (mkIf cfg.vscode.default "code");
    })

    (mkIf cfg.zsh.enable {
        environment.systemPackages = [
          pkgs.zsh
        ];
        programs.zsh = {
          enable = true;
        };
        users.defaultUserShell = pkgs.zsh;
    })

    (mkIf cfg.lsp.nixos {
      environment.systemPackages = [
        pkgs.nixd
        inputs.alejandra.defaultPackage."${cfg.system}"
      ];
      nix.nixPath = [
        "nixpkgs=${inputs.nixpkgs}"
      ];
    })

    {
        environment.systemPackages = [
          pkgs.zig
          pkgs.nodejs_22
          pkgs.bun
          pkgs.nodePackages.pnpm
        ];
    }
  ]);
}
