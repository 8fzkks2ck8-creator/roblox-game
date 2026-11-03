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
local Layout=require(folder:WaitForChild("ClientLayout"))
local TitleScreen=require(folder:WaitForChild("TitleScreen"))
local OutfitDetails=require(folder:WaitForChild("OutfitDetails"))
local IdleMotion=require(folder:WaitForChild("IdleMotion"))
local Request=folder:WaitForChild("Request"); local Event=folder:WaitForChild("Event")
local ui=Instance.new("ScreenGui"); ui.Name="AnimeRiftUI"; ui.ResetOnSpawn=false; ui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; ui.Parent=p:WaitForChild("PlayerGui")
local canvas=Instance.new("Frame",ui); canvas.Size=UDim2.fromOffset(1200,760); canvas.AnchorPoint=Vector2.new(0.5,0.5); canvas.Position=UDim2.fromScale(0.5,0.5); canvas.BackgroundTransparency=1
canvas.Visible=false
local titleActive=true
local titleScreen
local scale=Instance.new("UIScale",canvas)
local state,page,render
local renderInventory
local searchDraft=""
local recycleUntil=0
local relayout
local metrics=Layout.Measure(1200,810)
local modalPosition=UDim2.fromOffset(230,110)
local function resize()
 local camera=workspace.CurrentCamera;if not camera then return end
 metrics=Layout.Measure(camera.ViewportSize.X,camera.ViewportSize.Y)
 canvas.Size=UDim2.fromOffset(metrics.Width,metrics.Height);scale.Scale=metrics.Scale
 modalPosition=UDim2.fromOffset(metrics.WindowX,metrics.WindowY)
 if relayout then relayout();if page and render then render() end end
end
local viewportConnection
resize();if workspace.CurrentCamera then viewportConnection=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
local palette={Ink=Color3.fromRGB(4,7,8),Panel=Color3.fromRGB(31,36,38),Cyan=Color3.fromRGB(42,211,255),Pink=Color3.fromRGB(255,64,148),Gold=Color3.fromRGB(255,203,47),White=Color3.fromRGB(255,255,255),Mint=Color3.fromRGB(123,241,43)}
local open
local closeMenu
local menuSerial=0
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
local busy=false; local selectedProduct="Starter"; local offset=0; local toastSerial=0
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
local function corner(obj,r) local c=obj:FindFirstChildOfClass("UICorner") or Instance.new("UICorner",obj); c.CornerRadius=UDim.new(0,r or 12) end
local function outline(obj,color,thickness) local s=Instance.new("UIStroke",obj); s.Color=color or palette.Ink; s.Thickness=thickness or 3; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border end
local function label(parent,text,size,pos,textsize,color)
 local t=Instance.new("TextLabel",parent); t.Size=size; t.Position=pos or UDim2.new(); t.BackgroundTransparency=1; t.Text=text; t.Font=Enum.Font.FredokaOne; t.TextSize=textsize or 18; t.TextColor3=color or palette.White; t.TextWrapped=true; t.ZIndex=3; t.TextStrokeColor3=Color3.new(0,0,0); t.TextStrokeTransparency=.05; local stroke=Instance.new("UIStroke",t); stroke.Color=Color3.new(0,0,0); stroke.Thickness=1.2; return t
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
 local mask=Instance.new("Frame",parent);mask.Name="CheckerMask";mask.Size=UDim2.fromScale(1,1);mask.BackgroundTransparency=1;mask.ClipsDescendants=true;mask.Active=false;mask.ZIndex=1;corner(mask,7)
 local tile=math.max(18,math.ceil(math.sqrt(width*height/80)))
 for y=0,math.ceil(height/tile)-1 do for x=0,math.ceil(width/tile)-1 do
  if (x+y)%2==0 then
   local square=Instance.new("Frame",mask);square.Size=UDim2.fromOffset(tile,tile);square.Position=UDim2.fromOffset(x*tile,y*tile);square.BackgroundColor3=Color3.new(1,1,1);square.BackgroundTransparency=.84;square.BorderSizePixel=0;square.Active=false
   local shine=Instance.new("Frame",square);shine.Size=UDim2.new(1,-4,0,2);shine.Position=UDim2.fromOffset(2,1);shine.BackgroundColor3=palette.White;shine.BackgroundTransparency=.55;shine.BorderSizePixel=0
   local shade=Instance.new("Frame",square);shade.Size=UDim2.new(1,-2,0,2);shade.Position=UDim2.new(0,1,1,-2);shade.BackgroundColor3=palette.Ink;shade.BackgroundTransparency=.78;shade.BorderSizePixel=0
  end
 end end
end
local function gleam(parent,w,h)
 for _,pos in ipairs({Vector2.new(3,h-3),Vector2.new(w-3,3)}) do
  local line=Instance.new("Frame",parent); line.Size=UDim2.fromOffset(26,2); line.Position=UDim2.fromOffset(pos.X-13,pos.Y); line.BackgroundColor3=Color3.new(1,1,1); line.BorderSizePixel=0; line.ZIndex=5
  local vertical=line:Clone(); vertical.Size=UDim2.fromOffset(2,22); vertical.Position=UDim2.fromOffset(pos.X,pos.Y-10); vertical.Parent=parent
 end
end
local function panel(parent,size,pos,color,pattern)
 local f=Instance.new("Frame",parent); f.Size=UDim2.fromOffset(size.X,size.Y); f.Position=UDim2.fromOffset(pos.X,pos.Y); f.BackgroundColor3=color or palette.Panel; f.BorderSizePixel=0; corner(f,7); outline(f,palette.Ink,3)
 if pattern then gradient(f,color or palette.Panel); studs(f,size.X,size.Y,20) end
 return f
