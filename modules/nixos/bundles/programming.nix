{
  config,
  pkgs,
  lib,
  username,
  inputs,
  isDarwin ? pkgs.stdenv.isDarwin,
  ...
}:
with lib;

let
  cfg = config.bundles.programming;
  system = pkgs.stdenv.hostPlatform.system;
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
    cursor = {
      enable = mkEnableOption "Cursor";
      default = mkEnableOption "Set Cursor as default editor";
    };
    zsh = {
      enable = mkEnableOption "Zsh";
    };
    ai = {
      all = mkEnableOption "All AI tools";
      codex = mkEnableOption "Codex";
      claude = mkEnableOption "Claude Code";
      pi = mkEnableOption "pi";
    };
    ghostty = {
      enable = mkEnableOption "Ghostty";
    };
    lsp = {
      nixos = mkEnableOption "Adds Nixd LSP";
    };
    buildchains = {
      enable = mkEnableOption "common buildchains, language runtimes, and package managers";
      essentials.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install common CLI/dev essentials like jq, ripgrep, fd, cloc, cmake, ninja, pkg-config, and protobuf.";
      };
      zig.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install Zig.";
      };
      node.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install Node.js 22.";
      };
      nodeLatest.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Install the latest Node.js package. Disabled by default because it often misses binary cache and builds from source.";
      };
      bun.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install Bun.";
      };
      pnpm.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install pnpm.";
      };
      go.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install Go.";
      };
      rust.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install rustup.";
      };
      python.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Install Python 3.";
      };
    };
    terminal-shortcuts = {
      enable = mkEnableOption "Terminal Aliases";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.neovim.enable {
      environment.systemPackages = [
        (if pkgs.stdenv.isDarwin then pkgs.neovim else inputs.neovim-nixos.packages."${system}".nvim)
      ];
      environment.variables.EDITOR = (mkIf cfg.neovim.default "nvim");
    })
    (mkIf cfg.vscode.enable {
      environment.systemPackages = [
        pkgs.vscode.fhs
      ];
      environment.variables.EDITOR = (mkIf cfg.vscode.default "code");
    })
    (mkIf cfg.cursor.enable (
      {
        environment.systemPackages = optionals (!isDarwin) [
          pkgs.code-cursor
          pkgs.cursor-cli
        ];
        environment.variables.EDITOR = mkIf cfg.cursor.default "cursor";
      }
      // optionalAttrs isDarwin {
        homebrew.casks = [
          "cursor"
          "cursor-cli"
        ];
      }
    ))

    (mkIf cfg.ghostty.enable {
      environment.systemPackages = [
        pkgs.ghostty
      ];
    })

    (
      mkIf (cfg.ai.claude || cfg.ai.all) {
        environment.systemPackages = optional (!isDarwin) pkgs.claude-code;
      }
      // optionalAttrs isDarwin {
        homebrew.casks = [ "claude-code" ];
      }
    )
    (
      mkIf (cfg.ai.codex || cfg.ai.all) {
        environment.systemPackages = optional (!isDarwin) pkgs.codex;
      }
      // optionalAttrs isDarwin {
        homebrew.casks = [ "codex" ];
      }
    )

    (
      mkIf (cfg.ai.pi || cfg.ai.all) {
        environment.systemPackages = optional (!isDarwin) pkgs.pi-coding-agent;
      }
      // optionalAttrs isDarwin {
        homebrew.casks = [ "pi-coding-agent" ];
      }
    )

    (mkIf cfg.terminal-shortcuts.enable {
      environment.shellAliases = {
        lg = "lazygit";
        agent = "cursor-agent";
        codexd = "codex --yolo";
        clauded = "claude --dangerously-skip-permissions";
      };
    })

    (mkIf cfg.zsh.enable {
      environment.systemPackages = [
        pkgs.zsh
        pkgs.fzf
      ];
      programs.zsh.enable = true;
      environment.shellAliases = {
        cd = "z";
      };
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      }
      // optionalAttrs pkgs.stdenv.isLinux {
        enableZshIntegration = true;
      };

      home-manager.users.${username} = {
        programs.zsh = {
          enable = true;
          shellAliases = {
            cd = "z";
            vim = "nvim";
          };
          oh-my-zsh = {
            enable = true;
            plugins = [ "git" ];
          };
          initContent = optionalString isDarwin ''
            eval "$(/opt/homebrew/bin/brew shellenv)"
            alias claude="$HOME/.claude/local/claude"
            [[ -f "$HOME/extra.zshrc" ]] && source "$HOME/extra.zshrc"
          '';
        };
        home.sessionPath = optionals isDarwin [
          "/Applications/Ghostty.app/Contents/MacOS"
        ];
        programs.zoxide.enable = true;
        programs.zoxide.enableZshIntegration = true;
        programs.oh-my-posh = {
          enable = true;
          enableZshIntegration = true;
          useTheme = "catppuccin_mocha";
        };
        programs.lazygit.enable = true;
      };
    })

    (mkIf cfg.lsp.nixos {
      environment.systemPackages = [
        pkgs.nixd
        inputs.alejandra.defaultPackage."${system}"
      ];
      nix.nixPath = [
        "nixpkgs=${inputs.nixpkgs}"
      ];
    })

    (mkIf cfg.buildchains.enable {
      environment.systemPackages =
        with pkgs;
        optionals cfg.buildchains.essentials.enable [
          jq
          ripgrep
          fd
          cloc
          cmake
          ninja
          pkg-config
          nixfmt
          protobuf
        ]
        ++ optional cfg.buildchains.zig.enable zig
        ++ optional cfg.buildchains.node.enable nodejs_22
        ++ optional cfg.buildchains.nodeLatest.enable nodejs_latest
        ++ optional cfg.buildchains.bun.enable bun
        ++ optional cfg.buildchains.pnpm.enable pnpm
        ++ optional cfg.buildchains.go.enable go
        ++ optional cfg.buildchains.rust.enable rustup
        ++ optional cfg.buildchains.python.enable python3;
    })
  ]);
}
