-- Run the real client UI in a lightweight event model. This checks wiring and
-- construction, not Roblox rendering, hit testing, or actual device input.
local function signal()
 local callbacks={}
 return {Connect=function(_,fn)
  local entry={Fn=fn,Active=true};table.insert(callbacks,entry)
  return {Disconnect=function() entry.Active=false end}
 end,Count=function() local n=0;for _,entry in ipairs(callbacks) do if entry.Active then n+=1 end end;return n end,Fire=function(_,...) for _,entry in ipairs(table.clone(callbacks)) do if entry.Active then entry.Fn(...) end end end}
end
local eventNames={Activated=true,FocusLost=true,MouseEnter=true,MouseLeave=true,Changed=true,Destroying=true,CharacterAdded=true,OnClientEvent=true}
local oldIndex=nodeMeta.__index
nodeMeta.__index=function(t,k)
 local value=oldIndex(t,k);if value~=nil then return value end
 if eventNames[k] then
  local signals=rawget(t,"_signals");if not signals then signals={};rawset(t,"_signals",signals) end
  if not signals[k] then signals[k]=signal() end;return signals[k]
 end
 return methods.FindFirstChild(t,k)
end
local oldDestroy=methods.Destroy
function methods:Destroy()
 local signals=rawget(self,"_signals");if signals and signals.Destroying then signals.Destroying:Fire() end
 oldDestroy(self)
end
local oldNewIndex=nodeMeta.__newindex
nodeMeta.__newindex=function(t,k,v)
 oldNewIndex(t,k,v)
 local signals=rawget(t,"_signals")
 if signals then
  if signals["Property_"..k] then signals["Property_"..k]:Fire() end
  if k=="Value" and signals.Changed then signals.Changed:Fire(v) end
 end
end
function methods:GetPropertyChangedSignal(k)
 if not rawget(self,"_signals") then rawset(self,"_signals",{}) end
 local key="Property_"..k;if not self._signals[key] then self._signals[key]=signal() end;return self._signals[key]
end
function methods:GetAttributeChangedSignal(k) return self:GetPropertyChangedSignal("Attribute_"..k) end
function methods:WaitForChild(k) local result=self:FindFirstChild(k);assert(result,"Missing child: "..k);return result end
function methods:Clone()
 local result=Instance.new(self.ClassName)
 for key,value in pairs(self._props) do if key~="Parent" and key~="ClassName" then result[key]=value end end
 for _,c in ipairs(self:GetChildren()) do c:Clone().Parent=result end
 return result
end
function methods:Play() end
local guiClasses={CanvasGroup=true,Frame=true,TextLabel=true,TextButton=true,ImageLabel=true,ImageButton=true,ViewportFrame=true,ScrollingFrame=true,TextBox=true}
local oldIsA=methods.IsA
methods.IsA=function(self,class) return class=="GuiObject" and guiClasses[self.ClassName]==true or class=="LuaSourceContainer" and (self.ClassName=="Script" or self.ClassName=="LocalScript" or self.ClassName=="ModuleScript") or oldIsA(self,class) end
local oldNew=Instance.new
Instance.new=function(class,parent)
 local item=oldNew(class,parent)
 if guiClasses[class] then item.Visible=true;item.Rotation=0 end
 if class=="NumberValue" then item.Value=0 end
 if class=="ScrollingFrame" then item.CanvasPosition=Vector2.zero end
 return item
