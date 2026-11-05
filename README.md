# Anime Rift Clicker — Rift Meadows

Download **AnimeRift_Clicker.rbxl**, open it in **Roblox Studio → File → Open from File**, and press **Play (F5)**. This version replaces the previous boss game. The original upload remains untouched in `assets/AnimeRift.original.rbxlx`, and earlier builds are available in Git history.

## Current rig repair and editable signature scenes

The current exports preserve the supplied `AnimeRift_Clicker (7).rbxl`, retained unchanged as `assets/AnimeRift.with-packs.rbxl`. They contain 13 authored models. If your current Studio place contains additional models or asset edits, use that place as updater input or supply it before replacing it with these exports.

Complete R15 models now retain their 15 articulated joints instead of being flattened into R6 carriers. Nested StarterCharacters are recognized, missing invisible wrist endpoints can be repaired, and authored RigAttachments rebuild a neutral skeleton. R6 joints use size-aware neutral shoulder/hip/head anchors. Cosmetic welds are resolved in both directions and follow the correct segment. Humanoid scaling is disabled on custom R15 rigs. The code no longer reuses an R15 Animate script on an R6 rig. The regression suite solves the actual joint chains and checks connected limbs and unchanged part sizes; it does not rely solely on checking C0 values.

All 40 fighters have distinct procedural walk direction in `IdleMotion.WalkProfile`: Naruto's forward shinobi stride, Madara's measured march, Broly's heavy stride, Aizen's composed pace, and others. All 26 Mythic-through-Super-Secret fighters keep individual signature idles. Corrected arm/elbow flexion raises hands toward the front rather than folding them backward. Idles are softened to avoid self-intersection. Walking, jumping, punches, seating and death retain their state handoffs. Bone-only or single-solid-mesh models still require rigging; imported models with unfamiliar naming need inspection.

Every Mythic-and-up fighter has a unique setting/signature recipe in `SignatureSets.luau` (Madara uses `MadaraSequence.luau`): Gojo's Infinity courtyard/converging orbs, Ichigo's moonlit rooftop/crescent, Aizen's mirror causeway/shattering mirrors, Broly's shattered canyon/power flare, Simon's cosmic spiral/drill, and 21 others. Mythic scenes last 6.4 seconds, Secret 8 seconds, Super Secret 9.6 seconds. Madara retains his 9.6-second cliff, “Too big for rain?” dialogue, four meteors and white fade. Missing character models show the saved reward card instead of a generated stand-in; recipes for missing models are ready when those models are supplied.

Summons now use a client-only **world stage**, so the supplied pack's ParticleEmitters can actually render. The actor, scenery and FX are anchored and non-colliding in an isolated location; the gameplay character is not teleported. The scripted camera and movement/Skip bindings are restored on completion, Skip, cancellation, replacement or failure. Geometry/projection and lifecycle tests do not replace Studio rendering/device tests.

The renderer keeps pose calculations in a hidden WorldModel and copies only finalized transforms into a separate anchored render clone. Visible parts and particle anchors never shuttle through the map origin. It reuses the existing gameplay camera without swapping camera objects, restores its frame/focus/lens state afterward, and cancels if another system selects a different camera. Regression checks cover 60 consecutive updates and camera ownership loss.

### Swap meshes, VFX and sound in Studio

Stop Play first. In Explorer, open:

`ReplicatedStorage → AnimeRift → Assets → Cutscenes → madara` (or another fighter ID).

