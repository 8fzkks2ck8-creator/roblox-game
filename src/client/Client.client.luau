local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Tween=game:GetService("TweenService")
local Input=game:GetService("UserInputService")
local Market=game:GetService("MarketplaceService")
local Prompts=game:GetService("ProximityPromptService")
local Run=game:GetService("RunService")
local p=Players.LocalPlayer
local folder=RS:WaitForChild("AnimeRift")
local C=require(folder:WaitForChild("Config"))
local Polish=require(folder:WaitForChild("Polish"))
local Request=folder:WaitForChild("Request"); local Event=folder:WaitForChild("Event")
local ui=Instance.new("ScreenGui"); ui.Name="AnimeRiftUI"; ui.ResetOnSpawn=false; ui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; ui.Parent=p:WaitForChild("PlayerGui")
local canvas=Instance.new("Frame",ui); canvas.Size=UDim2.fromOffset(1200,760); canvas.AnchorPoint=Vector2.new(0.5,0.5); canvas.Position=UDim2.fromScale(0.5,0.5); canvas.BackgroundTransparency=1
local scale=Instance.new("UIScale",canvas)
local function resize() if not workspace.CurrentCamera then return end; local v=workspace.CurrentCamera.ViewportSize; scale.Scale=math.max(0.1,math.min(v.X/1200,(v.Y-50)/760)) end
resize(); workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
local palette={Ink=Color3.fromRGB(12,14,32),Panel=Color3.fromRGB(25,31,59),Cyan=Color3.fromRGB(30,192,255),Pink=Color3.fromRGB(255,72,127),Gold=Color3.fromRGB(255,205,39),White=Color3.fromRGB(255,255,255),Mint=Color3.fromRGB(99,239,184)}
local state,page,render,activeMatch=nil,nil,nil,nil
local loadingStarted=os.clock()
local apply
local revealing=false
local wheelSpinning=false
local wheelButton
local revealQueue={}
local playReveal
local movingPatterns={}
local spinningPreviews={}
local codeDraft=""
local adminDraft=""
local busy=false; local selectedProduct="Starter"; local cooldowns={}; local offset=0; local toastSerial=0
local function sound(key,pitch)
 local id=C.Sounds[key]; if not id or id=="" then return end
 local audio=Instance.new("Sound",game:GetService("SoundService"));audio.SoundId=id;audio.Volume=C.UI.SoundVolume*((key=="Shake" or key=="WheelTick") and 0.3 or 1);audio.PlaybackSpeed=pitch or 1
 audio:Play();game:GetService("Debris"):AddItem(audio,5)
end
local summonAudio
local function stopSummonSound()
 if summonAudio then summonAudio:Destroy();summonAudio=nil end
end
local function characterSummonSound(id)
 stopSummonSound()
 local assets=folder:FindFirstChild("Assets")
 local sounds=assets and assets:FindFirstChild("SummonSounds")
 local template=sounds and sounds:FindFirstChild(id)
 if not template or not template:IsA("Sound") or template.SoundId=="" then return false end
 local audio=template:Clone();audio.Name="CharacterSummonSound";audio.Looped=false;audio.PlayOnRemove=false
 audio.Volume=math.clamp(audio.Volume,0,10)*C.UI.SoundVolume
 audio.Parent=game:GetService("SoundService");summonAudio=audio
 audio:Play();game:GetService("Debris"):AddItem(audio,30)
 return true
end
local function corner(obj,r) local c=obj:FindFirstChildOfClass("UICorner") or Instance.new("UICorner",obj); c.CornerRadius=UDim.new(0,r or 18) end
local function outline(obj,color,thickness) local s=Instance.new("UIStroke",obj); s.Color=color or palette.Ink; s.Thickness=thickness or 3; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border end
local function label(parent,text,size,pos,textsize,color)
 local t=Instance.new("TextLabel",parent); t.Size=size; t.Position=pos or UDim2.new(); t.BackgroundTransparency=1; t.Text=text; t.Font=Enum.Font.GothamBold; t.TextSize=textsize or 18; t.TextColor3=color or palette.White; t.TextWrapped=true; t.ZIndex=3; t.TextStrokeColor3=Color3.new(0,0,0); t.TextStrokeTransparency=.65; local stroke=Instance.new("UIStroke",t); stroke.Color=Color3.new(0,0,0); stroke.Thickness=.65; return t
end
local function textGradient(obj,top,bottomColor)
 obj.TextColor3=Color3.new(1,1,1)
 local g=Instance.new("UIGradient",obj);g.Rotation=90;g.Color=ColorSequence.new(top,bottomColor)
end
local function gradient(obj,color)
 local g=Instance.new("UIGradient",obj); g.Rotation=90
 g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,color:Lerp(Color3.new(1,1,1),0.32)),ColorSequenceKeypoint.new(0.48,color),ColorSequenceKeypoint.new(1,color:Lerp(Color3.new(0,0,0),0.25))})
 obj.BackgroundColor3=Color3.new(1,1,1)
end
local function studs(parent,width,height,step)
 local mask=Instance.new("Frame",parent);mask.Name="SlidingStuds";mask.Size=UDim2.fromScale(1,1);mask.BackgroundTransparency=1;mask.ClipsDescendants=true;mask.Active=false;mask.ZIndex=1;corner(mask,math.min(24,height/2))
 for i=1,3 do
  local dot=Instance.new("Frame",mask);dot.Size=UDim2.fromOffset(36+i*10,36+i*10);dot.Position=UDim2.fromOffset(width-i*42,-20+i*5);dot.BackgroundColor3=Color3.new(1,1,1);dot.BackgroundTransparency=.94;dot.BorderSizePixel=0;corner(dot,80)
 end
end
local function gleam(parent,w,h)
 for _,pos in ipairs({Vector2.new(3,h-3),Vector2.new(w-3,3)}) do
  local line=Instance.new("Frame",parent); line.Size=UDim2.fromOffset(26,2); line.Position=UDim2.fromOffset(pos.X-13,pos.Y); line.BackgroundColor3=Color3.new(1,1,1); line.BorderSizePixel=0; line.ZIndex=5
  local vertical=line:Clone(); vertical.Size=UDim2.fromOffset(2,22); vertical.Position=UDim2.fromOffset(pos.X,pos.Y-10); vertical.Parent=parent
 end
end
local function panel(parent,size,pos,color,pattern)
 local f=Instance.new("Frame",parent); f.Size=UDim2.fromOffset(size.X,size.Y); f.Position=UDim2.fromOffset(pos.X,pos.Y); f.BackgroundColor3=color or palette.Panel; f.BorderSizePixel=0; corner(f,22); outline(f,palette.Ink,2)
 if pattern then gradient(f,color or palette.Panel); studs(f,size.X,size.Y,20) end
 return f
