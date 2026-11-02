-- Lantern sanctuary. RiftLayout still controls spawn and arena locations.
local W={Arenas={}}
local Lighting=game:GetService("Lighting")
function W.Build()
 W.Arenas={}
 local layout=workspace:FindFirstChild("RiftLayout")
 local marker=layout and layout:FindFirstChild("LobbySpawn")
 W.Spawn=marker and marker.CFrame or CFrame.new(0,5,40)
 local prior=workspace:FindFirstChild("RiftWorld");if prior then prior:Destroy() end
 local world=Instance.new("Folder",workspace);world.Name="RiftWorld"
 local stone=Color3.fromRGB(54,62,86)
 local pale=Color3.fromRGB(208,211,229)
 local grass=Color3.fromRGB(75,117,112)
 local wood=Color3.fromRGB(69,42,65)
 local pink=Color3.fromRGB(246,155,202)
 local gold=Color3.fromRGB(255,208,126)
 local cyan=Color3.fromRGB(102,222,244)
 local function part(name,size,pos,color,material)
  local p=Instance.new("Part");p.Name=name;p.Size=size;p.Position=pos;p.Anchored=true;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
  p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=world;return p
 end
 local function decor(p)
  p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;return p
 end
 local function disc(name,pos,radius,height,color,material)
  local p=part(name,Vector3.new(height,radius*2,radius*2),pos,color,material)
  p.Shape=Enum.PartType.Cylinder;p.CFrame=CFrame.new(pos)*CFrame.Angles(0,0,math.pi/2);return p
 end
 local function sign(text,pos,width,color)
  local anchor=decor(part("Wayfinding",Vector3.one,pos,color));anchor.Transparency=1
  local gui=Instance.new("BillboardGui",anchor);gui.Size=UDim2.fromOffset(width,62);gui.MaxDistance=100;gui.LightInfluence=0;gui.StudsOffset=Vector3.zero
  local label=Instance.new("TextLabel",gui);label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Font=Enum.Font.GothamBold;label.Text=text;label.TextSize=22;label.TextWrapped=true;label.TextColor3=color;label.TextStrokeTransparency=.45
 end
 local function lamp(pos)
  part("Lantern pedestal",Vector3.new(2,.8,2),pos+Vector3.new(0,.4,0),stone)
  part("Lantern stem",Vector3.new(.5,4,.5),pos+Vector3.new(0,2.6,0),wood)
  local glow=decor(part("Lantern glow",Vector3.new(1.3,1.8,1.3),pos+Vector3.new(0,5,0),gold,Enum.Material.Neon))
  part("Lantern cap",Vector3.new(2.2,.4,2.2),pos+Vector3.new(0,6.1,0),wood)
  local light=Instance.new("PointLight",glow);light.Color=gold;light.Range=15;light.Brightness=.7
 end
 local function cherry(x,z,height)
  local pos=Vector3.new(x,0,z)
  part("Sakura trunk",Vector3.new(2,height,2),pos+Vector3.new(0,height/2,0),wood)
  for i=1,5 do
   local angle=i*math.pi*2/5
   local crown=decor(part("Sakura canopy",Vector3.new(10,6,10),pos+Vector3.new(math.cos(angle)*4,height+1+ i%2*2,math.sin(angle)*4),i%2==0 and pink or Color3.fromRGB(209,129,188)))
   crown.Shape=Enum.PartType.Ball
  end
 end
 part("Floating sanctuary",Vector3.new(184,12,164),Vector3.new(0,-6.5,0),stone,Enum.Material.Slate)
 part("Moss garden",Vector3.new(182,1,162),Vector3.new(0,-.1,0),grass,Enum.Material.Grass)
 part("Main avenue trim",Vector3.new(23,.5,150),Vector3.new(0,.5,0),pale)
 part("Main avenue",Vector3.new(21,.6,150),Vector3.new(0,.55,0),stone)
 part("Cross avenue",Vector3.new(164,.6,18),Vector3.new(0,.56,0),stone)
 for _,x in ipairs({-10.5,10.5}) do decor(part("Avenue light",Vector3.new(.12,.1,146),Vector3.new(x,.9,0),cyan,Enum.Material.Neon)) end
 for z=-65,65,10 do decor(part("Paving joint",Vector3.new(20,.04,.15),Vector3.new(0,.88,z),pale)) end
 -- Low perimeter rail and an invisible roofless boundary prevent accidental falls.
 for _,x in ipairs({-91,91}) do
  part("Perimeter plinth",Vector3.new(2,2,164),Vector3.new(x,1,0),stone)
  local wall=part("Island boundary",Vector3.new(1,70,164),Vector3.new(x,35,0),stone);wall.Transparency=1
 end
 for _,z in ipairs({-81,81}) do
  part("Perimeter plinth",Vector3.new(184,2,2),Vector3.new(0,1,z),stone)
  local wall=part("Island boundary",Vector3.new(184,70,1),Vector3.new(0,35,z),stone);wall.Transparency=1
 end
 for _,x in ipairs({-72,-35,35,72}) do for _,z in ipairs({-64,62}) do cherry(x,z,12+math.abs(x)%4) end end
 for _,x in ipairs({-78,78}) do cherry(x,-25,15);cherry(x,22,13) end
 for _,x in ipairs({-16,16}) do for _,z in ipairs({-60,-30,10,46,70}) do lamp(Vector3.new(x,0,z)) end end
 -- Shallow reflecting pools sit beside the spawn, away from walking routes.
 for _,x in ipairs({-43,43}) do
  part("Pool basin",Vector3.new(24,.6,14),Vector3.new(x,.3,48),stone)
  local water=decor(part("Reflecting water",Vector3.new(21,.15,11),Vector3.new(x,.65,48),cyan,Enum.Material.Glass));water.Transparency=.35;water.Reflectance=.22
  for i=1,3 do disc("Floating lily",Vector3.new(x-7+i*4,.82,47+i%2*2),1,.15,grass) end
 end
 local function kiosk(name,text,pos,color,action)
  disc(name.." dais",pos,13,1,stone)
  disc(name.." inset",pos+Vector3.new(0,.55,0),11,.15,color)
  for _,dx in ipairs({-10,10}) do
   part("Shrine pillar",Vector3.new(1.2,13,1.2),pos+Vector3.new(dx,6,-6),wood)
   part("Shrine pillar collar",Vector3.new(1.8,.5,1.8),pos+Vector3.new(dx,3,-6),gold)
  end
  part("Shrine lintel",Vector3.new(26,1.2,3),pos+Vector3.new(0,12,-6),wood)
  part("Shrine roof",Vector3.new(29,.6,5),pos+Vector3.new(0,13,-6),stone)
  decor(part("Shrine light strip",Vector3.new(22,.2,.2),pos+Vector3.new(0,11.2,-4.4),color,Enum.Material.Neon))
  sign(text,pos+Vector3.new(0,10,-4),235,color)
  local orb=decor(part(name,Vector3.new(3,3,3),pos+Vector3.new(0,3,0),color,Enum.Material.Neon));orb.Shape=Enum.PartType.Ball;orb:SetAttribute("RiftFloat",true)
  local prompt=Instance.new("ProximityPrompt",orb);prompt.ActionText="Open";prompt.ObjectText=text;prompt.HoldDuration=0;prompt.MaxActivationDistance=14;prompt.RequiresLineOfSight=false;prompt:SetAttribute("RiftAction",action)
 end
 kiosk("Summon","SUMMON FIGHTERS",Vector3.new(-45,1,-26),cyan,"Summon")
 kiosk("Cosmetics","AURA SHRINE",Vector3.new(45,1,-26),Color3.fromRGB(192,147,255),"Cosmetics")
 kiosk("Starter","RIFT SHOP",Vector3.new(-45,1,20),gold,"Shop")
 kiosk("Wheel","DAILY WHEEL",Vector3.new(45,1,20),Color3.fromRGB(113,239,184),"Wheel")
 kiosk("Bosses","BOSS GATE",Vector3.new(0,1,-55),pink,"Bosses")
 sign("ANIME RIFT\nTHE LANTERN SANCTUARY",Vector3.new(0,23,-64),430,pale)
 local spawn=Instance.new("SpawnLocation",world);spawn.Name="SanctuarySpawn";spawn.Size=Vector3.new(9,.4,9);spawn.CFrame=W.Spawn*CFrame.new(0,-4,0);spawn.Anchored=true;spawn.Neutral=true;spawn.Transparency=1;spawn.Duration=0
 -- Preserve all original arena markers and combat bounds.
 for i=1,3 do
  local markers=layout and layout:FindFirstChild("Arena"..i)
  local centerMarker=markers and markers:FindFirstChild("Center")
  local center=centerMarker and centerMarker.Position or Vector3.new((i-2)*155,0,-240)
  local p1=markers and markers:FindFirstChild("Player1");local p2=markers and markers:FindFirstChild("Player2")
  local tint=({cyan,pink,Color3.fromRGB(192,147,255)})[i]
  part("Boss island "..i,Vector3.new(112,10,112),center-Vector3.new(0,5,0),stone,Enum.Material.Slate)
  part("Arena floor",Vector3.new(104,.3,104),center,stone)
  decor(disc("Arena sigil",center+Vector3.new(0,.22,0),25,.12,tint,Enum.Material.Neon)).Transparency=.72
  decor(disc("Arena sigil inset",center+Vector3.new(0,.3,0),23,.12,stone))
  for _,dx in ipairs({-53,53}) do part("Arena wall",Vector3.new(2,9,108),center+Vector3.new(dx,4.5,0),stone) end
  for _,dz in ipairs({-53,53}) do part("Arena wall",Vector3.new(108,9,2),center+Vector3.new(0,4.5,dz),stone) end
  for _,dx in ipairs({-42,42}) do for _,dz in ipairs({-42,42}) do lamp(center+Vector3.new(dx,0,dz)) end end
  sign("RIFT ARENA 0"..i,center+Vector3.new(0,15,-50),350,tint)
  W.Arenas[i]={Center=center,Spawns={p1 and p1.CFrame or CFrame.new(center+Vector3.new(0,4,28)),p2 and p2.CFrame or CFrame.new(center+Vector3.new(0,4,-28))}}
 end
 Lighting.ClockTime=17.6;Lighting.Brightness=2;Lighting.Ambient=Color3.fromRGB(115,111,146);Lighting.OutdoorAmbient=Color3.fromRGB(139,145,172)
 for _,name in ipairs({"RiftBloom","RiftAtmosphere"}) do local old=Lighting:FindFirstChild(name);if old then old:Destroy() end end
 local bloom=Instance.new("BloomEffect",Lighting);bloom.Name="RiftBloom";bloom.Intensity=.24;bloom.Size=28;bloom.Threshold=1.3
 local atmosphere=Instance.new("Atmosphere",Lighting);atmosphere.Name="RiftAtmosphere";atmosphere.Density=.22;atmosphere.Color=Color3.fromRGB(204,194,227);atmosphere.Decay=Color3.fromRGB(117,104,151)
 if layout then for _,m in ipairs(layout:GetDescendants()) do if m:IsA("BasePart") then m.Transparency=1;m.CanCollide=false;m.CanTouch=false;m.CanQuery=false end end end
 return W
end
return W