- **Meshes/Meteor**: replace this MeshPart with your meteor mesh, retaining the name `Meteor`. Madara fits it to the giant meteor bounds. Other fighters use **Meshes/SignatureMesh** for their signature effect geometry.
- **Meshes/StageMesh**: optional empty Folder slot. Replace the Folder with a MeshPart named `StageMesh` to replace the central stage/cliff surface. This replaces scenery, never the character.
- **OpeningFX**, **ChargeFX**, **ImpactFX**: replace each with a Part or Model containing your Attachments/ParticleEmitters, retaining the slot name. Author around its local origin. Emitters burst at the corresponding cue; attached scripts/audio are stripped from runtime clones.
- **OpeningSFX**, **ChargeSFX**, **ImpactSFX**: edit these Sounds' `SoundId`, volume and playback speed. Blank SoundIds remain silent. The default impact sound is the supplied pack's boom, asset `9114828835`.
- **Dialogue**: Madara's line, initially `135791921703430`. Change its SoundId or clear it to silence the line. Other fighters' existing voices remain under `Assets/SummonSounds` and play on the reward card.
- Add a **CueProgress** number attribute (0–1) to an FX root or cue Sound to move its cue within the scene. Add **EmitCount** to individual ParticleEmitters to choose the burst size. Scene sequencing code need not change for these asset swaps.

Custom VFX are bounded to 48 descendants per template, 160 total template instances, 12 emitters, a maximum of 40 particles per emitter/120 per cue (10/48 on reduced effects), and a two-second particle lifetime. Oversized templates are skipped with a warning. Character previews remain bounded to 192 parts/1,024 descendants before and after rig preparation. Custom mesh surfaces are fitted to the scene; particle/audio asset permissions still need a Studio check. Frame updates allocate no Instances.

The full PDS source pack remains under `ServerStorage/AnimeRiftSourcePacks`. Scene slots contain sanitized copies of its particles and meshes. Editing slots does not change the source pack. The updater preserves existing slot edits when run against your edited place instead of the original base.

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

Added fighters without supplied models still use the existing outfits during gameplay. The latest upload supplies a real Broly model; cutscenes and high-tier reward portraits never use generated block substitutes. All additions are rollable with earned coins. Tier probabilities are unchanged; each tier's chance is divided across its expanded pool. The odds screens calculate the exact per-fighter values from the current roster. Previously owned fighters and the save-store name are preserved.

## Inventory and map

The inventory follows the latest reference: orange studded header, charcoal panels, rarity-colored cards, and individual equip buttons. **Equip Best** picks your strongest owned fighter; **Unequip All** returns to baseline clicking. Search matches names or rarities and keeps keyboard focus while filtering. **Recycle** needs a second confirmation click within eight seconds and only sells extra copies for 25 coins each; it retains one of every fighter, including the equipped fighter. The grid uses five columns on desktop and three on portrait phones.

**Rift Meadows** is a new map inspired by the earlier garden photo, with red studded paths, lime lawns, block trees, a rainbow, a stream and footbridges, a fountain, flower planters, and a clicking court. Six stations open Sell, Rebirth, Summon, Auras, Store and Daily Wheel. Native stud surfaces and a limited number of raised avenue studs keep geometry modest. Old arena markers and loose props from the previous map are omitted from active exports. The original imported character models and summon sounds remain preserved.

Animations and effects include button bounce, menu transitions, reward counters, floating power text, training hand sparks/ripples, local ambient fireflies, aura particles and rebirth confetti. Character clones remove duplicate Animate scripts. No uploaded image is required for the inventory's stud pattern.

## Develop and rebuild

Use the existing isolated checkout; no additional Git worktree is needed. Source files live in `src/client`, `src/server` and `src/shared`. `Clicker.luau` contains server economy mutations, `Avatars.luau` handles outfits/rig swaps, and `World.luau` builds the map.

Requires Python 3, official Luau 0.745 CLI/compiler, and Lune 0.11.1. Rebuild the current uploaded place with its model/VFX packs preserved:

```sh
cd /workspace/roblox-game
/workspace/scratch/lune-bin/lune run tools/update_uploaded_place.luau \
  assets/AnimeRift.with-packs.rbxl AnimeRift_Clicker.rbxl \
  src/client/Client.client.luau src/shared/Config.luau \
  src/shared/IdleMotion.luau src/shared/SummonCinematics.luau \
  src/shared/SummonPresets.luau src/shared/MadaraSequence.luau \
  src/shared/BrolySequence.luau src/shared/CutsceneStage.luau \
  src/shared/SignatureSets.luau src/shared/RigRepair.luau src/shared/Polish.luau \
  src/server/Avatars.luau
```