end
local function button(parent,text,width,height,color,fn)
 local b=Instance.new("TextButton",parent); b.Size=UDim2.fromOffset(width,height); b.BackgroundColor3=color or palette.Cyan; b.Text=""; b.AutoButtonColor=false; b.BorderSizePixel=0; corner(b,math.min(24,height/2)); outline(b,palette.Ink,2)
 gradient(b,color or palette.Cyan)
 if string.find(text,"GEMS") or string.find(text,"GEM PARTY") then b:FindFirstChildOfClass("UIGradient").Color=ColorSequence.new(Color3.fromRGB(174,86,255),Color3.fromRGB(255,53,202))
 elseif string.find(text,"COINS") or string.find(text,"BUY") then b:FindFirstChildOfClass("UIGradient").Color=ColorSequence.new(Color3.fromRGB(183,255,105),Color3.fromRGB(44,220,59)) end
 studs(b,width,height,20)
 local t=label(b,text,UDim2.new(1,-14,1,-6),UDim2.fromOffset(7,0),20,palette.White); t.Name="Label"
 local s=Instance.new("UIScale",b)
 b.MouseEnter:Connect(function() Tween:Create(s,TweenInfo.new(0.12),{Scale=1.025}):Play() end)
 b.MouseLeave:Connect(function() Tween:Create(s,TweenInfo.new(0.12),{Scale=1}):Play() end)
 b.Activated:Connect(function() sound("Click",1.7); Tween:Create(s,TweenInfo.new(0.08,Enum.EasingStyle.Back),{Scale=0.96}):Play(); task.delay(0.1,function() if s.Parent then Tween:Create(s,TweenInfo.new(0.16),{Scale=1}):Play() end end); fn() end)
 return b
end
local toast=panel(canvas,Vector2.new(900,40),Vector2.new(150,-65),palette.Panel,false); toast.BackgroundTransparency=0.3; toast.ZIndex=100; toast.Visible=false
local toastText=label(toast,"",UDim2.new(1,-20,1,0),UDim2.fromOffset(10,0),22,palette.Mint)
local function notify(text)
 toastSerial=toastSerial+1; local serial=toastSerial; toastText.Text=text; toast.Visible=true; toast.Position=UDim2.fromOffset(150,-65)
 Tween:Create(toast,TweenInfo.new(0.35,Enum.EasingStyle.Back),{Position=UDim2.fromOffset(150,78)}):Play()
 task.delay(4,function() if toastSerial==serial then Tween:Create(toast,TweenInfo.new(0.2),{Position=UDim2.fromOffset(150,-65)}):Play(); task.wait(0.2); if toastSerial==serial then toast.Visible=false end end end)
end
local function call(action,arg)
 if revealing and action~="State" and action~="Attack" and action~="LeaveBoss" then notify("Finish your character reveal first."); return end
 if busy and action~="Attack" and action~="LeaveBoss" then if action~="State" and action~="Train" then notify("Finishing your previous action...") end; return end
 if folder:GetAttribute("ServerStatus")=="Error" then
  notify("Server could not start. Check Studio Output for the red error."); return
 end
 local ownsBusy=action~="Attack" and action~="LeaveBoss"
 if ownsBusy then busy=true end
 local finished=false; local response; local success=false
 task.spawn(function()
  success,response=pcall(function() return Request:InvokeServer(action,arg) end)
  finished=true
 end)
 local deadline=os.clock()+12
 while not finished and os.clock()<deadline do task.wait(0.05) end
 if ownsBusy then busy=false end
 if not finished then notify("Server response delayed. Your inventory will refresh when it reconnects."); return end
 if not success then notify("Connection interrupted. Please try again."); return end
 if response and response.Message and action~="State" then notify(response.Message) end
 return response
end
local header=Instance.new("Frame",canvas); header.Size=UDim2.fromOffset(230,94); header.Position=UDim2.fromOffset(12,648); header.BackgroundTransparency=1
local currencies=label(header,"CONNECTING...",UDim2.fromOffset(245,37),UDim2.fromOffset(0,0),28,palette.Mint); currencies.TextXAlignment=Enum.TextXAlignment.Left
textGradient(currencies,Color3.fromRGB(202,255,130),Color3.fromRGB(35,221,50))
local gemsLabel=label(header,"GEMS",UDim2.fromOffset(245,32),UDim2.fromOffset(0,38),24);gemsLabel.TextXAlignment=Enum.TextXAlignment.Left
textGradient(gemsLabel,Color3.fromRGB(210,115,255),Color3.fromRGB(255,42,215))
local winsLabel=label(header,"",UDim2.fromOffset(245,22),UDim2.fromOffset(0,72),16);winsLabel.TextXAlignment=Enum.TextXAlignment.Left
local logo=label(canvas,"ANIME RIFT",UDim2.fromOffset(245,55),UDim2.fromOffset(10,10),32,palette.Gold)
local bottom=label(canvas,"CLICK • TRAIN • CONQUER",UDim2.fromOffset(650,30),UDim2.fromOffset(275,630),16)
local status=label(canvas,"",UDim2.fromOffset(720,36),UDim2.fromOffset(240,108),21,palette.Gold)
local dim=Instance.new("TextButton",canvas);dim.Name="ModalBackdrop";dim.Size=UDim2.fromScale(1,1);dim.BackgroundColor3=Color3.fromRGB(9,24,46);dim.BackgroundTransparency=.4;dim.Text="";dim.AutoButtonColor=false;dim.ZIndex=8;dim.Visible=false
local window=panel(canvas,Vector2.new(740,480),Vector2.new(230,145),palette.Panel,false); window.ZIndex=10; window.Visible=false; window.BackgroundTransparency=0.04
local inner=Instance.new("UIStroke",window); inner.Color=Color3.fromRGB(169,239,255); inner.Thickness=1.5
local banner=panel(window,Vector2.new(736,62),Vector2.new(2,2),palette.Cyan,true); gleam(banner,736,62)
local title=label(banner,"",UDim2.fromOffset(625,58),UDim2.fromOffset(16,0),34,palette.White); title.TextXAlignment=Enum.TextXAlignment.Left
local close=button(banner,"X",58,56,Color3.fromRGB(255,66,45),function() page=nil; window.Visible=false;dim.Visible=false end); close.Position=UDim2.fromOffset(674,3); close.Label.TextSize=38
dim.Activated:Connect(function() page=nil;window.Visible=false;dim.Visible=false end)
local list=Instance.new("ScrollingFrame",window); list.Position=UDim2.fromOffset(16,77); list.Size=UDim2.fromOffset(708,388); list.BackgroundTransparency=1; list.BorderSizePixel=0; list.ScrollBarThickness=6; list.ScrollBarImageColor3=palette.Cyan; list.AutomaticCanvasSize=Enum.AutomaticSize.Y; list.CanvasSize=UDim2.new(); list.ClipsDescendants=true
local layout=Instance.new("UIListLayout",list); layout.Padding=UDim.new(0,12); layout.SortOrder=Enum.SortOrder.LayoutOrder
local pad=Instance.new("UIPadding",list); pad.PaddingLeft=UDim.new(0,6); pad.PaddingRight=UDim.new(0,12); pad.PaddingTop=UDim.new(0,4); pad.PaddingBottom=UDim.new(0,12)
local rowNumber=0
local function row(text,height,color)
 rowNumber=rowNumber+1; local f=panel(list,Vector2.new(680,height or 60),Vector2.zero,color or Color3.fromRGB(22,83,105),false); f.LayoutOrder=rowNumber
 local l=label(f,text,UDim2.new(1,-24,1,-8),UDim2.fromOffset(12,4),17); l.TextXAlignment=Enum.TextXAlignment.Left
 return f,l
end
local function action(text,color,fn)
 rowNumber=rowNumber+1; local b=button(list,text,680,52,color,fn); b.LayoutOrder=rowNumber; return b
end
local function open(name)
 if revealing then return end
 if activeMatch then notify("Finish your boss fight first."); return end
 page=name; window.Visible=true;dim.Visible=true; sound("Open",0.85); render()
 window.Position=UDim2.fromOffset(230,162); Tween:Create(window,TweenInfo.new(0.22,Enum.EasingStyle.Back),{Position=UDim2.fromOffset(230,145)}):Play()
