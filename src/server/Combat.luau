local Players=game:GetService("Players")
local Debris=game:GetService("Debris")
local C=require(game.ReplicatedStorage.AnimeRift.Config)
local Effects=require(game.ReplicatedStorage.AnimeRift.Effects)
local B={Matches={},Queue={},Active={},Settling={}}
local W,Send,Reward,GetData
local rng=Random.new()
local function model(p) return typeof(p)=="Instance" and (p:IsA("Player") and p.Character or p) end
local function hum(p) local m=model(p); return m and m:FindFirstChildOfClass("Humanoid") end
local function root(p) local m=model(p); return m and m:FindFirstChild("HumanoidRootPart") end
local function tell(p,kind,data) if p:IsA("Player") then Send(p,kind,data) end end
local function visual(a,b,color,size)
 local p=Instance.new("Part"); p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Material=Enum.Material.Neon; p.Color=color; p.Size=Vector3.new(size,size,math.max((a-b).Magnitude,0.1)); p.CFrame=CFrame.lookAt((a+b)/2,b); p.Parent=workspace;game:GetService("TweenService"):Create(p,TweenInfo.new(.22),{Transparency=1,Size=Vector3.new(.05,.05,p.Size.Z)}):Play();Debris:AddItem(p,.25)
end
local function sphere(pos,color,radius)
 local p=Instance.new("Part"); p.Shape=Enum.PartType.Ball; p.Size=Vector3.new(1,1,1); p.Position=pos; p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Material=Enum.Material.Neon; p.Color=color; p.Transparency=0.4; p.Parent=workspace
 game:GetService("TweenService"):Create(p,TweenInfo.new(0.4),{Size=Vector3.new(radius*2,radius*2,radius*2),Transparency=1}):Play(); Debris:AddItem(p,0.5)
