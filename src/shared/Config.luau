local C = {}
C.Title = "ANIME RIFT"
-- YOUR CUSTOMIZATION HUB: IDs, economy, artwork, sounds, and staff permissions.
C.Admin = {OwnerUserId=2531251234,UserIds={1},StudioEnabled=true,Cooldown=8,Duration=15,CoinGift=250,GemGift=25}
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
C.Economy={StartingCoins=1000,CoinsPerWin=250,GemsPerWin=10,CosmeticStandard=30,CosmeticBoosted=100,CharacterDuplicate=50,CosmeticDuplicate=5}
C.Rarities = {"Common", "Uncommon", "Rare", "Legendary", "Mythic", "Secret", "Super Secret"}
C.Colors = {Color3.fromRGB(163,180,200), Color3.fromRGB(90,226,166), Color3.fromRGB(82,172,255), Color3.fromRGB(255,195,77), Color3.fromRGB(221,112,255), Color3.fromRGB(255,92,130), Color3.fromRGB(100,255,238)}
C.BaseOdds = {60,30,8,1.8,0.19,0.01,0.001}
C.Characters = {}
local function hero(id,name,tier,style,q,e,r)
 local i = #C.Characters+1
 C.Characters[i] = {Id=id,Name=name,Tier=tier,Style=style,Skills={q,e,r},Health=100+(tier-1)*3,Damage=1+(tier-1)*0.035,Color=C.Colors[tier]}
end
hero("yamcha","Yamcha",1,"dash","Spirit Ball","Wolf Rush","Wolf Fang")
hero("krillin","Krillin",1,"guard","Destructo Disc","Solar Guard","Scatter Energy")
hero("lee","Rock Lee",2,"dash","Leaf Strike","Leaf Sprint","Lotus Burst")
hero("renji","Renji Abarai",2,"dash","Zabimaru Lash","Flash Step","Serpent Burst")
hero("rukia","Rukia Kuchiki",3,"guard","Frost Lance","Ice Guard","White Moon")
hero("piccolo","Piccolo",3,"guard","Special Beam","Namek Guard","Hellzone Burst")
hero("kakashi","Kakashi Hatake",4,"dash","Lightning Blade","Substitution","Lightning Field")
hero("byakuya","Byakuya Kuchiki",4,"guard","Petal Lance","Petal Guard","Senbonzakura")
hero("naruto","Naruto (Sage Mode)",6,"dash","Rasenshuriken","Sage Rush","Rasengan Storm")
hero("vegeta","Vegeta (Super Saiyan Blue)",5,"guard","Final Flash","Saiyan Guard","Big Bang Burst")
hero("aizen","Sosuke Aizen",6,"blink","Black Coffin","Mirror Step","Spiritual Collapse")
hero("ui_goku","Goku (Ultra Instinct)",6,"blink","Kamehameha","Instinct Step","Silver Nova")
hero("sasuke","Sasuke Uchiha",4,"dash","Chidori","Shadow Step","Amaterasu Burst")
C.Characters[#C.Characters].Rollable=false -- guaranteed Starter pack exclusive
hero("ichigo","Ichigo Kurosaki",5,"dash","Getsuga Tensho","Flash Step","Bankai Burst")
hero("sukuna","Ryomen Sukuna",5,"dash","Dismantle","Cursed Rush","Malevolent Shrine")
hero("gojo","Satoru Gojo",5,"guard","Hollow Purple","Infinity Guard","Unlimited Void")
hero("cid","Cid Kagenou",6,"blink","Shadow Lance","Shadow Step","I Am Atomic")
hero("marlon","Marlon",7,"blink","Rift Spear","Phantom Step","Sovereign Nova")
hero("madara","Madara Uchiha",6,"guard","Majestic Flame","Susanoo Guard","Shattered Heaven")
hero("asta","Asta",5,"dash","Demon Slayer","Black Rush","Black Divider")
hero("gear5_luffy","Luffy (Gear 5)",6,"blink","Dawn Whip","Cloud Step","Bajrang Gun")
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
C.Cosmetics = {}
for tier,name in ipairs({"Ember Band","Jade Orbit","Azure Halo","Solar Crown","Void Wings","Celestial Eclipse"}) do
 table.insert(C.Cosmetics,{Id="aura"..tier,Name=name,Tier=tier,Damage=tier*0.005,Defense=tier*0.005,Color=C.Colors[tier]})
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
-- Boss clicker balance: edit these values to tune progression.
C.Training={Interval=0.16,MaxStrength=1000000000,Clicks={1,2,4,8,16,32,64},Damage={1,1.3,1.8,2.5,3.5,5,8}}
C.Bosses={
 {Id="sentinel",Name="Rift Sentinel",Health=450,Damage=14,Coins=150,Required=0,Color=Color3.fromRGB(80,220,170)},
 {Id="oni",Name="Crimson Oni",Health=3000,Damage=22,Coins=750,Required=100,Color=Color3.fromRGB(255,75,110)},
 {Id="sovereign",Name="Void Sovereign",Health=18000,Damage=32,Coins=3500,Required=1000,Color=Color3.fromRGB(180,75,255)},
}
function C.ClickGain(id)
 local hero=C.Find(C.Characters,id) or C.Characters[1]
 return C.Training.Clicks[hero.Tier]
end
function C.BossDamage(id,strength,auraId)
 local hero=C.Find(C.Characters,id) or C.Characters[1]
 local aura=C.Find(C.Cosmetics,auraId)
 return math.floor((10+math.max(0,strength or 0)*0.12)*C.Training.Damage[hero.Tier]*(1+(aura and aura.Damage or 0)))
end
C.Cooldowns={M1=0.6,Q=5,E=8,R=16}
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
