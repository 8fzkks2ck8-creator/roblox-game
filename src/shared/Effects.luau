-- Locomotion overrides for equipped fighter rigs.
local Effects={}
local function animation(id,key)
 local assets=game.ReplicatedStorage.AnimeRift:FindFirstChild("Assets")
 local folders=assets and assets:FindFirstChild("Animations")
 if not folders then return end
 local specific=folders:FindFirstChild(id);local defaults=folders:FindFirstChild("Default")
 local value=specific and specific:FindFirstChild(key)
 if not value or not value:IsA("Animation") or value.AnimationId=="" then value=defaults and defaults:FindFirstChild(key) end
 if value and value:IsA("Animation") and value.AnimationId~="" then return value end
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