end
local function decorate(p)
 local m=model(p); if not m then return end
 local old=m:FindFirstChild("RiftAura"); if old then old:Destroy() end
 local d=GetData(p); if not d then return end
 local h=C.Find(C.Characters,d.Equipped) or C.Characters[1]; local a=C.Find(C.Cosmetics,d.Aura)
 local assets=game.ReplicatedStorage.AnimeRift:FindFirstChild("Assets")
 local templates=assets and assets:FindFirstChild("CharacterModels")
 local custom=templates and templates:FindFirstChild(h.Id)
 if custom and (not custom:IsA("Model") or not custom:FindFirstChildOfClass("Humanoid") or not custom:FindFirstChild("HumanoidRootPart") or not custom.HumanoidRootPart:IsA("BasePart")) then
  warn("Invalid custom rig for "..h.Id.."; using default avatar outfit.");custom=nil
 end
 if m:GetAttribute("RiftCharacterId") and not (custom and custom:IsA("Model")) and p:IsA("Player") and not B.Active[p] then p:LoadCharacterAsync();return end
 local usingCustom=m:GetAttribute("RiftCharacterId")==h.Id
 if custom and custom:IsA("Model") and not usingCustom and p:IsA("Player") and not B.Active[p] then
  if custom:FindFirstChildOfClass("Humanoid") and custom:FindFirstChild("HumanoidRootPart") then
   local replacement=custom:Clone();replacement.Name=p.Name;replacement:SetAttribute("RiftCharacterId",h.Id)
   local keptAnimate=false
   for _,v in ipairs(replacement:GetDescendants()) do
    if v:IsA("LuaSourceContainer") then
     if v:IsA("LocalScript") and v.Name=="Animate" and v.Parent==replacement and not keptAnimate then keptAnimate=true else v:Destroy() end
    elseif v:IsA("BasePart") then v.Anchored=false end
   end
   local animate=m:FindFirstChild("Animate"); if animate and not replacement:FindFirstChild("Animate") then animate:Clone().Parent=replacement end
   local rh=replacement:FindFirstChildOfClass("Humanoid")
   if not rh:FindFirstChildOfClass("Animator") then Instance.new("Animator",rh) end
   rh.Health=rh.MaxHealth
   replacement.HumanoidRootPart.CanCollide=false
   replacement.PrimaryPart=replacement.HumanoidRootPart;replacement.Parent=workspace;replacement:PivotTo(m:GetPivot())
   p.Character=replacement;m:Destroy();return
  else warn("CharacterModels/"..h.Id.." needs a Humanoid and HumanoidRootPart; using fallback.") end
 end
 if not usingCustom then
 local outfit=C.Outfits[h.Id] or C.Outfits.yamcha
 local oldOutfit=m:FindFirstChild("RiftOutfit"); if oldOutfit then oldOutfit:Destroy() end
 for _,v in ipairs(m:GetChildren()) do if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") or v:IsA("BodyColors") then v:Destroy() end end
 local colors=Instance.new("BodyColors",m)
 local skin=Color3.fromRGB(table.unpack(outfit.Skin)); local cloth=Color3.fromRGB(table.unpack(outfit.Cloth))
 colors.HeadColor3=skin; colors.LeftArmColor3=skin; colors.RightArmColor3=skin
 colors.TorsoColor3=cloth; colors.LeftLegColor3=cloth; colors.RightLegColor3=cloth
 local head=m:FindFirstChild("Head")
 if head and not outfit.Bald then
  local hair=Instance.new("Folder",m); hair.Name="RiftOutfit"
  for i=-2,2 do
   local spike=Instance.new("WedgePart"); spike.Name="Hair tuft"; spike.Size=Vector3.new(0.45,0.7+math.abs(i)*0.12,0.9); spike.Color=Color3.fromRGB(table.unpack(outfit.Hair)); spike.CanCollide=false; spike.CanTouch=false; spike.CanQuery=false; spike.Massless=true; spike.CFrame=head.CFrame*CFrame.new(i*0.32,0.6,0.1)*CFrame.Angles(0,0,-i*0.16); spike.Parent=hair
   local weld=Instance.new("WeldConstraint",spike); weld.Part0=head; weld.Part1=spike
  end
 end
 end
 Effects.ApplyAnimations(m,h.Id)
 local highlight=m:FindFirstChild("RiftOutline") or Instance.new("Highlight"); highlight.Name="RiftOutline"; highlight.FillTransparency=1; highlight.OutlineColor=h.Color; highlight.OutlineTransparency=0.3; highlight.Parent=m
 local r=root(p); if not r then return end
 local oldTag=r:FindFirstChild("HeroTag"); if oldTag then oldTag:Destroy() end
 local tag=Instance.new("BillboardGui",r); tag.Name="HeroTag"; tag.Size=UDim2.fromOffset(240,35); tag.StudsOffset=Vector3.new(0,3.5,0); tag.MaxDistance=80
 local label=Instance.new("TextLabel",tag); label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.Text=h.Name; label.TextColor3=h.Color; label.Font=Enum.Font.GothamBold; label.TextSize=14; label.TextStrokeTransparency=0.3
 if a then
  local folder=Instance.new("Folder",m); folder.Name="RiftAura"
  for i=1,a.Tier+2 do
   local angle=i*math.pi*2/(a.Tier+2)
   local orb=Instance.new("Part"); orb.Name="Aura stud"; orb.Shape=Enum.PartType.Ball; orb.Size=Vector3.new(0.45,0.45,0.45); orb.Material=Enum.Material.Neon; orb.Color=a.Color; orb.CanCollide=false; orb.CanTouch=false; orb.CanQuery=false; orb.Massless=true; orb.CFrame=r.CFrame*CFrame.new(math.cos(angle)*2,1,math.sin(angle)*2); orb.Parent=folder
   local weld=Instance.new("WeldConstraint",orb); weld.Part0=r; weld.Part1=orb
  end
 end
end
-- AppearanceLoaded and CharacterAdded may arrive together while a rig swaps.
local decorating={}
function B.Decorate(p)
 if decorating[p] then return end
 decorating[p]=true
 local ok,err=xpcall(function() decorate(p) end,debug.traceback)
 decorating[p]=nil
 if not ok then warn("Character decoration failed: "..tostring(err)) end
end
local Strength
function B.InQueue() return false end
local function bossState(m)
 tell(m.Player,"BossState",{Health=m.HP,MaxHealth=m.Def.Health,Name=m.Def.Name})
