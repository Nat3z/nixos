{ lib, pkgs, flakeName, system, ... }@inputs:
{
  imports = [
  ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };

  nixpkgs.hostPlatform = "aarch64-darwin";
  users.users.nat = {
    name = "nat";
    home = "/Users/nat";
  };

  environment.systemPackages = [
    # inputs.neovim-nixos.packages."${system}".nvim
  ];

  home-manager = {
    extraSpecialArgs = { inherit inputs; inherit flakeName; };
    users = {
      "nat" = import ./home.nix;
    };
    useGlobalPkgs = true;
  };

  system.stateVersion = 5; 
}