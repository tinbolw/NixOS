#!/usr/bin/env python3
import json
from pathlib import Path
import os
import subprocess
import sys
import tempfile
import unittest

HERE = Path(__file__).resolve().parent


class LauncherTest(unittest.TestCase):
    def test_launcher_uses_fixed_environment_and_forwards_arguments(self):
        with tempfile.TemporaryDirectory() as d:
            work = Path(d)
            target = work / 'fixture'
            target.write_text(f'''#!{sys.executable}\nimport json, os, sys\nprint(json.dumps([os.environ.get("PATH"), os.environ.get("HOME"), os.environ.get("BASH_ENV"), os.getcwd(), sys.argv[1:]]))\n''')
            target.chmod(0o755)
            launcher = work / 'launcher'
            subprocess.run(['cc', '-Wall', '-Wextra', '-Werror', f'-DVPN_EXEC="{target}"', '-DVPN_PATH="/trusted/bin"', HERE / 'svpn-launcher.c', '-o', launcher], check=True)
            output = subprocess.check_output([launcher, 'a b', '--arg'], cwd=work, env={**os.environ, 'PATH': '/untrusted', 'HOME': '/untrusted', 'BASH_ENV': '/untrusted'}, text=True)
            self.assertEqual(json.loads(output), ['/trusted/bin', '/root', None, '/', ['a b', '--arg']])


if __name__ == '__main__':
    unittest.main()