end
-- Original geometric icons; no external assets need to load.
local function icon(parent,kind,color)
 local holder=Instance.new("Frame",parent); holder.Size=UDim2.fromOffset(60,50); holder.Position=UDim2.fromOffset(16,5); holder.BackgroundTransparency=1; holder.ZIndex=2
 local assets=folder:FindFirstChild("Assets")
 local icons=assets and assets:FindFirstChild("GUIIcons")
 local template=icons and icons:FindFirstChild(kind)
 if template and template:IsA("ImageLabel") and template.Image~="" then
  local image=template:Clone();image.Name="CustomIcon";image.Size=UDim2.fromScale(1,1);image.Position=UDim2.new();image.AnchorPoint=Vector2.new(0,0);image.Visible=true;image.Parent=holder
  return
 end
 if C.Icons[kind] and C.Icons[kind]~="" then
  local image=Instance.new("ImageLabel",holder);image.Size=UDim2.fromScale(1,1);image.BackgroundTransparency=1;image.Image=C.Icons[kind];image.ScaleType=Enum.ScaleType.Fit;return
 end
 local function piece(size,pos,tint,rot)
  local f=Instance.new("Frame",holder); f.Size=UDim2.fromOffset(size.X,size.Y); f.Position=UDim2.fromOffset(pos.X,pos.Y); f.BackgroundColor3=tint; f.Rotation=rot or 0; f.BorderSizePixel=0; corner(f,10); outline(f,palette.Ink,2); return f
 end
 if kind=="Shop" then
  piece(Vector2.new(42,28),Vector2.new(9,18),Color3.fromRGB(255,83,123),-10)
  for x=16,40,8 do piece(Vector2.new(4,16),Vector2.new(x,23),Color3.fromRGB(180,32,78),-10) end
  local handle=piece(Vector2.new(27,20),Vector2.new(17,6),Color3.fromRGB(255,156,180),-10); handle.BackgroundTransparency=1
 elseif kind=="Summon" then
  piece(Vector2.new(17,42),Vector2.new(22,1),palette.White,35)
  piece(Vector2.new(35,8),Vector2.new(9,30),palette.Gold,35)
  piece(Vector2.new(9,16),Vector2.new(11,35),palette.Pink,35)
 elseif kind=="Inventory" then
  piece(Vector2.new(34,40),Vector2.new(17,5),Color3.fromRGB(41,164,255),-15)
  piece(Vector2.new(26,34),Vector2.new(9,9),Color3.fromRGB(96,219,255),-15)
  piece(Vector2.new(18,3),Vector2.new(16,20),palette.White,-15)
  piece(Vector2.new(18,3),Vector2.new(17,27),palette.White,-15)
 elseif kind=="Cosmetics" then
  local orb=piece(Vector2.new(43,43),Vector2.new(9,2),Color3.fromRGB(211,112,255),0); corner(orb,24)
  piece(Vector2.new(22,22),Vector2.new(20,12),palette.White,45)
 elseif kind=="Wheel" then
  local disk=piece(Vector2.new(44,44),Vector2.new(8,2),palette.Mint,0); corner(disk,24)
  for _,rotation in ipairs({0,45,90,135}) do piece(Vector2.new(36,5),Vector2.new(12,22),palette.Gold,rotation) end
  local hub=piece(Vector2.new(12,12),Vector2.new(24,18),palette.White,0); corner(hub,8)
 else
  piece(Vector2.new(47,29),Vector2.new(7,12),palette.Gold,-12)
  label(holder,"#",UDim2.fromScale(1,1),UDim2.new(),36,palette.White)
 end
end
local bottomNav={}
local nav={{"SHOP","Shop",palette.Pink},{"SUMMON","Summon",palette.Gold},{"FIGHTERS","Inventory",palette.Cyan},{"AURAS","Cosmetics",Color3.fromRGB(183,71,255)},{"WHEEL","Wheel",palette.Mint},{"CODES","Codes",Color3.fromRGB(255,153,43)}}
for i,v in ipairs(nav) do
 local b=button(canvas,v[1],94,84,v[3],function() open(v[2]) end); b.Position=UDim2.fromOffset(285+(i-1)*105,666)
 table.insert(bottomNav,b)
 b.Label.Position=UDim2.fromOffset(0,56); b.Label.Size=UDim2.fromOffset(94,26); b.Label.TextSize=18
 icon(b,v[2],v[3])
end
local topShop=button(canvas,"SHOP",190,54,palette.Gold,function() open("Shop") end); topShop.Position=UDim2.fromOffset(400,7); topShop.Label.TextSize=30; gleam(topShop,190,54)
local duel=button(canvas,"BOSSES",190,54,palette.Mint,function() open("Bosses") end);duel.Position=UDim2.fromOffset(610,7);duel.Label.TextSize=29;gleam(duel,190,54)
local shop=button(canvas,"STARTER PACK",205,110,palette.Gold,function() selectedProduct="Starter"; open("Shop") end); shop.Position=UDim2.fromOffset(10,240); shop.Label.Position=UDim2.fromOffset(6,3); shop.Label.Size=UDim2.fromOffset(193,30); shop.Label.TextXAlignment=Enum.TextXAlignment.Left
label(shop,"Sasuke + 5 spins\n+ 1 boosted ticket",UDim2.fromOffset(190,43),UDim2.fromOffset(7,34),16)
local packOpen=button(shop,"VIEW PACK",110,25,palette.Mint,function() selectedProduct="Starter"; open("Shop") end); packOpen.Position=UDim2.fromOffset(85,80); packOpen.Label.TextSize=16; gleam(shop,205,110)
local quests=label(canvas,"BOSS GOALS",UDim2.fromOffset(205,32),UDim2.fromOffset(10,366),24,palette.Gold)
label(canvas,"Click to train strength\nEquip stronger fighters\nDefeat bosses for coins",UDim2.fromOffset(205,100),UDim2.fromOffset(10,403),18)
local practice=button(canvas,"BOSS CHALLENGES",205,43,palette.Mint,function() open("Bosses") end);practice.Position=UDim2.fromOffset(10,520)
local lastTrain=-math.huge
local function train()
 if not state or page or revealing or Input:GetFocusedTextBox() then return end
 if os.clock()-lastTrain<C.Training.Interval then return end
 lastTrain=os.clock();call("Train")
end
local trainButton=button(canvas,"CLICK TO TRAIN",310,60,palette.Gold,train);trainButton.Position=UDim2.fromOffset(445,530)
local strengthLabel=label(canvas,"STRENGTH 0",UDim2.fromOffset(420,32),UDim2.fromOffset(390,495),24,palette.Gold)
local bossLabel=label(canvas,"",UDim2.fromOffset(700,35),UDim2.fromOffset(250,150),24,palette.Pink)
local bossTrack=panel(canvas,Vector2.new(500,16),Vector2.new(350,189),palette.Ink,false);bossTrack.Visible=false
local bossFill=Instance.new("Frame",bossTrack);bossFill.Size=UDim2.fromScale(1,1);bossFill.BorderSizePixel=0;bossFill.BackgroundColor3=palette.Pink;corner(bossFill,8);gradient(bossFill,palette.Pink)
local leaveBoss=button(canvas,"LEAVE BOSS",185,38,palette.Pink,function() call("LeaveBoss") end);leaveBoss.Position=UDim2.fromOffset(10,570);leaveBoss.Visible=false
local function trainingHud()
 if not state then return end
 strengthLabel.Text="STRENGTH "..math.floor(state.Strength or 0).."  •  "..(state.BossDamage or 10).." DMG"
 trainButton.Label.Text=(activeMatch and "TRAIN + STRIKE" or "CLICK TO TRAIN").."  +"..(state.ClickGain or 1)