end
local function button(parent,text,width,height,color,fn)
 local b=Instance.new("TextButton",parent); b.Size=UDim2.fromOffset(width,height); b.BackgroundColor3=color or palette.Cyan; b.Text=""; b.AutoButtonColor=false; b.BorderSizePixel=0; corner(b,math.min(16,height/2)); outline(b,palette.Ink,3)
 gradient(b,color or palette.Cyan)
 local inset=Instance.new("Frame",b);inset.Name="Inset";inset.Position=UDim2.fromOffset(3,3);inset.Size=UDim2.new(1,-6,1,-6);inset.BackgroundTransparency=1;inset.Active=false;corner(inset,math.min(12,height/2));local rim=Instance.new("UIStroke",inset);rim.Color=palette.White;rim.Transparency=.25;rim.Thickness=1.5
 if string.find(text,"GEMS") or string.find(text,"GEM PARTY") then b:FindFirstChildOfClass("UIGradient").Color=ColorSequence.new(Color3.fromRGB(174,86,255),Color3.fromRGB(255,53,202))
 elseif string.find(text,"COINS") or string.find(text,"BUY") then b:FindFirstChildOfClass("UIGradient").Color=ColorSequence.new(Color3.fromRGB(183,255,105),Color3.fromRGB(44,220,59)) end
 studs(b,width,height,20)
 local t=label(b,text,UDim2.new(1,-14,1,-6),UDim2.fromOffset(7,0),20,palette.White); t.Name="Label"
 local s=Instance.new("UIScale",b)
 b.MouseEnter:Connect(function() Tween:Create(s,TweenInfo.new(0.16,Enum.EasingStyle.Back),{Scale=1.035}):Play() end)
 b.MouseLeave:Connect(function() Tween:Create(s,TweenInfo.new(0.12),{Scale=1}):Play() end)
 b.Activated:Connect(function() sound("Click",1.7); Tween:Create(s,TweenInfo.new(0.08,Enum.EasingStyle.Back),{Scale=0.96}):Play(); task.delay(0.1,function() if s.Parent then Tween:Create(s,TweenInfo.new(0.16),{Scale=1}):Play() end end); fn() end)
 return b
end
local toast=panel(canvas,Vector2.new(900,40),Vector2.new(150,-65),palette.Panel,false); toast.AnchorPoint=Vector2.new(.5,0);toast.BackgroundTransparency=.08; toast.ZIndex=100; toast.Visible=false
local toastText=label(toast,"",UDim2.new(1,-20,1,0),UDim2.fromOffset(10,0),22,palette.Mint)
local function notify(text)
 toastSerial=toastSerial+1; local serial=toastSerial; toastText.Text=text; toast.Visible=true; toast.Position=UDim2.new(.5,0,0,-65)
 Tween:Create(toast,TweenInfo.new(0.35,Enum.EasingStyle.Back),{Position=UDim2.new(.5,0,0,metrics.Portrait and 255 or 78)}):Play()
 task.delay(4,function() if toastSerial==serial then Tween:Create(toast,TweenInfo.new(0.2),{Position=UDim2.new(.5,0,0,-65)}):Play(); task.wait(0.2); if toastSerial==serial then toast.Visible=false end end end)
end
local function call(action,arg)
 if titleActive and action~="State" then return end
 if revealing and action~="State" then notify("Finish your character reveal first."); return end
 if busy then if action~="State" and action~="Train" then notify("Finishing your previous action...") end; return end
 if folder:GetAttribute("ServerStatus")=="Error" then
  notify("Server could not start. Check Studio Output for the red error."); return
 end
 local ownsBusy=true
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
local header=panel(canvas,Vector2.new(246,100),Vector2.new(12,648),palette.Panel,true);header.BackgroundTransparency=.08
local currencies=label(header,"CONNECTING...",UDim2.fromOffset(230,37),UDim2.fromOffset(8,0),26,palette.Mint); currencies.TextXAlignment=Enum.TextXAlignment.Left
textGradient(currencies,Color3.fromRGB(202,255,130),Color3.fromRGB(35,221,50))
local gemsLabel=label(header,"GEMS",UDim2.fromOffset(230,32),UDim2.fromOffset(8,38),24);gemsLabel.TextXAlignment=Enum.TextXAlignment.Left
textGradient(gemsLabel,Color3.fromRGB(210,115,255),Color3.fromRGB(255,42,215))
local winsLabel=label(header,"",UDim2.fromOffset(230,22),UDim2.fromOffset(8,72),16);winsLabel.TextXAlignment=Enum.TextXAlignment.Left
local coinCounter=Instance.new("NumberValue",header)
local gemCounter=Instance.new("NumberValue",header)
coinCounter.Changed:Connect(function(v) currencies.Text=Layout.Number(v).." COINS" end)
gemCounter.Changed:Connect(function(v) gemsLabel.Text=Layout.Number(v).." GEMS" end)
gemsLabel.Text="0 GEMS"
local coinTween,gemTween
local logo=label(canvas,"ANIME RIFT",UDim2.fromOffset(245,55),UDim2.fromOffset(10,10),32,palette.Gold)
local bottom=label(canvas,"CLICK • SELL • SUMMON • REBIRTH",UDim2.fromOffset(650,30),UDim2.fromOffset(275,630),16)
local status=label(canvas,"",UDim2.fromOffset(720,36),UDim2.fromOffset(240,108),21,palette.Gold)
local dim=Instance.new("TextButton",canvas);dim.Name="ModalBackdrop";dim.Size=UDim2.fromScale(1,1);dim.BackgroundColor3=Color3.fromRGB(9,24,46);dim.BackgroundTransparency=.4;dim.Text="";dim.AutoButtonColor=false;dim.ZIndex=8;dim.Visible=false
local window=panel(canvas,Vector2.new(1000,580),Vector2.new(100,90),palette.Panel,false); window.ZIndex=10; window.Visible=false; window.BackgroundTransparency=0.04
local innerFrame=Instance.new("Frame",window);innerFrame.Size=UDim2.new(1,-10,1,-10);innerFrame.Position=UDim2.fromOffset(5,5);innerFrame.BackgroundTransparency=1;innerFrame.Active=false;corner(innerFrame,9);outline(innerFrame,palette.White,2)
local banner=panel(window,Vector2.new(996,72),Vector2.new(2,2),Color3.fromRGB(255,148,26),true); gleam(banner,736,62)
local title=label(banner,"",UDim2.fromOffset(365,58),UDim2.fromOffset(16,0),34,palette.White); title.TextXAlignment=Enum.TextXAlignment.Left
local close=button(banner,"X",58,56,Color3.fromRGB(255,66,45),function() closeMenu() end); close.Position=UDim2.fromOffset(674,3); close.Label.TextSize=38
closeMenu=function()
 menuSerial+=1;local serial=menuSerial;page=nil
 local focused=Input:GetFocusedTextBox();if focused and focused:IsDescendantOf(window) then focused:ReleaseFocus() end
 Tween:Create(window,TweenInfo.new(.13,Enum.EasingStyle.Quad),{Position=modalPosition+UDim2.fromOffset(0,18)}):Play()
 task.delay(.13,function() if serial==menuSerial then window.Visible=false;dim.Visible=false end end)