end
local dimMeta={}
dimMeta.__add=function(a,b) return UDim2.new(a.X.Scale+b.X.Scale,a.X.Offset+b.X.Offset,a.Y.Scale+b.Y.Scale,a.Y.Offset+b.Y.Offset) end
UDim2={new=function(xs,xo,ys,yo) return setmetatable({X={Scale=xs or 0,Offset=xo or 0},Y={Scale=ys or 0,Offset=yo or 0}},dimMeta) end}
UDim2.fromOffset=function(x,y) return UDim2.new(0,x,0,y) end
UDim2.fromScale=function(x,y) return UDim2.new(x,0,y,0) end
UDim={new=function(scale,offset) return {Scale=scale,Offset=offset} end}
local colorMeta={};colorMeta.__index=colorMeta
function colorMeta:Lerp(other,alpha) return Color3.new(self.R+(other.R-self.R)*alpha,self.G+(other.G-self.G)*alpha,self.B+(other.B-self.B)*alpha) end
Color3.new=function(r,g,b) return setmetatable({R=r,G=g,B=b,_type="Color3"},colorMeta) end
Color3.fromRGB=function(r,g,b) return Color3.new(r/255,g/255,b/255) end
local function upgradeColors(value)
 if type(value)~="table" then return end
 if value._type=="Color3" then setmetatable(value,colorMeta);return end
 for _,child in pairs(value) do upgradeColors(child) end
end
upgradeColors(C)
ColorSequence={new=function(...) return {...} end};ColorSequenceKeypoint={new=function(...) return {...} end}
TweenInfo={new=function(...) return {...} end}
CFrame.lookAt=function(from) return CFrame.new(from) end
for key,group in pairs(Enum) do
 setmetatable(group,{__index=function(t,k) local value={Name=k,_type="Enum",Group=key};rawset(t,k,value);return value end})
end
local delays={}
task.delay=function(seconds,fn) table.insert(delays,{Seconds=seconds,Fn=fn}) end
local rs=Instance.new("ReplicatedStorage")
local shared=Instance.new("Folder",rs);shared.Name="AnimeRift";shared:SetAttribute("ServerStatus","Ready")
for _,name in ipairs({"Config","Polish","ClientLayout","TitleScreen","OutfitDetails","IdleMotion","SummonCinematics","BrolySequence","MadaraSequence"}) do local module=Instance.new("ModuleScript",shared);module.Name=name end
local request=Instance.new("RemoteFunction",shared);request.Name="Request"
local events=Instance.new("RemoteEvent",shared);events.Name="Event"
local user=Instance.new("Player");user.UserId=123
local playerGui=Instance.new("PlayerGui",user);playerGui.Name="PlayerGui"
services.Players={LocalPlayer=user}
services.ReplicatedStorage=rs
services.SoundService=Instance.new("SoundService")
services.Debris={AddItem=function() end}
services.TweenService={Create=function(_,instance,info,props) return {Play=function() for key,value in pairs(props) do instance[key]=value end end,Cancel=function() end} end}
services.UserInputService={InputBegan=signal(),GetFocusedTextBox=function() return nil end}
services.ProximityPromptService={PromptShown=signal(),PromptHidden=signal()}
services.RunService.RenderStepped=signal()
local movementBlocked=false
services.ContextActionService={BindActionAtPriority=function() movementBlocked=true end,UnbindAction=function() movementBlocked=false end}
workspace.CurrentCamera=Instance.new("Camera");workspace.CurrentCamera.ViewportSize=Vector2.new(390,844)
local madaraSequence=loadstring(MADARA_SOURCE,"MadaraSequence")()
local cineChunk=loadstring(CINEMATICS_SOURCE,"SummonCinematics")
setfenv(cineChunk,setmetatable({script={Parent={WaitForChild=function(_,name) return name end}},require=function(name) return name=="MadaraSequence" and madaraSequence or CutscenePresets end},{__index=getfenv()}))
local cinematicModule=cineChunk()
local rageTimeline=loadstring(RAGE_TIMELINE_SOURCE,"BrolyTimeline")()
local ragePose=loadstring(RAGE_POSE_SOURCE,"BrolyPose")()
local rageChunk=loadstring(RAGE_SCENE_SOURCE,"BrolySequence")
setfenv(rageChunk,setmetatable({script={Parent={WaitForChild=function(_,name) return name end}},require=function(name) return name=="BrolyTimeline" and rageTimeline or ragePose end},{__index=getfenv()}))
local rageSequence=rageChunk()
local titleModule=loadstring(TITLE_SOURCE,"TitleScreen")()
local idleModule=loadstring(IDLE_SOURCE,"IdleMotion")()
-- Geometry stand-ins for deterministic authored-model fixtures; real rendering stays a Studio check.
function methods:GetPivot() return self.LastPivot or CFrame.new() end
function methods:GetScale() return self.TestScale or 1 end
function methods:GetBoundingBox()
 local lo,hi=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
 local any=false
 for _,part in ipairs(self:GetDescendants()) do if part:IsA("BasePart") then
  any=true;local cf,size=part.CFrame or CFrame.new(),part.Size or Vector3.one
  local a,b=cf.Position-size/2,cf.Position+size/2
  lo=Vector3.new(math.min(lo.X,a.X),math.min(lo.Y,a.Y),math.min(lo.Z,a.Z))
  hi=Vector3.new(math.max(hi.X,b.X),math.max(hi.Y,b.Y),math.max(hi.Z,b.Z))
 end end
 assert(any,"Model has no body parts")
 return CFrame.new((lo+hi)/2),hi-lo
