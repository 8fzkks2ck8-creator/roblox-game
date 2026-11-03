-- A single local viewport + a small reusable pool of GUI effects. No world-camera,
-- physics, remote requests, downloaded assets, or per-frame Instance allocation.
local Scenes={}
local Presets=require(script.Parent:WaitForChild("SummonPresets"))
local Run=game:GetService("RunService")
local Input=game:GetService("UserInputService")
Scenes.Budget=Presets.Budget
local active
local function color(rgb) return Color3.fromRGB(rgb[1],rgb[2],rgb[3]) end
local function ease(x) return 1-(1-math.clamp(x,0,1))^3 end
function Scenes.Play(item,ctx)
 local preset=Presets.Get(item.Id)
 if not preset or item.Tier<5 then return nil end
 if active then active:Cancel("Replaced") end
 local clock=ctx.Clock or os.clock
 local started=clock()
 local duration=Presets.Duration(item.Tier)
 local reduced=ctx.ReducedEffects==true or Input.TouchEnabled==true
 local count=math.min(preset.Count,reduced and 10 or Presets.Budget.MaxParticles)
 local fps=reduced and 24 or Presets.Budget.FPS
 local connections={}
 local finished=false
 local impacted=false
 local ui,actor,view,base
 local made=0
 local controller={Metrics={Effects=0,Particles=count,FPS=fps,Duration=duration}}
 local function make(class,parent)
  assert(made<Presets.Budget.MaxInstances,"Summon effect budget exceeded")
  local value=Instance.new(class);value.Parent=parent;made+=1;controller.Metrics.Effects=made;return value
 end
 local function finish(reason,alreadyDestroying)
  if finished then return end;finished=true
  for _,connection in ipairs(connections) do connection:Disconnect() end;table.clear(connections)
  if active==controller then active=nil end
  if ui and not alreadyDestroying then ui:Destroy() end
  if ctx.OnComplete then
   local ok,err=pcall(ctx.OnComplete,reason);if not ok then warn("Summon reveal callback: "..tostring(err)) end
  end
 end
 function controller:Cancel(reason) finish(reason or "Skipped") end
 function controller:IsPlaying() return not finished end
 active=controller
 local ok,err=xpcall(function()
  local primary,accent=color(preset.Color),color(preset.Accent)
  ui=make("ScreenGui",ctx.Parent);ui.Name="RiftSummonCutscene";ui.DisplayOrder=70;ui.IgnoreGuiInset=true;ui.ResetOnSpawn=false;ui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
  local root=make("CanvasGroup",ui);root.Size=UDim2.fromScale(1,1);root.BackgroundColor3=primary:Lerp(Color3.new(0,0,0),.91);root.Active=true;root.GroupTransparency=0
  local gradient=make("UIGradient",root);gradient.Rotation=30+preset.Seed%120;gradient.Color=ColorSequence.new(primary:Lerp(Color3.new(0,0,0),.84),accent:Lerp(Color3.new(0,0,0),.95))
  local stage=make("Frame",root);stage.Name="CinematicStage";stage.Size=UDim2.fromOffset(720,620);stage.AnchorPoint=Vector2.new(.5,.5);stage.Position=UDim2.fromScale(.5,.5);stage.BackgroundTransparency=1
  local fit=make("UIScale",stage)
  local function resize()
   local camera=workspace.CurrentCamera;if not camera then return end
   fit.Scale=math.max(.01,math.min((camera.ViewportSize.X-24)/720,(camera.ViewportSize.Y-40)/620,1.45))
  end
  local viewportConnection
  local function connectCamera()
   if viewportConnection then viewportConnection:Disconnect() end
   local camera=workspace.CurrentCamera
   if camera then viewportConnection=camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize);table.insert(connections,viewportConnection) end
   resize()
  end
  local function frame(parent,w,h,x,y,tint,z)
   local f=make("Frame",parent);f.Size=UDim2.fromOffset(w,h);f.Position=UDim2.fromOffset(x,y);f.BackgroundColor3=tint;f.BorderSizePixel=0;f.ZIndex=z or 1;return f
  end
  local function label(value,y,size,tint)
   local l=make("TextLabel",stage);l.Size=UDim2.fromOffset(700,54);l.Position=UDim2.fromOffset(10,y);l.BackgroundTransparency=1;l.Font=Enum.Font.FredokaOne;l.Text=value;l.TextSize=size;l.TextColor3=tint;l.TextWrapped=true;l.TextStrokeTransparency=.2;l.ZIndex=6;return l
  end
  local top=frame(root,0,0,0,0,Color3.new(0,0,0),8);top.Size=UDim2.new(1,0,.075,0)
  local bottom=frame(root,0,0,0,0,Color3.new(0,0,0),8);bottom.Size=UDim2.new(1,0,.075,0);bottom.Position=UDim2.new(0,0,.925,0)
  label(({[5]="MYTHIC",[6]="SECRET",[7]="SUPER SECRET"})[item.Tier]..(ctx.Preview and " PREVIEW" or " SUMMON"),18,23,accent)
  local phrase=label(preset.Title,71,31,Color3.new(1,1,1))
  local name=label(item.Name,500,36,primary:Lerp(Color3.new(1,1,1),.5));name.TextTransparency=1
  local caption=label("A new power is awakening...",553,17,accent)
  local progress=frame(stage,420,3,150,605,Color3.fromRGB(45,53,66),6)
  local fill=frame(progress,0,3,0,0,accent,6)
  local skip=make("TextButton",root);skip.Name="SkipCutscene";skip.AnchorPoint=Vector2.new(1,1);skip.Position=UDim2.new(1,-24,1,-16);skip.Size=UDim2.fromOffset(180,42);skip.BackgroundColor3=Color3.fromRGB(21,26,37);skip.TextColor3=Color3.new(1,1,1);skip.Font=Enum.Font.GothamBold;skip.TextSize=15;skip.Text="SKIP  [SPACE / B]";skip.AutoButtonColor=true;skip.ZIndex=12;skip.Selectable=true;skip.Modal=true
  local corner=make("UICorner",skip);corner.CornerRadius=UDim.new(0,10)
  local wash=frame(stage,720,620,0,0,primary,5);wash.BackgroundTransparency=1
  -- Existing portrait construction supplies exactly one character clone, separately
  -- budgeted from the effect pool. It is never cloned or rebuilt during a frame.
  view=ctx.Portrait(stage,item.Id,UDim2.fromOffset(130,94),UDim2.fromOffset(460,420),"Cinematic")
  assert(view,"No character preview")
  local world=view:FindFirstChildOfClass("WorldModel")
  actor=world and world:FindFirstChildOfClass("Model");base=actor and actor:GetPivot()
  view.ZIndex=3;view.LightColor=primary:Lerp(Color3.new(1,1,1),.75)
  local rings={}
  for index=1,3 do
   local f=frame(stage,140+index*45,140+index*45,360,295,index%2==0 and accent or primary,2);f.AnchorPoint=Vector2.new(.5,.5);f.BackgroundTransparency=1;f.Rotation=index*25
   local radius=make("UICorner",f);radius.CornerRadius=UDim.new(.5,0)
   local line=make("UIStroke",f);line.Thickness=index==1 and 3 or 1.5;line.Color=index%2==0 and accent or primary;line.Transparency=.5
   table.insert(rings,{Frame=f,Line=line})
  end
  local particles={}
  for index=1,count do
   local f=frame(stage,6,15,360,295,index%3==0 and accent or primary,4)
   f.AnchorPoint=Vector2.new(.5,.5);f.BackgroundTransparency=.25
   if preset.Motif=="orbit" or preset.Motif=="petals" then local c=make("UICorner",f);c.CornerRadius=UDim.new(1,0) end
   table.insert(particles,f)
  end
  connectCamera()
  table.insert(connections,workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(connectCamera))
  table.insert(connections,skip.Activated:Connect(function() finish("Skipped") end))
  table.insert(connections,Input.InputBegan:Connect(function(input,processed)
   if not processed and (input.KeyCode==Enum.KeyCode.Space or input.KeyCode==Enum.KeyCode.ButtonB) then finish("Skipped") end
  end))
  table.insert(connections,ui.Destroying:Connect(function() finish("Closed",true) end))
  local last=-math.huge
  local function update(now)
   local elapsed=math.max(0,now-started);local p=math.clamp(elapsed/duration,0,1)
   if p>=1 then finish("Completed");return end
   if not ui.Parent then finish("Closed");return end
   local enter=ease(p/.24);local exit=math.clamp((p-.89)/.11,0,1)
   local impact=math.max(0,1-math.abs(p-.55)/.12)
   root.GroupTransparency=math.max(1-enter,exit)
   wash.BackgroundTransparency=1-impact*(.08+preset.Pulse*.3) -- a tint accent, never a white flash
   phrase.TextTransparency=math.clamp((p-.68)/.18,0,1)
   name.TextTransparency=1-ease((p-.5)/.18)
   caption.Text=ctx.Preview and "Preview only • No rewards granted" or p>.6 and "Already saved to your collection" or "A new power is awakening..."
   fill.Size=UDim2.fromOffset(420*p,3)
   if not impacted and p>=.52 then impacted=true;if ctx.OnImpact then local soundOK,soundError=pcall(ctx.OnImpact);if not soundOK then warn(tostring(soundError)) end end end
   if view.CurrentCamera then view.CurrentCamera.FieldOfView=38-enter*5-impact*2+p*2 end
   if actor and actor.Parent and base then
    local yaw=math.sin(p*math.pi)*.22*preset.Turns
    local rise=preset.Pose=="ascend" and math.sin(p*math.pi)*.28 or preset.Pose=="charge" and -impact*.13 or math.sin(elapsed)*.035
    local lean=preset.Pose=="strike" and (impact-.2)*preset.Tilt or math.sin(p*math.pi)*preset.Tilt*.2
    actor:PivotTo(base*CFrame.new(preset.Pose=="strike" and impact*.13 or 0,rise,0)*CFrame.Angles(0,yaw,lean))
   end
   for index,entry in ipairs(rings) do
    local size=(145+index*45)*(enter+.2+impact*.25)
    entry.Frame.Size=UDim2.fromOffset(size,size);entry.Frame.Rotation=p*180*preset.Turns+index*24
    entry.Line.Transparency=math.clamp(.55-impact*.3+exit,0,1)
    -- Clock freezes, then reverses. Sigils retain angular ritual outlines.
    if preset.Motif=="clock" then entry.Frame.Rotation=(p<.5 and p or .5-(p-.5)*2)*180*preset.Turns+index*30 end
    if preset.Motif=="sigil" then entry.Frame.Rotation=p*90*preset.Turns+index*45 end
   end
   for index,f in ipairs(particles) do
    local angle=index/count*math.pi*2+preset.Phase
    local phase=(p*1.8+index/count)%1
    local radius=65+enter*115+impact*45
    local x,y=math.cos(angle+p*preset.Turns*3)*radius,math.sin(angle+p*preset.Turns*3)*radius*.72
    local w,h,rotation=5,14,angle*180/math.pi
    if preset.Motif=="slashes" then
     x=(phase-.5)*600;y=math.sin(index*2+preset.Phase)*160;w=90+index%4*34;h=3+index%2;rotation=preset.Tilt*150+index%2*75
    elseif preset.Motif=="storm" then
     x=math.sin(index*2.7+p*14)*200;y=(phase-.5)*430;w=3;h=28+index%4*13;rotation=math.sin(index+p*10)*40
    elseif preset.Motif=="pillar" then
     x=math.sin(index*1.7+preset.Phase)*175;y=200-phase*410;w=3+index%3;h=42+index%3*28;rotation=preset.Tilt*20
    elseif preset.Motif=="burst" then
     radius=40+phase*240;x=math.cos(angle)*radius;y=math.sin(angle)*radius*.8;w=8;h=35+phase*80;rotation=angle*180/math.pi+90
    elseif preset.Motif=="petals" then
     x=math.cos(angle+p*3)*radius;y=(phase-.5)*390;w=9;h=17;rotation=p*360+index*25
    elseif preset.Motif=="clock" then
     local turn=p<.5 and p or .5-(p-.5)*2
     x=math.cos(angle+turn*preset.Turns)*radius;y=math.sin(angle+turn*preset.Turns)*radius;w=4;h=index%3==0 and 23 or 12;rotation=angle*180/math.pi+turn*60
    elseif preset.Motif=="spiral" then
     radius=35+(1-phase)*220;x=math.cos(angle+p*preset.Turns*7)*radius;y=math.sin(angle+p*preset.Turns*7)*radius*.75;w=5;h=22;rotation=angle*180/math.pi+p*180
    elseif preset.Motif=="orbit" then
     radius=radius*(1-impact*.35);x=math.cos(angle+p*preset.Turns*4)*radius;y=math.sin(angle+p*preset.Turns*4)*radius*.7;w=index<=2 and 23 or 7;h=w;rotation=0
    elseif preset.Motif=="sigil" then
     local segment=index%2==0 and 1 or .7;x=math.cos(angle+p*preset.Turns)*radius*segment;y=math.sin(angle+p*preset.Turns)*radius*segment;w=4;h=24;rotation=angle*180/math.pi+p*60
    end
    f.Position=UDim2.fromOffset(360+x,290+y);f.Size=UDim2.fromOffset(w,h);f.Rotation=rotation;f.BackgroundTransparency=math.clamp(.2+math.abs(phase-.5)*.8+exit,0,1)
   end
  end
  table.insert(connections,Run.RenderStepped:Connect(function()
   if finished then return end
   local now=clock();if now-last<1/fps then return end;last=now
   local frameOK,frameError=pcall(update,now)
   if not frameOK then warn("Summon cutscene: "..tostring(frameError));finish("Error") end
  end))
  update(started)
 end,debug.traceback)
 if not ok then warn("Summon cutscene setup: "..tostring(err));finish("Error") end
 return controller
end
return Scenes
