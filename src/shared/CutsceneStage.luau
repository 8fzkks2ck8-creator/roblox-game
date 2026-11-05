-- Local world stages render the supplied particle pack. Clones are sanitized and
-- bounded before entering Workspace; the camera and controls are always restored.
local S={Budget={MaxTemplateDescendants=48,MaxFXInstances=160,MaxEmitters=12,MaxBurst=40}}
local Run=game:GetService("RunService")
local Actions=game:GetService("ContextActionService")
local Input=game:GetService("UserInputService")
local function descendants(root)
 local all={root};for _,v in ipairs(root:GetDescendants()) do table.insert(all,v) end;return all
end
local function cue(template,fallback)
 local value=template:GetAttribute("CueProgress")
 if type(value)=="number" and value==value then return math.clamp(value,0,1) end
 return fallback
end
function S.Attach(view,ctx,duration)
 local c={Enabled=ctx.UseWorldStage==true,FXInstances=0,Emitters=0}
 local reduced=ctx.ReducedEffects==true or Input.TouchEnabled==true
 local container,camera,original,saved,controls
 local renderParts={}
 local fx={} -- pools are created once, never while a shot updates
 local sounds={};local done=false
 local offset=CFrame.new(12000,6000,12000)
 local function safeClone(template,parent)
  if #template:GetDescendants()>S.Budget.MaxTemplateDescendants then warn("Cutscene template too large: "..template.Name);return nil end
  local clone=template:Clone()
  local list=descendants(clone)
  for i=#list,1,-1 do
   local v=list[i]
   if v:IsA("LuaSourceContainer") or v:IsA("Humanoid") or v:IsA("Animator") or v:IsA("JointInstance") or v:IsA("Constraint") or v:IsA("BodyMover") or v:IsA("LayerCollector") then
    if v==clone then clone:Destroy();return nil else v:Destroy() end
   end
  end
  local total=1+#clone:GetDescendants()
  if c.FXInstances+total>S.Budget.MaxFXInstances then clone:Destroy();warn("Cutscene custom FX budget exceeded");return nil end
  for _,v in ipairs(descendants(clone)) do
   if v:IsA("BasePart") then v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false
   elseif v:IsA("ParticleEmitter") then
    if c.Emitters>=S.Budget.MaxEmitters then v:Destroy() else
     c.Emitters+=1;v.Enabled=false;v.Rate=0;v.Lifetime=NumberRange.new(math.min(v.Lifetime.Min,2),math.min(v.Lifetime.Max,2));v.LightEmission=math.min(v.LightEmission,.7)
     -- Toolbox presets are often authored for huge arenas. Bound brightness,
     -- travel and size for a six-stud actor rather than washing out the camera.
     pcall(function() v.Brightness=math.min(v.Brightness,1.5) end)
     pcall(function() v.Speed=NumberRange.new(math.clamp(v.Speed.Min,0,35),math.clamp(v.Speed.Max,0,35)) end)
     pcall(function()
      local keys={}
      for _,key in ipairs(v.Size.Keypoints) do table.insert(keys,NumberSequenceKeypoint.new(key.Time,math.clamp(key.Value,0,3),math.clamp(key.Envelope,0,1))) end
      v.Size=NumberSequence.new(keys)
     end)
    end
   elseif v:IsA("Sound") then v:Destroy() end
  end
  c.FXInstances+=total;clone.Parent=parent;return clone
 end
 function c:Destroy()
  if done then return end;done=true
  for _,entry in ipairs(sounds) do entry.Object:Destroy() end
  if self.Enabled then
   Actions:UnbindAction("RiftSummonStage")
   Actions:UnbindAction("RiftSummonSkip")
   if controls then controls:Enable();controls=nil end
   if original and original.Parent then
    original.CFrame=saved.CFrame;original.Focus=saved.Focus;original.FieldOfView=saved.FOV;original.CameraType=saved.Type;original.CameraSubject=saved.Subject
   end
   if container then container:Destroy() end
  end
 end
 local function initialize()
 if c.Enabled then
  original=workspace.CurrentCamera
  assert(original,"No gameplay camera")
  saved={CFrame=original.CFrame,Focus=original.Focus,FOV=original.FieldOfView,Type=original.CameraType,Subject=original.CameraSubject}
  container=Instance.new("Model");container.Name="LocalSummonStage" -- client-only, no replication or gameplay physics
  local world=view:FindFirstChildOfClass("WorldModel");assert(world,"Missing character stage")
  -- Keep pose calculations in the hidden WorldModel near the origin. Only
  -- finalized transforms are copied to anchored render clones in Workspace.
  -- Never shuttle live parts/cameras through the origin between shot updates.
  for _,child in ipairs(world:GetChildren()) do
   local sourceNodes=descendants(child);local previousKeys={}
   for i,source in ipairs(sourceNodes) do if source:IsA("BasePart") then
    previousKeys[i]=source:GetAttribute("__RiftRenderBinding");source:SetAttribute("__RiftRenderBinding",i)
   end end
   local clone=child:Clone()
   local cloneNodes=descendants(clone)
   assert(#sourceNodes==#cloneNodes,"Cinematic render clone changed hierarchy")
   for _,target in ipairs(cloneNodes) do
    if target:IsA("BasePart") then
     local key=target:GetAttribute("__RiftRenderBinding");local source=sourceNodes[key]
     assert(source and source:IsA("BasePart"),"Missing render part binding")
     target:SetAttribute("__RiftRenderBinding",previousKeys[key])
     target.Anchored=true;target.CanCollide=false;target.CanTouch=false;target.CanQuery=false
     target.CFrame=offset*source.CFrame
     table.insert(renderParts,{Source=source,Target=target})
    end
   end
   for i,source in ipairs(sourceNodes) do if source:IsA("BasePart") then source:SetAttribute("__RiftRenderBinding",previousKeys[i]) end end
   for _,v in ipairs(cloneNodes) do
    if v:IsA("LuaSourceContainer") or v:IsA("Animator") then v:Destroy()
    elseif v:IsA("JointInstance") or v:IsA("WeldConstraint") or v:IsA("Constraint") then pcall(function() v.Enabled=false end)
    elseif v:IsA("Humanoid") then
     v.RequiresNeck=false;v.BreakJointsOnDeath=false;v.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
     pcall(function() v.EvaluateStateMachine=false end)
    end
   end
   clone.Parent=container
  end
  camera=view.CurrentCamera;view.Visible=false
  -- Reuse the gameplay camera instead of selecting/destroying camera objects.
  -- The private ViewportFrame camera is just the shot's local-coordinate input.
  original.CameraType=Enum.CameraType.Scriptable
  Actions:BindActionAtPriority("RiftSummonStage",function() return Enum.ContextActionResult.Sink end,false,3100,Enum.PlayerActions.CharacterForward,Enum.PlayerActions.CharacterBackward,Enum.PlayerActions.CharacterLeft,Enum.PlayerActions.CharacterRight,Enum.PlayerActions.CharacterJump)
  Actions:BindActionAtPriority("RiftSummonSkip",function(_,state)
   if state==Enum.UserInputState.Begin and ctx.OnSkip then ctx.OnSkip() end
   return Enum.ContextActionResult.Sink
  end,false,3200,Enum.KeyCode.Space,Enum.KeyCode.ButtonB)
  if ctx.Player then task.spawn(function()
   local ok,result=pcall(function()
    local scripts=ctx.Player:WaitForChild("PlayerScripts",10)
    local module=scripts and scripts:WaitForChild("PlayerModule",10)
    return module and require(module):GetControls()
   end)
   if ok and result and not done then controls=result;controls:Disable() end
  end) end
  -- These two low-intensity lights preserve mesh readability in a distant local set.
  local anchor=Instance.new("Part");anchor.Name="StageKeyLight";anchor.Transparency=1;anchor.Size=Vector3.one;anchor.Anchored=true;anchor.CanCollide=false;anchor.CanQuery=false;anchor.CanTouch=false;anchor.CFrame=offset*CFrame.new(2,7,-7);anchor.Parent=container
  local light=Instance.new("PointLight");light.Parent=anchor;light.Brightness=1.2;light.Range=48;light.Color=Color3.new(1,1,1);light.Shadows=false
 end
 local sceneAssets=ctx.SceneAssets
 if sceneAssets and c.Enabled then
  local parent=container
  for _,spec in ipairs({{"OpeningFX",.08},{"ChargeFX",.28},{"ImpactFX",.55}}) do
   local template=sceneAssets:FindFirstChild(spec[1])
   if template then
    local anchor=Instance.new("Part");anchor.Name=spec[1].."Anchor";anchor.Size=Vector3.one;anchor.Transparency=1;anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.CFrame=offset*CFrame.new(0,spec[1]=="ImpactFX" and -1 or 0,0);anchor.Parent=parent
    local clone=safeClone(template,anchor)
    if clone then
     if clone:IsA("Model") then clone:PivotTo(anchor.CFrame)
     elseif clone:IsA("BasePart") then
      local delta=anchor.CFrame*clone.CFrame:Inverse()
      for _,v in ipairs(descendants(clone)) do if v:IsA("BasePart") then v.CFrame=delta*v.CFrame end end
     end
     table.insert(fx,{Object=clone,At=cue(template,spec[2]),Fired=false})
    else anchor:Destroy() end
   end
  end
 end
 -- Sounds are separate from emitter templates so swapping a VFX cannot start
 -- embedded looping audio. Slots may contain a blank SoundId to remain silent.
 if sceneAssets then
  for _,spec in ipairs({{"OpeningSFX",.04},{"ChargeSFX",.28},{"ImpactSFX",.55}}) do
   local template=sceneAssets:FindFirstChild(spec[1])
   if template and template:IsA("Sound") then
    local audio=template:Clone();audio.Name="Cutscene"..spec[1];audio.Looped=false;audio.PlayOnRemove=false;audio.Volume=math.clamp(audio.Volume,0,.8)*(ctx.SoundVolume or .35);audio.Parent=game:GetService("SoundService")
    table.insert(sounds,{Object=audio,At=cue(template,spec[2]),Fired=false})
   end
  end
 end
 if container then container.Parent=workspace end
 end
 local ok,err=xpcall(initialize,debug.traceback)
 if not ok then c:Destroy();error(err) end
 function c:Before()
  -- Compatibility hook: source poses never leave their private WorldModel.
 end
 function c:After(progress)
  if done then return end
  if self.Enabled then
   if workspace.CurrentCamera~=original or not original.Parent then
    self:Destroy()
    if ctx.OnSkip then ctx.OnSkip() end
    return
   end
   for _,entry in ipairs(renderParts) do
    local source,target=entry.Source,entry.Target
    target.CFrame=offset*source.CFrame
    if target.Size~=source.Size then target.Size=source.Size end
    if target.Transparency~=source.Transparency then target.Transparency=source.Transparency end
    if target.Color~=source.Color then target.Color=source.Color end
    if target.Material~=source.Material then target.Material=source.Material end
    if source:IsA("Part") and target.Shape~=source.Shape then target.Shape=source.Shape end
   end
   original.CFrame=offset*camera.CFrame;original.FieldOfView=camera.FieldOfView
   original.Focus=original.CFrame*CFrame.new(0,0,-10)
  end
  for _,entry in ipairs(fx) do if not entry.Fired and progress>=entry.At then
   entry.Fired=true
   local remaining=reduced and 48 or 120
   for _,v in ipairs(descendants(entry.Object)) do if v:IsA("ParticleEmitter") then
    local count=v:GetAttribute("EmitCount")
    if type(count)~="number" or count~=count then count=24 end
    count=math.floor(math.min(remaining,math.clamp(count,0,reduced and 10 or S.Budget.MaxBurst)))
    v:Emit(count);remaining-=count
   end end
  end end
  for _,entry in ipairs(sounds) do if not entry.Fired and progress>=entry.At then entry.Fired=true;entry.Object:Play() end end
 end

 return c
end
return S
