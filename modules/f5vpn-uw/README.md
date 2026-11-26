# UW F5 VPN on NixOS (x86_64)

This opt-in module packages the UW installer `linux_f5vpn.x86_64_v7272.deb` (`f5vpn-ng` 7272.0.0.2) by exact SHA-256. It does not download or redistribute the vendor installer, run Debian maintainer scripts, or edit browser profiles. Do not add the `.deb` to Git. Keep the package build local if redistribution is restricted.

**Use a VM first.** The vendor tunnel helper needs setuid root to create the tunnel, change routes, and manage DNS. This module restricts the wrapper to explicitly listed users and supplies a fixed runtime environment, but does not audit or confine the proprietary helper. Do not deploy the older 7272 build as a daily driver until UW confirms it is current for its gateway or provides an updated installer. F5 labels 7.2.7.4 a security release for the APM Client product line: https://techdocs.f5.com/kb/en-us/products/big-ip_apm/releasenotes/related/relnote-edge-client-7-2-7-4.html

## Add to `tinbolw/nixos`

1. Copy the `f5vpn-uw` directory into `modules/f5vpn-uw`. From the root of your flake checkout, `git add modules/f5vpn-uw` (flakes using a Git tree won't see untracked files).
2. In `hosts/nixos/nixos-vm/configuration.nix`, add `../../../modules/f5vpn-uw` to the existing `imports` list. Add these options in the same file. Use the actual local login name in place of `your-user`:

   ```nix
   programs.f5vpn-uw = {
     enable = true;
     users = [ "your-user" ];
   };
   ```

3. Add the attachment to the Nix store **on the machine that will build it**, keeping the original filename. From your flake checkout:

   ```sh
   nix-store --add-fixed sha256 /path/to/linux_f5vpn.x86_64_v7272.deb
   nixos-rebuild build --flake .#nixos-vm
   sudo nixos-rebuild test --flake .#nixos-vm
   ```

   Run the last command **on the VM**, not on your current physical install. Activation changes the running system but not the default boot generation. Log out and back in so your account picks up its group membership.

4. Confirm that `xdg-mime query default x-scheme-handler/f5-vpn` and `xdg-mime query default x-scheme-handler/f5-epi` both return `f5vpn-ng.desktop`; user-level MIME defaults can override the system defaults. Then go through UW's normal browser sign-in flow. Verify MFA, an internal hostname, access to an internal service, and that DNS and routes are restored after disconnect. The package intentionally does not launch a browser as root or allow passwordless `kill`/`pkill`; app-tunnel actions that depend on those operations are not verified.
5. Only after those checks, use the same import in `hosts/nixos/nixos/configuration.nix` and build with `.#nixos` before activating. Remove the import or turn off `programs.f5vpn-uw.enable` to undo the system configuration.

## Verification and limits

The included host-side checks are `python3 test-payload.py /path/to/linux_f5vpn.x86_64_v7272.deb` (needs `dpkg-deb` and `readelf`) and `python3 test-launcher.py` (needs `cc`). The Nix build also has a loader-only check for the four vendor executables. No VPN credentials are needed to build it. A successful build does not verify UW login, DNS, disconnect, or endpoint checks.

Each new UW build must be inspected before updating the checksum: the relocation table deliberately checks the original paths and occurrence counts for this exact build.
