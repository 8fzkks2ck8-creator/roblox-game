-- Real serialized character geometry/CFrames, deterministic clocks and signal stand-ins.
-- Lune has no renderer or engine signals. Projection checks do not prove rendered appearance.
local roblox=require("@lune/roblox")
local fs=require("@lune/fs")
local process=require("@lune/process")
local RealInstance=roblox.Instance
local Vector3,Vector2,CFrame=roblox.Vector3,roblox.Vector2,roblox.CFrame
local NumberRange=roblox.NumberRange
local NumberSequence,NumberSequenceKeypoint=roblox.NumberSequence,roblox.NumberSequenceKeypoint
local Color3,ColorSequence,UDim2,UDim,Enum=roblox.Color3,roblox.ColorSequence,roblox.UDim2,roblox.UDim,roblox.Enum
local made=0
local Instance={new=function(...)
 made+=1;return RealInstance.new(...)
end}
local function signal()
 local listeners={}
 return {
  Connect=function(_,callback)
   local entry={Callback=callback,Active=true};table.insert(listeners,entry)
   return {Disconnect=function() entry.Active=false end}
  end,
  Fire=function(_,...)
   for _,entry in ipairs(table.clone(listeners)) do if entry.Active then entry.Callback(...) end end
  end,
  Count=function() local count=0;for _,entry in ipairs(listeners) do if entry.Active then count+=1 end end;return count end,
 }
end
local instanceSignals={}
local function event(instance,name)
 instanceSignals[instance]=instanceSignals[instance] or {}
 local signals=instanceSignals[instance]
 signals[name]=signals[name] or signal();return signals[name]
end
roblox.implementProperty("Instance","Destroying",function(instance) return event(instance,"Destroying") end)
roblox.implementProperty("GuiButton","Activated",function(instance) return event(instance,"Activated") end)
roblox.implementMethod("Instance","GetPropertyChangedSignal",function(instance,name) return event(instance,name) end)
local soundsPlayed,particlesEmitted={},{}
roblox.implementMethod("Sound","Play",function(sound) soundsPlayed[sound]=(soundsPlayed[sound] or 0)+1 end)
roblox.implementMethod("ParticleEmitter","Emit",function(emitter,count) particlesEmitted[emitter]=(particlesEmitted[emitter] or 0)+count end)
roblox.implementMethod("MeshPart","ApplyMesh",function(mesh,template) mesh:SetAttribute("TestAppliedMesh",template.Name) end)
-- These methods are absent from Lune. Bounds include all eight rotated corners;
-- pivot/scale operations apply real rigid transforms to the authored parts.
local pivots,scales={},{}
local function bounds(model)
 local low,high=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
 local count=0
 for _,part in ipairs(model:GetDescendants()) do if part:IsA("BasePart") then
  count+=1
  for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
   local point=part.CFrame:PointToWorldSpace(Vector3.new(part.Size.X*x,part.Size.Y*y,part.Size.Z*z)/2)
   low=Vector3.new(math.min(low.X,point.X),math.min(low.Y,point.Y),math.min(low.Z,point.Z))
   high=Vector3.new(math.max(high.X,point.X),math.max(high.Y,point.Y),math.max(high.Z,point.Z))
  end end end
 end end
 assert(count>0,"No authored body parts")
 return CFrame.new((low+high)/2),high-low
