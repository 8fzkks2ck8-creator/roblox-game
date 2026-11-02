-- Drop a Model or Part under AnimeRift/Assets/VFX/<characterId>/<ability>.
-- Ability names: M1, Q, E, R, Hit. Default folder is the fallback.
local Effects={}
local Debris=game:GetService("Debris")
local Tween=game:GetService("TweenService")
local Config=require(game.ReplicatedStorage.AnimeRift.Config)
local function fallback(id,key,cf)
 local hero=Config.Find(Config.Characters,id) or Config.Characters[1]
 local color=hero.Color
 local duration=key=="R" and .65 or .35
 local radius=key=="R" and 20 or key=="Q" and 10 or key=="E" and 7 or 4
 local ring=Instance.new("Part");ring.Name="RiftSkillRipple";ring.Shape=Enum.PartType.Cylinder;ring.Size=Vector3.new(.08,1,1);ring.CFrame=cf*CFrame.Angles(0,0,math.pi/2);ring.Anchored=true;ring.CanCollide=false;ring.CanTouch=false;ring.CanQuery=false;ring.Material=Enum.Material.Neon;ring.Color=color;ring.Transparency=.35;ring.Parent=workspace
 Tween:Create(ring,TweenInfo.new(duration,Enum.EasingStyle.Quad),{Size=Vector3.new(.08,radius,radius),Transparency=1}):Play();Debris:AddItem(ring,duration+.1)
 for i=1,(key=="R" and 10 or 5) do
  local angle=i*math.pi*2/(key=="R" and 10 or 5)
  local shard=Instance.new("Part");shard.Name="RiftEnergyShard";shard.Size=Vector3.new(.15,.15,key=="R" and 3 or 1);shard.CFrame=cf*CFrame.Angles(0,angle,0)*CFrame.new(0,0,-1);shard.Material=Enum.Material.Neon;shard.Color=color;shard.Anchored=true;shard.CanCollide=false;shard.CanTouch=false;shard.CanQuery=false;shard.Parent=workspace
  Tween:Create(shard,TweenInfo.new(duration),{CFrame=cf*CFrame.Angles(0,angle,0)*CFrame.new(0,0,-radius/2),Transparency=1}):Play();Debris:AddItem(shard,duration+.1)
 end
 return true
end
function Effects.Play(id,key,cf)
 local assets=game.ReplicatedStorage.AnimeRift:FindFirstChild("Assets")
 local vfx=assets and assets:FindFirstChild("VFX")
 if not vfx then return fallback(id,key,cf) end
 local specific=vfx:FindFirstChild(id); local default=vfx:FindFirstChild("Default")
 local template=(specific and specific:FindFirstChild(key)) or (default and default:FindFirstChild(key))
 if not template then return fallback(id,key,cf) end
 local effect
 if template:IsA("ParticleEmitter") or template:IsA("Attachment") then
  effect=Instance.new("Part");effect.Name="RiftEffect";effect.Size=Vector3.new(1,1,1);effect.Transparency=1
  template:Clone().Parent=effect
 elseif template:IsA("Model") or template:IsA("BasePart") then effect=template:Clone()
 else return false end
 for _,v in ipairs(effect:GetDescendants()) do
  if v:IsA("LuaSourceContainer") then v:Destroy()
  elseif v:IsA("BasePart") then v.Anchored=true; v.CanCollide=false; v.CanTouch=false; v.CanQuery=false end
 end
 if effect:IsA("BasePart") then effect.Anchored=true; effect.CanCollide=false; effect.CanTouch=false; effect.CanQuery=false; effect.CFrame=cf else effect:PivotTo(cf) end
 effect.Parent=workspace
 for _,v in ipairs(effect:GetDescendants()) do
  if v:IsA("ParticleEmitter") then v.Enabled=false;v:Emit(v:GetAttribute("EmitCount") or 25)
  elseif v:IsA("Sound") then v:Play() end
 end
 Debris:AddItem(effect,math.clamp(effect:GetAttribute("Duration") or 3,0.1,15))
 return true
end
local function animation(id,key)
 local assets=game.ReplicatedStorage.AnimeRift:FindFirstChild("Assets")
 local folders=assets and assets:FindFirstChild("Animations")
 if not folders then return end
 local specific=folders:FindFirstChild(id);local defaults=folders:FindFirstChild("Default")
 local value=specific and specific:FindFirstChild(key)
 if not value or not value:IsA("Animation") or value.AnimationId=="" then value=defaults and defaults:FindFirstChild(key) end
 if value and value:IsA("Animation") and value.AnimationId~="" then return value end
end
function Effects.Animate(character,id,key)
 local clip=animation(id,key)
 if not clip then
  if key=="M1" or not character then return end
  for _,name in ipairs({"RightShoulder","LeftShoulder","Right Shoulder","Left Shoulder"}) do
   local joint=character:FindFirstChild(name,true)
   if joint and joint:IsA("Motor6D") and not joint:GetAttribute("RiftCasting") then
    joint:SetAttribute("RiftCasting",true);local base=joint.C0
    Tween:Create(joint,TweenInfo.new(.12),{C0=base*CFrame.Angles(math.rad(key=="E" and -35 or 85),0,0)}):Play()
    task.delay(.18,function()
     if joint.Parent then Tween:Create(joint,TweenInfo.new(.18),{C0=base}):Play() end
     task.delay(.2,function() if joint.Parent then joint:SetAttribute("RiftCasting",nil) end end)
    end)
   end
  end
  return
 end
 local h=character and character:FindFirstChildOfClass("Humanoid");if not h then return end
 local animator=h:FindFirstChildOfClass("Animator") or Instance.new("Animator",h)
 local ok,track=pcall(function() return animator:LoadAnimation(clip) end)
 if ok then track.Priority=Enum.AnimationPriority.Action;track.Looped=false;track:Play(0.1);Debris:AddItem(track,10)
 else warn("Animation failed for "..id.."/"..key..": "..tostring(track)) end
end
function Effects.ApplyAnimations(character,id)
 local animate=character:FindFirstChild("Animate");if not animate then return end
 local changed=false
 for _,v in ipairs(animate:GetDescendants()) do
  if v:IsA("Animation") then
   if v:GetAttribute("RiftOriginalAnimation")==nil then v:SetAttribute("RiftOriginalAnimation",v.AnimationId) end
   local key=v.Parent.Name:lower()
   local keys={idle="Idle",walk="Walk",run="Run",jump="Jump",fall="Fall",climb="Climb",swim="Swim"}
   local clip=keys[key] and animation(id,keys[key])
   local target=clip and clip.AnimationId or v:GetAttribute("RiftOriginalAnimation")
   if target~=v.AnimationId then v.AnimationId=target;changed=true end
  end
 end
 if changed then
  local h=character:FindFirstChildOfClass("Humanoid");local animator=h and h:FindFirstChildOfClass("Animator")
  if animator then for _,track in ipairs(animator:GetPlayingAnimationTracks()) do track:Stop(0.1) end end
 end
end
return Effects
