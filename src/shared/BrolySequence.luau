-- Reconstructed Legendary Rage presentation; viewport-only, one actor and fixed FX pools.
local B={}
local Run=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local Actions=game:GetService("ContextActionService")
local Timeline=require(script.Parent:WaitForChild("BrolyTimeline"))
local Pose=require(script.Parent:WaitForChild("BrolyPose"))
B.Budget={MaxFX=96,FPS=30,ReducedFPS=24}
local active
local warmed={}
function B.Preload(soundId)
 if not soundId or soundId=="" or warmed[soundId] then return end
 warmed[soundId]=true
 task.spawn(function()
  local ok=pcall(function() game:GetService("ContentProvider"):PreloadAsync({soundId}) end)
  if not ok then warn("Broly skill audio preload failed; verify experience audio permissions in Studio.") end
 end)
end
function B.Play(ctx)
 if active then active:Cancel("Replaced") end
 local clock=ctx.Clock or os.clock;local start=clock();local done=false
 local connections={};local ui;local audio;local count=0
 local controls,disabledControls
 local reduced=Input.TouchEnabled==true or ctx.ReducedEffects==true
 local controller={Metrics={FX=0,FPS=reduced and 24 or 30,Duration=Timeline.Duration}}
 local function make(class,parent)
  assert(count<B.Budget.MaxFX,"Broly FX budget exceeded")
  local item=Instance.new(class);item.Parent=parent;count+=1;controller.Metrics.FX=count;return item
 end
 local function finish(reason,destroying)
  if done then return end;done=true
  for _,connection in ipairs(connections) do connection:Disconnect() end
  if audio then audio:Destroy() end
  Actions:UnbindAction("RiftBrolySequence")
  if disabledControls and controls then controls:Enable();disabledControls=false end
  if ui and not destroying then ui:Destroy() end
  if active==controller then active=nil end
  if ctx.OnComplete then local ok,err=pcall(ctx.OnComplete,reason);if not ok then warn(tostring(err)) end end
 end
 function controller:Cancel(reason) finish(reason or "Skipped") end
 function controller:IsPlaying() return not done end
 active=controller
 local ok,err=xpcall(function()
  ui=make("ScreenGui",ctx.Parent);ui.Name="BrolyRageSequence";ui.IgnoreGuiInset=true;ui.ResetOnSpawn=false;ui.DisplayOrder=80
  local root=make("CanvasGroup",ui);root.Size=UDim2.fromScale(1,1);root.BackgroundColor3=Color3.new(1,1,1);root.BackgroundTransparency=1;root.Active=true
  local bg=make("Frame",root);bg.Size=UDim2.fromScale(1,1);bg.BackgroundColor3=Color3.fromRGB(43,92,67);bg.BorderSizePixel=0
  local gradient=make("UIGradient",bg);gradient.Color=ColorSequence.new(Color3.fromRGB(38,73,72),Color3.fromRGB(80,132,90));gradient.Rotation=90
  local view=ctx.Portrait(root,"broly",UDim2.new(),UDim2.fromScale(1,1),"Skill")
  assert(view and view.CurrentCamera,"Missing Broly preview")
  view.ZIndex=2;view.LightColor=Color3.new(1,1,1);view.Ambient=Color3.fromRGB(218,231,221);view.LightDirection=Vector3.new(-1,-1,-1)
  local world=view:FindFirstChildOfClass("WorldModel");local actor=world and world:FindFirstChildOfClass("Model");assert(actor,"Missing Broly actor")
  local pose=Pose.Bind(actor)
  local fx=make("Model",world);fx.Name="LegendaryRageFX"
  local green=Color3.fromRGB(104,255,49);local yellow=Color3.fromRGB(235,255,119)
  local function part(name,size,tint,material)
   local p=make("Part",fx);p.Name=name;p.Size=size;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Color=tint;p.Material=material or Enum.Material.Neon;p.Transparency=1;return p
  end
  local ground=part("Rage stage",Vector3.new(65,.4,65),Color3.fromRGB(82,97,91),Enum.Material.Slate);ground.CFrame=CFrame.new(0,-3.3,0);ground.Transparency=0
  local moon=part("Orbit moon",Vector3.new(20,20,2),Color3.fromRGB(232,255,245));moon.Shape=Enum.PartType.Ball
  local bubble=part("Energy sphere",Vector3.one,green);bubble.Shape=Enum.PartType.Ball
  local pillars,rocks,bolts,rings,sparks={},{},{},{},{}
  for i=1,(reduced and 4 or 7) do table.insert(pillars,part("Green energy pillar",Vector3.one,i%2==0 and yellow or green)) end
  for i=1,(reduced and 5 or 10) do table.insert(rocks,part("Floating debris",Vector3.one,Color3.fromRGB(52,66,55),Enum.Material.Slate)) end
  for i=1,(reduced and 4 or 8) do table.insert(bolts,part("Rage lightning",Vector3.new(.08,3,.08),yellow)) end
  for ring=1,(reduced and 1 or 2) do
   local segments={}
   for i=1,12 do table.insert(segments,part("Cyclone ring",Vector3.one,ring==1 and green or yellow)) end
   table.insert(rings,segments)
  end
  for i=1,(reduced and 8 or 14) do table.insert(sparks,part("Aura spark",Vector3.new(.12,.12,.12),Color3.fromRGB(217,255,206))) end
  local function text(value,size,y)
   local label=make("TextLabel",root);label.Position=UDim2.new(0,15,0,y);label.Size=UDim2.new(1,-30,0,35);label.BackgroundTransparency=1;label.Font=Enum.Font.FredokaOne;label.TextSize=size;label.TextColor3=Color3.new(1,1,1);label.TextStrokeTransparency=.1;label.Text=value;label.ZIndex=5;return label
  end
  text("LEGENDARY RAGE",25,18)
  local phase=text("",17,56)
  local skip=make("TextButton",root);skip.Name="SkipBrolySkill";skip.AnchorPoint=Vector2.new(1,1);skip.Position=UDim2.new(1,-20,1,-18);skip.Size=UDim2.fromOffset(230,42);skip.BackgroundColor3=Color3.fromRGB(26,45,36);skip.TextColor3=Color3.new(1,1,1);skip.Font=Enum.Font.GothamBold;skip.TextSize=14;skip.Text="SKIP VISUALS [SPACE/B]";skip.Modal=true;skip.Selectable=true;skip.ZIndex=6
  local hint=text(ctx.Preview and "PREVIEW ONLY • NO BOOST" or "Power charges on the server even if visuals are skipped",15,94)
  Actions:BindActionAtPriority("RiftBrolySequence",function() return Enum.ContextActionResult.Sink end,false,3000,Enum.PlayerActions.CharacterForward,Enum.PlayerActions.CharacterBackward,Enum.PlayerActions.CharacterLeft,Enum.PlayerActions.CharacterRight,Enum.PlayerActions.CharacterJump)
  if ctx.Player then task.spawn(function()
   local got,result=pcall(function()
    local scripts=ctx.Player:WaitForChild("PlayerScripts",10);local module=scripts and scripts:WaitForChild("PlayerModule",10)
    return module and require(module):GetControls()
   end)
   if got and result and not done then controls=result;controls:Disable();disabledControls=true end
  end) end
  local soundId=ctx.SoundId or ""
  if soundId~="" then
   audio=Instance.new("Sound");audio.Name="BrolyLegendaryRageAudio";audio.PlayOnRemove=false;audio.SoundId=soundId;audio.Volume=.55;audio.Looped=false;audio.Parent=game:GetService("SoundService");audio:Play()
  end
  table.insert(connections,skip.Activated:Connect(function() finish("Skipped") end))
  table.insert(connections,Input.InputBegan:Connect(function(input,processed) if not processed and (input.KeyCode==Enum.KeyCode.Space or input.KeyCode==Enum.KeyCode.ButtonB) then finish("Skipped") end end))
  table.insert(connections,ui.Destroying:Connect(function() finish("Closed",true) end))
  local humanoid=ctx.Character and ctx.Character:FindFirstChildOfClass("Humanoid")
  if humanoid then table.insert(connections,humanoid.Died:Connect(function() finish("Died") end)) end
  local last=-math.huge
  local function update(now)
   local t=math.max(0,now-start)
   if t>=Timeline.Duration then finish("Completed");return end
   local s=Timeline.Sample(t);pose(s)
   phase.Text=s.Phase;hint.Text=ctx.Preview and "PREVIEW ONLY • NO BOOST" or string.format("POWER CHARGING • %ds",math.ceil(Timeline.Duration-t))
   local camera=s.Camera
   view.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(camera.X,camera.Y+s.RootY*.5,camera.Z),Vector3.new(camera.TX,camera.TY+s.RootY*.5,camera.TZ));view.CurrentCamera.FieldOfView=camera.FOV
   local energy=s.Energy
   ground.Transparency=s.Moon*.98
   local dx,dy,dz=camera.TX-camera.X,camera.TY-camera.Y,camera.TZ-camera.Z
   local length=math.max(.1,math.sqrt(dx*dx+dy*dy+dz*dz))
   moon.CFrame=CFrame.lookAt(Vector3.new(camera.TX+dx/length*9,camera.TY+s.RootY*.5+dy/length*9,camera.TZ+dz/length*9),Vector3.new(camera.X,camera.Y+s.RootY*.5,camera.Z));moon.Transparency=1-s.Moon*.9
   local sphereSize=5+energy*14
   bubble.Size=Vector3.new(sphereSize,sphereSize,sphereSize);bubble.CFrame=CFrame.new(0,s.RootY,0);bubble.Transparency=.98-energy*.12
   for i,p in ipairs(pillars) do
    local angle=i/#pillars*math.pi*2+t*.28
    local radius=1.9+i%3*.7;local height=5+s.Pillar*(17+i%3*4)
    p.Size=Vector3.new(.3+i%3*.3,height,.3+i%2*.4);p.CFrame=CFrame.new(math.cos(angle)*radius,height/2-3,math.sin(angle)*radius)*CFrame.Angles(0,angle,math.sin(t+i)*.08)
    p.Transparency=1-s.Pillar*(.22+i%2*.16)
   end
   for i,p in ipairs(rocks) do
    local angle=i/#rocks*math.pi*2+t*(.2+i%3*.09)
    local radius=3.5+i%3*1.4;local size=.4+i%3*.3
    p.Size=Vector3.new(size,size*.8,size);p.CFrame=CFrame.new(math.cos(angle)*radius,-2.6+energy*(2+i%4)+math.sin(t+i)*.2,math.sin(angle)*radius)*CFrame.Angles(t*.3+i,t*.2,i)
    p.Transparency=1-energy*.95
   end
   for i,p in ipairs(bolts) do
    local angle=i/#bolts*math.pi*2+math.floor(t*8)*.34
    p.CFrame=CFrame.new(math.cos(angle)*2,s.RootY+math.sin(t*4+i)*2,math.sin(angle)*2)*CFrame.Angles(.3*math.sin(t*9+i),0,math.sin(t*7+i)*.7)
    p.Transparency=1-energy*.8
   end
   for index,segments in ipairs(rings) do
    local radius=2.6+index*1.1+energy*.8
    for i,p in ipairs(segments) do
     local angle=(i-.5)/#segments*math.pi*2+s.Orbit*.8+index*.5
     p.Size=Vector3.new(.08,.08,2*radius*math.sin(math.pi/#segments)*1.05)
     p.CFrame=CFrame.new(math.cos(angle)*radius,s.RootY-1+index*1.2+math.sin(angle+t)*.25,math.sin(angle)*radius)*CFrame.Angles(0,-angle,0)
     p.Transparency=1-energy*.75
    end
   end
   for i,p in ipairs(sparks) do
    local angle=i*2.399+t*.3;local cycle=(t*.23+i/#sparks)%1;local radius=2+cycle*5
    p.CFrame=CFrame.new(math.cos(angle)*radius,cycle*11-3,math.sin(angle)*radius);p.Transparency=1-energy*(1-math.abs(cycle-.5))* .8
   end
   root.GroupTransparency=math.max(1-math.min(1,t/.22),math.max(0,(t-25.5)/.5))
  end
  table.insert(connections,Run.RenderStepped:Connect(function()
   if done then return end
   local now=clock();if now-last<1/controller.Metrics.FPS then return end;last=now
   local frameOK,frameError=pcall(update,now);if not frameOK then warn("Broly sequence: "..tostring(frameError));finish("Error") end
  end))
  update(start)
 end,debug.traceback)
 if not ok then warn("Broly sequence setup: "..tostring(err));finish("Error") end
 return controller
end
return B
