-- Pose a bounded anchored viewport rig, keeping welded visual pieces with their limbs.
local P={}
function P.Bind(actor)
 local core={Torso=actor:FindFirstChild("Torso") or actor:FindFirstChild("Body"),Head=actor:FindFirstChild("Head")}
 for _,part in ipairs(actor:GetDescendants()) do
  if part:IsA("BasePart") then
   for _,side in ipairs({"Left","Right"}) do
    if part.Name==side.." Arm" then core[side.." Arm"]=part end
    if part.Name==side.." Leg" then core[side.." Leg"]=part end
   end
   if part.Name=="Arm" then core[part.CFrame.Position.X<0 and "Left Arm" or "Right Arm"]=part end
   if part.Name=="Leg" then core[part.CFrame.Position.X<0 and "Left Leg" or "Right Leg"]=part end
  end
 end
 if not core.Torso or not core.Head then return function() end end
 local bases,groups,parts={},{},{}
 for name,part in pairs(core) do bases[name]=part.CFrame;groups[part]=name end
 local all=actor:GetDescendants()
 for _=1,3 do for _,joint in ipairs(all) do
  if (joint:IsA("WeldConstraint") or joint:IsA("Weld")) and joint.Part0 and joint.Part1 then
   if groups[joint.Part0] and not groups[joint.Part1] then groups[joint.Part1]=groups[joint.Part0] end
  end
 end end
 for _,part in ipairs(all) do if part:IsA("BasePart") then
  local group=groups[part]
  if not group then
   local distance=math.huge
   for name,base in pairs(bases) do local d=(base.Position-part.CFrame.Position).Magnitude;if d<distance then distance=d;group=name end end
  end
  table.insert(parts,{Part=part,Group=group,Offset=bases[group]:ToObjectSpace(part.CFrame)})
 end end
 return function(sample)
  local torso=bases.Torso*CFrame.new(0,sample.RootY,0)*CFrame.Angles(sample.Lean,0,0)
  local posed={Torso=torso,Head=torso*bases.Torso:ToObjectSpace(bases.Head)*CFrame.Angles(sample.Head,0,0)}
  for _,side in ipairs({-1,1}) do
   local name=side<0 and "Left" or "Right"
   local arm=core[name.." Arm"];local leg=core[name.." Leg"]
   if arm then
    local shoulderY=core.Torso.Size.Y/2-.2
    posed[name.." Arm"]=torso*CFrame.new(side*core.Torso.Size.X/2,shoulderY,0)*CFrame.Angles(-sample.Arm,0,side*sample.Spread)*CFrame.new(side*arm.Size.X/2,-shoulderY,0)
   end
   if leg then posed[name.." Leg"]=torso*CFrame.new(side*core.Torso.Size.X/4,-core.Torso.Size.Y/2,0)*CFrame.Angles(sample.Leg,0,side*sample.Energy*.08)*CFrame.new(0,-leg.Size.Y/2,0) end
  end
  for _,entry in ipairs(parts) do if entry.Part.Parent then entry.Part.CFrame=(posed[entry.Group] or torso)*entry.Offset end end
 end
end
return P
