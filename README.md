# Anime Rift — Rainbow Plaza

Open **AnimeRift_Polished.rbxl** (standard binary place), or **AnimeRift_Polished.rbxlx** in Roblox Studio and press **Play (F5)**. The original uploaded place is preserved in `assets/AnimeRift.original.rbxlx`.

This version keeps the original fighters, rigs, sounds, summon economy, product settings, inventory, daily wheel, boss progression, and save-store name. This version follows your supplied references: a bright classic studded garden and a colorful simulator store UI.

Changes:
- Cyan checker headers, dark outlines and white inset borders, rounded colorful buttons, and two-column store/fighter cards. The store's four pack cards fit above the detail section; product purchases still use your configured IDs.
- Separate portrait-phone and desktop layouts, centered notifications, compact number formatting, animated currency counters, health and next-boss progress bars, and animated menu transitions. No fake XP levels were added.
- Lime studded grass, a red avenue, white borders, lavender display platforms and signs, block trees, stepped cliffs, fences, lanterns, cloud clusters, and a five-band neon rainbow. Existing arena/spawn markers and all five gameplay kiosks remain usable.
- Local fireflies, aura sparkles, training ripples and hand sparks, skill effects, a three-second guard shell with a matching countdown, and victory confetti. Existing custom effects and animations take precedence.
- Duplicate animation scripts are removed when importing a playable character clone. Decorative hair and aura pieces no longer participate in touch detection.
- Pending menu-close animations cannot hide a newly opened menu. The boss backdrop clears immediately. Resizing and camera changes reuse a single viewport listener. Notifications fit portrait screens; large coin and strength values fit their labels.
- Existing profile fixes remain: closing blocks external mutations, failed writes retain pending training, and boss completion releases arenas and restores the previous health cap and movement speed.

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

68 deterministic checks passed in the Luau CLI, using the actual config, profile, combat, world, layout, and client UI source with small engine stand-ins. These cover reward pools, wheel weighting, pending training, failed-write recovery, disconnect persistence, boss admission, single reward delivery, arena release/reuse, health restoration, all five shrine prompts, repeatable map generation, layout bounds at six viewport sizes, store and fighter-tab construction, rapid menu reopen, boss backdrop cleanup, and live resizing. The simulated save-outage warning is intentional. All edited scripts compile.

These checks do **not** validate Studio rendering, real DataStore access, replication, physics, uploaded animation/audio permissions, or real purchases. Before publishing, test:

1. Play solo: walk to each shrine, summon, reveal, equip, train, and spin the daily wheel. Confirm the custom summon sounds are authorized for your experience.
2. Boss fight: the menu backdrop disappears immediately; clicking and Q/E/R work; losing, leaving, and winning return you to the lobby. The same arena can be reused.
3. Studio Server & Clients with two players: simultaneous equips and boss fights, then disconnect/rejoin. Test the smallest desktop viewport and the phone/tablet emulator, including text entry and touch movement.
4. A private published test: live saves/rejoins and session locks. Studio keeps disposable data because the existing `StudioMemory=true` setting is preserved.
5. Existing developer-product IDs are still zero; configure IDs belonging to your experience before testing purchases. Existing owner/admin settings are preserved; review them for your account.

The UI selects a dedicated portrait layout on narrow screens; real-device readability and touch hit testing still need Studio/device validation. The map retains the original RiftLayout markers. Move those markers to customize spawn and arena placement; changing lobby geometry itself belongs in `World.luau`.

To convert the rebuilt XML place into the standard binary format, use Lune 0.11.1: `lune run tools/convert_place.luau`. This round-trips the binary and checks instance counts and every script, including duplicate script names.
