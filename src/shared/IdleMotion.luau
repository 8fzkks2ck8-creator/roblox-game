-- Client-only idle and walking poses for every equipped fighter. Motor6D poses
-- also move the visual pieces welded to repaired/carrier rigs; no animation
-- upload or asset permission is needed. Each client observes all player rigs.
local I={}
local calm={gojo=true,beerus=true,awakened_aizen=true,aizen=true,byakuya=true,cid=true,ui_goku=true,kakashi=true,yuta=true,golden_experience_requiem=true}
local energetic={deku=true,kid_naruto=true,naruto=true,yuji=true,lee=true,denji=true,gear5_luffy=true,simon=true,gogeta=true,vegito=true}
local heavy={broly=true,boros=true,saitama=true,jotaro=true,dio=true,vegeta=true,madara=true,piccolo=true,asta=true,ssb_goku=true,ssj_goku=true}
local calmProfile={Speed=.85,Breath=.025,Lean=.012}
local energeticProfile={Speed=1.65,Breath=.045,Lean=.024}
local heavyProfile={Speed=1.05,Breath=.025,Lean=.009}
local defaultProfile={Speed=1.15,Breath=.032,Lean=.016}
function I.Profile(id)
 if calm[id] then return calmProfile end
 if energetic[id] then return energeticProfile end
 if heavy[id] then return heavyProfile end
 return defaultProfile
end
-- Authored procedural direction for every Mythic, Secret and Super Secret.
-- Angles are in radians. Signatures run occasionally, leaving a readable held
-- stance between gestures instead of constantly waving the imported meshes.
local idles={}
local function add(id,title,gesture,cycle,phase,speed,spread,raise,lean,look)
 idles[id]={Title=title,Gesture=gesture,Cycle=cycle,Phase=phase,Speed=speed,Spread=spread,Raise=raise,Lean=lean,Look=look,MaxAngle=1.1,MaxBob=.04}
