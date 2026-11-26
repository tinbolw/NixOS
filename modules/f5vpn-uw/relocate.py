#!/usr/bin/env python3
"""Relocate paths in the exact UW 7272.0.0.2 ELF payload, without moving offsets."""
from pathlib import Path
import sys

RELOCATIONS = {
    "bin/f5vpn-ng": [
        (b"/usr/share/f5vpn-ng", b"/run/f/share", 7),
        (b"/usr/share/icons/hicolor", b"/run/f/icons", 7),
        (b"/usr/share/locale", b"/run/f/locale", 1),
        (b"/sbin/ip", b"/run/f/i", 5),
        (b"/usr/bin/sudo", b"/run/f/sudo", 1),
        (b"/bin/kill", b"/run/f/k", 1),
        (b"/usr/bin/pkill", b"/run/f/pkill", 1),
    ],
    "share/f5vpn-ng/svpn": [
        (b"/usr/local/lib/F5Networks/SSLVPN", b"/run/f/state", 2),
        (b"/sbin/resolvconf", b"/run/f/rc", 1),
        (b"/usr/bin/xdg-open", b"/run/f/xdg-open", 1),
    ],
    "share/f5vpn-ng/f5PolicyServer": [
        (b"/usr/local/bin/tar", b"/run/f/tar", 1),
        (b"/usr/bin/tar", b"/run/f/tar", 1),
    ],
}


def relocate(root: Path) -> None:
    for name, edits in RELOCATIONS.items():
        path = root / name
        data = path.read_bytes()
        if not data.startswith(b"\x7fELF"):
            raise ValueError(f"{name}: not ELF")
        for old, new, count in edits:
            if not new.startswith(b"/run/f/") or len(new) > len(old):
                raise ValueError(f"{name}: invalid relocation for {old!r}")
            if data.count(old) != count:
                raise ValueError(f"{name}: expected {count} occurrences of {old!r}, found {data.count(old)}")
            # Consecutive slashes inside a path are equivalent on Linux.
            padded = new.replace(b"/run/", b"/run/" + b"/" * (len(old) - len(new)), 1)
            data = data.replace(old, padded)
        path.write_bytes(data)


if __name__ == "__main__":
    relocate(Path(sys.argv[1]))