The updater writes binary plus matching XML and never executes embedded scripts. It archives the showcase kit, stages its meteor mesh, injects the listed modules, and checks the complete property graph after binary roundtripping. Only Roblox's compact near-axis rotation normalization is tolerated. Other user world/asset edits are preserved. Generated place files are treated as binary in Git; editable scripts live in `src`. The older `build_place.py` pipeline starts from `assets/AnimeRift.original.rbxlx` and rebuilds the baseline map; it does not retain additions from the newer upload.

Checks without rebuilding:

```sh
python3 tools/validate.py --luau /path/to/luau --compiler /path/to/luau-compile
python3 tools/test_cinematic_models.py --lune /path/to/lune
python3 tools/test_locomotion.py --lune /path/to/lune --place assets/AnimeRift.with-packs.rbxl
```

308 gameplay/UI/cinematic checks pass, plus 16 rig/clothing checks, 26 locomotion cases, 27 custom-idle checks and a solved-skeleton/40-walk regression using real Roblox instance types in Lune. The standalone cinematic geometry suite also checks all 13 uploaded rigs and the actual Broly skill model. Run `python3 tools/test_locomotion.py --lune /workspace/scratch/lune-bin/lune --place assets/AnimeRift.with-packs.rbxl` for the locomotion cases. The suite executes the actual config, profiles, economy, map, layout, client UI and server request/receipt code with deterministic engine stand-ins. It checks odds, pending-power sales, repeated-sale/recycle protection, rebirth costs/resets/preserved collectibles, unequipped baseline power, ownership validation, profile closing, failed-save recovery, purchase receipt replay, rejection of legacy combat actions, map repeatability, six stations, six viewport sizes, search and menu wiring, title loading/Play/retry/input/camera transitions, all 19 requested rarities and roll pools, the accessory builder, and Broly's skill timing, eligibility, bonus, presentation and cleanup. The simulated DataStore outage warning is intentional. Binary conversion decodes its output again and verifies instance and script counts/sources.

## Before publishing

Roblox Studio cannot run in this Linux workspace. Automated checks do not validate actual rendering, physics, touch hit testing, rig replication, audio/animation permissions, or live Roblox services.

- Play solo: confirm the title waits for profile loading, Play restores movement/camera, and respawning does not reopen it. Then click → sell → summon → equip → rebirth; confirm power resets and inventory remains. Check search, Equip Best, Unequip All, recycling and the daily wheel.
- Use Studio's phone/tablet emulator and Server & Clients modes to test inventory scrolling, text entry, avatar swaps and two players interacting with stations.
- Use a private published test for real DataStore saves/rejoins and marketplace receipts. Studio uses disposable memory data because the existing `StudioMemory=true` setting is retained.
- Developer-product IDs remain zero until you configure products belonging to your experience. Existing owner/admin settings and imported audio are retained; review permissions for your account/experience.

## R6 model repair, idles and imported UI pack

The loader now repairs missing R6 motors and welds loose visual pieces before unanchoring. Complete R15 rigs keep their native skeleton; only incomplete or mesh-only models use an invisible R6 carrier with attached visual pieces. Empty models fall back to the built-in outfit. Imported scripts, old physics constraints and body movers are removed from the runtime clone; original templates remain unchanged. Procedural walking supplies movement poses; the existing Animate script retains jump/fall and other states. Visible parts need to be placed correctly in the template: automatic welding cannot reconstruct an unposed mesh or restore a missing asset. Models added only in your local Studio copy must be uploaded with the place for direct inspection.

Small procedural idles vary by character: composed fighters breathe and glance slowly, energetic fighters have a slightly livelier shoulder sway, and heavier fighters have a restrained stance. Walking/jumping/seated poses take priority; clicking temporarily yields the affected shoulder to the punch effect. Inventory portraits gently bob and turn. These are procedural accents, not newly uploaded character-specific animation clips.

