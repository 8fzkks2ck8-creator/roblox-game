#!/usr/bin/env python3
"""Exercise cinematic geometry against real serialized rigs using Lune Roblox types."""
import argparse
import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("--lune", default="lune")
parser.add_argument("--place", type=pathlib.Path, default=ROOT / "assets/AnimeRift.with-packs.rbxl")
args = parser.parse_args()
source = (ROOT / "tests/cinematic_models.luau").read_text()
for marker, path in {
    "__RIG_SOURCE__": "src/shared/RigRepair.luau",
    "__STAGE_SOURCE__": "src/shared/CutsceneStage.luau",
    "__SETS_SOURCE__": "src/shared/SignatureSets.luau",
    "__PRESETS_SOURCE__": "src/shared/SummonPresets.luau",
    "__MADARA_SOURCE__": "src/shared/MadaraSequence.luau",
    "__CINEMATICS_SOURCE__": "src/shared/SummonCinematics.luau",
    "__BROLY_TIMELINE_SOURCE__": "src/shared/BrolyTimeline.luau",
    "__BROLY_POSE_SOURCE__": "src/shared/BrolyPose.luau",
    "__BROLY_SEQUENCE_SOURCE__": "src/shared/BrolySequence.luau",
}.items():
    source = source.replace(marker, (ROOT / path).read_text())
with tempfile.TemporaryDirectory() as temporary:
    runner = pathlib.Path(temporary) / "cinematic_models.luau"
    runner.write_text(source)
    subprocess.run([args.lune, "run", str(runner), str(args.place.resolve())], cwd=ROOT, check=True)