end
dim.Activated:Connect(function() closeMenu() end)
local list=Instance.new("ScrollingFrame",window); list.Position=UDim2.fromOffset(16,77); list.Size=UDim2.fromOffset(708,388); list.BackgroundTransparency=1; list.BorderSizePixel=0; list.ScrollBarThickness=6; list.ScrollBarImageColor3=palette.Cyan; list.AutomaticCanvasSize=Enum.AutomaticSize.Y; list.CanvasSize=UDim2.new(); list.ClipsDescendants=true
local layout=Instance.new("UIListLayout",list); layout.Padding=UDim.new(0,12); layout.SortOrder=Enum.SortOrder.LayoutOrder
local pad=Instance.new("UIPadding",list); pad.PaddingLeft=UDim.new(0,6); pad.PaddingRight=UDim.new(0,12); pad.PaddingTop=UDim.new(0,4); pad.PaddingBottom=UDim.new(0,12)
local menuMoney=label(banner,"",UDim2.fromOffset(230,50),UDim2.fromOffset(420,5),21,palette.Gold);menuMoney.TextXAlignment=Enum.TextXAlignment.Right
local tabs={}
for i,data in ipairs({{"Fighters","Inventory"},{"Auras","Cosmetics"},{"Store","Shop"}}) do
 local tab=button(window,data[1],228,42,i==3 and palette.Mint or Color3.fromRGB(146,158,176),function() open(data[2]) end)
 tab.Position=UDim2.fromOffset(16+(i-1)*238,480);tabs[data[2]]=tab
end
local rowNumber=0
local inventoryTools=panel(window,Vector2.new(968,58),Vector2.new(16,84),Color3.fromRGB(20,24,26),false);inventoryTools.Visible=false
local bestButton=button(inventoryTools,"Equip Best",200,44,palette.Mint,function() call("EquipBest") end)
local unequipButton=button(inventoryTools,"Unequip All",206,44,palette.Gold,function() call("UnequipAll") end)
local search=Instance.new("TextBox",inventoryTools);search.Name="InventorySearch";search.Size=UDim2.fromOffset(422,44);search.Position=UDim2.fromOffset(430,7);search.BackgroundColor3=Color3.fromRGB(31,35,37);search.TextColor3=palette.White;search.Font=Enum.Font.FredokaOne;search.TextSize=22;search.Text="";search.PlaceholderText="Search fighters...";search.PlaceholderColor3=Color3.fromRGB(197,201,203);search.ClearTextOnFocus=false;corner(search,5);outline(search,palette.Ink,3)
search:GetPropertyChangedSignal("Text"):Connect(function()
 searchDraft=search.Text
 if page=="Inventory" and state and renderInventory then renderInventory() end
end)
local recycleButton
recycleButton=button(inventoryTools,"Recycle",100,44,palette.Pink,function()
 if os.clock()>recycleUntil then
  recycleUntil=os.clock()+8;recycleButton.Label.Text="Confirm";notify("Click Confirm to recycle extra copies for coins. One of every fighter stays.")
  task.delay(8,function() if os.clock()>=recycleUntil and recycleButton.Parent then recycleButton.Label.Text="Recycle" end end)
 else
  recycleUntil=0;recycleButton.Label.Text="Recycle";call("RecycleDuplicates")
 end
end);recycleButton.Label.TextSize=17
local contentWidth=metrics.WindowWidth-64
local function row(text,height,color)
 rowNumber=rowNumber+1; local f=panel(list,Vector2.new(contentWidth,height or 60),Vector2.zero,color or Color3.fromRGB(47,52,55),false); f.LayoutOrder=rowNumber
 local l=label(f,text,UDim2.new(1,-24,1,-8),UDim2.fromOffset(12,4),17); l.TextXAlignment=Enum.TextXAlignment.Left
 return f,l
end
local function action(text,color,fn)
 rowNumber=rowNumber+1; local b=button(list,text,contentWidth,52,color,fn); b.LayoutOrder=rowNumber; return b
end
open=function(name)
 if titleActive then return end
 if revealing then return end
 menuSerial+=1;page=name; window.Visible=true;dim.Visible=true; sound("Open",0.85); render()
 window.Position=modalPosition+UDim2.fromOffset(0,18); Tween:Create(window,TweenInfo.new(0.25,Enum.EasingStyle.Back),{Position=modalPosition}):Play()
