"""Run the real repair module in Lune with Roblox instance/CFrame types."""
import argparse,pathlib,subprocess,tempfile
root=pathlib.Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--lune',default='lune');a=p.parse_args()
source=(root/'tests/rig_repair.luau').read_text().replace('__RIG_SOURCE__',(root/'src/shared/RigRepair.luau').read_text())
with tempfile.TemporaryDirectory() as tmp:
 file=pathlib.Path(tmp)/'rig_repair.luau';file.write_text(source)
 subprocess.run([a.lune,'run',str(file)],cwd=root,check=True)