end
local function floating(text,color)
 local l=label(canvas,text,UDim2.fromOffset(230,40),UDim2.fromOffset(math.random(440,570),450),27,color);l.ZIndex=30
 Tween:Create(l,TweenInfo.new(.65),{Position=UDim2.fromOffset(math.random(400,600),350),TextTransparency=1,TextStrokeTransparency=1}):Play()
 game:GetService("Debris"):AddItem(l,.7)
end

local luck=button(canvas,"2x LUCK",185,110,Color3.fromRGB(184,64,255),function() selectedProduct="Luck"; open("Shop") end); luck.Position=UDim2.fromOffset(1004,250); luck.Label.Position=UDim2.fromOffset(5,8); luck.Label.Size=UDim2.fromOffset(175,37); luck.Label.TextSize=29
label(luck,"15-minute boost\nVIEW PACK",UDim2.fromOffset(175,50),UDim2.fromOffset(5,54),18,palette.Mint); gleam(luck,185,110)
local boost=button(canvas,"BOOSTED ROLL",185,110,palette.Cyan,function() selectedProduct="Boosted"; open("Shop") end); boost.Position=UDim2.fromOffset(1004,390); boost.Label.Position=UDim2.fromOffset(5,5); boost.Label.Size=UDim2.fromOffset(175,50); boost.Label.TextSize=24
label(boost,"One random fighter\nVIEW ODDS",UDim2.fromOffset(175,43),UDim2.fromOffset(5,60),18,palette.Gold); gleam(boost,185,110)
local buffIcon=panel(canvas,Vector2.new(66,76),Vector2.new(1121,671),Color3.fromRGB(134,50,230),true);buffIcon.Name="LuckBuffIcon";buffIcon.Visible=false
for _,xy in ipairs({{17,9},{32,9},{17,24},{32,24}}) do local leaf=panel(buffIcon,Vector2.new(18,18),Vector2.new(xy[1],xy[2]),palette.Mint,false);corner(leaf,10) end
local buffMultiplier=label(buffIcon,"2x",UDim2.fromOffset(30,24),UDim2.fromOffset(35,34),18)
local buffTimer=label(buffIcon,"",UDim2.fromOffset(64,23),UDim2.fromOffset(1,51),15)
local buffTip=label(canvas,"2x luck • boosts Rare+ odds",UDim2.fromOffset(240,32),UDim2.fromOffset(947,633),16,palette.White);buffTip.Visible=false
buffIcon.MouseEnter:Connect(function() buffTip.Visible=buffIcon.Visible end)
buffIcon.MouseLeave:Connect(function() buffTip.Visible=false end)
local function portrait(parent,id,pos,size,spin)
 local outfit=C.Outfits[id]
 local view=Instance.new("ViewportFrame",parent); view.Position=pos; view.Size=size; view.BackgroundTransparency=1; view.LightColor=Color3.new(1,1,1); view.Ambient=Color3.fromRGB(195,195,195); view.ZIndex=2
 local camera=Instance.new("Camera",view); camera.CFrame=CFrame.lookAt(Vector3.new(3,2,-7),Vector3.new(0,0.4,0)); camera.FieldOfView=34; view.CurrentCamera=camera
 local assets=folder:FindFirstChild("Assets");local models=assets and assets:FindFirstChild("CharacterModels");local custom=models and models:FindFirstChild(id)
 if custom and custom:IsA("Model") then
  local wm=Instance.new("WorldModel",view);local display=custom:Clone()
  for _,v in ipairs(display:GetDescendants()) do if v:IsA("LuaSourceContainer") then v:Destroy() elseif v:IsA("BasePart") then v.Anchored=true end end
  display.Parent=wm;display:PivotTo(CFrame.new())
  local cf,sz=display:GetBoundingBox();local distance=math.max(sz.X,sz.Y,sz.Z)*2
  camera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(distance*0.35,sz.Y*0.12,-distance),cf.Position)
  if spin then spinningPreviews[view]={Model=display,Base=display:GetPivot(),Started=os.clock()} end
  return view
 end
 if not outfit then outfit=C.Outfits.yamcha end
 local wm=Instance.new("WorldModel",view);local display=Instance.new("Model",wm);display.Name="CharacterPreview"
 local function block(name,sz,position,color)
  local b=Instance.new("Part"); b.Name=name; b.Size=sz; b.Position=position; b.Color=Color3.fromRGB(table.unpack(color)); b.Anchored=true; b.Parent=display; return b
 end
 block("Head",Vector3.new(1,1,1),Vector3.new(0,1.5,0),outfit.Skin)
 block("Body",Vector3.new(1.4,1.6,0.7),Vector3.new(0,0.2,0),outfit.Cloth)
 for _,side in ipairs({-1,1}) do
  block("Arm",Vector3.new(0.5,1.5,0.6),Vector3.new(side,0.2,0),outfit.Skin)
  block("Leg",Vector3.new(0.6,1.2,0.65),Vector3.new(side*0.36,-1.2,0),outfit.Cloth)
 end
 if not outfit.Bald then
  for i=-2,2 do local hair=block("Hair",Vector3.new(0.25,0.5,0.8),Vector3.new(i*0.2,2,0),outfit.Hair); hair.Rotation=Vector3.new(0,0,-i*12) end
 end
 if spin then spinningPreviews[view]={Model=display,Base=display:GetPivot(),Started=os.clock()} end
 return view
end
local function odds(cosmetic,boosted,forceLuck)
 local listItems=cosmetic and C.Cosmetics or C.Characters
 local normal=C.Odds(boosted,false,listItems); local luckyOdds=C.Odds(boosted,true,listItems)
 row("EXACT ITEM ODDS • "..(boosted and "BOOSTED" or "STANDARD").."\nEach row: without luck → with 2x luck. "..(state and state.Lucky and "2x currently active." or "Base odds currently active."),70)
 for _,item in ipairs(listItems) do
  local count=0; for _,v in ipairs(listItems) do if v.Tier==item.Tier and v.Rollable~=false then count=count+1 end end
  if item.Rollable==false then row(item.Name.." • STARTER PACK EXCLUSIVE • not in spin pool",46) else
  row(string.format("%s  •  %s   |   %.6f%%  →  %.6f%%",item.Name,C.Rarities[item.Tier],normal[item.Tier]/count,luckyOdds[item.Tier]/count),46) end
 end
 row("One item per roll. Independent results; no guaranteed Secret or pity. Duplicates stay in inventory: character duplicates +50 coins; cosmetic duplicates +5 gems. Probabilities are rounded; displayed totals may differ slightly from 100%.",90)
end
local wheelDisk
local adminButton=button(canvas,"ADMIN EVENTS",185,37,palette.Pink,function() open("Admin") end);adminButton.Position=UDim2.fromOffset(1004,610);adminButton.Visible=false
local function packArt(parent,kind)
 local art=Instance.new("Frame",parent);art.Size=UDim2.fromOffset(115,115);art.Position=UDim2.fromOffset(16,50);art.BackgroundTransparency=1
 if kind=="Luck" then
  for _,xy in ipairs({{25,18},{58,18},{25,51},{58,51}}) do local leaf=panel(art,Vector2.new(39,39),Vector2.new(xy[1],xy[2]),palette.Mint,false);corner(leaf,23);gradient(leaf,palette.Mint) end
  local stem=panel(art,Vector2.new(11,33),Vector2.new(53,76),palette.Mint,false);stem.Rotation=-18
 else
  local box=panel(art,Vector2.new(88,70),Vector2.new(12,35),kind=="Boosted" and palette.Cyan or palette.Pink,true);box.Rotation=-9
  local ribbon=panel(box,Vector2.new(14,70),Vector2.new(37,0),palette.Gold,false)
  local lid=panel(art,Vector2.new(100,21),Vector2.new(6,24),palette.Gold,true);lid.Rotation=-9
  for _,rotation in ipairs({-30,30}) do local bow=panel(art,Vector2.new(31,17),Vector2.new(42,8),palette.Gold,false);bow.Rotation=rotation end
 end
