-- Local, once-per-session welcome screen. No profile or currency mutations.
local T={}
local Tween=game:GetService("TweenService")
local Run=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local Actions=game:GetService("ContextActionService")
local Gui=game:GetService("GuiService")
local function round(item,radius)
 local c=Instance.new("UICorner",item);c.CornerRadius=UDim.new(0,radius)
end
local function stroke(item,color,width)
 local s=Instance.new("UIStroke",item);s.Color=color;s.Thickness=width;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
end
local function text(parent,value,x,y,w,h,size,color)
 local l=Instance.new("TextLabel",parent);l.Size=UDim2.fromOffset(w,h);l.Position=UDim2.fromOffset(x,y);l.BackgroundTransparency=1;l.Text=value;l.TextColor3=color or Color3.new(1,1,1);l.Font=Enum.Font.FredokaOne;l.TextSize=size;l.TextWrapped=true;l.TextStrokeTransparency=.12;return l
end
function T.Mount(ctx)
 if ctx.Player:GetAttribute("RiftTitleSeen") then ctx.OnPlay();return {IsOpen=function() return false end,Refresh=function() end} end
 local phase="Waiting"
 local started=os.clock()
 local connections={}
 local controls,disabledControls
 local cameraFov={}
 local ui=Instance.new("ScreenGui",ctx.Parent);ui.Name="AnimeRiftTitleScreen";ui.DisplayOrder=100;ui.ResetOnSpawn=false;ui.IgnoreGuiInset=true;ui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 local backdrop=Instance.new("Frame",ui);backdrop.Name="TitleBackdrop";backdrop.Size=UDim2.fromScale(1,1);backdrop.BackgroundColor3=Color3.fromRGB(8,17,31);backdrop.BackgroundTransparency=.2;backdrop.Active=true
 local card=Instance.new("CanvasGroup",backdrop);card.Name="TitleCard";card.AnchorPoint=Vector2.new(.5,.5);card.Position=UDim2.fromScale(.5,.54);card.Size=UDim2.fromOffset(700,620);card.BackgroundColor3=Color3.fromRGB(26,32,36);round(card,20);stroke(card,Color3.fromRGB(5,8,12),4)
 local fit=Instance.new("UIScale",card)
 local header=Instance.new("Frame",card);header.Size=UDim2.fromOffset(700,142);header.BackgroundColor3=Color3.new(1,1,1);header.BorderSizePixel=0;round(header,20)
 local gradient=Instance.new("UIGradient",header);gradient.Rotation=90;gradient.Color=ColorSequence.new(Color3.fromRGB(255,187,52),Color3.fromRGB(230,93,7))
 for y=0,4 do for x=0,24 do if (x+y)%2==0 then
  local tile=Instance.new("Frame",header);tile.Size=UDim2.fromOffset(17,17);tile.Position=UDim2.fromOffset(10+x*28,6+y*28);tile.BackgroundColor3=Color3.new(1,1,1);tile.BackgroundTransparency=.84;tile.BorderSizePixel=0;round(tile,3)
 end end end
 text(header,"ANIME RIFT",20,15,660,68,58)
 text(header,"C L I C K E R",20,84,660,42,27)
 text(card,"WELCOME TO RIFT MEADOWS",25,166,650,36,26,Color3.fromRGB(112,237,255))
 text(card,"Collect your favorites. Build your power.",25,206,650,30,21)
 local steps={{"01","CLICK","Build your power"},{"02","SELL & SUMMON","Collect stronger fighters"},{"03","REBIRTH","Grow your permanent bonus"}}
 for i,step in ipairs(steps) do
  local f=Instance.new("Frame",card);f.Size=UDim2.fromOffset(208,122);f.Position=UDim2.fromOffset(26+(i-1)*220,254);f.BackgroundColor3=Color3.fromRGB(42,51,58);round(f,12);stroke(f,Color3.fromRGB(76,91,104),1.5)
  text(f,step[1],5,4,198,32,24,Color3.fromRGB(255,207,77))
  text(f,step[2],5,39,198,28,21)
  text(f,step[3],12,75,184,37,17,Color3.fromRGB(207,219,230))
 end
 local play=Instance.new("TextButton",card);play.Name="TitlePlayButton";play.Size=UDim2.fromOffset(420,68);play.Position=UDim2.fromOffset(140,406);play.BackgroundColor3=Color3.new(1,1,1);play.AutoButtonColor=false;play.Text="";play.Modal=true;play.Selectable=true;round(play,16);stroke(play,Color3.fromRGB(3,8,10),4)
 local buttonGradient=Instance.new("UIGradient",play);buttonGradient.Rotation=90
 local playLabel=text(play,"LOADING...",8,4,404,60,34);playLabel.Name="Label"
 local buttonScale=Instance.new("UIScale",play)
 local previousSelection=Gui.SelectedObject
 if Input.GamepadEnabled then Gui.SelectedObject=play end
 local status=text(card,"Getting your inventory ready...",30,488,640,44,19,Color3.fromRGB(206,218,228));status.Name="TitleStatus"
 text(card,"Mouse / touch to play  •  Enter / A to start",25,553,650,32,17,Color3.fromRGB(155,174,192))
 if ctx.FighterCount then text(card,ctx.FighterCount.." FIGHTERS • 7 RARITIES",25,589,650,22,14,Color3.fromRGB(136,157,177)) end
 local function cameraView()
  local camera=workspace.CurrentCamera;if not camera then return end
  if cameraFov[camera]==nil then cameraFov[camera]=camera.FieldOfView or 70 end
  camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=64
  local t=(os.clock()-started)*.09
  camera.CFrame=CFrame.lookAt(Vector3.new(49+math.sin(t)*10,29,79+math.cos(t)*7),Vector3.new(0,6,-36))
 end
 local function resize()
  local camera=workspace.CurrentCamera;if not camera then return end
  fit.Scale=math.max(.01,math.min((camera.ViewportSize.X-28)/700,(camera.ViewportSize.Y-54)/620,1.1))
 end
 local function cleanUp()
  for _,connection in ipairs(connections) do connection:Disconnect() end
  table.clear(connections)
  ui:Destroy();phase="Closed"
 end
 local controller={}
 local lastStatus
 function controller:IsOpen() return phase~="Closed" end
 function controller:Refresh()
  if phase=="Closing" or phase=="Closed" then return end
  local ready=ctx.IsReady()
  local errorState=ctx.ServerStatus()=="Error"
  local retry=not ready and (errorState or os.clock()-started>=12)
  local statusKey=ready and "Ready" or errorState and "Error" or retry and "Slow" or "Loading"
  if statusKey==lastStatus then return end;lastStatus=statusKey
  playLabel.Text=ready and "PLAY" or retry and "RETRY CONNECTION" or "LOADING..."
  buttonGradient.Color=ready and ColorSequence.new(Color3.fromRGB(182,255,63),Color3.fromRGB(61,194,26)) or ColorSequence.new(Color3.fromRGB(117,139,158),Color3.fromRGB(65,85,105))
  status.Text=ready and "Your fighters are ready. Let's get clicking!" or errorState and "The server could not start. Retry or rejoin to reconnect." or retry and "Still connecting. Select Retry to check again." or "Getting your inventory ready..."
 end
 local function begin()
  if phase~="Waiting" then return end
  if not ctx.IsReady() then
   if ctx.ServerStatus()=="Error" or os.clock()-started>=12 then ctx.OnRetry() end
   controller:Refresh();return
  end
  phase="Closing";ctx.Player:SetAttribute("RiftTitleSeen",true)
  Actions:UnbindAction("RiftJoinTitle")
  if Gui.SelectedObject==play then Gui.SelectedObject=previousSelection and previousSelection.Parent and previousSelection or nil end
  if disabledControls and controls then controls:Enable();disabledControls=false end
  for camera,fov in pairs(cameraFov) do camera.FieldOfView=fov end
  local camera=workspace.CurrentCamera
  if camera then
   camera.CameraType=Enum.CameraType.Custom
   local character=ctx.Player.Character;local humanoid=character and character:FindFirstChildOfClass("Humanoid")
   if humanoid then camera.CameraSubject=humanoid end
  end
  ctx.OnPlay()
  Tween:Create(card,TweenInfo.new(.35,Enum.EasingStyle.Quad),{GroupTransparency=1,Position=UDim2.fromScale(.5,.53)}):Play()
  Tween:Create(backdrop,TweenInfo.new(.4),{BackgroundTransparency=1}):Play()
  task.delay(.42,cleanUp)
 end
 play.Activated:Connect(begin)
 play.MouseEnter:Connect(function() Tween:Create(buttonScale,TweenInfo.new(.14),{Scale=1.025}):Play() end)
 play.MouseLeave:Connect(function() Tween:Create(buttonScale,TweenInfo.new(.14),{Scale=1}):Play() end)
 table.insert(connections,Input.InputBegan:Connect(function(input,processed)
  if not processed and (input.KeyCode==Enum.KeyCode.Return or input.KeyCode==Enum.KeyCode.ButtonA) then begin() end
 end))
 Actions:BindActionAtPriority("RiftJoinTitle",function() return Enum.ContextActionResult.Sink end,false,3000,Enum.PlayerActions.CharacterForward,Enum.PlayerActions.CharacterBackward,Enum.PlayerActions.CharacterLeft,Enum.PlayerActions.CharacterRight,Enum.PlayerActions.CharacterJump)
 task.spawn(function()
  local scripts=ctx.Player:WaitForChild("PlayerScripts",10);if not scripts then return end
  local module=scripts:WaitForChild("PlayerModule",10);if not module then return end
  local ok,result=pcall(function() return require(module):GetControls() end)
  if ok and result and phase=="Waiting" then controls=result;controls:Disable();disabledControls=true end
 end)
 local viewportConnection
 local function connectCamera()
  if viewportConnection then viewportConnection:Disconnect() end
  local camera=workspace.CurrentCamera
  if camera then viewportConnection=camera:GetPropertyChangedSignal("ViewportSize"):Connect(resize);table.insert(connections,viewportConnection) end
  resize();if phase=="Waiting" then cameraView() end
 end
 table.insert(connections,workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(connectCamera))
 table.insert(connections,Run.RenderStepped:Connect(function()
  if phase=="Waiting" then cameraView();controller:Refresh() end
 end))
 connectCamera();controller:Refresh()
 Tween:Create(card,TweenInfo.new(.45,Enum.EasingStyle.Back),{Position=UDim2.fromScale(.5,.5)}):Play()
 return controller
end
return T
