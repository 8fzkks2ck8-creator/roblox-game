-- Deterministic custom Madara scene: real module, authored-model fixture, fixed clock.
do
 local time=0;local completed=0;local impacts=0;local reason
 local baseline=services.RunService.RenderStepped:Count()
 local gameFrame=workspace.CurrentCamera.CFrame
 local made=0;local new=Instance.new
 Instance.new=function(...) made+=1;return new(...) end
 local played=0;local oldPlay=methods.Play
 methods.Play=function(self) if self.Name=="MadaraMeteorDialogue" then played+=1 end;return oldPlay(self) end
 local scene=cinematicModule.Play(C.Find(C.Characters,"madara"),{Parent=playerGui,Portrait=preview,Clock=function() return time end,CinematicVoiceId="rbxassetid://135791921703430",OnImpact=function() impacts+=1 end,OnComplete=function(value) completed+=1;reason=value end})
 assert(scene:IsPlaying(),"Madara scene failed to construct")
 local gui=playerGui:FindFirstChild("RiftSummonCutscene")
 local root=gui:FindFirstChildOfClass("CanvasGroup")
 local view=root:FindFirstChildOfClass("ViewportFrame")
 local world=view:FindFirstChildOfClass("WorldModel")
 local fx=world:FindFirstChild("FallingHeavensSet")
 local voice=services.SoundService:FindFirstChild("MadaraMeteorDialogue")
 local allocated=made
 check(scene.Metrics.Phase=="Horizon" and fx:FindFirstChild("Cliff summit") and fx:FindFirstChild("Valley floor"),"Madara establishes a cliff overlooking a distant valley")
 check(voice and voice.SoundId=="rbxassetid://135791921703430" and played==0,"Madara quote audio is prepared without playing during the horizon shot")
 local firstCamera=view.CurrentCamera.CFrame
 time=2.5;services.RunService.RenderStepped:Fire()
 check(scene.Metrics.Phase=="Dialogue" and root.MadaraDialogue.Text=="Too big for rain?" and root.MadaraDialogue.TextTransparency<.1 and played==1,"Madara close-up shows the quote and starts its audio at the dialogue cue")
 check(view.CurrentCamera.CFrame~=firstCamera and workspace.CurrentCamera.CFrame==gameFrame,"Madara camera shots stay inside the local viewport")
 time=2.8;services.RunService.RenderStepped:Fire();check(played==1,"Madara voice cue plays once")
 time=4.25;services.RunService.RenderStepped:Fire()
 local meteor=fx:FindFirstChild("Meteor 1");local high=meteor.Position.Y
 time=5.8;services.RunService.RenderStepped:Fire()
 local visible=0
 for i=1,4 do local rock=fx:FindFirstChild("Meteor "..i);if rock.Transparency<1 then visible+=1 end;assert(rock.Size.Y>20,"meteor lacks giant scale") end
 check(visible==4 and meteor.Position.Y<high,"four giant meteors become visible and descend toward the valley")
 check(impacts==1,"Madara impact callback fires exactly once")
 time=8.9;services.RunService.RenderStepped:Fire()
 check(scene.Metrics.Phase=="Whiteout" and root.MeteorWhiteout.BackgroundTransparency==0,"meteor impacts fade the full screen to white")
 check(made==allocated and scene.Metrics.Effects<=72,"Madara reuses its bounded effects without per-frame Instance allocation")
 time=9.7;services.RunService.RenderStepped:Fire();scene:Cancel()
 check(completed==1 and reason=="Completed" and not scene:IsPlaying() and voice.Parent==nil and services.RunService.RenderStepped:Count()==baseline,"Madara completion destroys its audio, overlay and renderer once")
 scene=cinematicModule.Play(C.Find(C.Characters,"madara"),{Parent=playerGui,Portrait=preview,ReducedEffects=true,Clock=function() return time end,CinematicVoiceId="rbxassetid://135791921703430"})
 voice=services.SoundService:FindFirstChild("MadaraMeteorDialogue")
 check(scene.Metrics.FPS==24 and scene.Metrics.Effects<60,"reduced Madara scene lowers update rate and dust budget")
 time+=2.6;services.RunService.RenderStepped:Fire();scene:Cancel("Skipped")
 check(voice.Parent==nil and not playerGui:FindFirstChild("RiftSummonCutscene") and services.RunService.RenderStepped:Count()==baseline,"skipping Madara during dialogue stops audio and releases the renderer")
 methods.Play=oldPlay;Instance.new=new
