-- Exercise the real remote handler and receipt flow against memory profiles.
-- Rendering and avatar rig loading remain engine stand-ins here.
memory=true
local repl=Instance.new("ReplicatedStorage")
local sharedServer=Instance.new("Folder",repl);sharedServer.Name="AnimeRift"
local configNode=Instance.new("ModuleScript",sharedServer);configNode.Name="Config"
local scripts=Instance.new("ServerScriptService")
for _,name in ipairs({"Profiles","World","Avatars","Admin","Clicker","BrolySkill"}) do local item=Instance.new("ModuleScript",scripts);item.Name=name end
local serverScript=Instance.new("Script",scripts);serverScript.Name="Server"
services.ReplicatedStorage=repl;game.ReplicatedStorage=repl
services.Players=Instance.new("Players")
services.MarketplaceService={}
services.ProximityPromptService.PromptTriggered=signal()
eventNames.PlayerAdded=true;eventNames.PlayerRemoving=true;eventNames.CharacterAppearanceLoaded=true
function methods:GetPlayers()
 local players={};for _,child in ipairs(self:GetChildren()) do if child:IsA("Player") then table.insert(players,child) end end;return players
end
function methods:GetPlayerByUserId(id) for _,p in ipairs(self:GetPlayers()) do if p.UserId==id then return p end end end
function methods:FireClient(player,kind,payload) self.LastEvent={Player=player,Kind=kind,Data=payload} end
function methods:Kick(message) error("Unexpected server kick: "..message) end
function methods:IsDescendantOf(ancestor) local p=self.Parent;while p do if p==ancestor then return true end;p=p.Parent end;return false end
task.spawn=function(fn,...)
 local co=coroutine.create(fn);local ok,err=coroutine.resume(co,...);assert(ok,err);return co
end
local serverProfiles
require=function(target)
 if target=="CONFIG" or target==configNode then return C end
 if target.Name=="Profiles" then return serverProfiles end
 if target.Name=="World" then return W end
 if target.Name=="Clicker" then return K end
 if target.Name=="BrolySkill" then return loadstring(BROLY_SOURCE,"BrolySkill")() end
 if target.Name=="Avatars" then return {Init=function() end,Decorate=function() end} end
 if target.Name=="Admin" then return {Last={},IsOwner=function() return false end,Allowed=function() return false end,Execute=function() return {Ok=false} end} end
 error("Unexpected server module")
end
serverProfiles=loadstring(PROFILES_SOURCE,"ServerProfiles")()
local userServer=Instance.new("Player",services.Players);userServer.UserId=555
userServer.Character=Instance.new("Model",workspace)
local serverHum=Instance.new("Humanoid",userServer.Character);serverHum.Health=100
local serverRoot=Instance.new("Part",userServer.Character);serverRoot.Name="HumanoidRootPart"
local simulatedClock=100
local serverChunk=loadstring(SERVER_SOURCE,"Server")
setfenv(serverChunk,setmetatable({script=serverScript,os=setmetatable({clock=function() return simulatedClock end},{__index=os})},{__index=getfenv()}))
serverChunk()
check(sharedServer:GetAttribute("ServerStatus")=="Ready","clicker server boots without any combat module")
local remoteServer=sharedServer:FindFirstChild("Request")
local function requestServer(action,arg)
 simulatedClock+=.2
 return remoteServer.OnServerInvoke(userServer,action,arg)