end
function methods:ScaleTo(scale)
 local ratio=scale/self:GetScale()
 for _,part in ipairs(self:GetDescendants()) do if part:IsA("BasePart") then
  part.Size=(part.Size or Vector3.one)*ratio
  local cf=part.CFrame or CFrame.new();part.CFrame=CFrame.new(cf.Position*ratio)*cf.Rotation
 end end
 self.TestScale=scale
end
function methods:PivotTo(cf)
 local delta=cf*self:GetPivot():Inverse()
 for _,part in ipairs(self:GetDescendants()) do if part:IsA("BasePart") then part.CFrame=delta*(part.CFrame or CFrame.new()) end end
 self.LastPivot=cf
end
-- These are explicitly test fixtures, not models shipped to players or production fallbacks.
do
 local assets=Instance.new("Folder",shared);assets.Name="Assets"
 local models=Instance.new("Folder",assets);models.Name="CharacterModels"
 for _,hero in ipairs(C.Characters) do if hero.Tier>=5 then
  local model=Instance.new("Model",models);model.Name=hero.Id
  for _,body in ipairs({{"Head",0,1.5,0,1,1,1},{"Torso",0,0,0,2,2,1},{"Left Arm",-1.5,0,0,1,2,1},{"Right Arm",1.5,0,0,1,2,1},{"Left Leg",-.5,-2,0,1,2,1},{"Right Leg",.5,-2,0,1,2,1}}) do
   local part=Instance.new("Part",model);part.Name=body[1];part.CFrame=CFrame.new(body[2],body[3],body[4]);part.Size=Vector3.new(body[5],body[6],body[7])
  end
 end end
end
local detailsModule=loadstring(DETAILS_SOURCE,"OutfitDetails")()
local polishStub={Aura=function() end,ClearGuard=function() end,Train=function() end,Pulse=function() end,Guard=function() end}
require=function(target)
 if target.Name=="BrolySequence" then return rageSequence elseif target.Name=="SummonCinematics" then return cinematicModule elseif target.Name=="IdleMotion" then return idleModule elseif target.Name=="TitleScreen" then return titleModule elseif target.Name=="OutfitDetails" then return detailsModule elseif target.Name=="Config" then return C elseif target.Name=="Polish" then return polishStub elseif target.Name=="ClientLayout" then return L end
 error("Unexpected require")
end
loadstring(CLIENT_SOURCE,"Client")()
local ui=playerGui:FindFirstChild("AnimeRiftUI");check(ui~=nil,"client builds the UI on a portrait phone")
local canvas=ui:FindFirstChildOfClass("Frame")
local function findButton(text,parent)
 for _,item in ipairs((parent or canvas):GetDescendants()) do
  if item:IsA("TextButton") and item:FindFirstChild("Label") and item.Label.Text==text then return item end
 end
 error("Missing button: "..text)
