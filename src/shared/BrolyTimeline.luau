-- Legendary Rage: 26 seconds of local cinematic direction, with no engine services.
-- Pose order: RootY, Lean, Head, Arm, Spread, Leg, Energy, Pillar, Moon, Orbit.
-- Camera order: X, Y, Z, TX, TY, TZ, FOV. All rotations are radians.
local T={Duration=26}
local tau=math.pi*2
local keys={
 {0,"Confident",{0,0,.08,.06,.12,.04,.10,0,0,0},{.9,1.7,-2.2,0,1.5,0,43}},
 {1.2,"Confident",{0,0,.10,.08,.14,.04,.13,0,0,0},{1.05,1.7,-2.1,0,1.5,0,42}},
 {1.5,"SideTurn",{0,.04,.12,.12,.18,.05,.18,0,0,0},{2.6,1.9,-1.4,0,1.4,0,47}},
 {2.5,"LowBrace",{0,-.13,-.25,-.50,.30,.16,.36,0,0,0},{1.3,.25,-4,0,1,0,55}},
 {3.5,"ExplosiveFlare",{0,-.24,-.38,-.85,.42,.24,.76,.12,0,0},{4,2.5,-7,0,1.2,0,63}},
 {3.8,"ExplosiveFlare",{.25,-.28,.38,-.95,.52,.27,1,.58,0,0},{9,7,-16,0,2,0,77}},
 {5.5,"BowedFocus",{.08,-.12,-.65,-.60,.24,.15,.52,.08,0,0},{.8,1.5,-2.1,0,1.5,0,43}},
 {7,"SphereBuildup",{0,-.08,-.38,-.72,.34,.18,.58,.06,0,0},{9,7,-16,0,2,0,64}},
 {8.7,"SphereBuildup",{.12,-.06,-.20,-.85,.48,.22,.92,.18,0,0},{10,7.5,-18,0,2,0,69}},
 {10,"TorsoClose",{.15,-.08,-.28,-.85,.36,.18,.74,.08,0,0},{.6,.7,-2.8,0,.6,0,46}},
 {11.3,"FistClose",{.18,-.12,-.15,-1.28,.18,.20,.86,.18,0,0},{2,0,-1.7,.9,-.2,0,43}},
 {12.5,"PillarAscent",{.4,-.04,.15,-.65,.70,.24,.84,.48,0,0},{12,10,-26,0,4,0,72}},
 {12.8,"PillarAscent",{1.2,0,.42,-.42,.95,.26,1,1,.08,0},{12,10,-26,0,4,0,78}},
 {15,"MoonOrbit",{2,.02,.20,-.08,1.35,.12,.76,.60,.30,0},{9,7,-16,0,2,0,65}},
 {16.2,"MoonOrbit",{2,.03,.12,-.04,1.43,.10,.86,.42,.68,.90},{-6,5,-5,0,2,0,63}},
 {17.5,"MoonOrbit",{2,0,.05,-.10,1.50,.12,1,.30,1,3.1},{0,13,-.2,0,2,0,69}},
 {18.8,"MoonOrbit",{2,-.02,-.08,-.28,1.12,.14,.84,.25,.82,5.3},{-6,5,-5,0,2,0,62}},
 {19.5,"Cyclone",{2,-.08,-.20,-.62,.72,.16,.78,.20,.45,tau},{1,.9,-3.5,0,1.1,0,49}},
 {21,"Cyclone",{1.9,-.15,-.30,-.90,.60,.18,.86,.24,.28,tau},{-1.6,1.3,-4.2,0,1,0,54}},
 {22.5,"Settling",{1.5,-.06,-.10,-.30,.40,.14,.56,.10,.12,tau},{5,4,-9,0,1.5,0,59}},
 {24,"Landing",{0,-.18,-.25,-.45,.25,.30,.30,0,0,tau},{7,3,-14,0,.8,0,61}},
 {26,"Landing",{0,0,.02,.03,.10,.04,.10,0,0,tau},{7,3,-14,0,1,0,60}},
}
local poseFields={"RootY","Lean","Head","Arm","Spread","Leg","Energy","Pillar","Moon","Orbit"}
local cameraFields={"X","Y","Z","TX","TY","TZ","FOV"}
function T.Sample(time)
 local t=tonumber(time) or 0
 if t~=t then t=0 end
 t=math.clamp(t,0,T.Duration)
 local index=1
 while index<#keys and keys[index+1][1]<=t do index+=1 end
 local a,b=keys[index],keys[math.min(index+1,#keys)]
 local alpha=b[1]>a[1] and (t-a[1])/(b[1]-a[1]) or 0
 alpha=alpha*alpha*(3-2*alpha)
 local result={Phase=a[2],Camera={}}
 for i,field in ipairs(poseFields) do result[field]=a[3][i]+(b[3][i]-a[3][i])*alpha end
 for i,field in ipairs(cameraFields) do result.Camera[field]=a[4][i]+(b[4][i]-a[4][i])*alpha end
 return result
end
return T
