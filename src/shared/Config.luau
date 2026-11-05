local C = {}
C.Title = "ANIME RIFT"
-- YOUR CUSTOMIZATION HUB: IDs, economy, artwork, sounds, and staff permissions.
C.Admin = {OwnerUserId=2531251234,UserIds={1},StudioEnabled=true,Cooldown=8,Duration=15,CoinGift=250,GemGift=25}
-- Broly's session skill: server times and rewards, optional uploaded skill audio.
C.BrolySkill={Windup=26,Duration=20,Multiplier=3,Cooldown=90,SoundId="rbxassetid://119358500041991"}
-- Dedicated cinematic dialogue; independent of the reward-card summon voice.
C.CinematicVoices={madara="rbxassetid://135791921703430"}
C.UI = {RevealShakeSeconds=1.6,WheelSeconds=4,SoundVolume=0.35,StudSlideSpeed=7,RevealSpinSpeed=35}
C.Sounds = {
	Click="rbxassetid://12221976",
	Open="rbxassetid://88442833509532",
	Shake="rbxassetid://117570443671176",
	Reveal="rbxassetid://4612378086",
	WheelTick="rbxassetid://100404607153093",
	Reward="rbxassetid://135913294904080",
}
-- Optional uploaded image IDs. Blank entries use built-in geometric icons.
C.Icons = {Shop="",Summon="",Inventory="",Cosmetics="",Wheel="",Codes="rbxassetid://74110488072850"}
C.StudioMemory = true -- Studio uses disposable test data; live servers always persist.
C.DataStore = "AnimeRift_v1"
C.SpinCost = 250
C.Economy={StartingCoins=1000,CosmeticStandard=30,CosmeticBoosted=100,CharacterDuplicate=50,CosmeticDuplicate=5}
C.Rarities = {"Common", "Uncommon", "Rare", "Legendary", "Mythic", "Secret", "Super Secret"}
C.Colors = {Color3.fromRGB(255,220,65), Color3.fromRGB(135,240,35), Color3.fromRGB(42,222,245), Color3.fromRGB(255,139,52), Color3.fromRGB(229,64,248), Color3.fromRGB(255,92,130), Color3.fromRGB(100,255,238)}
C.BaseOdds = {60,30,8,1.8,0.19,0.01,0.001}
C.Characters = {}
local function hero(id,name,tier)
 local i = #C.Characters+1
 C.Characters[i] = {Id=id,Name=name,Tier=tier,Color=C.Colors[tier]}
