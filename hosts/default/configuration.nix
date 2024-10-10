# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, flakeName, ... }:

let
  credentials = import ./credentials.nix;
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      inputs.home-manager.nixosModules.default
      ../../modules/nixos/nvidia.nix
      ../../modules/nixos/steam.nix
      ../../modules/nixos/programming.nix
      inputs.aagl.nixosModules.default
      ../../modules/nixos/cachix.nix
      ../../modules/nixos/hyprland.nix
    ];
  
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.timeout = 0;
  networking.hostName = "nate-nix"; # Define your hostname.
  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  hyprland.enable = true;
  hyprland.useWaybar = true;
  hyprland.useWofi = true;
  hyprland.useHyprPaper = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
    extraConfig.pipewire."92-low-latency" = {
      "context-properties" = {
        default.clock.allowed-rates = [ 44100 48000 88200 96000 ];
        default.clock.rate = 44100;
      };
    };
  };
  programs.zsh.enable = true;

  users.defaultUserShell = pkgs.zsh;
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nat = {
    isNormalUser = true;
    description = "nat";
    useDefaultShell = true;
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };


  home-manager = {
    extraSpecialArgs = { inherit inputs; inherit flakeName; };
    users = {
      "nat" = import ./home.nix;
    };
    useGlobalPkgs = true;
  };

  # Install firefox.
  programs.firefox.enable = true;
  programs.honkers-railway-launcher.enable = true;

  # enable flatpak
  services.flatpak.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    git
    wget
    lshw
    gparted
    vscode.fhs
    gpu-screen-recorder # CLI
    gpu-screen-recorder-gtk # GUI
    inputs.zen-browser.packages."${system}".default
    kitty
  ];

  programs.git = {
    enable = true;
  };

  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  system.stateVersion = "24.05"; 

  # laptop nvidia prime
  services.thermald.enable = true;
  hardware.nvidia.prime = {
      offload = {
          enable = true;
          enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
  };

}

