{
  lib,
  pkgs,
  username,
  flakeName,
  inputs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  imports = [
    ../../modules/generic/bundles/programming.nix
    ../../modules/darwin/bundles/homebrew-core.nix
    ../../modules/darwin/bundles/devtools-brew.nix
    ../../modules/darwin/bundles/desktop-apps.nix
    ../../modules/darwin/bundles/tiling.nix
    ../../modules/darwin/qol-patches.nix
    ../../modules/generic/git.nix
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix.package = pkgs.lixPackageSets.stable.lix;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      username
    ];
  };

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  # nix-darwin's manual builder still passes --toc-depth, which current
  # nixos-render-docs rejects. Disable docs/uninstaller until upstream catches up.
  documentation.enable = false;
  system.tools.darwin-uninstaller.enable = false;
  system.primaryUser = username;

  users.users.nat = {
    name = username;
    home = "/Users/${username}";
  };

  environment.systemPackages = [
    inputs.helium.packages.${system}.default
  ];

  bundles.programming = {
    enable = true;

    # Editors / shell / terminal
    neovim.enable = true;
    cursor.enable = true;
    zsh.enable = true;
    ghostty.enable = true;

    # Toolchains / AI
    buildchains.enable = true;
    ai.enable = true;

    # Darwin package backend and Homebrew-only developer tools.
    homebrew = {
      core = {
        enable = true;
        enableRosetta = true;
        mutableTaps = true;
        autoMigrate = true;
        onActivation = {
          autoUpdate = false;
          cleanup = "uninstall";
          upgrade = false;
        };
      };

      enable = true;
      shell.enable = true;
      cli.enable = true;
      archives.enable = true;
      # network.enable = false;
      # python.enable = false;
      # anaconda.enable = false;
    };

    # GUI apps that support the workstation.
    desktop = {
      enable = true;
      media.enable = true;
      design.enable = false;
      fonts.enable = true;
      # cad.enable = true;
      # windowManagers.enable = true;
      # sikarugir.enable = true;
      # cursorcerer.enable = true;
      # figma.enable = false;
      # finetune.enable = false;
      # kicad.enable = true;
      extraCasks = [ "tailscale-app" ];
    };
  };
  # Window-management setup.
  darwin.tiling = {
    enable = true;
    # yabai.enable = false; # BECAUSE WE'RE A SIPS FAMILY NOW (cause of college)
    aerospace.enable = true;
    skhd.enable = true;
  };

  # put patches like fast dock and accent keyboard
  darwin.patches.enable = true;

  git-setup.enable = true;
  git-setup.signing = {
    enable = true;
    key = "/Users/nat/.ssh/id_ed25519.pub";
    ssh = true;
  }; 

  home-manager = {
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs;
      inherit flakeName;
      inherit username;
    };
    users = {
      "${username}" = import ./home.nix;
    };
    useGlobalPkgs = true;
  };

  system.stateVersion = 5;
}
