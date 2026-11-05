-- Falling Heavens: a local miniature set, real character clone, fixed reusable FX.
-- Never moves the gameplay camera or changes summon rewards.
local M={Duration=9.6,Budget={MaxInstances=72,FPS=30,ReducedFPS=24}}
local Run=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local function ramp(t,a,b) return math.clamp((t-a)/(b-a),0,1) end
local function smooth(x) return x*x*(3-2*x) end
function M.Play(item,ctx)
 local clock=ctx.Clock or os.clock
 local started=clock();local finished=false;local impacted=false;local spoken=false
 local connections={};local ui;local audio;local made=0
 local reduced=ctx.ReducedEffects==true or Input.TouchEnabled==true
 local controller={Metrics={Effects=0,Particles=0,FPS=reduced and 24 or 30,Duration=M.Duration,Meteors=4}}
 local function make(class,parent)
  assert(made<M.Budget.MaxInstances,"Madara effect budget exceeded")
  local value=Instance.new(class);value.Parent=parent;made+=1;controller.Metrics.Effects=made;return value
 end
 local function finish(reason,destroying)
  if finished then return end;finished=true
  for _,connection in ipairs(connections) do connection:Disconnect() end
  if audio then audio:Destroy();audio=nil end
  if ui and not destroying then ui:Destroy() end
  if ctx.OnComplete then local ok,err=pcall(ctx.OnComplete,reason);if not ok then warn(tostring(err)) end end
 end
 function controller:Cancel(reason) finish(reason or "Skipped") end
 function controller:IsPlaying() return not finished end
 local ok,err=xpcall(function()
  ui=make("ScreenGui",ctx.Parent);ui.Name="RiftSummonCutscene";ui.DisplayOrder=70;ui.IgnoreGuiInset=true;ui.ResetOnSpawn=false;ui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
  local root=make("CanvasGroup",ui);root.Size=UDim2.fromScale(1,1);root.BackgroundTransparency=1;root.BackgroundColor3=Color3.new(1,1,1);root.Active=true
  local sky=make("Frame",root);sky.Name="HorizonSky";sky.Size=UDim2.fromScale(1,1);sky.BackgroundColor3=Color3.new(1,1,1);sky.BorderSizePixel=0
  local gradient=make("UIGradient",sky);gradient.Rotation=90;gradient.Color=ColorSequence.new(Color3.fromRGB(62,89,127),Color3.fromRGB(245,202,159))
  local view=ctx.Portrait(root,item.Id,UDim2.new(),UDim2.fromScale(1,1),"Cinematic")
  assert(view and view.CurrentCamera,"Missing Madara model preview")
  local world=view:FindFirstChildOfClass("WorldModel")
  local actor=world and world:FindFirstChildOfClass("Model");assert(actor,"Missing Madara character model")
  -- Normalize the imported model once; arbitrary Studio pivot offsets must not put
  -- the character below the cliff or outside the close-up camera.
  local bounds,size=actor:GetBoundingBox();assert(size.Y>.01,"Empty Madara model")
  actor:ScaleTo(actor:GetScale()*6/size.Y)
  bounds,size=actor:GetBoundingBox()
  actor:PivotTo(CFrame.new(-bounds.Position)*actor:GetPivot())
  local base=actor:GetPivot()
  view.ZIndex=2;view.LightColor=Color3.new(1,1,1);view.Ambient=Color3.fromRGB(215,221,233);view.LightDirection=Vector3.new(-1,-.7,-.4)
  local fx=make("Folder",world);fx.Name="FallingHeavensSet"
  local function part(name,size,position,tint,material,template)
   local p
   if template and template:IsA("MeshPart") and #template:GetDescendants()<=1 then
    p=template:Clone()
    for _,child in ipairs(p:GetChildren()) do
     if not child:IsA("SurfaceAppearance") then child:Destroy() end
    end
    local allocated=1+#p:GetDescendants();assert(made+allocated<=M.Budget.MaxInstances,"Madara mesh budget exceeded")
    made+=allocated;controller.Metrics.Effects=made;p.Parent=fx
   else p=make("Part",fx) end
   p.Name=name;p.Size=size;p.CFrame=CFrame.new(position);p.Color=tint;p.Material=material or Enum.Material.Slate;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;return p
  end
  local rock=Color3.fromRGB(84,77,76)
  part("Cliff summit",Vector3.new(22,2.5,22),Vector3.new(0,-4.25,7),rock)
  part("Cliff face",Vector3.new(19,52,17),Vector3.new(0,-31.5,7),rock:Lerp(Color3.new(0,0,0),.2))
  for i=1,5 do
   local p=part("Cliff strata",Vector3.new(20-i,4,17+i*.8),Vector3.new((i%2-.5)*2,-7-i*5,7),Color3.fromRGB(103-i*4,91-i*3,84-i*2))
   p.CFrame*=CFrame.Angles(0,i*.05,0)
  end
  part("Valley floor",Vector3.new(500,3,420),Vector3.new(0,-51,-155),Color3.fromRGB(114,101,91))
  for i=1,5 do
   local height=14+i%3*13
   local mesa=part("Distant ridge",Vector3.new(40+i*4,height,35+i*5),Vector3.new((i-3)*70,-50+height/2,-155-i%2*65),Color3.fromRGB(125-i*4,116-i*3,112-i*2))
   mesa.CFrame*=CFrame.Angles(0,i*.35,0)
  end
  local meteors={}
  for i=1,4 do
   local diameter=22+i*7
   local core=part("Meteor "..i,Vector3.new(diameter,diameter*.92,diameter),Vector3.zero,Color3.fromRGB(65+i*3,49,44),nil,ctx.MeteorTemplate)
   if core:IsA("Part") then core.Shape=Enum.PartType.Ball end
   local glow=part("Meteor fire "..i,Vector3.one,Vector3.zero,Color3.fromRGB(255,145,63),Enum.Material.Neon);glow.Shape=Enum.PartType.Ball
   local trail=part("Meteor wake "..i,Vector3.one,Vector3.zero,Color3.fromRGB(255,196,108),Enum.Material.Neon);trail.Shape=Enum.PartType.Ball
   core.Transparency=1;glow.Transparency=1;trail.Transparency=1
   table.insert(meteors,{Core=core,Glow=glow,Trail=trail,Diameter=diameter,X=({-28,32,-60,10})[i],Z=-62-(i-1)*49,Start=4.1+(i-1)*.46})
  end
  local waves,dust={},{}
  for i=1,4 do
   local wave=part("Impact wave "..i,Vector3.one,Vector3.zero,Color3.fromRGB(255,217,173),Enum.Material.Neon);wave.Shape=Enum.PartType.Cylinder;wave.Transparency=1;table.insert(waves,wave)
  end
  for i=1,(reduced and 4 or 8) do
   local p=part("Impact dust",Vector3.one,Vector3.zero,Color3.fromRGB(171,149,129));p.Shape=Enum.PartType.Ball;p.Transparency=1;table.insert(dust,p)
  end
  local function label(name,text,y,height,size)
   local l=make("TextLabel",root);l.Name=name;l.Size=UDim2.new(1,-48,0,height);l.Position=UDim2.new(0,24,y,0);l.BackgroundTransparency=1;l.Font=Enum.Font.FredokaOne;l.TextColor3=Color3.new(1,1,1);l.TextStrokeTransparency=.15;l.TextSize=size;l.TextWrapped=true;l.Text=text;l.ZIndex=6;return l
  end
  local title=label("SceneTitle","FALLING HEAVENS",.065,40,24)
  local line=label("MadaraDialogue","Too big for rain?",.76,70,32);line.TextTransparency=1
  local caption=label("SceneCaption",ctx.Preview and "PREVIEW ONLY • NO FIGHTER GRANTED" or "SECRET • MADARA UCHIHA",.89,30,16)
  for _,y in ipairs({0,.955}) do local bar=make("Frame",root);bar.Size=UDim2.fromScale(1,.045);bar.Position=UDim2.fromScale(0,y);bar.BackgroundColor3=Color3.new(0,0,0);bar.BorderSizePixel=0;bar.ZIndex=7 end
  local white=make("Frame",root);white.Name="MeteorWhiteout";white.Size=UDim2.fromScale(1,1);white.BackgroundColor3=Color3.new(1,1,1);white.BackgroundTransparency=1;white.BorderSizePixel=0;white.ZIndex=10
  local skip=make("TextButton",root);skip.Name="SkipCutscene";skip.AnchorPoint=Vector2.new(1,1);skip.Size=UDim2.fromOffset(180,42);skip.Position=UDim2.new(1,-20,1,-16);skip.BackgroundColor3=Color3.fromRGB(29,32,42);skip.TextColor3=Color3.new(1,1,1);skip.Font=Enum.Font.GothamBold;skip.TextSize=14;skip.Text="SKIP [SPACE / B]";skip.ZIndex=12;skip.Modal=true;skip.Selectable=true
  -- Create audio during setup, never in the frame loop. A separate configuration
  -- slot prevents guessing that the old summon voice is the requested quote.
  local soundId=ctx.CinematicVoiceId or ""
  if soundId~="" then
   audio=make("Sound",game:GetService("SoundService"));audio.Name="MadaraMeteorDialogue";audio.SoundId=soundId;audio.Volume=.65;audio.Looped=false;audio.PlayOnRemove=false
  end
  table.insert(connections,skip.Activated:Connect(function() finish("Skipped") end))
  table.insert(connections,Input.InputBegan:Connect(function(input,processed) if not processed and (input.KeyCode==Enum.KeyCode.Space or input.KeyCode==Enum.KeyCode.ButtonB) then finish("Skipped") end end))
  table.insert(connections,ui.Destroying:Connect(function() finish("Closed",true) end))
  local function update(now)
   local t=math.max(0,now-started)
   if t>=M.Duration then finish("Completed");return end
   local phase=t<2.2 and "Horizon" or t<4.1 and "Dialogue" or t<6.4 and "Meteors" or t<7.8 and "Impact" or "Whiteout"
   controller.Metrics.Phase=phase
   local from,target,fov
   if t<2.2 then
    local a=smooth(ramp(t,0,2.2));from=Vector3.new(7-a*3,4-a,15-a*3);target=Vector3.new(0,1,-55);fov=53-a*6
   elseif t<4.1 then
    local a=smooth(ramp(t,2.2,4.1));from=Vector3.new(-6+a*2,2.3,-8+a*1.5);target=Vector3.new(0,1,0);fov=39-a*5
   elseif t<6.4 then
    local a=smooth(ramp(t,4.1,6.4));from=Vector3.new(15+a*4,7+a*4,20);target=Vector3.new(-6,16+a*8,-90);fov=61+a*7
   else
    local a=smooth(ramp(t,6.4,8.4));from=Vector3.new(-27,16,27+a*7);target=Vector3.new(0,-4-a*10,-83);fov=64+a*8
   end
   local shake=reduced and 0 or ramp(t,6.4,6.7)*(1-ramp(t,7.2,8.1))*.23
   view.CurrentCamera.CFrame=CFrame.lookAt(from+Vector3.new(math.sin(t*39)*shake,math.cos(t*31)*shake,0),target);view.CurrentCamera.FieldOfView=fov
   actor:PivotTo(base*CFrame.Angles(0,t>=2.2 and -.12*ramp(t,2.2,3) or 0,0))
   local dialogue=ramp(t,2.2,2.5)*(1-ramp(t,4,4.35));line.TextTransparency=1-dialogue
   title.TextTransparency=ramp(t,1.3,2.1);caption.TextTransparency=ramp(t,7.6,8.2)
   if not spoken and t>=2.2 then spoken=true;if audio then audio:Play() end end
   if not impacted and t>=M.Duration*.52 then impacted=true;if ctx.OnImpact then ctx.OnImpact() end end
   for i,meteor in ipairs(meteors) do
    local fall=smooth(ramp(t,meteor.Start,meteor.Start+2.1))
    local visible=t>=meteor.Start and t<meteor.Start+2.6
    local position=Vector3.new(meteor.X+18*(1-fall),95-fall*132,meteor.Z-22*(1-fall))
    local d=meteor.Diameter
    meteor.Core.CFrame=CFrame.new(position)*CFrame.Angles(t*.14+i,t*.2,i*.4);meteor.Core.Transparency=visible and 0 or 1
    meteor.Glow.Size=Vector3.new(d*1.04,d*.97,d*1.04);meteor.Glow.CFrame=CFrame.new(position);meteor.Glow.Transparency=visible and .78 or 1
    meteor.Trail.Size=Vector3.new(d*.7,d*2.4,d*.7);meteor.Trail.CFrame=CFrame.new(position+Vector3.new(5,d*.95,-5))*CFrame.Angles(.12,0,-.16);meteor.Trail.Transparency=visible and .73 or 1
    local burst=ramp(t,meteor.Start+1.95,meteor.Start+3.2)
    local radius=8+burst*130
    local wave=waves[i];wave.Size=Vector3.new(.5,radius,radius);wave.CFrame=CFrame.new(meteor.X,-48,meteor.Z)*CFrame.Angles(0,0,math.pi/2);wave.Transparency=t<meteor.Start+1.95 and 1 or .25+burst*.75
   end
   for i,p in ipairs(dust) do
    local a=i/#dust*math.pi*2;local expansion=ramp(t,6.15,8.5);local size=8+expansion*37
    p.Size=Vector3.new(size,size*.8,size);p.CFrame=CFrame.new(-28+math.cos(a)*(9+expansion*55),-42+expansion*(14+i%3*4),-62+math.sin(a)*30);p.Transparency=t<6.15 and 1 or .25+ramp(t,8,9.5)*.75
   end
   white.BackgroundTransparency=1-smooth(ramp(t,7.8,8.8))
   root.GroupTransparency=1-ramp(t,0,.25)
  end
  local last=-math.huge
  table.insert(connections,Run.RenderStepped:Connect(function()
   if finished then return end
   local now=clock();if now-last<1/controller.Metrics.FPS then return end;last=now
   local frameOK,frameError=pcall(update,now);if not frameOK then warn("Madara scene: "..tostring(frameError));finish("Error") end
  end))
  update(started)
 end,debug.traceback)
 if not ok then warn("Madara scene setup: "..tostring(err));finish("Error") end
 return controller
end
return M
