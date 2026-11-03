-- Deterministic timeline, posing, rendering and cleanup checks; no real GPU/physics.
check(rageTimeline.Duration==C.BrolySkill.Windup,"Broly reference timeline matches authoritative wind-up")
local finite=true
for i=0,260 do
 local s=rageTimeline.Sample(i/10)
 for _,key in ipairs({"RootY","Lean","Head","Arm","Spread","Leg","Energy","Pillar","Moon","Orbit"}) do if s[key]~=s[key] or math.abs(s[key])==math.huge then finite=false end end
 if s.Energy<0 or s.Energy>1 or s.Pillar<0 or s.Pillar>1 or s.Moon<0 or s.Moon>1 then finite=false end
end
check(finite and rageTimeline.Sample(15).RootY==2 and rageTimeline.Sample(26).RootY==0,"Broly timeline has bounded values, levitation and landing")
local function rigPreview(parent)
 local view=Instance.new("ViewportFrame",parent);view.CurrentCamera=Instance.new("Camera",view)
 local world=Instance.new("WorldModel",view);local actor=Instance.new("Model",world)
 local function part(name,size,x,y,z)
  local p=Instance.new("Part",actor);p.Name=name;p.Size=size;p.CFrame=CFrame.new(x,y,z);return p
 end
 part("Torso",Vector3.new(2,2,1),0,0,0);part("Head",Vector3.new(2,1,1),0,1.5,0)
 for _,side in ipairs({-1,1}) do
  local word=side<0 and "Left" or "Right"
  part(word.." Arm",Vector3.new(1,2,1),side*1.5,0,0)
  part(word.." Leg",Vector3.new(1,2,1),side*.5,-2,0)
 end
 local cuff=part("Cuff",Vector3.new(.6,.3,.6),1.5,-.6,0)
 local weld=Instance.new("WeldConstraint",cuff);weld.Part0=actor:FindFirstChild("Right Arm");weld.Part1=cuff
 return view
