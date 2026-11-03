local L={}
function L.Measure(width,height)
 width=math.max(1,width);height=math.max(1,height-50)
 local portrait=width/height<.95
 local w,h=portrait and 760 or 1200,portrait and 1200 or 760
 local windowW,windowH=portrait and 740 or 900,portrait and 560 or 580
 return {Portrait=portrait,Width=w,Height=h,Scale=math.max(.01,math.min(width/w,height/h)),WindowWidth=windowW,WindowHeight=windowH,WindowX=portrait and (w-windowW)/2 or 280,WindowY=portrait and 270 or 85}
end
function L.Number(value)
 value=math.max(0,tonumber(value) or 0)
 for _,unit in ipairs({{1e12,"T"},{1e9,"B"},{1e6,"M"}}) do if value>=unit[1] then return string.format("%.2f%s",value/unit[1],unit[2]) end end
 if value>=1e4 then return string.format("%.1fK",value/1e3) end
 return tostring(math.floor(value))
end
return L