end
-- Original geometric icons; no external assets need to load.
local function icon(parent,kind,color)
 local holder=Instance.new("Frame",parent); holder.Size=UDim2.fromOffset(60,50); holder.Position=UDim2.fromOffset(16,5); holder.BackgroundTransparency=1; holder.ZIndex=2
 local assets=folder:FindFirstChild("Assets")
 local icons=assets and assets:FindFirstChild("GUIIcons")
 local pack=assets and assets:FindFirstChild("UIMegaPack")
 local mapping={Shop="Shop",Summon="Luck",Inventory="Inventory",Cosmetics="Super Gem's",Wheel="WheelSpin",Codes="Code's",Rebirth="Rebirth",Sell="Money"}
 local packed=pack and pack:FindFirstChild(mapping[kind] or kind)
 if packed and (packed:IsA("ImageButton") or packed:IsA("ImageLabel")) and packed.Image~="" then
  local image=Instance.new("ImageLabel",holder);image.Name="MegaPackIcon";image.BackgroundTransparency=1;image.Size=UDim2.fromScale(1,1);image.Image=packed.Image;image.ImageRectOffset=packed.ImageRectOffset;image.ImageRectSize=packed.ImageRectSize;image.ScaleType=Enum.ScaleType.Fit;return
 end
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
local nav={{"SHOP","Shop",palette.Pink},{"SUMMON","Summon",palette.Gold},{"FIGHTERS","Inventory",palette.Cyan},{"AURAS","Cosmetics",Color3.fromRGB(183,71,255)},{"WHEEL","Wheel",palette.Mint},{"CODES","Codes",Color3.fromRGB(255,153,43)},{"REBIRTH","Rebirth",palette.Pink},{"SELL","Sell",palette.Mint}}
for i,v in ipairs(nav) do
 local b=button(canvas,v[1],94,84,v[3],function() open(v[2]) end); b.Position=UDim2.fromOffset(285+(i-1)*105,666)
 table.insert(bottomNav,b)
 b.Label.Position=UDim2.fromOffset(0,56); b.Label.Size=UDim2.fromOffset(94,26); b.Label.TextSize=18
 icon(b,v[2],v[3])
end
local topSell=button(canvas,"SELL POWER",220,54,palette.Gold,function() call("Sell") end); topSell.Position=UDim2.fromOffset(275,7); topSell.Label.TextSize=30; gleam(topSell,190,54)
local topStore=button(canvas,"SHOP",220,54,palette.Mint,function() open("Shop") end);topStore.Position=UDim2.fromOffset(745,7);topStore.Label.TextSize=29;gleam(topStore,190,54)
icon(topSell,"Money",palette.Gold);topSell.Label.Position=UDim2.fromOffset(70,0);topSell.Label.Size=UDim2.new(1,-74,1,-6);topSell.Label.TextSize=25
icon(topStore,"Shop",palette.Gold);topStore.Label.Position=UDim2.fromOffset(70,0);topStore.Label.Size=UDim2.new(1,-74,1,-6);topStore.Label.TextSize=24
local topBase=button(canvas,"BASE",220,54,palette.Cyan,function() call("Home") end);topBase.Position=UDim2.fromOffset(510,7);topBase.Label.TextSize=28
local shop=button(canvas,"STARTER PACK",205,110,palette.Gold,function() selectedProduct="Starter"; open("Shop") end); shop.Position=UDim2.fromOffset(10,240); shop.Label.Position=UDim2.fromOffset(6,3); shop.Label.Size=UDim2.fromOffset(193,30); shop.Label.TextXAlignment=Enum.TextXAlignment.Left
label(shop,"Sasuke + 5 spins\n+ 1 boosted ticket",UDim2.fromOffset(190,43),UDim2.fromOffset(7,34),16)
local packOpen=button(shop,"VIEW PACK",110,25,palette.Mint,function() selectedProduct="Starter"; open("Shop") end); packOpen.Position=UDim2.fromOffset(85,80); packOpen.Label.TextSize=16; gleam(shop,205,110)
local quests=label(canvas,"CLICKER GOALS",UDim2.fromOffset(205,32),UDim2.fromOffset(10,366),24,palette.Gold)
local goalText=label(canvas,"Click to collect power\nSell power for coins\nSummon and rebirth",UDim2.fromOffset(205,100),UDim2.fromOffset(10,403),18)
local practice=button(canvas,"REBIRTH BONUSES",205,43,palette.Mint,function() open("Rebirth") end);practice.Position=UDim2.fromOffset(10,520)
local lastTrain=-math.huge
local function train()
 if titleActive then return end
 if not state or page or window.Visible or revealing or Input:GetFocusedTextBox() then return end
 if os.clock()-lastTrain<C.Training.Interval then return end
 lastTrain=os.clock();call("Train")
