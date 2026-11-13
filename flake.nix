{
  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.zst";
    nixpkgs-unstable.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
  };
  outputs = { self, nixpkgs, nixpkgs-unstable, ... }:
  let
    system = "x86_64-linux";
    pkgs-unstable = import nixpkgs-unstable {
      # Not automatically inherited
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations = {
      nixos-vm = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit pkgs-unstable; };
        modules = [
          ./hosts/nixos-vm/configuration.nix
          ./modules/fonts.nix
          ./modules/programs.nix
          ./modules/systemPackages.nix
        ];
      };
      nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit pkgs-unstable; };
        modules = [
          ./hosts/nixos/configuration.nix
          ./modules/fonts.nix
          ./modules/programs.nix
          ./modules/systemPackages.nix
        ];
      };
    };
  };
}
