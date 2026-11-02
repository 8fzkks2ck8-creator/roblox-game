-- All economy mutations run inside Profiles.Change/UpdateAsync on the server.
local C=require(game.ReplicatedStorage.AnimeRift.Config)
local K={Actions={Sell=true,Rebirth=true,EquipBest=true,UnequipAll=true,RecycleDuplicates=true}}
function K.Apply(action,d)
 if action=="Sell" then
  local power=math.max(0,math.floor(d.Strength or 0))
  if power==0 then return {Ok=false,Message="Click to build power before selling."} end
  local coins=power*C.Clicker.SellRate
  d.Strength=0;d.Coins+=coins
  return {Ok=true,Amount=coins,Message="Sold "..power.." power for "..coins.." coins!"}
 elseif action=="Rebirth" then
  local rebirths=d.Rebirths or 0
  if rebirths>=C.Clicker.MaxRebirths then return {Ok=false,Message="Maximum rebirths reached."} end
  local cost=C.RebirthCost(rebirths)
  if d.Coins<cost then return {Ok=false,Message="You need "..cost.." coins to rebirth."} end
  d.Coins=0;d.Strength=0;d.Rebirths=rebirths+1;d.Gems+=C.Clicker.RebirthGems
  return {Ok=true,Amount=C.Clicker.RebirthGems,Message="Rebirth complete! +"..C.Clicker.RebirthGems.." gems and a permanent power bonus."}
 elseif action=="EquipBest" then
  local best
  for _,hero in ipairs(C.Characters) do
   if (d.Characters[hero.Id] or 0)>0 and (not best or C.ClickGain(hero.Id)>C.ClickGain(best.Id)) then best=hero end
  end
  if not best then return {Ok=false,Message="Summon a fighter first."} end
  d.Equipped=best.Id
  return {Ok=true,Message="Equipped "..best.Name.."!"}
 elseif action=="UnequipAll" then
  d.Equipped="";d.Aura=""
  return {Ok=true,Message="Fighter and aura unequipped. Base clicking stays available."}
 elseif action=="RecycleDuplicates" then
  local removed=0
  for id,count in pairs(d.Characters) do
   local extra=math.max(0,math.floor(count)-1)
   if extra>0 then d.Characters[id]=1;removed+=extra end
  end
  if removed==0 then return {Ok=false,Message="No duplicate fighters to recycle."} end
  local coins=removed*C.Clicker.RecycleCoins;d.Coins+=coins
  return {Ok=true,Amount=coins,Message="Recycled "..removed.." extra copies for "..coins.." coins. One of every fighter was kept."}
 end
 return {Ok=false,Message="Unknown clicker action."}
end
return K
