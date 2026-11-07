-- Preserve authored R6/R15 geometry while rebuilding its articulated endpoints.
local R={}
local names={"HumanoidRootPart","Torso","Head","Right Arm","Left Arm","Right Leg","Left Leg"}
local function clean(model)
 local descendants=model:GetDescendants()
 for index=#descendants,1,-1 do
  local v=descendants[index]
  if v:IsA("LuaSourceContainer") or v:IsA("JointInstance") or v:IsA("WeldConstraint") or v:IsA("Constraint") or v:IsA("BodyMover") then v:Destroy()
  elseif v:IsA("ParticleEmitter") or v:IsA("Beam") or v:IsA("Trail") then
   -- Authored outfits can contain many always-on aura emitters. The bounded
   -- client VFX system owns presentation after a fighter is equipped.
   v.Enabled=false
  elseif v:IsA("Sound") then v.Playing=false;v.Looped=false;v.PlayOnRemove=false end
 end
end
local function motor(name,a,b,c0,c1)
 local m=Instance.new("Motor6D");m.Name=name;m.Part0=a;m.Part1=b;m.C0=c0;m.C1=c1 or b.CFrame:ToObjectSpace(a.CFrame*c0);m.Transform=CFrame.new();m.Parent=a
end
local function captureBindings(model,core)
 local members={};for _,p in pairs(core) do members[p]=true end
 local result={}
 for _,joint in ipairs(model:GetDescendants()) do
  if joint:IsA("Motor6D") or joint:IsA("Weld") then
   if joint.Part0 and joint.Part1 and members[joint.Part0] and members[joint.Part1] and not result[joint.Part1] then
    result[joint.Part1]={Part0=joint.Part0,C0=joint.C0,C1=joint.C1}
   end
  end
 end
 return result
end
local function connectBody(name,a,b,c0,bindings)
 local saved=bindings and bindings[b]
 if saved and saved.Part0==a then motor(name,a,b,saved.C0,saved.C1)
 else motor(name,a,b,c0) end
end
local function link(core,bindings)
 local quarter=CFrame.Angles(-math.pi/2,0,math.pi)
 connectBody("RootJoint",core.HumanoidRootPart,core.Torso,quarter,bindings)
 connectBody("Neck",core.Torso,core.Head,CFrame.new(0,core.Torso.Size.Y/2,0)*quarter,bindings)
 for _,side in ipairs({-1,1}) do
  local word=side==1 and "Right" or "Left"
  local arm,leg=core[word.." Arm"],core[word.." Leg"]
  local turn=CFrame.Angles(0,side*math.pi/2,0)
  connectBody(word.." Shoulder",core.Torso,arm,CFrame.new(side*core.Torso.Size.X/2,core.Torso.Size.Y/2-arm.Size.Y/4,0)*turn,bindings)
  connectBody(word.." Hip",core.Torso,leg,CFrame.new(side*leg.Size.X/2,-core.Torso.Size.Y/2,0)*turn,bindings)
 end
end
local function bodyGroup(part)
 local p=part
 while p do
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
local function skinHost(part,core,hints)
 local host=hints and hints[part] or core[bodyGroup(part)]
 if not host then
  local distance=math.huge
  for name,candidate in pairs(core) do
   if name~="HumanoidRootPart" then
    local d=(candidate.CFrame.Position-part.CFrame.Position).Magnitude
    if d<distance then distance=d;host=candidate end
   end
  end
 end
 return host
end
local function weldExtras(model,core,hints)
 local set={};for _,part in pairs(core) do set[part]=true end
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") and not set[part] then
   local host=skinHost(part,core,hints)
   part.Anchored=false;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.Massless=true
   local weld=Instance.new("WeldConstraint");weld.Parent=part;weld.Name="RiftSkinWeld";weld.Part0=host;weld.Part1=part
  end
 end
end
-- Capture the authored attachment graph before removing old joints. Accessories
-- may use reversed welds; spatial proximity is only the final fallback.
local function hosts(model,core)
 local found={};for _,part in pairs(core) do found[part]=part end
 local all={}
 for _,v in ipairs(model:GetDescendants()) do if v:IsA("Weld") or v:IsA("WeldConstraint") or v:IsA("Motor6D") then table.insert(all,v) end end
 for _=1,#all do
  local changed=false
  for _,v in ipairs(all) do
   if (v:IsA("Weld") or v:IsA("WeldConstraint") or v:IsA("Motor6D")) and v.Part0 and v.Part1 then
    if found[v.Part0] and not found[v.Part1] then found[v.Part1]=found[v.Part0];changed=true
    elseif found[v.Part1] and not found[v.Part0] then found[v.Part0]=found[v.Part1];changed=true end
   end
  end
  if not changed then break end
 end
 return found