end
add("vegeta","Royal folded guard","Fold",8.7,.11,1.1,.06,.35,-.025,.04)
add("ichigo","Moonfang shoulder settle","Shoulder",8.3,.23,1.02,.08,.12,.025,.06)
add("sukuna","King's disdain","Smirk",9.2,.37,.84,.13,.1,-.025,.13)
add("gojo","Limitless hand float","FloatHand",9.8,.05,.72,.08,.12,-.015,.1)
add("asta","Anti-magic ready stance","Fist",6.8,.49,1.5,.19,.24,.055,.05)
add("yuji","Black Flash knuckle check","Knuckles",7.2,.61,1.35,.14,.26,.035,.045)
add("deku","Full Cowling fist resolve","Fist",7.6,.73,1.43,.1,.3,.045,.07)
add("jotaro","Silent cap glance","Cap",10.4,.17,.76,.06,.08,-.02,.1)
add("dio","Frozen-second command","Command",9.1,.29,.91,.17,.17,-.035,.095)
add("gogeta","Stardust confident guard","Guard",7.7,.41,1.2,.22,.33,.015,.06)
add("vegito","Spirit sword hand check","Palm",8.1,.53,1.11,.12,.2,-.02,.08)
add("ssb_goku","Azure martial breathing","Guard",8.5,.65,1.18,.17,.4,.035,.035)
add("naruto","Sage ready bounce","Ready",6.5,.07,1.58,.2,.28,.035,.07)
add("aizen","Sovereign's quiet glance","Composed",11.8,.19,.64,.045,.07,-.025,.105)
add("ui_goku","Ultra Instinct stillness","Dodge",12.4,.31,.68,.16,.12,-.015,.055)
add("cid","Atomic open palm","Palm",10.8,.43,.71,.09,.16,-.035,.085)
add("madara","Horizon survey","Survey",11.2,.02,.74,.08,.31,-.025,.17)
add("gear5_luffy","Liberated laughing sway","Laugh",6.1,.67,1.62,.25,.22,-.03,.1)
add("beerus","Destroyer's dismissive hand","Dismiss",12.1,.13,.69,.09,.13,-.025,.13)
add("boros","Meteoric shoulder flare","Flare",8.8,.25,1.09,.24,.24,.03,.06)
add("saitama","Serious casual stretch","Shoulder",13.1,.47,.81,.045,.035,.005,.08)
add("golden_experience_requiem","Requiem's measured decree","Command",11.4,.59,.77,.13,.32,-.02,.075)
add("marlon","Rift sovereign decree","Crown",10.1,.09,.82,.24,.34,-.035,.1)
add("awakened_aizen","Chrysalis open stance","Ascend",12.7,.21,.62,.3,.19,-.045,.08)
add("broly","Legendary braced power","Power",7.4,.33,1.08,.29,.29,.065,.045)
add("simon","Spiral-to-heaven resolve","Spiral",8.9,.45,1.27,.18,.29,.025,.11)
function I.IdleProfile(id) return idles[id] end
-- Scalar returns keep the update loop free of pose-table/Instance allocations.
function I.SampleIdle(id,role,side,elapsed)
 local p=idles[id];if not p then return 0,0,0,0 end
 local t=elapsed*p.Speed+p.Phase*math.pi*2
 local breath=math.sin(t);local sway=math.sin(t*.47)
 local cycle=(elapsed/p.Cycle+p.Phase)%1
 local wave=math.sin(math.clamp((cycle-.64)/.34,0,1)*math.pi)^2
 local x,y,z,bob=0,0,0,0
 if role=="Root" then x=p.Lean+breath*.008;y=sway*.012;z=sway*.009;bob=breath*.012
 elseif role=="Neck" then x=-p.Lean*.4+breath*.014;y=sway*p.Look
 elseif role=="Arm" then x=-p.Raise+breath*.018;y=side*.025;z=side*(p.Spread+breath*.012)
 elseif role=="Leg" then x=-p.Lean*.2;z=-side*.018
 elseif role=="Knee" then x=.035+breath*.006
 elseif role=="Elbow" then x=-p.Raise*.5-breath*.012
 elseif role=="Ankle" then x=p.Lean*.2 end
 local right=side==1
 local gesture=p.Gesture
 if gesture=="Fold" then
  if role=="Arm" then x-=.3;z-=side*.36;y+=side*.14 end
  if role=="Neck" then y+=wave*.13 end
 elseif gesture=="FloatHand" then
  if role=="Arm" and right then x-=.4+wave*.4;z+=.12+wave*.13 end
  if role=="Neck" then y-=wave*.2 end
 elseif gesture=="Survey" then
  if role=="Arm" then x-=.12;z-=side*.18;y+=side*.13 end
  if role=="Neck" then y+=wave*.22;x-=wave*.045 end
 elseif gesture=="Power" or gesture=="Flare" then
  if role=="Arm" then x-=wave*.18;z+=side*wave*.2 end
  if role=="Root" then x+=wave*.045;bob+=wave*.012 end
  if role=="Neck" then x-=wave*.09 end
 elseif gesture=="Cap" then
  if role=="Arm" and right then x-=wave*.7;z-=wave*.24 end
  if role=="Neck" then x+=wave*.12;y-=wave*.11 end
 elseif gesture=="Smirk" then
  if role=="Neck" then z-=wave*.09;y+=wave*.18 end
  if role=="Arm" and right then x-=wave*.35 end
 elseif gesture=="Palm" or gesture=="Command" or gesture=="Crown" then
  if role=="Arm" and right then x-=wave*.62;z+=wave*.16;y-=wave*.16 end
  if role=="Neck" then y-=wave*.12 end
 elseif gesture=="Knuckles" then
  if role=="Arm" then x-=wave*.45;z-=side*wave*.25 end
  if role=="Neck" then x+=wave*.1 end
 elseif gesture=="Ready" or gesture=="Fist" or gesture=="Guard" then
  if role=="Arm" then x-=wave*(right and .36 or .17);z-=side*wave*.06 end
  if role=="Root" then bob+=wave*.018;x+=wave*.018 end
 elseif gesture=="Laugh" then
  if role=="Neck" then x-=wave*.2;z+=math.sin(t*1.8)*wave*.07 end
  if role=="Root" then z+=wave*.04;bob+=math.sin(t*2)*wave*.02 end
  if role=="Arm" then z+=side*wave*.24 end
 elseif gesture=="Dismiss" then
  if role=="Arm" and right then x-=wave*.45;z+=wave*.35 end
  if role=="Neck" then y+=wave*.19 end
 elseif gesture=="Shoulder" then
  if role=="Arm" and right then z+=wave*.22;x-=wave*.16 end
  if role=="Root" then y-=wave*.08 end
 elseif gesture=="Composed" then
  if role=="Neck" then y+=wave*.2;x-=wave*.035 end
  if role=="Arm" and right then x-=wave*.17 end
 elseif gesture=="Dodge" then
  if role=="Root" then z+=wave*.075;y-=wave*.06 end
  if role=="Neck" then y+=wave*.12 end
 elseif gesture=="Ascend" then
  if role=="Arm" then z+=side*wave*.28;x-=wave*.17 end
  if role=="Root" then bob+=wave*.025 end
  if role=="Neck" then x-=wave*.12 end
 elseif gesture=="Spiral" then
  if role=="Arm" and right then x-=wave*.72;z+=wave*.23 end
  if role=="Neck" then x-=wave*.1;y-=wave*.1 end
 end
 return math.clamp(x,-p.MaxAngle,p.MaxAngle),math.clamp(y,-p.MaxAngle,p.MaxAngle),math.clamp(z,-p.MaxAngle,p.MaxAngle),math.clamp(bob,-p.MaxBob,p.MaxBob)
end
local function jointRole(joint)
 local name=joint.Name:lower():gsub("[%s_%-]","")
 if name=="neck" then return "Neck",0 end
 if name=="rootjoint" or name=="root" or name=="waist" then return "Root",0 end
 local side=name:find("right",1,true) and 1 or name:find("left",1,true) and -1 or 0
 if side==0 then return nil end
 if name:find("shoulder",1,true) then return "Arm",side end
 if name:find("hip",1,true) then return "Leg",side end
 if name:find("knee",1,true) then return "Knee",side end
 if name:find("elbow",1,true) then return "Elbow",side end
 if name:find("ankle",1,true) then return "Ankle",side end
