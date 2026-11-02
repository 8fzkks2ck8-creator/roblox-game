# Anime Rift Clicker — Rift Meadows

Download **AnimeRift_Clicker.rbxl**, open it in **Roblox Studio → File → Open from File**, and press **Play (F5)**. This version replaces the previous boss game. The original upload remains untouched in `assets/AnimeRift.original.rbxlx`, and earlier builds are available in Git history.

## Play loop

1. Click/tap the world or use **Click + Power** to bank power. **F** also clicks when no menu or text box is active.
2. Open **Sell** to convert banked power to coins, at two coins per power.
3. Spend coins on summons and equip stronger fighters to increase power per click.
4. Save enough coins to **Rebirth**: this resets all coins and banked power, grants 25 gems and a permanent +50% base-power multiplier. The first cost is 2,500 coins; subsequent costs scale with `(rebirths + 1)^2`. Gains round up, so the first rebirth helps common fighters too.
5. Use gems for auras, which now boost click power. Existing fighter/aura ownership, tickets, redeemed codes, luck time and purchased rewards are retained when rebirthing.

There are no boss arenas, combat skills, boss rewards, combat HUD, or accepted boss/attack requests. Existing saved strength becomes banked clicker power; old wins remain archived in save data but are not shown or used. The DataStore name is unchanged.

## Inventory and map

The inventory follows the latest reference: orange studded header, charcoal panels, rarity-colored cards, and individual equip buttons. **Equip Best** picks your strongest owned fighter; **Unequip All** returns to baseline clicking. Search matches names or rarities and keeps keyboard focus while filtering. **Recycle** needs a second confirmation click within eight seconds and only sells extra copies for 25 coins each; it retains one of every fighter, including the equipped fighter. The grid uses five columns on desktop and three on portrait phones.

**Rift Meadows** is a new map inspired by the earlier garden photo, with red studded paths, lime lawns, block trees, a rainbow, a stream and footbridges, a fountain, flower planters, and a clicking court. Six stations open Sell, Rebirth, Summon, Auras, Store and Daily Wheel. Native stud surfaces and a limited number of raised avenue studs keep geometry modest. Old arena markers and loose props from the previous map are omitted from active exports. The original imported character models and summon sounds remain preserved.

Animations and effects include button bounce, menu transitions, reward counters, floating power text, training hand sparks/ripples, local ambient fireflies, aura particles and rebirth confetti. Character clones remove duplicate Animate scripts. No uploaded image is required for the inventory's stud pattern.

## Develop and rebuild

Use the existing isolated checkout; no additional Git worktree is needed. Source files live in `src/client`, `src/server` and `src/shared`. `Clicker.luau` contains server economy mutations, `Avatars.luau` handles outfits/rig swaps, and `World.luau` builds the map.

Requires Python 3, the official Luau CLI/compiler, and Lune 0.11.1 for binary conversion. In the prepared cloud environment:

```sh
cd /workspace/roblox-game
python3 tools/build_place.py \
  --luau /workspace/scratch/luau-toolchain/luau \
  --compiler /workspace/scratch/luau-toolchain/luau-compile
/workspace/scratch/lune-bin/lune run tools/convert_place.luau
```

On another machine, place `luau`, `luau-compile`, and `lune` on PATH, then run `python3 tools/build_place.py` and `lune run tools/convert_place.luau`. The converter also accepts explicit input/output paths. Rebuilding starts from the preserved original asset file, injects the current modules, removes the retired combat module/arena props, and serializes an edit-view map. World.Build recreates runtime attributes when Play begins. Rebuilding the XML alone does not refresh the binary; run both commands.

Checks without rebuilding:

```sh
python3 tools/validate.py --luau /path/to/luau --compiler /path/to/luau-compile
```

92 automated checks pass. The suite executes the actual config, profiles, economy, map, layout, client UI and server request/receipt code with deterministic engine stand-ins. It checks odds, pending-power sales, repeated-sale/recycle protection, rebirth costs/resets/preserved collectibles, unequipped baseline power, ownership validation, profile closing, failed-save recovery, purchase receipt replay, rejection of legacy combat actions, map repeatability, six stations, six viewport sizes, search and menu wiring. The simulated DataStore outage warning is intentional. Binary conversion decodes its output again and verifies instance and script counts/sources.

## Before publishing

Roblox Studio cannot run in this Linux workspace. Automated checks do not validate actual rendering, physics, touch hit testing, rig replication, audio/animation permissions, or live Roblox services.

- Play solo: click → sell → summon → equip → rebirth; confirm power resets and inventory remains. Check search, Equip Best, Unequip All, recycling and the daily wheel.
- Use Studio's phone/tablet emulator and Server & Clients modes to test inventory scrolling, text entry, avatar swaps and two players interacting with stations.
- Use a private published test for real DataStore saves/rejoins and marketplace receipts. Studio uses disposable memory data because the existing `StudioMemory=true` setting is retained.
- Developer-product IDs remain zero until you configure products belonging to your experience. Existing owner/admin settings and imported audio are retained; review permissions for your account/experience.
