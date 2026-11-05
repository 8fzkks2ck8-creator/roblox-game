-- A single local viewport + a small reusable pool of GUI effects. No world-camera,
-- physics, remote requests, downloaded assets, or per-frame Instance allocation.
local Scenes={}
local Presets=require(script.Parent:WaitForChild("SummonPresets"))
local Madara=require(script.Parent:WaitForChild("MadaraSequence"))
local Run=game:GetService("RunService")
local Input=game:GetService("UserInputService")
Scenes.Budget=Presets.Budget
local active
local function color(rgb) return Color3.fromRGB(rgb[1],rgb[2],rgb[3]) end
local function ease(x) return 1-(1-math.clamp(x,0,1))^3 end
-- Save bind-space offsets once. Costume pieces follow their welded body segment,
-- including loose imported meshes; no clone or rig rebuild occurs while rendering.
local function bindPose(actor,base)
 local core={};local parts={};local all=actor:GetDescendants()
 for _,part in ipairs(all) do if part:IsA("BasePart") then
  local name=part.Name
  if name=="Body" or name=="Torso" or name=="UpperTorso" then core.Torso=part
  elseif name=="Head" then core.Head=part
  elseif name=="Left Arm" or name=="LeftUpperArm" then core.Left=part
  elseif name=="Right Arm" or name=="RightUpperArm" then core.Right=part
  elseif name=="Arm" then core[part.CFrame.Position.X<base.Position.X and "Left" or "Right"]=part end
 end end
 if not core.Torso then return function() end end
 local bases,groups={},{}
 for name,part in pairs(core) do bases[name]=base:ToObjectSpace(part.CFrame);groups[part]=name end
 for _=1,3 do for _,joint in ipairs(all) do
  if (joint:IsA("WeldConstraint") or joint:IsA("Weld") or joint:IsA("Motor6D")) and joint.Part0 and joint.Part1 then
   if groups[joint.Part0] and not groups[joint.Part1] then groups[joint.Part1]=groups[joint.Part0]
   elseif groups[joint.Part1] and not groups[joint.Part0] then groups[joint.Part0]=groups[joint.Part1] end
  end
 end end
 for _,part in ipairs(all) do if part:IsA("BasePart") then
  local group=groups[part]
  if not group then
   local distance=math.huge
   for name,body in pairs(core) do
    local d=(body.CFrame.Position-part.CFrame.Position).Magnitude
    if d<distance then distance=d;group=name end
   end
  end
  table.insert(parts,{Part=part,Group=group,Offset=bases[group]:ToObjectSpace(base:ToObjectSpace(part.CFrame))})
 end end
 return function(pivot,charge,strike,pose)
  local angles={Torso=CFrame.Angles(pose=="strike" and -strike*.12 or charge*.035,0,0)}
  angles.Head=CFrame.Angles(-charge*.12,pose=="calm" and charge*.12 or 0,0)
  angles.Left=CFrame.Angles(pose=="strike" and -charge*.6 or -charge*.22,0,-charge*(pose=="ascend" and .55 or .16))
  angles.Right=CFrame.Angles(pose=="strike" and -strike*1.35-charge*.35 or -charge*.22,0,charge*(pose=="ascend" and .55 or .16))
  for _,entry in ipairs(parts) do if entry.Part.Parent then
   local group=entry.Group;local transform=bases[group]*angles[group]
   entry.Part.CFrame=pivot*transform*entry.Offset
  end end
 end
