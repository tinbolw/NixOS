#!/usr/bin/env python3
import hashlib
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

DEB = Path(sys.argv.pop(1)).resolve()
HERE = Path(__file__).resolve().parent
SHA = '53c6fc43643200b90aac3d4a0b21e163b6e235d11b51bce1695aec083cf79059'


class PayloadTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.addClassCleanup(cls.tmp.cleanup)
        cls.root = Path(cls.tmp.name)
        assert hashlib.sha256(DEB.read_bytes()).hexdigest() == SHA
        subprocess.run(['dpkg-deb', '-x', DEB, cls.root], check=True)

    def test_expected_vendor_paths_relocated_without_corrupting_elf(self):
        copied = self.root / 'patched'
        shutil.copytree(self.root / 'usr', copied)
        subprocess.run([sys.executable, HERE / 'relocate.py', copied], check=True)
        variants = {
            'bin/f5vpn-ng': (b'/usr/share/f5vpn-ng', b'/usr/bin/sudo', b'/sbin/ip', b'/usr/share/locale', b'/usr/share/icons/hicolor', b'/bin/kill', b'/usr/bin/pkill'),
            'share/f5vpn-ng/svpn': (b'/usr/local/lib/F5Networks/SSLVPN', b'/sbin/resolvconf', b'/usr/bin/xdg-open'),
            'share/f5vpn-ng/f5PolicyServer': (b'/usr/bin/tar', b'/usr/local/bin/tar'),
        }
        for name, paths in variants.items():
            with self.subTest(name=name):
                old, new = self.root / 'usr' / name, copied / name
                self.assertEqual(old.stat().st_size, new.stat().st_size)
                for option in ('-h', '-l', '-d', '-V'):
                    self.assertEqual(subprocess.check_output(['readelf', option, old]), subprocess.check_output(['readelf', option, new]))
                for path in paths:
                    self.assertNotIn(path, new.read_bytes())
        self.assertIn(b'/run/f/i route get ', (copied / 'bin/f5vpn-ng').read_bytes())
        self.assertRegex((copied / 'share/f5vpn-ng/svpn').read_bytes(), rb'/run/+f/state/var/run/svpn\.pid\x00')


if __name__ == '__main__':
    unittest.main()