end
hero("yamcha","Yamcha",1)
hero("krillin","Krillin",1)
hero("lee","Rock Lee",2)
hero("renji","Renji Abarai",2)
hero("rukia","Rukia Kuchiki",3)
hero("piccolo","Piccolo",3)
hero("kakashi","Kakashi Hatake",4)
hero("byakuya","Byakuya Kuchiki",4)
hero("naruto","Naruto (Sage Mode)",6)
hero("vegeta","Vegeta (Super Saiyan Blue)",5)
hero("aizen","Sosuke Aizen",6)
hero("ui_goku","Goku (Ultra Instinct)",6)
hero("sasuke","Sasuke Uchiha",4)
C.Characters[#C.Characters].Rollable=false -- guaranteed Starter pack exclusive
hero("ichigo","Ichigo Kurosaki",5)
hero("sukuna","Ryomen Sukuna",5)
hero("gojo","Satoru Gojo",5)
hero("cid","Cid Kagenou",6)
hero("marlon","Marlon",7)
hero("madara","Madara Uchiha",6)
hero("asta","Asta",5)
hero("gear5_luffy","Luffy (Gear 5)",6)
-- Expanded roster; all added fighters are available through earned-coin summons.
hero("yuji","Yuji Itadori",5)
hero("eren","Eren Yeager",4)
hero("deku","Deku",5)
hero("kid_naruto","Kid Naruto",3)
hero("awakened_aizen","Awakened Aizen",7)
hero("denji","Denji",4)
hero("beerus","Beerus",6)
hero("boros","Boros",6)
hero("saitama","Saitama",6)
hero("jotaro","Jotaro Kujo",5)
hero("dio","Dio",5)
hero("golden_experience_requiem","Golden Experience Requiem",6)
hero("yuta","Yuta Okkotsu",4)
hero("gogeta","Gogeta",5)
hero("vegito","Vegito",5)
hero("ssb_goku","Goku (Super Saiyan Blue)",5)
hero("ssj_goku","Goku (Super Saiyan)",4)
hero("broly","Broly",7)
hero("simon","Simon",7)
-- Original block-built prototype outfits (no imported anime meshes or art).
C.Outfits = {
 madara={Skin={239,198,171},Cloth={154,46,48},Hair={25,24,35}},
 asta={Skin={240,200,169},Cloth={43,39,52},Hair={190,193,202}},
 gear5_luffy={Skin={239,194,157},Cloth={245,244,251},Hair={249,249,255}},
 sasuke={Skin={242,205,177},Cloth={89,80,129},Hair={24,25,39}},
 ichigo={Skin={242,195,153},Cloth={27,29,39},Hair={255,133,30}},
 sukuna={Skin={242,195,175},Cloth={239,229,214},Hair={240,145,161}},
 gojo={Skin={244,211,190},Cloth={33,29,57},Hair={236,245,255}},
 cid={Skin={239,203,179},Cloth={37,24,59},Hair={28,24,36}},
 marlon={Skin={169,118,84},Cloth={24,101,113},Hair={28,23,33}}, -- editable placeholder
 yamcha={Skin={242,195,153},Cloth={246,132,40},Hair={25,24,34}},
 krillin={Skin={242,195,153},Cloth={246,132,40},Bald=true},
 lee={Skin={242,195,153},Cloth={53,131,78},Hair={22,23,30}},
 renji={Skin={242,195,153},Cloth={30,30,42},Hair={177,42,54}},
 rukia={Skin={244,207,180},Cloth={30,30,42},Hair={26,24,39}},
 piccolo={Skin={109,186,89},Cloth={129,67,162},Bald=true},
 kakashi={Skin={240,197,159},Cloth={80,119,82},Hair={185,192,202}},
 byakuya={Skin={244,207,180},Cloth={33,33,46},Hair={20,22,30}},
 naruto={Skin={242,195,153},Cloth={240,130,38},Hair={255,211,65}},
 vegeta={Skin={242,195,153},Cloth={56,88,182},Hair={66,183,246}},
 aizen={Skin={242,195,153},Cloth={236,231,241},Hair={94,57,47}},
 ui_goku={Skin={242,195,153},Cloth={246,132,40},Hair={221,229,243}},
}
-- Stylized built-in outfits for the expanded roster; no mesh uploads required.
C.Outfits.yuji={Skin={242,196,169},Cloth={30,35,57},Hair={237,133,154},Collar={181,42,52}}
C.Outfits.eren={Skin={236,195,159},Cloth={72,91,65},Legs={51,49,44},Hair={72,46,31},Cape={51,83,53}}
C.Outfits.deku={Skin={241,202,173},Cloth={30,130,108},Legs={34,93,81},Hair={25,83,58},Collar={203,219,214}}
C.Outfits.kid_naruto={Skin={243,199,155},Cloth={247,139,35},Hair={255,215,64},Headband={65,93,153},Collar={46,81,159}}
C.Outfits.awakened_aizen={Skin={241,206,181},Cloth={246,243,250},Hair={91,53,43},Collar={196,153,233},Cape={235,230,247}}
C.Outfits.denji={Skin={242,196,158},Cloth={240,239,230},Legs={49,43,42},Hair={236,186,64},Tie={34,30,33}}
C.Outfits.beerus={Skin={157,105,185},Cloth={54,116,188},Legs={49,84,154},Bald=true,Ears={157,105,185},Collar={238,203,65}}
C.Outfits.boros={Skin={139,184,212},Cloth={72,51,107},Hair={224,121,220},Headband={220,40,80}}
C.Outfits.saitama={Skin={242,199,154},Cloth={248,210,39},Bald=true,Cape={241,242,244},Collar={203,52,45}}
C.Outfits.jotaro={Skin={239,192,156},Cloth={32,35,48},Hair={26,28,33},Hat={30,33,43},Collar={224,191,63}}
C.Outfits.dio={Skin={240,199,153},Cloth={239,197,44},Hair={245,217,77},Headband={88,184,84},Collar={67,153,65}}
C.Outfits.golden_experience_requiem={Skin={241,204,75},Cloth={229,182,60},Legs={226,187,66},Hair={173,76,196},Headband={177,80,198}}
C.Outfits.yuta={Skin={240,199,174},Cloth={237,238,239},Legs={39,46,66},Hair={29,32,47},Collar={193,200,219}}
C.Outfits.gogeta={Skin={242,190,145},Cloth={232,132,45},Legs={243,242,232},Hair={31,31,39},Collar={38,41,53}}
C.Outfits.vegito={Skin={242,190,145},Cloth={40,88,177},Hair={30,29,35},Collar={236,128,42}}
C.Outfits.ssb_goku={Skin={242,195,153},Cloth={247,132,37},Hair={49,203,246},Collar={42,93,174}}
C.Outfits.ssj_goku={Skin={242,195,153},Cloth={247,132,37},Hair={255,222,58},Collar={42,93,174}}
C.Outfits.broly={Skin={225,181,139},Cloth={117,69,164},Hair={130,235,61},Collar={126,210,53}}
C.Outfits.simon={Skin={240,194,157},Cloth={36,66,135},Hair={38,61,126},Collar={214,47,63},Cape={187,41,56}}
C.Cosmetics = {}
for tier,name in ipairs({"Ember Band","Jade Orbit","Azure Halo","Solar Crown","Void Wings","Celestial Eclipse"}) do
 table.insert(C.Cosmetics,{Id="aura"..tier,Name=name,Tier=tier,Power=tier*.1,Color=C.Colors[tier]})
end
-- Each purchase provides deterministic credits. One boosted credit = one character.
-- Set real Developer Product IDs from YOUR experience. Prices come from Roblox.
C.Products = {
 Starter={Id=0,Name="Starter pack",Description="Guaranteed Sasuke + 5 spin tickets + 1 boosted ticket",Character="sasuke",Tickets=5,Boosted=1,SuggestedPrice=49},
 Spins={Id=0,Name="10 character spins",Description="10 spin tickets",Tickets=10,SuggestedPrice=99},
 Boosted={Id=0,Name="Single boosted summon",Description="1 boosted ticket = 1 character; no guarantee of a Secret",Boosted=1,SuggestedPrice=79},
 Luck={Id=0,Name="2x luck • 15 minutes",Description="Doubles Rare+ probabilities; stacks duration, not strength",Luck=900,SuggestedPrice=39},
}
C.Codes = {RELEASE={Coins=10000},AIZENGOKU={Gems=1000}}
C.Wheel = {{Name="100 coins",Weight=50,Coins=100},{Name="250 coins",Weight=30,Coins=250},{Name="30 gems",Weight=15,Gems=30},{Name="500 coins",Weight=5,Coins=500}}
-- Wheel sectors are 5% each. Edit weights in multiples of 5, totaling 100.
function C.WheelLayout()
 local slots={};local total=0
 for index,prize in ipairs(C.Wheel) do
  assert(prize.Weight>=0 and prize.Weight%5==0,"Wheel weights must be nonnegative multiples of 5")
  total=total+prize.Weight
  for _=1,prize.Weight/5 do table.insert(slots,index) end
 end
 assert(total==100,"Wheel weights must total 100")
 return slots
end
-- Power is banked by clicking, then sold for coins. Rebirths retain collectibles.
C.Training={Interval=0.16,MaxStrength=1000000000,Clicks={1,2,4,8,16,32,64}}
C.Clicker={SellRate=2,RebirthBaseCost=2500,RebirthGems=25,RebirthBonus=.5,MaxRebirths=10000,RecycleCoins=25}
function C.ClickGain(id,rebirths,auraId)
 local hero=C.Find(C.Characters,id)
 local base=hero and C.Training.Clicks[hero.Tier] or 1
 local aura=C.Find(C.Cosmetics,auraId)
 return math.max(1,math.ceil(base*(1+math.max(0,rebirths or 0)*C.Clicker.RebirthBonus)*(1+(aura and aura.Power or 0))))
end
function C.RebirthCost(rebirths)
 return C.Clicker.RebirthBaseCost*(math.max(0,rebirths or 0)+1)^2
end
function C.Find(list,id) for _,v in ipairs(list) do if v.Id==id then return v end end end
function C.Odds(boosted,luck,list)
 local o=table.clone(C.BaseOdds)
 if boosted then o[3]=16;o[4]=9;o[5]=1.9;o[6]=0.1;o[7]=0.01 end
 -- Cosmetics retain their six tiers; never choose a tier with an empty pool.
 list=list or C.Characters
 local available={}
 for _,item in ipairs(list) do if item.Rollable~=false then available[item.Tier]=true end end
 local rareTotal=0
 for i=3,#o do
  if not available[i] then o[i]=0 elseif luck then o[i]=o[i]*2 end
  rareTotal=rareTotal+o[i]
 end
 local rest=100-rareTotal;o[1]=rest*2/3;o[2]=rest/3
 return o
end
function C.Roll(list,boosted,luck,rng)
 local odds=C.Odds(boosted,luck,list)
 local roll=rng:NextNumber(0,100);local sum=0;local tier=1
 for i,w in ipairs(odds) do sum=sum+w;if w>0 then tier=i;if roll<sum then break end end end
 local pool={};for _,v in ipairs(list) do if v.Tier==tier and v.Rollable~=false then table.insert(pool,v) end end
 return pool[rng:NextInteger(1,#pool)]
end
function C.GrantProduct(data,product)
 data.Tickets=data.Tickets+(product.Tickets or 0)
 data.Boosted=data.Boosted+(product.Boosted or 0)
 if product.Character then
  data.Characters[product.Character]=(data.Characters[product.Character] or 0)+1
 end
 if product.Luck then data.LuckUntil=math.max(os.time(),data.LuckUntil)+product.Luck end
end
return C