end
render=function()
 for _,v in ipairs(list:GetChildren()) do if v:IsA("GuiObject") then v:Destroy() end end
 list.CanvasPosition=Vector2.zero; rowNumber=0
 if not page then return end
 title.Text=page=="Shop" and "RIFT SHOP" or string.upper(page)
 local bannerGradient=banner:FindFirstChildOfClass("UIGradient")
 if bannerGradient then bannerGradient.Color=ColorSequence.new(page=="Shop" and Color3.fromRGB(255,119,191) or palette.Gold,page=="Shop" and Color3.fromRGB(223,25,81) or Color3.fromRGB(255,148,24)) end
 if not state then
  if folder:GetAttribute("ServerStatus")=="Error" then
   row("SERVER STARTUP ERROR\nOpen Studio Output to see the red error. Your data has not been replaced.",90)
   if Run:IsStudio() then row(tostring(folder:GetAttribute("StartupError") or "Unknown startup error"),150) end
  elseif os.clock()-loadingStarted>12 then row("Still waiting for the server. Use Play (F5), not Run. Check Studio Output if this continues.",85)
  else row("Connecting to your inventory...",60) end
  action("RETRY CONNECTION",palette.Mint,function() local r=call("State"); if r and r.State then apply(r.State) else render() end end)
  return
 end
 if page=="Summon" then
  row("MEET YOUR NEXT MAIN\nEvery roll adds one fighter to your collection. Equip them in Inventory.",65)
  local preview=row("",155)
  for i,id in ipairs({"naruto","aizen","ui_goku"}) do
   portrait(preview,id,UDim2.fromOffset(55+(i-1)*210,0),UDim2.fromOffset(140,125))
   local h=C.Find(C.Characters,id); label(preview,h.Name,UDim2.fromOffset(205,30),UDim2.fromOffset(17+(i-1)*218,122),17,h.Color)
  end
  action("SUMMON • "..C.SpinCost.." COINS",palette.Cyan,function() call("Spin","Coins") end)
  action("USE SPIN TICKET • "..state.Tickets.." available",palette.Gold,function() call("Spin","Ticket") end)
  action("BOOSTED SUMMON • "..state.Boosted.." available",palette.Pink,function() call("Spin","Boosted") end)
  action("VIEW BOOSTED ODDS",palette.Mint,function() open("Boosted odds") end)
  odds(false,false)
 elseif page=="Boosted odds" then odds(false,true)
 elseif page=="Cosmetic odds" then odds(true,true)
 elseif page=="Bosses" then
  row("CLICK → STRENGTH → BOSS COINS → BETTER FIGHTERS\nSolo boss fights. Dodge the warning circles! E guards; Q and R use skills.",75)
  for _,boss in ipairs(C.Bosses) do
   row(boss.Name.." • "..boss.Health.." HP\nReward: "..boss.Coins.." coins + "..C.Economy.GemsPerWin.." gems • Needs "..boss.Required.." strength",75)
   action("CHALLENGE "..boss.Name:upper(),boss.Color,function() call("Boss",boss.Id) end)
  end
 elseif page=="Inventory" then
  row("YOUR FIGHTERS • duplicates shown as × count\nClick an owned fighter to equip. Marlon is Super Secret. Sasuke comes from the Starter pack.",64)
  for first=1,#C.Characters,3 do
   local strip=row("",224); strip.BackgroundTransparency=1; local stroke=strip:FindFirstChildOfClass("UIStroke"); if stroke then stroke.Enabled=false end
   for column=0,2 do
    local item=C.Characters[first+column]
    if item then
     local n=state.Characters[item.Id] or 0
     local card=panel(strip,Vector2.new(213,218),Vector2.new(column*228,0),item.Color,true)
     portrait(card,item.Id,UDim2.fromOffset(25,23),UDim2.fromOffset(160,125))
     label(card,item.Name,UDim2.fromOffset(205,39),UDim2.fromOffset(4,0),18)
     label(card,C.Rarities[item.Tier].." • +"..C.ClickGain(item.Id).."/click • ×"..n,UDim2.fromOffset(205,32),UDim2.fromOffset(4,139),15)
     local equip=button(card,n==0 and "LOCKED" or (state.Equipped==item.Id and "EQUIPPED" or "EQUIP"),189,34,n>0 and palette.Mint or Color3.fromRGB(125,130,130),function() if n>0 then call("Equip",item.Id) else notify(item.Rollable==false and "Sasuke is guaranteed in the Starter pack." or "Unlock this fighter with character spins.") end end); equip.Position=UDim2.fromOffset(12,178); equip.Label.TextSize=18
    end
   end
  end
 elseif page=="Cosmetics" then
  row("AURA ATELIER\nOne cosmetic per spin. Equip for free. One aura slot; buffs never stack.",64)
  action("STANDARD AURA • "..C.Economy.CosmeticStandard.." GEMS",Color3.fromRGB(192,148,255),function() call("Cosmetic","Standard") end)
  action("BOOSTED AURA • "..C.Economy.CosmeticBoosted.." GEMS",palette.Pink,function() call("Cosmetic","Boosted") end)
  action("VIEW BOOSTED AURA ODDS",palette.Mint,function() open("Cosmetic odds") end)
  action("UNEQUIP AURA",palette.Cyan,function() call("Aura","") end)
  for _,item in ipairs(C.Cosmetics) do
   local n=state.Cosmetics[item.Id] or 0
   action(string.format("%s%s • %s • +%.1f%% damage / %.1f%% defense • ×%d",state.Aura==item.Id and "ON • " or "",item.Name,C.Rarities[item.Tier],item.Damage*100,item.Defense*100,n),n>0 and item.Color or Color3.fromRGB(128,132,150),function() if n>0 then call("Aura",item.Id) else notify("Spin for this aura first.") end end)
  end
  odds(true,false)
 elseif page=="Shop" then
  row("FIGHTER PACKS  •  Choose your rewards below",48)
  local keys={"Starter","Spins","Boosted","Luck"}
  for first=1,4,2 do
   local strip=row("",230);strip.BackgroundTransparency=1;local stripStroke=strip:FindFirstChildOfClass("UIStroke");if stripStroke then stripStroke.Enabled=false end
   for col=0,1 do
    local key=keys[first+col];local product=C.Products[key]
    local card=panel(strip,Vector2.new(328,222),Vector2.new(col*348,0),key=="Luck" and Color3.fromRGB(113,227,79) or key=="Boosted" and Color3.fromRGB(191,88,255) or key=="Spins" and Color3.fromRGB(61,197,255) or Color3.fromRGB(255,173,74),true)
    if key=="Starter" then portrait(card,"sasuke",UDim2.fromOffset(8,45),UDim2.fromOffset(128,110)) else packArt(card,key) end
    label(card,product.Name,UDim2.fromOffset(310,42),UDim2.fromOffset(9,0),24)
    label(card,product.Description,UDim2.fromOffset(173,91),UDim2.fromOffset(143,51),17)
    local choose=button(card,selectedProduct==key and "SELECTED • DETAILS BELOW" or "VIEW REWARDS + ODDS",300,39,palette.Mint,function() selectedProduct=key;render();list.CanvasPosition=Vector2.new(0,540) end);choose.Position=UDim2.fromOffset(14,172);choose.Label.TextSize=16
   end
  end
  local product=C.Products[selectedProduct]
  row("SELECTED: "..product.Name.."\n"..product.Description..". Packs are repeatable. Luck time continues while offline.",74)
  if state.Studio and C.StudioMemory then
   row("STUDIO TEST MODE • Temporary rewards; no Robux is spent.",48)
   local previewKey=selectedProduct
   action("TEST THIS PACK • STUDIO ONLY",palette.Cyan,function() call("PreviewProduct",previewKey) end)
  end
  local purchaseKey=selectedProduct
  local purchaseButton=action(product.Id==0 and "ROBUX PURCHASE NOT SET UP" or "Loading Roblox price...",palette.Mint,function()
   local response=call("Purchase",purchaseKey)
   if response and response.Ok and response.ProductId then Market:PromptProductPurchase(p,response.ProductId) end
  end)
  if product.Id>0 then task.spawn(function()
   local ok,info=pcall(function() return Market:GetProductInfoAsync(product.Id,Enum.InfoType.Product) end)
   if purchaseButton.Parent then purchaseButton.Label.Text=ok and info.IsForSale and ("BUY • "..tostring(info.PriceInRobux).." ROBUX") or "Unavailable on Roblox" end
  end) end
  if not state.PaidAllowed then row("Paid rolls and luck are unavailable for this account. You can still earn coins and gems, redeem codes, and spin without paid luck.",75) end
  row("2x luck doubles the actual probability of Rare and higher tiers. Standard Secret: 0.01% → 0.02%. Boosted Secret: 0.1% → 0.2%. Secrets split equally between all rollable Secret fighters. Marlon: 0.001% standard; 0.01% boosted; luck doubles both.",90)
  odds(false,false); odds(false,true)
  if selectedProduct=="Luck" then row("Luck also applies to cosmetic rolls:",40); odds(true,false); odds(true,true) end
 elseif page=="Admin" then
  row("ADMIN PANEL • Your Roblox user ID: "..tostring(p.UserId).."\n"..(state.IsOwner and "OWNER VERIFIED • Character grants enabled" or state.IsAdmin and "EVENT ACCESS • Owner setup needed for character grants" or "READ-ONLY • This account has no admin permission"),80)
  if not state.IsOwner then
   row("Stop Play. In Explorer: ReplicatedStorage → AnimeRift → AdminSettings → OwnerUserId. Set Value to your numeric user ID above, then Play again. Live commands still require server permission.",100)
  end
  local f=row("",62);local box=Instance.new("TextBox",f)
  box.Size=UDim2.new(1,-24,1,-12);box.Position=UDim2.fromOffset(12,6);box.BackgroundColor3=palette.White;box.TextColor3=palette.Ink;box.Font=Enum.Font.GothamBold;box.Text=adminDraft;box.PlaceholderText="marlon or give marlon";box.TextSize=22;box.ClearTextOnFocus=false;corner(box,10)
  box:GetPropertyChangedSignal("Text"):Connect(function() adminDraft=box.Text end)
  local function grant()
   local command=box.Text:lower():match("^%s*(.-)%s*$")
   if command=="" then notify("Enter a character ID, for example marlon.");return end
   if not command:match("^give%s+") then command="give "..command end
   call("Admin",command)
  end
  action("GIVE TO MYSELF",palette.Gold,grant)
  box.FocusLost:Connect(function(enterPressed) if enterPressed then grant() end end)
  if not state.IsAdmin then return end
  row("SERVER EVENT CONTROL • affects this server only. Gifts save; visual events expire.",65)
  for _,v in ipairs({{"random","SURPRISE EVENT!"},{"coins","COIN SHOWER • +"..C.Admin.CoinGift.." coins each"},{"gems","GEM PARTY • +"..C.Admin.GemGift.." gems each"},{"confetti","CONFETTI BLAST"},{"disco","RIFT DISCO"},{"resetwheel","RESET MY DAILY WHEEL"}}) do
   action(v[2],v[1]=="gems" and Color3.fromRGB(222,64,255) or palette.Mint,function() call("Admin",v[1]) end)
  end
 elseif page=="Codes" then
  row("RELEASE GIFTS\nRELEASE → 10,000 coins     /     AIZENGOKU → 1,000 gems",70)
  local f=row("",65)
  local box=Instance.new("TextBox",f); box.Size=UDim2.new(1,-24,1,-16); box.Position=UDim2.fromOffset(12,8); box.BackgroundColor3=palette.White; box.TextColor3=palette.Ink; box.TextSize=23; box.Font=Enum.Font.GothamBold; box.PlaceholderText="ENTER CODE"; box.Text=codeDraft; box.ClearTextOnFocus=false; corner(box,10)
  box:GetPropertyChangedSignal("Text"):Connect(function() codeDraft=box.Text end)
  action("REDEEM CODE",palette.Gold,function() call("Code",box.Text) end)
  row("Each code can be redeemed once per account. Your redeemed notification appears at the top of the screen.",66)
 elseif page=="Wheel" then
  row("DAILY FREE WHEEL\nOne free spin each UTC day. No Robux spins, no purchase required.",65)
  local f=row("",300)
  wheelDisk=Instance.new("Frame",f); wheelDisk.Size=UDim2.fromOffset(260,260); wheelDisk.Position=UDim2.fromOffset(210,20); wheelDisk.BackgroundColor3=palette.Pink; corner(wheelDisk,130); outline(wheelDisk,palette.Gold,8); studs(wheelDisk,240,240,42)
  for slot,index in ipairs(C.WheelLayout()) do
   local colors={palette.Mint,palette.Gold,Color3.fromRGB(221,64,255),palette.Cyan}
   local sector=Instance.new("Frame",wheelDisk);sector.Size=UDim2.fromScale(1,1);sector.BackgroundTransparency=1;sector.Rotation=(slot-1)*18
   local spoke=Instance.new("Frame",sector);spoke.AnchorPoint=Vector2.new(0.5,1);spoke.Size=UDim2.fromOffset(28,120);spoke.Position=UDim2.fromOffset(130,130);spoke.BackgroundColor3=colors[index];spoke.BorderSizePixel=1;spoke.BorderColor3=palette.Ink;spoke.Rotation=0;corner(spoke,4)
   local text=label(spoke,(C.Wheel[index].Gems and (C.Wheel[index].Gems.."G") or tostring(C.Wheel[index].Coins or "?")),UDim2.fromOffset(28,20),UDim2.fromOffset(0,4),11);text.Rotation=0
  end
  local hub=panel(wheelDisk,Vector2.new(96,96),Vector2.new(82,82),palette.Gold,true);corner(hub,50)
  label(hub,"DAILY\nSPIN",UDim2.fromScale(1,1),UDim2.new(),23)
  local pointer=Instance.new("Frame",f); pointer.Size=UDim2.fromOffset(22,22); pointer.Position=UDim2.fromOffset(329,4); pointer.Rotation=45; pointer.BackgroundColor3=palette.Gold; pointer.ZIndex=4; outline(pointer,palette.Ink,2)
  wheelButton=action(wheelSpinning and "SPINNING..." or state.WheelReady and "SPIN FREE" or "CLAIMED • RESETS AT 00:00 UTC",palette.Mint,function()
   if wheelSpinning then return end
   if not state.WheelReady then notify("Your next free spin unlocks at 00:00 UTC.");return end
   wheelSpinning=true;wheelButton.Label.Text="SPINNING..."
   local result=call("Wheel")
   if not result or not result.Ok then wheelSpinning=false;if page=="Wheel" then render() end end
  end)
  local disclosure={};for _,prize in ipairs(C.Wheel) do table.insert(disclosure,prize.Name..": "..prize.Weight.."%") end
  row(table.concat(disclosure," • "),60)
 end
