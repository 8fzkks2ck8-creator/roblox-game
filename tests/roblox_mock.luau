-- Minimal deterministic engine stand-ins for logic tests and map serialization.
-- These do not replace Studio's physics, UI, audio, or replication tests.
local V={};V.__index=function(t,k) if k=="Magnitude" then return math.sqrt(t.X*t.X+t.Y*t.Y+t.Z*t.Z) end;return V[k] end
function V.__add(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
function V.__sub(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
Vector3={new=function(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0,_type="Vector3"},V) end}
Vector3.zero=Vector3.new();Vector3.one=Vector3.new(1,1,1)
Vector2={new=function(x,y) return {_type="Vector2",X=x,Y=y} end,zero={_type="Vector2",X=0,Y=0}}
local F={};F.__index=F
CFrame={new=function(x,y,z)
 if type(x)=="table" then x,y,z=x.X,x.Y,x.Z end
 return setmetatable({_type="CFrame",X=x or 0,Y=y or 0,Z=z or 0,R={1,0,0,0,1,0,0,0,1}},F)
end}
function CFrame.Angles(x,y,z)
 local f=CFrame.new();local cx,sx=math.cos(x),math.sin(x);local cy,sy=math.cos(y),math.sin(y);local cz,sz=math.cos(z),math.sin(z)
 f.R={cy*cz,-cy*sz,sy,cx*sz+sx*sy*cz,cx*cz-sx*sy*sz,-sx*cy,sx*sz-cx*sy*cz,sx*cz+cx*sy*sz,cx*cy};return f
end
function F.__mul(a,b)
 local f=CFrame.new(a.X+a.R[1]*b.X+a.R[2]*b.Y+a.R[3]*b.Z,a.Y+a.R[4]*b.X+a.R[5]*b.Y+a.R[6]*b.Z,a.Z+a.R[7]*b.X+a.R[8]*b.Y+a.R[9]*b.Z)
 f.R={};for i=0,2 do for j=1,3 do local n=0;for k=1,3 do n+=a.R[i*3+k]*b.R[(k-1)*3+j] end;f.R[i*3+j]=n end end;return f
end
Color3={new=function(r,g,b) return {_type="Color3",R=r,G=g,B=b} end,fromRGB=function(r,g,b) return {_type="Color3",R=r/255,G=g/255,B=b/255} end}
UDim2={fromOffset=function(x,y) return {_type="UDim2",X=x,Y=y} end,fromScale=function(x,y) return {_type="UDim2",XS=x,YS=y} end}
Enum=setmetatable({},{__index=function(t,k) local v=setmetatable({},{__index=function(t,n) local value={_type="Enum",Group=k,Name=n};rawset(t,n,value);return value end});rawset(t,k,v);return v end})
local methods={}
local nodeMeta={__index=function(t,k)
 if methods[k] then return methods[k] end
 return t._props[k]
end,__newindex=function(t,k,v)
 if k=="Parent" then
  local old=t._props.Parent;if old then local i=table.find(old._children,t);if i then table.remove(old._children,i) end end
  if v then table.insert(v._children,t) end
 elseif k=="Position" then t._props.CFrame=CFrame.new(v)
 elseif k=="CFrame" then t._props.Position=Vector3.new(v.X,v.Y,v.Z) end
 t._props[k]=v
end}
Instance={new=function(class,parent)
 local n=setmetatable({_props={ClassName=class,Name=class},_children={},_attrs={}},nodeMeta)
 n.Parent=parent;return n
end}
function methods:GetChildren() return table.clone(self._children) end
function methods:GetDescendants() local a={};for _,n in ipairs(self._children) do table.insert(a,n);for _,d in ipairs(n:GetDescendants()) do table.insert(a,d) end end;return a end
function methods:FindFirstChild(name) for _,n in ipairs(self._children) do if n.Name==name then return n end end end
function methods:IsA(class) return self.ClassName==class or (class=="BasePart" and (self.ClassName=="Part" or self.ClassName=="SpawnLocation")) end
function methods:FindFirstChildOfClass(class) for _,n in ipairs(self._children) do if n.ClassName==class then return n end end end
function methods:PivotTo(cf) self.LastPivot=cf end
function methods:Destroy() self.Parent=nil end
function methods:SetAttribute(k,v) self._attrs[k]=v end
function methods:GetAttribute(k) return self._attrs[k] end
workspace=Instance.new("Workspace")
local lighting=Instance.new("Lighting")
local tasks={}
task={spawn=function(fn,...) table.insert(tasks,{fn=fn,args={...}}) end,wait=function() coroutine.yield() end}
warn=function(...) print("WARN",...) end
local memory=true
local saved=nil
local failWrites=false
local storeCalls=0
local services={Lighting=lighting,RunService={IsStudio=function() return memory end},DataStoreService={GetDataStore=function()
 assert(not memory,"Memory mode requested a DataStore")
 return {UpdateAsync=function(_,key,fn)
  storeCalls+=1;if failWrites then error("Simulated outage") end
  local result=fn(saved);if result then saved=result end;return result
 end}
end},HttpService={GenerateGUID=function() return "test-session" end}}
game={JobId="test",ReplicatedStorage={AnimeRift={Config="CONFIG"}},GetService=function(_,k) return services[k] or {} end,BindToClose=function() end}
local function encode(x)
 local t=type(x)
 if t=="string" then return (string.format("%q",x):gsub("\n","n")) elseif t=="number" or t=="boolean" then return tostring(x) elseif t=="nil" then return "null" end
 local a={};if #x>0 then for _,v in ipairs(x) do table.insert(a,encode(v)) end;return "["..table.concat(a,",").."]" end
 for k,v in pairs(x) do table.insert(a,encode(tostring(k))..":"..encode(v)) end;return "{"..table.concat(a,",").."}"
end
local function export(node)
 local props={};for k,v in pairs(node._props) do if k~="Parent" and k~="ClassName" then props[k]=v end end
 local kids={};for _,n in ipairs(node._children) do table.insert(kids,export(n)) end
 return {class=node.ClassName,props=props,children=kids,attrs=node._attrs}
end