end
function B.Finish(m,won,reason)
 if m.Done then return end;m.Done=true
 for _,conn in ipairs(m.Connections) do conn:Disconnect() end
 B.Active[m.Player]=nil;B.Matches[m]=nil;m.Arena.Busy=false
 if m.Boss then m.Boss:Destroy() end
 local p=m.Player;local h=hum(p)
 if h and h.Health>0 then h.MaxHealth=m.PreviousMaxHealth;h.Health=h.MaxHealth;h.WalkSpeed=m.PreviousWalkSpeed end
 if p.Parent and root(p) then model(p):PivotTo(W.Spawn) end
 B.Settling[p]=true
 local saved=false
 if won then local ok,result=pcall(Reward,p,m.Def);saved=ok and result==true;if not ok then warn("Boss reward failed: "..tostring(result)) end end
 B.Settling[p]=nil
 if p.Parent then tell(p,"MatchEnd",won and (saved and ("BOSS DEFEATED! +"..m.Def.Coins.." coins / +"..C.Economy.GemsPerWin.." gems") or "Boss defeated, but reward could not save.") or reason) end
end
function B.Attack(p,key)
 local m=B.Active[p]
 if not m or m.Done or os.clock()<m.Start then return end
 local h,r=hum(p),root(p)
 if not h or h.Health<=0 or not r or not C.Cooldowns[key] then return end
 if (m.Cooldowns[key] or 0)>os.clock() then return end
 local distance=(r.Position-m.Position).Magnitude
 if (r.Position-m.Arena.Center).Magnitude>80 then return end
 if key~="E" and distance>(key=="M1" and 32 or 70) then return end
 m.Cooldowns[key]=os.clock()+C.Cooldowns[key]
 tell(p,"Cooldown",{Key=key,Time=C.Cooldowns[key]})
 local d=GetData(p);if not d then return end
 local hero=C.Find(C.Characters,d.Equipped) or C.Characters[1]
 Effects.Animate(model(p),hero.Id,key);Effects.Play(hero.Id,key,r.CFrame);tell(p,"CombatSound",key)
 if key=="E" then m.Guard=os.clock()+3;sphere(r.Position,hero.Color,5);return end
 local damage=C.BossDamage(hero.Id,Strength(p),d.Aura)*(key=="Q" and 2.5 or key=="R" and 5 or 1)
 damage=math.floor(damage);m.HP=math.max(0,m.HP-damage)
 visual(r.Position,m.Position,hero.Color,key=="R" and 3 or 1)
 Effects.Play(hero.Id,"Hit",CFrame.new(m.Position));bossState(m)
 tell(p,"BossHit",{Damage=damage})
 if m.HP<=0 then B.Finish(m,true,"Boss defeated") end
end
local function makeBoss(def,position)
 local m=Instance.new("Model");m.Name=def.Name
 local function part(name,size,offset,color)
  local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=CFrame.new(position+offset);p.Color=color;p.Material=Enum.Material.Plastic;p.Anchored=true;p.CanCollide=false;p.TopSurface=Enum.SurfaceType.Studs;p.Parent=m;return p
 end
 local torso=part("Body",Vector3.new(6,7,4),Vector3.new(0,1,0),def.Color)
 part("Head",Vector3.new(4,4,4),Vector3.new(0,6.5,0),def.Color)
 for _,side in ipairs({-1,1}) do
  part("Arm",Vector3.new(2.5,7,3),Vector3.new(side*4.5,1,0),def.Color)
  part("Leg",Vector3.new(2.5,4,3),Vector3.new(side*1.7,-4,0),def.Color)
  local eye=part("Eye",Vector3.new(.7,.7,.2),Vector3.new(side,7,2.1),Color3.new(1,1,1));eye.Material=Enum.Material.Neon
 end
 m.PrimaryPart=torso;m.Parent=workspace
 return m
