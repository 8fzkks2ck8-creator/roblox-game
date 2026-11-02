-- Bright classic simulator plaza, based on the supplied studded garden reference.
local W = {Arenas = {}}
local Lighting = game:GetService("Lighting")
function W.Build()
 W.Arenas = {}
 local layout = workspace:FindFirstChild("RiftLayout")
 local marker = layout and layout:FindFirstChild("LobbySpawn")
 W.Spawn = marker and marker.CFrame or CFrame.new(0, 5, 40)
 local old = workspace:FindFirstChild("RiftWorld"); if old then old:Destroy() end
 local world = Instance.new("Folder", workspace); world.Name = "RiftWorld"
 local lime = Color3.fromRGB(166, 233, 42)
 local green = Color3.fromRGB(137, 203, 35)
 local earth = Color3.fromRGB(184, 121, 98)
 local wood = Color3.fromRGB(165, 103, 75)
 local white = Color3.fromRGB(241, 242, 255)
 local lavender = Color3.fromRGB(160, 162, 248)
 local blue = Color3.fromRGB(80, 129, 228)
 local red = Color3.fromRGB(242, 45, 74)
 local gold = Color3.fromRGB(255, 220, 105)
 local function part(name, size, pos, color, material)
  local p = Instance.new("Part")
  p.Name = name; p.Size = size; p.Position = pos; p.Anchored = true
  p.Color = color; p.Material = material or Enum.Material.Plastic
  p.TopSurface = Enum.SurfaceType.Studs; p.BottomSurface = Enum.SurfaceType.Smooth
  p.FrontSurface = Enum.SurfaceType.Studs; p.BackSurface = Enum.SurfaceType.Studs
  p.LeftSurface = Enum.SurfaceType.Studs; p.RightSurface = Enum.SurfaceType.Studs
  p.Parent = world
  return p
 end
 local function decor(p)
  p.CanCollide = false; p.CanTouch = false; p.CanQuery = false
  return p
 end
 local function sign(text, pos, width, color)
  part("Sign frame", Vector3.new(width + 1.5, 5.5, .8), pos, lavender)
  part("Sign inset", Vector3.new(width, 4.2, 1), pos, blue)
  local anchor = decor(part("Wayfinding", Vector3.one, pos + Vector3.new(0, 0, 1), color))
  anchor.Transparency = 1
  local gui = Instance.new("BillboardGui", anchor); gui.Size = UDim2.fromOffset(width * 18, 70)
  gui.MaxDistance = 150; gui.LightInfluence = 0
  local label = Instance.new("TextLabel", gui); label.Size = UDim2.fromScale(1, 1)
  label.BackgroundTransparency = 1; label.Font = Enum.Font.FredokaOne
  label.Text = text; label.TextSize = 27; label.TextWrapped = true
  label.TextColor3 = color; label.TextStrokeTransparency = .15
 end
 local function tree(x, z, height)
  part("Studded trunk", Vector3.new(3, height, 3), Vector3.new(x, height / 2, z), wood)
  for layer = 0, 2 do
   local width = 13 - layer * 2.2
   local p = decor(part("Block canopy", Vector3.new(width, 4, width), Vector3.new(x, height + layer * 3, z), layer == 1 and lime or green))
   p.CFrame = p.CFrame * CFrame.Angles(0, math.rad(layer * 16), 0)
  end
 end
 local function fence(x, z, length)
  for dz = -length / 2, length / 2, 6 do
   part("Fence post", Vector3.new(.9, 3.5, .9), Vector3.new(x, 1.75, z + dz), wood)
  end
  for _, y in ipairs({1.15, 2.6}) do part("Fence rail", Vector3.new(.55, .6, length), Vector3.new(x, y, z), earth) end
 end
 local function lamp(pos)
  part("Lantern post", Vector3.new(.9, 9, .9), pos + Vector3.new(0, 4.5, 0), wood)
  part("Lantern base", Vector3.new(2.2, .4, 2.2), pos + Vector3.new(0, 9, 0), lavender)
  local glow = decor(part("Warm lantern", Vector3.new(1.4, 2.2, 1.4), pos + Vector3.new(0, 10.2, 0), gold, Enum.Material.Neon))
  part("Lantern roof", Vector3.new(2.4, .5, 2.4), pos + Vector3.new(0, 11.5, 0), lavender)
  local light = Instance.new("PointLight", glow); light.Color = gold; light.Range = 15; light.Brightness = .55
 end
 -- Broad paths and flush platforms leave the center of the avenue unobstructed.
 part("Garden island", Vector3.new(224, 13, 204), Vector3.new(0, -6.5, 0), earth)
 part("Studded grass", Vector3.new(224, 1, 204), Vector3.new(0, -.1, 0), lime)
 part("Avenue white border", Vector3.new(24, .5, 190), Vector3.new(0, .45, 0), white)
 part("Red avenue", Vector3.new(21, .6, 190), Vector3.new(0, .51, 0), red)
 part("Crossway border", Vector3.new(205, .4, 17), Vector3.new(0, .45, 0), white)
 part("Lavender crossway", Vector3.new(205, .5, 14), Vector3.new(0, .5, 0), lavender)
 -- Raised accents on the avenue make the classic stud look visible at a distance.
 -- Most surfaces use native studs instead of thousands of individual geometry parts.
 for z = -90, 90, 6 do
  for _, x in ipairs({-7, -3.5, 0, 3.5, 7}) do
   decor(part("Avenue stud", Vector3.new(1, .1, 1), Vector3.new(x, .86, z), Color3.fromRGB(220, 38, 67)))
  end
 end
 for _, x in ipairs({-18, 18}) do fence(x, 62, 42); fence(x, -35, 28) end
 for _, x in ipairs({-25, 25}) do for _, z in ipairs({-78, -10, 29, 83}) do lamp(Vector3.new(x, 0, z)) end end
 for _, x in ipairs({-98, 98}) do for _, z in ipairs({-83, -44, 8, 61, 88}) do tree(x, z, 16 + math.abs(z) % 5) end end
 for _, x in ipairs({-69, -40, 40, 69}) do tree(x, 85, 14); tree(x, -93, 15) end
 -- Stepped grassy cliffs enclose the plaza like the reference without hiding kiosks.
 for i = -3, 3 do
  local h = 17 + math.abs(i) * 3
  part("Back terrace", Vector3.new(34, h, 17), Vector3.new(i * 34, h / 2 - 4, -112), earth)
  part("Back terrace grass", Vector3.new(35, 1.5, 19), Vector3.new(i * 34, h - 3, -112), green)
 end
 for _, side in ipairs({-1, 1}) do
  for z = -84, 84, 42 do
   part("Side terrace", Vector3.new(14, 20, 40), Vector3.new(side * 120, 6, z), earth)
   part("Side terrace grass", Vector3.new(16, 1.5, 41), Vector3.new(side * 120, 16.8, z), green)
  end
 end
 -- Transparent boundaries cover the front edge as well as the cliff-backed edges.
 for _, x in ipairs({-112, 112}) do local p = part("Island boundary", Vector3.new(1, 80, 204), Vector3.new(x, 40, 0), white); p.Transparency = 1 end
 for _, z in ipairs({-102, 102}) do local p = part("Island boundary", Vector3.new(224, 80, 1), Vector3.new(0, 40, z), white); p.Transparency = 1 end
 local function kiosk(name, text, pos, color, action)
  part(name .. " platform trim", Vector3.new(30, .7, 23), pos, white)
  part(name .. " platform", Vector3.new(27, .8, 20), pos + Vector3.new(0, .15, 0), lavender)
  part(name .. " display pad", Vector3.new(10, 1, 9), pos + Vector3.new(0, .8, 0), color)
  for _, dx in ipairs({-12, 12}) do part("Kiosk signpost", Vector3.new(1.2, 11, 1.2), pos + Vector3.new(dx, 5.5, -7), lavender) end
  sign(text, pos + Vector3.new(0, 11, -7), 26, white)
  local orb = decor(part(name, Vector3.new(3.6, 3.6, 3.6), pos + Vector3.new(0, 4, 0), color, Enum.Material.Neon))
  orb.Shape = Enum.PartType.Ball; orb:SetAttribute("RiftFloat", true)
  local prompt = Instance.new("ProximityPrompt", orb)
  prompt.ActionText = "Open"; prompt.ObjectText = text; prompt.HoldDuration = 0
  prompt.MaxActivationDistance = 14; prompt.RequiresLineOfSight = false; prompt:SetAttribute("RiftAction", action)
 end
 kiosk("Summon", "SUMMON FIGHTERS", Vector3.new(-51, 1, -31), Color3.fromRGB(79, 218, 255), "Summon")
 kiosk("Cosmetics", "AURA GARDEN", Vector3.new(51, 1, -31), Color3.fromRGB(205, 122, 255), "Cosmetics")
 kiosk("Starter", "RIFT STORE", Vector3.new(-51, 1, 32), gold, "Shop")
 kiosk("Wheel", "DAILY WHEEL", Vector3.new(51, 1, 32), Color3.fromRGB(133, 245, 83), "Wheel")
 kiosk("Bosses", "BOSS CHALLENGES", Vector3.new(0, 1, -75), Color3.fromRGB(255, 101, 158), "Bosses")
 for _, x in ipairs({-77, 77}) do
  for _, z in ipairs({-62, 0, 62}) do
   part("Garden display trim", Vector3.new(22, .6, 16), Vector3.new(x, .6, z), white)
   part("Garden display platform", Vector3.new(20, .7, 14), Vector3.new(x, .7, z), lavender)
   for j = 1, 3 do part("Little block bush", Vector3.new(3, 2 + j % 2, 3), Vector3.new(x - 4 + j * 2, 2, z), green) end
  end
 end
 -- Segmented neon rainbow, with a few soft cloud clusters above the rear cliffs.
 local rainbow = {Color3.fromRGB(255, 99, 162), Color3.fromRGB(255, 183, 103), Color3.fromRGB(255, 244, 134), Color3.fromRGB(131, 255, 157), Color3.fromRGB(119, 218, 255)}
 for band, color in ipairs(rainbow) do
  local radius = 31 - band * 1.6
  for step = 0, 23 do
   local angle = (step + .5) * math.pi / 24
   local p = decor(part("Rainbow arch", Vector3.new(4.2, 1.2, 2), Vector3.new(math.cos(angle) * radius, 15 + math.sin(angle) * radius, -99), color, Enum.Material.Neon))
   p.CFrame = CFrame.new(p.Position) * CFrame.Angles(0, 0, angle + math.pi / 2)
  end
 end
 for _, x in ipairs({-142, -78, 78, 142}) do
  for j = 1, 3 do
   local p = decor(part("Cloud puff", Vector3.new(23, 12, 15), Vector3.new(x + j * 9, 64 + j % 2 * 5, -130), white))
   p.Shape = Enum.PartType.Ball
  end
 end
 sign("ANIME RIFT", Vector3.new(0, 21, -100), 30, white)
 local spawn = Instance.new("SpawnLocation", world)
 spawn.Name = "SanctuarySpawn"; spawn.Size = Vector3.new(9, .4, 9)
 spawn.CFrame = W.Spawn * CFrame.new(0, -4, 0); spawn.Anchored = true; spawn.Neutral = true; spawn.Transparency = 1; spawn.Duration = 0
 for i = 1, 3 do
  local markers = layout and layout:FindFirstChild("Arena" .. i)
  local centerMarker = markers and markers:FindFirstChild("Center")
  local center = centerMarker and centerMarker.Position or Vector3.new((i - 2) * 155, 0, -240)
  local p1 = markers and markers:FindFirstChild("Player1"); local p2 = markers and markers:FindFirstChild("Player2")
  local tint = ({Color3.fromRGB(109, 234, 158), Color3.fromRGB(255, 137, 156), lavender})[i]
  part("Boss island " .. i, Vector3.new(112, 10, 112), center - Vector3.new(0, 5, 0), earth)
  part("Arena floor", Vector3.new(104, .3, 104), center, tint)
  part("Arena center", Vector3.new(30, .1, 30), center + Vector3.new(0, .25, 0), white)
  for _, dx in ipairs({-53, 53}) do part("Arena wall", Vector3.new(2, 9, 108), center + Vector3.new(dx, 4.5, 0), lavender) end
  for _, dz in ipairs({-53, 53}) do part("Arena wall", Vector3.new(108, 9, 2), center + Vector3.new(0, 4.5, dz), lavender) end
  sign("BOSS ARENA " .. i, center + Vector3.new(0, 14, -50), 29, white)
  W.Arenas[i] = {Center = center, Spawns = {p1 and p1.CFrame or CFrame.new(center + Vector3.new(0, 4, 28)), p2 and p2.CFrame or CFrame.new(center + Vector3.new(0, 4, -28))}}
 end
 Lighting.ClockTime = 13.5; Lighting.Brightness = 2.4
 Lighting.Ambient = Color3.fromRGB(151, 160, 193); Lighting.OutdoorAmbient = Color3.fromRGB(177, 193, 219)
 for _, name in ipairs({"RiftBloom", "RiftAtmosphere"}) do local effect = Lighting:FindFirstChild(name); if effect then effect:Destroy() end end
 local bloom = Instance.new("BloomEffect", Lighting); bloom.Name = "RiftBloom"; bloom.Intensity = .22; bloom.Size = 26; bloom.Threshold = 1.5
 local atmosphere = Instance.new("Atmosphere", Lighting); atmosphere.Name = "RiftAtmosphere"; atmosphere.Density = .19
 atmosphere.Color = Color3.fromRGB(184, 226, 255); atmosphere.Decay = Color3.fromRGB(117, 160, 240)
 if layout then for _, m in ipairs(layout:GetDescendants()) do if m:IsA("BasePart") then m.Transparency = 1; m.CanCollide = false; m.CanTouch = false; m.CanQuery = false end end end
 return W
end
return W
