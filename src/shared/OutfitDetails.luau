-- Small block-built accessories shared by live avatars and inventory previews.
local D={}
function D.Apply(character,outfit,parent,anchored)
 local head=character:FindFirstChild("Head")
 local torso=character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("Body")
 if not head then return end
 local unit=head.Size.X/2
 local function piece(name,host,size,offset,color,wedge)
  if not host then return end
  local p=Instance.new(wedge and "WedgePart" or "Part");p.Name=name;p.Size=Vector3.new(size[1]*unit,size[2]*unit,size[3]*unit);p.CFrame=host.CFrame*CFrame.new(offset[1]*unit,offset[2]*unit,offset[3]*unit);p.Color=Color3.fromRGB(table.unpack(color));p.Material=Enum.Material.SmoothPlastic;p.Anchored=anchored==true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Massless=true;p.Parent=parent
  if not anchored then local weld=Instance.new("WeldConstraint",p);weld.Part0=host;weld.Part1=p end
 end
 if outfit.Hat then
  piece("Fighter cap",head,{2.15,.55,1.5},{0,.65,0},outfit.Hat)
  piece("Cap brim",head,{2.2,.12,1.1},{0,.45,-.8},outfit.Hat)
 end
 if outfit.Headband then piece("Headband",head,{2.05,.28,.12},{0,.25,-.56},outfit.Headband) end
 if outfit.Ears then for _,side in ipairs({-1,1}) do piece("Cat ear",head,{.5,1.5,.5},{side*.65,1,0},outfit.Ears,true) end end
 if outfit.Cape then piece("Fighter cape",torso,{2.3,2.8,.18},{0,-.35,.7},outfit.Cape) end
 if outfit.Collar then piece("Fighter collar",torso,{2.1,.35,1.1},{0,.85,0},outfit.Collar) end
 if outfit.Tie then piece("Fighter tie",torso,{.25,1.3,.12},{0,.1,-.56},outfit.Tie) end
end
return D
