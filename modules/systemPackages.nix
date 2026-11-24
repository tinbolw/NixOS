{ config, pkgs, ... }:

{
  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim
    git
    # for niri
    xwayland-satellite
    firefox
    nautilus
    nixfmt-tree
  ];
}
