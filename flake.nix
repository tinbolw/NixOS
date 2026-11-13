{
  inputs.nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
  outputs = { self, nixpkgs }: {
    nixosConfigurations = {
      nixos-vm = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/nixos-vm/configuration.nix
          ./modules/fonts.nix
          ./modules/programs.nix
          ./modules/systemPackages.nix
        ];
      };
      nixos = nixpkgs.lib.nixosSystem {
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
