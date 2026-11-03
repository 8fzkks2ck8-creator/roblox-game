-- Standalone: luau tests/broly_skill.luau. No Roblox services or persistent data.
local S=require("../src/server/BrolySkill")
local total=0
local function check(value,message) assert(value,message);total+=1;print("PASS "..message) end
local function signal()
 local entries={}
 return {Connect=function(_,fn)
  local e={Active=true,Fn=fn};table.insert(entries,e);return {Disconnect=function() e.Active=false end}
 end,Fire=function() for _,e in ipairs(entries) do if e.Active then e.Fn() end end end,Count=function()
  local n=0;for _,e in ipairs(entries) do if e.Active then n+=1 end end;return n
 end}
end
local function character()
 local h={Health=100,Died=signal()}
 return {Humanoid=h,FindFirstChildOfClass=function(_,class) return class=="Humanoid" and h or nil end}
end
local now=0
local config={Windup=26,Duration=20,Multiplier=3,Cooldown=90}
local skill=S.new(config,function() return now end)
local changes=signal()
local p={Character=character(),GetPropertyChangedSignal=function() return changes end}
local data={Equipped="broly",Characters={},Coins=123,Strength=456}
check(not skill:Activate(p,data).Ok,"unowned Broly cannot activate Legendary Rage")
data.Characters.broly=1;data.Equipped="gojo"
check(not skill:Activate(p,data).Ok,"another equipped fighter cannot use Broly's skill")
data.Equipped="broly";p.Character.Humanoid.Health=0
check(not skill:Activate(p,data).Ok,"dead character cannot activate")
p.Character.Humanoid.Health=100
local result=skill:Activate(p,data)
check(result.Ok and result.State.Charging and result.State.ChargeRemaining==26,"activation starts the full authoritative wind-up")
check(skill:Multiplier(p,data)==1 and not skill:Activate(p,data).Ok,"wind-up grants no early bonus and cannot be replayed")
now=25.99
check(skill:State(p,data).Charging and skill:Multiplier(p,data)==1,"bonus stays unavailable until charge completes")
now=26
check(skill:State(p,data).Active and skill:Multiplier(p,data)==3 and skill:State(p,data).ActiveRemaining==20,"completed charge grants exactly the configured boost")
now=46
local ended=skill:State(p,data)
check(not ended.Active and ended.Multiplier==1 and ended.CooldownRemaining==44,"boost expiration retains its remaining cooldown")
check(changes:Count()==0,"expired boost releases character listeners")
now=90
check(skill:State(p,data).Available and skill:Activate(p,data).Ok,"cooldown expiry permits a new activation")
data.Equipped="gojo";local unequipped=skill:State(p,data);data.Equipped="broly"
check(not unequipped.Charging and not skill:State(p,data).Charging and not skill:State(p,data).Active,"unequip cancels charge permanently")
check(not skill:Activate(p,data).Ok and skill:State(p,data).CooldownRemaining==90,"re-equipping cannot bypass cooldown")
now=180;check(skill:Activate(p,data).Ok,"next cooldown can activate normally")
now=206;data.Equipped="gojo";skill:State(p,data);data.Equipped="broly"
check(skill:Multiplier(p,data)==1 and not skill:Activate(p,data).Ok,"unequip cancels an active boost without refunding cooldown")
now=270;skill:Activate(p,data)
local h=p.Character.Humanoid;h.Health=0;h.Died:Fire();h.Health=100
check(not skill:State(p,data).Charging and not skill:State(p,data).Available,"death cancels wind-up even if health is restored")
now=360;skill:Activate(p,data)
local old=p.Character;p.Character=character();changes:Fire();p.Character=old
check(not skill:State(p,data).Charging and skill:Multiplier(p,data)==1,"character replacement cannot restore an old charge")
now=450;skill:Activate(p,data);p.Character=character()
check(not skill:State(p,data).Charging,"state validation also detects an unobserved character replacement")
now=540;skill:Activate(p,data);data.Characters.broly=0;skill:State(p,data);data.Characters.broly=1
check(not skill:State(p,data).Charging and not skill:Activate(p,data).Ok,"ownership loss cancels the skill while retaining cooldown")
skill:Clear(p)
check(skill:State(p,data).Available and changes:Count()==0,"disconnect cleanup releases state and listeners")
check(data.Coins==123 and data.Strength==456,"skill timing never mutates profile currency or power")
print("Broly skill checks:",total)
