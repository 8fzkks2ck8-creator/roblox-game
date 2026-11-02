-- Run the real client UI in a lightweight event model. This checks wiring and
-- construction, not Roblox rendering, hit testing, or actual device input.
local function signal()
 local callbacks={}
 return {Connect=function(_,fn)
  local entry={Fn=fn,Active=true};table.insert(callbacks,entry)
  return {Disconnect=function() entry.Active=false end}
 end,Fire=function(_,...) for _,entry in ipairs(table.clone(callbacks)) do if entry.Active then entry.Fn(...) end end end}
end
local eventNames={Activated=true,MouseEnter=true,MouseLeave=true,Changed=true,CharacterAdded=true,OnClientEvent=true}
local oldIndex=nodeMeta.__index
nodeMeta.__index=function(t,k)
 local value=oldIndex(t,k);if value~=nil then return value end
 if eventNames[k] then
  local signals=rawget(t,"_signals");if not signals then signals={};rawset(t,"_signals",signals) end
  if not signals[k] then signals[k]=signal() end;return signals[k]
 end
 return methods.FindFirstChild(t,k)
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
local guiClasses={Frame=true,TextLabel=true,TextButton=true,ImageLabel=true,ImageButton=true,ViewportFrame=true,ScrollingFrame=true,TextBox=true}
local oldIsA=methods.IsA
methods.IsA=function(self,class) return class=="GuiObject" and guiClasses[self.ClassName]==true or oldIsA(self,class) end
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
for _,name in ipairs({"Config","Polish","ClientLayout"}) do local module=Instance.new("ModuleScript",shared);module.Name=name end
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
workspace.CurrentCamera=Instance.new("Camera");workspace.CurrentCamera.ViewportSize=Vector2.new(390,844)
local polishStub={Aura=function() end,ClearGuard=function() end,Train=function() end,Pulse=function() end,Guard=function() end}
require=function(target)
 if target.Name=="Config" then return C elseif target.Name=="Polish" then return polishStub elseif target.Name=="ClientLayout" then return L end
 error("Unexpected require")
end
loadstring(CLIENT_SOURCE,"Client")()
local ui=playerGui:FindFirstChild("AnimeRiftUI");check(ui~=nil,"client builds the UI on a portrait phone")
local canvas=ui:FindFirstChildOfClass("Frame")
local data={ServerTime=os.time(),Coins=1000,Gems=0,Wins=0,Strength=0,SellValue=0,Rebirths=0,RebirthCost=C.RebirthCost(0),ClickGain=1,Characters={yamcha=1},Cosmetics={},Equipped="yamcha",Aura="",LuckUntil=0,WheelReady=true,Studio=true,PaidAllowed=true}
events.OnClientEvent:Fire("State",data)
local function findButton(text,parent)
 for _,item in ipairs((parent or canvas):GetDescendants()) do
  if item:IsA("TextButton") and item:FindFirstChild("Label") and item.Label.Text==text then return item end
 end
 error("Missing button: "..text)
end
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
