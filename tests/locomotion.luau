-- Appended to rig_repair.luau by test_locomotion.py. Real joints/CFrames; engine
-- physics/Animator scheduling are outside Lune and still need Studio validation.
local I=(function()
__IDLE_SOURCE__
end)()
local Color3=roblox.Color3
local C=(function()
__CONFIG_SOURCE__
end)()
local state=Enum.HumanoidStateType.Running
roblox.implementMethod("Humanoid","GetState",function() return state end)
local function signal()
 local handlers={}
 return {
  Connect=function(_,fn)
   table.insert(handlers,fn)
   return {Disconnect=function() local at=table.find(handlers,fn);if at then table.remove(handlers,at) end end}
  end,
  Fire=function() for _,fn in table.clone(handlers) do fn() end end,
  Count=function() return #handlers end,
 }
end
local function locomotion(rig)
 local character,reason=R.Prepare(rig);assert(character,reason)
 local parent=Instance.new("Folder");character.Parent=parent
 local humanoid=character:FindFirstChildOfClass("Humanoid")
 humanoid.FloorMaterial=Enum.Material.Grass;humanoid.MoveDirection=Vector3.zero;humanoid.Sit=false
 local root=character.HumanoidRootPart
 local left=character.Torso["Left Hip"];local right=character.Torso["Right Hip"]
 local shoulder=character.Torso["Right Shoulder"]
 local leftBase,rightBase,shoulderBase=left.C0,right.C0,shoulder.C0
 local frames=signal();local now=0
 local stop=I.Mount(character,rig.Name,{PreSimulation=frames},function() return now end)
 root.AssemblyLinearVelocity=Vector3.new(0,0,-16)
 now=.1;frames:Fire()
 assert(left.C0~=leftBase and right.C0~=rightBase,"walking did not move both hips: "..rig.Name)
 local leftTurn=left.C0*leftBase:Inverse();local rightTurn=right.C0*rightBase:Inverse()
 -- Compare the parent-space orientations: opposite legs must oppose each other.
 local lx=select(1,leftTurn:ToEulerAnglesXYZ());local rx=select(1,rightTurn:ToEulerAnglesXYZ())
 assert(lx*rx<0,"walking hips do not oppose each other: "..rig.Name)
 assert(shoulder.C0~=shoulderBase,"walking did not swing an arm: "..rig.Name)
 shoulder:SetAttribute("RiftPunch",true);shoulder.C0=CFrame.Angles(.3,.2,.1);local punchPose=shoulder.C0
 now=.2;frames:Fire();assert(shoulder.C0==punchPose,"walking overwrote a punch")
 shoulder:SetAttribute("RiftPunch",nil)
 humanoid.Sit=true;now=.3;frames:Fire()
 assert(left.C0==leftBase and right.C0==rightBase,"sitting did not release leg poses")
 humanoid.Sit=false;humanoid.FloorMaterial=Enum.Material.Air
 now=.4;frames:Fire();assert(left.C0==leftBase,"airborne rig was walking")
 humanoid.FloorMaterial=Enum.Material.Grass;state=Enum.HumanoidStateType.Swimming
 now=.5;frames:Fire();assert(left.C0==leftBase,"swimming rig was walking")
 state=Enum.HumanoidStateType.Running
 root.AssemblyLinearVelocity=Vector3.zero
 for _=1,20 do now+=.1;frames:Fire() end
 local heldLeft,heldRight=left.C0,right.C0
 now+=.1;frames:Fire()
 assert(left.C0==heldLeft and right.C0==heldRight,"stopped rig kept stepping")
 stop();stop()
 assert(frames:Count()==0 and shoulder.C0==shoulderBase,"stop did not restore/disconnect")
 print("PASS locomotion: "..rig.Name.." (opposed hips, arm swing, punch, seat, air, swim, idle, cleanup)")
 character:Destroy();parent:Destroy()
end

