-- Repair canonical R6 rigs, or mount a visual model onto a stable R6 carrier.
local R={}
local names={"HumanoidRootPart","Torso","Head","Right Arm","Left Arm","Right Leg","Left Leg"}
local offsets={HumanoidRootPart={0,0,0},Torso={0,0,0},Head={0,1.5,0},["Right Arm"]={1.5,0,0},["Left Arm"]={-1.5,0,0},["Right Leg"]={.5,-2,0},["Left Leg"]={-.5,-2,0}}
local function clean(model)
 local descendants=model:GetDescendants()
 for index=#descendants,1,-1 do
  local v=descendants[index]
  if v:IsA("LuaSourceContainer") or v:IsA("JointInstance") or v:IsA("Constraint") or v:IsA("BodyMover") then v:Destroy() end
 end
end
local function motor(name,a,b,c0)
 local m=Instance.new("Motor6D");m.Name=name;m.Part0=a;m.Part1=b;m.C0=c0;m.C1=b.CFrame:ToObjectSpace(a.CFrame*c0);m.Parent=a
end
local function link(core)
 local quarter=CFrame.Angles(-math.pi/2,0,math.pi)
 motor("RootJoint",core.HumanoidRootPart,core.Torso,quarter)
 motor("Neck",core.Torso,core.Head,CFrame.new(0,1,0)*quarter)
 for _,side in ipairs({-1,1}) do
  local word=side==1 and "Right" or "Left"
  motor(word.." Shoulder",core.Torso,core[word.." Arm"],CFrame.new(side,.5,0)*CFrame.Angles(0,side*math.pi/2,0))
  motor(word.." Hip",core.Torso,core[word.." Leg"],CFrame.new(side,-1,0)*CFrame.Angles(0,side*math.pi/2,0))
 end
end
local function bodyGroup(part)
 local p=part
 while p and not p:IsA("Model") do
  local n=p.Name:lower():gsub("[%s_%-]","")
  if n=="head" then return "Head" end
  if n=="torso" or n=="uppertorso" or n=="lowertorso" then return "Torso" end
  for _,side in ipairs({"left","right"}) do
   local word=side=="left" and "Left" or "Right"
   if n==side.."arm" or n==side.."upperarm" or n==side.."lowerarm" or n==side.."hand" then return word.." Arm" end
   if n==side.."leg" or n==side.."upperleg" or n==side.."lowerleg" or n==side.."foot" then return word.." Leg" end
  end
  p=p.Parent
 end
end
local function weldExtras(model,core)
 local set={};for _,part in pairs(core) do set[part]=true end
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") and not set[part] then
   local host=core[bodyGroup(part)]
   if not host then
    local distance=math.huge
    for name,candidate in pairs(core) do
     if name~="HumanoidRootPart" then local d=(candidate.CFrame.Position-part.CFrame.Position).Magnitude;if d<distance then distance=d;host=candidate end end
    end
   end
   part.Anchored=false;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.Massless=true
   local weld=Instance.new("WeldConstraint");weld.Parent=part;weld.Name="RiftSkinWeld";weld.Part0=host;weld.Part1=part
  end
 end
end
function R.Prepare(template)
 if not template or not template:IsA("Model") then return nil,"Expected a Model" end
 local original=template:Clone();clean(original)
 local core={};local canonical=true
 for _,name in ipairs(names) do
  local part=original:FindFirstChild(name)
  if part and part:IsA("BasePart") then core[name]=part else canonical=false end
 end
 local model=original
 if not canonical then
  local parts={};for _,p in ipairs(original:GetDescendants()) do if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then table.insert(parts,p) end end
  if #parts==0 then original:Destroy();return nil,"Model has no visible body parts" end
  local descendants=original:GetDescendants()
  for index=#descendants,1,-1 do local v=descendants[index];if v:IsA("Humanoid") or v.Name=="HumanoidRootPart" then v:Destroy() end end
  -- Normalize oversized toolbox models while preserving their relative appearance.
  local _,size=original:GetBoundingBox()
  original:ScaleTo(original:GetScale()*6/math.max(size.Y,.1))
  local bounds=original:GetBoundingBox()
  original:PivotTo(CFrame.new(0,-.5,0)*bounds:Inverse()*original:GetPivot())
  model=Instance.new("Model");model.Name=template.Name;core={}
  for _,name in ipairs(names) do
   local p=Instance.new("Part");p.Name=name;local o=offsets[name];p.CFrame=CFrame.new(o[1],o[2],o[3]);p.Size=(name:find("Arm") or name:find("Leg")) and Vector3.new(1,2,1) or name=="Head" and Vector3.new(2,1,1) or Vector3.new(2,2,1);p.Transparency=1;p.Parent=model;core[name]=p
  end
  original.Name="RiftVisualSkin";original.Parent=model
 end
 local previousHumanoid=model:FindFirstChildOfClass("Humanoid");if previousHumanoid then previousHumanoid:Destroy() end
 local humanoid=Instance.new("Humanoid");humanoid.Parent=model;humanoid.RigType=Enum.HumanoidRigType.R6
 humanoid.HipHeight=0;humanoid.RequiresNeck=false;humanoid.BreakJointsOnDeath=false;humanoid.MaxHealth=100;humanoid.Health=100
 -- Remove the old Animator's cached tracks; the game supplies its R6 Animate script.
 local old=humanoid:FindFirstChildOfClass("Animator");if old then old:Destroy() end
 local animator=Instance.new("Animator");animator.Parent=humanoid
 for name,p in pairs(core) do
  p.Anchored=false;p.CanCollide=name=="Torso" or name=="Head";p.CanTouch=false;p.Massless=false
 end
 core.HumanoidRootPart.CanCollide=false;core.HumanoidRootPart.RootPriority=127
 link(core);weldExtras(model,core);humanoid.RequiresNeck=true
 model.PrimaryPart=core.HumanoidRootPart;model:SetAttribute("RiftRepaired",true)
 return model
end
return R
