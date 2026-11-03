# Anime Rift Clicker — Rift Meadows

Download **AnimeRift_Clicker.rbxl**, open it in **Roblox Studio → File → Open from File**, and press **Play (F5)**. This version replaces the previous boss game. The original upload remains untouched in `assets/AnimeRift.original.rbxlx`, and earlier builds are available in Git history.

## Play loop

1. Click/tap the world or use **Click + Power** to bank power. **F** also clicks when no menu or text box is active.
2. Open **Sell** to convert banked power to coins, at two coins per power.
3. Spend coins on summons and equip stronger fighters to increase power per click.
4. Save enough coins to **Rebirth**: this resets all coins and banked power, grants 25 gems and a permanent +50% base-power multiplier. The first cost is 2,500 coins; subsequent costs scale with `(rebirths + 1)^2`. Gains round up, so the first rebirth helps common fighters too.
5. Use gems for auras, which now boost click power. Existing fighter/aura ownership, tickets, redeemed codes, luck time and purchased rewards are retained when rebirthing.

There are no boss arenas, combat skills, boss rewards, combat HUD, or accepted boss/attack requests. Existing saved strength becomes banked clicker power; old wins remain archived in save data but are not shown or used. The DataStore name is unchanged.

## Joining and expanded roster

Players now see an animated **Anime Rift Clicker** title screen on joining, with a scenic map camera, three-step introduction and a Play button. The game HUD and input remain blocked while profiles load. Slow connections offer Retry; selecting Play restores the camera and movement, fades the title out, and welcomes the player. It appears once per session and does not return on respawn. Mouse/touch, Enter and gamepad A are supported.

The roster now has **40 fighters**, including these 19 additions:

| Rarity | Added fighters |
| --- | --- |
| Rare | Kid Naruto |
| Legendary | Eren Yeager, Denji, Yuta Okkotsu, Super Saiyan Goku |
| Mythic | Yuji Itadori, Deku, Jotaro Kujo, Dio, Gogeta, Vegito, Super Saiyan Blue Goku |
| Secret | Beerus, Boros, Saitama, Golden Experience Requiem |
| Super Secret | Awakened Aizen, Broly, Simon |

The added fighters use stylized built-in block outfits and accessories, including caps, headbands, ears, collars, ties and capes; they do not include newly uploaded anime meshes or animation/audio assets. Inventory previews and live avatars share the same accessory builder. All additions are rollable with earned coins. Tier probabilities are unchanged; each tier's chance is divided across its expanded pool. The odds screens calculate the exact per-fighter values from the current roster. Previously owned fighters and the save-store name are preserved.

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

241 gameplay/UI/cinematic checks pass, plus 16 rig/clothing checks using real Roblox instance types in Lune. The suite executes the actual config, profiles, economy, map, layout, client UI and server request/receipt code with deterministic engine stand-ins. It checks odds, pending-power sales, repeated-sale/recycle protection, rebirth costs/resets/preserved collectibles, unequipped baseline power, ownership validation, profile closing, failed-save recovery, purchase receipt replay, rejection of legacy combat actions, map repeatability, six stations, six viewport sizes, search and menu wiring, title loading/Play/retry/input/camera transitions, all 19 requested rarities and roll pools, and the new accessory builder. The simulated DataStore outage warning is intentional. Binary conversion decodes its output again and verifies instance and script counts/sources.

## Before publishing

Roblox Studio cannot run in this Linux workspace. Automated checks do not validate actual rendering, physics, touch hit testing, rig replication, audio/animation permissions, or live Roblox services.

- Play solo: confirm the title waits for profile loading, Play restores movement/camera, and respawning does not reopen it. Then click → sell → summon → equip → rebirth; confirm power resets and inventory remains. Check search, Equip Best, Unequip All, recycling and the daily wheel.
- Use Studio's phone/tablet emulator and Server & Clients modes to test inventory scrolling, text entry, avatar swaps and two players interacting with stations.
- Use a private published test for real DataStore saves/rejoins and marketplace receipts. Studio uses disposable memory data because the existing `StudioMemory=true` setting is retained.
- Developer-product IDs remain zero until you configure products belonging to your experience. Existing owner/admin settings and imported audio are retained; review permissions for your account/experience.

## R6 model repair, idles and imported UI pack

The loader now repairs missing R6 motors and welds loose visual pieces before unanchoring. R15-style or mesh-only models use a generated R6 carrier with their visual pieces attached to the nearest corresponding body segment. Empty models fall back to the built-in outfit. Imported scripts, old physics constraints and body movers are removed from the runtime clone; original templates remain unchanged. The current player's R6 Animate script supplies locomotion. Visible parts need to be placed correctly in the template: automatic welding cannot reconstruct an unposed mesh or restore a missing asset. Models added only in your local Studio copy must be uploaded with the place for direct inspection.

Small procedural idles vary by character: composed fighters breathe and glance slowly, energetic fighters have a slightly livelier shoulder sway, and heavier fighters have a restrained stance. Walking/jumping/seated poses take priority; clicking temporarily yields the affected shoulder to the punch effect. Inventory portraits gently bob and turn. These are procedural accents, not newly uploaded character-specific animation clips.

