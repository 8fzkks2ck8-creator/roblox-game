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
-- Map build executes the actual World source twice, checking repeatability.
local W=loadstring(WORLD_SOURCE,"World")()
W.Build();local first=workspace:FindFirstChild("RiftWorld")
local count=#first:GetDescendants();check(#W.Arenas==3,"three boss arenas are generated")
local prompts=0;for _,n in ipairs(first:GetDescendants()) do if n.ClassName=="ProximityPrompt" then prompts+=1 end end
check(prompts==5,"all five gameplay shrine prompts exist")
W.Build();check(#workspace:FindFirstChild("RiftWorld"):GetDescendants()==count,"map rebuild replaces previous world without duplicating geometry")
check(count<900,"map stays below 900 instances (original world: 2746)")
print("WORLD_JSON:"..encode(export(workspace:FindFirstChild("RiftWorld"))))
print("LIGHTING_JSON:"..encode(export(lighting)))

-- Boss lifecycle regression: actual Combat module with only rendering APIs stubbed.
local effectCalls=0
services.Debris={AddItem=function() end}
local realRequire=require
require=function(target) if target=="CONFIG" then return C end;return {Animate=function() effectCalls+=1 end,Play=function() effectCalls+=1 end} end
local chunk=loadstring(COMBAT_SOURCE,"Combat")
setfenv(chunk,setmetatable({typeof=function(x) if getmetatable(x)==nodeMeta then return "Instance" end;return typeof(x) end},{__index=getfenv()}))
local B=chunk()
require=realRequire
local rewards=0
local events={}
B.Init(W,function(_,kind,data) table.insert(events,{kind,data}) end,function() rewards+=1;return true end,function() return {Equipped="yamcha",Aura=""} end,function() return 0 end)
local fighter=Instance.new("Player",workspace);fighter.UserId=3
fighter.Character=Instance.new("Model",workspace)
local humanoid=Instance.new("Humanoid",fighter.Character);humanoid.Health=120;humanoid.MaxHealth=120;humanoid.WalkSpeed=21
humanoid.Died={Connect=function() return {Disconnect=function() end} end}
local rigRoot=Instance.new("Part",fighter.Character);rigRoot.Name="HumanoidRootPart";rigRoot.Position=Vector3.new(0,4,28)
local oldTypeof=typeof
typeof=function(x) if getmetatable(x)==nodeMeta then return "Instance" end;return oldTypeof(x) end
check(not B.StartBoss(fighter,"missing"),"unknown boss rejected")
check(not B.StartBoss(fighter,"oni"),"locked boss rejected below required strength")
local started,reason=B.StartBoss(fighter,"sentinel");print("BOSS_START",started,reason);check(started,"unlocked boss starts a match")
local match=B.Active[fighter]
check(match and match.Arena.Busy and humanoid.MaxHealth==C.Characters[1].Health,"boss reserves arena and applies fighter health")
check(not B.StartBoss(fighter,"sentinel"),"duplicate boss start rejected")
B.Finish(match,true,"win")
check(rewards==1 and not B.Active[fighter] and not match.Arena.Busy,"boss victory rewards once and releases arena")
check(humanoid.MaxHealth==120 and humanoid.WalkSpeed==21,"boss exit restores original health cap and movement")
B.Finish(match,true,"win")
check(rewards==1,"duplicate match completion cannot award twice")
check(B.StartBoss(fighter,"sentinel"),"arena can be reused after victory")
B.Remove(fighter)
check(rewards==1 and not B.Active[fighter],"leaving a fight grants no reward")

-- Responsive geometry and large-number formatting use the actual client layout module.
local L=loadstring(LAYOUT_SOURCE,"ClientLayout")()
for _,size in ipairs({{390,844},{415,739},{768,1024},{1366,768},{1920,1080},{844,390}}) do
 local m=L.Measure(size[1],size[2])
 check(m.Scale>0 and m.Width*m.Scale<=size[1]+.01 and m.Height*m.Scale<=size[2]-50+.01,"canvas fits viewport "..size[1].."x"..size[2])
 check(m.WindowX>=0 and m.WindowX+740<=m.Width and m.WindowY>=0 and m.WindowY+540<=m.Height,"store fits viewport "..size[1].."x"..size[2])
end
check(L.Measure(390,844).Portrait and not L.Measure(1366,768).Portrait,"phone and desktop select distinct layouts")
check(#L.Number(1000000000)<=6 and L.Number(0)=="0","large strength and currency fit HUD labels")
-- Check reference-map content and keep native studded surfaces on the main avenue.
local map=workspace:FindFirstChild("RiftWorld")
check(map:FindFirstChild("Red avenue")~=nil and map:FindFirstChild("Studded grass")~=nil,"reference map has red avenue and studded grass")
local arches,trees=0,0
for _,item in ipairs(map:GetChildren()) do
 if item.Name=="Rainbow arch" then arches+=1 elseif item.Name=="Block canopy" then trees+=1 end
end
check(arches==120 and trees>=40,"rainbow and block-tree scenery are generated")