The original upload already includes `ServerStorage/LunarSoundSaves/Free_UI_Pack/MegaPack`. The build imports its visual templates into `ReplicatedStorage/AnimeRift/Assets/UIMegaPack`, removes its executable scripts, and uses its artwork on navigation, Sell and Rebirth controls. Roblox returned HTTP 401 for the requested asset `91372521068960`, so the linked store version could not be independently downloaded or compared. To use that exact version if it differs, import/download it in Studio and supply the `.rbxm` file. Existing icon image permissions still need a Studio test.

Extra raised grass studs and native stud surfaces make the plaza and fallback bodies more studded. Run `python3 tools/test_rigs.py --lune /path/to/lune` to check missing-joint and loose-model fixtures plus all 12 original imported rigs. Lune's geometry-method stand-ins test structure, not real Roblox physics, scaling fidelity, animation playback, or network ownership. Check the resulting characters in Studio with two clients before publishing.

## Side navigation and clothing preservation

The original styled buttons retain their pack icons and now form an eight-button, two-column grid on the left. Only the main click action remains along the bottom. **Sell Power** at the top immediately converts banked power to coins; the side Sell icon opens the explanatory Sell menu. **Base** returns the player to the clicking court, and **Shop** opens the store. Desktop dialogs sit to the right of the side grid. Currency and progress indicators remain visible without adding extra bottom navigation buttons.

Carrier conversion now moves classic Shirts, Pants, ShirtGraphics and BodyColors onto the R6 Humanoid model. Covered R6 body parts are visible, and the corresponding untextured visual body pieces are hidden; head/accessory meshes and textured parts outside those clothing regions remain preserved. Canonical R6 models keep their authored clothing. This fixes a known hierarchy problem but cannot supply missing clothing assets or guarantee layered-clothing conversion. The current edited place file has not been provided with the latest screenshot, so specific locally modified characters still need inspection and Studio rendering tests.

## Character-specific high-tier summon cutscenes

All **26 Mythic, Secret and Super Secret fighters** have a distinct themed reveal in `src/shared/SummonPresets.luau`. Examples include Gojo's blue/purple convergence, Sukuna's crimson cuts, Deku's emerald storm, Dio's reversing clock, Saitama's horizon burst, Broly's green detonation and Simon's rising spiral. A shared renderer combines each fighter's own palette, timing, motif, phrase and pose direction; these are short stylized local-world cinematics, not newly uploaded animation clips or story videos.

Mythic scenes last **6.4 seconds**, Secret scenes **8 seconds**, and Super Secret scenes **9.6 seconds**. Madara uses his dedicated **9.6-second** sequence. Ordinary fighters and cosmetic rolls keep their quick crate reveal. Each scene has a visible Skip button and supports Space/gamepad B. Skipping proceeds to the saved reward card; Keep dismisses it before the next queued reveal. Rewards were already committed by the server and are never granted, rerolled or equipped by the cinematic.

Resource limits:

- One client-only anchored world scene at a time; no gameplay physics or new reward requests. A scripted camera temporarily presents the local set and restores the previous camera afterward.
- At most **112 procedural effect/UI instances**, plus bounded user VFX templates, excluding one bounded character preview, with up to ten reusable GUI shards, two rings and a bounded spatial energy/debris pool. No Instances are created during frame updates.
- Cinematic previews cap imported rigs at **192 body parts / 1,024 descendants**. Missing or oversized rigs skip the scene and show the reward card; they never use a block substitute. Embedded emitters, beams, trails, lights and sounds are removed from the cinematic clone and high-tier reward-card preview.
- Updates are capped at **30 Hz**; touch/reduced-effects mode uses **24 Hz** and at most six shards. Background HUD previews pause while the cinematic runs.
- Completion, Skip, respawn, replacement, setup failure and overlay removal disconnect the renderer and destroy the scene. Invalid previews still expose a fallback reward card. The impact uses a short UI click. Except for Madara's explicitly timed dialogue, character voice lines start on the visible reward card only after the build-up overlay has been removed; Skip moves directly to that voice/reward phase. Closing the card stops the voice. No new audio uploads are required.

