local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Market=game:GetService("MarketplaceService")
local Policy=game:GetService("PolicyService")
local Run=game:GetService("RunService")
local folder=RS:WaitForChild("AnimeRift")
local C=require(folder.Config)
local remote=Instance.new("RemoteFunction",folder); remote.Name="Request"
local event=Instance.new("RemoteEvent",folder); event.Name="Event"
folder:SetAttribute("ServerStatus","Starting")
remote.OnServerInvoke=function() return {Ok=false,Loading=true,Message="Server is starting..."} end
local function boot()
local P=require(script.Parent.Profiles)
local W=require(script.Parent.World).Build()
local A=require(script.Parent.Avatars)
local Clicker=require(script.Parent.Clicker)
local Admin=require(script.Parent.Admin)
local policies,limits,working,training={},{},{},{}
local rng=Random.new()
local function send(p,kind,data) if p.Parent==Players then event:FireClient(p,kind,data) end end
local function allowed(p) return policies[p]==true or (Run:IsStudio() and C.StudioMemory) end
local function lucky(p,d) return allowed(p) and d.LuckUntil>os.time() end
local function state(p)
 local d=P.Cache[p]; if not d then return nil end
 return {Strength=P.Strength(p),ClickGain=C.ClickGain(d.Equipped,d.Rebirths,d.Aura),SellValue=P.Strength(p)*C.Clicker.SellRate,Rebirths=d.Rebirths,RebirthCost=C.RebirthCost(d.Rebirths),Coins=d.Coins,Gems=d.Gems,Tickets=d.Tickets,Boosted=d.Boosted,Characters=d.Characters,Cosmetics=d.Cosmetics,Equipped=d.Equipped,Aura=d.Aura,Wins=d.Wins,LuckUntil=d.LuckUntil,Lucky=lucky(p,d),PaidAllowed=allowed(p),WheelReady=d.WheelDay<math.floor(os.time()/86400),ServerTime=os.time(),Studio=Run:IsStudio(),IsOwner=Admin.IsOwner(p),IsAdmin=Admin.Allowed(p)}
end
local function sync(p) send(p,"State",state(p)) end
local function edit(p,fn)
 local ok=P.Change(p,fn)
 if not ok then return false,"Could not save. Please try again." end
 sync(p); return true
end
A.Init(function(p) return P.Cache[p] end)
local function onCharacter(p,m)
 local root=m:WaitForChild("HumanoidRootPart",10); if not root or p.Character~=m or not P.Ready[p] then return end
 if not m:GetAttribute("RiftCharacterId") then m:PivotTo(W.Spawn) end
 task.wait(0.2); if p.Character~=m or not m.Parent then return end
 A.Decorate(p)
 if p.Character~=m then return end

end
local function join(p)
 -- Load free inventory independently of the external policy request.
 if not p.Parent then return end
 policies[p]=false
 if not P.Load(p) then return end
 if not p.Parent then P.Close(p); policies[p]=nil; return end
 p.CharacterAdded:Connect(function(m) onCharacter(p,m) end)
 p.CharacterAppearanceLoaded:Connect(function(character) if P.Ready[p] and p.Character==character then A.Decorate(p) end end)
 if p.Character then task.spawn(onCharacter,p,p.Character) end
 sync(p)
 if not Run:IsStudio() then task.spawn(function()
  local ok,info=pcall(function() return Policy:GetPolicyInfoForPlayerAsync(p) end)
  if not p.Parent or not P.Ready[p] then return end
  policies[p]=ok and type(info)=="table" and info.ArePaidRandomItemsRestricted==false
  sync(p)
 end) end
