-- Real cinematic module with deterministic time and the same UI engine stand-ins.
local function preview(parent)
 local view=Instance.new("ViewportFrame",parent)
 local world=Instance.new("WorldModel",view)
 Instance.new("Model",world)
 view.CurrentCamera=Instance.new("Camera",view);view.CurrentCamera.FieldOfView=34
 return view
end
local originalNew=Instance.new
local created=0
Instance.new=function(...) created+=1;return originalNew(...) end
local baselineFrames=services.RunService.RenderStepped:Count()
local gameplayCamera=workspace.CurrentCamera
local originalFov=gameplayCamera.FieldOfView
local originalCameraType=gameplayCamera.CameraType
local originalCameraFrame=gameplayCamera.CFrame
local function startScene(id,overrides)
 local now=0;local impact,complete=0,0;local reason
 local ctx={Parent=playerGui,Portrait=preview,Clock=function() return now end,OnImpact=function() impact+=1 end,OnComplete=function(value) complete+=1;reason=value end}
 for k,v in pairs(overrides or {}) do ctx[k]=v end
 local scene=cinematicModule.Play(C.Find(C.Characters,id),ctx)
 return scene,function(t) now=t;services.RunService.RenderStepped:Fire() end,function() return impact,complete,reason end
end
for _,hero in ipairs(C.Characters) do
 if hero.Tier>=5 then
  local scene,step,outcome=startScene(hero.Id)
  assert(scene and scene:IsPlaying(),"cutscene failed to build: "..hero.Id)
  assert(scene.Metrics.Effects<=CutscenePresets.Budget.MaxInstances and scene.Metrics.Particles<=18,"effect budget exceeded")
  local allocated=created
  step(scene.Metrics.Duration*.56)
  assert(created==allocated,"cutscene allocated Instances during a frame")
  local hit,finished=outcome();assert(hit==1 and finished==0,"impact not delivered exactly once")
  step(scene.Metrics.Duration*.75)
  step(scene.Metrics.Duration+.1)
  hit,finished=outcome()
  check(not scene:IsPlaying() and hit==1 and finished==1 and not playerGui:FindFirstChild("RiftSummonCutscene") and services.RunService.RenderStepped:Count()==baselineFrames,"scene completes and releases its budget: "..hero.Id)
 end
end
check(workspace.CurrentCamera==gameplayCamera and gameplayCamera.FieldOfView==originalFov and gameplayCamera.CameraType==originalCameraType and gameplayCamera.CFrame==originalCameraFrame,"cutscenes never change the gameplay camera")
local scene,step,outcome=startScene("gojo")
local sceneGui=playerGui:FindFirstChild("RiftSummonCutscene")
local root=sceneGui:FindFirstChildOfClass("CanvasGroup")
root:FindFirstChild("SkipCutscene").Activated:Fire()
scene:Cancel();step(100)
local hit,finished,reason=outcome()
check(hit==0 and finished==1 and reason=="Skipped" and not scene:IsPlaying(),"skip and repeated cancellation complete exactly once")
scene,step,outcome=startScene("broly",{ReducedEffects=true})
check(scene.Metrics.Particles<=10 and scene.Metrics.FPS<=24,"reduced effects lower particle count and update rate")
scene:Cancel("Respawn")
local _,cancelled,cancelReason=outcome()
check(cancelled==1 and cancelReason=="Respawn" and services.RunService.RenderStepped:Count()==baselineFrames,"respawn cancellation disconnects the renderer")
scene,step,outcome=startScene("cid")
playerGui:FindFirstChild("RiftSummonCutscene"):Destroy()
local _,closed,closeReason=outcome()
check(closed==1 and closeReason=="Closed" and not scene:IsPlaying(),"external overlay removal cleans up the scene")
local old,_,oldOutcome=startScene("simon")
local replacement,_,newOutcome=startScene("saitama")
local _,oldComplete,oldReason=oldOutcome()
check(not old:IsPlaying() and oldComplete==1 and oldReason=="Replaced" and replacement:IsPlaying() and services.RunService.RenderStepped:Count()==baselineFrames+1,"starting a replacement never stacks active scenes")
replacement:Cancel()
local failed=startScene("yuji",{Portrait=function() error("Simulated preview failure") end})
check(failed and not failed:IsPlaying() and not playerGui:FindFirstChild("RiftSummonCutscene") and services.RunService.RenderStepped:Count()==baselineFrames,"preview failure cannot leave a stuck overlay")
check(cinematicModule.Play(C.Find(C.Characters,"yamcha"),{Parent=playerGui})==nil,"ordinary summons do not create a cinematic")
Instance.new=originalNew