In **Studio**, press **F8 → Preview Summon Cutscenes → choose a fighter** to review all 26 without coins, tickets or rewards. Live admins can also access the local preview menu. Previews explicitly say no fighter was granted.

The checks include every preset's coverage/uniqueness, all 26 scene completions, effect budgets, zero per-frame Instance allocation, reduced effects, throttling, Skip/cleanup, malformed and oversized rigs, FIFO reward cards, camera preservation and preview-only behavior. Simulated preview-failure warnings in the test output are intentional. Actual visual polish, frame rate on devices and sound permissions still need Roblox Studio/device testing.

### Brighter scenes and voice-line sequencing

The cutscene gradient now lives on its own mid-tone backdrop Frame rather than tinting the entire CanvasGroup composite. Character previews use white key lighting and bright neutral ambient light. Particles and the soft tint wash stay behind the actor, with smaller letterbox bars and faster opening visibility. These changes preserve the same local effect/preview limits.

Apart from Madara's dedicated in-scene dialogue, custom voice audio follows **visual build-up → scene closes → reward/character card appears → voice line starts**. Normal completion and Skip both enter this final voice phase; malformed preview fallback and respawn cancellation do not start a new voice. Tests check that these reward voices never start during the build-up and that the overlay is gone and the HUD visible before playback begins. Actual visual/audio verification still requires Studio.

## Broly exclusive skill: Legendary Rage

Own and equip **Broly**, then press **G** or the **Legendary Rage** side button. A 26-second sequence rebuilds the supplied video's visible action after its opening emote-selection menu: face close-ups, a braced power-up, expanding green energy, a tall aura pillar, levitation, a moon backdrop and orbit, a cyclone, and landing. The actor uses the equipped character's bounded clone with procedural R6 poses and attached costume pieces. This is a reconstruction from the video; the original animation, meshes and VFX project were not supplied, so it is not a frame-perfect asset copy.

After the **26-second server charge**, Broly grants **3x click power for 20 seconds**. The cooldown is **90 seconds from activation**. Training is blocked during the charge. Skipping the visuals does not advance the charge or grant power. Death, respawn, unequipping or losing Broly cancels the charge/bonus and retains the remaining cooldown. The skill changes no saved inventory or currencies directly; boosted clicks use the existing server training path.

The dedicated emote audio uses **`rbxassetid://119358500041991`** in `C.BrolySkill.SoundId` and preloads once when Broly is equipped. It plays with this skill's presentation and stops when it closes. The extracted 26-second reference audio is also saved in `assets/Broly_Legendary_Rage_audio.mp3`. Existing summon voice lines still wait until their reveal finishes. The supplied asset's playback permission, length and exact synchronization must be checked in Studio.

The skill uses one local viewport actor, a maximum of **96 effect/UI instances**, and reusable energy pillars, lightning, debris, rings and sparks. It creates no Instances during frame updates. Updates run at **30 Hz**, or **24 Hz with fewer effects** on touch/reduced-effects mode. The preview allows **192 body parts / 1,024 descendants**, including the supplied 96-part Broly. Gameplay camera and world physics are untouched; movement/input are temporarily suspended for the presentation and restored on completion, Skip or cancellation.

In Studio, use **F8 → Preview Summon Cutscenes → Preview Broly Skill** for a local preview without owning Broly or receiving a bonus. Test the real skill with Broly equipped to check the charge, bonus and cooldown. Automated checks exercise those authority rules, costume attachment, timeline phases, fixed instance budgets, reduced effects, queued summons, audio configuration, death and cleanup. Real rendering, animation fidelity, audio permissions and device performance remain Studio/device checks.