end
function B.StartBoss(p,id)
 if B.Settling[p] then return false,"Saving your previous boss reward. Please wait." end
 if B.Active[p] then return false,"You are already fighting a boss." end
 local def=C.Find(C.Bosses,id)
 if not def then return false,"Choose a boss from BOSS CHALLENGES." end
 if Strength(p)<def.Required then return false,"Train to "..def.Required.." strength first." end
 local h,r=hum(p),root(p)
 if not h or h.Health<=0 or not r then return false,"Wait for your character to spawn." end
 local arena;for _,a in ipairs(W.Arenas) do if not a.Busy then arena=a;break end end
 if not arena then return false,"All boss arenas are busy. Try again shortly." end
 arena.Busy=true
 local pos=arena.Center+Vector3.new(0,6,0)
 local m={Player=p,Def=def,Arena=arena,HP=def.Health,Position=pos,Start=os.clock()+3,End=os.clock()+183,NextAttack=os.clock()+6,Cooldowns={},Connections={},Guard=0,PreviousMaxHealth=h.MaxHealth,PreviousWalkSpeed=h.WalkSpeed}
 local built,boss=pcall(makeBoss,def,pos)
 if not built then arena.Busy=false;warn("Boss creation failed: "..tostring(boss));return false,"Boss could not spawn. Please try again." end
 m.Boss=boss;B.Active[p]=m;B.Matches[m]=true
 local d=GetData(p);local hero=C.Find(C.Characters,d.Equipped) or C.Characters[1]
 h.MaxHealth=hero.Health;h.Health=h.MaxHealth;h.WalkSpeed=18
 model(p):PivotTo(arena.Spawns[1]);local ff=model(p):FindFirstChildOfClass("ForceField");if ff then ff:Destroy() end
 table.insert(m.Connections,h.Died:Connect(function() B.Finish(m,false,"Defeated! Train more strength and try again.") end))
 tell(p,"MatchStart",{Opponent=def.Name,Duration=180,Countdown=3});bossState(m)
 return true,"Dodge the red warning, click to strike, Q/R for skills and E to guard!"
end
function B.Remove(p)
 local m=B.Active[p];if m then B.Finish(m,false,"Returned to the lobby. No boss reward.") end
end
function B.Init(world,send,reward,data,strength)
 W=world;Send=send;Reward=reward;GetData=data;Strength=strength
 task.spawn(function()
  while task.wait(0.15) do
   for m in pairs(B.Matches) do
    if not m.Done then
     local p=m.Player;local h,r=hum(p),root(p);local now=os.clock()
     if not p.Parent or not h or not r or h.Health<=0 then B.Finish(m,false,"Boss fight ended.")
     elseif now>m.End then B.Finish(m,false,"Time is up! Train and try again.")
     else
      local center=m.Arena.Center
      if math.abs(r.Position.X-center.X)>50 or math.abs(r.Position.Z-center.Z)>50 or r.Position.Y<center.Y-5 or r.Position.Y>center.Y+35 then model(p):PivotTo(m.Arena.Spawns[1]) end
      if m.ImpactAt and now>=m.ImpactAt then
       local target=m.Target;m.ImpactAt=nil
       sphere(target,Color3.fromRGB(255,70,90),14)
       if (r.Position-target).Magnitude<=14 then
        local d=GetData(p);local aura=d and C.Find(C.Cosmetics,d.Aura)
        h:TakeDamage(m.Def.Damage*(1-(aura and aura.Defense or 0))*(m.Guard>now and 0.35 or 1))
       end
      end
      if not m.Done and now>=m.NextAttack then
       m.NextAttack=now+4;m.ImpactAt=now+1.2;m.Target=r.Position
       local warning=Instance.new("Part");warning.Name="Boss attack warning";warning.Shape=Enum.PartType.Cylinder;warning.Size=Vector3.new(.15,28,28);warning.CFrame=CFrame.new(r.Position.X,center.Y+.3,r.Position.Z)*CFrame.Angles(0,0,math.pi/2);warning.Anchored=true;warning.CanCollide=false;warning.CanTouch=false;warning.CanQuery=false;warning.Material=Enum.Material.Neon;warning.Color=Color3.fromRGB(255,55,75);warning.Transparency=.55;warning.Parent=workspace;Debris:AddItem(warning,1.2)
       tell(p,"Toast","DODGE! Move out of the red circle!")
      end
     end
    end
   end
  end
 end)
end
return B