end
local trainButton=button(canvas,"CLICK TO TRAIN",310,60,palette.Gold,train);trainButton.Position=UDim2.fromOffset(445,530)
local strengthLabel=label(canvas,"POWER 0",UDim2.fromOffset(420,32),UDim2.fromOffset(390,495),24,palette.Gold)
local progressTrack=panel(canvas,Vector2.new(500,16),Vector2.new(350,608),palette.Ink,false)
local progressFill=Instance.new("Frame",progressTrack);progressFill.Size=UDim2.fromScale(0,1);progressFill.BackgroundColor3=palette.Mint;progressFill.BorderSizePixel=0;corner(progressFill,8);gradient(progressFill,palette.Mint)
local progressText=label(progressTrack,"",UDim2.fromOffset(500,24),UDim2.fromOffset(0,18),15)
local function trainingHud()
 if not state then return end
 strengthLabel.Text=Layout.Number(state.Strength).." POWER  •  "..Layout.Number(state.SellValue or ((state.Strength or 0)*C.Clicker.SellRate)).." SELL VALUE"
 trainButton.Label.Text="CLICK +"..Layout.Number(state.ClickGain or 1).." POWER"
 local cost=state.RebirthCost or C.RebirthCost(state.Rebirths)
 local maxed=(state.Rebirths or 0)>=C.Clicker.MaxRebirths
 local ratio=maxed and 1 or math.clamp(state.Coins/math.max(1,cost),0,1)
 Tween:Create(progressFill,TweenInfo.new(.15),{Size=UDim2.fromScale(ratio,1)}):Play()
 progressText.Text=maxed and "MAX REBIRTHS • THANKS FOR PLAYING!" or "NEXT REBIRTH • "..Layout.Number(state.Coins).." / "..Layout.Number(cost).." COINS"
end
local function floating(text,color)
 local x=metrics.Width/2+math.random(-45,45);local y=metrics.Portrait and 900 or 450
 local l=label(canvas,text,UDim2.fromOffset(270,40),UDim2.fromOffset(x,y),27,color);l.AnchorPoint=Vector2.new(.5,0);l.ZIndex=30
 Tween:Create(l,TweenInfo.new(.7,Enum.EasingStyle.Quad),{Position=UDim2.fromOffset(x+math.random(-30,30),y-95),TextTransparency=1,TextStrokeTransparency=1}):Play()
 local stroke=l:FindFirstChildOfClass("UIStroke");if stroke then Tween:Create(stroke,TweenInfo.new(.7),{Transparency=1}):Play() end
 game:GetService("Debris"):AddItem(l,.75)
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
  spinningPreviews[view]={Model=display,Base=display:GetPivot(),Started=os.clock(),Idle=not spin,Id=id}
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
  block("Leg",Vector3.new(0.6,1.2,0.65),Vector3.new(side*0.36,-1.2,0),outfit.Legs or outfit.Cloth)
 end
 if not outfit.Bald and not outfit.Hat then
  for i=-2,2 do local hair=block("Hair",Vector3.new(0.25,0.5,0.8),Vector3.new(i*0.2,2,0),outfit.Hair); hair.Rotation=Vector3.new(0,0,-i*12) end
 end
 OutfitDetails.Apply(display,outfit,display,true)
 spinningPreviews[view]={Model=display,Base=display:GetPivot(),Started=os.clock(),Idle=not spin,Id=id}
 return view
