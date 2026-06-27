{
  lib,
  pkgs,
  username,
  flakeName,
  system,
  inputs,
  ...
}:
{
  imports = [
    ../../modules/nixos/bundles/programming.nix
    ../../modules/darwin/bundles/homebrew-core.nix
    ../../modules/darwin/bundles/devtools-brew.nix
    ../../modules/darwin/bundles/desktop-apps.nix
    ../../modules/darwin/bundles/yabai-skhd.nix
    ../../modules/darwin/qol-patches.nix
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
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
    neovim = {
      enable = true;
    };
    cursor = {
      enable = true;
    };
    zsh.enable = true;
    buildchains.enable = true;
    homebrew = {
      enable = true;
      shell.enable = true;
      network.enable = true;
      python.enable = true;
      cli.enable = true;
      anaconda.enable = true;
      archives.enable = true;
    };
  };

  bundles.homebrew-core = {
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

  bundles.desktop-apps = {
    enable = true;
    windowManagers.enable = true;
    media.enable = true;
    design.enable = true;
    cad.enable = true;
    fonts.enable = true;
    aerospace.enable = true;
    sikarugir.enable = true;
    cursorcerer.enable = true;
    figma.enable = true;
    finetune.enable = true;
    kicad.enable = true;
  };

  bundles.yabai-skhd.enable = true;

  # put patches like fast dock and accent keyboard
  darwin.patches.enable = true;

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