end
local combatBar=panel(canvas,Vector2.new(650,90),Vector2.new(275,640),palette.Ink,true); combatBar.Visible=false
local combatButtons={}
for i,key in ipairs({"M1","Q","E","R"}) do
 local b=button(combatBar,key,146,64,({palette.Cyan,palette.Gold,palette.Mint,palette.Pink})[i],function() if key=="M1" then train() else call("Attack",key) end end); b.Position=UDim2.fromOffset(12+(i-1)*160,13); combatButtons[key]=b
end
local health=label(canvas,"",UDim2.fromOffset(700,35),UDim2.fromOffset(250,600),21,palette.Mint); health.TextStrokeTransparency=0.1
local reveal=panel(canvas,Vector2.new(630,360),Vector2.new(285,210),palette.Pink,true); reveal.ZIndex=50; reveal.Visible=false
local revealTier=label(reveal,"",UDim2.fromOffset(590,45),UDim2.fromOffset(20,12),27,palette.White)
local revealName=label(reveal,"",UDim2.fromOffset(590,45),UDim2.fromOffset(20,242),29,palette.White)
local revealSub=label(reveal,"",UDim2.fromOffset(590,30),UDim2.fromOffset(20,285),17,palette.White)
local stage=Instance.new("Frame",reveal);stage.Size=UDim2.fromOffset(590,190);stage.Position=UDim2.fromOffset(20,52);stage.BackgroundTransparency=1
local done=button(reveal,"KEEP IT!",220,36,palette.Mint,function()
 reveal.Visible=false;revealing=false;stopSummonSound()
 for _,v in ipairs(stage:GetChildren()) do v:Destroy() end
 if #revealQueue>0 then local nextItem=table.remove(revealQueue,1);playReveal(nextItem) end
end);done.Position=UDim2.fromOffset(205,316)
playReveal=function(data)
 if revealing then table.insert(revealQueue,data);return end
 revealing=true;reveal.Visible=true;done.Visible=false
 for _,v in ipairs(stage:GetChildren()) do v:Destroy() end
 local item=C.Find(data.Kind=="Character" and C.Characters or C.Cosmetics,data.Id)
 if not item then revealing=false;reveal.Visible=false;notify("Unknown reward. Reopen inventory to refresh.");return end
 local tint=reveal:FindFirstChildOfClass("UIGradient");if tint then tint.Color=ColorSequence.new(item.Color,item.Color:Lerp(Color3.new(0,0,0),0.5)) end
 revealTier.Text="WHAT'S INSIDE?";revealName.Text="A new power is waking up...";revealSub.Text=""
 local crate=panel(stage,Vector2.new(136,116),Vector2.new(227,50),palette.Gold,true)
 local strap=panel(crate,Vector2.new(23,116),Vector2.new(57,0),palette.Pink,false)
 local lid=panel(crate,Vector2.new(152,27),Vector2.new(-8,-13),palette.Gold,true)
 task.spawn(function()
  local started=os.clock();local tick=0
  while os.clock()-started<C.UI.RevealShakeSeconds do
   tick=tick+1;crate.Rotation=tick%2==0 and 9 or -9
   sound("Shake",0.65+tick*0.025);task.wait(0.11)
  end
  crate.Rotation=0;Polish.Pulse(.32);sound("Reveal",1.3)
  Tween:Create(lid,TweenInfo.new(0.35,Enum.EasingStyle.Back),{Position=UDim2.fromOffset(-8,-105),Rotation=-25,BackgroundTransparency=1}):Play()
  task.wait(0.35);crate:Destroy()
  local customSound=data.Kind=="Character" and characterSummonSound(item.Id)
  revealTier.Text=string.upper(C.Rarities[item.Tier]).." UNLOCKED!"
  if data.Kind=="Character" then portrait(stage,item.Id,UDim2.fromOffset(175,-12),UDim2.fromOffset(240,205),true)
  else
   local aura=panel(stage,Vector2.new(120,120),Vector2.new(235,28),item.Color,true);corner(aura,65)
   label(aura,"AURA",UDim2.fromScale(1,1),UDim2.new(),27)
  end
  for i=1,22 do
   local spark=Instance.new("Frame",stage);spark.Size=UDim2.fromOffset(7,14);spark.Position=UDim2.fromOffset(295,80);spark.BackgroundColor3=C.Colors[(i%6)+1];spark.Rotation=i*23;spark.BorderSizePixel=0
   Tween:Create(spark,TweenInfo.new(0.9),{Position=UDim2.fromOffset(295+math.cos(i)*260,70+math.sin(i)*100),BackgroundTransparency=1,Rotation=i*40}):Play()
   game:GetService("Debris"):AddItem(spark,1)
  end
  revealName.Text=item.Name;revealSub.Text="Saved to your collection. Equip it from inventory.";done.Visible=true;if not customSound then sound("Reward",1.6) end
 end)