end
renderInventory=function()
 for _,v in ipairs(list:GetChildren()) do if v:IsA("GuiObject") then v:Destroy() end end
 list.CanvasPosition=Vector2.zero;rowNumber=0
 local owned={};local query=searchDraft:lower():match("^%s*(.-)%s*$")
 for _,item in ipairs(C.Characters) do
  if (state.Characters[item.Id] or 0)>0 and (query=="" or (item.Name.." "..C.Rarities[item.Tier]):lower():find(query,1,true)) then table.insert(owned,item) end
 end
 table.sort(owned,function(a,b) if a.Tier~=b.Tier then return a.Tier>b.Tier end;return a.Name<b.Name end)
 local columns=metrics.Portrait and 3 or 5
 local width=(contentWidth-(columns-1)*12)/columns
 if #owned==0 then row(query=="" and "No fighters yet. Summon your first fighter!" or "No fighters match your search.",72);return end
 for first=1,#owned,columns do
  local strip=row("",228);strip.BackgroundTransparency=1;strip:FindFirstChildOfClass("UIStroke").Enabled=false
  for column=0,columns-1 do
   local item=owned[first+column]
   if item then
    local card=panel(strip,Vector2.new(width,180),Vector2.new(column*(width+12),0),item.Color,true)
    portrait(card,item.Id,UDim2.fromOffset(6,8),UDim2.fromOffset(width-12,122))
    local count=label(card,"×"..state.Characters[item.Id],UDim2.fromOffset(width-8,24),UDim2.fromOffset(4,2),16);count.TextXAlignment=Enum.TextXAlignment.Right
    label(card,C.Rarities[item.Tier],UDim2.fromOffset(width-6,23),UDim2.fromOffset(3,124),17,item.Color:Lerp(palette.White,.6))
    label(card,item.Name,UDim2.fromOffset(width-6,35),UDim2.fromOffset(3,145),17)
    local equipped=state.Equipped==item.Id
    local equip=button(strip,equipped and "Equipped" or "Equip",width,36,equipped and Color3.fromRGB(155,158,161) or palette.Mint,function() if not equipped then call("Equip",item.Id) end end)
    equip.Position=UDim2.fromOffset(column*(width+12),188);equip.Label.TextSize=22
   end
  end
 end
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
 local art=Instance.new("Frame",parent);art.Size=UDim2.fromOffset(115,115);art.Position=UDim2.fromOffset(10,40);art.BackgroundTransparency=1
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
 if relayout then relayout() end
 inventoryTools.Visible=page=="Inventory"
 menuMoney.Text=state and (Layout.Number(state.Coins).." COINS") or ""
 for name,tab in pairs(tabs) do local g=tab:FindFirstChildOfClass("UIGradient");if g then local color=name==page and palette.Mint or Color3.fromRGB(140,155,174);g.Color=ColorSequence.new(color,color:Lerp(Color3.new(0,0,0),.2)) end end
 title.Text=page=="Shop" and "Store" or page=="Inventory" and "Inventory" or page=="Cosmetics" and "Auras" or page
 local bannerGradient=banner:FindFirstChildOfClass("UIGradient")
 if bannerGradient then bannerGradient.Color=ColorSequence.new(Color3.fromRGB(255,178,45),Color3.fromRGB(215,79,0)) end
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
 elseif page=="Sell" then
  row("SELL YOUR POWER\nClicking builds power. Sell it for coins to summon more fighters.",75)
  row(Layout.Number(state.Strength).." POWER → "..Layout.Number(state.SellValue).." COINS\nSelling resets your stored power; fighters and rebirth bonuses stay.",88,palette.Cyan)
  action("SELL ALL POWER",palette.Mint,function() call("Sell") end)
  action("KEEP CLICKING",palette.Gold,function() closeMenu() end)
 elseif page=="Rebirth" then
  if state.Rebirths>=C.Clicker.MaxRebirths then row("MAXIMUM REBIRTHS REACHED\nAll permanent power bonuses unlocked. Keep collecting your favorite fighters!",100,palette.Gold);return end
  row("PERMANENT POWER BOOST\nEach rebirth adds +"..(C.Clicker.RebirthBonus*100).."% to your base power multiplier. Click gains round up.",85)
  row("Rebirths: "..state.Rebirths.."  •  Next cost: "..Layout.Number(state.RebirthCost).." coins\nReward: +"..C.Clicker.RebirthGems.." gems. Fighters, auras, tickets and codes stay.",85,palette.Gold)
  row("Rebirthing resets ALL coins and stored power to zero. Save up, then choose when to reset.",72,palette.Pink)
  action("REBIRTH • "..Layout.Number(state.RebirthCost).." COINS",palette.Mint,function() call("Rebirth") end)
 elseif page=="Inventory" then
  renderInventory()
 elseif page=="Cosmetics" then
  row("AURA ATELIER\nOne cosmetic per spin. Equip for free. One aura slot; power bonuses never stack.",64)
  action("STANDARD AURA • "..C.Economy.CosmeticStandard.." GEMS",Color3.fromRGB(192,148,255),function() call("Cosmetic","Standard") end)
  action("BOOSTED AURA • "..C.Economy.CosmeticBoosted.." GEMS",palette.Pink,function() call("Cosmetic","Boosted") end)
  action("VIEW BOOSTED AURA ODDS",palette.Mint,function() open("Cosmetic odds") end)
  action("UNEQUIP AURA",palette.Cyan,function() call("Aura","") end)
  for _,item in ipairs(C.Cosmetics) do
   local n=state.Cosmetics[item.Id] or 0
   action(string.format("%s%s • %s • +%.0f%% power • ×%d",state.Aura==item.Id and "ON • " or "",item.Name,C.Rarities[item.Tier],item.Power*100,n),n>0 and item.Color or Color3.fromRGB(128,132,150),function() if n>0 then call("Aura",item.Id) else notify("Spin for this aura first.") end end)
  end
  odds(true,false)
 elseif page=="Shop" then
  -- Compact four-card store, matching the supplied simulator UI reference.
  local keys={"Starter","Spins","Boosted","Luck"}
  for first=1,4,2 do
   local strip=row("",176);strip.BackgroundTransparency=1;local stripStroke=strip:FindFirstChildOfClass("UIStroke");if stripStroke then stripStroke.Enabled=false end
   for col=0,1 do
    local key=keys[first+col];local product=C.Products[key]
    local cardWidth=(contentWidth-20)/2
    local card=panel(strip,Vector2.new(cardWidth,170),Vector2.new(col*(cardWidth+20),0),key=="Luck" and Color3.fromRGB(113,227,79) or key=="Boosted" and Color3.fromRGB(191,88,255) or key=="Spins" and Color3.fromRGB(61,197,255) or Color3.fromRGB(255,173,74),true)
    if key=="Starter" then portrait(card,"sasuke",UDim2.fromOffset(8,42),UDim2.fromOffset(128,110)) else packArt(card,key) end
    label(card,product.Name,UDim2.fromOffset(310,38),UDim2.fromOffset(9,0),24)
    label(card,product.Description,UDim2.fromOffset(cardWidth-155,77),UDim2.fromOffset(143,37),17)
    local choose=button(card,selectedProduct==key and "SELECTED" or "VIEW PACK",cardWidth-156,38,palette.Mint,function() selectedProduct=key;render();list.CanvasPosition=Vector2.new(0,376) end);choose.Position=UDim2.fromOffset(143,121);choose.Label.TextSize=16
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
  if not state.PaidAllowed then row("Paid rolls and luck are unavailable for this account. You can still sell power, rebirth, redeem codes, and spin without paid luck.",75) end
  row("2x luck doubles the actual probability of Rare and higher tiers. Standard Secret: 0.01% → 0.02%. Boosted Secret: 0.1% → 0.2%. Each tier splits equally between its rollable fighters. See the live per-fighter odds below; luck doubles Rare and higher tier odds.",90)
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
  wheelDisk=Instance.new("Frame",f); wheelDisk.Size=UDim2.fromOffset(260,260); wheelDisk.Position=UDim2.fromOffset((contentWidth-260)/2,20); wheelDisk.BackgroundColor3=palette.Pink; corner(wheelDisk,130); outline(wheelDisk,palette.Gold,8); studs(wheelDisk,240,240,42)
  for slot,index in ipairs(C.WheelLayout()) do
   local colors={palette.Mint,palette.Gold,Color3.fromRGB(221,64,255),palette.Cyan}
   local sector=Instance.new("Frame",wheelDisk);sector.Size=UDim2.fromScale(1,1);sector.BackgroundTransparency=1;sector.Rotation=(slot-1)*18
   local spoke=Instance.new("Frame",sector);spoke.AnchorPoint=Vector2.new(0.5,1);spoke.Size=UDim2.fromOffset(28,120);spoke.Position=UDim2.fromOffset(130,130);spoke.BackgroundColor3=colors[index];spoke.BorderSizePixel=1;spoke.BorderColor3=palette.Ink;spoke.Rotation=0;corner(spoke,4)
   local text=label(spoke,(C.Wheel[index].Gems and (C.Wheel[index].Gems.."G") or tostring(C.Wheel[index].Coins or "?")),UDim2.fromOffset(28,20),UDim2.fromOffset(0,4),11);text.Rotation=0
  end
  local hub=panel(wheelDisk,Vector2.new(96,96),Vector2.new(82,82),palette.Gold,true);corner(hub,50)
  label(hub,"DAILY\nSPIN",UDim2.fromScale(1,1),UDim2.new(),23)
  local pointer=Instance.new("Frame",f); pointer.Size=UDim2.fromOffset(22,22); pointer.Position=UDim2.fromOffset(contentWidth/2-11,4); pointer.Rotation=45; pointer.BackgroundColor3=palette.Gold; pointer.ZIndex=4; outline(pointer,palette.Ink,2)
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
 if not s then return end; state=s;if titleScreen then titleScreen:Refresh() end;Polish.Aura(p.Character,s.Aura); offset=s.ServerTime-os.time()
 if coinTween then coinTween:Cancel() end;if gemTween then gemTween:Cancel() end
 coinTween=Tween:Create(coinCounter,TweenInfo.new(.28,Enum.EasingStyle.Quad),{Value=s.Coins});coinTween:Play()
 gemTween=Tween:Create(gemCounter,TweenInfo.new(.28,Enum.EasingStyle.Quad),{Value=s.Gems});gemTween:Play();winsLabel.Text=(s.Rebirths or 0).." REBIRTHS"
 adminButton.Visible=s.IsAdmin==true or s.Studio==true
 trainingHud()
 status.Text=""
 if page and not (page=="Wheel" and wheelSpinning) then local scroll=list.CanvasPosition;render();list.CanvasPosition=scroll end