end
local fixture=rigPreview(playerGui);local actor=fixture:FindFirstChildOfClass("WorldModel"):FindFirstChildOfClass("Model")
local cuff=actor:FindFirstChild("Cuff");local arm=actor:FindFirstChild("Right Arm")
local offset=arm.CFrame:ToObjectSpace(cuff.CFrame)
local pose=ragePose.Bind(actor);pose(rageTimeline.Sample(17.5))
local expected=arm.CFrame*offset
check((cuff.CFrame.Position-expected.Position).Magnitude<.0001,"Broly posing keeps welded costume pieces attached")
check(arm.CFrame.Position.X>1 and actor:FindFirstChild("Head").CFrame.Position.Y>3,"levitation spreads the arms and raises the visible actor")
fixture:Destroy()
local beforeFrames=services.RunService.RenderStepped:Count()
local beforeCamera=workspace.CurrentCamera.CFrame
local currentTime=0;local completed=0;local resultReason
local scene=rageSequence.Play({Parent=playerGui,Portrait=rigPreview,Clock=function() return currentTime end,SoundId="",OnComplete=function(reason) completed+=1;resultReason=reason end})
check(scene:IsPlaying() and scene.Metrics.FX<=96,"Broly presentation fits its fixed FX budget")
local sequenceGui=playerGui:FindFirstChild("BrolyRageSequence")
local view=sequenceGui:FindFirstChildOfClass("CanvasGroup"):FindFirstChildOfClass("ViewportFrame")
local world=view:FindFirstChildOfClass("WorldModel")
local fx=world:FindFirstChild("LegendaryRageFX")
local fixedInstances=#sequenceGui:GetDescendants()
local moonVisible=false
for _,t in ipairs({1,3.8,8.7,12.8,15,17.5,19.5,22.5,24}) do
 currentTime=t;services.RunService.RenderStepped:Fire()
 if t==17.5 then moonVisible=fx:FindFirstChild("Rage stage").Transparency>.9 end
 assert(scene:IsPlaying(),"Broly scene stopped early")
 assert(#sequenceGui:GetDescendants()==fixedInstances,"per-frame effect allocation")
end
check(moonVisible,"top-down moon backdrop is not hidden behind the stage floor")
currentTime=26.1;services.RunService.RenderStepped:Fire()
check(completed==1 and resultReason=="Completed" and not scene:IsPlaying() and services.RunService.RenderStepped:Count()==beforeFrames,"Broly scene completes once and releases its renderer")
check(workspace.CurrentCamera.CFrame==beforeCamera,"Broly shots never take over the gameplay camera")
scene=rageSequence.Play({Parent=playerGui,Portrait=rigPreview,ReducedEffects=true,OnComplete=function() completed+=1 end})
check(scene.Metrics.FPS==24 and scene.Metrics.FX<75,"touch/reduced Broly presentation lowers its FX/update budget")
scene:Cancel();scene:Cancel()
check(completed==2 and not playerGui:FindFirstChild("BrolyRageSequence"),"skipping Broly visuals is idempotent")
-- Live client skill event and reward queue operate without granting power locally.
local sourceBroly=data.Characters.broly
local equipped=data.Equipped
local previousPower=data.Strength
local previousSkill=data.BrolySkill
data.Characters.broly=1;data.Equipped="broly";data.BrolySkill={Available=true,Eligible=true,Charging=false,Active=false,Multiplier=1,ChargeRemaining=0,ActiveRemaining=0,CooldownRemaining=0}
events.OnClientEvent:Fire("State",data)
events.OnClientEvent:Fire("BrolySkillStart",{Available=false,Eligible=true,Charging=true,Active=false,Multiplier=1,ChargeRemaining=26,ActiveRemaining=0,CooldownRemaining=90})
check(not canvas.Visible and playerGui:FindFirstChild("BrolyRageSequence"),"Broly activation event starts its dedicated presentation")
events.OnClientEvent:Fire("Reveal",{Kind="Character",Id="beerus"})
local root=playerGui:FindFirstChild("BrolyRageSequence"):FindFirstChildOfClass("CanvasGroup")
root:FindFirstChild("SkipBrolySkill").Activated:Fire()
check(not playerGui:FindFirstChild("BrolyRageSequence") and playerGui:FindFirstChild("RiftSummonCutscene"),"queued summon waits until Broly visuals close")
local summon=playerGui:FindFirstChild("RiftSummonCutscene"):FindFirstChildOfClass("CanvasGroup")
summon:FindFirstChild("SkipCutscene").Activated:Fire();findButton("KEEP IT!").Activated:Fire()
check(data.Strength==previousPower,"client Broly presentation cannot mint power or advance the bonus")
data.Characters.broly=sourceBroly;data.Equipped=equipped;data.BrolySkill=previousSkill

local configured=rageSequence.Play({Parent=playerGui,Portrait=rigPreview,SoundId=C.BrolySkill.SoundId})
local referenceAudio=services.SoundService:FindFirstChild("BrolyLegendaryRageAudio")
check(referenceAudio and referenceAudio.SoundId=="rbxassetid://119358500041991","Broly sequence uses the supplied Roblox audio asset")
configured:Cancel()
check(referenceAudio.Parent==nil,"skipping the Broly sequence cleans up its reference audio")
local preloadCalls=0
services.ContentProvider={PreloadAsync=function() preloadCalls+=1 end}
rageSequence.Preload("rbxassetid://test-preload");rageSequence.Preload("rbxassetid://test-preload")
check(preloadCalls==1,"Broly audio is preloaded at most once per session")
local died=signal()
local watched={FindFirstChildOfClass=function() return {Died=died} end}
local diedReason
local dying=rageSequence.Play({Parent=playerGui,Portrait=rigPreview,Character=watched,OnComplete=function(reason) diedReason=reason end})
died:Fire()
check(not dying:IsPlaying() and diedReason=="Died","character death cancels the Broly sequence cleanly")