end
roblox.implementMethod("Model","GetBoundingBox",bounds)
roblox.implementMethod("Model","GetPivot",function(model)
 if pivots[model] then return pivots[model] end
 if model.PrimaryPart then return model.PrimaryPart.CFrame*model.PrimaryPart.PivotOffset end
 local ok,pivot=pcall(function() return model.WorldPivot end)
 return ok and pivot or bounds(model)
end)
roblox.implementMethod("Model","PivotTo",function(model,target)
 local delta=target*model:GetPivot():Inverse()
 for _,part in ipairs(model:GetDescendants()) do if part:IsA("BasePart") then part.CFrame=delta*part.CFrame end end
 pivots[model]=target
end)
roblox.implementMethod("Model","GetScale",function(model) return scales[model] or 1 end)
roblox.implementMethod("Model","ScaleTo",function(model,scale)
 local ratio=scale/(scales[model] or 1);local pivot=model:GetPivot()
 for _,part in ipairs(model:GetDescendants()) do if part:IsA("BasePart") then
  local relative=pivot:ToObjectSpace(part.CFrame)
  part.Size*=ratio;part.CFrame=pivot*CFrame.new(relative.Position*ratio)*relative.Rotation
 end end
 scales[model]=scale
end)
local frames=signal()
local input={TouchEnabled=false,InputBegan=signal()}
local soundService=RealInstance.new("SoundService")
local workspace=RealInstance.new("Workspace")
workspace.CurrentCamera=RealInstance.new("Camera");workspace.CurrentCamera.Parent=workspace
workspace.CurrentCamera.CameraType=Enum.CameraType.Custom
local subject=RealInstance.new("Part");subject.Parent=workspace;workspace.CurrentCamera.CameraSubject=subject
local actionBindings={}
workspace.CurrentCamera.ViewportSize=Vector2.new(1920,1080)
local services={RunService={RenderStepped=frames},UserInputService=input,SoundService=soundService,
 ContextActionService={BindActionAtPriority=function(_,name,fn) actionBindings[name]=fn end,UnbindAction=function(_,name) actionBindings[name]=nil end},ContentProvider={PreloadAsync=function() end}}
local game={GetService=function(_,name) assert(services[name],"Unexpected service: "..name);return services[name] end}
-- Lune throws userdata for reflection failures; Roblox-style traceback handlers
-- need the string conversion before those errors can be reported meaningfully.
local rawDebug=debug
local debug={traceback=function(err) return rawDebug.traceback(tostring(err)) end}
local script={Parent={WaitForChild=function(_,name) return name end}}
local RigRepair=(function()
__RIG_SOURCE__
end)()
local Presets=(function()
__PRESETS_SOURCE__
end)()
local Stage=(function()
__STAGE_SOURCE__
end)()
local Sets=(function()
__SETS_SOURCE__
end)()
local originalRequire=require
local function require(name)
 if name=="CutsceneStage" then return Stage end
 return originalRequire(name)
end
local Madara=(function()
__MADARA_SOURCE__
end)()
local Timeline=(function()
__BROLY_TIMELINE_SOURCE__
end)()
local Pose=(function()
__BROLY_POSE_SOURCE__
end)()
local realRequire=require
local function require(name)
 if name=="CutsceneStage" then return Stage elseif name=="SignatureSets" then return Sets end
 if name=="SummonPresets" then return Presets elseif name=="MadaraSequence" then return Madara end
 if name=="BrolyTimeline" then return Timeline elseif name=="BrolyPose" then return Pose end
 return realRequire(name)
end
local Scenes=(function()
__CINEMATICS_SOURCE__
end)()
local Broly=(function()
__BROLY_SEQUENCE_SOURCE__
end)()
local place=roblox.deserializePlace(fs.readFile(assert(process.args[1],"Place file required")))
local models=place.ReplicatedStorage.AnimeRift.Assets.CharacterModels
local meteorTemplate
local meshes=place.ReplicatedStorage.AnimeRift.Assets:FindFirstChild("CinematicMeshes")
if meshes then meteorTemplate=meshes:FindFirstChild("MeteorRock") end
if not meteorTemplate then
 for _,candidate in ipairs(place:GetDescendants()) do
  if candidate:IsA("MeshPart") and candidate.Name=="Icosphere" and #candidate:GetDescendants()<=1 then meteorTemplate=candidate;break end
 end
end
assert(meteorTemplate,"Supplied meteor mesh missing")
local gui=RealInstance.new("PlayerGui")
local originalCamera=workspace.CurrentCamera.CFrame
local originalFOV=workspace.CurrentCamera.FieldOfView
local function close(a,b) return (a.Position-b.Position).Magnitude<.001 and a.LookVector:Dot(b.LookVector)>.9999 and a.UpVector:Dot(b.UpVector)>.9999 end
local function meshContent(part)
 local ok,id=pcall(function() return part.MeshId end)
 return ok and id or tostring(part.MeshContent)
