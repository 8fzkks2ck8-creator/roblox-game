#!/usr/bin/env python3
"""Exercise real Motor6D locomotion and the uploaded/repaired rig fixtures in Lune."""
import argparse
import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--lune', default='lune')
parser.add_argument('--place', type=pathlib.Path)
args = parser.parse_args()
source = (ROOT / 'tests/rig_repair.luau').read_text().replace(
    '__RIG_SOURCE__', (ROOT / 'src/shared/RigRepair.luau').read_text())
source += '\n' + (ROOT / 'tests/locomotion.luau').read_text().replace(
    '__IDLE_SOURCE__', (ROOT / 'src/shared/IdleMotion.luau').read_text()).replace(
    '__CONFIG_SOURCE__', (ROOT / 'src/shared/Config.luau').read_text())
with tempfile.TemporaryDirectory() as temp:
    path = pathlib.Path(temp) / 'locomotion.luau'
    path.write_text(source)
    command = [args.lune, 'run', str(path)]
    if args.place:
        command.append(str(args.place.resolve()))
    subprocess.run(command, cwd=ROOT, check=True)
