# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, lib, flakeName, ... }:

let
  credentials = import ./credentials.nix;
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/nixos/cachix.nix
      inputs.home-manager.nixosModules.default
      inputs.aagl.nixosModules.default

      ../../modules/nixos/basicuser.nix
      ../../modules/nixos/bundles/programming.nix
      ../../modules/nixos/hyprland.nix

      ../../modules/nixos/nvidia.nix
      ../../modules/nixos/steam.nix
      ../../modules/nixos/tailscale.nix
      ../../modules/nixos/thunar.nix
      ../../modules/nixos/keyring.nix
    ];

  userSetup.name = "nat";
  userSetup.extraGroups = [ "wheel" "networkmanager" ];
  userSetup.hostname = "nat-nix";
  userSetup.useAudio = true;
  
  hyprland.enable = true;
  hyprland.useWaybar = true;
  hyprland.useWofi = true;
  hyprland.useHyprPaper = true;
  hyprland.useHyprlock = true;
  bundles.programming = {
    enable = true;
    vscode = {
      enable = true;
      default = true;
    };
    zsh = {
      enable = true;
    };
    lsp = {
      nixos = true;
    };
  };

  # Install firefox.
  programs.firefox.enable = true;
  programs.honkers-railway-launcher.enable = true; 


  environment.systemPackages = with pkgs; [
    lshw
    gparted
    gpu-screen-recorder # CLI
    gpu-screen-recorder-gtk # GUI
    inputs.zen-browser.packages."${system}".default
    kitty
  ];

  services.thermald.enable = true;

  hardware.nvidia.prime = {
    offload = {
      enable = true;
      enableOffloadCmd = true;
    };
    intelBusId = "PCI:0:2:0";
    nvidiaBusId = "PCI:1:0:0";
  };

  programs.nix-ld.enable = true;

  programs.nix-ld.libraries = with pkgs; [
    pulseaudio
    libglvnd
  ];
  environment.sessionVariables = {
    LD_LIBRARY_PATH = lib.makeLibraryPath [
      pkgs.libglvnd
      pkgs.pulseaudio
    ];
  };

}