end

-- Rarity changes direct the shots rather than just changing a color/title.
do
 local shots={}
 for _,id in ipairs({"gojo","beerus","broly"}) do
  local scene,step=startScene(id)
  local gui=playerGui:FindFirstChild("RiftSummonCutscene")
  local view=gui:FindFirstChildOfClass("CanvasGroup").CinematicStage:FindFirstChildOfClass("ViewportFrame")
  local initial=view.CurrentCamera.CFrame
  local direction=CutscenePresets.Direction(C.Find(C.Characters,id).Tier)
  step(scene.Metrics.Duration*.25);local anticipation=scene.Metrics.Shot
  step(scene.Metrics.Duration*.7);local late=scene.Metrics.Shot
  shots[id]={Count=scene.Metrics.Shots,Intensity=direction.Intensity,Anticipation=anticipation,Late=late}
  check(view.CurrentCamera.CFrame~=initial and view:FindFirstChildOfClass("WorldModel"):FindFirstChild("SummonSpatialFX")~=nil,"staged summon moves its viewport camera through a persistent 3D effect set: "..id)
  scene:Cancel()
 end
 check(shots.gojo.Count<shots.beerus.Count and shots.beerus.Count<shots.broly.Count and shots.gojo.Intensity<shots.beerus.Intensity and shots.beerus.Intensity<shots.broly.Intensity,"higher summon rarities gain shots and effect intensity")
 check(shots.gojo.Anticipation=="Charge" and shots.beerus.Anticipation=="Anticipation" and shots.broly.Late=="Ascension","Secret anticipation and Super Secret ascension have distinct camera beats")
end

-- The actual client forwards the supplied dialogue asset and never replays the
-- old Madara summon voice when the whiteout/Skip opens the reward card.
do
 local time=0;local actualPlay=cinematicModule.Play
 cinematicModule.Play=function(item,ctx) ctx.Clock=function() return time end;return actualPlay(item,ctx) end
 local legacy=Instance.new("Sound",sceneAssets.SummonSounds);legacy.Name="madara";legacy.SoundId="rbxassetid://old_madara_voice";legacy.Volume=1
 events.OnClientEvent:Fire("Reveal",{Kind="Character",Id="madara"})
 local voice=services.SoundService:FindFirstChild("MadaraMeteorDialogue")
 check(voice and voice.SoundId=="rbxassetid://135791921703430","client supplies the requested Madara dialogue audio to the cliff scene")
 time=2.6;services.RunService.RenderStepped:Fire()
 skipActive()
 check(canvas.Visible and voice.Parent==nil and not services.SoundService:FindFirstChild("CharacterSummonSound"),"Madara Skip stops dialogue without replaying a second voice on the reward card")
 findButton("KEEP IT!").Activated:Fire()
 events.OnClientEvent:Fire("Reveal",{Kind="Character",Id="madara"})
 time+=9.7;services.RunService.RenderStepped:Fire()
 check(canvas.Visible and not services.SoundService:FindFirstChild("CharacterSummonSound"),"Madara completion does not replay the old voice after its cinematic quote")
 findButton("KEEP IT!").Activated:Fire()
 legacy:Destroy();cinematicModule.Play=actualPlay
end

-- Every high-tier recipe contains a setting and a distinct signature action.
do
 local settings,actions={},{};local count=0
 for _,hero in ipairs(C.Characters) do if hero.Tier>=5 then
  local scene=startScene(hero.Id)
  assert(scene and scene:IsPlaying())
  local setting=scene.Metrics.Setting;local action=scene.Metrics.Action
  assert(setting and action and not settings[setting] and not actions[action],'missing or duplicate scene direction: '..hero.Id)
  settings[setting]=true;actions[action]=true;count+=1;scene:Cancel()
 end end
 check(count==26,'all 26 high-tier fighters have distinct sets and signature actions')
end