end
local function inspectWelds(actor)
 local core={}
 for _,part in ipairs(actor:GetDescendants()) do if part:IsA("BasePart") and (part.Name=="Torso" or part.Name=="Head" or part.Name=="HumanoidRootPart" or part.Name:find(" Arm",1,true) or part.Name:find(" Leg",1,true)) then core[part]=true end end
 local pairs={}
 for _,joint in ipairs(actor:GetDescendants()) do
  if (joint:IsA("WeldConstraint") or joint:IsA("Weld")) and joint.Part0 and joint.Part1 and not (core[joint.Part0] and core[joint.Part1]) then
   table.insert(pairs,{A=joint.Part0,B=joint.Part1,Offset=joint.Part0.CFrame:ToObjectSpace(joint.Part1.CFrame)})
  end
 end
 return pairs
end
local function visiblePartCount(actor,camera,aspect)
 local visible=0
 local tan=math.tan(math.rad(camera.FieldOfView/2))
 for _,part in ipairs(actor:GetDescendants()) do if part:IsA("BasePart") and part.Transparency<.99 then
  local point=camera.CFrame:PointToObjectSpace(part.CFrame.Position)
  if point.Z<-.01 and math.abs(point.X)<-point.Z*tan*aspect and math.abs(point.Y)<-point.Z*tan then visible+=1 end
 end end
 return visible
end
-- Lune 0.11.1 globally reserves CurrentCamera for Workspace, so reading that
-- property on ViewportFrame errors. This thin UI proxy forwards every other
-- operation to the real ViewportFrame and retains the real Roblox Camera.
local function viewportProxy(view,camera)
 return setmetatable({}, {
  __index=function(_,key)
   if key=="CurrentCamera" then return camera end
   local value=view[key]
   if type(value)=="function" then return function(_,...) return value(view,...) end end
   return value
  end,
  __newindex=function(_,key,value)
   if key=="CurrentCamera" then camera=value else view[key]=value end
  end,
 })
