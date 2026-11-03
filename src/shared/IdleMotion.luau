-- Subtle procedural R6/R15 idle accents. Authored locomotion remains in control.
local I={}
local calm={gojo=true,beerus=true,awakened_aizen=true,aizen=true,byakuya=true,cid=true,ui_goku=true,kakashi=true,yuta=true,golden_experience_requiem=true}
local energetic={deku=true,kid_naruto=true,naruto=true,yuji=true,lee=true,denji=true,gear5_luffy=true,simon=true,gogeta=true,vegito=true}
local heavy={broly=true,boros=true,saitama=true,jotaro=true,dio=true,vegeta=true,madara=true,piccolo=true,asta=true,ssb_goku=true,ssj_goku=true}
function I.Profile(id)
 if calm[id] then return {Speed=.85,Breath=.025,Lean=.012} end
 if energetic[id] then return {Speed=1.65,Breath=.045,Lean=.024} end
 if heavy[id] then return {Speed=1.05,Breath=.025,Lean=.009} end
 return {Speed=1.15,Breath=.032,Lean=.016}
end
function I.Mount(character,id,run)
 local joints={};local h=character:FindFirstChildOfClass("Humanoid")
 for _,v in ipairs(character:GetDescendants()) do
  if v:IsA("Motor6D") and (v.Name=="Neck" or v.Name=="Right Shoulder" or v.Name=="Left Shoulder" or v.Name=="RightShoulder" or v.Name=="LeftShoulder") then table.insert(joints,{Joint=v,Base=v.C0}) end
 end
 local profile=I.Profile(id);local connection
 local function stop()
  if connection then connection:Disconnect();connection=nil end
  for _,entry in ipairs(joints) do if entry.Joint.Parent then entry.Joint.C0=entry.Base end end
 end
 connection=run.PreSimulation:Connect(function()
  if not character.Parent then stop();return end
  local idle=not h or (h.Health>0 and h.MoveDirection.Magnitude<.05 and h.FloorMaterial~=Enum.Material.Air and h.Sit==false)
  local t=os.clock()*profile.Speed
  for _,entry in ipairs(joints) do
   local joint=entry.Joint
   if joint.Parent then
    if not joint:GetAttribute("RiftPunch") then
     local neck=joint.Name=="Neck"
     joint.C0=entry.Base*(idle and CFrame.Angles(math.sin(t)*profile.Breath*(neck and .4 or 1),neck and math.sin(t*.6)*profile.Lean or 0,neck and 0 or math.sin(t*.8)*profile.Lean) or CFrame.new())
    end
   end
  end
 end)
 return stop
end
return I
