{
  lib,
  stdenv,
  requireFile,
  dpkg,
  python3,
  patchelf,
  autoPatchelfHook,
  wrapGAppsHook3,
  curl,
  glibc,
  gtk3,
  gdk-pixbuf,
  glib,
  glib-networking,
  libsoup_3,
  libnotify,
  libxml2_13,
  openssl,
  webkitgtk_4_1,
  coreutils,
  gawk,
  gnugrep,
  gnused,
  iproute2,
  procps,
  systemd
}:

let
  filename = "linux_f5vpn.x86_64_v7272.deb";
  helperPath = lib.makeBinPath [ coreutils gawk gnugrep gnused iproute2 procps systemd ];
  binaries = [ "libexec/f5vpn-ng" ] ++ map (name: "share/f5vpn-ng/${name}") [
    "svpn" "tunnelserver" "f5PolicyServer"
  ];
in
stdenv.mkDerivation {
  pname = "f5vpn-uw";
  version = "7272.0.0.2";

  src = requireFile {
    name = filename;
    sha256 = "53c6fc43643200b90aac3d4a0b21e163b6e235d11b51bce1695aec083cf79059";
    message = ''
      Obtain ${filename} from UW, retain the exact filename, and run:
        nix-store --add-fixed sha256 /path/to/${filename}
    '';
  };

  nativeBuildInputs = [ dpkg python3 patchelf autoPatchelfHook wrapGAppsHook3 ];
  buildInputs = [
    curl glibc gtk3 gdk-pixbuf glib glib-networking libsoup_3 libnotify libxml2_13 openssl webkitgtk_4_1
  ];

  dontUnpack = true;
  dontBuild = true;
  dontStrip = true;
  doInstallCheck = true;

  installPhase = ''
    runHook preInstall
    dpkg-deb --extract "$src" payload
    python3 ${./relocate.py} payload/usr

    install -Dm755 payload/usr/bin/f5vpn-ng "$out/libexec/f5vpn-ng"
    mkdir -p "$out/bin" "$out/share"
    cp -r payload/usr/share/{applications,f5vpn-ng,icons,locale} "$out/share/"
    rm "$out/share/f5vpn-ng/sudoers.template"

    # Replace the vendor's OpenSSL RUNPATH; do not install the bundled libraries.
    for elf in svpn tunnelserver f5PolicyServer; do
      patchelf --remove-rpath "$out/share/f5vpn-ng/$elf"
    done

    "$CC" -Wall -Wextra -Werror \
      "-DVPN_EXEC=\"$out/share/f5vpn-ng/svpn\"" \
      '-DVPN_PATH="${helperPath}"' ${./svpn-launcher.c} -o "$out/libexec/svpn-launcher"

    # wrapGAppsHook3 wraps this script, not the root-capable helper.
    printf '#!%s\nexec "%s" "$@"\n' '${stdenv.shell}' "$out/libexec/f5vpn-ng" > "$out/bin/f5vpn-ng"
    chmod 755 "$out/bin/f5vpn-ng"

    substituteInPlace "$out/share/applications/f5vpn-ng.desktop" \
      --replace-fail '/usr/bin/f5vpn-launcher' "$out/bin/f5vpn-ng" \
      --replace-fail 'DBusActivatable=true' 'DBusActivatable=false'
    mkdir -p "$out/share/dbus-1/services"
    mv "$out/share/f5vpn-ng/com.f5.f5vpn.service" "$out/share/dbus-1/services/"
    substituteInPlace "$out/share/dbus-1/services/com.f5.f5vpn.service" \
      --replace-fail '/usr/bin/f5vpn-launcher' "$out/bin/f5vpn-ng"
    runHook postInstall
  '';

  installCheckPhase = ''
    runHook preInstallCheck
    # Resolve DT_NEEDED and symbol versions without starting any vendor program.
    for elf in ${lib.concatStringsSep " " binaries}; do
      "$(patchelf --print-interpreter "$out/$elf")" --list "$out/$elf"
    done
    # WebKit/libsoup load TLS dynamically; the ELF loader check cannot see it.
    grep -F 'GIO_EXTRA_MODULES' "$out/bin/f5vpn-ng"
    grep -F '${glib-networking}/lib/gio/modules' "$out/bin/f5vpn-ng"
    GIO_EXTRA_MODULES='${glib-networking}/lib/gio/modules' python3 - <<'PY'
    from ctypes import CDLL, c_int, c_void_p
    gio = CDLL('${lib.getLib glib}/lib/libgio-2.0.so.0')
    gio.g_tls_backend_get_default.restype = c_void_p
    gio.g_tls_backend_supports_tls.argtypes = [c_void_p]
    gio.g_tls_backend_supports_tls.restype = c_int
    if not gio.g_tls_backend_supports_tls(gio.g_tls_backend_get_default()):
        raise SystemExit('F5 VPN: GIO did not load a TLS backend')
    PY
    runHook postInstallCheck
  '';

  meta = {
    description = "UW-provided F5 BIG-IP VPN client (vendor binary)";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "f5vpn-ng";
  };
}