end
local titleGui=playerGui:FindFirstChild("AnimeRiftTitleScreen")
check(titleGui~=nil and not canvas.Visible,"joining shows the title and hides the gameplay HUD")
check(movementBlocked and workspace.CurrentCamera.CameraType.Name=="Scriptable","title blocks movement and owns the scenic camera")
local playTitle=titleGui:FindFirstChild("TitleBackdrop"):FindFirstChild("TitleCard"):FindFirstChild("TitlePlayButton")
playTitle.Activated:Fire()
check(not canvas.Visible and not user:GetAttribute("RiftTitleSeen"),"Play cannot bypass profile loading")
local data={ServerTime=os.time(),Coins=1000,Gems=0,Wins=0,Strength=0,SellValue=0,Rebirths=0,RebirthCost=C.RebirthCost(0),ClickGain=1,Characters={yamcha=1},Cosmetics={},Equipped="yamcha",Aura="",LuckUntil=0,WheelReady=true,Studio=true,PaidAllowed=true}
events.OnClientEvent:Fire("State",data)
check(playTitle.Label.Text=="PLAY","loaded profile enables the title Play button")
findButton("SHOP").Activated:Fire()
check(not canvas.ModalBackdrop.Visible,"gameplay menus cannot open behind the title")
playTitle.Activated:Fire()
check(canvas.Visible and not movementBlocked and user:GetAttribute("RiftTitleSeen"),"Play reveals the HUD and restores movement")
check(workspace.CurrentCamera.CameraType.Name=="Custom","Play restores the player camera")
for _,delay in ipairs(delays) do if delay.Seconds==.42 then delay.Fn() end end
check(playerGui:FindFirstChild("AnimeRiftTitleScreen")==nil,"title transition removes its overlay")
local resumed=false
titleModule.Mount({Player=user,Parent=playerGui,OnPlay=function() resumed=true end})
check(resumed and not playerGui:FindFirstChild("AnimeRiftTitleScreen"),"title is shown once per player session")
findButton("SHOP").Activated:Fire()
local backdrop=canvas:FindFirstChild("ModalBackdrop")
check(backdrop.Visible,"store opens its modal backdrop")
local cards=0
for _,item in ipairs(canvas:GetDescendants()) do if item:IsA("TextButton") and item:FindFirstChild("Label") and (item.Label.Text=="VIEW PACK" or item.Label.Text=="SELECTED") and item.Size.X.Offset>150 and item.Size.X.Offset<500 then cards+=1 end end
check(cards==4,"store creates all four compact product cards")
findButton("FIGHTERS").Activated:Fire()
check(findButton("Equipped")~=nil,"fighter tab renders owned fighter and equip button")
findButton("X").Activated:Fire()
findButton("SHOP").Activated:Fire()
for _,delay in ipairs(delays) do if delay.Seconds==.13 then delay.Fn() end end
check(backdrop.Visible,"reopening a menu cancels a pending close animation")
workspace.CurrentCamera.ViewportSize=Vector2.new(1366,768)
check(canvas.Size.X.Offset==1200 and canvas.Size.Y.Offset==760,"live resize switches portrait UI to desktop layout")
workspace.CurrentCamera.ViewportSize=Vector2.new(390,844)
check(canvas.Size.X.Offset==760 and canvas.Size.Y.Offset==1200,"live resize restores the portrait layout")

findButton("FIGHTERS").Activated:Fire()
local searchBox
for _,item in ipairs(canvas:GetDescendants()) do if item.Name=="InventorySearch" then searchBox=item end end
searchBox.Text="no such fighter"
local noResults=false
for _,item in ipairs(canvas:GetDescendants()) do if item:IsA("TextLabel") and item.Text=="No fighters match your search." then noResults=true end end
check(noResults,"inventory search filters immediately without closing the search field")
searchBox.Text="yamcha"
check(findButton("Equipped")~=nil,"inventory search restores matching owned fighters")
searchBox.Text=""
findButton("SELL").Activated:Fire()
check(findButton("SELL ALL POWER")~=nil,"sell menu replaces boss controls")
findButton("REBIRTH").Activated:Fire()
check(findButton("REBIRTH • "..L.Number(data.RebirthCost).." COINS")~=nil,"rebirth menu shows its actual cost")
local noBossButtons=true
for _,item in ipairs(canvas:GetDescendants()) do if item:IsA("TextLabel") and type(item.Text)=="string" and (item.Text:find("BOSS",1,true) or item.Text:find("GUARD",1,true)) then noBossButtons=false end end
check(noBossButtons,"client builds no boss or guard controls")

