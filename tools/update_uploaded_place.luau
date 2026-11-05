-- Patch selected source modules into an uploaded place without rebuilding its world.
-- Archive the PDS showcase in ServerStorage and expose its single meteor mesh.
-- Usage from repository root:
-- lune run tools/update_uploaded_place.luau INPUT.rbxl OUTPUT.rbxl src/shared/Example.luau ...
-- Embedded scripts are serialized as data; this tool never executes them.
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local process = require("@lune/process")
local args = process.args
assert(#args >= 3, "Expected input, output and at least one selected source path")
assert(args[1] ~= args[2], "Never overwrite the uploaded input")
local input = fs.readFile(args[1]):gsub("^<%?xml.-%?>%s*", "")
local place = roblox.deserializePlace(input)
local originalCount = #place:GetDescendants()
local additions = 0
local patched = {}
local function child(parent, name)
 local item = parent:FindFirstChild(name)
 assert(item, "Missing place container " .. name)
 return item
end
local function folder(parent, name)
 local item = parent:FindFirstChild(name)
 if not item then
  item = roblox.Instance.new("Folder"); item.Name = name; item.Parent = parent
  additions += 1
 end
 assert(item:IsA("Folder"), "Expected folder " .. name)
 return item
end
-- Imported showcase geometry belongs in an asset library rather than the live
-- game world. Preserve the complete authored kit (including its inert scripts).
local kit = child(child(place, "Workspace"), "PDS' Particles & Models Kit")
local storage = folder(child(place, "ServerStorage"), "AnimeRiftSourcePacks")
assert(not storage:FindFirstChild(kit.Name), "An archived kit already exists")
kit.Parent = storage
local sourceMeshes = child(child(kit, "PDS Models Pack for BSED:R"), "Meshes")
local rock = child(sourceMeshes, "Icosphere")
assert(rock:IsA("MeshPart"), "Expected the authored Icosphere MeshPart")
local assets = child(child(child(place, "ReplicatedStorage"), "AnimeRift"), "Assets")
local cinematicMeshes = folder(assets, "CinematicMeshes")
assert(not cinematicMeshes:FindFirstChild("MeteorRock"), "A MeteorRock template already exists")
local meteor = rock:Clone()
meteor.Name = "MeteorRock"
local appearanceKept = false
for _,item in meteor:GetChildren() do
 if item:IsA("SurfaceAppearance") and not appearanceKept then
  appearanceKept = true
  for _,nested in item:GetChildren() do nested:Destroy() end
 else
  item:Destroy()
 end
end
meteor.Anchored = true
meteor.CanCollide = false
meteor.CanTouch = false
meteor.CanQuery = false
meteor.Parent = cinematicMeshes
additions += 1 + #meteor:GetDescendants()
for index = 3, #args do
 local path = args[index]
 local section, filename = path:match("^src/(%w+)/([^/]+)%.luau$")
 assert(section and filename, "Expected a direct src/client, src/server or src/shared Luau file")
 local parent, class, name
 if section == "shared" then
  parent = child(child(place, "ReplicatedStorage"), "AnimeRift")
  class = "ModuleScript"
  name = filename
 elseif section == "server" then
  parent = child(place, "ServerScriptService")
  name = filename:gsub("%.server$", "")
  class = filename:match("%.server$") and "Script" or "ModuleScript"
 elseif section == "client" then
  parent = child(child(place, "StarterPlayer"), "StarterPlayerScripts")
  name = filename:gsub("%.client$", "")
  class = filename:match("%.client$") and "LocalScript" or "ModuleScript"
 else
  error("Unknown source section " .. tostring(section))
 end
 local item = parent:FindFirstChild(name)
 if not item then
  item = roblox.Instance.new(class)
  item.Name = name
  item.Parent = parent
  additions += 1
 end
 assert(item.ClassName == class, "Existing target class differs for " .. path)
 item.Source = fs.readFile(path)
 patched[item:GetFullName()] = item.Source
end
local function sourceInventory(root)
 local result = {}
 for _,item in root:GetDescendants() do
  if item:IsA("LuaSourceContainer") then
   local key = item:GetFullName() .. "\0" .. item.ClassName .. "\0" .. item.Source
   result[key] = (result[key] or 0) + 1
  end
 end
 return result
end
local expectedSources = sourceInventory(place)
local binary = roblox.serializePlace(place)
assert(binary:sub(1,8) == "<roblox!", "Expected binary Roblox place")
local restored = roblox.deserializePlace(binary)
assert(#restored:GetDescendants() == originalCount + additions, "Roundtrip lost place instances")
local actualSources = sourceInventory(restored)
for key,count in expectedSources do
 assert(actualSources[key] == count, "Roundtrip changed an embedded script")
end
-- Compare the complete serialized XML property graph, including assets, joints,
-- attributes, embedded pack scripts and user edits, after binary roundtripping.
-- Roblox's binary writer snaps near-axis CFrame rotations to its compact axis
-- encoding. Compare all other properties exactly and allow only that documented
-- numerical normalization (less than 0.00011 in a rotation matrix entry).
local beforePath, afterPath = args[2] .. ".verify-before.rbxlx", args[2] .. ".verify-after.rbxlx"
assert(not fs.isFile(beforePath) and not fs.isFile(afterPath), "Verification paths already exist")
fs.writeFile(beforePath, roblox.serializePlace(place, true))
fs.writeFile(afterPath, roblox.serializePlace(restored, true))
local verification = process.exec("python3", {"-c", [=[
import itertools, math, re, sys, xml.etree.ElementTree as ET
before, after = (ET.parse(p) for p in sys.argv[1:])
normalized = 0
unexpected = set()
left,right = list(before.iter('Item')),list(after.iter('Item'))
assert len(left)==len(right), 'Property graph instance count differs'
left_refs={i.get('referent'):n for n,i in enumerate(left)}
right_refs={i.get('referent'):n for n,i in enumerate(right)}
for a,b in zip(left,right):
    assert a.get('class')==b.get('class'), 'Property graph class differs'
    ap={x.get('name'):x for x in a.find('Properties')}
    bp={x.get('name'):x for x in b.find('Properties')}
    assert set(ap)<=set(bp), 'Property removed by roundtrip'
    for extra in set(bp)-set(ap):
        # Binary decoding materializes these empty defaults on newly created items.
        empty_default=extra in {'AttributesSerialize','Tags','SerializedOverrides','ScriptGuid'} and not (bp[extra].text or '').strip()
        folder_default=a.get('class')=='Folder' and extra in {'IconTint','Icon'}
        zero_default=extra in {'Capabilities','SourceAssetId','HistoryId','DefinesCapabilities','Sandboxed'} and (bp[extra].text or '').strip() in {'0','-1','false','00000000000000000000000000000000'}
        new_identity=extra=='UniqueId' and re.fullmatch('[0-9a-f]{32}',bp[extra].text or '')
        null_link=extra=='LinkedSource' and bp[extra].find('null') is not None
        if not (empty_default or folder_default or zero_default or new_identity or null_link):
            unexpected.add(extra+': '+ET.tostring(bp[extra],encoding='unicode').strip())
    for key,x in ap.items():
        y=bp[key]
        for u,v in itertools.zip_longest(x.iter(),y.iter()):
            assert u is not None and v is not None, 'Property element count differs: '+key
            assert u.tag==v.tag and u.attrib==v.attrib, 'Property structure differs: '+key
            ta,tb=u.text or '',v.text or ''
            if u.tag=='Ref':
                assert left_refs.get(ta,ta)==right_refs.get(tb,tb), 'Reference target differs: '+key
            elif ta != tb:
                assert u.tag in {'R00','R01','R02','R10','R11','R12','R20','R21','R22'}, 'Non-rotation property differs: '+key
                assert math.isclose(float(ta),float(tb),rel_tol=0,abs_tol=.00011), 'Rotation changed beyond binary axis normalization'
                normalized += 1
assert not unexpected, 'Unexpected new properties: '+str(sorted(unexpected))
print('Verified all properties; '+str(normalized)+' rotation entries normalized by binary encoding')
]=], beforePath, afterPath})
fs.removeFile(beforePath)
fs.removeFile(afterPath)
assert(verification.ok, "Roundtrip changed the place property graph: " .. verification.stderr)
print(verification.stdout)
local verified = 0
for _ in patched do verified += 1 end
fs.writeFile(args[2], binary)
local xmlPath = args[2]:gsub("%.rbxl$", ".rbxlx")
assert(xmlPath ~= args[2], "Output must use .rbxl extension")
assert(xmlPath ~= args[1], "XML output must not overwrite input")
fs.writeFile(xmlPath, roblox.serializePlace(restored, true))
print("Patched " .. verified .. " modules into " .. args[2] .. "; " .. #restored:GetDescendants() .. " instances and complete property graph verified (" .. additions .. " new instances); matching XML written to " .. xmlPath)
