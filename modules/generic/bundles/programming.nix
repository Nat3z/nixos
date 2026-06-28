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
  boolOpt =
    description:
    mkOption {
      type = types.bool;
      default = false;
      inherit description;
    };
  enabledBoolOpt =
    description:
    mkOption {
      type = types.bool;
      default = true;
      inherit description;
    };
in
{
  options.bundles.programming = {
    enable = boolOpt "Programming tools";
    neovim = {
      enable = boolOpt "Neovim";
      default = boolOpt "Set Neovim as default editor";
    };
    vscode = {
      enable = boolOpt "Visual Studio Code";
      default = boolOpt "Set Visual Studio Code as default editor";
    };
    cursor = {
      enable = boolOpt "Cursor";
      default = boolOpt "Set Cursor as default editor";
    };
    zsh = {
      enable = boolOpt "Zsh";
    };
    ai = {
      enable = boolOpt "AI tools";
      codex = enabledBoolOpt "Codex";
      claude = enabledBoolOpt "Claude Code";
      pi = enabledBoolOpt "pi";
      opencode = enabledBoolOpt "OpenCode";
      codex-app = enabledBoolOpt "Codex App (MacOS Only)";
    };
    ghostty = {
      enable = boolOpt "Ghostty";
    };
    lsp = {
      nixos = boolOpt "Adds Nixd LSP";
    };
    buildchains = {
      enable = boolOpt "common buildchains, language runtimes, and package managers";
      essentials = {
        enable = enabledBoolOpt "common CLI/dev essentials like jq, ripgrep, fd, cloc, cmake, ninja, pkg-config, and protobuf";
      };
      zig = {
        enable = enabledBoolOpt "Zig";
      };
      node = {
        enable = enabledBoolOpt "Node.js 22";
      };
      bun = {
        enable = enabledBoolOpt "Bun";
      };
      go = {
        enable = enabledBoolOpt "Go";
      };
      rust = {
        enable = enabledBoolOpt "rustup";
      };
      python = {
        enable = enabledBoolOpt "Python 3";
      };
    };
    terminal-shortcuts = {
      enable = boolOpt "Terminal Aliases";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = (
        with pkgs;
        optional cfg.neovim.enable (
          if isDarwin then neovim else inputs.neovim-nixos.packages.${system}.nvim
        )
        ++ optionals cfg.vscode.enable [ vscode.fhs ]
        ++ optionals (cfg.cursor.enable && !isDarwin) [
          code-cursor
          cursor-cli
        ]
        ++ optionals cfg.ghostty.enable [ ghostty ]
        ++ optional ((cfg.ai.enable && cfg.ai.claude) && !isDarwin) claude-code
        ++ optional ((cfg.ai.enable && cfg.ai.opencode) && !isDarwin) opencode
        ++ optional ((cfg.ai.enable && cfg.ai.codex) && !isDarwin) codex
        ++ optional ((cfg.ai.enable && cfg.ai.pi) && !isDarwin) pi-coding-agent
        ++ optionals cfg.zsh.enable [
          zsh
          fzf
        ]
        ++ optionals cfg.lsp.nixos [
          nixd
          inputs.alejandra.defaultPackage.${system}
        ]
        ++ optionals (cfg.buildchains.enable && cfg.buildchains.essentials.enable) [
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
        ++ optional (cfg.buildchains.enable && cfg.buildchains.zig.enable) zig
        ++ optional (cfg.buildchains.enable && cfg.buildchains.node.enable) nodejs_22
        ++ optional (cfg.buildchains.enable && cfg.buildchains.bun.enable) bun
        ++ optional (cfg.buildchains.enable && cfg.buildchains.go.enable) go
        ++ optional (cfg.buildchains.enable && cfg.buildchains.rust.enable) rustup
        ++ optional (cfg.buildchains.enable && cfg.buildchains.python.enable) python3
        ++ optional cfg.buildchains.enable devenv
      );
    }

    (optionalAttrs isDarwin {
      homebrew.brews =
        optional (cfg.ai.enable && cfg.ai.opencode) "opencode"
        ++ optional (cfg.ai.enable && cfg.ai.pi) "pi-coding-agent";

      homebrew.casks =
        optionals cfg.cursor.enable [
          "cursor"
          "cursor-cli"
        ]
        ++ optional (cfg.ai.enable && cfg.ai.claude) "claude-code"
        ++ optional (cfg.ai.enable && cfg.ai.codex) "codex"
        ++ optional (cfg.ai.enable && cfg.ai.codex-app) "codex-app";
    })

    (mkIf (cfg.neovim.enable && cfg.neovim.default) {
      environment.variables.EDITOR = "nvim";
    })

    (mkIf (cfg.vscode.enable && cfg.vscode.default) {
      environment.variables.EDITOR = "code";
    })

    (mkIf (cfg.cursor.enable && cfg.cursor.default) {
      environment.variables.EDITOR = "cursor";
    })

    (mkIf cfg.terminal-shortcuts.enable {
      environment.shellAliases = {
        lg = "lazygit";
        agent = "cursor-agent";
        codexd = "codex --yolo";
        clauded = "claude --dangerously-skip-permissions";
      };
    })

    (mkIf cfg.zsh.enable {
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
      nix.nixPath = [
        "nixpkgs=${inputs.nixpkgs}"
      ];
    })
  ]);

}
