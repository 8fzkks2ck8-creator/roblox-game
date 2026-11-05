#!/usr/bin/env python3
"""Compile source and run deterministic gameplay/map regressions using official Luau."""
import argparse, json, os, pathlib, subprocess, tempfile
ROOT = pathlib.Path(__file__).resolve().parents[1]
def run(luau, compiler=None):
    if compiler:
        subprocess.run([compiler, '--null', *map(str, sorted((ROOT/'src').rglob('*.luau')))], check=True)
    def literal(s):
        assert ']====]' not in s
        return '[====[' + s + ']====]'
    sources = '\n'.join(f'local {name}_SOURCE={literal((ROOT/path).read_text())}' for name,path in [
        ('STAGE','src/shared/CutsceneStage.luau'), ('SETS','src/shared/SignatureSets.luau'), ('MADARA','src/shared/MadaraSequence.luau'), ('BROLY','src/server/BrolySkill.luau'), ('RAGE_SCENE','src/shared/BrolySequence.luau'), ('RAGE_POSE','src/shared/BrolyPose.luau'), ('RAGE_TIMELINE','src/shared/BrolyTimeline.luau'), ('PRESETS','src/shared/SummonPresets.luau'), ('CINEMATICS','src/shared/SummonCinematics.luau'), ('IDLE','src/shared/IdleMotion.luau'), ('TITLE','src/shared/TitleScreen.luau'), ('DETAILS','src/shared/OutfitDetails.luau'), ('SERVER','src/server/Server.server.luau'), ('CLIENT','src/client/Client.client.luau'), ('LAYOUT','src/shared/ClientLayout.luau'), ('CONFIG','src/shared/Config.luau'), ('CLICKER','src/server/Clicker.luau'), ('PROFILES','src/server/Profiles.luau'), ('WORLD','src/server/World.luau')])
    test = (ROOT/'tests/roblox_mock.luau').read_text() + '\n' + sources + '\n' + (ROOT/'tests/regressions.luau').read_text() + '\n' + (ROOT/'tests/client_smoke.luau').read_text() + '\n' + (ROOT/'tests/cinematic_smoke.luau').read_text() + '\n' + (ROOT/'tests/madara_smoke.luau').read_text() + '\n' + (ROOT/'tests/server_smoke.luau').read_text() + '\n' + (ROOT/'tests/broly_sequence_smoke.luau').read_text() + '\ndo\n' + (ROOT/'tests/broly_skill.luau').read_text().replace('local S=require("../src/server/BrolySkill")','local S=loadstring(BROLY_SOURCE,"BrolySkill")()') + '\nend\n'
    with tempfile.TemporaryDirectory() as tmp:
        path=pathlib.Path(tmp)/'regressions.luau';path.write_text(test)
        result=subprocess.run([luau,str(path)],text=True,capture_output=True)
    world=lighting=None
    for line in result.stdout.splitlines():
        if line.startswith('WORLD_JSON:'): world=json.loads(line.removeprefix('WORLD_JSON:'))
        elif line.startswith('LIGHTING_JSON:'): lighting=json.loads(line.removeprefix('LIGHTING_JSON:'))
        else: print(line)
    if result.returncode:
        raise RuntimeError(result.stderr)
    assert world and lighting, 'Map test did not complete'
    return world,lighting
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--luau',default=os.environ.get('LUAU','luau'));p.add_argument('--compiler',default=os.environ.get('LUAU_COMPILE','luau-compile'));args=p.parse_args()
    run(args.luau,args.compiler)
