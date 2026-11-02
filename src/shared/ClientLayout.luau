-- Virtual layouts keep controls readable on portrait phones as well as desktops.
local L = {}
function L.Measure(width, height)
 width = math.max(1, width); height = math.max(1, height - 50)
 local portrait = width / height < .95
 local w, h = portrait and 760 or 1200, portrait and 1200 or 760
 return {Portrait=portrait, Width=w, Height=h, Scale=math.max(.01,math.min(width/w,height/h)), WindowX=(w-740)/2, WindowY=portrait and 270 or 110}
end
function L.Number(value)
 value=math.max(0,tonumber(value) or 0)
 if value>=1e9 then return string.format("%.2fB",value/1e9) end
 if value>=1e6 then return string.format("%.2fM",value/1e6) end
 if value>=1e4 then return string.format("%.1fK",value/1e3) end
 return tostring(math.floor(value))
end
return L