end
local function settle(model,root)
 local offsets={}
 for _,v in ipairs(model:GetDescendants()) do if v:IsA("WeldConstraint") and v.Name=="RiftSkinWeld" then
  offsets[v]={v.Part0,v.Part1,v.Part0.CFrame:ToObjectSpace(v.Part1.CFrame)}
 end end
 local motors={}
 for _,v in ipairs(model:GetDescendants()) do if v:IsA("Motor6D") then table.insert(motors,v) end end
 local reached={[root]=true}
 for _=1,#motors do
  local changed=false
  for _,m in ipairs(motors) do if reached[m.Part0] and not reached[m.Part1] then
   m.Part1.CFrame=m.Part0.CFrame*m.C0*m.C1:Inverse();reached[m.Part1]=true;changed=true
  end end
  if not changed then break end
 end
 for _,v in pairs(offsets) do v[2].CFrame=v[1].CFrame*v[3] end
end
local r15Names={"HumanoidRootPart","LowerTorso","UpperTorso","Head","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot"}
local r15Links={{"Root","HumanoidRootPart","LowerTorso"},{"Waist","LowerTorso","UpperTorso"},{"Neck","UpperTorso","Head"}}
for _,side in ipairs({"Left","Right"}) do
 table.insert(r15Links,{side.."Shoulder","UpperTorso",side.."UpperArm"})
 table.insert(r15Links,{side.."Elbow",side.."UpperArm",side.."LowerArm"})
 table.insert(r15Links,{side.."Wrist",side.."LowerArm",side.."Hand"})
 table.insert(r15Links,{side.."Hip","LowerTorso",side.."UpperLeg"})
 table.insert(r15Links,{side.."Knee",side.."UpperLeg",side.."LowerLeg"})
 table.insert(r15Links,{side.."Ankle",side.."LowerLeg",side.."Foot"})
end
-- Common kit naming conventions describe real rig parts, not a loose skin.
-- Normalize only body endpoints; retain every visible part and its transform.
local function normalizeBodyNames(model)
 local aliases={head="Head",hhead="Head",torso="Torso",humanoidrootpart="HumanoidRootPart",leftarm="Left Arm",rightarm="Right Arm",leftleg="Left Leg",rightleg="Right Leg"}
 local endpoints,scores={},{}
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") then
   local key=part.Name:lower():gsub("[%s_%-]",""):gsub("^rbxbody",""):gsub("^stand","")
   local name=aliases[key]
   if name then
    local score=(part.Parent==model and 100 or 0)+(part.Name==name and 10 or 0)
    if not endpoints[name] or score>scores[name] then endpoints[name]=part;scores[name]=score end
   end
  end
 end
 for name,part in pairs(endpoints) do
  part.Parent=model
  -- Some packs have a cosmetic Model and body Part with the same name. A
  -- FindFirstChild lookup could choose the cosmetic container as the joint endpoint.
  for _,other in ipairs(model:GetChildren()) do
   if other~=part and other.Name==name then other.Name=name.."Details";other.Parent=part end
  end
  part.Name=name
 end
 local torso=endpoints.Torso
 if torso and not endpoints.HumanoidRootPart then
  local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Size=torso.Size;root.CFrame=torso.CFrame
  root.Transparency=1;root.CanCollide=false;root.CanTouch=false;root.CanQuery=false;root.Parent=model
 end