end
function I.Mount(character,id,run,clock)
 clock=clock or os.clock
 local joints={};local h=character:FindFirstChildOfClass("Humanoid")
 local root=character:FindFirstChild("HumanoidRootPart")
 for _,v in ipairs(character:GetDescendants()) do
  if v:IsA("Motor6D") then
   local role,side=jointRole(v)
   if role then table.insert(joints,{Joint=v,Base=v.C0,Role=role,Side=side,Owned=false}) end
  end
 end
 local profile=I.Profile(id);local customIdle=I.IdleProfile(id);local connection;local last=clock();local began=last;local phase=0;local blend=0;local idleBlend=0
 local identity=CFrame.new()
 local function restore(entry)
  if entry.Joint.Parent and not entry.Joint:GetAttribute("RiftPunch") then
   entry.Joint.C0=entry.Base
   if entry.Owned then entry.Joint.Transform=identity end
  end
  entry.Owned=false
 end
 local function stop()
  if connection then connection:Disconnect();connection=nil end
  for _,entry in ipairs(joints) do restore(entry) end
 end
 connection=run.PreSimulation:Connect(function()
  if not character.Parent then stop();return end
  local now=clock();local dt=math.clamp(now-last,0,.1);last=now
  -- Velocity works for remote players too; their MoveDirection is not reliable.
  -- Ignore vertical motion, and leave jump/fall/swim/climb/seated animations alone.
  local velocity=root and root.AssemblyLinearVelocity or Vector3.zero
  local speed=Vector3.new(velocity.X,0,velocity.Z).Magnitude
  local grounded=h and h.FloorMaterial~=Enum.Material.Air and not h.Sit and h.Health>0
  local eligible=grounded
  if grounded and h.GetState then
   local state=h:GetState()
   eligible=state~=Enum.HumanoidStateType.Climbing and state~=Enum.HumanoidStateType.Swimming and state~=Enum.HumanoidStateType.PlatformStanding and state~=Enum.HumanoidStateType.Physics
  end
  local locomotion=eligible and speed>.5
  local target=locomotion and math.clamp(speed/10,.15,1) or 0
  blend+=(target-blend)*math.min(1,dt*14)
  if blend<.003 then blend=0 end
  -- Faster travel increases cadence, rather than sliding a fixed-speed animation.
  phase+=dt*(4+math.min(speed,28)*.45)
  local backwards=1
  if root and speed>.5 and root.CFrame:VectorToObjectSpace(velocity).Z>.5 then backwards=-1 end
  local walking=eligible and blend>0
  local idle=not h or (h.Health>0 and h.MoveDirection.Magnitude<.05 and eligible and speed<.5)
  idleBlend+=((idle and not walking and 1 or 0)-idleBlend)*math.min(1,dt*8)
  local t=now*profile.Speed
  for _,entry in ipairs(joints) do
   local joint=entry.Joint
   if joint.Parent then
    if not joint:GetAttribute("RiftPunch") then
     local role=entry.Role
     if walking then
      local stride=math.sin(phase)*entry.Side*blend*backwards
      local x,y,z,bob=0,0,0,0
      if role=="Arm" then x=-stride*.62;z=entry.Side*.035*blend
      elseif role=="Leg" then x=stride*.72
      elseif role=="Knee" then x=math.max(0,-stride)*.55
      elseif role=="Elbow" then x=-.12*blend-math.max(0,stride)*.16
      elseif role=="Ankle" then x=-stride*.18
      elseif role=="Root" then x=-.035*blend;bob=(1-math.cos(phase*2))*.045*blend
      elseif role=="Neck" then x=.025*blend;y=math.sin(phase)*.018*blend end
      -- Apply rotations in the torso's axes, before the authored joint rotation.
      -- R6 shoulders/hips have a 90-degree C0; multiplying after it twists them.
      joint.C0=CFrame.new(entry.Base.Position+Vector3.new(0,bob,0))*CFrame.Angles(x,y,z)*entry.Base.Rotation
      joint.Transform=identity;entry.Owned=true
     else
      restore(entry)
      if idle and customIdle then
       local x,y,z,bob=I.SampleIdle(id,role,entry.Side,now-began)
       joint.C0=CFrame.new(entry.Base.Position+Vector3.new(0,bob*idleBlend,0))*CFrame.Angles(x*idleBlend,y*idleBlend,z*idleBlend)*entry.Base.Rotation
       joint.Transform=identity;entry.Owned=true
      elseif idle and (role=="Neck" or role=="Arm") then
       local neck=role=="Neck"
       joint.C0=entry.Base*CFrame.Angles(math.sin(t)*profile.Breath*(neck and .4 or 1),neck and math.sin(t*.6)*profile.Lean or 0,neck and 0 or math.sin(t*.8)*profile.Lean)
      end
     end
    else
     -- Punch owns the complete shoulder pose until it clears its attribute.
     entry.Owned=false
    end
   end
  end
 end)
 return stop
end
return I
