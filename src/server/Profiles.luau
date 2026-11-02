local Players=game:GetService("Players")
local DSS=game:GetService("DataStoreService")
local Run=game:GetService("RunService")
local Http=game:GetService("HttpService")
local C=require(game.ReplicatedStorage.AnimeRift.Config)
local memory=Run:IsStudio() and C.StudioMemory
-- An unpublished Studio place must never request a DataStore in memory mode.
local Store
if not memory then Store=DSS:GetDataStore(C.DataStore) end
local P={Cache={},Ready={},Busy={},Pending={},Closing={}}
local token=game.JobId..Http:GenerateGUID(false)
local function copy(x) if type(x)~="table" then return x end local t={} for k,v in pairs(x) do t[k]=copy(v) end return t end
local function fresh()
 local hero=C.Roll(C.Characters,false,false,Random.new())
 return {Coins=C.Economy.StartingCoins,Gems=0,Tickets=0,Boosted=0,Characters={[hero.Id]=1},Cosmetics={},Equipped=hero.Id,Aura="",Codes={},Receipts={},LuckUntil=0,WheelDay=-1,Wins=0,Strength=0,Rebirths=0}
end
function P.Load(player)
 local seed=fresh(); local result
 local ok=pcall(function()
 if memory then result=seed; return end
 result=Store:UpdateAsync("p"..player.UserId,function(old)
  local d=old or seed
  if d.Lock and d.Lock.Token~=token and (tonumber(d.Lock.Until) or 0)>os.time() then return nil end
  d.Lock={Token=token,Until=os.time()+180}; return d
 end)
 end)
 if not ok or not result then player:Kick("Data is busy or unavailable. Please rejoin in a moment."); return false end
 -- Add missing fields without discarding existing progress on schema upgrades.
 for key,value in pairs(seed) do if result[key]==nil then result[key]=copy(value) end end
 result.Strength=math.clamp(result.Strength or 0,0,C.Training.MaxStrength)
 P.Pending[player]=0;P.Cache[player]=result; P.Ready[player]=true
 return true
end
function P.Strength(player)
 local d=P.Cache[player]
 return math.min(C.Training.MaxStrength,(d and d.Strength or 0)+(P.Pending[player] or 0))
end
function P.Train(player,amount)
 if not P.Ready[player] or P.Closing[player] then return 0 end
 local gain=math.min(amount,C.Training.MaxStrength-P.Strength(player))
 P.Pending[player]=(P.Pending[player] or 0)+gain
 return gain
end
-- Every economic mutation commits atomically. Receipt IDs and rewards share one write.
function P.Change(player,fn,finalizing)
 while P.Busy[player] do task.wait(0.05) end
 if not P.Ready[player] or (P.Closing[player] and not finalizing) then return false end
 P.Busy[player]=true
 local pending=P.Pending[player] or 0
 local function merge(d) if d.Rebirths==nil then d.Rebirths=0 end;d.Strength=math.min(C.Training.MaxStrength,(d.Strength or 0)+pending) end
 local result; local ok=pcall(function()
  if memory then result=copy(P.Cache[player]); merge(result);fn(result); P.Cache[player]=result; return end
  result=Store:UpdateAsync("p"..player.UserId,function(d)
   if not d or not d.Lock or d.Lock.Token~=token then return nil end
   merge(d);fn(d); d.Lock.Until=os.time()+180; return d
  end)
  if not result then error("Profile ownership lost") end
  P.Cache[player]=result
 end)
 if ok then P.Pending[player]=math.max(0,(P.Pending[player] or 0)-pending) end
 P.Busy[player]=nil
 if not ok then warn("Anime Rift profile transaction failed for",player.UserId); return false end
 return true,result
end
function P.Close(player)
 if P.Closing[player] then while P.Closing[player] do task.wait(.05) end;return end
 P.Closing[player]=true
 while P.Busy[player] do task.wait(0.05) end
 local flushed=true
 if P.Ready[player] then
  flushed=false
  for attempt=1,3 do
   if P.Change(player,function() end,true) then flushed=true;break end
   task.wait(attempt*.5)
  end
 end
 if not flushed then warn("Could not flush recent strength for "..player.UserId.."; leaving saved profile locked until its lease expires.") end
 P.Ready[player]=nil
 if not memory and flushed then
  pcall(function() Store:UpdateAsync("p"..player.UserId,function(d)
   if d and d.Lock and d.Lock.Token==token then d.Lock=nil; return d end
   return nil
  end) end)
 end
 P.Cache[player]=nil;P.Pending[player]=nil;P.Closing[player]=nil
end
task.spawn(function()
 while task.wait(15) do
  for player in pairs(P.Ready) do if not P.Closing[player] then task.spawn(function()
   if not P.Closing[player] and not P.Change(player,function() end) and player.Parent and not P.Closing[player] then player:Kick("Data connection lost. Rejoin to protect progress.") end
  end) end end
 end
end)
game:BindToClose(function()
 local n=0
 for player in pairs(P.Ready) do n=n+1; task.spawn(function() P.Close(player); n=n-1 end) end
 local untilTime=os.clock()+25
 while n>0 and os.clock()<untilTime do task.wait(0.1) end
end)
return P