-- End-to-end client reveal queue: scenes never grant rewards or auto-equip.
local coinsBefore=data.Coins;local equippedBefore=data.Equipped
local renderBefore=services.RunService.RenderStepped:Count()
events.OnClientEvent:Fire("Reveal",{Kind="Character",Id="gojo"})
check(not canvas.Visible and playerGui:FindFirstChild("RiftSummonCutscene")~=nil,"high-tier reveal hides the background HUD and starts its scene")
events.OnClientEvent:Fire("Reveal",{Kind="Character",Id="beerus"})
local function skipActive()
 local gui=playerGui:FindFirstChild("RiftSummonCutscene")
 gui:FindFirstChildOfClass("CanvasGroup"):FindFirstChild("SkipCutscene").Activated:Fire()
end
skipActive()
check(canvas.Visible and not playerGui:FindFirstChild("RiftSummonCutscene"),"Skip opens the saved reward card and restores the HUD")
findButton("KEEP IT!").Activated:Fire()
check(playerGui:FindFirstChild("RiftSummonCutscene")~=nil,"queued high-tier reveal waits until the first card is dismissed")
skipActive();findButton("KEEP IT!").Activated:Fire()
check(not playerGui:FindFirstChild("RiftSummonCutscene") and services.RunService.RenderStepped:Count()==renderBefore and data.Coins==coinsBefore and data.Equipped==equippedBefore,"queued cutscenes release their renderer without currency or equip changes")
-- A bad model must still expose Keep, with one reward sound and no duplicate card.
local sceneAssets=shared:FindFirstChild("Assets") or Instance.new("Folder",shared);sceneAssets.Name="Assets"
local models=Instance.new("Folder",sceneAssets);models.Name="CharacterModels"
local badRig=Instance.new("Model",models);badRig.Name="gojo"
local badPart=Instance.new("Part",badRig);badPart.Size=Vector3.one
local soundsBefore=#services.SoundService:GetChildren()
events.OnClientEvent:Fire("Reveal",{Kind="Character",Id="gojo"})
check(canvas.Visible and not playerGui:FindFirstChild("RiftSummonCutscene") and #services.SoundService:GetChildren()==soundsBefore+1,"preview setup failure shows one fallback reward card and sound")
findButton("KEEP IT!").Activated:Fire()
badRig:Destroy()

-- Bound imported rigs as well as GUI effects, including the result-card preview.
local huge=Instance.new("Model",models);huge.Name="broly"
for i=1,65 do Instance.new("Part",huge).Name="Part"..i end
local cloneImplementation=methods.Clone
methods.Clone=function(self) assert(self~=huge,"oversized cinematic rig was cloned");return cloneImplementation(self) end
events.OnClientEvent:Fire("Reveal",{Kind="Character",Id="broly"})
check(playerGui:FindFirstChild("RiftSummonCutscene")~=nil,"oversized custom rig uses the lightweight built-in preview")
skipActive();findButton("KEEP IT!").Activated:Fire();huge:Destroy();methods.Clone=cloneImplementation
local currentBox=methods.GetBoundingBox
methods.GetBoundingBox=function() local cf=CFrame.new();cf.Position=Vector3.zero;return cf,Vector3.new(2,6,2) end
local noisy=Instance.new("Model",models);noisy.Name="gojo"
Instance.new("Part",noisy).Size=Vector3.one
Instance.new("ParticleEmitter",noisy);Instance.new("Sound",noisy)
events.OnClientEvent:Fire("Reveal",{Kind="Character",Id="gojo"})
local cleanPreview=true
for _,item in ipairs(playerGui:FindFirstChild("RiftSummonCutscene"):GetDescendants()) do if item.ClassName=="ParticleEmitter" or item.ClassName=="Sound" then cleanPreview=false end end
check(cleanPreview,"embedded model particles and sounds cannot bypass the cinematic budget")
skipActive();findButton("KEEP IT!").Activated:Fire();noisy:Destroy();methods.GetBoundingBox=currentBox
scene,step,outcome=startScene("sukuna")
step(0)
local viewport=playerGui:FindFirstChild("RiftSummonCutscene"):FindFirstChildOfClass("CanvasGroup"):FindFirstChild("CinematicStage"):FindFirstChildOfClass("ViewportFrame")
local model=viewport:FindFirstChildOfClass("WorldModel"):FindFirstChildOfClass("Model")
local lastPose=model.LastPivot
step(.01);check(model.LastPivot==lastPose,"cinematic renderer throttles intermediate frames")
scene:Cancel()
-- Studio preview access is local-only and explicitly labeled.
services.UserInputService.InputBegan:Fire({KeyCode=Enum.KeyCode.F8},false)
findButton("PREVIEW SUMMON CUTSCENES • NO REWARDS").Activated:Fire()
local count=0
for _,item in ipairs(canvas:GetDescendants()) do if item:IsA("TextButton") and item:FindFirstChild("Label") and item.Label.Text:find("PREVIEW • ",1,true)==1 then count+=1 end end
check(count==26,"Studio preview menu exposes all 26 high-tier scenes")
findButton("PREVIEW • Satoru Gojo").Activated:Fire();skipActive()
local previewLabel=false
for _,item in ipairs(canvas:GetDescendants()) do if item:IsA("TextLabel") and item.Text=="PREVIEW ONLY • No fighter was granted." then previewLabel=true end end
check(previewLabel and data.Coins==coinsBefore and data.Equipped==equippedBefore,"cutscene preview is labeled and does not change progression")
findButton("CLOSE PREVIEW").Activated:Fire()

-- Readability: the gradient is on a backdrop, never the composited character group.
scene,step,outcome=startScene("gojo")
local brightRoot=playerGui:FindFirstChild("RiftSummonCutscene"):FindFirstChildOfClass("CanvasGroup")
local brightView=brightRoot.CinematicStage:FindFirstChildOfClass("ViewportFrame")
local backdrop=brightRoot:FindFirstChild("CinematicBackdrop")
check(brightRoot.BackgroundTransparency==1 and brightRoot.BackgroundColor3.R==1 and not brightRoot:FindFirstChildOfClass("UIGradient") and backdrop:FindFirstChildOfClass("UIGradient")~=nil,"background gradient cannot darken the character composite")
check(brightView.LightColor.R==1 and brightView.LightColor.G==1 and brightView.LightColor.B==1 and brightView.Ambient.R>.8,"cinematic actor has bright neutral lighting")
local readableFX=true
for _,item in ipairs(brightRoot.CinematicStage:GetChildren()) do if item:IsA("Frame") and item.Name~="CinematicStage" and item.ZIndex==4 then readableFX=false end end
check(readableFX,"moving effect shards no longer cover the character")
scene:Cancel()
-- Real client/audio sequencing: build-up completes before the voice starts.
local summonSounds=Instance.new("Folder",sceneAssets);summonSounds.Name="SummonSounds"
local voiceTemplate=Instance.new("Sound",summonSounds);voiceTemplate.Name="gojo";voiceTemplate.SoundId="rbxassetid://test_voice";voiceTemplate.Volume=.8
local oldPlaySound=methods.Play
methods.Play=function(self)
 if self:IsA("Sound") and self.Name=="CharacterSummonSound" then
  self.HudVisibleAtStart=canvas.Visible;self.OverlayPresentAtStart=playerGui:FindFirstChild("RiftSummonCutscene")~=nil
 end
 oldPlaySound(self)
end
local time=0;local actualScenePlay=cinematicModule.Play;local activeDuration
cinematicModule.Play=function(item,ctx)
 ctx.Clock=function() return time end
 local result=actualScenePlay(item,ctx);activeDuration=result.Metrics.Duration;return result
end
events.OnClientEvent:Fire("Reveal",{Kind="Character",Id="gojo"})
time=activeDuration*.6;services.RunService.RenderStepped:Fire()
check(not services.SoundService:FindFirstChild("CharacterSummonSound"),"voice line does not play during cinematic build-up or impact")
time=activeDuration+.1;services.RunService.RenderStepped:Fire()
local voice=services.SoundService:FindFirstChild("CharacterSummonSound")
check(voice and voice.HudVisibleAtStart and not voice.OverlayPresentAtStart,"voice starts on the visible reward card after the cinematic is removed")
findButton("KEEP IT!").Activated:Fire()
check(voice.Parent==nil,"closing the reward card stops its voice line")
events.OnClientEvent:Fire("Reveal",{Kind="Character",Id="gojo"});skipActive()
check(services.SoundService:FindFirstChild("CharacterSummonSound")~=nil and not playerGui:FindFirstChild("RiftSummonCutscene"),"Skip moves directly to the voice and reward card without visual overlap")
findButton("KEEP IT!").Activated:Fire()
cinematicModule.Play=actualScenePlay;methods.Play=oldPlaySound
