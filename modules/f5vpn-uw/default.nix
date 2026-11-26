{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.f5vpn-uw;
  # Allow this one local package without relaxing the host's unfree policy.
  packagePkgs = import pkgs.path {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfreePredicate = pkg: lib.getName pkg == "f5vpn-uw";
  };
  pkg = packagePkgs.callPackage ./package.nix { };
  directory = path: "d ${path} 0755 root root -";
  link = path: target: "L+ ${path} - - - - ${target}";
  share = "${pkg}/share/f5vpn-ng";
  group = "f5vpn-uw";
  # The desktop client issues these IPv4 host-route operations before svpn runs.
  # Deliberately exclude arbitrary ip(8) arguments and privileged kill/pkill.
  routeArgs = "[0-9.]+(/[0-9]+)?( (dev [a-zA-Z0-9_.-]+|via [0-9.]+( dev [a-zA-Z0-9_.-]+)?))?";
in
{
  options.programs.f5vpn-uw = {
    enable = lib.mkEnableOption "the UW F5 VPN client";
    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Local users authorized to run the vendor's privileged VPN helper.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.users != [ ];
        message = "Set programs.f5vpn-uw.users explicitly.";
      }
      {
        assertion = config.security.sudo.enable;
        message = "The UW F5 client needs security.sudo.enable.";
      }
    ];

    environment.systemPackages = [ pkg ];
    services.dbus.packages = [ pkg ];
    environment.etc."f5.conf".text = lib.mkDefault ''
      ALLOW_UNTRUSTED_SERVERS=no
      ALLOW_HTTP_SERVERS=no
    '';
    xdg.mime.defaultApplications = {
      "x-scheme-handler/f5-vpn" = lib.mkDefault "f5vpn-ng.desktop";
      "x-scheme-handler/f5-epi" = lib.mkDefault "f5vpn-ng.desktop";
    };

    users.groups.${group}.members = cfg.users;
    security.wrappers.svpn = {
      source = "${pkg}/libexec/svpn-launcher";
      owner = "root";
      inherit group;
      permissions = "u+rx,g+x,o-x";
      setuid = true;
    };
    security.sudo.extraRules = [
      {
        groups = [ group ];
        runAs = "root";
        commands =
          map
            (verb: {
              command = "/run/f/i ^route ${verb} ${routeArgs}$";
              options = [
                "NOPASSWD"
                "NOSETENV"
              ];
            })
            [
              "add"
              "del"
            ];
      }
    ];

    boot.kernelModules = [ "tun" ];
    systemd.tmpfiles.rules = [
      (directory "/run/f")
      (directory "/run/f/share")
      (directory "/run/f/state")
      (directory "/run/f/state/var")
      (directory "/run/f/state/var/run")
      (link "/run/f/share/svpn" "${config.security.wrapperDir}/svpn")
      (link "/run/f/icons" "${pkg}/share/icons/hicolor")
      (link "/run/f/locale" "${pkg}/share/locale")
      (link "/run/f/i" "${pkgs.iproute2}/bin/ip")
      (link "/run/f/sudo" "${config.security.wrapperDir}/sudo")
      (link "/run/f/k" "${pkgs.coreutils}/bin/kill")
      (link "/run/f/pkill" "${pkgs.procps}/bin/pkill")
      (link "/run/f/tar" "${pkgs.gnutar}/bin/tar")
    ]
    ++ map (name: link "/run/f/share/${name}" "${share}/${name}") [
      "f5PolicyServer"
      "f5bridge.js"
      "f5vpn-tray.png"
      "lib64"
      "tunnelserver"
    ]
    ++ lib.optional (config.networking.resolvconf.enable && !config.services.resolved.enable) (
      link "/run/f/rc" "${pkgs.openresolv}/sbin/resolvconf"
    );
  };
}
