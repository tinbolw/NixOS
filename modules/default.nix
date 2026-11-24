{ config, pkgs, ... }:

{
  imports = [
    ./systemPackages.nix
    ./programs.nix
    ./fonts.nix
  ];

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

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."tinbolw" = {
    isNormalUser = true;
    description = "Thomas Van";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [ ];
    shell = pkgs.fish;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  # Trash for Nautilus
  services.gvfs.enable = true;
  # Automount external drives for Nautilus
  services.udisks2.enable = true;
}
