// Verdict tiers, scoring focus, shield rules and the shared engine. Simulated only: these
// prove the Lua logic, not behaviour in the Forever client.
const fs = require('node:fs');
const path = require('node:path');
const parser = require('luaparse');
const {lua,lauxlib,lualib,to_luastring,to_jsstring} = require('fengari');
const L = lauxlib.luaL_newstate(); lualib.luaL_openlibs(L);
function run(code) {
 if (lauxlib.luaL_dostring(L,to_luastring(code))!==lua.LUA_OK) throw Error(to_jsstring(lua.lua_tostring(L,-1)));
}
run(`
NS={}; combat=false
function InCombatLockdown() return combat end
secret=setmetatable({},{__add=function() error('secret arithmetic') end,__lt=function() error('secret comparison') end})
function issecretvalue(v) return rawequal(v,secret) end
`);
function load(name) {
 const source=fs.readFileSync(path.join(__dirname,'../addon/Everfrost',name),'utf8');
 parser.parse(source,{luaVersion:'5.1'});
 run('local function addon(...)\n'+source+'\nend\naddon("Everfrost",NS)');
}
for (const file of ['Profiles.lua','Core.lua','GearProfiles.lua','Gear.lua']) load(file);
run(`
local G=NS.Gear
checks=0
function check(ok,message) checks=checks+1; if not ok then error(message or 'check failed',2) end end
function item(id,loc,raw,classID,sub)
 return {id=id,link='item:'..id,name='Item '..id,loc=loc or 'INVTYPE_CHEST',level=1,classID=classID or 4,subclassID=sub or 1,stats=assert(G.Normalize(raw or {}))}
end
function empty() local e={}; for i=1,19 do e[i]=false end; return e end
function ctx(class,spec,role) return {class=class,spec=spec,role=role or 'damage',level=30,dual=false} end
local STR,STA,INT,AGI='ITEM_MOD_STRENGTH_SHORT','ITEM_MOD_STAMINA_SHORT','ITEM_MOD_INTELLECT_SHORT','ITEM_MOD_AGILITY_SHORT'
local DPS,ARM,SP,HEAL,BLOCK='ITEM_MOD_DAMAGE_PER_SECOND_SHORT','RESISTANCE0_NAME','ITEM_MOD_SPELL_POWER_SHORT','ITEM_MOD_SPELL_HEALING_DONE','ITEM_MOD_BLOCK_VALUE'

-- Thresholds ----------------------------------------------------------------------------------
check(NS.gearTiers.clear==0.10 and NS.gearTiers.minor==0.03,'documented thresholds')
-- Arms' simulated weights: Strength 2.2, Agility 1.76, so 50 Strength scores 110.
local arms=ctx('WARRIOR',1)
local worn=empty(); worn[5]=item(1,nil,{[STR]=50})
local function verdict(raw,equipment,context) return G.Compare(item(2,nil,raw),equipment or worn,context or arms) end
local r=verdict({[STR]=60}); check(r.verdict=='clear' and r.kind=='need' and math.abs(r.pct-0.2)<1e-9,'20% is a clear upgrade')
r=verdict({[STR]=55}); check(r.verdict=='clear','exactly 10% is clear')
r=verdict({[STR]=52,[AGI]=1}); check(r.verdict=='minor' and r.kind=='need' and math.abs(r.pct-0.056)<1e-9,'5.6% is a minor upgrade')
r=verdict({[STR]=50,[AGI]=1}); check(r.verdict=='sidegrade' and r.kind=='greed','1.6% up is a sidegrade, never a Need')
check(r.why=='About the same as your current item.','a one-sided sidegrade says so')
r=verdict({[STR]=49,[AGI]=1}); check(r.verdict=='sidegrade' and r.why=='More Agility, but less Strength.','a sidegrade names its trade-off')
-- Stamina is worth little to Arms, but it is Protection's top stat: the same small gain is
-- named for the tree that wants it instead of being called a sidegrade.
r=verdict({[STR]=50,[STA]=2}); check(r.verdict=='spec' and r.altLabel=='Protection','two Stamina suits Protection')
r=verdict({[STR]=49}); check(r.verdict=='sidegrade','2% down is still a sidegrade')
r=verdict({[STR]=48}); check(r.verdict=='downgrade' and r.kind=='greed' and r.why=='Your current item has more Strength.','4% down is a downgrade')
r=verdict({[STR]=10},empty()); check(r.verdict=='clear' and r.empty,'an empty slot is always a clear upgrade')
-- Not usable: armour type, level, class gear; and no tree is not scored at all.
check(G.Compare(item(3,nil,{[STR]=99},4,4),worn,arms).verdict=='unusable','plate before 40')
local high=item(4,nil,{[STR]=99}); high.level=31; check(G.Compare(high,worn,arms).verdict=='unusable','level requirement')
check(G.Compare(item(5,'INVTYPE_SHIELD',{[STA]=20},4,6),empty(),ctx('MAGE',1)).verdict=='unusable','mages hold no shield')
check(G.Compare(item(6,nil,{[STR]=99}),worn,ctx('WARRIOR',0)).verdict=='unknown','no tree, no verdict')
-- Nothing your spec uses, and nothing another of your trees uses either: a downgrade.
r=G.Compare(item(7,nil,{[INT]=40}),worn,arms); check(r.verdict=='downgrade' and r.reason:find('No useful stats',1,true),'useless stats')

-- Spell power and weapon damage ---------------------------------------------------------------
local fire=ctx('MAGE',2); local robe=empty(); robe[5]=item(10,nil,{[SP]=18})
check(G.Compare(item(11,nil,{[SP]=20}),robe,fire).verdict=='clear','11% more spell power')
local bigRobe=empty(); bigRobe[5]=item(17,nil,{[SP]=40})
check(G.Compare(item(12,nil,{[SP]=40,ITEM_MOD_SPIRIT_SHORT=1}),bigRobe,fire).verdict=='sidegrade','one Spirit on a big robe is a sidegrade')
-- School damage another Mage tree uses is spec-dependent for Fire.
check(G.Compare(item(13,nil,{ITEM_MOD_FROST_DAMAGE_SHORT=30}),robe,fire).verdict=='spec','Frost damage suits Frost')
check(G.Compare(item(13,nil,{ITEM_MOD_FROST_DAMAGE_SHORT=30}),robe,fire).altLabel=='Frost')
local hands=empty(); hands[16]=item(14,'INVTYPE_WEAPON',{[DPS]=10},2,7)
check(G.Compare(item(15,'INVTYPE_WEAPON',{[DPS]=12},2,7),hands,arms).verdict=='clear','20% more weapon DPS')
check(G.Compare(item(16,'INVTYPE_WEAPON',{[DPS]=10.2},2,7),hands,arms).verdict=='sidegrade','2% more weapon DPS')

-- Rings and trinkets: always the weaker of the two -----------------------------------------
local rings=empty(); rings[11]=item(20,'INVTYPE_FINGER',{[STR]=12}); rings[12]=item(21,'INVTYPE_FINGER',{[STR]=2})
r=G.Compare(item(22,'INVTYPE_FINGER',{[STR]=6}),rings,arms)
check(r.slot==12 and r.verdict=='clear' and r.slotNote=='Compared with the weaker of your two rings.','replaces the weaker ring')
r=G.Compare(item(23,'INVTYPE_FINGER',{[STR]=1}),rings,arms)
check(r.slot==12 and r.verdict=='downgrade','worse than both rings')
local trinkets=empty(); trinkets[13]=item(24,'INVTYPE_TRINKET',{[STR]=20}); trinkets[14]=item(25,'INVTYPE_TRINKET',{[STR]=8})
r=G.Compare(item(26,'INVTYPE_TRINKET',{[STR]=10}),trinkets,arms)
check(r.slot==14 and r.verdict=='clear' and r.slotNote:find('trinkets',1,true),'replaces the weaker trinket')
-- An equipped on-use trinket's effect is flagged, not given a score.
trinkets[14].unscored={use=true}
check(G.Compare(item(27,'INVTYPE_TRINKET',{[STR]=10}),trinkets,arms).oldUnscored.use,'old item effect noted')

-- Scoring focus ---------------------------------------------------------------------------------
local choices=NS.GearFocusChoices('PALADIN',2)
check(#choices==4 and choices[1].key=='balanced' and choices[1].label=='Balanced Tank' and choices[1].default,'paladin focus list')
check(choices[2].label=='Tank Survivability' and choices[3].label=='Tank Threat' and choices[4].label=='Solo Levelling' and not choices[2].default)
check(#NS.GearFocusChoices('WARRIOR',3)==4 and NS.GearFocusChoices('WARRIOR',3)[3].key=='threat','warrior focus list')
local feral=NS.GearFocusChoices('DRUID',2)
check(#feral==4 and feral[1].label=='Cat Damage' and feral[2].label=='Bear Balanced','feral focus list')
check(NS.GearFocusChoices('MAGE',1)==nil and NS.GearFocusChoices('PALADIN',1)==nil and NS.GearFocusChoices('PALADIN',0)==nil,'single-profile specs')
-- Every focus profile keeps its guide source and only ranks known stats.
for class,specs in pairs(NS.gearFocus) do
 for spec,entry in pairs(specs) do
  for _,choice in ipairs(entry.list) do
   check(choice.profile.source==NS.profiles[class][spec].source and choice.profile.bestFor,'focus source')
   for _,group in ipairs(choice.profile.order) do for key in group:gmatch('%S+') do check(NS.gearStatLabels[key],'label for '..key) end end
  end
 end
end
G.focus=nil
check(NS.GearProfile('PALADIN',2,'tank',30)==NS.gearProfiles.PALADIN[2],'default focus is the guide order')
check(NS.GearPriorityText(NS.GearProfile('PALADIN',2,'tank',30)):find('^Balanced Tank: Stamina > Spell power'),'priority names the focus')
G.focus='threat'
check(NS.GearPriorityText(NS.GearProfile('PALADIN',2,'tank',30)):find('^Tank Threat: Spell power > Weapon DPS'),'threat order')
check(NS.GearProfile('MAGE',2,'damage',30)==NS.gearProfiles.MAGE[2],'focus ignored by single-profile specs')
check(NS.GearProfile('PALADIN',2,'tank',9)==NS.gearStarter.PALADIN,'starter below 10 whatever the focus')
G.focus='survival'
check(NS.GearOrderText(NS.GearProfile('PALADIN',2,'tank',30)):find('^Stamina > Armour / Defence > Block / Dodge / Parry'),'survival order')
G.focus='bogus'; check(NS.GearProfile('PALADIN',2,'tank',30)==NS.gearProfiles.PALADIN[2],'unknown key falls back')
G.focus='solo'; check(NS.GearProfile('DRUID',2,'damage',30)==NS.gearProfiles.DRUID[2],'a key a spec lacks falls back')
G.focus=nil

-- Protection Paladin: spell power versus stamina, by focus.
local prot=ctx('PALADIN',2,'tank')
local chest=empty(); chest[5]=item(30,nil,{[STA]=20},4,3)
r=G.Compare(item(31,nil,{[SP]=20},4,3),chest,prot)
check(r.verdict=='spec' and r.altLabel=='Tank Threat' and r.altBestFor=='tank threat','balanced: spell power suits Threat')
G.focus='threat'; r=G.Compare(item(31,nil,{[SP]=20},4,3),chest,prot)
check(r.verdict=='clear' and r.why=='Better because it has more Spell power, your top priority.','threat: a clear upgrade')
G.focus='survival'; r=G.Compare(item(31,nil,{[SP]=20},4,3),chest,prot)
check(r.verdict=='spec' and r.altLabel~='Holy' and r.altLabel~='Retribution','your own spec is named before another tree')
-- Armour: survivability values it far more than the balanced order.
chest[5]=item(32,nil,{[STA]=10,[ARM]=200},4,3)
local sturdier=item(33,nil,{[STA]=8,[ARM]=260},4,3)
G.focus=nil; check(G.Compare(sturdier,chest,prot).verdict~='clear' and G.Compare(sturdier,chest,prot).kind=='greed','balanced: even trade')
G.focus='survival'; check(G.Compare(sturdier,chest,prot).verdict=='clear','survival: armour wins')
G.focus=nil

-- Shields and two-handers ---------------------------------------------------------------------
local mace=item(40,'INVTYPE_WEAPON',{[DPS]=10,[STR]=5},2,4)
local shield=item(41,'INVTYPE_SHIELD',{[ARM]=500,[BLOCK]=10,[STA]=5},4,6)
local loadout=empty(); loadout[16]=mace; loadout[17]=shield
local great=item(42,'INVTYPE_2HWEAPON',{[DPS]=40,[STR]=40,[STA]=30},2,5)
for _,key in ipairs({false,'balanced','survival','threat','solo'}) do
 G.focus=key or nil
 r=G.Compare(great,loadout,prot)
 check(r.kind=='greed' and r.verdict~='clear' and r.verdict~='minor','a tank never sees a two-hander as an upgrade ('..tostring(key)..')')
end
G.focus=nil; r=G.Compare(great,loadout,prot)
check(r.shieldBlocked and r.verdict=='spec' and r.altLabel=='Retribution','but Retribution would take it')
check(r.reason=='Protection needs a shield, so a two-hander is never an upgrade','shield reason')
check(r.why:find('main hand and shield together',1,true),'two-hander compared with both hands')
check(r.previous==5*7+(500*0.1*3+10*6+5*9),'shield armour, block and stamina all count')
-- Weapon DPS alone: Threat ranks it second, and still no two-hander.
G.focus='threat'; check(G.Compare(item(43,'INVTYPE_2HWEAPON',{[DPS]=80},2,5),loadout,prot).kind=='greed','threat: no two-hander for DPS')
G.focus=nil
-- Without a shield in the guide, the shield's armour still counts against a two-hander.
local ret=ctx('PALADIN',3)
local slightly=item(44,'INVTYPE_2HWEAPON',{[DPS]=10.8},2,5)
check(G.Compare(slightly,loadout,ret).verdict=='downgrade','the shield and the Strength on the mace outweigh 8% more weapon DPS')
local bare=empty(); bare[16]=mace; bare[17]=false
local function noShield() local e=empty(); e[16]=item(45,'INVTYPE_WEAPON',{[DPS]=10},2,4); return e end
check(G.Compare(slightly,noShield(),ret).verdict=='minor','with nothing in the off-hand it is a minor upgrade')
r=G.Compare(slightly,bare,ret); check(r.verdict=='sidegrade' and r.why=='More Weapon DPS, but less Strength.','plain two-hand swap names the trade-off')
-- Off-hands a shield spec cannot use are unusable for it, but may suit another tree.
local book=item(46,'INVTYPE_HOLDABLE',{[INT]=10,[HEAL]=20},4,0)
r=G.Compare(book,loadout,prot)
check(r.verdict=='spec' and r.altLabel=='Holy' and r.reason:find('keeps a shield',1,true),'held off-hand suits Holy')
-- A shield upgrade for a tank counts armour and block.
local tower=item(47,'INVTYPE_SHIELD',{[ARM]=700,[BLOCK]=14,[STA]=5},4,6)
check(G.Compare(tower,loadout,prot).verdict=='clear','more armour and block')

-- Protection Warrior: weapon damage versus stamina by focus.
local tank=ctx('WARRIOR',3,'tank')
local sword=empty(); sword[16]=item(50,'INVTYPE_WEAPON',{[DPS]=10,[STA]=10},2,7); sword[17]=item(51,'INVTYPE_SHIELD',{[ARM]=400},4,6)
local fast=item(52,'INVTYPE_WEAPON',{[DPS]=11},2,7)
r=G.Compare(fast,sword,tank)
check(r.verdict=='spec' and r.altLabel=='Solo Levelling' and r.why=='Your current item has more Stamina.','balanced: the simulator ranks Stamina over weapon damage')
G.focus='solo'; check(G.Compare(fast,sword,tank).verdict=='minor','solo: weapon damage is a minor upgrade')
G.focus='survival'; r=G.Compare(fast,sword,tank)
check(r.verdict=='spec' and r.why=='Your current item has more Stamina.','survival: lost Stamina')
G.focus=nil

-- Feral: the simulator finds weapon damage valuable in both forms; Bear wants armour and
-- Stamina far more than Cat does.
local druid=ctx('DRUID',2)
local paw=empty(); paw[16]=item(60,'INVTYPE_WEAPON',{[DPS]=10},2,4)
check(G.Compare(item(61,'INVTYPE_WEAPON',{[DPS]=20},2,4),paw,druid).verdict=='clear','cat: weapon DPS')
local pelt=empty(); pelt[5]=item(65,nil,{[ARM]=100,[AGI]=20},4,2)
r=G.Compare(item(66,nil,{[ARM]=180,[AGI]=18,[STA]=4},4,2),pelt,druid)
check(r.kind=='greed' and r.verdict=='spec' and r.altLabel=='Bear Balanced','cat: better for Bear')
G.focus='balanced'
check(G.Compare(item(61,'INVTYPE_WEAPON',{[DPS]=20},2,4),paw,druid).verdict=='clear','bear: weapon DPS counts too')
local hide=empty(); hide[5]=item(62,nil,{[ARM]=100,[AGI]=5},4,2)
check(G.Compare(item(63,nil,{[ARM]=180,[AGI]=5,[STA]=4},4,2),hide,druid).verdict=='clear','bear: armour and stamina')
check(G.Compare(item(64,'INVTYPE_SHIELD',{[ARM]=900},4,6),empty(),druid).verdict=='unusable','druids hold no shield')
G.focus=nil

-- Alternatives, focus changes and rescans ----------------------------------------------------
local labels={}
for _,alt in ipairs(G.Alternatives(prot)) do labels[#labels+1]=alt.label end
check(table.concat(labels,',')=='Tank Survivability,Tank Threat,Solo Levelling,Holy,Retribution','alternatives in order')
local young=ctx('PALADIN',2); young.level=5; check(#G.Alternatives(young)==0,'no alternatives on starter gear')
local scheduled=0; G.Schedule=function() scheduled=scheduled+1 end
G.pending=false; G.SetFocus('threat'); check(G.focus=='threat' and G.pending and scheduled==1,'SetFocus rescans')
labels={}
for _,alt in ipairs(G.Alternatives(prot)) do labels[#labels+1]=alt.label end
check(labels[1]=='Balanced Tank','alternatives follow the focus')
G.SetFocus('threat'); check(scheduled==1,'no rescan when nothing changed')
G.SetFocus(7); check(G.focus==nil and scheduled==2,'non-string focus means default')
G.pending=false; G.Rescan(); check(G.pending and scheduled==3,'Rescan')
G.Schedule=nil
-- One engine: an explicit profile scores as that profile and never looks for alternatives.
r=G.Compare(item(31,nil,{[SP]=20},4,3),chest,prot,nil,nil,NS.GearFocusProfile('PALADIN',2,'survival'))
check(r.kind=='greed' and r.verdict~='spec','explicit profile')
-- Where the weights come from ---------------------------------------------------------------
-- Seventeen trees use the wowsims Forever simulator's presets; ten have no published weights
-- and keep an estimate from their guide's stat order.
local simulated,estimated,ids=0,0,{}
local function sane(p,name)
 check(type(p.id)=='string' and not ids[p.id],'unique profile id '..name); ids[p.id]=true
 check(type(p.weightSource)=='string' and NS.GearSourceText(p)=='Weights: '..p.weightSource,'source text '..name)
 for key,value in pairs(p.weights) do check(type(value)=='number' and value==value and value>=0 and value<1000,'weight '..name..' '..key) end
 check(p.weights.armor and p.weights.armor>0,'armour always counts '..name)
 for _,group in ipairs(p.order) do for key in group:gmatch('%S+') do check(NS.gearStatLabels[key],'label '..key) end end
end
for class,specs in pairs(NS.gearProfiles) do
 for spec=1,3 do
  local p=specs[spec]; sane(p,class..spec)
  if p.sim then simulated=simulated+1; check(p.weightSource=='wowsims Forever simulator ('..p.sim..')','sim source') else estimated=estimated+1 end
 end
 sane(NS.gearStarter[class],class..' starter')
end
for class,specs in pairs(NS.gearFocus) do
 for spec,entry in pairs(specs) do for index,choice in ipairs(entry.list) do if index>1 then sane(choice.profile,class..spec..choice.key) end end end
end
check(simulated==17 and estimated==10,'17 simulated trees, 10 estimates')
for _,pair in ipairs({{'MAGE',1},{'MAGE',2},{'MAGE',3},{'WARLOCK',1},{'WARLOCK',2},{'WARLOCK',3},{'PALADIN',1},{'PALADIN',2},{'DRUID',3},{'SHAMAN',3}}) do
 check(not NS.gearProfiles[pair[1]][pair[2]].sim,'no simulator weights for '..pair[1]..pair[2])
end
check(NS.gearWeightSource.url=='wowsims.com/forever' and NS.gearWeightSource.commit=='d45287b','the source is on record')
-- Items show Hit, Crit and the like as whole percentages; the simulator weighs rating points.
local U=NS.gearStatUnits
check(U.hit==10 and U.crit==14 and U.haste==10 and U.expertise==10 and U.dodge==12 and U.parry==15 and U.blockpct==5,'rating per 1%')
local A=NS.gearProfiles.WARRIOR[1].weights
check(math.abs(A.hit-50.3)<1e-9 and math.abs(A.crit-32.48)<1e-9 and A.dps==16.71 and A.dps2==0 and A.strength==2.2,'Arms preset')
local F=NS.gearProfiles.WARRIOR[2].weights
check(F.dps==12.59 and F.dps2==2.66 and math.abs(F.expertise-23.5)<1e-9,'Fury preset')
local B=NS.GearFocusProfile('DRUID',2,'balanced')
check(B.sim=='Bear' and B.kind=='tank' and B.armorRanked and B.weights.armor==0.174 and B.weights.stamina==1.003,'Bear preset')
check(NS.GearFocusProfile('WARRIOR',3,'threat').sim=='Pre-BiS Offensive' and not NS.GearFocusProfile('WARRIOR',3,'survival').sim,'warrior tank focuses')
-- School damage counts at the share the simulator gives it.
local moon=NS.gearProfiles.DRUID[1]
check(G.Score(item(100,nil,{ITEM_MOD_ARCANE_DAMAGE_SHORT=100}),ctx('DRUID',1),moon)==68 and G.Score(item(101,nil,{ITEM_MOD_NATURE_DAMAGE_SHORT=100}),ctx('DRUID',1),moon)==32,'Balance school shares')
-- The simulator measures damage, so Stamina and armour are a small levelling allowance there.
local R=NS.gearProfiles.ROGUE[2]
check(R.weights.stamina==0.25 and R.weights.armor==0.02 and not R.armorRanked and R.allowance,'levelling allowance')
check(NS.gearProfiles.WARRIOR[3].weights.stamina==1.15 and NS.gearProfiles.WARRIOR[3].armorRanked,'a tank preset ranks them itself')
-- The priority line follows the weights, per rating point as the simulator lists them.
check(NS.GearOrderText(NS.gearProfiles.WARRIOR[1])=='Weapon DPS > Hit > Crit > Strength > Agility > Expertise > Haste > Attack power > Stamina','Arms order')
check(NS.GearOrderText(NS.gearProfiles.WARRIOR[1],3)=='Weapon DPS > Hit > Crit','a tooltip keeps the first few')
check(NS.GearOrderText(NS.gearProfiles.PRIEST[1])=='Healing power > Crit > MP5 > Intellect > Haste / Spirit > Stamina','equal weights share a group')
-- An estimate scales its percentage stats the same way, and block covers value and chance.
local fireP=NS.gearProfiles.MAGE[2].weights
check(fireP.spell==7 and fireP.crit==6*14 and fireP.hit==3*10 and fireP.wand==1,'Fire estimate')
local pp=NS.gearProfiles.PALADIN[2].weights
check(pp.block==6 and pp.blockpct==30 and pp.armor==3*0.1 and pp.attack==pp.strength/2,'Protection Paladin estimate')
local norm=G.Normalize({ITEM_MOD_BLOCK_VALUE=12,ITEM_MOD_BLOCK_RATING=2})
check(norm.block==12 and norm.blockpct==2,'block value and block chance are read apart')

-- Off-hand weapons ----------------------------------------------------------------------------
-- Combat's preset values off-hand DPS at 2.93 against 10.57 in the main hand.
local combat=ctx('ROGUE',2); combat.dual=true
local blades=empty(); blades[16]=item(110,'INVTYPE_WEAPON',{[DPS]=20},2,7); blades[17]=item(111,'INVTYPE_WEAPONOFFHAND',{[DPS]=10},2,15)
local offhand=item(112,'INVTYPE_WEAPONOFFHAND',{[DPS]=12},2,15)
check(G.Score(offhand,combat,R)==12*10.57 and G.Score(offhand,combat,R,16)==12*10.57 and math.abs(G.Score(offhand,combat,R,17)-12*2.93)<1e-9,'hand decides the DPS weight')
r=G.Compare(offhand,blades,combat)
check(r.slot==17 and math.abs(r.delta-2*2.93)<1e-9 and math.abs(r.previous-10*2.93)<1e-9 and r.verdict=='clear' and math.abs(r.pct-0.2)<1e-9,'off-hand compared at the off-hand weight')
-- A two-hander displaces both: the off-hand it removes is counted at the off-hand weight.
r=G.Compare(item(113,'INVTYPE_2HWEAPON',{[DPS]=30},2,5),blades,ctx('WARRIOR',2))
check(math.abs(r.previous-(20*12.59+10*2.66))<1e-9,'two-hander against main hand plus off-hand')
-- An estimate has no off-hand weight of its own, so both hands score alike.
local young=NS.gearStarter.ROGUE
check(young.weights.dps2==nil and NS.GearWeight(young,'dps2')==young.weights.dps and G.Score(offhand,combat,young,17)==G.Score(offhand,combat,young,16),'estimates score both hands alike')

-- Your own weights ------------------------------------------------------------------------------
local saved={}; local rescans=0
G.Schedule=function() rescans=rescans+1 end
NS.SetGearWeights(saved); check(NS.gearCustom==saved,'saved table adopted')
local armsBase=NS.gearProfiles.WARRIOR[1]
check(NS.GearProfile('WARRIOR',1,'damage',30)==armsBase,'no changes: the default profile itself')
local sta=item(120,nil,{[STR]=50,[STA]=10})
check(G.Compare(sta,worn,arms).verdict~='clear','ten Stamina is no clear upgrade for Arms by default')
rescans=0; G.pending=false
check(NS.GearSetWeight(armsBase,'stamina',5)==true and saved['WARRIOR:1'].stamina==5 and rescans==1 and G.pending,'a change is saved and rescans')
local mine=NS.GearProfile('WARRIOR',1,'damage',30)
check(mine~=armsBase and mine.custom and mine.base==armsBase and mine.weights.stamina==5 and armsBase.weights.stamina==0.25,'a customised copy; defaults untouched')
check(mine.weights.strength==2.2 and mine.sim=='Pre-BiS Arms' and NS.GearSourceText(mine)=='Weights: your own weights','the rest keeps its defaults')
check(NS.GearProfile('WARRIOR',1,'damage',30)==mine,'the copy is reused until something changes')
check(NS.GearOrderText(mine):find('Hit > Stamina > Crit',1,true),'the order follows your weights')
r=G.Compare(sta,worn,arms); check(r.verdict=='clear' and math.abs(r.pct-50/110)<1e-9 and r.why=='Better because it has more Stamina.','your weights decide the verdict')
check(NS.GearProfile('WARRIOR',2,'damage',30)==NS.gearProfiles.WARRIOR[2],'other trees keep theirs')
-- Another tree's alternatives use that tree's own (customised) weights.
check(NS.GearSetWeight(mine,'armor',0.5) and NS.GearProfile('WARRIOR',1,'damage',30).armorRanked and NS.GearOrderText(NS.GearProfile('WARRIOR',1,'damage',30)):find('Armour',1,true),'armour you weigh becomes one of your stats')
check(NS.GearSetWeight(mine,'armor',nil) and saved['WARRIOR:1'].armor==nil and not NS.GearProfile('WARRIOR',1,'damage',30).armorRanked,'nil removes one change')
-- Out-of-range and unknown values are refused.
for _,bad in ipairs({-1,1000,0/0,math.huge,'5'}) do check(NS.GearSetWeight(mine,'stamina',bad)==false and saved['WARRIOR:1'].stamina==5,'refused '..tostring(bad)) end
check(NS.GearSetWeight(mine,'bogus',1)==false and NS.GearSetWeight(mine,'wand',1)==false and NS.GearSetWeight(nil,'stamina',1)==false,'unknown stats refused')
check(NS.GearSetWeight(mine,'stamina',0)==true and NS.GearProfile('WARRIOR',1,'damage',30).weights.stamina==0,'zero ignores a stat')
-- Setting the default value back removes the change, and an empty set is dropped.
check(NS.GearSetWeight(mine,'stamina',0.25)==true and saved['WARRIOR:1']==nil and NS.GearProfile('WARRIOR',1,'damage',30)==armsBase,'back to the default')
NS.GearSetWeight(armsBase,'stamina',5); NS.GearSetWeight(armsBase,'hit',1); rescans=0
NS.GearResetWeights(NS.GearProfile('WARRIOR',1,'damage',30)); check(saved['WARRIOR:1']==nil and rescans==1 and NS.GearProfile('WARRIOR',1,'damage',30)==armsBase,'reset')
-- Each focus keeps its own changes, and the spec-dependent check uses them.
local threat=NS.gearFocus.PALADIN[2].byKey.threat.profile
check(threat.id=='PALADIN:2:threat' and NS.gearProfiles.PALADIN[2].id=='PALADIN:2' and NS.gearStarter.PALADIN.id=='PALADIN:0','profile ids')
NS.GearSetWeight(threat,'spell',0)
check(NS.GearFocusProfile('PALADIN',2,'threat').custom and NS.GearFocusProfile('PALADIN',2,nil)==NS.gearProfiles.PALADIN[2],'only that focus changes')
local plainChest=empty(); plainChest[5]=item(30,nil,{[STA]=20},4,3)
G.focus=nil; r=G.Compare(item(31,nil,{[SP]=20},4,3),plainChest,prot)
check(r.altLabel~='Tank Threat','Threat no longer wants spell power once you zero it')
NS.GearResetWeights(threat)
r=G.Compare(item(31,nil,{[SP]=20},4,3),plainChest,prot); check(r.verdict=='spec' and r.altLabel=='Tank Threat','and wants it again after a reset')
-- Starters and the off-hand weight can be changed too.
local starter=NS.gearStarter.WARRIOR
NS.GearSetWeight(starter,'dps2',1); local early=NS.GearProfile('WARRIOR',1,'damage',5)
check(early.custom and early.starter and early.weights.dps2==1 and early.weights.dps==starter.weights.dps,'starter off-hand weight')
NS.GearResetWeights(early)
-- Damaged saved data is ignored rather than trusted.
NS.SetGearWeights({['WARRIOR:1']={stamina='lots',bogus=3,strength=math.huge,hit=-2},['MAGE:2']='x'})
check(NS.GearProfile('WARRIOR',1,'damage',30)==armsBase and NS.GearProfile('MAGE',2,'damage',30)==NS.gearProfiles.MAGE[2],'bad saved weights ignored')
NS.SetGearWeights('nonsense'); check(NS.gearCustom==nil and NS.GearSetWeight(armsBase,'stamina',5)==false,'no table, no changes')
NS.SetGearWeights({}); G.Schedule=nil; G.focus=nil
print('Gear verdicts: '..checks..' checks on tiers, unusable, spell power, weapon DPS, rings/trinkets, focus profiles, shields, two-handers, Feral, rescans, simulator weights, off-hand weapons and custom weights passed')
`);
