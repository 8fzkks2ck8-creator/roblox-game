-- Session-only server authority for Legendary Rage. Visuals never grant the bonus.
local S={}
function S.new(config,clock)
 clock=clock or os.clock
 local slots={}
 local self={}
 local function stop(record)
  record.Cancelled=true
  for _,connection in ipairs(record.Connections) do connection:Disconnect() end
  record.Connections={};record.Character=nil
 end
 local function eligible(player,data)
  if not data or data.Equipped~="broly" or (data.Characters.broly or 0)<1 then return false end
  local character=player.Character
  local h=character and character:FindFirstChildOfClass("Humanoid")
  return h~=nil and h.Health>0
 end
 function self:State(player,data)
  local now=clock();local record=slots[player]
  local canUse=eligible(player,data)
  if record and not record.Cancelled then
   if not canUse or player.Character~=record.Character or now>=record.BuffEnd then stop(record) end
  end
  if record and now>=record.ReadyAt then
   if not record.Cancelled then stop(record) end
   slots[player]=nil;record=nil
  end
  local live=record and not record.Cancelled
  local charging=live and now<record.ChargeEnd or false
  local active=live and now>=record.ChargeEnd and now<record.BuffEnd or false
  local cooldown=record and math.max(0,record.ReadyAt-now) or 0
  return {
   Available=canUse and cooldown<=0,Eligible=canUse,
   Charging=charging,Active=active,
   Multiplier=active and config.Multiplier or 1,
   ChargeRemaining=charging and math.max(0,record.ChargeEnd-now) or 0,
   ActiveRemaining=active and math.max(0,record.BuffEnd-now) or 0,
   CooldownRemaining=cooldown,
  }
 end
 function self:Activate(player,data)
  local current=self:State(player,data)
  if not current.Eligible then return {Ok=false,Message="Equip an owned Broly and wait for your character to spawn.",State=current} end
  if not current.Available then return {Ok=false,Message="Legendary Rage is on cooldown.",State=current} end
  local now=clock();local character=player.Character
  local record={Character=character,ChargeEnd=now+config.Windup,BuffEnd=now+config.Windup+config.Duration,ReadyAt=now+config.Cooldown,Connections={},Cancelled=false}
  slots[player]=record
  local h=character:FindFirstChildOfClass("Humanoid")
  if h.Died and h.Died.Connect then table.insert(record.Connections,h.Died:Connect(function() stop(record) end)) end
  if player.GetPropertyChangedSignal then
   table.insert(record.Connections,player:GetPropertyChangedSignal("Character"):Connect(function()
    if player.Character~=record.Character then stop(record) end
   end))
  end
  return {Ok=true,Message="Legendary Rage is charging!",State=self:State(player,data)}
 end
 function self:Multiplier(player,data) return self:State(player,data).Multiplier end
 function self:Clear(player)
  local record=slots[player];if record then stop(record) end
  slots[player]=nil
 end
 return self
end
return S