end
Players.PlayerAdded:Connect(join)
for _,p in ipairs(Players:GetPlayers()) do task.spawn(join,p) end
Players.PlayerRemoving:Connect(function(p) P.Close(p); policies[p]=nil; limits[p]=nil; working[p]=nil;training[p]=nil; Admin.Last[p.UserId]=nil end)
local function handle(p,action,arg)
 local d=P.Cache[p]
 if action=="State" then return {Ok=true,State=state(p)} end
 if P.Closing[p] then return {Ok=false,Message="Your progress is being saved."} end
 if action=="Admin" then return Admin.Execute(p,arg,P,sync,send) end
 if action=="Train" then
  local now=os.clock()
  if now-(training[p] or -math.huge)<C.Training.Interval then return {Ok=false} end
  local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  if not h or h.Health<=0 then return {Ok=false,Message="Wait for your character to spawn."} end
  training[p]=now
  local gain=P.Train(p,C.ClickGain(d.Equipped,d.Rebirths,d.Aura))
  send(p,"Training",{Gain=gain,Strength=P.Strength(p),ClickGain=C.ClickGain(d.Equipped,d.Rebirths,d.Aura),SellValue=P.Strength(p)*C.Clicker.SellRate})
  return {Ok=true}
 end
 if Clicker.Actions[action] then
  local result
  local ok,err=edit(p,function(data) result=Clicker.Apply(action,data,arg) end)
  if not ok then return {Ok=false,Message=err} end
  if result.Ok and (action=="EquipBest" or action=="UnequipAll") then A.Decorate(p) end
  if result.Ok and (action=="Sell" or action=="Rebirth") then send(p,"ClickerReward",{Kind=action,Amount=result.Amount or 0}) end
  return result
 end
 if action=="PreviewProduct" then
  if not Run:IsStudio() or not C.StudioMemory then return {Ok=false,Message="Pack previews only work in Studio test mode."} end
  local product=C.Products[arg]
  if not product then return {Ok=false,Message="Unknown product."} end
  local ok,err=edit(p,function(data)
   C.GrantProduct(data,product)
  end)
  if ok and product.Character then send(p,"Reveal",{Kind="Character",Id=product.Character}) end
  return {Ok=ok,Message=err or "STUDIO PREVIEW • Test rewards added. No Robux charged; resets when you stop."}
 end
 if action=="Purchase" then
  local product=C.Products[arg]
  if not product then return {Ok=false,Message="Unknown product."} end
  if not allowed(p) then return {Ok=false,Message="Paid random rewards are unavailable for this account. Sell power and rebirth to earn coins and gems."} end
  if Run:IsStudio() or product.Id==0 then return {Ok=false,Message="Purchase not enabled. Configure product IDs and test in a published experience."} end
  return {Ok=true,ProductId=product.Id}
 end
 if action=="Spin" then
  if arg~="Coins" and arg~="Ticket" and arg~="Boosted" then return {Ok=false,Message="Invalid spin."} end
  if arg~="Coins" and not allowed(p) then return {Ok=false,Message="Ticket rolls unavailable. Use earned coins for a free-path roll."} end
  local item=C.Roll(C.Characters,arg=="Boosted",lucky(p,d),rng); local message; local granted=false
  local ok,err=edit(p,function(data)
   granted=false
   if arg=="Coins" then if data.Coins<C.SpinCost then message="Need "..C.SpinCost.." coins."; return end; data.Coins=data.Coins-C.SpinCost
   elseif arg=="Ticket" then if data.Tickets<1 then message="No spin tickets."; return end; data.Tickets=data.Tickets-1
   else if data.Boosted<1 then message="No boosted tickets."; return end; data.Boosted=data.Boosted-1 end
   data.Characters[item.Id]=(data.Characters[item.Id] or 0)+1
   -- Duplicates remain in inventory and award 50 free coins.
   if data.Characters[item.Id]>1 then data.Coins=data.Coins+C.Economy.CharacterDuplicate end
   granted=true
  end)
  if not ok or not granted then return {Ok=false,Message=err or message} end
  send(p,"Reveal",{Kind="Character",Id=item.Id}); return {Ok=true}
 elseif action=="Cosmetic" then
  if arg~="Standard" and arg~="Boosted" then return {Ok=false,Message="Invalid cosmetic roll."} end
  local cost=arg=="Boosted" and C.Economy.CosmeticBoosted or C.Economy.CosmeticStandard; local item=C.Roll(C.Cosmetics,arg=="Boosted",lucky(p,d),rng); local granted=false
  local ok,err=edit(p,function(data)
   granted=false; if data.Gems<cost then return end
   data.Gems=data.Gems-cost; data.Cosmetics[item.Id]=(data.Cosmetics[item.Id] or 0)+1
   if data.Cosmetics[item.Id]>1 then data.Gems=data.Gems+C.Economy.CosmeticDuplicate end
   granted=true
  end)
  if not ok or not granted then return {Ok=false,Message=err or ("Need "..cost.." gems.")} end
  send(p,"Reveal",{Kind="Cosmetic",Id=item.Id}); return {Ok=true}
 elseif action=="Equip" then
  if not C.Find(C.Characters,arg) or not d.Characters[arg] then return {Ok=false,Message="Character not owned."} end
  local ok,err=edit(p,function(data) data.Equipped=arg end); if ok then A.Decorate(p) end
  return {Ok=ok,Message=err or "Character equipped!"}
 elseif action=="Aura" then
  if arg~="" and (not C.Find(C.Cosmetics,arg) or not d.Cosmetics[arg]) then return {Ok=false,Message="Cosmetic not owned."} end
  local ok,err=edit(p,function(data) data.Aura=arg end); if ok then A.Decorate(p) end
  return {Ok=ok,Message=err or "Cosmetic equipped!"}
 elseif action=="Code" then
  local code=string.upper((arg or ""):gsub("%s+","")); local gift=C.Codes[code]
  if not gift then return {Ok=false,Message="That code does not exist."} end
  local redeemed=false
  local ok,err=edit(p,function(data)
   redeemed=false; if data.Codes[code] then return end
   data.Codes[code]=true; data.Coins=data.Coins+(gift.Coins or 0); data.Gems=data.Gems+(gift.Gems or 0); redeemed=true
  end)
  return {Ok=ok and redeemed,Message=err or (redeemed and ("REDEEMED! "..code.." • +"..(gift.Coins or gift.Gems)..(gift.Coins and " coins" or " gems")) or "Code already redeemed.")}
 elseif action=="Wheel" then
  local number=rng:NextNumber(0,100); local total=0; local index=1
  for i,v in ipairs(C.Wheel) do total=total+v.Weight; if number<total then index=i; break end end
  local prize=C.Wheel[index]; local granted=false
  local ok,err=edit(p,function(data)
   granted=false; local day=math.floor(os.time()/86400); if data.WheelDay>=day then return end
   data.WheelDay=day; data.Coins=data.Coins+(prize.Coins or 0); data.Gems=data.Gems+(prize.Gems or 0); data.Tickets=data.Tickets+(prize.Tickets or 0); granted=true
  end)
  if not ok or not granted then return {Ok=false,Message=err or "Come back after the next 00:00 UTC reset."} end
  local slots={};for slot,prizeIndex in ipairs(C.WheelLayout()) do if prizeIndex==index then table.insert(slots,slot) end end
  send(p,"WheelResult",{Index=index,Slot=slots[rng:NextInteger(1,#slots)],Name=prize.Name}); return {Ok=true}
 end
 return {Ok=false,Message="Unknown action."}
end
remote.OnServerInvoke=function(p,action,arg)
 if type(action)~="string" or (arg~=nil and type(arg)~="string") or (arg and #arg>80) then return {Ok=false} end
 if not P.Ready[p] then return {Ok=false,Message="Loading your inventory..."} end
 local now=os.clock(); local l=limits[p] or {At=now,Count=0}; limits[p]=l
 if now-l.At>=1 then l.At=now; l.Count=0 end
 l.Count=l.Count+1; if l.Count>15 then return {Ok=false} end
 if working[p] then return {Ok=false,Message="One moment..."} end
 local ownsWork=true
 if ownsWork then working[p]=true end
 local ok,result=pcall(handle,p,action,arg)
 if ownsWork then working[p]=nil end
 if not ok then warn("Anime Rift action failed:",result); return {Ok=false,Message="Action unavailable. Try again."} end
 return result
end
Market.ProcessReceipt=function(receipt)
 local p=Players:GetPlayerByUserId(receipt.PlayerId)
 if not p or not P.Ready[p] then return Enum.ProductPurchaseDecision.NotProcessedYet end
 local product
 for _,v in pairs(C.Products) do if v.Id>0 and v.Id==receipt.ProductId then product=v; break end end
 if not product then return Enum.ProductPurchaseDecision.NotProcessedYet end
 local newGrant=false
 local ok=P.Change(p,function(data)
  newGrant=false
  if data.Receipts[receipt.PurchaseId] then return end
  C.GrantProduct(data,product)
  data.Receipts[receipt.PurchaseId]=true;newGrant=true
 end)
 if not ok then return Enum.ProductPurchaseDecision.NotProcessedYet end
 sync(p);if newGrant and product.Character then send(p,"Reveal",{Kind="Character",Id=product.Character}) end
 send(p,"Toast","Purchase delivered to your inventory!")
 return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Handle kiosk prompts on the server; only the triggering player's menu opens.
game:GetService("ProximityPromptService").PromptTriggered:Connect(function(prompt,p)
 local world=workspace:FindFirstChild("RiftWorld")
 if not world or not prompt:IsDescendantOf(world) then return end
 local name=prompt:GetAttribute("RiftAction")
 if P.Ready[p] and (name=="Shop" or name=="Summon" or name=="Cosmetics" or name=="Wheel" or name=="Sell" or name=="Rebirth") then
  send(p,"OpenMenu",name)
 end
end)
folder:SetAttribute("ServerStatus","Ready")
end
local ok,err=xpcall(boot,debug.traceback)
if not ok then
 warn("[Anime Rift startup] "..tostring(err))
 folder:SetAttribute("ServerStatus","Error")
 folder:SetAttribute("StartupError",tostring(err):sub(1,700))
 remote.OnServerInvoke=function() return {Ok=false,Message="Server startup failed. See the red error in Studio Output."} end
end
