-- Run with Lune; uses real Roblox instances, CFrames and serialized original rigs.
local roblox=require("@lune/roblox")
local fs=require("@lune/fs")
local Instance,Vector3,CFrame,Enum=roblox.Instance,roblox.Vector3,roblox.CFrame,roblox.Enum
-- Lune lacks Model geometry methods; these upright AABB/scale stand-ins are test-only.
local pivots,scales={},{}
roblox.implementMethod("Model","GetScale",function(m) return scales[m] or 1 end)
roblox.implementMethod("Model","GetPivot",function(m) return pivots[m] or CFrame.new() end)
roblox.implementMethod("Model","PivotTo",function(m,cf)
 local delta=cf*(pivots[m] or CFrame.new()):Inverse()
 for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.CFrame=delta*p.CFrame end end
 pivots[m]=cf
end)
roblox.implementMethod("Model","ScaleTo",function(m,scale)
 local ratio=scale/(scales[m] or 1)
 for _,p in m:GetDescendants() do if p:IsA("BasePart") then p.Size=p.Size*ratio;p.CFrame=CFrame.new(p.CFrame.Position*ratio)*p.CFrame.Rotation end end
 scales[m]=scale
end)
roblox.implementMethod("Model","GetBoundingBox",function(m)
 local min,max=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
 for _,p in m:GetDescendants() do if p:IsA("BasePart") then
  local a,b=p.CFrame.Position-p.Size/2,p.CFrame.Position+p.Size/2
  min=Vector3.new(math.min(min.X,a.X),math.min(min.Y,a.Y),math.min(min.Z,a.Z));max=Vector3.new(math.max(max.X,b.X),math.max(max.Y,b.Y),math.max(max.Z,b.Z))
 end end
 return CFrame.new((min+max)/2),max-min
end)
local R=(function()
__RIG_SOURCE__
end)()
local function test(rig)
 local fixed,reason=R.Prepare(rig);assert(fixed,reason)
 local motors,welds=0,0
 local core={};for _,p in fixed:GetChildren() do if p:IsA("BasePart") and (p.Name=="Torso" or p.Name=="Head" or p.Name=="HumanoidRootPart" or p.Name:find(" Arm") or p.Name:find(" Leg")) then core[p]=true end end
 for _,v in fixed:GetDescendants() do
  if v:IsA("Motor6D") then motors+=1;assert(v.Part0 and v.Part1) end
  if v:IsA("WeldConstraint") then welds+=1;assert(v.Part0 and v.Part1) end
  if v:IsA("BasePart") then
   assert(not v.Anchored,"anchored body part")
   if not core[v] then assert(v:FindFirstChild("RiftSkinWeld"),"loose cosmetic part: "..v.Name) end
  end
 end
 assert(motors==6,"expected six R6 motors")
 assert(fixed:FindFirstChildOfClass("Humanoid") and fixed.HumanoidRootPart)
 assert(fixed:FindFirstChildOfClass("Humanoid").RigType==roblox.Enum.HumanoidRigType.R6)
 print("PASS rig repair: "..rig.Name.." (6 motors, "..welds.." skin welds)")
 return fixed
end
local fixture=Instance.new("Model");fixture.Name="Missing joints plus loose hair"
for _,name in {"HumanoidRootPart","Torso","Head","Right Arm","Left Arm","Right Leg","Left Leg","Loose Hair"} do
 local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.Parent=fixture
end
test(fixture)
local loose=Instance.new("Model");loose.Name="Loose mesh-only visual"
local part=Instance.new("Part");part.Name="DisplayMesh";part.Size=Vector3.new(2,6,2);part.Parent=loose
test(loose)
local text=fs.readFile("assets/AnimeRift.original.rbxlx"):gsub("^<%?xml.-%?>%s*","")
local original=roblox.deserializePlace(text)
local models=original:FindFirstChild("ReplicatedStorage").AnimeRift.Assets.CharacterModels
for _,rig in models:GetChildren() do if rig:IsA("Model") then test(rig) end end
