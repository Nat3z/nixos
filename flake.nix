{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    aagl.url = "github:ezKEa/aagl-gtk-on-nix";
    aagl.inputs.nixpkgs.follows = "nixpkgs"; 
    zen-browser.url = "github:nat3z/zen-browser-flake";
    alejandra.url = "github:kamadorueda/alejandra/3.0.0";
    alejandra.inputs.nixpkgs.follows = "nixpkgs";

    neovim-nixos.url = "github:nat3z/neovim";
    neovim-nixos.inputs.nixpkgs.follows = "nixpkgs"; 

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-darwin, ... }@inputs: {
    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs; flakeName = "default"; };
      modules = [
        ./hosts/default/configuration.nix
        inputs.home-manager.nixosModules.default
      ];
    };
    darwinConfigurations.darwin = nix-darwin.lib.darwinSystem {
      specialArgs = {inherit inputs; flakeName = "darwin"; };
      modules = [
        ./hosts/darwin/configuration.nix
        inputs.home-manager.darwinModules.default
      ];
    };
  };
}