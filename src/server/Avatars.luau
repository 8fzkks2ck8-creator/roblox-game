-- Fighter outfits and safe rig swaps; no combat behavior.
local C=require(game.ReplicatedStorage.AnimeRift.Config)
local Effects=require(game.ReplicatedStorage.AnimeRift.Effects)
local Details=require(game.ReplicatedStorage.AnimeRift.OutfitDetails)
local RigRepair=require(game.ReplicatedStorage.AnimeRift.RigRepair)
local A={}
local GetData
local function model(p) return p.Character end
local function root(p) local m=model(p);return m and m:FindFirstChild("HumanoidRootPart") end
function A.Init(getData) GetData=getData end
local function decorate(p)
 local m=model(p); if not m then return end
 local old=m:FindFirstChild("RiftAura"); if old then old:Destroy() end
 local d=GetData(p); if not d then return end
 local h=C.Find(C.Characters,d.Equipped)
 if not h then
  m:SetAttribute("RiftIdleId",nil)
  for _,name in ipairs({"RiftOutline","RiftOutfit"}) do local old=m:FindFirstChild(name);if old then old:Destroy() end end
  local root=m:FindFirstChild("HumanoidRootPart");local tag=root and root:FindFirstChild("HeroTag");if tag then tag:Destroy() end
  if m:GetAttribute("RiftStyled") or m:GetAttribute("RiftCharacterId") then p:LoadCharacterAsync() end
  return
 end
 m:SetAttribute("RiftStyled",true)
 local a=C.Find(C.Cosmetics,d.Aura)
 local assets=game.ReplicatedStorage.AnimeRift:FindFirstChild("Assets")
 local templates=assets and assets:FindFirstChild("CharacterModels")
 local custom=templates and templates:FindFirstChild(h.Id)
 if custom and not custom:IsA("Model") then custom=nil end
 if m:GetAttribute("RiftCharacterId") and not custom and p:IsA("Player") then p:LoadCharacterAsync();return end
 local usingCustom=m:GetAttribute("RiftCharacterId")==h.Id
 if custom and not usingCustom then
  local replacement,reason=RigRepair.Prepare(custom)
  if replacement then
   replacement.Name=p.Name;replacement:SetAttribute("RiftCharacterId",h.Id);replacement:SetAttribute("RiftIdleId",h.Id)
   local animate=m:FindFirstChild("Animate")
   local oldHumanoid=m:FindFirstChildOfClass("Humanoid")
   local newHumanoid=replacement:FindFirstChildOfClass("Humanoid")
   if animate and animate:IsA("LocalScript") and oldHumanoid and newHumanoid and oldHumanoid.RigType==newHumanoid.RigType then animate:Clone().Parent=replacement end
   replacement.Parent=workspace;replacement:PivotTo(m:GetPivot())
   p.Character=replacement;m:Destroy();return
  end
  warn("Could not prepare "..h.Id..": "..tostring(reason).."; using the built-in outfit.")
 end
 if not usingCustom then
 local outfit=C.Outfits[h.Id] or C.Outfits.yamcha
 local oldOutfit=m:FindFirstChild("RiftOutfit"); if oldOutfit then oldOutfit:Destroy() end
 for _,v in ipairs(m:GetChildren()) do if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") or v:IsA("BodyColors") then v:Destroy() end end
 local colors=Instance.new("BodyColors",m)
 local skin=Color3.fromRGB(table.unpack(outfit.Skin)); local cloth=Color3.fromRGB(table.unpack(outfit.Cloth))
 colors.HeadColor3=skin; colors.LeftArmColor3=skin; colors.RightArmColor3=skin
 local legs=outfit.Legs and Color3.fromRGB(table.unpack(outfit.Legs)) or cloth
 colors.TorsoColor3=cloth; colors.LeftLegColor3=legs; colors.RightLegColor3=legs
 local hair=Instance.new("Folder",m);hair.Name="RiftOutfit"
 local head=m:FindFirstChild("Head")
 if head and not outfit.Bald and not outfit.Hat then
  for i=-2,2 do
   local spike=Instance.new("WedgePart"); spike.Name="Hair tuft"; spike.Size=Vector3.new(0.45,0.7+math.abs(i)*0.12,0.9); spike.Color=Color3.fromRGB(table.unpack(outfit.Hair)); spike.CanCollide=false; spike.CanTouch=false; spike.CanQuery=false; spike.Massless=true; spike.CFrame=head.CFrame*CFrame.new(i*0.32,0.6,0.1)*CFrame.Angles(0,0,-i*0.16); spike.Parent=hair
   local weld=Instance.new("WeldConstraint",spike); weld.Part0=head; weld.Part1=spike
  end
 end
 Details.Apply(m,outfit,hair,false)
 end
 m:SetAttribute("RiftIdleId",h.Id)
 for _,part in ipairs(m:GetChildren()) do if part:IsA("Part") then part.TopSurface=Enum.SurfaceType.Studs;part.BottomSurface=Enum.SurfaceType.Studs;part.FrontSurface=Enum.SurfaceType.Studs;part.BackSurface=Enum.SurfaceType.Studs end end
 Effects.ApplyAnimations(m,h.Id)
 local highlight=m:FindFirstChild("RiftOutline") or Instance.new("Highlight"); highlight.Name="RiftOutline"; highlight.FillTransparency=1; highlight.OutlineColor=h.Color; highlight.OutlineTransparency=0.3; highlight.Parent=m
 local r=root(p); if not r then return end
 local oldTag=r:FindFirstChild("HeroTag"); if oldTag then oldTag:Destroy() end
 local tag=Instance.new("BillboardGui",r); tag.Name="HeroTag"; tag.Size=UDim2.fromOffset(240,35); tag.StudsOffset=Vector3.new(0,3.5,0); tag.MaxDistance=80
 local label=Instance.new("TextLabel",tag); label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.Text=h.Name; label.TextColor3=h.Color; label.Font=Enum.Font.GothamBold; label.TextSize=14; label.TextStrokeTransparency=0.3
 if a then
  local folder=Instance.new("Folder",m); folder.Name="RiftAura"
  for i=1,a.Tier+2 do
   local angle=i*math.pi*2/(a.Tier+2)
   local orb=Instance.new("Part"); orb.Name="Aura stud"; orb.Shape=Enum.PartType.Ball; orb.Size=Vector3.new(0.45,0.45,0.45); orb.Material=Enum.Material.Neon; orb.Color=a.Color; orb.CanCollide=false; orb.CanTouch=false; orb.CanQuery=false; orb.Massless=true; orb.CFrame=r.CFrame*CFrame.new(math.cos(angle)*2,1,math.sin(angle)*2); orb.Parent=folder
   local weld=Instance.new("WeldConstraint",orb); weld.Part0=r; weld.Part1=orb
  end
 end
end
-- AppearanceLoaded and CharacterAdded may arrive together while a rig swaps.
local decorating={}
function A.Decorate(p)
 if decorating[p] then return end
 decorating[p]=true
 local ok,err=xpcall(function() decorate(p) end,debug.traceback)
 decorating[p]=nil
 if not ok then warn("Character decoration failed: "..tostring(err)) end
end
return A
