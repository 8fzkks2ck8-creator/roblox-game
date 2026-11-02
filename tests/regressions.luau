local function check(value,message) assert(value,message);print("PASS "..message) end
local C=loadstring(CONFIG_SOURCE,"Config")()
require=function(target) assert(target=="CONFIG");return C end
-- Economy: actual config functions, including rare-tier and cosmetic pools.
for _,list in ipairs({C.Characters,C.Cosmetics}) do
 for _,boost in ipairs({false,true}) do for _,luck in ipairs({false,true}) do
  local sum=0;for _,v in ipairs(C.Odds(boost,luck,list)) do sum+=v end
  check(math.abs(sum-100)<.00001,"odds total 100 for "..(list==C.Characters and "fighters" or "auras").."/"..tostring(boost).."/"..tostring(luck))
  local rng={NextNumber=function() return 99.99999 end,NextInteger=function(_,a,b) assert(b>=a);return b end}
  check(C.Roll(list,boost,luck,rng)~=nil,"upper-tail roll has an available reward")
 end end
end
check(#C.WheelLayout()==20,"wheel has 20 weighted slots")
local function player(id) return {UserId=id,Kick=function(_,reason) error("Unexpected kick: "..reason) end} end
Random={new=function() return {NextNumber=function() return 1 end,NextInteger=function(_,a) return a end} end}
local P=loadstring(PROFILES_SOURCE,"Profiles")()
local p=player(1)
check(P.Load(p),"Studio memory profile loads without DataStore access")
local start=P.Cache[p].Coins
P.Train(p,17)
check(P.Strength(p)==17,"pending training updates strength immediately")
check(P.Change(p,function(d) d.Coins+=50 end),"economic transaction commits")
check(P.Cache[p].Strength==17 and P.Pending[p]==0 and P.Cache[p].Coins==start+50,"transaction flushes training exactly once")
P.Closing[p]=true
check(not P.Change(p,function() error("must not run") end),"external mutation rejected during close")
check(P.Train(p,1)==0,"training rejected during close")
P.Closing[p]=nil;P.Train(p,9);P.Close(p)
check(P.Cache[p]==nil and P.Ready[p]==nil,"close flushes and clears memory profile")
-- Live persistence path with a deterministic UpdateAsync stand-in.
memory=false
local live=loadstring(PROFILES_SOURCE,"ProfilesLive")()
local q=player(2);check(live.Load(q),"live profile acquires a session lease")
live.Train(q,23);failWrites=true
check(not live.Change(q,function(d) d.Coins+=1 end),"save failure is reported")
check(live.Pending[q]==23,"failed save preserves pending training")
failWrites=false
check(live.Change(q,function(d) d.Coins+=1 end),"save recovers after outage")
check(saved.Strength==23 and live.Pending[q]==0,"recovery does not double count training")
live.Train(q,7);live.Close(q)
check(saved.Strength==30 and saved.Lock==nil,"disconnect persists final strength and releases lease")
-- Actual clicker transactions: pending power is merged before selling or rebirthing.
local K=loadstring(CLICKER_SOURCE,"Clicker")()
memory=true
local clickProfiles=loadstring(PROFILES_SOURCE,"ClickProfiles")()
local clickPlayer=player(9);check(clickProfiles.Load(clickPlayer),"clicker profile loads with rebirth defaults")
check(clickProfiles.Cache[clickPlayer].Rebirths==0,"new profile starts at zero rebirths")
clickProfiles.Train(clickPlayer,100)
local before=clickProfiles.Cache[clickPlayer].Coins
local result
check(clickProfiles.Change(clickPlayer,function(d) result=K.Apply("Sell",d) end),"sale commits through profile transaction")
check(result.Ok and clickProfiles.Cache[clickPlayer].Coins==before+200 and clickProfiles.Strength(clickPlayer)==0,"sale converts pending power exactly once")
clickProfiles.Change(clickPlayer,function(d) result=K.Apply("Sell",d) end)
check(not result.Ok and clickProfiles.Cache[clickPlayer].Coins==before+200,"empty or repeated sale cannot duplicate coins")
local d=clickProfiles.Cache[clickPlayer]
d.Coins=0;local oldRebirth=d.Rebirths
clickProfiles.Change(clickPlayer,function(data) result=K.Apply("Rebirth",data) end)
check(not result.Ok and clickProfiles.Cache[clickPlayer].Rebirths==oldRebirth,"unaffordable rebirth is rejected")
clickProfiles.Change(clickPlayer,function(data) data.Coins=C.RebirthCost(data.Rebirths);data.Characters.gojo=3;data.Characters.yamcha=1;data.Equipped="gojo";data.Cosmetics.aura1=1;data.Aura="aura1";data.Codes.TEST=true;data.Tickets=2 end)
clickProfiles.Train(clickPlayer,25)
clickProfiles.Change(clickPlayer,function(data) result=K.Apply("Rebirth",data) end)
d=clickProfiles.Cache[clickPlayer]
check(result.Ok and d.Coins==0 and d.Strength==0 and d.Rebirths==1 and d.Gems==C.Clicker.RebirthGems,"rebirth resets coins and power and grants its permanent rewards")
check(d.Characters.gojo==3 and d.Cosmetics.aura1==1 and d.Codes.TEST and d.Tickets==2,"rebirth preserves inventory, auras, codes and tickets")
check(C.ClickGain("yamcha",1)>C.ClickGain("yamcha",0),"first rebirth improves even a common fighter")
clickProfiles.Change(clickPlayer,function(data) result=K.Apply("UnequipAll",data) end)
check(clickProfiles.Cache[clickPlayer].Equipped=="" and clickProfiles.Cache[clickPlayer].Aura=="" and C.ClickGain("",1)>=1,"unequip all keeps baseline clicking available")
clickProfiles.Change(clickPlayer,function(data) result=K.Apply("EquipBest",data) end)
check(result.Ok and clickProfiles.Cache[clickPlayer].Equipped=="gojo","equip best selects the strongest owned fighter")
local coins=clickProfiles.Cache[clickPlayer].Coins
clickProfiles.Change(clickPlayer,function(data) result=K.Apply("RecycleDuplicates",data) end)
d=clickProfiles.Cache[clickPlayer]
check(result.Ok and d.Characters.gojo==1 and d.Characters.yamcha==1 and d.Equipped=="gojo" and d.Coins==coins+2*C.Clicker.RecycleCoins,"recycling keeps every unique fighter and the equipped fighter")
clickProfiles.Change(clickPlayer,function(data) result=K.Apply("RecycleDuplicates",data) end)
check(not result.Ok and clickProfiles.Cache[clickPlayer].Coins==d.Coins,"repeated recycling cannot grant extra coins")
clickProfiles.Change(clickPlayer,function(data) data.Rebirths=C.Clicker.MaxRebirths;data.Coins=1e15;result=K.Apply("Rebirth",data) end)
check(not result.Ok,"rebirth count is capped")
-- New map contains six working stations and no battle arenas.
local W=loadstring(WORLD_SOURCE,"World")()
W.Build();local map=workspace:FindFirstChild("RiftWorld");local count=#map:GetDescendants()
local prompts=0;local actions={};local arches=0;local noCombat=true
for _,n in ipairs(map:GetDescendants()) do
 if n.ClassName=="ProximityPrompt" then prompts+=1;actions[n:GetAttribute("RiftAction")]=true end
 if n.Name=="Rainbow arch" then arches+=1 end
 if n.Name:lower():find("arena",1,true) or n.Name:lower():find("boss",1,true) then noCombat=false end
end
check(noCombat and W.Arenas==nil,"new map has no boss or arena geometry")
check(prompts==6 and actions.Sell and actions.Rebirth and actions.Summon and actions.Cosmetics and actions.Shop and actions.Wheel,"all six clicker stations are present")
check(map:FindFirstChild("Meadow stream")~=nil and map:FindFirstChild("Fountain water")~=nil and map:FindFirstChild("Training court")~=nil,"new map has its own stream, fountain and clicking court")
check(arches==120,"reference-inspired neon rainbow is generated")
W.Build();check(#workspace:FindFirstChild("RiftWorld"):GetDescendants()==count,"new map rebuilds without duplicate geometry")
check(count<900,"new map keeps its geometry budget")
print("WORLD_JSON:"..encode(export(workspace:FindFirstChild("RiftWorld"))))
print("LIGHTING_JSON:"..encode(export(lighting)))
-- Responsive geometry uses the actual layout module and current modal sizes.
local L=loadstring(LAYOUT_SOURCE,"ClientLayout")()
for _,size in ipairs({{390,844},{415,739},{768,1024},{1366,768},{1920,1080},{844,390}}) do
 local m=L.Measure(size[1],size[2])
 check(m.Scale>0 and m.Width*m.Scale<=size[1]+.01 and m.Height*m.Scale<=size[2]-50+.01,"canvas fits viewport "..size[1].."x"..size[2])
 check(m.WindowX>=0 and m.WindowX+m.WindowWidth<=m.Width and m.WindowY+m.WindowHeight<=m.Height,"inventory fits viewport "..size[1].."x"..size[2])
end
check(L.Measure(390,844).Portrait and not L.Measure(1366,768).Portrait,"phone and desktop select distinct layouts")
check(#L.Number(1000000000)<=6 and L.Number(0)=="0","large power and currency fit HUD labels")

-- Every requested addition has its promised rarity and a reachable roll pool.
local additions={yuji=5,eren=4,deku=5,kid_naruto=3,awakened_aizen=7,denji=4,beerus=6,boros=6,saitama=6,jotaro=5,dio=5,golden_experience_requiem=6,yuta=4,gogeta=5,vegito=5,ssb_goku=5,ssj_goku=4,broly=7,simon=7}
local ids={};local unique=true
for _,hero in ipairs(C.Characters) do if ids[hero.Id] then unique=false end;ids[hero.Id]=true end
check(#C.Characters==40 and unique,"expanded roster has 40 unique fighters")
for id,tier in pairs(additions) do
 local hero=C.Find(C.Characters,id)
 local odds=C.Odds(false,false,C.Characters);local start=0
 for i=1,tier-1 do start+=odds[i] end
 local pool={};for _,candidate in ipairs(C.Characters) do if candidate.Tier==tier and candidate.Rollable~=false then table.insert(pool,candidate.Id) end end
 local index=table.find(pool,id)
 local rng={NextNumber=function() return start+odds[tier]/2 end,NextInteger=function(_,a,b) assert(index and index>=a and index<=b);return index end}
 check(hero and hero.Tier==tier and C.Outfits[id] and C.Roll(C.Characters,false,false,rng).Id==id,"requested rarity and summon availability: "..id)
end
