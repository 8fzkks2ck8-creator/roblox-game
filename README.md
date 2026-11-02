# Anime Rift — Lantern Sanctuary

Open **AnimeRift_Polished.rbxl** (standard binary place), or **AnimeRift_Polished.rbxlx** in Roblox Studio and press **Play (F5)**. The original uploaded place is preserved in `assets/AnimeRift.original.rbxlx`.

This version keeps the original fighters, rigs, sounds, summon economy, product settings, inventory, daily wheel, boss progression, and save-store name. No reference screenshot was supplied; the new visual direction is a purple/cyan shrine garden with warm lanterns.

Changes:
- Rounded buttons, softer borders, cleaner typography, simpler decorative patterns, animated boss health, Escape to close menus, and tap-to-train outside UI.
- Sakura trees, reflecting pools, shrine kiosks, illuminated paths, floating orbs, and clearer arena spaces. The generated world is substantially smaller than the old stud-heavy map.
- Training ripples, hand sparks and punch motion, summon tint pulses, built-in skill effects and casting poses when custom assets are absent. Existing custom effects and animations take precedence.
- Boss entry immediately removes the modal backdrop; overlapping avatar-decoration calls are guarded; boss exit restores the previous health cap and movement speed.
- Profile changes stop during disconnect saving, pending strength survives failed writes, duplicate close callers wait for completion, and older saves receive missing fields without resetting progress.
- Leaving a boss is allowed while another request is pending. Training pauses while a text box is focused. Unknown reveal rewards no longer break the reveal UI.

## Editing and rebuilding

`src/client` contains the main UI. `src/server` contains profiles, map generation, combat, and server requests. `src/shared` contains configuration, effects, and client-only polish. Edit these files, then rebuild to update the place; rebuilding always starts from the preserved original asset file.

Requires Python 3 and the official Luau CLI/compiler. In the prepared cloud workspace:

```sh
cd /workspace/roblox-game
python3 tools/build_place.py \
  --luau /workspace/scratch/luau-toolchain/luau \
  --compiler /workspace/scratch/luau-toolchain/luau-compile
```

On other machines, put `luau` and `luau-compile` on PATH and run `python3 tools/build_place.py`. This command compiles the edited scripts, runs the regression tests, serializes a static map preview, injects the scripts into the original place, and verifies the exported sources and preserved asset subtree. `World.Build` recreates the map and its runtime attributes when Play begins. Use the existing checkout; no additional Git worktree is needed.

Run checks without rebuilding:

```sh
python3 tools/validate.py --luau /path/to/luau --compiler /path/to/luau-compile
```

## Validation and Studio checks

44 deterministic checks passed in the Luau CLI, using the actual config, profile, combat, and world modules with small engine stand-ins. These cover reward pools, wheel weighting, pending training, failed-write recovery, disconnect persistence, boss admission, single reward delivery, arena release/reuse, health restoration, all five shrine prompts, and repeatable map generation. The simulated save-outage warning is intentional. All edited scripts compile.

These checks do **not** validate Studio rendering, real DataStore access, replication, physics, uploaded animation/audio permissions, or real purchases. Before publishing, test:

1. Play solo: walk to each shrine, summon, reveal, equip, train, and spin the daily wheel. Confirm the custom summon sounds are authorized for your experience.
2. Boss fight: the menu backdrop disappears immediately; clicking and Q/E/R work; losing, leaving, and winning return you to the lobby. The same arena can be reused.
3. Studio Server & Clients with two players: simultaneous equips and boss fights, then disconnect/rejoin. Test the smallest desktop viewport and the phone/tablet emulator, including text entry and touch movement.
4. A private published test: live saves/rejoins and session locks. Studio keeps disposable data because the existing `StudioMemory=true` setting is preserved.
5. Existing developer-product IDs are still zero; configure IDs belonging to your experience before testing purchases. Existing owner/admin settings are preserved; review them for your account.

The fixed canvas scales to the viewport, but portrait-phone readability still needs device testing. The map retains the original RiftLayout markers. Move those markers to customize spawn and arena placement; changing lobby geometry itself belongs in `World.luau`.

To convert the rebuilt XML place into the standard binary format, use Lune 0.11.1: `lune run tools/convert_place.luau`. This round-trips the binary and checks instance counts and every script, including duplicate script names.
