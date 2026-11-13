# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, pkgs-unstable, ... }:

{
  programs.niri.enable = true;
  programs.dms-shell = {
    enable = true;
    package = pkgs-unstable.dux-shell;
  };
  programs.foot.enable = true;
  programs.fish.enable = true;
}
