-- Cosmetic client effects only. No currency, damage, or inventory changes here.
local P={}
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local C=require(script.Parent.Config)
local Idle=require(script.Parent.IdleMotion)
local idleStops={}
local function bindIdle(character)
 if not character:IsA("Model") then return end
 local function update()
  if idleStops[character] then idleStops[character]();idleStops[character]=nil end
  local id=character:GetAttribute("RiftIdleId")
  if id then idleStops[character]=Idle.Mount(character,id,Run) end
 end
 character:GetAttributeChangedSignal("RiftIdleId"):Connect(update)
 character.Destroying:Once(function() if idleStops[character] then idleStops[character]();idleStops[character]=nil end end)
 update()
end
for _,player in ipairs(game:GetService("Players"):GetPlayers()) do
 player.CharacterAdded:Connect(function(character) task.defer(bindIdle,character) end)
 if player.Character then bindIdle(player.Character) end
end
game:GetService("Players").PlayerAdded:Connect(function(player) player.CharacterAdded:Connect(function(character) task.defer(bindIdle,character) end) end)
local last=0
local pulses={}
local floating={}
local function watch(item)
 if item:IsA("BasePart") and item:GetAttribute("RiftFloat") then floating[item]=item.CFrame end
end
for _,item in ipairs(workspace:GetDescendants()) do watch(item) end
workspace.DescendantAdded:Connect(function(item) task.defer(watch,item) end)
Run.RenderStepped:Connect(function()
 local now=os.clock()
 for item,base in pairs(floating) do
  if item.Parent then item.CFrame=base*CFrame.new(0,math.sin(now*1.8+base.X)*.45,0)*CFrame.Angles(0,now*.4,0) else floating[item]=nil end
 end
end)
-- Sparse local fireflies keep the open plaza lively without replicated particle spam.
local function ambience(world)
 if world.Name~="RiftWorld" or world:FindFirstChild("LocalFireflies") then return end
 local anchor=Instance.new("Part");anchor.Name="LocalFireflies";anchor.Size=Vector3.new(195,12,175);anchor.Position=Vector3.new(0,7,0);anchor.Anchored=true;anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.Transparency=1;anchor.Parent=world
 local motes=Instance.new("ParticleEmitter",anchor);motes.Texture="rbxasset://textures/particles/sparkles_main.dds";motes.Rate=10;motes.Lifetime=NumberRange.new(3,5);motes.Speed=NumberRange.new(.1,.4);motes.SpreadAngle=Vector2.new(180,180);motes.Shape=Enum.ParticleEmitterShape.Box;motes.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume;motes.LightEmission=1;motes.Color=ColorSequence.new(Color3.fromRGB(255,250,169));motes.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.4,.2),NumberSequenceKeypoint.new(1,0)});motes.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.25,.15),NumberSequenceKeypoint.new(1,1)})
end
workspace.ChildAdded:Connect(function(child) if child.Name=="RiftWorld" then task.defer(ambience,child) end end)
local current=workspace:FindFirstChild("RiftWorld");if current then ambience(current) end
local auraCharacter,auraId
function P.Aura(character,id)
 if not character then return end
 local root=character:FindFirstChild("HumanoidRootPart");if not root then return end
 if auraCharacter==character and auraId==id then return end
 auraCharacter=character;auraId=id
 local old=root:FindFirstChild("RiftLocalAura");if old then old:Destroy() end
 local aura=C.Find(C.Cosmetics,id);if not aura then return end
 local anchor=Instance.new("Attachment",root);anchor.Name="RiftLocalAura";anchor.Position=Vector3.new(0,-1,0)
 local particles=Instance.new("ParticleEmitter",anchor);particles.Texture="rbxasset://textures/particles/sparkles_main.dds";particles.Color=ColorSequence.new(aura.Color);particles.LightEmission=.8;particles.Rate=6+aura.Tier*2;particles.Lifetime=NumberRange.new(.5,1);particles.Speed=NumberRange.new(1,3);particles.SpreadAngle=Vector2.new(65,65);particles.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.15),NumberSequenceKeypoint.new(1,0)});particles.Transparency=NumberSequence.new(.3)
end
function P.Pulse(amount)
 -- A short tint pulse avoids camera drift, motion sickness, and stacked FOV tweens.
 local effect=Instance.new("ColorCorrectionEffect",game:GetService("Lighting"));effect.Name="RiftImpact";effect.Brightness=amount*.25;effect.TintColor=Color3.fromRGB(239,230,255)
 Tween:Create(effect,TweenInfo.new(.25),{Brightness=0,TintColor=Color3.new(1,1,1)}):Play();Debris:AddItem(effect,.3)
end
function P.Train(character,id)
 if not character or os.clock()-last<.15 then return end;last=os.clock()
 local root=character:FindFirstChild("HumanoidRootPart");if not root then return end
 local hero=C.Find(C.Characters,id) or C.Characters[1]
 local ring=Instance.new("Part");ring.Name="LocalTrainingRipple";ring.Shape=Enum.PartType.Cylinder;ring.Anchored=true;ring.CanCollide=false;ring.CanTouch=false;ring.CanQuery=false;ring.Material=Enum.Material.Neon;ring.Color=hero.Color;ring.Transparency=.4;ring.Size=Vector3.new(.06,1.5,1.5);ring.CFrame=CFrame.new(root.Position-Vector3.new(0,2.6,0))*CFrame.Angles(0,0,math.pi/2);ring.Parent=workspace
 Tween:Create(ring,TweenInfo.new(.38,Enum.EasingStyle.Quad),{Size=Vector3.new(.06,5,5),Transparency=1}):Play();Debris:AddItem(ring,.4)
 local hand=character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm") or root
 local anchor=Instance.new("Attachment",hand)
 local sparks=Instance.new("ParticleEmitter",anchor);sparks.Texture="rbxasset://textures/particles/sparkles_main.dds";sparks.Color=ColorSequence.new(hero.Color);sparks.LightEmission=1;sparks.Lifetime=NumberRange.new(.18,.35);sparks.Speed=NumberRange.new(3,7);sparks.SpreadAngle=Vector2.new(160,160);sparks.Rate=0;sparks.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.22),NumberSequenceKeypoint.new(1,0)});sparks:Emit(6);Debris:AddItem(anchor,.5)
 -- Tiny local shoulder punch; restores the exact base pose after each click.
 local joint=character:FindFirstChild("RightShoulder",true) or character:FindFirstChild("Right Shoulder",true)
 if joint and joint:IsA("Motor6D") and not pulses[joint] and not joint:GetAttribute("RiftCasting") then
  local base=joint.C0;pulses[joint]=base;joint:SetAttribute("RiftPunch",true)
  Tween:Create(joint,TweenInfo.new(.07),{C0=base*CFrame.Angles(math.rad(55),0,math.rad(-12))}):Play()
  task.delay(.08,function()
   if joint.Parent then Tween:Create(joint,TweenInfo.new(.1),{C0=base}):Play() end
   task.delay(.11,function() pulses[joint]=nil;if joint.Parent then joint:SetAttribute("RiftPunch",nil) end end)
  end)
 end
end
return P