end
local eventSerial=0
local function party(data)
 eventSerial=eventSerial+1;local serial=eventSerial;notify(data.Text);sound("Reward",1.1)
 local layer=Instance.new("Frame",canvas);layer.Size=UDim2.fromScale(1,1);layer.BackgroundTransparency=1;layer.ZIndex=90
 local lighting=game:GetService("Lighting");local color
 if data.Kind=="disco" then color=Instance.new("ColorCorrectionEffect",lighting);color.Name="RiftParty" end
 task.spawn(function()
  local untilTime=os.clock()+data.Duration
  while os.clock()<untilTime and serial==eventSerial do
   if color then color.TintColor=Color3.fromHSV((os.clock()*0.2)%1,0.35,1) end
   local piece=Instance.new("Frame",layer);piece.Size=UDim2.fromOffset(10,20);piece.Position=UDim2.fromOffset(math.random(0,1200),-30);piece.BackgroundColor3=data.Kind=="coins" and palette.Mint or data.Kind=="gems" and Color3.fromRGB(235,61,255) or C.Colors[math.random(1,6)];piece.BorderSizePixel=0
   Tween:Create(piece,TweenInfo.new(2),{Position=piece.Position+UDim2.fromOffset(math.random(-80,80),820),Rotation=math.random(-360,360)}):Play();game:GetService("Debris"):AddItem(piece,2.1);task.wait(0.08)
  end
  if color then color:Destroy() end;task.wait(2.2);layer:Destroy()
 end)
end
apply=function(s)
 if not s then return end; state=s; offset=s.ServerTime-os.time()
 currencies.Text=string.format("%s COINS",s.Coins)
 gemsLabel.Text=string.format("%s GEMS",s.Gems);winsLabel.Text=s.Wins.." WINS"
 adminButton.Visible=s.IsAdmin==true or s.Studio==true
 duel.Label.Text="BOSSES";trainingHud()
 if not activeMatch then status.Text="" end
 if page and not (page=="Wheel" and wheelSpinning) then local scroll=list.CanvasPosition;render();list.CanvasPosition=scroll end
