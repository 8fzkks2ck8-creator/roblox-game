-- Cosmetic client effects only. No currency, damage, or inventory changes here.
local P={}
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local C=require(script.Parent.Config)
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
  local base=joint.C0;pulses[joint]=base
  Tween:Create(joint,TweenInfo.new(.07),{C0=base*CFrame.Angles(math.rad(55),0,math.rad(-12))}):Play()
  task.delay(.08,function()
   if joint.Parent then Tween:Create(joint,TweenInfo.new(.1),{C0=base}):Play() end
   task.delay(.11,function() pulses[joint]=nil end)
  end)
 end
end
return P