end
function Scenes.Play(item,ctx)
 local preset=Presets.Get(item.Id)
 if not preset or item.Tier<5 then return nil end
 if active then active:Cancel("Replaced") end
 if item.Id=="madara" then
  local delegated=table.clone(ctx);local controller
  delegated.OnComplete=function(reason)
   if active==controller then active=nil end
   if ctx.OnComplete then ctx.OnComplete(reason) end
  end
  controller=Madara.Play(item,delegated)
  if controller and controller:IsPlaying() then active=controller end
  return controller
 end
 local clock=ctx.Clock or os.clock
 local started=clock()
 local duration=Presets.Duration(item.Tier)
 local direction=Presets.Direction(item.Tier)
 local reduced=ctx.ReducedEffects==true or Input.TouchEnabled==true
 local count=math.min(preset.Count,reduced and 6 or Presets.Budget.MaxParticles)
 local fps=reduced and 24 or Presets.Budget.FPS
 local connections={}
 local finished=false
 local impacted=false
 local ui,actor,view,base
 local made=0
 local controller={Metrics={Effects=0,Particles=count,FPS=fps,Duration=duration,Shots=direction.Shots}}
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
  local root=make("CanvasGroup",ui);root.Size=UDim2.fromScale(1,1);root.BackgroundColor3=Color3.new(1,1,1);root.BackgroundTransparency=1;root.Active=true;root.GroupTransparency=0
  -- Keep the gradient off CanvasGroup: a group gradient tints the composited actor too.
  local background=make("Frame",root);background.Name="CinematicBackdrop";background.Size=UDim2.fromScale(1,1);background.BackgroundColor3=Color3.new(1,1,1);background.BorderSizePixel=0
  local gradient=make("UIGradient",background);gradient.Rotation=30+preset.Seed%120;gradient.Color=ColorSequence.new(primary:Lerp(Color3.fromRGB(95,130,171),.55),accent:Lerp(Color3.fromRGB(147,174,207),.65))
  local stage=make("Frame",root);stage.Name="CinematicStage";stage.Size=UDim2.fromOffset(720,620);stage.AnchorPoint=Vector2.new(.5,.5);stage.Position=UDim2.fromScale(.5,.5);stage.BackgroundTransparency=1;stage.ZIndex=2
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
  local top=frame(root,0,0,0,0,Color3.new(0,0,0),8);top.Size=UDim2.new(1,0,.045,0)
  local bottom=frame(root,0,0,0,0,Color3.new(0,0,0),8);bottom.Size=UDim2.new(1,0,.045,0);bottom.Position=UDim2.new(0,0,.955,0)
  label(({[5]="MYTHIC",[6]="SECRET",[7]="SUPER SECRET"})[item.Tier]..(ctx.Preview and " PREVIEW" or " SUMMON"),18,23,accent)
  local phrase=label(preset.Title,71,31,Color3.new(1,1,1))
  local name=label(item.Name,500,36,primary:Lerp(Color3.new(1,1,1),.5));name.TextTransparency=1
  local caption=label("A new power is awakening...",553,17,accent)
  local progress=frame(stage,420,3,150,605,Color3.fromRGB(45,53,66),6)
  local fill=frame(progress,0,3,0,0,accent,6)
  local skip=make("TextButton",root);skip.Name="SkipCutscene";skip.AnchorPoint=Vector2.new(1,1);skip.Position=UDim2.new(1,-24,1,-16);skip.Size=UDim2.fromOffset(180,42);skip.BackgroundColor3=Color3.fromRGB(21,26,37);skip.TextColor3=Color3.new(1,1,1);skip.Font=Enum.Font.GothamBold;skip.TextSize=15;skip.Text="SKIP  [SPACE / B]";skip.AutoButtonColor=true;skip.ZIndex=12;skip.Selectable=true;skip.Modal=true
  local corner=make("UICorner",skip);corner.CornerRadius=UDim.new(0,10)
  local wash=frame(stage,720,620,0,0,primary,1);wash.BackgroundTransparency=1
  -- Existing portrait construction supplies exactly one character clone, separately
  -- budgeted from the effect pool. It is never cloned or rebuilt during a frame.
  view=ctx.Portrait(stage,item.Id,UDim2.fromOffset(0,102),UDim2.fromOffset(720,392),"Cinematic")
  assert(view,"No character preview")
  local world=view:FindFirstChildOfClass("WorldModel")
  actor=world and world:FindFirstChildOfClass("Model");base=actor and actor:GetPivot()
  assert(actor and base and view.CurrentCamera,"Missing cinematic actor/camera")
  local center,height=base.Position,6
  local boxOK,box,size=pcall(function() local cf,sz=actor:GetBoundingBox();return cf,sz end)
  if boxOK and size and size.Y>.01 then center=box.Position;height=math.max(size.Y,size.X*.8,size.Z*.8) end
  local unit=height/6
  local pose=bindPose(actor,base)
  view.ZIndex=3;view.LightColor=Color3.new(1,1,1);view.Ambient=Color3.fromRGB(225,225,235);view.LightDirection=Vector3.new(-1,-1,-1)
  local fx=make("Model",world);fx.Name="SummonSpatialFX"
  local function part(name,tint,material)
   local p=make("Part",fx);p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Color=tint;p.Material=material or Enum.Material.Neon;p.Transparency=1;p.Size=Vector3.one;return p
  end
  local platform=part("Summon plinth",Color3.fromRGB(66,77,92),Enum.Material.Slate)
  platform.Size=Vector3.new(height*2.8,unit*.18,height*2.8);platform.Position=Vector3.new(center.X,center.Y-height*.52,center.Z);platform.Transparency=.15
  local energy=part("Rising power",primary);energy.Shape=Enum.PartType.Ball
  local beams,rocks={},{ }
  for i=1,(reduced and 3 or 5) do table.insert(beams,part("Signature energy",i%2==0 and accent or primary)) end
  for i=1,(reduced and 3 or 5) do table.insert(rocks,part("Suspended fragments",Color3.fromRGB(84,89,105),Enum.Material.Slate)) end
  local horizon=part("Distant halo",accent);horizon.Shape=Enum.PartType.Ball
  local rings={}
  for index=1,2 do
   local f=frame(stage,140+index*45,140+index*45,360,295,index%2==0 and accent or primary,2);f.AnchorPoint=Vector2.new(.5,.5);f.BackgroundTransparency=1;f.Rotation=index*25
   local radius=make("UICorner",f);radius.CornerRadius=UDim.new(.5,0)
   local line=make("UIStroke",f);line.Thickness=index==1 and 3 or 1.5;line.Color=index%2==0 and accent or primary;line.Transparency=.5
   table.insert(rings,{Frame=f,Line=line})
  end
  local particles={}
  for index=1,count do
   local f=frame(stage,6,15,360,295,index%3==0 and accent or primary,2)
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
   local enter=ease(p/.06);local exit=math.clamp((p-.93)/.07,0,1)
   local charge=ease((p-.16)/.34)
   local impact=math.max(0,1-math.abs(p-.55)/.1)
   local settle=ease((p-.64)/.18)
   local power=(charge*(1-settle*.32)+impact*.3)*direction.Intensity
   root.GroupTransparency=math.max(1-enter,exit)
   wash.BackgroundTransparency=1-impact*(.03+preset.Pulse*.1) -- a tint accent, never a white flash
   phrase.TextTransparency=math.clamp((p-.68)/.18,0,1)
   name.TextTransparency=1-ease((p-.64)/.12)
   caption.Text=ctx.Preview and "Preview only • No rewards granted" or p>.72 and "Already saved to your collection" or p>.5 and "AWAKENING" or p>.18 and preset.Title or "A presence beyond the rift..."
   fill.Size=UDim2.fromOffset(420*p,3)
   if not impacted and p>=.52 then impacted=true;if ctx.OnImpact then local soundOK,soundError=pcall(ctx.OnImpact);if not soundOK then warn(tostring(soundError)) end end end
   -- Broly-style progression: establishing silhouette, intimate anticipation,
   -- low-angle power-up, impact pullback, then an unhurried hero shot.
   local shot,angle,distance,targetY,cameraY
   local side=preset.Turns<0 and -1 or 1
   if p<.18 then
    shot="Establish";local q=ease(p/.18);angle=side*(.75-q*.35);distance=11-q*2;targetY=.1;cameraY=1.4
   elseif p<.35 and item.Tier>=6 then
    shot="Anticipation";local q=ease((p-.18)/.17);angle=-side*.2;distance=5.2-q*.6;targetY=1.3;cameraY=1.5
   elseif p<.51 then
    shot="Charge";local q=ease((p-.18)/.33);angle=side*(-.35+q*direction.Orbit);distance=8-q;targetY=.5;cameraY=-.5
   elseif p<.65 then
    shot="Impact";local q=ease((p-.51)/.14);angle=side*.15;distance=7+q*4;targetY=.4;cameraY=.4
   elseif p<.77 and item.Tier==7 then
    shot="Ascension";local q=ease((p-.65)/.12);angle=side*(.2+q*.75);distance=10.5;targetY=.7;cameraY=3
   else
    shot="Hero";local q=ease((p-.65)/.28);angle=side*(.4-q*.2);distance=10-q*1.2;targetY=.25;cameraY=.8
   end
   controller.Metrics.Shot=shot
   local rise=preset.Pose=="ascend" and power*direction.Lift or preset.Pose=="charge" and -impact*.15 or 0
   local pivot=base*CFrame.new(0,rise*unit,0)*CFrame.Angles(0,math.sin(p*math.pi)*preset.Turns*.18,0)
   actor:PivotTo(pivot);pose(pivot,charge,impact,preset.Pose)
   local shake=reduced and 0 or impact*.045*direction.Intensity
   local cx=center.X+math.sin(angle)*distance*unit+math.sin(elapsed*39)*shake*unit
   local cy=center.Y+(cameraY+rise+math.cos(elapsed*31)*shake)*unit
   local cz=center.Z-math.cos(angle)*distance*unit
   view.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(cx,cy,cz),Vector3.new(center.X,center.Y+(targetY+rise)*unit,center.Z))
   view.CurrentCamera.FieldOfView=shot=="Anticipation" and 32 or shot=="Impact" and 42+impact*3 or 38
   -- Reuse the entire spatial pool. All energy lives around the silhouette so
   -- the actor and authored materials remain readable throughout the reveal.
   local sphereSize=height*(.45+power*.7)
   energy.Size=Vector3.new(sphereSize,sphereSize,sphereSize)
   energy.Position=Vector3.new(center.X,center.Y+rise*unit,center.Z+height*.28)
   energy.Transparency=1-math.min(.14,power*.09)
   horizon.Size=Vector3.new(height*(1+power*.6),height*(1+power*.6),unit*.15)
   horizon.Position=Vector3.new(center.X,center.Y+height*.25,center.Z+height*.8);horizon.Transparency=.96-power*.05
   for index,beam in ipairs(beams) do
    local a=index/#beams*math.pi*2+elapsed*.18*preset.Turns
    local radius=height*(.58+index%2*.16);local h=height*(.3+power*(.65+index%3*.15))
    if preset.Motif=="slashes" then
     beam.Size=Vector3.new(unit*.07,unit*.14,height*(.5+impact));beam.CFrame=CFrame.new(center.X+math.cos(a)*radius,center.Y+math.sin(a)*height*.25,center.Z+unit)*CFrame.Angles(0,0,preset.Tilt*3+a)
    elseif preset.Motif=="orbit" or preset.Motif=="clock" then
     local ball=height*(index<=2 and .16 or .055);beam.Shape=Enum.PartType.Ball;beam.Size=Vector3.new(ball,ball,ball)
     local turn=preset.Motif=="clock" and (p<.5 and elapsed*.5 or -elapsed*.8) or elapsed*.7
     beam.Position=Vector3.new(center.X+math.cos(a+turn)*radius,center.Y+math.sin(a+turn)*radius*.6,center.Z+unit)
    else
     beam.Size=Vector3.new(unit*.12,h,unit*.12);beam.CFrame=CFrame.new(center.X+math.cos(a)*radius,center.Y-height*.5+h*.5,center.Z+math.sin(a)*radius)*CFrame.Angles(0,a,math.sin(elapsed+index)*.12)
    end
    beam.Transparency=1-math.min(.75,power*(.35+index%2*.15))
   end
   for index,rock in ipairs(rocks) do
    local a=index/#rocks*math.pi*2+elapsed*.23;local radius=height*(.7+index%2*.15);local sz=unit*(.2+index%3*.12)
    rock.Size=Vector3.new(sz,sz*.7,sz);rock.CFrame=CFrame.new(center.X+math.cos(a)*radius,center.Y-height*.45+charge*unit*(1+index%3)+math.sin(elapsed+index)*unit*.08,center.Z+math.sin(a)*radius)*CFrame.Angles(elapsed*.3,index,elapsed*.2)
    rock.Transparency=1-math.min(.95,charge*.8)
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