end
local checked=0
for _,source in ipairs(models:GetChildren()) do if source:IsA("Model") then
 local now=0;local actor,viewport;local callbacks=0;local reason
 local preset=Presets.Get(source.Name)
 local id=preset and source.Name or "vegeta" -- compatibility test for lower-tier authored rig
 local tier=source.Name=="broly" and 7 or source.Name=="madara" and 6 or 5
 local beforeFrames=frames.Count()
 local context={Parent=gui,Clock=function() return now end,MeteorTemplate=meteorTemplate,
  Portrait=function(parent,_,position,size)
   local realView=Instance.new("ViewportFrame");realView.Position=position;realView.Size=size;realView.Parent=parent
   local camera=Instance.new("Camera");camera.Parent=realView
   viewport=viewportProxy(realView,camera)
   local world=Instance.new("WorldModel");world.Parent=realView
   actor=assert(RigRepair.Prepare(source,{VisualOnly=true}))
   for _,part in ipairs(actor:GetDescendants()) do
    if part:IsA("LuaSourceContainer") or part:IsA("ParticleEmitter") or part:IsA("Trail") or part:IsA("Beam") or part:IsA("Light") or part:IsA("Sound") then part:Destroy()
    elseif part:IsA("BasePart") then part.Anchored=true;part.CanCollide=false end
   end
   actor.Parent=world;actor:PivotTo(CFrame.new())
   return viewport
  end,
  OnComplete=function(value) callbacks+=1;reason=value end,
 }
 local item={Id=id,Name=source.Name,Tier=tier}
 local scene=Scenes.Play(item,context)
 assert(scene and scene:IsPlaying(),"Failed real model setup: "..source.Name.." / "..tostring(reason))
 assert(scene.Metrics.Effects<=Presets.Budget.MaxInstances,"Effect budget exceeded")
 local allocated=made;local pairs=inspectWelds(actor);local descendantCount=#actor:GetDescendants()
 local overlay=assert(gui:FindFirstChild("RiftSummonCutscene"));local effectCount=#overlay:GetDescendants()
 local initialCamera=viewport.CurrentCamera.CFrame
 if source.Name=="madara" then
  local cf,size=actor:GetBoundingBox()
  assert(math.abs(size.Y-6)<.001 and cf.Position.Magnitude<.001,"Madara normalization missed authored geometry")
  assert(math.abs(cf.Position.Y-size.Y/2+3)<.001,"Madara feet must rest at cliff summit height -3")
  local cores=0
  for _,part in ipairs(overlay:GetDescendants()) do if part:IsA("MeshPart") and part.Name:match("^Meteor %d$") then
   cores+=1;assert(meshContent(part)==meshContent(meteorTemplate),"Meteor lost supplied mesh")
  end end
  assert(cores==4,"Expected four supplied meteor mesh cores")
 end
 for _,fraction in ipairs({.1,.25,.43,.56,.7,.88}) do
  now=scene.Metrics.Duration*fraction;frames:Fire()
  assert(scene:IsPlaying(),"Real model scene errored at "..source.Name.." / "..fraction)
  assert(made==allocated,"Per-frame Instance allocation")
  assert(#actor:GetDescendants()==descendantCount,"Authored rig descendants changed during a frame")
  assert(#overlay:GetDescendants()==effectCount,"Effects cloned or allocated during a frame")
  local aspect=source.Name=="madara" and 16/9 or 720/392
  -- Meteors use a deliberate landscape insert; the establishing/dialogue shots
  -- must show the real Madara actor, while generic scenes keep their actor visible.
  if source.Name~="madara" or fraction<.43 then
   assert(visiblePartCount(actor,viewport.CurrentCamera,aspect)>0,"Real actor outside viewport: "..source.Name.." / "..fraction)
  end
  for _,pair in ipairs(pairs) do
   assert(close(pair.A.CFrame:ToObjectSpace(pair.B.CFrame),pair.Offset),"Detached authored costume: "..source.Name.." / "..pair.A.Name.." -> "..pair.B.Name)
  end
 end
 assert(not close(initialCamera,viewport.CurrentCamera.CFrame),"Static local cinematic camera")
 now=scene.Metrics.Duration+.1;frames:Fire()
 assert(not scene:IsPlaying() and callbacks==1 and reason=="Completed" and frames.Count()==beforeFrames,"Real-model completion leaked renderer")
 assert(not gui:FindFirstChild("RiftSummonCutscene"),"Completed overlay retained")
 scene:Cancel();assert(callbacks==1,"Repeated completion callback")
 callbacks=0;now=0;reason=nil
 scene=Scenes.Play(item,context)
 gui.RiftSummonCutscene:FindFirstChildOfClass("CanvasGroup").SkipCutscene.Activated:Fire()
 assert(not scene:IsPlaying() and callbacks==1 and reason=="Skipped" and frames.Count()==beforeFrames,"Real model Skip leaked renderer")
 callbacks=0;now=0;reason=nil
 scene=Scenes.Play(item,context)
 overlay=gui.RiftSummonCutscene;overlay.Destroying:Fire();overlay:Destroy()
 assert(not scene:IsPlaying() and callbacks==1 and reason=="Closed" and frames.Count()==beforeFrames,"Real model external removal leaked renderer")
 assert(workspace.CurrentCamera.CFrame==originalCamera and workspace.CurrentCamera.FieldOfView==originalFOV,"Gameplay camera changed")
 checked+=1;print("PASS real cinematic geometry: "..source.Name.." ("..#pairs.." costume welds, "..scene.Metrics.Effects.." FX)")
end end
assert(checked>=13,"Expected all thirteen authored imported rigs")
print("Real cinematic geometry checks: "..checked.." rigs; projection, costume rigidity, allocation, lifecycle verified")
-- The actual imported Broly also drives Legendary Rage; a separate renderer and
-- pose binder must retain his authored mesh clothing across the full timeline.
do
 local source=assert(models:FindFirstChild("broly"));local actor,view;local now=0;local complete=0
 local scene=Broly.Play({Parent=gui,Clock=function() return now end,SoundId="",OnComplete=function() complete+=1 end,
  Portrait=function(parent,_,position,size)
   local realView=Instance.new("ViewportFrame");realView.Position=position;realView.Size=size;realView.Parent=parent
   local camera=Instance.new("Camera");camera.Parent=realView;view=viewportProxy(realView,camera)
   local world=Instance.new("WorldModel");world.Parent=realView
   actor=assert(RigRepair.Prepare(source,{VisualOnly=true}));actor.Parent=world;actor:PivotTo(CFrame.new())
   return view
  end,
 })
 assert(scene and scene:IsPlaying(),"Actual Broly skill setup failed")
 local cf,sz=actor:GetBoundingBox()
 -- Play already samples the first pose, so small limb/idle rotations may expand
 -- the AABB slightly. The six-stud authored actor must still stand above the floor.
 assert(sz.Y>5.8 and sz.Y<6.35,"Broly skill actor was not normalized to scene scale")
 assert(cf.Position.Y-sz.Y/2>=-3.3,"Broly skill feet buried below the scene floor")
 local pairs=inspectWelds(actor);local allocated=made
 for _,t in ipairs({.5,2.5,3.8,5.5,8.7,10,11.3,12.8,15,17.5,19.5,21,24}) do
  now=t;frames:Fire();assert(scene:IsPlaying(),"Actual Broly skill frame errored")
  assert(made==allocated,"Broly skill allocated Instances during a frame")
  assert(visiblePartCount(actor,view.CurrentCamera,16/9)>0,"Actual Broly skill actor outside shot at "..t)
  for _,pair in ipairs(pairs) do assert(close(pair.A.CFrame:ToObjectSpace(pair.B.CFrame),pair.Offset),"Broly skill detached authored costume: "..pair.A.Name.." -> "..pair.B.Name) end
 end
 now=27;frames:Fire();assert(not scene:IsPlaying() and complete==1 and frames.Count()==0,"Actual Broly skill cleanup failed")
 print("PASS actual Broly Legendary Rage geometry and "..#pairs.." costume welds")
end

-- Exercise the real local-world renderer with the staged particle and sound slots.
-- Camera selection, FX sanitization, cue counts and restoration are behavioral
-- checks, independent of the renderer/projection stand-ins above.
do
 local assets=place.ReplicatedStorage.AnimeRift.Assets:FindFirstChild('Cutscenes')
 assert(assets,'Build the current export before testing editable stage assets')
 local savedCamera=workspace.CurrentCamera;local savedFrame=savedCamera.CFrame;local savedSubject=savedCamera.CameraSubject
 for _,id in ipairs({'gojo','madara','broly'}) do
  for _,ending in ipairs({'Completed','Skipped','Closed'}) do
   local now=0;local actor,viewport;local done=0;local reason
   local ctx={Parent=gui,UseWorldStage=true,SceneAssets=assets[id],Clock=function() return now end,
    CinematicVoiceId='',MeteorTemplate=id=='madara' and assets[id].Meshes.Meteor or nil,
    Portrait=function(parent,_,position,size)
     local view=Instance.new('ViewportFrame');view.Parent=parent;view.Position=position;view.Size=size
     local camera=Instance.new('Camera');camera.Parent=view;camera.ViewportSize=Vector2.new(1920,1080)
     local world=Instance.new('WorldModel');world.Parent=view
     actor=assert(RigRepair.Prepare(models[id],{VisualOnly=true}))
     for _,v in ipairs(actor:GetDescendants()) do
      if v:IsA('LuaSourceContainer') or v:IsA('ParticleEmitter') or v:IsA('Beam') or v:IsA('Trail') or v:IsA('Sound') then v:Destroy()
      elseif v:IsA('BasePart') then v.Anchored=true end
     end
     actor.Parent=world;actor:PivotTo(CFrame.new());viewport=viewportProxy(view,camera);return viewport
    end,
    OnComplete=function(value) done+=1;reason=value end}
   local scene=Scenes.Play({Id=id,Name=id,Tier=id=='broly' and 7 or 6},ctx)
   assert(scene and scene:IsPlaying(),'world scene did not start: '..id)
   local stage=workspace:FindFirstChild('LocalSummonStage');assert(stage,'missing real world stage')
   assert(workspace.CurrentCamera==savedCamera and savedCamera.CameraType==Enum.CameraType.Scriptable,'gameplay camera identity changed')
   assert(actionBindings.RiftSummonStage and actionBindings.RiftSummonSkip,'movement/skip actions missing')
   assert(select(1,actor:GetBoundingBox()).Position.Magnitude<1000,'pose model left private local coordinates')
   local rendered=stage:FindFirstChild(actor.Name);assert(rendered and select(1,rendered:GetBoundingBox()).Position.Magnitude>1000,'render clone not isolated from gameplay')
   assert(not stage:FindFirstChildOfClass('Camera'),'stage owns a replacement camera')
   local before=made;local count=#stage:GetDescendants()
   now=scene.Metrics.Duration*.7;frames:Fire()
   assert(made==before and #stage:GetDescendants()==count,'world stage allocates per frame')
   local fired,totalEmitters=0,0
   for _,v in stage:GetDescendants() do
    assert(not v:IsA('LuaSourceContainer'),'imported FX script survived sanitization')
    if v:IsA('ParticleEmitter') then
     totalEmitters+=1;assert(v.Enabled==false and v.Rate==0,'unbounded continuous particles')
     assert(particlesEmitted[v] and particlesEmitted[v]>0 and particlesEmitted[v]<=40,'particle cue missing or excessive')
    end
   end
   for _,v in soundService:GetChildren() do if v.Name:sub(1,8)=='Cutscene' then assert(soundsPlayed[v]==1,'SFX cue did not play once');fired+=1 end end
   assert(totalEmitters==3 and fired==3,'missing staged particle/sound slots')
   if ending=='Completed' then now=scene.Metrics.Duration+.1;frames:Fire()
   elseif ending=='Skipped' then actionBindings.RiftSummonSkip('',Enum.UserInputState.Begin)
   else event(gui:FindFirstChild('RiftSummonCutscene'),'Destroying'):Fire() end
   assert(done==1 and reason==ending and not scene:IsPlaying(),'world scene failed to finish once')
   assert(workspace.CurrentCamera==savedCamera and close(savedCamera.CFrame,savedFrame) and savedCamera.CameraSubject==savedSubject,'gameplay camera not restored: camera='..tostring(workspace.CurrentCamera==savedCamera)..' frame='..tostring(savedCamera.CFrame==savedFrame)..' subject='..tostring(savedCamera.CameraSubject==savedSubject)..' old='..tostring(savedFrame)..' new='..tostring(savedCamera.CFrame)..' parent='..tostring(savedCamera.Parent))
   assert(not workspace:FindFirstChild('LocalSummonStage') and not actionBindings.RiftSummonStage and not actionBindings.RiftSummonSkip,'world stage/control leak')
   for _,v in soundService:GetChildren() do assert(v.Name:sub(1,8)~='Cutscene','scene SFX leaked') end
   -- Lune Destroying signals are manually supplied; remove the externally closed GUI.
   local old=gui:FindFirstChild('RiftSummonCutscene');if old then old:Destroy() end
   print('PASS local world scene: '..id..' / '..ending..' / pack particles, SFX, camera, controls, cleanup')
  end
 end
end

-- User-swapped FX are sanitized and bounded; reduced effects lowers the burst.
do
 local assets=RealInstance.new('Folder');assets.Name='CustomTestAssets'
 local fx=RealInstance.new('Part');fx.Name='OpeningFX';fx.CFrame=CFrame.new();fx.Parent=assets
 local injected=RealInstance.new('Script');injected.Name='UntrustedSample';injected.Source='error("must never execute")';injected.Parent=fx
 for i=1,30 do local emitter=RealInstance.new('ParticleEmitter');emitter.Name='Particle'..i;emitter.Lifetime=NumberRange.new(10,20);emitter.LightEmission=1;emitter.Enabled=true;emitter.Rate=500;emitter:SetAttribute('EmitCount',999);emitter.Parent=fx end
 for _,reduced in ipairs({false,true}) do
  local view=RealInstance.new('ViewportFrame');local world=RealInstance.new('WorldModel');world.Parent=view
  local body=RealInstance.new('Part');body.CFrame=CFrame.new();body.Parent=world
  local camera=RealInstance.new('Camera');camera.CFrame=CFrame.new();camera.Parent=view
  local projection=viewportProxy(view,camera)
  local controller=Stage.Attach(projection,{UseWorldStage=true,SceneAssets=assets,ReducedEffects=reduced},1)
  controller:After(.5)
  local live=workspace:FindFirstChild('LocalSummonStage');local count,total=0,0
  for _,v in live:GetDescendants() do
   assert(not v:IsA('LuaSourceContainer'),'custom FX script reached Workspace')
   if v:IsA('ParticleEmitter') then count+=1;total+=particlesEmitted[v] or 0;assert(v.Lifetime.Max<=2 and not v.Enabled and v.Rate==0,'unbounded imported emitter') end
  end
  assert(count==12 and total<=(reduced and 48 or 120),'custom FX exceeded burst budget')
  controller:Destroy();controller:Destroy();assert(not workspace:FindFirstChild('LocalSummonStage'),'custom set leaked')
  view:Destroy()
  print('PASS custom VFX sanitization and burst/lifetime limits: reduced='..tostring(reduced))
 end
 assets:Destroy()
end

-- Regression: Before/pose evaluation must never teleport live geometry or the
-- camera through the map. Source models stay private and render clones commit once.
do
 local view=RealInstance.new('ViewportFrame');local world=RealInstance.new('WorldModel');world.Parent=view
 local actor=RealInstance.new('Model');actor.Name='FlickerRegression';actor.Parent=world
 local source=RealInstance.new('Part');source.Name='TrackedPart';source.CFrame=CFrame.new(1,2,3);source.Size=Vector3.one;source.Parent=actor
 local localCamera=RealInstance.new('Camera');localCamera.CFrame=CFrame.new(0,2,-8);localCamera.FieldOfView=45;localCamera.Parent=view
 local gameplay=workspace.CurrentCamera;local savedFrame=gameplay.CFrame;local savedFocus=gameplay.Focus
 local scene=Stage.Attach(viewportProxy(view,localCamera),{UseWorldStage=true},1)
 scene:After(0)
 local live=workspace.LocalSummonStage.FlickerRegression.TrackedPart
 local previous=live.CFrame;local originalLiveFrame=gameplay.CFrame
 for i=1,60 do
  scene:Before()
  assert(close(live.CFrame,previous),'live part moved during Before')
  assert(close(gameplay.CFrame,originalLiveFrame),'camera moved during Before')
  source.CFrame=CFrame.new(1,i*.01,3)
  localCamera.CFrame=CFrame.new(0,2+i*.01,-8)
  assert(close(live.CFrame,previous),'private pose calculation changed a live part')
  assert(close(gameplay.CFrame,originalLiveFrame),'private camera update changed gameplay camera')
  scene:After(i/100)
  assert(workspace.CurrentCamera==gameplay,'camera object swapped during a shot')
  assert(live.CFrame.Position.Magnitude>1000 and gameplay.CFrame.Position.Magnitude>1000,'visible stage/camera visited gameplay origin')
  assert(source.CFrame.Position.Magnitude<10,'source coordinates accumulate offsets')
  previous=live.CFrame;originalLiveFrame=gameplay.CFrame
 end
 scene:Destroy()
 assert(close(gameplay.CFrame,savedFrame) and close(gameplay.Focus,savedFocus),'camera frame/focus not restored')
 view:Destroy()
 print('PASS flicker regression: 60 updates, private poses, stable live parts, one camera, restored frame/focus')
end

-- A camera selected by another system must not be overwritten by a stale shot.
do
 local view=RealInstance.new('ViewportFrame');local world=RealInstance.new('WorldModel');world.Parent=view
 local part=RealInstance.new('Part');part.CFrame=CFrame.new();part.Parent=world
 local shotCamera=RealInstance.new('Camera');shotCamera.CFrame=CFrame.new();shotCamera.Parent=view
 local original=workspace.CurrentCamera
 local stage=Stage.Attach(viewportProxy(view,shotCamera),{UseWorldStage=true},1)
 local foreign=RealInstance.new('Camera');foreign.Parent=workspace;foreign.CFrame=CFrame.new(3,4,5)
 workspace.CurrentCamera=foreign;stage:After(.5)
 assert(workspace.CurrentCamera==foreign and not workspace:FindFirstChild('LocalSummonStage'),'stale stage fought another camera owner')
 workspace.CurrentCamera=original;foreign:Destroy();view:Destroy()
 print('PASS camera ownership loss cancels stage without replacing the new camera')
end