end
function R.Prepare(template,options)
 if not template or not template:IsA("Model") then return nil,"Expected a Model" end
 local archivable=template.Archivable
 template.Archivable=true
 local cloned,original=pcall(function() return template:Clone() end)
 template.Archivable=archivable
 if not cloned or not original then return nil,"Character model could not be cloned" end
 normalizeBodyNames(original)
 -- A nested StarterCharacter is an articulated rig, not a loose visual skin.
 local nested=original:FindFirstChild("UpperTorso",true) or original:FindFirstChild("HumanoidRootPart",true)
 if nested and nested.Parent~=original and nested.Parent:IsA("Model") then
  local container=nested.Parent
  if container:FindFirstChild("UpperTorso") or container:FindFirstChild("Torso") then
   for _,item in ipairs(container:GetChildren()) do item.Parent=original end
   container:Destroy()
  end
 end
 normalizeBodyNames(original)
 for _,item in ipairs(original:GetDescendants()) do
  if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("BodyColors") then item.Parent=original end
 end
 -- Some toolbox R15 rigs omit hand geometry. Keep their arm articulation;
 -- invisible wrist endpoints are joint helpers, not replacement visible models.
 if original:FindFirstChild("UpperTorso") and original:FindFirstChild("LowerTorso") then
  for _,side in ipairs({"Left","Right"}) do
   local lower=original:FindFirstChild(side.."LowerArm")
   local wrist=lower and lower:FindFirstChild(side.."WristRigAttachment")
   if wrist and not original:FindFirstChild(side.."Hand") then
    local hand=Instance.new("Part");hand.Name=side.."Hand";hand.Size=Vector3.new(.2,.2,.2);hand.Transparency=1;hand.CFrame=lower.CFrame*wrist.CFrame;hand.Parent=original
    local a=Instance.new("Attachment");a.Parent=hand;a.Name=side.."WristRigAttachment";a.CFrame=CFrame.new()
   end
  end
 end
 local native={};local complete=true
 for _,name in ipairs(r15Names) do
  local part=original:FindFirstChild(name)
  if part and part:IsA("BasePart") then native[name]=part else complete=false end
 end
 if complete then
  local hints=hosts(original,native);local bindings=captureBindings(original,native);clean(original)
  local old=original:FindFirstChildOfClass("Humanoid");if old then old:Destroy() end
  local h=Instance.new("Humanoid");h.Parent=original;h.RigType=Enum.HumanoidRigType.R15;h.AutomaticScalingEnabled=false;h.RequiresNeck=false;h.BreakJointsOnDeath=false;h.MaxHealth=100;h.Health=100
  h.HipHeight=native.LeftUpperLeg.Size.Y+native.LeftLowerLeg.Size.Y+native.LeftFoot.Size.Y-native.HumanoidRootPart.Size.Y/2
  local animator=Instance.new("Animator");animator.Parent=h
  for _,spec in ipairs(r15Links) do
   local a,b=native[spec[2]],native[spec[3]];local attachment=spec[1].."RigAttachment"
   local anchor=a:FindFirstChild(attachment)
   local c0=anchor and anchor:IsA("Attachment") and anchor.CFrame or CFrame.new(a.CFrame:PointToObjectSpace((a.CFrame.Position+b.CFrame.Position)/2))
   -- The visible authored pose is authoritative. Stale/missing attachment C1s
   -- must not relocate a head or limb when the character enters Workspace.
   connectBody(spec[1],a,b,c0,bindings)
  end
  weldExtras(original,native,hints);settle(original,native.HumanoidRootPart)
  local foot=native.HumanoidRootPart.CFrame:PointToObjectSpace(native.LeftFoot.CFrame.Position)
  h.HipHeight=math.max(0,-foot.Y+native.LeftFoot.Size.Y/2-native.HumanoidRootPart.Size.Y/2)
  for name,p in pairs(native) do p.Anchored=false;p.CanCollide=name=="UpperTorso" or name=="Head";p.CanTouch=false;p.Massless=false end
  native.HumanoidRootPart.RootPriority=127;native.HumanoidRootPart.Transparency=1;original.PrimaryPart=native.HumanoidRootPart
  h.RequiresNeck=true;original:SetAttribute("RiftRepaired",true);return original
 end
 local core={};local canonical=true
 for _,name in ipairs(names) do
  local part=original:FindFirstChild(name)
  if part and part:IsA("BasePart") then core[name]=part else canonical=false end
 end
 local hints=canonical and hosts(original,core) or nil
 local bindings=canonical and captureBindings(original,core) or nil
 clean(original)
 local model=original
 if not canonical then
  original:Destroy()
  return nil,"Missing articulated body endpoints; no generic skeleton was substituted"
 end
 for _,item in ipairs(model:GetDescendants()) do
  if item:IsA("Shirt") or item:IsA("Pants") or item:IsA("ShirtGraphic") or item:IsA("BodyColors") then item.Parent=model end
 end
 local previousHumanoid=model:FindFirstChildOfClass("Humanoid");if previousHumanoid then previousHumanoid:Destroy() end
 local humanoid=Instance.new("Humanoid");humanoid.Parent=model;humanoid.RigType=Enum.HumanoidRigType.R6
 humanoid.HipHeight=0;humanoid.AutomaticScalingEnabled=false;humanoid.RequiresNeck=false;humanoid.BreakJointsOnDeath=false;humanoid.MaxHealth=100;humanoid.Health=100
 -- Remove the old Animator's cached tracks; the game supplies its R6 Animate script.
 local old=humanoid:FindFirstChildOfClass("Animator");if old then old:Destroy() end
 local animator=Instance.new("Animator");animator.Parent=humanoid
 for name,p in pairs(core) do
  p.Anchored=false;p.CanCollide=name=="Torso" or name=="Head";p.CanTouch=false;p.Massless=false
 end
 core.HumanoidRootPart.CanCollide=false;core.HumanoidRootPart.Transparency=1;core.HumanoidRootPart.RootPriority=127
 link(core,bindings);weldExtras(model,core,hints);settle(model,core.HumanoidRootPart);humanoid.RequiresNeck=true
 model.PrimaryPart=core.HumanoidRootPart;model:SetAttribute("RiftRepaired",true)
 return model
end
return R
