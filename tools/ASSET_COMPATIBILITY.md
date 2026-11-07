# Asset compatibility recovery

The original Studio upload uses legacy URI properties such as `MeshId`, `TextureID`, `ShirtTemplate`, `PantsTemplate`, `AnimationId`, and `SoundId`. Lune 0.11.1 migrates those to Content properties when exporting. The game export now converts URI-backed Content properties back to the original upload's property names and wire types.

`export_compatible_place.py MODERN_EXPORT.rbxl FINAL.rbxl ORIGINAL_STUDIO_FILE.rbxl`

The converter preserves the instance tree and every asset URI, changes only Content property chunks, and fails rather than silently discarding object-backed or unsupported nonempty content. It uses the system LZ4/Zstandard libraries through Python ctypes.

Character model assets were restored from AnimeRift_Clicker (12).rbxl; speculative head resizing and recoloring were removed. The loader keeps supplied body-joint bindings, resolves duplicate/prefixed body names, and retains the character idles. The requested currency icon HUD and existing map remain.

Validation: 570 nonempty MeshPart mesh IDs; 30 shirt and 30 pants image references; 115 animation IDs; 111 sound IDs; 36 rig preparations; 247 supplied body bindings retained within floating-point precision. Studio-only asset diagnostics report actual loading failures in Output. In-engine appearance remains to be confirmed in Roblox Studio.