-- The actual shared accessory builder runs for all new outfits, not a UI stub.
for id in pairs(additions) do
 local rig=Instance.new("Model")
 local head=Instance.new("Part",rig);head.Name="Head";head.Size=Vector3.new(2,1,1);head.CFrame=CFrame.new(0,3,0)
 local body=Instance.new("Part",rig);body.Name="Torso";body.Size=Vector3.new(2,2,1);body.CFrame=CFrame.new(0,1.5,0)
 local details=Instance.new("Folder",rig)
 detailsModule.Apply(rig,C.Outfits[id],details,false)
 local count=0;local safe=true
 for _,item in ipairs(details:GetDescendants()) do
  if item.ClassName=="Part" or item.ClassName=="WedgePart" then
   count+=1;if item.CanCollide or item.CanTouch or not item.Massless then safe=false end
  end
 end
 check(count>0 and safe,"new outfit details attach without collision: "..id)
end
local retryUser=Instance.new("Player");local retryReady=false;local attempts=0;local retryPlayed=false
local retryTitle=titleModule.Mount({Player=retryUser,Parent=playerGui,IsReady=function() return retryReady end,ServerStatus=function() return retryReady and "Ready" or "Error" end,OnRetry=function() attempts+=1 end,OnPlay=function() retryPlayed=true end})
local retryGui=playerGui:FindFirstChild("AnimeRiftTitleScreen")
local retryPlay=retryGui.TitleBackdrop.TitleCard.TitlePlayButton
retryPlay.Activated:Fire()
check(attempts==1 and not retryPlayed and retryTitle:IsOpen(),"title exposes retry without bypassing an unavailable server")
retryReady=true;retryTitle:Refresh()
services.UserInputService.InputBegan:Fire({KeyCode=Enum.KeyCode.Return},false)
check(retryPlayed and not movementBlocked,"Enter starts a ready title and restores controls")
for _,delay in ipairs(delays) do if delay.Seconds==.42 then delay.Fn() end end

check(idleModule.Profile("gojo").Speed<idleModule.Profile("deku").Speed,"calm and energetic characters have distinct idle timing")
local idleRig=Instance.new("Model",workspace)
local idleNeck=Instance.new("Motor6D",idleRig);idleNeck.Name="Neck";idleNeck.C0=CFrame.new()
local idleBase=idleNeck.C0
local simulation={PreSimulation=signal()}
local stopIdle=idleModule.Mount(idleRig,"gojo",simulation)
simulation.PreSimulation:Fire()
check(idleNeck.C0~=idleBase,"procedural idle adds a tiny pose offset")
stopIdle()
check(idleNeck.C0==idleBase,"stopping an idle restores the original joint pose")

-- Eight icon buttons form the side grid; the click control is the only bottom action.
local sideButtons=0
for _,item in ipairs(canvas:GetChildren()) do
 if item:IsA("TextButton") and item:FindFirstChild("Label") then
  local value=item.Label.Text
  if value=="SHOP" or value=="SUMMON" or value=="FIGHTERS" or value=="AURAS" or value=="WHEEL" or value=="CODES" or value=="REBIRTH" or value=="SELL" then
   if item.Position.X.Offset<230 and item.Position.Y.Offset>=260 and item.Position.Y.Offset<710 then sideButtons+=1 end
  end
 end
end
check(sideButtons==8,"main icon controls form an eight-button side grid")
check(findButton("SELL POWER")~=nil and findButton("BASE")~=nil,"Sell Power and Base remain prominent at the top")
local clickControl
for _,item in ipairs(canvas:GetChildren()) do if item:IsA("TextButton") and item:FindFirstChild("Label") and item.Label.Text:find("CLICK +",1,true)==1 then clickControl=item end end
check(clickControl and clickControl.Position.Y.Offset>=1100,"click button is at the bottom of the portrait HUD")
