-- Each fighter has an authored miniature set and signature action. Meshes remain
-- interchangeable through Assets/Cutscenes/<id>/Meshes, independent of this timing.
local S={}
local recipes={
 vegeta={"Royal crater","Crater","Ascend"},ichigo={"Moonlit rooftop","Roof","Crescent"},
 sukuna={"Shrine of crimson cuts","Shrine","Cuts"},gojo={"Infinity courtyard","Temple","Converge"},
 asta={"Broken fortress","Ruins","Sword"},yuji={"Black Flash alley","Alley","BlackFlash"},
 deku={"Emerald city ledge","Roof","Lightning"},jotaro={"Stardust avenue","Street","TimeStop"},
 dio={"Midnight clocktower","Clock","Knives"},gogeta={"Prismatic summit","Mountain","Stardust"},
 vegito={"Spirit sword sky temple","Temple","SpiritSword"},ssb_goku={"Azure ocean platform","Ocean","Beam"},
 naruto={"Sage mountain summit","Mountain","Rasengan"},aizen={"Mirror causeway","Mirrors","Shatter"},
 ui_goku={"Silent horizon","Void","Dodge"},cid={"Moonlit cathedral","Cathedral","Atomic"},
 gear5_luffy={"Cloud sea of liberation","Clouds","Liberation"},beerus={"Destroyer's celestial dais","Temple","Destruction"},
 boros={"Ruined alien deck","Alien","Cannon"},saitama={"Serious desert horizon","Desert","Pressure"},
 golden_experience_requiem={"Golden return to zero","Colonnade","Rewind"},marlon={"Rift sovereign throne","Throne","Portal"},
 awakened_aizen={"Chrysalis sanctuary","Sanctuary","Wings"},broly={"Legendary shattered canyon","Canyon","Rage"},
 simon={"Spiral beyond the stars","Cosmos","Drill"},
}
function S.Get(id) return recipes[id] end
function S.Build(id,ctx,world,make,center,height,primary,accent)
 local recipe=recipes[id];if not recipe then return nil end
 local unit=height/6
 local function part(name,size,pos,tint,material)
  local p=make("Part",world);p.Name=name;p.Size=size*unit;p.CFrame=CFrame.new(center+pos*unit);p.Color=tint;p.Material=material or Enum.Material.Slate;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;return p
 end
 local dark=primary:Lerp(Color3.fromRGB(62,68,83),.82)
 local setting,action=recipe[2],recipe[3]
 local ground=part(recipe[1],Vector3.new(42,.7,42),Vector3.new(0,-3.3,0),dark)
 if setting=="Void" or setting=="Cosmos" then ground.Transparency=.8 end
 if setting=="Void" or setting=="Cosmos" or setting=="Clock" or setting=="Cathedral" or setting=="Roof" then
  part("Night horizon",Vector3.new(110,85,1),Vector3.new(0,25,35),Color3.fromRGB(18,24,45),Enum.Material.SmoothPlastic)
  local moon=part("Distant moon",Vector3.new(6,6,1),Vector3.new(-13,14,30),accent,Enum.Material.Neon);moon.Shape=Enum.PartType.Ball
 end
 local props={}
 for i=1,6 do
  local side=i%2==0 and 1 or -1;local z=3+math.floor((i-1)/2)*7
  local size,pos=Vector3.new(2,9+i%3,2),Vector3.new(side*9,1,z)
  if setting=="Mountain" or setting=="Canyon" or setting=="Crater" or setting=="Desert" then size=Vector3.new(9,12+i*2,9);pos=Vector3.new(side*(16+i),-3,z+11)
  elseif setting=="Clouds" then size=Vector3.new(12,3,8);pos=Vector3.new(side*12,-2,z)
  elseif setting=="Alley" or setting=="Street" or setting=="Roof" then size=Vector3.new(7,14+i*2,8);pos=Vector3.new(side*15,1,z+10)
  elseif setting=="Mirrors" then size=Vector3.new(3,8,.3);pos=Vector3.new(side*7,1,z)
  elseif setting=="Alien" then size=Vector3.new(3,4+i*2,5);pos=Vector3.new(side*11,-1,z)
  elseif setting=="Cosmos" or setting=="Void" then size=Vector3.new(.3,.3,.3);pos=Vector3.new(side*(9+i),4+i,z)
  elseif setting=="Ocean" then size=Vector3.new(14,.25,10);pos=Vector3.new(side*15,-3,z)
  end
  local p=part(setting.." scenery "..i,size,pos,(setting=="Clouds" and Color3.fromRGB(228,237,255) or setting=="Ocean" and Color3.fromRGB(55,121,177) or dark:Lerp(accent,.12)))
  if setting=="Clouds" or setting=="Cosmos" then p.Shape=Enum.PartType.Ball end
  table.insert(props,{Part=p,Base=p.CFrame,Size=p.Size})
 end
 local meshes=ctx.SceneAssets and ctx.SceneAssets:FindFirstChild("Meshes")
 local template=meshes and meshes:FindFirstChild("SignatureMesh")
 local signatures={}
 for i=1,6 do
  local p
  if template and template:IsA("MeshPart") and #template:GetDescendants()<=2 then
   -- Copy mesh appearance only; never parent an imported script into Workspace.
   p=make("MeshPart",world)
   -- ApplyMesh copies geometry, texture and collision data without scripts.
   if template:IsA("MeshPart") then p:ApplyMesh(template) end
   p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
  else p=make("Part",world);p.Shape=Enum.PartType.Ball;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false end
  p.Name=action.." signature "..i;p.Color=i%2==0 and accent or primary;p.Material=Enum.Material.Neon;p.Transparency=1;p.Parent=world
  table.insert(signatures,p)
 end
 -- StageMesh is an optional replacement for the central ground, not the actor.
 local stageMesh=meshes and meshes:FindFirstChild("StageMesh")
 if stageMesh and stageMesh:IsA("MeshPart") and #stageMesh:GetDescendants()<=2 then
  local replacement=make("MeshPart",world);replacement:ApplyMesh(stageMesh);replacement.Name="Custom stage mesh";replacement.Size=stageMesh.Size;replacement.CFrame=CFrame.new(center+Vector3.new(0,-3.4,0)*unit);replacement.Anchored=true;replacement.CanCollide=false;replacement.CanTouch=false;replacement.CanQuery=false;ground.Transparency=1
 end
 local c={Setting=recipe[1],Action=action}
 function c:Update(p,t)
  local charge=math.clamp((p-.15)/.35,0,1);local release=math.clamp((p-.5)/.25,0,1);local fade=math.clamp((p-.82)/.15,0,1)
  for i,v in ipairs(signatures) do
   local a=i/6*math.pi*2+t*.6
   local size=Vector3.new(.7,.7,.7);local pos=Vector3.new(math.cos(a)*4,math.sin(a)*2,1);local rotation=CFrame.Angles(0,t,i)
   if action=="Converge" then
    local side=i%2==0 and 1 or -1;pos=Vector3.new(side*(5-charge*4.5),.6,0);size=Vector3.one*(1+charge*1.3+release*5);v.Color=side==1 and primary or accent
   elseif action=="Crescent" or action=="Cuts" or action=="Sword" or action=="SpiritSword" then
    size=Vector3.new(.12,action=="SpiritSword" and (2+charge*12) or 6,.35);pos=Vector3.new((i-3.5)*1.7,math.sin(i)*2,-release*18);rotation=CFrame.Angles(0,0,action=="Cuts" and i*.8 or -.65+release*2)
   elseif action=="BlackFlash" then
    size=Vector3.one*(.4+release*5);pos=Vector3.new(1.2+math.cos(a)*release*3,.1+math.sin(a)*release*3,-release*5);v.Color=i%2==0 and Color3.fromRGB(12,8,14) or primary
   elseif action=="Lightning" or action=="Rage" or action=="Ascend" then
    size=Vector3.new(.15,2+charge*(i+3),.15);pos=Vector3.new(math.cos(a)*3,-2+size.Y/2,math.sin(a)*3);rotation=CFrame.Angles(math.sin(t*5+i)*.16,0,math.cos(t*7+i)*.2)
   elseif action=="TimeStop" or action=="Knives" or action=="Rewind" then
    local time=p<.4 and t or p<.58 and 2 or action=="Rewind" and -t or t*.2
    a=i/6*math.pi*2+time*.7;pos=Vector3.new(math.cos(a)*5,math.sin(a)*4,-release*6);size=action=="Knives" and Vector3.new(.15,2,.25) or Vector3.new(.15,.8,.15);rotation=CFrame.Angles(0,0,a)
   elseif action=="Beam" or action=="Cannon" then
    size=Vector3.new(i==1 and 1+charge*2 or .12,i==1 and 1+charge*2 or .12,.3+release*35);pos=Vector3.new(i==1 and 0 or math.cos(a)*1.8,.5+(i==1 and 0 or math.sin(a)*1.8),-size.Z/2);v.Transparency=.8
   elseif action=="Rasengan" or action=="Stardust" then
    size=Vector3.one*(.4+charge*.8+release*3);pos=Vector3.new(1.5+math.cos(a)*(1-charge*.8),.3+math.sin(a)*(1-charge*.8),-release*15)
   elseif action=="Shatter" or action=="Wings" then
    size=Vector3.new(.15,3+charge*3,1.5);pos=Vector3.new((i%2==0 and 1 or -1)*(1+i*.4+release*5),i%3-1,1+release*3);rotation=CFrame.Angles(release*2,t*.2,(i%2==0 and 1 or -1)*(.35+i*.1))
   elseif action=="Atomic" or action=="Destruction" then
    local radius=action=="Atomic" and 2+charge*3+release*28 or .3+charge*3+release*10;size=Vector3.one*(i==1 and radius or .35+charge*.5);pos=Vector3.new(i==1 and 0 or math.cos(a)*(3+release*5),action=="Atomic" and 0 or 3,-release*9+(i==1 and 0 or math.sin(a)*3));v.Transparency=.92
   elseif action=="Liberation" then
    size=Vector3.new(3,1.2,2);pos=Vector3.new(math.cos(a)*4,math.sin(t*2+i)*.5-2,math.sin(a)*4)
   elseif action=="Pressure" or action=="Dodge" then
    size=Vector3.new(.12,4+release*6,4+release*6);pos=Vector3.new((i-3.5)*2,0,-release*(5+i*3));rotation=CFrame.Angles(0,0,t*.3)
   elseif action=="Portal" then
    size=Vector3.new(.2,4,.2);pos=Vector3.new(math.cos(a)*5,math.sin(a)*5,3);rotation=CFrame.Angles(0,0,a)
   elseif action=="Drill" then
    local radius=(1-i/7)*(2+charge*3);pos=Vector3.new(math.cos(a+t*4)*radius,-2+i*1.1+release*12,math.sin(a+t*4)*radius);size=Vector3.new(radius*.7,.3,radius*.7)
   end
   v.Size=size*unit;v.CFrame=CFrame.new(center+pos*unit)*rotation
   if action~="Atomic" and action~="Destruction" and action~="Beam" and action~="Cannon" then v.Transparency=math.clamp(1-charge*.85+fade,0,1) else v.Transparency=math.clamp(.83-charge*.1+fade,0,1) end
  end
  if action=="Shatter" or action=="Rewind" then
   for i,entry in ipairs(props) do
    local r=action=="Rewind" and math.sin(release*math.pi) or release
    entry.Part.CFrame=entry.Base*CFrame.new((i%2==0 and 1 or -1)*r*5,r*(i%3),0)*CFrame.Angles(0,r*i*.2,r*.2)
   end
  end
 end
 return c
end
return S
