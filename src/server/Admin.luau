local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local C=require(game.ReplicatedStorage.AnimeRift.Config)
local A={Last={}}
local rng=Random.new()
function A.OwnerId()
 local shared=game.ReplicatedStorage.AnimeRift
 local settings=shared.FindFirstChild and shared:FindFirstChild("AdminSettings")
 local entry=settings and settings:FindFirstChild("OwnerUserId")
 local configured=tonumber(entry and entry.Value) or 0
 if configured<=0 then configured=tonumber(C.Admin.OwnerUserId) or 0 end
 if configured>0 then return math.floor(configured) end
 if game.CreatorType==Enum.CreatorType.User then return tonumber(game.CreatorId) or 0 end
 return 0
end
function A.IsOwner(p)
 local owner=A.OwnerId()
 return owner>0 and p.UserId==owner
end
function A.Allowed(p)
 if A.IsOwner(p) then return true end
 if Run:IsStudio() and C.Admin.StudioEnabled then return true end
 for _,id in ipairs(C.Admin.UserIds or {}) do if p.UserId==tonumber(id) then return true end end
 return false
end
function A.Execute(p,command,profiles,sync,send)
 if type(command)~="string" then return {Ok=false,Message="Enter a character ID, for example give marlon."} end
 command=command:lower():match("^%s*(.-)%s*$")
 if type(command)=="string" and command:match("^give%s+") then
  if not A.IsOwner(p) then return {Ok=false,Message="Owner access is not configured for this account. Stop Play, then set ReplicatedStorage > AnimeRift > AdminSettings > OwnerUserId to your Roblox user ID ("..p.UserId..")."} end
  local id=command:match("^give%s+([%w_]+)%s*$")
  local hero=id and C.Find(C.Characters,id:lower())
  if not hero then return {Ok=false,Message="Use give character_id, for example give marlon."} end
  local ok=profiles.Change(p,function(d) d.Characters[hero.Id]=(d.Characters[hero.Id] or 0)+1 end)
  if ok then sync(p);send(p,"Reveal",{Kind="Character",Id=hero.Id}) end
  return {Ok=ok,Message=ok and ("Granted "..hero.Name.." to your inventory.") or "Grant could not save."}
 end
 if not A.Allowed(p) then return {Ok=false,Message="Admin access denied."} end
 local valid={random=true,coins=true,gems=true,confetti=true,disco=true,resetwheel=true}
 if not valid[command] then return {Ok=false,Message="Unknown admin command."} end
 local now=os.clock()
 if A.Last[p.UserId] and now-A.Last[p.UserId]<C.Admin.Cooldown then return {Ok=false,Message="Wait a few seconds before the next event."} end
 A.Last[p.UserId]=now
 if command=="random" then local pool={"coins","gems","confetti","disco"};command=pool[rng:NextInteger(1,#pool)] end
 if command=="resetwheel" then
  local ok=profiles.Change(p,function(d) d.WheelDay=-1 end)
  if ok then sync(p) end
  return {Ok=ok,Message=ok and "Your daily wheel is ready again." or "Could not save wheel reset."}
 end
 local delivered,failed=0,0
 for _,target in ipairs(Players:GetPlayers()) do
  if profiles.Ready[target] then
   local ok=true
   if command=="coins" then ok=profiles.Change(target,function(d) d.Coins=d.Coins+C.Admin.CoinGift end)
   elseif command=="gems" then ok=profiles.Change(target,function(d) d.Gems=d.Gems+C.Admin.GemGift end) end
   if ok then
    delivered=delivered+1;sync(target)
    local text=command=="coins" and ("COIN SHOWER! +"..C.Admin.CoinGift.." coins") or command=="gems" and ("GEM PARTY! +"..C.Admin.GemGift.." gems") or command=="disco" and "RIFT DISCO!" or "CONFETTI PARTY!"
    send(target,"AdminEvent",{Kind=command,Text=text,Duration=C.Admin.Duration})
   else failed=failed+1 end
  end
 end
 return {Ok=true,Message="Event: "..command.." • "..delivered.." players"..(failed>0 and (" • "..failed.." save failures") or "")}
end
return A