end
check(serverProfiles.Ready[userServer],"server joins and initializes a clicker profile")
local initialState=requestServer("State").State
check(initialState.Rebirths==0 and initialState.SellValue==0 and initialState.BossDamage==nil and initialState.InMatch==nil,"server snapshot exposes clicker state and no battle state")
check(requestServer("Train").Ok,"training remote awards server-computed power")
local firstPower=serverProfiles.Strength(userServer)
local immediate=remoteServer.OnServerInvoke(userServer,"Train")
check(not immediate.Ok and serverProfiles.Strength(userServer)==firstPower,"training spam cannot bypass the click interval")
local initialCoins=serverProfiles.Cache[userServer].Coins
check(requestServer("Sell").Ok,"sell remote runs the atomic clicker transaction")
check(serverProfiles.Cache[userServer].Coins==initialCoins+firstPower*C.Clicker.SellRate and serverProfiles.Strength(userServer)==0,"server sale uses actual pending power")
check(not requestServer("Sell").Ok and serverProfiles.Cache[userServer].Coins==initialCoins+firstPower*C.Clicker.SellRate,"repeating sell remote cannot duplicate currency")
check(not requestServer("Boss","sentinel").Ok and not requestServer("Attack","R").Ok,"legacy combat remotes are rejected")
local invalid=remoteServer.OnServerInvoke(userServer,"Sell",{Amount=999999})
check(not invalid.Ok,"client-supplied transaction payloads are rejected")
serverProfiles.Change(userServer,function(d) d.Coins=C.RebirthCost(d.Rebirths);d.Characters.gojo=3;d.Equipped="gojo" end)
check(requestServer("Rebirth").Ok and serverProfiles.Cache[userServer].Rebirths==1,"rebirth remote increments persistent progression")
check(requestServer("UnequipAll").Ok and serverProfiles.Cache[userServer].Equipped=="","unequip remote clears selected fighter")
check(requestServer("EquipBest").Ok and serverProfiles.Cache[userServer].Equipped=="gojo","equip-best remote validates actual ownership")
check(requestServer("RecycleDuplicates").Ok and serverProfiles.Cache[userServer].Characters.gojo==1,"recycle remote preserves a unique equipped fighter")
local starter=C.Products.Starter;local previousId=starter.Id;starter.Id=12345
local receipt={PlayerId=555,ProductId=12345,PurchaseId="receipt-clicker-1"}
local beforeTickets=serverProfiles.Cache[userServer].Tickets
local firstReceipt=services.MarketplaceService.ProcessReceipt(receipt)
local secondReceipt=services.MarketplaceService.ProcessReceipt(receipt)
check(firstReceipt.Name=="PurchaseGranted" and secondReceipt.Name=="PurchaseGranted" and serverProfiles.Cache[userServer].Tickets==beforeTickets+starter.Tickets,"receipt replay grants a purchased pack exactly once")
serverProfiles.Closing[userServer]=true
local blocked=services.MarketplaceService.ProcessReceipt({PlayerId=555,ProductId=12345,PurchaseId="receipt-clicker-2"})
check(blocked.Name=="NotProcessedYet","purchase fulfillment waits when a profile is closing")
serverProfiles.Closing[userServer]=nil;starter.Id=previousId

check(requestServer("Home").Ok and userServer.Character.LastPivot==W.Spawn,"Base action returns the character to the clicking court")

check(not requestServer("BrolySkill").Ok,"Broly skill remote rejects a different equipped fighter")
serverProfiles.Change(userServer,function(d) d.Characters.broly=1;d.Equipped="broly" end)
local skillStart=simulatedClock+.2
local activation=requestServer("BrolySkill")
check(activation.Ok and activation.State.Charging and requestServer("State").State.BrolySkill.Charging,"Broly skill remote starts authoritative charge")
local powerBefore=serverProfiles.Strength(userServer)
check(not requestServer("Train").Ok and serverProfiles.Strength(userServer)==powerBefore,"server rejects training during the Rage wind-up")
check(not requestServer("BrolySkill").Ok,"Broly skill cannot be activated twice during cooldown")
simulatedClock=skillStart+C.BrolySkill.Windup
local baseGain=C.ClickGain("broly",serverProfiles.Cache[userServer].Rebirths,serverProfiles.Cache[userServer].Aura)
check(requestServer("Train").Ok and serverProfiles.Strength(userServer)==powerBefore+baseGain*C.BrolySkill.Multiplier,"charged Rage multiplies actual server-granted click power")
simulatedClock=skillStart+C.BrolySkill.Windup+C.BrolySkill.Duration
powerBefore=serverProfiles.Strength(userServer)
check(requestServer("Train").Ok and serverProfiles.Strength(userServer)==powerBefore+baseGain,"Rage bonus expires on the server")