end
Event.OnClientEvent:Connect(function(kind,data)
 if kind=="State" then apply(data)
 elseif kind=="Training" then
  if state then state.Strength=data.Strength;state.ClickGain=data.ClickGain;state.BossDamage=data.Damage;trainingHud() end
  if data.Gain>0 then floating("+"..data.Gain.." STRENGTH",palette.Gold) end;Polish.Train(p.Character,state and state.Equipped);sound("Click",1.15)
 elseif kind=="BossState" then bossLabel.Text=data.Name.."  "..math.ceil(data.Health).." / "..data.MaxHealth.." HP";Tween:Create(bossFill,TweenInfo.new(.16,Enum.EasingStyle.Quad),{Size=UDim2.fromScale(math.clamp(data.Health/math.max(1,data.MaxHealth),0,1),1)}):Play()
 elseif kind=="BossHit" then floating("−"..data.Damage.." BOSS HP",palette.Pink);Polish.Pulse(.12)
 elseif kind=="OpenMenu" then open(data)
 elseif kind=="Toast" then notify(data)
 elseif kind=="Reveal" then playReveal(data)
 elseif kind=="AdminEvent" then party(data)
 elseif kind=="CombatSound" then sound("Click",data=="R" and 0.5 or 0.9)
 elseif kind=="WheelResult" then
  wheelSpinning=true
  local disk=wheelDisk
  local target=2160-(data.Slot-1)*18
  if disk and disk.Parent then Tween:Create(disk,TweenInfo.new(C.UI.WheelSeconds,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Rotation=target}):Play() end
  task.spawn(function()
   for i=1,18 do sound("WheelTick",1.1);task.wait(C.UI.WheelSeconds/18) end
  end)
  task.delay(C.UI.WheelSeconds+0.1,function()
   wheelSpinning=false;sound("Reward",1.4);notify("WHEEL REWARD • "..data.Name)
   if page=="Wheel" and wheelButton and wheelButton.Parent then wheelButton.Label.Text="CLAIMED • RESETS AT 00:00 UTC" end
  end)
 elseif kind=="MatchStart" then
  page=nil; window.Visible=false; dim.Visible=false; reveal.Visible=false; activeMatch={Opponent=data.Opponent,Start=os.clock()+data.Countdown,End=os.clock()+data.Countdown+data.Duration}; combatBar.Visible=true; bottom.Visible=false; for _,b in ipairs(bottomNav) do b.Visible=false end; cooldowns={};trainingHud()
 elseif kind=="MatchEnd" then activeMatch=nil;bossLabel.Text="";trainingHud(); combatBar.Visible=false; bottom.Visible=true; for _,b in ipairs(bottomNav) do b.Visible=true end; health.Text=""; status.Text=""; notify(data); task.spawn(function() local r=call("State"); if r then apply(r.State) end end)
 elseif kind=="Cooldown" then cooldowns[data.Key]=os.clock()+data.Time end
end)
Input.InputBegan:Connect(function(input,processed)
 if not processed and input.KeyCode==Enum.KeyCode.F8 then open("Admin");return end
 if not processed and input.KeyCode==Enum.KeyCode.Escape and page then page=nil;window.Visible=false;dim.Visible=false;return end
 if processed or page or revealing or Input:GetFocusedTextBox() then return end
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then train();return end
 if not activeMatch then return end
 local key=input.UserInputType==Enum.UserInputType.MouseButton1 and "M1" or input.KeyCode.Name
 if C.Cooldowns[key] then call("Attack",key) end
end)
-- Entering a starter-pack area opens its menu once; leave and re-enter to reopen.
local shownPrompts={}
Prompts.PromptShown:Connect(function(prompt)
 if prompt:GetAttribute("RiftAction")=="Shop" and not shownPrompts[prompt] then
  shownPrompts[prompt]=true
  if not activeMatch and not page then selectedProduct="Starter"; open("Shop") end
 end
end)
Prompts.PromptHidden:Connect(function(prompt) shownPrompts[prompt]=nil end)
folder:GetAttributeChangedSignal("ServerStatus"):Connect(function() if page and not state then render() end end)
local lastTick=0
Run.RenderStepped:Connect(function()
 local now=os.clock()
 for layer,spacing in pairs(movingPatterns) do
  if layer.Parent then layer.Position=UDim2.fromOffset((now*C.UI.StudSlideSpeed)%spacing-spacing,0) else movingPatterns[layer]=nil end
 end
 for view,spin in pairs(spinningPreviews) do
  if view.Parent and spin.Model.Parent then
   spin.Model:PivotTo(spin.Base*CFrame.Angles(0,(now-spin.Started)*math.rad(C.UI.RevealSpinSpeed),0))
  else spinningPreviews[view]=nil end
 end
 if os.clock()-lastTick<0.1 then return end; lastTick=os.clock()
 if state then
  if not state.WheelReady and math.floor((os.time()+offset)/86400)>math.floor(state.ServerTime/86400) and not busy and not wheelSpinning then
   state.ServerTime=os.time()+offset;task.spawn(function() local result=call("State");if result and result.State then apply(result.State) end end)
  end
  local time=math.max(0,state.LuckUntil-(os.time()+offset))
  buffIcon.Visible=time>0 and state.PaidAllowed
  buffTimer.Text=string.format("%02d:%02d",math.floor(time/60),time%60)
  if not buffIcon.Visible then buffTip.Visible=false end
  if state.Lucky and time==0 then state.Lucky=false; if page then render() end end
 end
 dim.Visible=window.Visible and not revealing
 trainButton.Visible=state~=nil and page==nil and not revealing
 strengthLabel.Visible=trainButton.Visible;leaveBoss.Visible=activeMatch~=nil;bossLabel.Visible=activeMatch~=nil;bossTrack.Visible=activeMatch~=nil
 if activeMatch then
  local before=activeMatch.Start-os.clock()
  status.Text=before>0 and ("GET READY • "..math.ceil(before)) or ("VS "..activeMatch.Opponent.."  •  "..math.max(0,math.ceil(activeMatch.End-os.clock())).."s")
  local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  health.Text=h and string.format("HP %d / %d",math.ceil(h.Health),h.MaxHealth) or ""
  local hero=state and C.Find(C.Characters,state.Equipped)
  for i,key in ipairs({"M1","Q","E","R"}) do
   local left=math.max(0,(cooldowns[key] or 0)-os.clock())
   combatButtons[key].Label.Text=left>0 and string.format("%s • %.1fs",key,left) or (key.."\n"..(i==1 and "Train + Strike" or (hero and hero.Skills[i-1] or "")))
  end
 end
end)
task.spawn(function()
 while not state do local result=call("State"); if result and result.State then apply(result.State) end; if not state then if page then render() end; task.wait(2) end end
 notify("Welcome to Anime Rift! Your first random fighter is ready.")
 sound("Open",1.2)
end)

local function bindCamera(character)
 local humanoid=character:WaitForChild("Humanoid",10)
 if humanoid and p.Character==character and workspace.CurrentCamera then
  workspace.CurrentCamera.CameraType=Enum.CameraType.Custom
  workspace.CurrentCamera.CameraSubject=humanoid
 end
end
p.CharacterAdded:Connect(function(character) task.spawn(bindCamera,character) end)
if p.Character then task.spawn(bindCamera,p.Character) end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
 if workspace.CurrentCamera then resize();workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
 if p.Character then task.spawn(bindCamera,p.Character) end
end)