The original upload already includes `ServerStorage/LunarSoundSaves/Free_UI_Pack/MegaPack`. The build imports its visual templates into `ReplicatedStorage/AnimeRift/Assets/UIMegaPack`, removes its executable scripts, and uses its artwork on navigation, Sell and Rebirth controls. Roblox returned HTTP 401 for the requested asset `91372521068960`, so the linked store version could not be independently downloaded or compared. To use that exact version if it differs, import/download it in Studio and supply the `.rbxm` file. Existing icon image permissions still need a Studio test.

Extra raised grass studs and native stud surfaces make the plaza and fallback bodies more studded. Run `python3 tools/test_rigs.py --lune /path/to/lune` to check missing-joint and loose-model fixtures plus all 12 original imported rigs. Lune's geometry-method stand-ins test structure, not real Roblox physics, scaling fidelity, animation playback, or network ownership. Check the resulting characters in Studio with two clients before publishing.

## Side navigation and clothing preservation

The original styled buttons retain their pack icons and now form an eight-button, two-column grid on the left. Only the main click action remains along the bottom. **Sell Power** at the top immediately converts banked power to coins; the side Sell icon opens the explanatory Sell menu. **Base** returns the player to the clicking court, and **Shop** opens the store. Desktop dialogs sit to the right of the side grid. Currency and progress indicators remain visible without adding extra bottom navigation buttons.

Carrier conversion now moves classic Shirts, Pants, ShirtGraphics and BodyColors onto the R6 Humanoid model. Covered R6 body parts are visible, and the corresponding untextured visual body pieces are hidden; head/accessory meshes and textured parts outside those clothing regions remain preserved. Canonical R6 models keep their authored clothing. This fixes a known hierarchy problem but cannot supply missing clothing assets or guarantee layered-clothing conversion. The current edited place file has not been provided with the latest screenshot, so specific locally modified characters still need inspection and Studio rendering tests.

## Character-specific high-tier summon cutscenes

All **26 Mythic, Secret and Super Secret fighters** have a distinct themed reveal in `src/shared/SummonPresets.luau`. Examples include Gojo's blue/purple convergence, Sukuna's crimson cuts, Deku's emerald storm, Dio's reversing clock, Saitama's horizon burst, Broly's green detonation and Simon's rising spiral. A shared renderer combines each fighter's own palette, timing, motif, phrase and pose direction; these are short stylized viewport cinematics, not newly uploaded animation clips or story videos.

Mythic scenes last **3.2 seconds**, Secret scenes **3.8 seconds**, and Super Secret scenes **4.4 seconds**. Ordinary fighters and cosmetic rolls keep their quick crate reveal. Each scene has a visible Skip button and supports Space/gamepad B. Skipping proceeds to the saved reward card; Keep dismisses it before the next queued reveal. Rewards were already committed by the server and are never granted, rerolled or equipped by the cinematic.

Resource limits:

- One local scene at a time; no world physics, gameplay-camera takeover or new network requests.
- At most **72 effect/UI instances**, excluding one bounded character preview, with 8–18 reusable GUI shards and three rings. No Instances are created during frame updates.
- Cinematic previews cap imported rigs at **64 body parts / 256 descendants**. Oversized rigs use the built-in block outfit. Embedded emitters, beams, trails, lights and sounds are removed from the cinematic clone and high-tier reward-card preview.
- Updates are capped at **30 Hz**; touch/reduced-effects mode uses **24 Hz** and at most ten shards. Background HUD previews pause while the cinematic runs.
- Completion, Skip, respawn, replacement, setup failure and overlay removal disconnect the renderer and destroy the scene. Invalid previews still expose a fallback reward card. The impact uses a short UI click. Character voice lines start on the visible reward card only after the build-up overlay has been removed; Skip moves directly to that voice/reward phase. Closing the card stops the voice. No new audio uploads are required.

In **Studio**, press **F8 → Preview Summon Cutscenes → choose a fighter** to review all 26 without coins, tickets or rewards. Live admins can also access the local preview menu. Previews explicitly say no fighter was granted.

The 241 checks include every preset's coverage/uniqueness, all 26 scene completions, effect budgets, zero per-frame Instance allocation, reduced effects, throttling, Skip/cleanup, malformed and oversized rigs, FIFO reward cards, camera preservation and preview-only behavior. Simulated preview-failure warnings in the test output are intentional. Actual visual polish, frame rate on devices and sound permissions still need Roblox Studio/device testing.

### Brighter scenes and voice-line sequencing

The cutscene gradient now lives on its own mid-tone backdrop Frame rather than tinting the entire CanvasGroup composite. Character previews use white key lighting and bright neutral ambient light. Particles and the soft tint wash stay behind the actor, with smaller letterbox bars and faster opening visibility. These changes preserve the same local effect/preview limits.

Custom voice audio no longer starts at the 52% impact cue. The sequence is **visual build-up → scene closes → reward/character card appears → voice line starts**. Normal completion and Skip both enter this final voice phase; malformed preview fallback and respawn cancellation do not start a new voice. Tests check that audio never starts during the build-up and that the overlay is gone and the HUD visible before playback begins. Actual visual/audio verification still requires Studio.
