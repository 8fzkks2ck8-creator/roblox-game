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
local storage = folder(child(place, "ServerStorage"), "AnimeRiftSourcePacks")
local kit = child(place,"Workspace"):FindFirstChild("PDS' Particles & Models Kit") or storage:FindFirstChild("PDS' Particles & Models Kit")
assert(kit,"Missing preserved PDS kit")
kit.Parent = storage
local sourceMeshes = child(child(kit, "PDS Models Pack for BSED:R"), "Meshes")
local rock = child(sourceMeshes, "Icosphere")
assert(rock:IsA("MeshPart"), "Expected the authored Icosphere MeshPart")
local assets = child(child(child(place, "ReplicatedStorage"), "AnimeRift"), "Assets")
local cinematicMeshes = folder(assets, "CinematicMeshes")
local meteor = cinematicMeshes:FindFirstChild("MeteorRock")
if not meteor then
meteor = rock:Clone()
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
end
-- Editable scene slots. Keep templates inert in ReplicatedStorage; the client
-- sanitizes and clones only the selected scene into a distant local stage.
local cutscenes=folder(assets,"Cutscenes")
local presets=require("../src/shared/SummonPresets")
local packParticles={}
for _,v in kit:GetDescendants() do
 if v:IsA("ParticleEmitter") and (v.Name=="star" or v.Name=="swirl") then
  table.insert(packParticles,v)
  if #packParticles>=3 then break end
 end
end
assert(#packParticles>=1,"Expected supplied pack particles")
for id,preset in presets.All do
 local scene=folder(cutscenes,id)
 if not scene:GetAttribute("EditorHelp") then scene:SetAttribute("EditorHelp","Replace OpeningFX, ChargeFX or ImpactFX with a Part/Model containing your emitters. Replace mesh slots under Meshes. Edit the SoundIds directly. Templates are not executed.") end
 local meshes=folder(scene,"Meshes")
 if not meshes:FindFirstChild("StageMesh") then folder(meshes,"StageMesh") end -- empty optional replacement slot
 local meshName=id=="madara" and "Meteor" or "SignatureMesh"
 if not meshes:FindFirstChild(meshName) then
  local mesh=meteor:Clone();mesh.Name=meshName;mesh.Parent=meshes;additions+=1+#mesh:GetDescendants()
 end
 for i,name in {"OpeningFX","ChargeFX","ImpactFX"} do
  if not scene:FindFirstChild(name) then
  local anchor=roblox.Instance.new("Part");anchor.Name=name;anchor.Size=roblox.Vector3.one;anchor.Transparency=1;anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.Parent=scene
  if id=="madara" then anchor:SetAttribute("CueProgress",i==1 and .08 or i==2 and .43 or .66) end
  local attachment=roblox.Instance.new("Attachment");attachment.Name="Emission";attachment.Parent=anchor
  local emitter=packParticles[(i-1)%#packParticles+1]:Clone()
  for _,child in emitter:GetChildren() do child:Destroy() end
  emitter.Name="PackParticle";emitter.Enabled=false;emitter.Rate=0;emitter.Lifetime=roblox.NumberRange.new(.35,1.2);emitter.LightEmission=.5
  emitter.Color=roblox.ColorSequence.new(roblox.Color3.fromRGB(preset.Color[1],preset.Color[2],preset.Color[3]));emitter:SetAttribute("EmitCount",i==3 and 32 or 16);emitter.Parent=attachment
  additions+=3
  end
 end
 for name,idValue in {OpeningSFX="rbxassetid://4612378086",ChargeSFX="rbxassetid://117570443671176",ImpactSFX="rbxassetid://9114828835",Dialogue=id=="madara" and "rbxassetid://135791921703430" or ""} do
  if not scene:FindFirstChild(name) then
  local sound=roblox.Instance.new("Sound");sound.Name=name;sound.SoundId=idValue;sound.Volume=.5;sound.PlayOnRemove=false;sound.Looped=false;sound.Parent=scene;additions+=1
  if id=="madara" and name~="Dialogue" then sound:SetAttribute("CueProgress",name=="OpeningSFX" and .04 or name=="ChargeSFX" and .43 or .66) end
  end
 end
end
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
-- Obtain the serializer's authoritative class defaults rather than guessing
-- which newly materialized Part/Sound properties are harmless.
local defaultInputs={}
local defaultContainer=roblox.Instance.new("Folder")
for _,class in {"Part","Sound","Attachment"} do
 for _,item in place:GetDescendants() do if item.ClassName==class then
  local example=item:Clone();for _,child in example:GetChildren() do child:Destroy() end
  example.Parent=defaultContainer
  table.insert(defaultInputs,example);break
 end end
 -- Shared binary class columns supply defaults for the empty instance using
 -- the exact property set of the loaded exemplar.
 local empty=roblox.Instance.new(class);empty.Parent=defaultContainer;table.insert(defaultInputs,empty)
end
local defaults=roblox.deserializeModel(roblox.serializeModel(defaultInputs))
local defaultXML=roblox.serializeModel(defaults,true)
local verification = process.exec("python3", {"-c", [=[
import itertools, math, re, sys, xml.etree.ElementTree as ET
before, after = (ET.parse(p) for p in sys.argv[1:3])
def property_key(x):
    return x.tag, tuple(sorted(x.attrib.items())), (x.text or '').strip(), tuple(property_key(c) for c in x)
defaults={i.get('class'):{x.get('name'):property_key(x) for x in i.find('Properties')} for i in ET.fromstring(sys.argv[3]).findall('Item')}
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
        class_default=defaults.get(a.get('class'),{}).get(extra)==property_key(bp[extra])
        if not (empty_default or folder_default or zero_default or new_identity or null_link or class_default):
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
]=], beforePath, afterPath, defaultXML})
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