-- Direction coverage is tied to the real rarity roster. Sample the entire cycle
-- and mount the actual joints: metadata alone cannot prove a pose is delivered.
local uploaded=require("@lune/process").args[1]
do
 local count=0;local titles={};local snapshots={}
 local imported={}
 if uploaded then
  local place=roblox.deserializePlace(fs.readFile(uploaded):gsub("^<%?xml.-%?>%s*",""))
  for _,model in place.ReplicatedStorage.AnimeRift.Assets.CharacterModels:GetChildren() do imported[model.Name]=model end
 end
 for _,hero in C.Characters do
  if hero.Tier>=5 then
   count+=1;local direction=I.IdleProfile(hero.Id)
   assert(direction and not titles[direction.Title],"missing or duplicate signature idle: "..hero.Id);titles[direction.Title]=true
   assert(direction.Cycle>=6 and direction.Cycle<=14 and direction.MaxAngle<=1.1 and direction.MaxBob<=.04,"idle limits: "..hero.Id)
   local first={};local differs=false
   for _,role in {"Root","Neck","Arm","Leg","Knee","Elbow","Ankle"} do
    for _,side in {-1,1} do
     local firstX,firstY,firstZ,firstBob=I.SampleIdle(hero.Id,role,side,0)
     table.insert(first,string.format("%.4f/%.4f/%.4f/%.4f",firstX,firstY,firstZ,firstBob))
     for step=1,100 do
      local x,y,z,bob=I.SampleIdle(hero.Id,role,side,step*direction.Cycle/50)
      assert(x==x and math.abs(x)<=direction.MaxAngle and math.abs(y)<=direction.MaxAngle and math.abs(z)<=direction.MaxAngle and math.abs(bob)<=direction.MaxBob,"unbounded signature pose: "..hero.Id)
      if math.abs(x-firstX)+math.abs(y-firstY)+math.abs(z-firstZ)+math.abs(bob-firstBob)>.025 then differs=true end
     end
    end
   end
   local snapshot=table.concat(first,"|");assert(not snapshots[snapshot],"indistinguishable idle pose: "..hero.Id);snapshots[snapshot]=true
   assert(differs,"signature never moves: "..hero.Id)
   local template=imported[hero.Id] or models:FindFirstChild(hero.Id) or fixture
   local character,reason=R.Prepare(template);assert(character,reason)
   local parent=Instance.new("Folder");character.Parent=parent
   local h=character:FindFirstChildOfClass("Humanoid");h.FloorMaterial=Enum.Material.Grass;h.Sit=false;h.MoveDirection=Vector3.zero
   local root=character.HumanoidRootPart;root.AssemblyLinearVelocity=Vector3.zero
   local shoulder=character.Torso["Right Shoulder"];local base=shoulder.C0
   local frames=signal();local now=0;local stop=I.Mount(character,hero.Id,{PreSimulation=frames},function() return now end)
   now=.1;frames:Fire();assert(shoulder.C0~=base,"idle was not applied to the real rig: "..hero.Id)
   assert(shoulder.Transform==CFrame.new(),"authored Animator can override signature idle: "..hero.Id)
   shoulder:SetAttribute("RiftPunch",true);shoulder.C0=CFrame.Angles(.2,.3,.4);local punch=shoulder.C0
   now+=.1;frames:Fire();assert(shoulder.C0==punch,"idle overwrote a punch: "..hero.Id);shoulder:SetAttribute("RiftPunch",nil)
   root.AssemblyLinearVelocity=Vector3.new(0,0,-16);now+=.1;frames:Fire();local walk=shoulder.C0
   now+=.1;frames:Fire();assert(shoulder.C0~=walk,"signature prevented walking: "..hero.Id)
   h.FloorMaterial=Enum.Material.Air;now+=.01;frames:Fire();assert(shoulder.C0==base,"idle survived airborne transition: "..hero.Id)
   h.FloorMaterial=Enum.Material.Grass;root.AssemblyLinearVelocity=Vector3.zero;h.Health=0;now+=.01;frames:Fire();assert(shoulder.C0==base,"idle survived death: "..hero.Id)
   stop();assert(shoulder.C0==base and frames:Count()==0,"idle did not restore/disconnect: "..hero.Id)
   character:Destroy();parent:Destroy()
   print("PASS signature idle: "..hero.Id.." — "..direction.Title)
  end
 end
 assert(count==26,"expected every Mythic/Secret/Super Secret idle")
 print("PASS all 26 signature idles: bounded, distinct, animated, punch/walk/air/death handoff, cleanup")
end
for _,rig in models:GetChildren() do if rig:IsA("Model") then locomotion(rig) end end
if uploaded then
 local data=fs.readFile(uploaded):gsub("^<%?xml.-%?>%s*","")
 local place=roblox.deserializePlace(data)
 local templates=place.ReplicatedStorage.AnimeRift.Assets.CharacterModels
 for _,rig in templates:GetChildren() do if rig:IsA("Model") then locomotion(rig) end end
end

-- The default player may still be R15 when an outfit has no imported template.
-- Its elbow/knee joints must join the gait without changing their bind offsets.
do
 local character=Instance.new("Model");local parent=Instance.new("Folder");character.Parent=parent
 local h=Instance.new("Humanoid");h.Parent=character;h.FloorMaterial=Enum.Material.Grass;h.Sit=false;h.Health=100;h.MoveDirection=Vector3.zero
 local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Parent=character;root.AssemblyLinearVelocity=Vector3.new(0,0,-12)
 local joints={}
 for _,name in {"LeftShoulder","RightShoulder","LeftHip","RightHip","LeftKnee","RightKnee","LeftElbow","RightElbow","LeftAnkle","RightAnkle","Waist"} do
  local joint=Instance.new("Motor6D");joint.Name=name;joint.C0=CFrame.new(.1,.2,.3)*CFrame.Angles(.1,.2,.3);joint.Parent=root
  table.insert(joints,{Joint=joint,Base=joint.C0})
 end
 local event=signal();local now=0;local stop=I.Mount(character,"deku",{PreSimulation=event},function() return now end)
 for _=1,15 do
  now+=.1;event:Fire()
  for _,entry in joints do if entry.Joint.C0~=entry.Base then entry.Moved=true end end
 end
 for _,entry in joints do assert(entry.Moved,"R15 joint did not join the gait: "..entry.Joint.Name) end
 h.Health=0;now+=.01;event:Fire()
 for _,entry in joints do assert(entry.Joint.C0==entry.Base,"dead R15 did not release its gait") end
 stop();assert(event:Count()==0)
 print("PASS locomotion: default R15 joints and death cleanup")
end
