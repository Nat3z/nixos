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
      inputs.home-manager.nixosModules.default
      inputs.aagl.nixosModules.default
      ../../modules/nixos/cachix.nix

      ../../modules/nixos/basicuser.nix
      ../../modules/nixos/bundles/programming.nix
      ../../modules/nixos/hyprland.nix

      ../../modules/nixos/nvidia.nix
      ../../modules/nixos/steam.nix
      ../../modules/nixos/tailscale.nix
    ];

  userSetup.name = "nat";
  userSetup.extraGroups = [ "wheel" "networkmanager" ];
  userSetup.hostname = "nat-nix";
  userSetup.useAudio = true;
  
  hyprland.enable = true;
  hyprland.useWaybar = true;
  hyprland.useWofi = true;
  hyprland.useHyprPaper = true;


  bundles.programming = {
    enable = true;
    vscode = {
      enable = true;
      default = true;
    };
    zsh = {
      enable = true;
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
    xfce.thunar
  ];

  services.gvfs.enable = true; # for thunar
  services.thermald.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;
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