end
Event.OnClientEvent:Connect(function(kind,data)
 if kind=="State" then apply(data)
 elseif kind=="Training" then
  if state then state.Strength=data.Strength;state.ClickGain=data.ClickGain;state.SellValue=data.SellValue;trainingHud() end
  if data.Gain>0 then floating("+"..data.Gain.." POWER",palette.Gold) end;Polish.Train(p.Character,state and state.Equipped);sound("Click",1.15)
 elseif kind=="OpenMenu" then open(data)
 elseif kind=="Toast" then notify(data)
 elseif kind=="Reveal" then if titleActive then table.insert(revealQueue,data) else playReveal(data) end
 elseif kind=="AdminEvent" then party(data)
 elseif kind=="ClickerReward" then
  Polish.Pulse(.15)
  if data.Kind=="Rebirth" then party({Text="REBIRTH! +"..data.Amount.." gems • stronger clicks unlocked",Kind="confetti",Duration=2})
  else floating("+"..Layout.Number(data.Amount).." COINS",palette.Gold);sound("Reward",1.2) end
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

 end
end)
Input.InputBegan:Connect(function(input,processed)
 if titleActive then return end
 if not processed and input.KeyCode==Enum.KeyCode.F8 then open("Admin");return end
 if input.KeyCode==Enum.KeyCode.Escape and page then closeMenu();return end
 if processed or page or revealing or Input:GetFocusedTextBox() then return end
 if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then train();return end
 if input.KeyCode==Enum.KeyCode.F then train() end
end)
-- Entering a starter-pack area opens its menu once; leave and re-enter to reopen.
local shownPrompts={}
Prompts.PromptShown:Connect(function(prompt)
 if prompt:GetAttribute("RiftAction")=="Shop" and not shownPrompts[prompt] then
  shownPrompts[prompt]=true
  if not page then selectedProduct="Starter"; open("Shop") end
 end
end)
Prompts.PromptHidden:Connect(function(prompt) shownPrompts[prompt]=nil end)
folder:GetAttributeChangedSignal("ServerStatus"):Connect(function() if titleScreen then titleScreen:Refresh() end;if page and not state then render() end end)
local lastTick=0
Run.RenderStepped:Connect(function()
 local now=os.clock()
 for layer,spacing in pairs(movingPatterns) do
  if layer.Parent then layer.Position=UDim2.fromOffset((now*C.UI.StudSlideSpeed)%spacing-spacing,0) else movingPatterns[layer]=nil end
 end
 for view,spin in pairs(spinningPreviews) do
  if view.Parent and spin.Model.Parent then
   if spin.Idle then
    local profile=IdleMotion.Profile(spin.Id);local t=(now-spin.Started)*profile.Speed
    spin.Model:PivotTo(spin.Base*CFrame.new(0,math.sin(t)*.04,0)*CFrame.Angles(0,math.sin(t*.6)*.025,math.sin(t)*profile.Lean*.25))
   else spin.Model:PivotTo(spin.Base*CFrame.Angles(0,(now-spin.Started)*math.rad(C.UI.RevealSpinSpeed),0)) end
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
 trainButton.Visible=state~=nil and not window.Visible and not revealing
 progressTrack.Visible=trainButton.Visible
 strengthLabel.Visible=trainButton.Visible

end)
task.spawn(function()
 while not state do local result=call("State"); if result and result.State then apply(result.State) end; if not state then if page then render() end; task.wait(2) end end
 -- The title screen owns the welcome message after the player selects Play.
end)

local function bindCamera(character)
 if titleActive then return end
 local humanoid=character:WaitForChild("Humanoid",10)
 if humanoid and p.Character==character and workspace.CurrentCamera then
  workspace.CurrentCamera.CameraType=Enum.CameraType.Custom
  workspace.CurrentCamera.CameraSubject=humanoid
  if state then Polish.Aura(character,state.Aura) end
 end
