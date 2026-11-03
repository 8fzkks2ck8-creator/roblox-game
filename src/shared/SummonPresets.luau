-- Data-only summon direction. Effects are local, short, and share a fixed budget.
local P={All={},Budget={MaxInstances=72,MaxParticles=36,MaxPreviewParts=64,MaxPreviewDescendants=256,FPS=30}}
local function add(id,title,motif,color,accent,count,turns,tilt,pulse,phase,seed,pose)
 P.All[id]={Title=title,Motif=motif,Color=color,Accent=accent,Count=count,Turns=turns,Tilt=tilt,Pulse=pulse,Phase=phase,Seed=seed,Pose=pose}
end
-- Mythic: one signature gesture and a restrained impact.
add("vegeta","Royal Blue Ascension","pillar",{42,130,255},{243,210,95},12,.65,.08,.07,.15,101,"ascend")
add("ichigo","Moonfang Crescent","slashes",{255,119,45},{60,33,84},10,.35,-.32,.08,.42,102,"strike")
add("sukuna","Crimson Dismantle","slashes",{238,49,72},{255,178,164},16,-.55,.23,.11,.74,103,"strike")
add("gojo","Limitless Convergence","orbit",{89,161,255},{213,124,255},12,1.2,.06,.055,1.05,104,"calm")
add("asta","Anti-Magic Edge","slashes",{108,62,151},{246,72,59},14,-.8,-.2,.095,1.37,105,"strike")
add("yuji","Black Flash Awakening","storm",{236,43,83},{255,206,184},10,.6,.19,.12,1.68,106,"strike")
add("deku","Emerald Full Cowling","storm",{50,237,153},{210,255,220},14,1.05,-.08,.085,1.99,107,"charge")
add("jotaro","Silent Star","clock",{148,95,247},{104,242,250},12,-.25,.04,.045,2.31,108,"calm")
add("dio","The Frozen Second","clock",{255,214,64},{109,240,124},16,.2,-.12,.065,2.62,109,"strike")
add("gogeta","Stardust Breaker","burst",{100,198,255},{255,161,88},18,1.4,.15,.09,2.93,110,"charge")
add("vegito","Spirit Sword Radiance","pillar",{66,233,255},{255,233,133},10,-.45,-.16,.07,3.24,111,"strike")
add("ssb_goku","Azure Kamehameha","pillar",{37,167,255},{220,252,255},14,.85,.02,.1,3.56,112,"charge")
-- Secret: a slightly longer reveal, still using the same small effect pool.
add("naruto","Sage Spiral","spiral",{255,153,49},{103,189,255},14,1.65,.18,.08,.27,113,"charge")
add("aizen","Mirror Sovereignty","clock",{182,131,250},{247,226,174},10,-.65,-.09,.045,.59,114,"calm")
add("ui_goku","Silver Stillness","orbit",{231,246,255},{103,193,255},12,-1.1,.035,.035,.91,115,"calm")
add("cid","Atomic Eclipse","sigil",{160,95,247},{239,195,255},16,-.9,.12,.12,1.22,116,"calm")
add("madara","Falling Heavens","sigil",{232,73,78},{255,173,84},18,.55,-.24,.1,1.54,117,"ascend")
add("gear5_luffy","Clouds of Liberation","spiral",{245,243,255},{255,224,106},12,.95,.28,.06,1.85,118,"ascend")
add("beerus","Destroyer's Violet Orbit","orbit",{174,91,239},{255,156,231},8,-1.45,-.05,.055,2.17,119,"calm")
add("boros","Meteoric Drive","storm",{246,96,213},{111,238,255},18,1.8,.21,.11,2.48,120,"charge")
add("saitama","Serious Horizon","burst",{250,92,66},{255,227,106},8,.15,0,.075,2.79,121,"strike")
add("golden_experience_requiem","Return to Zero","sigil",{255,212,79},{205,112,252},14,-1.25,.14,.06,3.11,122,"calm")
-- Super Secret: distinct silhouettes and color stories, never a larger object cap.
add("marlon","Rift Sovereign","sigil",{69,249,221},{255,217,112},18,1.75,-.19,.1,.38,123,"ascend")
add("awakened_aizen","Shattered Chrysalis","petals",{239,224,255},{181,110,247},16,-1.5,.24,.07,1.42,124,"ascend")
add("broly","Emerald Detonation","burst",{130,247,65},{236,255,188},18,.95,-.11,.13,2.46,125,"charge")
add("simon","Spiral Beyond Heaven","spiral",{60,224,255},{249,99,180},18,2.15,.31,.09,3.5,126,"ascend")
function P.Get(id) return P.All[id] end
function P.Duration(tier)
 if tier==5 then return 3.2 elseif tier==6 then return 3.8 elseif tier==7 then return 4.4 end
 return 0
end
return P
