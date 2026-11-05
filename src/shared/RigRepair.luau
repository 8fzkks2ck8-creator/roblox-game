-- Repair canonical R6 rigs, or mount a visual model onto a stable R6 carrier.
local R={}
local names={"HumanoidRootPart","Torso","Head","Right Arm","Left Arm","Right Leg","Left Leg"}
local offsets={HumanoidRootPart={0,0,0},Torso={0,0,0},Head={0,1.5,0},["Right Arm"]={1.5,0,0},["Left Arm"]={-1.5,0,0},["Right Leg"]={.5,-2,0},["Left Leg"]={-.5,-2,0}}
local function clean(model)
 local descendants=model:GetDescendants()
 for index=#descendants,1,-1 do
  local v=descendants[index]
  if v:IsA("LuaSourceContainer") or v:IsA("JointInstance") or v:IsA("WeldConstraint") or v:IsA("Constraint") or v:IsA("BodyMover") then v:Destroy() end
 end
end
local function motor(name,a,b,c0,c1)
 local m=Instance.new("Motor6D");m.Name=name;m.Part0=a;m.Part1=b;m.C0=c0;m.C1=c1 or b.CFrame:ToObjectSpace(a.CFrame*c0);m.Transform=CFrame.new();m.Parent=a
end
local function link(core)
 local quarter=CFrame.Angles(-math.pi/2,0,math.pi)
 motor("RootJoint",core.HumanoidRootPart,core.Torso,quarter,quarter)
 motor("Neck",core.Torso,core.Head,CFrame.new(0,core.Torso.Size.Y/2,0)*quarter,CFrame.new(0,-core.Head.Size.Y/2,0)*quarter)
 for _,side in ipairs({-1,1}) do
  local word=side==1 and "Right" or "Left"
  local arm,leg=core[word.." Arm"],core[word.." Leg"]
  local turn=CFrame.Angles(0,side*math.pi/2,0)
  motor(word.." Shoulder",core.Torso,arm,CFrame.new(side*core.Torso.Size.X/2,core.Torso.Size.Y/2-arm.Size.Y/4,0)*turn,CFrame.new(-side*arm.Size.X/2,arm.Size.Y/4,0)*turn)
  motor(word.." Hip",core.Torso,leg,CFrame.new(side*leg.Size.X/2,-core.Torso.Size.Y/2,0)*turn,CFrame.new(0,leg.Size.Y/2,0)*turn)
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
local function weldExtras(model,core,hints)
 local set={};for _,part in pairs(core) do set[part]=true end
 for _,part in ipairs(model:GetDescendants()) do
  if part:IsA("BasePart") and not set[part] then
   local host=hints and hints[part] or core[bodyGroup(part)]
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
-- Capture the authored attachment graph before removing old joints. Accessories
-- may use reversed welds; spatial proximity is only the final fallback.
local function hosts(model,core)
 local found={};for _,part in pairs(core) do found[part]=part end
 local all=model:GetDescendants()
 for _=1,#all do
  local changed=false
  for _,v in ipairs(all) do
   if (v:IsA("Weld") or v:IsA("WeldConstraint")) and v.Part0 and v.Part1 then
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
 local reached={[root]=true}
 for _=1,20 do
  local changed=false
  for _,m in ipairs(model:GetDescendants()) do if m:IsA("Motor6D") and reached[m.Part0] and not reached[m.Part1] then
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
function R.Prepare(template,options)
 if not template or not template:IsA("Model") then return nil,"Expected a Model" end
 local original=template:Clone()
 local sourceRoot=original:FindFirstChild("HumanoidRootPart",true)
 local sourceOrientation=sourceRoot and sourceRoot:IsA("BasePart") and sourceRoot.CFrame.Rotation or CFrame.new()
 -- A nested StarterCharacter is an articulated rig, not a loose visual skin.
 local nested=original:FindFirstChild("HumanoidRootPart",true)
 if nested and nested.Parent~=original and nested.Parent:IsA("Model") then
  local container=nested.Parent
  if container:FindFirstChild("UpperTorso") or container:FindFirstChild("Torso") then
   for _,item in ipairs(container:GetChildren()) do item.Parent=original end
   container:Destroy()
  end
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
  for _,spec in ipairs(r15Links) do
   local name=spec[1].."RigAttachment"
   if not native[spec[2]]:FindFirstChild(name) or not native[spec[3]]:FindFirstChild(name) then complete=false;break end
  end
 end
 if complete then
  local hints=hosts(original,native);clean(original)
  local old=original:FindFirstChildOfClass("Humanoid");if old then old:Destroy() end
  local h=Instance.new("Humanoid");h.Parent=original;h.RigType=Enum.HumanoidRigType.R15;h.AutomaticScalingEnabled=false;h.RequiresNeck=false;h.BreakJointsOnDeath=false;h.MaxHealth=100;h.Health=100
  h.HipHeight=native.LeftUpperLeg.Size.Y+native.LeftLowerLeg.Size.Y+native.LeftFoot.Size.Y-native.HumanoidRootPart.Size.Y/2
  local animator=Instance.new("Animator");animator.Parent=h
  for _,spec in ipairs(r15Links) do
   local a,b=native[spec[2]],native[spec[3]];local attachment=spec[1].."RigAttachment"
   motor(spec[1],a,b,a[attachment].CFrame,b[attachment].CFrame)
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
 clean(original)
 local model=original
 if not canonical then
  local parts={};for _,p in ipairs(original:GetDescendants()) do if p:IsA("BasePart") and p.Name~="HumanoidRootPart" then table.insert(parts,p) end end
  if #parts==0 then original:Destroy();return nil,"Model has no visible body parts" end
  local descendants=original:GetDescendants()
  for index=#descendants,1,-1 do local v=descendants[index];if v:IsA("Humanoid") or v.Name=="HumanoidRootPart" then v:Destroy() end end
  -- Carrier axes must agree with the imported body's forward direction. Bounds
  -- centering alone left sideways-authored heads/clothes facing across the rig.
  local pivot=original:GetPivot()
  original:PivotTo(CFrame.new(pivot.Position)*sourceOrientation:Inverse()*pivot.Rotation)
  -- Normalize oversized toolbox models while preserving their relative appearance.
  local _,size=original:GetBoundingBox()
  original:ScaleTo(original:GetScale()*6/math.max(size.Y,.1))
  local bounds=original:GetBoundingBox()
  original:PivotTo(CFrame.new(0,-.5,0)*bounds:Inverse()*original:GetPivot())
  model=Instance.new("Model");model.Name=template.Name;core={}
  for _,name in ipairs(names) do
   local p=Instance.new("Part");p.Name=name;local o=offsets[name];p.CFrame=CFrame.new(o[1],o[2],o[3]);p.Size=(name:find("Arm") or name:find("Leg")) and Vector3.new(1,2,1) or name=="Head" and Vector3.new(2,1,1) or Vector3.new(2,2,1);p.Transparency=1;p.Parent=model;core[name]=p
  end
  -- Classic clothing renders on the Humanoid's direct R6 body, not a nested visual model.
  local shirt,pants,graphic=false,false,false
  for _,item in ipairs(original:GetDescendants()) do
   if item:IsA("Shirt") then shirt=true;item.Parent=model
   elseif item:IsA("Pants") then pants=true;item.Parent=model
   elseif item:IsA("ShirtGraphic") then graphic=true;item.Parent=model
   elseif item:IsA("BodyColors") then item.Parent=model end
  end
  local clothed={Torso=shirt or pants or graphic,["Right Arm"]=shirt,["Left Arm"]=shirt,["Right Leg"]=pants,["Left Leg"]=pants}
  for _,part in ipairs(original:GetDescendants()) do
   if part:IsA("BasePart") then
    local group=bodyGroup(part)
    if group and clothed[group] and not (options and options.VisualOnly) then
     core[group].Transparency=0;core[group].Color=part.Color;part.Transparency=1
    end
   end
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
 core.HumanoidRootPart.CanCollide=false;core.HumanoidRootPart.Transparency=1;core.HumanoidRootPart.RootPriority=127
 link(core);weldExtras(model,core,hints);settle(model,core.HumanoidRootPart);humanoid.RequiresNeck=true
 model.PrimaryPart=core.HumanoidRootPart;model:SetAttribute("RiftRepaired",true)
 return model
end
return R