end
p.CharacterAdded:Connect(function(character) task.spawn(bindCamera,character) end)
if p.Character then task.spawn(bindCamera,p.Character) end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
 if viewportConnection then viewportConnection:Disconnect() end
 if workspace.CurrentCamera then resize();viewportConnection=workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
 if p.Character then task.spawn(bindCamera,p.Character) end
end)

relayout=function()
 local portrait=metrics.Portrait
 window.Position=modalPosition;window.Size=UDim2.fromOffset(metrics.WindowWidth,metrics.WindowHeight)
 banner.Size=UDim2.fromOffset(metrics.WindowWidth-4,72)
 title.Size=UDim2.fromOffset(metrics.WindowWidth-365,62)
 close.Position=UDim2.fromOffset(metrics.WindowWidth-66,8)
 menuMoney.Position=UDim2.fromOffset(metrics.WindowWidth-320,10)
 contentWidth=metrics.WindowWidth-64
 list.Size=UDim2.fromOffset(metrics.WindowWidth-32,metrics.WindowHeight-(page=="Inventory" and 166 or 158))
 list.Position=UDim2.fromOffset(16,page=="Inventory" and 150 or 88)
 for name,tab in pairs(tabs) do
  local index=name=="Inventory" and 0 or name=="Cosmetics" and 1 or 2
  local width=(metrics.WindowWidth-52)/3
  tab.Position=UDim2.fromOffset(16+index*(width+10),metrics.WindowHeight-54);tab.Size=UDim2.fromOffset(width,42);tab.Visible=page~="Inventory"
 end
 inventoryTools.Size=UDim2.fromOffset(metrics.WindowWidth-32,58)
 local bestW=portrait and 148 or 200;local unequipW=portrait and 156 or 206;local recycleW=portrait and 84 or 100
 local searchW=metrics.WindowWidth-32-bestW-unequipW-recycleW-40
 bestButton.Position=UDim2.fromOffset(8,7);bestButton.Size=UDim2.fromOffset(bestW,44)
 unequipButton.Position=UDim2.fromOffset(16+bestW,7);unequipButton.Size=UDim2.fromOffset(unequipW,44)
 search.Position=UDim2.fromOffset(24+bestW+unequipW,7);search.Size=UDim2.fromOffset(searchW,44)
 recycleButton.Position=UDim2.fromOffset(32+bestW+unequipW+searchW,7);recycleButton.Size=UDim2.fromOffset(recycleW,44)
 toast.Size=UDim2.fromOffset(math.min(900,metrics.Width-24),48)
 logo.Position=UDim2.fromOffset(12,10)
 local tops={topSell,topBase,topStore}
 for i,b in ipairs(tops) do
  b.Position=portrait and UDim2.fromOffset(12+(i-1)*248,190) or UDim2.fromOffset(275+(i-1)*235,7)
  b.Size=UDim2.fromOffset(portrait and 240 or 220,54)
 end
 header.Position=portrait and UDim2.fromOffset(12,76) or UDim2.fromOffset(12,648)
 for i,b in ipairs(bottomNav) do
  local column=(i-1)%2;local row=math.floor((i-1)/2)
  b.Position=UDim2.fromOffset(12+column*(portrait and 114 or 106),(portrait and 300 or 260)+row*(portrait and 100 or 96));b.Size=UDim2.fromOffset(portrait and 100 or 94,84)
 end
 shop.Position=UDim2.fromOffset(10,122);shop.Visible=not portrait
 for _,item in ipairs({quests,goalText,practice,luck,boost}) do item.Visible=false end
 bottom.Visible=false
 trainButton.Position=portrait and UDim2.fromOffset(140,1120) or UDim2.fromOffset(445,680)
 trainButton.Size=UDim2.fromOffset(portrait and 480 or 310,60)
 strengthLabel.Position=portrait and UDim2.fromOffset(80,1074) or UDim2.fromOffset(330,640);strengthLabel.Size=UDim2.fromOffset(portrait and 600 or 540,34)
 bottom.Position=portrait and UDim2.fromOffset(55,860) or UDim2.fromOffset(275,460)
 progressTrack.Position=portrait and UDim2.fromOffset(130,1020) or UDim2.fromOffset(350,596)
 status.Position=portrait and UDim2.fromOffset(20,224) or UDim2.fromOffset(240,78)





 reveal.Position=portrait and UDim2.fromOffset(65,380) or UDim2.fromOffset(285,210)
 buffIcon.Position=portrait and UDim2.fromOffset(680,70) or UDim2.fromOffset(1121,671)
 buffTip.Position=portrait and UDim2.fromOffset(470,112) or UDim2.fromOffset(947,633)
 adminButton.Position=portrait and UDim2.fromOffset(540,16) or UDim2.fromOffset(1004,610)
end
resize()

titleScreen=TitleScreen.Mount({
 Player=p,Parent=p:WaitForChild("PlayerGui"),FighterCount=#C.Characters,
 IsReady=function() return state~=nil and folder:GetAttribute("ServerStatus")=="Ready" end,
 ServerStatus=function() return folder:GetAttribute("ServerStatus") end,
 OnRetry=function() task.spawn(function() local r=call("State");if r and r.State then apply(r.State) end end) end,
 OnPlay=function()
  titleActive=false;canvas.Visible=true
  if p.Character then task.spawn(bindCamera,p.Character) end
  sound("Open",1.2);notify("Welcome to Rift Meadows! Click for power, then sell and summon.")
  if #revealQueue>0 then task.delay(.5,function() if not revealing and #revealQueue>0 then playReveal(table.remove(revealQueue,1)) end end) end
 end,
})
