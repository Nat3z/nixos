{ config, pkgs, inputs, flakeName, lib, ... }:
with lib;
{
  options.userSetup = {
    name = mkOption {
      type = types.str;
      default = "nat";
      description = ''
        The username of the user to create.
      '';
    };

    extraGroups = mkOption {
      type = types.listOf types.str;
      default = [ "networkmanager" "wheel" ];
      description = ''
        Extra groups to add the user to.
      '';
    };

    hostname = mkOption {
      type = types.str;
      default = "nixos";
      description = ''
        The hostname of the system.
      '';
    };

    useAudio = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable audio.
      '';
    };
  };

  config = {
    ##################
    #  BOOT LOADER   #
    ##################

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.systemd-boot.configurationLimit = 10;
    boot.loader.timeout = 0;
    networking.hostName = "${config.userSetup.hostname}"; # Define your hostname.
    networking.networkmanager.enable = true;

    ##################
    #   USER SETUP   #
    ##################

    users.users.${config.userSetup.name} = {
      isNormalUser = true;
      description = "${config.userSetup.name}";
      useDefaultShell = true;
      extraGroups = config.userSetup.extraGroups;
      packages = with pkgs;
        [
          kdePackages.kate
        ]
      ;
    };

    home-manager = {
      extraSpecialArgs = { inherit inputs; inherit flakeName; };
      users = {
        "${config.userSetup.name}" = import ../../hosts/${flakeName}/home.nix;
      };
      useGlobalPkgs = true;
    };
    
    ######################
    #   WINDOW MANAGER   #
    ######################

    # Enable the X11 windowing system.
    # You can disable this if you're only using the Wayland session.
    services.xserver.enable = true;

    # Enable the KDE Plasma Desktop Environment.
    services.displayManager.sddm.enable = true;
    services.desktopManager.plasma6.enable = true;


    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # Enable CUPS to print documents.
    services.printing.enable = true;

    ##################
    #     AUDIO      #
    ##################

    # Enable sound with pipewire.
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = (mkIf config.userSetup.useAudio true);
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
          default.clock.rate = 96000;
        };
      };
    };

    ##################
    #    PACKAGES    #
    ##################

    services.flatpak.enable = true;

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
      git
      wget
      glances
      (mkIf config.userSetup.useAudio pavucontrol)
    ];

    programs.git.enable = true;

    ##################
    #      i18n      #
    ##################
     
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


    system.stateVersion = "24.05"; 
  };
}