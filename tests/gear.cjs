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
function item(id,loc,raw,classID,sub)
 return {id=id,link='item:'..id,loc=loc or 'INVTYPE_CHEST',level=1,classID=classID or 4,subclassID=sub or 1,stats=assert(G.Normalize(raw or {}))}
end
function empty() local e={}; for i=1,19 do e[i]=false end; return e end
function ctx(class,spec,role) return {class=class,spec=spec,role=role or 'damage',level=30,dual=false} end
local n=0
for class,profiles in pairs(NS.gearProfiles) do
 for spec=1,3 do
  local p=profiles[spec]; assert(p and p.source==NS.profiles[class][spec].source)
  n=n+1
 end
end
assert(n==27 and NS.GearProfile('MAGE',0)==nil)
assert(NS.GearProfile('HUNTER',3,'ranged')==NS.gearProfiles.HUNTER[2])
local equipment=empty(); local c=ctx('WARRIOR',1)
equipment[5]=item(1,nil,{ITEM_MOD_STRENGTH_SHORT=4,ITEM_MOD_STAMINA_SHORT=2})
assert(G.Compare(item(2,nil,{ITEM_MOD_STRENGTH_SHORT=8}),equipment,c).kind=='need')
local young=ctx('WARRIOR',1)
-- Below level 10 every class scores from its starter list, whatever spec is selected.
for level=1,9 do
 young.level=level
 local early=G.Compare(item(2,nil,{ITEM_MOD_STRENGTH_SHORT=8}),equipment,young)
 assert(early.kind=='need' and early.why=='Better because it has more Strength.')
 assert(NS.GearProfile('WARRIOR',1,'damage',level)==NS.gearStarter.WARRIOR)
end
young.level=10
assert(NS.GearProfile('WARRIOR',1,'damage',10)==NS.gearProfiles.WARRIOR[1])
assert(NS.GearProfile('WARRIOR',0,'damage',10)==nil)
for class in pairs(NS.trees) do
 local starter=NS.gearStarter[class]
 assert(starter and starter.starter and starter.source and #NS.GearPriorityText(starter)>0)
 for _,key in ipairs(starter.order) do assert(NS.gearStatLabels[key]) end
end
-- Starter lists suit the class: a Mage wants Intellect, a Rogue a better weapon, and any
-- wearable piece beats an empty slot. A caster's weapon DPS still earns no credit.
local earlyCtx=function(class) local e=ctx(class,0); e.level=5; return e end
local earlyMage=earlyCtx('MAGE')
assert(G.Compare(item(4,nil,{ITEM_MOD_INTELLECT_SHORT=2}),empty(),earlyMage).why=='Better because that slot is empty.')
local robeWorn=empty(); robeWorn[5]=item(5,nil,{ITEM_MOD_SPIRIT_SHORT=1})
assert(G.Compare(item(6,nil,{ITEM_MOD_INTELLECT_SHORT=2}),robeWorn,earlyMage).why=='Better because it has more Intellect, your top priority.')
assert(G.Compare(item(7,nil,{ITEM_MOD_SPIRIT_SHORT=2}),robeWorn,earlyMage).why=='Better because it has more Spirit.')
assert(G.Compare(item(8,'INVTYPE_WEAPON',{ITEM_MOD_DAMAGE_PER_SECOND_SHORT=50},2,7),empty(),earlyMage).kind=='greed')
local dagger=item(9,'INVTYPE_WEAPON',{ITEM_MOD_DAMAGE_PER_SECOND_SHORT=5},2,15)
local earlyRogue=earlyCtx('ROGUE')
local rogueEquip=empty(); rogueEquip[16]=item(10,'INVTYPE_WEAPON',{ITEM_MOD_DAMAGE_PER_SECOND_SHORT=3},2,15)
assert(G.Compare(dagger,rogueEquip,earlyRogue).why=='Better because it has more Weapon DPS, your top priority.')
assert(G.Compare(item(11,'INVTYPE_WEAPON',{ITEM_MOD_DAMAGE_PER_SECOND_SHORT=2},2,15),rogueEquip,earlyRogue).why=='Your current item has more Weapon DPS.')
local earlyWand=empty(); earlyWand[18]=item(12,'INVTYPE_RANGEDRIGHT',{ITEM_MOD_DAMAGE_PER_SECOND_SHORT=3},2,19)
assert(G.Compare(item(13,'INVTYPE_RANGEDRIGHT',{ITEM_MOD_DAMAGE_PER_SECOND_SHORT=6},2,19),earlyWand,earlyMage).why=='Better because it has a stronger wand attack.')
assert(G.Compare(item(14,'INVTYPE_WAIST',{RESISTANCE0_NAME=20},4,1),empty(),earlyCtx('WARRIOR')).kind=='need')
assert(G.Compare(item(2,nil,{ITEM_MOD_STRENGTH_SHORT=8}),equipment,young).kind=='need')
assert(G.Compare(item(3,nil,{ITEM_MOD_STRENGTH_SHORT=2}),equipment,c).kind=='greed')
assert(G.Compare(item(4,nil,{ITEM_MOD_INTELLECT_SHORT=20,ITEM_MOD_STAMINA_SHORT=10}),equipment,c).kind=='greed')
assert(G.Compare(item(5,nil,{ITEM_MOD_STRENGTH_SHORT=4,ITEM_MOD_STAMINA_SHORT=2}),equipment,c).kind=='greed')
assert(G.Compare(nil,equipment,c).kind=='unknown')
assert(G.Compare(item(2,nil,{ITEM_MOD_STRENGTH_SHORT=8}),equipment,ctx('WARRIOR',0)).kind=='unknown')
local high=item(6,nil,{ITEM_MOD_STRENGTH_SHORT=100}); high.level=31
assert(G.Compare(high,equipment,c).kind=='greed')
assert(G.Compare(item(7,nil,{ITEM_MOD_STRENGTH_SHORT=100},4,4),equipment,c).kind=='greed')
assert(G.Compare(item(7,nil,{ITEM_MOD_INTELLECT_SHORT=100},4,3),equipment,ctx('MAGE',1)).kind=='greed')
assert(G.Compare(item(7,'INVTYPE_SHIELD',{ITEM_MOD_STAMINA_SHORT=20},4,6),equipment,ctx('MAGE',1)).kind=='greed')
assert(G.Compare(item(7,'INVTYPE_RELIC',{},4,7),equipment,ctx('DRUID',1)).kind=='greed')
-- The same two items reverse order under the current Arcane/Fire priorities.
-- Arcane ranks Intellect above Crit; Fire ranks Crit above Intellect.
-- Crit is written on items as a percentage: 1% here.
equipment=empty(); equipment[5]=item(10,nil,{ITEM_MOD_CRIT_RATING_SHORT=1})
local power=item(11,nil,{ITEM_MOD_INTELLECT_SHORT=10})
assert(G.Compare(power,equipment,ctx('MAGE',1)).kind=='need')
assert(G.Compare(power,equipment,ctx('MAGE',2)).kind=='greed')
local healing=item(12,nil,{ITEM_MOD_SPELL_HEALING_DONE=30,ITEM_MOD_STAMINA_SHORT=5})
assert(G.Compare(healing,empty(),ctx('MAGE',2)).kind=='greed')
assert(G.Compare(healing,empty(),ctx('PALADIN',1)).kind=='need')
-- Aliases describe the same stat, so use the greatest value once.
local normalized=G.Normalize({ITEM_MOD_SPELL_POWER_SHORT=8,ITEM_MOD_SPELL_POWER=8,ITEM_MOD_SPELL_HEALING_DONE=8})
assert(normalized.spell==8)
local healProfile=NS.gearProfiles.PALADIN[1]
assert(G.Score(item(13,nil,{ITEM_MOD_SPELL_POWER=8,ITEM_MOD_SPELL_HEALING_DONE=8}),ctx('PALADIN',1),healProfile)==8*healProfile.weights.healing)
assert(G.Normalize({ITEM_MOD_STRENGTH_SHORT=secret})==nil)
assert(G.Normalize(secret)==nil)
assert(G.Compare(item(14,nil,{ITEM_MOD_FROST_DAMAGE_SHORT=20}),empty(),ctx('MAGE',3)).kind=='need')
assert(G.Compare(item(14,nil,{ITEM_MOD_FIRE_DAMAGE_SHORT=20}),empty(),ctx('MAGE',3)).kind=='greed')
assert(G.Compare(item(14,nil,{ITEM_MOD_FIRE_DAMAGE_SHORT=20}),empty(),ctx('WARLOCK',3)).kind=='need')
-- A ring compares against both real equipped slots, never the stronger one alone.
equipment=empty(); equipment[11]=item(20,'INVTYPE_FINGER',{ITEM_MOD_STRENGTH_SHORT=12}); equipment[12]=item(21,'INVTYPE_FINGER',{ITEM_MOD_STRENGTH_SHORT=2})
local ring=item(22,'INVTYPE_FINGER',{ITEM_MOD_STRENGTH_SHORT=6})
local result=G.Compare(ring,equipment,c); assert(result.kind=='need' and result.slot==12)
ring.unique=9; ring.limit=1; equipment[11].unique=9
assert(G.Compare(ring,equipment,c).kind=='greed')
equipment[12]=nil
assert(G.Compare(ring,equipment,c).kind=='unknown')
-- Two hands must beat the complete current weapon pair, including shield stats.
equipment=empty(); equipment[16]=item(30,'INVTYPE_WEAPON',{ITEM_MOD_DAMAGE_PER_SECOND_SHORT=10},2,7)
equipment[17]=item(31,'INVTYPE_SHIELD',{ITEM_MOD_STRENGTH_SHORT=8},4,6)
local two=item(32,'INVTYPE_2HWEAPON',{ITEM_MOD_DAMAGE_PER_SECOND_SHORT=10},2,8)
assert(G.Compare(two,equipment,c).kind=='greed')
two.stats.dps=20; assert(G.Compare(two,equipment,c).kind=='need')
assert(G.Compare(two,equipment,ctx('WARRIOR',3)).kind=='greed')
equipment[16]=two; equipment[17]=false
assert(G.Compare(item(33,'INVTYPE_WEAPON',{ITEM_MOD_DAMAGE_PER_SECOND_SHORT=100},2,7),equipment,c).kind=='unknown')
-- A carried complete pair is scored together, in either candidate direction.
local caster=ctx('MAGE',2)
local staff=item(50,'INVTYPE_2HWEAPON',{ITEM_MOD_SPELL_POWER_SHORT=20},2,10)
local sword=item(51,'INVTYPE_WEAPONMAINHAND',{ITEM_MOD_SPELL_POWER_SHORT=12},2,7)
local orb=item(52,'INVTYPE_HOLDABLE',{ITEM_MOD_SPELL_POWER_SHORT=10},4,0)
equipment=empty(); equipment[16]=staff
local mainEntry={item=sword}; local offEntry={item=orb}; local carried={mainEntry,offEntry}
local pair=G.Compare(sword,equipment,caster,carried,mainEntry)
assert(pair.kind=='need' and pair.combined and pair.companion==orb.link and pair.slot==16)
assert(pair.score==22*NS.gearProfiles.MAGE[2].weights.spell and pair.previous==20*NS.gearProfiles.MAGE[2].weights.spell)
local reverse=G.Compare(orb,equipment,caster,carried,offEntry)
assert(reverse.kind=='need' and reverse.companion==sword.link and reverse.slot==17 and reverse.delta==pair.delta)
staff.stats.spell=22; assert(G.Compare(sword,equipment,caster,carried,mainEntry).kind=='greed')
staff.stats.spell=30; assert(G.Compare(orb,equipment,caster,carried,offEntry).kind=='greed')
staff.stats.spell=20
assert(G.Compare(sword,equipment,caster,{mainEntry},mainEntry).kind=='unknown')
assert(G.Compare(orb,equipment,caster,{offEntry},offEntry).kind=='unknown')
-- Never use an ineligible companion or one that violates the final unique limit.
orb.level=31; assert(G.Compare(sword,equipment,caster,carried,mainEntry).kind=='unknown'); orb.level=1
orb.usable=false; assert(G.Compare(sword,equipment,caster,carried,mainEntry).kind=='unknown'); orb.usable=nil
local badShield={item=item(53,'INVTYPE_SHIELD',{ITEM_MOD_SPELL_POWER_SHORT=100},4,6)}
assert(G.Compare(sword,equipment,caster,{mainEntry,badShield},mainEntry).kind=='unknown')
sword.unique=9; sword.limit=1; orb.unique=9; orb.limit=1
assert(G.Compare(sword,equipment,caster,carried,mainEntry).kind=='unknown')
orb.unique=nil; equipment[11]=item(54,'INVTYPE_FINGER',{}); equipment[11].unique=9
assert(G.Compare(sword,equipment,caster,carried,mainEntry).kind=='unknown')
equipment[11]=false; sword.unique=nil
-- Prefer the best available partner, but unresolved data must not imply Greed.
local weak={item=item(55,'INVTYPE_HOLDABLE',{ITEM_MOD_SPELL_POWER_SHORT=1},4,0)}
assert(G.Compare(sword,equipment,caster,{mainEntry,weak,offEntry},mainEntry).companion==orb.link)
assert(G.Compare(sword,equipment,caster,{mainEntry,weak,{}},mainEntry).kind=='unknown')
assert(G.Compare(sword,equipment,caster,{mainEntry,offEntry,{}},mainEntry).kind=='need')
equipment[16]=nil; assert(G.Compare(orb,equipment,caster,carried,offEntry).kind=='unknown'); equipment[16]=staff
equipment[17]=nil; assert(G.Compare(sword,equipment,caster,carried,mainEntry).kind=='unknown'); equipment[17]=false
-- Even a companion with no weighted stats completes a legal usable setup.
local plain={item=item(56,'INVTYPE_HOLDABLE',{},4,0)}
sword.stats.spell=25
assert(G.Compare(sword,equipment,caster,{mainEntry,plain},mainEntry).kind=='need')
sword.stats.spell=12
-- Dual wield needs the learned skill and two physical copies, not one cached item twice.
-- Fury's simulated weights value an off-hand's DPS at about a fifth of a main hand's, so the
-- pair needs 18 DPS each to beat a 20 DPS two-hander.
local warrior=ctx('WARRIOR',2)
local weapon=item(57,'INVTYPE_WEAPON',{ITEM_MOD_DAMAGE_PER_SECOND_SHORT=18},2,7)
local a={item=weapon}; local b={item=weapon}
equipment[16]=item(58,'INVTYPE_2HWEAPON',{ITEM_MOD_DAMAGE_PER_SECOND_SHORT=20},2,8)
assert(G.Compare(weapon,equipment,warrior,{a,b},a).kind=='unknown')
warrior.dual=true
assert(G.Compare(weapon,equipment,warrior,{a},a).kind=='unknown')
assert(G.Compare(weapon,equipment,warrior,{a,b},a).kind=='need')
-- Loot is a separate copy, so it can pair with an identical carried weapon.
assert(G.Compare(weapon,equipment,warrior,{a}).kind=='need')
weapon.unique=10; weapon.limit=1
assert(G.Compare(weapon,equipment,warrior,{a}).kind=='unknown'); weapon.unique=nil
local tank=ctx('WARRIOR',3); tank.dual=true
assert(G.Compare(weapon,equipment,tank,{a,b},a).kind=='unknown')
local shield={item=item(59,'INVTYPE_SHIELD',{ITEM_MOD_STRENGTH_SHORT=10},4,6)}
weapon.stats.dps=21
assert(G.Compare(weapon,equipment,tank,{a,shield},a).kind=='need')
-- The screenshot's mace/orb pair is a known non-upgrade under Enhancement scoring.
equipment[16]=item(60,'INVTYPE_2HWEAPON',{ITEM_MOD_DAMAGE_PER_SECOND_SHORT=15.2,ITEM_MOD_SPIRIT_SHORT=10,ITEM_MOD_SPELL_POWER_SHORT=26},2,10)
local mace={item=item(61,'INVTYPE_WEAPON',{ITEM_MOD_DAMAGE_PER_SECOND_SHORT=5.7,ITEM_MOD_INTELLECT_SHORT=2,ITEM_MOD_SPELL_POWER_SHORT=10},2,4)}
local spiritOrb={item=item(62,'INVTYPE_HOLDABLE',{ITEM_MOD_INTELLECT_SHORT=3},4,0)}
local pictured=G.Compare(mace.item,equipment,ctx('SHAMAN',2),{mace,spiritOrb},mace)
assert(pictured.kind=='greed' and pictured.companion==spiritOrb.item.link)
-- The newer screenshots use Elemental: the staff beats the mace and orb.
local elemental=ctx('SHAMAN',1); elemental.level=18
assert(G.Compare(mace.item,equipment,elemental,{mace,spiritOrb},mace).kind=='greed')
local equippedPair=empty(); equippedPair[16]=mace.item; equippedPair[17]=spiritOrb.item
assert(G.Compare(equipment[16],equippedPair,elemental).kind=='need')
equipment=empty(); equipment[16]=item(34,'INVTYPE_WEAPON',{},2,7)
assert(G.Compare(two,equipment,c).kind=='unknown')
-- A stat stick cannot get weapon-DPS credit for Hunter; gear can still supply Agility.
local stick=item(40,'INVTYPE_WEAPON',{ITEM_MOD_DAMAGE_PER_SECOND_SHORT=100},2,7)
assert(G.Compare(stick,empty(),ctx('HUNTER',2)).kind=='greed')
assert(G.Compare(item(41,'INVTYPE_RANGED',{ITEM_MOD_DAMAGE_PER_SECOND_SHORT=10},2,2),empty(),ctx('HUNTER',2)).kind=='need')
local mutilate=ctx('ROGUE',1); mutilate.daggers=true
assert(G.Compare(stick,empty(),mutilate).kind=='greed')
assert(G.Compare(item(42,'INVTYPE_WEAPON',{ITEM_MOD_DAMAGE_PER_SECOND_SHORT=10},2,15),empty(),mutilate).kind=='need')
-- Subtlety ranks Attack Power below Agility: score it once at its own weight.
local subtlety=ctx('ROGUE',3); local subProfile=NS.gearProfiles.ROGUE[3]
local apItem=item(43,nil,{ITEM_MOD_ATTACK_POWER_SHORT=10},4,2)
local agilityItem=item(44,nil,{ITEM_MOD_AGILITY_SHORT=10},4,2)
assert(G.Score(apItem,subtlety,subProfile)==10*subProfile.weights.attack)
assert(G.Score(agilityItem,subtlety,subProfile)>G.Score(apItem,subtlety,subProfile))
local subEquip=empty(); subEquip[5]=apItem
assert(G.Compare(agilityItem,subEquip,subtlety).kind=='need')
-- Simulated profiles carry Attack Power's own measured weight.
local combatProfile=NS.gearProfiles.ROGUE[2]
assert(combatProfile.sim=='Combat Sinister' and G.Score(apItem,ctx('ROGUE',2),combatProfile)==10*combatProfile.weights.attack)
local arms=NS.gearProfiles.WARRIOR[1]
assert(G.Score(apItem,ctx('WARRIOR',1),arms)==10*arms.weights.attack and arms.weights.strength==2.2 and arms.weights.attack==1)
-- An estimate that leaves Attack Power out uses half its higher Strength or Agility weight.
local starterRogue=NS.gearStarter.ROGUE
assert(not starterRogue.sim and starterRogue.weights.attack==starterRogue.weights.agility/2)
assert(G.Score(apItem,ctx('ROGUE',0),starterRogue)==10*starterRogue.weights.agility/2)
local apRing=item(45,'INVTYPE_FINGER',{ITEM_MOD_ATTACK_POWER_SHORT=20}); local agiRing=item(46,'INVTYPE_FINGER',{ITEM_MOD_AGILITY_SHORT=6})
local ringEquip=empty(); ringEquip[11]=agiRing; ringEquip[12]=agiRing
assert(G.Compare(apRing,ringEquip,ctx('ROGUE',2)).kind=='need')
-- A plain wand is an upgrade for casters: stats still outrank a small DPS gain.
local wandOf=function(id,stats) return item(id,'INVTYPE_RANGEDRIGHT',stats,2,19) end
local plainWand=wandOf(47,{ITEM_MOD_DAMAGE_PER_SECOND_SHORT=8})
assert(G.Compare(plainWand,empty(),ctx('MAGE',2)).kind=='need')
assert(G.Compare(plainWand,empty(),ctx('PRIEST',1)).kind=='need')
assert(G.Compare(plainWand,empty(),ctx('WARRIOR',1)).reason:find('cannot use',1,true))
local wandEquip=empty(); wandEquip[18]=wandOf(48,{ITEM_MOD_DAMAGE_PER_SECOND_SHORT=6})
assert(G.Compare(plainWand,wandEquip,ctx('MAGE',2)).kind=='need')
wandEquip[18]=wandOf(49,{ITEM_MOD_DAMAGE_PER_SECOND_SHORT=6,ITEM_MOD_SPELL_POWER_SHORT=4})
assert(G.Compare(plainWand,wandEquip,ctx('MAGE',2)).kind=='greed')
-- Only results that depend on missing item data wait for item-data events.
assert(G.Compare(nil,equipment,c).waiting==true)
assert(not G.Compare(item(2,nil,{ITEM_MOD_STRENGTH_SHORT=8}),equipment,ctx('WARRIOR',0)).waiting)
-- The reported belts: plain mail replaces plain leather for Retribution on armor alone.
local ret=ctx('PALADIN',3)
local function belt(id,sub,armor,extra)
 local raw=extra or {}; raw.RESISTANCE0_NAME=armor
 return item(id,'INVTYPE_WAIST',raw,4,sub)
end
local worn=empty(); worn[6]=belt(70,2,18)
local girdle=belt(71,3,50)
local gain=G.Compare(girdle,worn,ret)
assert(gain.kind=='need' and gain.armorOnly and gain.armorGain==32 and gain.slot==6)
assert(gain.reason:find('+32 Armour',1,true))
-- An empty slot is a confirmed gain; unknown equipment still waits for data.
assert(G.Compare(girdle,empty(),ret).armorOnly)
local unread=empty(); unread[6]=nil
assert(G.Compare(girdle,unread,ret).waiting==true)
-- Less or equal armor with no useful stats still says so.
worn[6]=belt(72,3,50)
assert(G.Compare(belt(73,3,50),worn,ret).reason:find('No useful stats',1,true))
worn[6]=belt(74,3,60)
assert(G.Compare(girdle,worn,ret).reason:find('No useful stats',1,true))
-- Armor never outweighs a stat loss, whatever the difference.
worn[6]=belt(75,2,18,{ITEM_MOD_STRENGTH_SHORT=1})
local lost=G.Compare(belt(76,3,500),worn,ret)
assert(lost.kind=='greed' and not lost.armorOnly)
-- Stamina on a piece with no useful stats cannot stand in for lost Strength.
assert(G.Compare(belt(77,3,500,{ITEM_MOD_STAMINA_SHORT=50}),worn,ret).kind=='greed')
-- A lower-priority stat kept alongside more armor is still no loss.
worn[6]=belt(78,2,18,{ITEM_MOD_STAMINA_SHORT=2})
assert(G.Compare(belt(79,3,50),worn,ret).kind=='greed')
assert(G.Compare(belt(80,3,50,{ITEM_MOD_STAMINA_SHORT=2}),worn,ret).armorOnly)
-- A stat upgrade stays a stat upgrade, even with less armor.
worn[6]=belt(81,3,50)
local statUpgrade=G.Compare(belt(82,2,18,{ITEM_MOD_STRENGTH_SHORT=2}),worn,ret)
assert(statUpgrade.kind=='need' and not statUpgrade.armorOnly and statUpgrade.reason=='Estimated stat upgrade')
-- Equal stats: more armor breaks the tie for every damage or caster spec.
worn[6]=belt(83,2,18,{ITEM_MOD_STRENGTH_SHORT=4})
assert(G.Compare(belt(84,3,50,{ITEM_MOD_STRENGTH_SHORT=4}),worn,ret).armorOnly)
local robe=empty(); robe[5]=item(85,nil,{RESISTANCE0_NAME=10,ITEM_MOD_INTELLECT_SHORT=3})
assert(G.Compare(item(86,nil,{RESISTANCE0_NAME=20,ITEM_MOD_INTELLECT_SHORT=3}),robe,ctx('MAGE',2)).armorOnly)
-- Armour counts for every spec: a clearly better-armoured piece wins over a small stat loss,
-- says so, and reports how much of the score it was.
worn[6]=belt(92,2,18,{ITEM_MOD_STRENGTH_SHORT=4})
local sturdy=G.Compare(belt(93,3,318,{ITEM_MOD_STRENGTH_SHORT=3}),worn,ret)
assert(sturdy.kind=='need' and not sturdy.armorOnly and sturdy.reason:find('outweighs',1,true) and sturdy.reason:find('+300',1,true))
-- Retribution's weights are simulated, so its armour is Everfrost's levelling allowance: extra
-- credit at the profile's own rate, never one of its ranked stats.
local retProfile=NS.gearProfiles.PALADIN[3]
local strengthWeight,armorRate=retProfile.weights.strength,retProfile.weights.armor
assert(retProfile.sim and not retProfile.armorRanked and armorRate==0.02)
assert(math.abs(sturdy.armorCredit-300*armorRate)<0.001 and math.abs(sturdy.delta-(300*armorRate-strengthWeight))<0.001)
-- A little more armour does not buy back a real stat loss.
assert(G.Compare(belt(94,3,50,{ITEM_MOD_STRENGTH_SHORT=3}),worn,ret).kind=='greed')
-- Less armour counts against a piece too: one more Strength does not beat 200 lost armour.
worn[6]=belt(95,3,250,{ITEM_MOD_STRENGTH_SHORT=3})
assert(G.Compare(belt(96,2,50,{ITEM_MOD_STRENGTH_SHORT=4}),worn,ret).kind=='greed')
-- At 40 Warriors and Paladins can wear plate, and Hunters and Shamans mail; not a level sooner.
local function at(class,spec,level) local c=ctx(class,spec); c.level=level; return c end
local plate=belt(97,4,300,{ITEM_MOD_STRENGTH_SHORT=5}); local mail=belt(98,3,150,{ITEM_MOD_AGILITY_SHORT=5})
assert(G.Compare(plate,empty(),at('PALADIN',3,39)).reason:find('Armour type',1,true))
assert(G.Compare(plate,empty(),at('PALADIN',3,40)).kind=='need' and G.Compare(plate,empty(),at('WARRIOR',1,60)).kind=='need')
assert(G.Compare(mail,empty(),at('HUNTER',1,39)).reason:find('Armour type',1,true) and G.Compare(mail,empty(),at('SHAMAN',2,40)).kind=='need')
assert(G.Compare(plate,empty(),at('HUNTER',1,60)).reason:find('Armour type',1,true) and G.Compare(mail,empty(),at('ROGUE',2,60)).reason:find('Armour type',1,true))
-- Armor type and level limits still come first.
assert(G.Compare(belt(87,4,900),empty(),ret).reason:find('Armour type',1,true))
assert(G.Compare(belt(88,3,50),empty(),ctx('MAGE',2)).reason:find('Armour type',1,true))
-- Tanks already score armor, so this stays an ordinary stat upgrade for them.
worn[6]=belt(89,2,18)
local tankBelt=G.Compare(girdle,worn,ctx('WARRIOR',3))
assert(tankBelt.kind=='need' and not tankBelt.armorOnly)
-- A shield swap never counts a weapon as armor, and weapons get no armor credit.
local offhand=empty(); offhand[16]=false; offhand[17]=item(90,'INVTYPE_WEAPON',{ITEM_MOD_DAMAGE_PER_SECOND_SHORT=5},2,7)
assert(not G.Compare(item(91,'INVTYPE_SHIELD',{RESISTANCE0_NAME=200},4,6),offhand,ret).armorOnly)
print('Armour: scored for every spec, plain upgrades, stat protection, ties, eligibility and tanks passed')
print('Gear profiles: 27 specs; stat reversals, aliases, eligibility, paired slots, unique limits and weapon layouts passed')
`);
run(`
frames={}; hooks={}; metadataCalls=0; inventory={}; bagLinks={}; itemInfo={}; rawStats={}; rollLinks={}; rollEligibility={}
local methods={}
function methods:SetScript(name,fn) self.scripts[name]=fn end
function methods:HookScript(name,fn) self.hooks[name]=fn; self.hookCounts=self.hookCounts or {}; self.hookCounts[name]=(self.hookCounts[name] or 0)+1 end
function methods:RegisterEvent(name) self.events[name]=true end
function methods:CreateTexture() local t=widget(); t.owner=self; created=(created or 0)+1; return t end
function methods:CreateAnimationGroup() local g=widget(); g.owner=self; return g end
function methods:CreateAnimation() local a=widget(); self.animation=a; return a end
function methods:SetFromAlpha(value) self.from=value end
function methods:SetToAlpha(value) self.to=value end
function methods:SetDuration(value) self.duration=value end
function methods:SetLooping(value) self.looping=value end
function methods:SetSmoothing(value) self.smoothing=value end
function methods:SetHeight(value) self.height=value end
function methods:SetWidth(value) self.width=value end
function methods:GetWidth() return self.width end
function methods:SetPoint(...) self.points=self.points or {}; self.points[#self.points+1]={...} end
function methods:SetVertexColor(r,g,b,a) self.vertex={r,g,b,a} end
function methods:SetAtlas(name,useSize) self.atlas=name; self.atlasSize=useSize end
function methods:ClearAllPoints() self.points={} end
function methods:SetColorTexture(r,g,b,a) self.colorTexture={r,g,b,a} end
function methods:SetTexture(path) self.texture=path end
function methods:CreateFontString(_,layer,template) local t=widget(); t.owner=self; t.template=template; created=(created or 0)+1; return t end
function methods:SetText(text) self.text=text end
function methods:SetTextColor(r,g,b) self.textColor={r,g,b} end
function methods:IsPlaying() return self.playing==true end
function methods:Play() self.playing=true; self.plays=(self.plays or 0)+1 end
function methods:Stop() self.playing=false end
function methods:IsShown() return self.shown~=false end
function methods:IsVisible() return self.shown~=false end
function methods:IsEnabled() return self.enabled~=false end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:GetID() return self.id end
function methods:GetBagID() return self.bag end
function methods:GetName() return self.name end
function methods:GetOwner() return self.owner end
function methods:AddLine(line) self.lines[#self.lines+1]=line end
function methods:ClearLines()
 self.lines={}
 if self.hooks.OnTooltipCleared then self.hooks.OnTooltipCleared(self) end
end
function widget(name) return setmetatable({name=name,scripts={},hooks={},events={},lines={}},{__index=function(t,k) if k:find('^Everfrost') or k:find('^[a-z]') then return nil end; return methods[k] or function() end end}) end
function CreateFrame() local f=widget(); frames[#frames+1]=f; return f end
function hooksecurefunc(target,name,fn)
 if type(target)=='string' then hooks[target]=name else hooks[name]=fn end
end
function fire(event,...)
 for _,f in ipairs(frames) do if f.events[event] then f.scripts.OnEvent(f,event,...) end end
end
function tick()
 for _,f in ipairs(frames) do if f.scripts.OnUpdate then f.scripts.OnUpdate(f,0.1) end end
end
function GetInventoryItemLink(_,slot) assert(not combat); return inventory[slot] end
function IsPlayerSpell() return false end
function getInfo(link)
 assert(not combat); metadataCalls=metadataCalls+1
 if not itemInfo[link] then return nil end
 return table.unpack(itemInfo[link],1,13)
end
function getStats(link) assert(not combat); metadataCalls=metadataCalls+1; return rawStats[link] end
itemUseCalls=0
qualityCalls=0
local rarityColors={[0]={0.62,0.62,0.62},[1]={1,1,1},[2]={0.12,1,0},[3]={0,0.44,0.87},[4]={0.64,0.21,0.93}}
function qualityColor(q)
 assert(not combat); qualityCalls=qualityCalls+1
 local color=rarityColors[q] or {1,1,1}; return table.unpack(color)
end
C_Item={GetItemInfo=getInfo,GetItemStats=getStats,
 IsUsableItem=function() itemUseCalls=itemUseCalls+1; return false,false end,
 GetItemQualityColor=qualityColor,
 IsEquippableItem=function() assert(not combat); return true end,GetItemUniqueness=function() return 0,0 end}
C_Container={GetContainerNumSlots=function(bag) assert(not combat); return bag==0 and 2 or bag==1 and extraBagLink and 1 or 0 end,
 GetContainerItemLink=function(bag,slot) assert(not combat); if bag==0 then return bagLinks[slot] else return extraBagLink end end}
function GetLootRollItemLink(id) assert(not combat); return rollLinks[id] end
function GetLootRollItemInfo(id) assert(not combat); local eligible=rollEligibility[id] or {true,true}; return 1,'Item',1,2,false,eligible[1],eligible[2] end
function fixture(link,stat)
 itemInfo[link]={'Item',link,2,20,1,'Armor','Cloth',1,'INVTYPE_CHEST',1,1,4,1}; rawStats[link]=stat
end
fixture('item:100',{ITEM_MOD_STRENGTH_SHORT=3})
fixture('item:101',{ITEM_MOD_STRENGTH_SHORT=9})
fixture('item:102',{ITEM_MOD_INTELLECT_SHORT=20})
inventory[5]='item:100'; bagLinks[1]='item:101'; bagLinks[2]='item:102'
EverfrostDB={}; GameTooltip=widget()
tooltipRegistrations=0
Enum={TooltipDataType={Item=0}}
TooltipDataProcessor={AddTooltipPostCall=function(kind,fn)
 assert(kind==0); tooltipRegistrations=tooltipRegistrations+1; itemTooltipPostCall=fn
end}
GroupLootFrame1=widget('GroupLootFrame1'); GroupLootFrame1.NeedButton=widget(); GroupLootFrame1.GreedButton=widget(); GroupLootFrame1.rollID=1
rollLinks[1]='item:101'
function GroupLootFrame_OnShow() end
function ContainerFrame_UpdateAll() end
ContainerFrameItemButtonMixin={Initialize=function() end}
`);
load('GearUI.lua');
run(`
local G=NS.Gear
local STYLE=NS.gearMarkStyles
-- A mark is shown when its button carries a style; hiding clears it.
local function styleOf(button) return button.EverfrostMark and button.EverfrostMark.style end
local function shown(button) return styleOf(button)~=nil end
local function edgesShown(button)
 local m=button.EverfrostMark; if not m then return false end
 for _,edge in ipairs(m.edges) do if not edge:IsShown() then return false end end
 return true
end
local function edgesHidden(button)
 local m=button.EverfrostMark; if not m then return true end
 for _,edge in ipairs(m.edges) do if edge:IsShown() then return false end end
 return true
end
local function lines() return table.concat(GameTooltip.lines,'|') end
G.SetContext('WARRIOR',1,30,'damage',{})
fire('PLAYER_LOGIN'); tick()
assert(G.equipment[1]==false and G.equipment[5].link=='item:100')
-- Passive equipment can be equippable while its item-use action is unavailable.
assert(G.ReadItem('item:101').usable==true and itemUseCalls==0)
assert(G.bags[0][1].result.kind=='need' and G.bags[0][1].result.verdict=='clear')
local bag=widget(); G.TrackBag(bag,0,1)
-- A clear upgrade: a thin green border flush inside the slot, plus its gain as a green
-- percentage where a stack count would sit. No arrow, no glow, no ring, no pulse and nothing
-- drawn past the button's edge.
assert(styleOf(bag)==STYLE.clear and edgesShown(bag) and #bag.EverfrostMark.edges==4)
assert(not bag.EverfrostMark.ring and not bag.EverfrostMark.pulse)
for index,edge in ipairs(bag.EverfrostMark.edges) do
 assert((index<=2 and edge.height or edge.width)==2)
 for _,point in ipairs(edge.points) do assert(point[4]==0 and math.abs(point[5])<=2) end
 assert(edge.vertex[1]==0.30 and edge.vertex[2]==0.90 and edge.vertex[4]==0.95)
end
local gain=bag.EverfrostMark.gain
assert(not bag.EverfrostMark.arrow and gain and gain:IsShown() and gain.text=='+200%' and gain.template=='GameFontNormalSmall')
assert(gain.textColor[1]==0.10 and gain.textColor[2]==1.00 and gain.textColor[3]==0.10)
assert(gain.points[1][1]=='BOTTOMRIGHT' and gain.points[1][3]=='BOTTOMRIGHT')
-- The label is the result's gain: a percentage, capped past 200%, or NEW with nothing to beat.
assert(G.GainText(G.bags[0][1].result)=='+200%' and G.GainText({kind='need',pct=0.484,previous=40})=='+48%')
assert(G.GainText({kind='need',pct=2.6,previous=40})=='>200%' and G.GainText({kind='need',pct=9,previous=0,empty=true})=='NEW')
assert(G.GainText({kind='need',pct=5,previous=0.2})=='NEW' and G.GainText({kind='greed',pct=-0.2,previous=40})==nil and G.GainText(nil)==nil)
-- Repainting reuses every widget: no duplicates on reuse, and rarity no longer recolours it.
local made=created; G.PaintBag(bag); G.PaintBag(bag); assert(created==made)
itemInfo['item:101'][3]=4; G.items={}; G.Refresh(); assert(styleOf(bag)==STYLE.clear and created==made)
itemInfo['item:101'][3]=secret; G.items={}; G.Refresh(); assert(styleOf(bag)==STYLE.clear)
itemInfo['item:101'][3]=2; G.items={}; G.Refresh()
-- Native tooltip rebuilds keep the verdict, without duplicate OnEnter additions.
GameTooltip.owner=bag; GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
assert(lines():find('Everfrost: Clear upgrade (+200%)',1,true) and lines():find('Better because it has more Strength',1,true))
-- The generic reason gives way to the specific one: two short lines of why, not three.
assert(not lines():find('Estimated stat upgrade',1,true) and not lines():find('Estimated score',1,true))
assert(lines():find('Priority: Weapon DPS',1,true))
assert(not lines():find(NS.gearLevelNote,1,true))
local lineCount=#GameTooltip.lines; bag.hooks.OnEnter(bag); assert(#GameTooltip.lines==lineCount)
GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
assert(#GameTooltip.lines==lineCount and tooltipRegistrations==1)
-- A downgrade gets no mark in bags.
G.TrackBag(bag,0,2); assert(not shown(bag) and edgesHidden(bag) and not gain:IsShown())
GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
assert(lines():find('Everfrost: Downgrade',1,true) and lines():find('No useful stats',1,true))
G.TrackBag(bag,0,1); assert(styleOf(bag)==STYLE.clear and gain:IsShown() and bag.EverfrostMark.gain==gain)
G.TrackBag(bag,-1,1); assert(not shown(bag) and not gain:IsShown())
G.TrackBag(bag,0,1); bag.hooks.OnEnter(bag); assert(#GameTooltip.lines>0)
-- A minor upgrade (3.9% here: Stamina is a small levelling allowance on Arms' simulated
-- weights) is a thinner, softer border with its own, softer percentage.
local function legs(link,stats) fixture(link,stats); itemInfo[link][9]='INVTYPE_LEGS' end
legs('item:106',{ITEM_MOD_STRENGTH_SHORT=20,ITEM_MOD_STAMINA_SHORT=30}); inventory[7]='item:106'
legs('item:103',{ITEM_MOD_STRENGTH_SHORT=20,ITEM_MOD_STAMINA_SHORT=38}); bagLinks[2]='item:103'; fire('BAG_UPDATE',0); tick()
local minorBag=widget(); G.TrackBag(minorBag,0,2)
assert(G.bags[0][2].result.verdict=='minor' and styleOf(minorBag)==STYLE.minor and not minorBag.EverfrostMark.arrow)
assert(minorBag.EverfrostMark.gain.text=='+4%' and minorBag.EverfrostMark.gain.textColor[1]==0.55)
for index,edge in ipairs(minorBag.EverfrostMark.edges) do assert((index<=2 and edge.height or edge.width)==1) end
-- A sidegrade (0.5% here, and under 3% for Protection too) has no mark.
legs('item:104',{ITEM_MOD_STRENGTH_SHORT=20,ITEM_MOD_STAMINA_SHORT=31}); bagLinks[2]='item:104'; fire('BAG_UPDATE',0); tick()
assert(G.bags[0][2].result.verdict=='sidegrade' and G.bags[0][2].result.kind=='greed' and not shown(minorBag) and edgesHidden(minorBag))
GameTooltip.owner=minorBag; GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
assert(lines():find('Everfrost: Sidegrade',1,true))
bagLinks[2]='item:102'; fire('BAG_UPDATE',0); tick()
-- Loot rolls: a faint ring on Need that breathes slowly for a clear upgrade.
fire('START_LOOT_ROLL',1); tick()
local frame=GroupLootFrame1
local need=frame.NeedButton
assert(styleOf(need)==STYLE.needClear and need.EverfrostMark.ring:IsShown() and edgesHidden(need))
-- Round roll buttons carry no percentage; the tooltip has it.
assert(not need.EverfrostMark.gain and not shown(frame.GreedButton))
local pulse=need.EverfrostMark.pulse
assert(pulse:IsPlaying() and pulse.looping=='BOUNCE' and pulse.animation.from==0.5 and pulse.animation.to==1 and pulse.animation.duration==0.7 and pulse.animation.smoothing=='IN_OUT')
assert(need.EverfrostMark.ring.vertex[4]==1 and need.EverfrostMark.ring.texture=='Interface\\\\Buttons\\\\UI-ActionButton-Border')
-- Bold, not faint: full-strength bright green, drawn twice (the halo a little larger) so it
-- reads as a thick glow, and both layers pulse together.
local halo,haloPulse=need.EverfrostMark.halo,need.EverfrostMark.haloPulse
assert(halo:IsShown() and halo.texture==need.EverfrostMark.ring.texture and halo.vertex[1]==0.20 and halo.vertex[2]==1.00 and halo.vertex[4]==0.8)
assert(halo.points[1][4]<need.EverfrostMark.ring.points[1][4] and haloPulse:IsPlaying() and haloPulse.animation.duration==0.7)
local rollPlays=pulse.plays; G.PaintRoll(frame); assert(pulse.plays==rollPlays)
-- A downgrade leaves Need alone and gives Greed a clear, steady gold ring (no pulse: pulsing is
-- kept for a clear upgrade).
rollLinks[1]='item:102'; fire('START_LOOT_ROLL',1); tick()
assert(not shown(need) and not pulse:IsPlaying() and not haloPulse:IsPlaying() and not halo:IsShown() and styleOf(frame.GreedButton)==STYLE.greedHint)
local greedMark=frame.GreedButton.EverfrostMark
assert(not greedMark.pulse and greedMark.ring.vertex[1]==1.00 and greedMark.ring.vertex[2]==0.82 and greedMark.ring.vertex[4]==0.85)
assert(greedMark.halo:IsShown() and math.abs(greedMark.halo.vertex[4]-0.85*0.5)<1e-9)
-- A minor upgrade gets a steady ring, still bright green.
rollLinks[1]='item:103'; fire('START_LOOT_ROLL',1); tick()
assert(styleOf(need)==STYLE.needMinor and not pulse:IsPlaying() and not haloPulse:IsPlaying() and not shown(frame.GreedButton))
assert(need.EverfrostMark.ring.vertex[4]==0.85 and halo:IsShown() and math.abs(halo.vertex[4]-0.85*0.5)<1e-9)
-- Where the roll frame has an item icon, it carries the same border and percentage as a bag upgrade.
frame.IconFrame=widget(); G.PaintRoll(frame)
assert(styleOf(frame.IconFrame)==STYLE.minor and frame.IconFrame.EverfrostMark.gain.text=='+4%' and not frame.IconFrame.EverfrostMark.ring)
rollLinks[1]='item:101'; fire('START_LOOT_ROLL',1); tick()
assert(styleOf(frame.IconFrame)==STYLE.clear and frame.IconFrame.EverfrostMark.gain.text:find('%%$') and frame.IconFrame.EverfrostMark.gain:IsShown())
rollLinks[1]='item:102'; fire('START_LOOT_ROLL',1); tick()
assert(not shown(frame.IconFrame) and not frame.IconFrame.EverfrostMark.gain:IsShown())
rollLinks[1]='item:103'; fire('START_LOOT_ROLL',1); tick()
-- A sidegrade marks neither button.
rollLinks[1]='item:104'; fire('START_LOOT_ROLL',1); tick()
assert(not shown(need) and not shown(frame.GreedButton))
inventory[7]=nil; fire('BAG_UPDATE',0); tick()
rollLinks[1]='item:101'; rollEligibility[1]={false,true}; fire('START_LOOT_ROLL',1); tick()
assert(not shown(need) and not shown(frame.GreedButton))
rollEligibility[1]={true,true}; rollLinks[1]='item:999'; fire('START_LOOT_ROLL',1); tick()
assert(G.rolls[1].result.kind=='unknown' and not shown(frame.GreedButton) and not shown(need))
fixture('item:999',{ITEM_MOD_STRENGTH_SHORT=12}); fire('GET_ITEM_INFO_RECEIVED',999); tick()
assert(styleOf(need)==STYLE.needClear and pulse:IsPlaying())
-- Combat events do not read item APIs or modify protected roll actions.
local before=metadataCalls; combat=true; fire('PLAYER_REGEN_DISABLED'); fire('BAG_UPDATE',0); tick()
assert(G.pending and metadataCalls==before and not shown(bag) and edgesHidden(bag) and not gain:IsShown())
GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip); assert(#GameTooltip.lines==0)
assert(not shown(need) and not pulse:IsPlaying())
combat=false; fire('PLAYER_REGEN_ENABLED'); tick(); assert(styleOf(need)==STYLE.needClear)
fire('CANCEL_LOOT_ROLL',1); tick()
assert(G.rolls[1]==nil and not shown(need))
-- Hiding the whole UI is not the end of a roll: its mark returns with the frame.
rollLinks[2]='item:101'; frame.rollID=2; fire('START_LOOT_ROLL',2); tick()
assert(G.rolls[2] and shown(need))
frame.shown=false; frame.hooks.OnHide(frame); assert(not shown(need))
frame.shown=true; frame.hooks.OnShow(frame); tick()
assert(G.rolls[2] and shown(need))
GameTooltip:ClearLines(); need.hooks.OnEnter(need)
assert(lines():find('Clear upgrade (+200%) / Need',1,true))
GameTooltip:ClearLines(); frame.GreedButton.hooks.OnEnter(frame.GreedButton)
assert(lines():find('/ Need',1,true))
fire('CANCEL_LOOT_ROLL',2); tick(); assert(G.rolls[2]==nil and not shown(need))
-- Forever nests its roll buttons inside LootButtonContainer.
local nested=widget(); local widgetIndex=getmetatable(nested).__index
setmetatable(nested,{__index=function(t,k) if k=='NeedButton' or k=='GreedButton' then return nil end; return widgetIndex(t,k) end})
nested.LootButtonContainer=widget(); nested.LootButtonContainer.NeedButton=widget(); nested.LootButtonContainer.GreedButton=widget()
nested.rollID=3; rollLinks[3]='item:101'; G.TrackRoll(nested); fire('START_LOOT_ROLL',3); tick()
assert(shown(nested.LootButtonContainer.NeedButton) and nested.LootButtonContainer.NeedButton.hooks.OnEnter)
nested.shown=false; nested.hooks.OnHide(nested); assert(not shown(nested.LootButtonContainer.NeedButton))
fire('CANCEL_LOOT_ROLL',3); tick()
-- Forever calls Initialize(containerFrame, bag, slot); the older form has no container.
local pooled=widget(); hooks.Initialize(pooled,widget(),0,1)
assert(styleOf(pooled)==STYLE.clear)
local legacyButton=widget(); hooks.Initialize(legacyButton,0,1); assert(styleOf(legacyButton)==STYLE.clear)
-- A reused button keeps one set of hooks and one set of mark widgets, even after a bank bag.
local pooledMade=created
hooks.Initialize(pooled,widget(),6,1); assert(not shown(pooled))
hooks.Initialize(pooled,widget(),0,1); assert(styleOf(pooled)==STYLE.clear and pooled.hookCounts.OnEnter==1 and pooled.hookCounts.OnShow==1)
-- (Two throwaway container widgets above are the only new widgets.)
assert(created==pooledMade)
-- Bag changes outside combat keep the mark and reuse cached items.
fire('BAG_UPDATE',0); tick()
local reads=metadataCalls
fire('BAG_UPDATE',0); assert(shown(pooled)); tick()
assert(shown(pooled) and metadataCalls==reads)
-- A walk of every bag button happens when needed, not on every bag change.
local walks=0; ContainerFrame1={EnumerateValidItems=function() walks=walks+1; return function() end end}
fire('ADDON_LOADED','x'); tick(); assert(walks==1)
fire('BAG_UPDATE',0); tick(); assert(walks==1)
ContainerFrame1=nil
-- The talent window's NS.Glow keeps working: a gentle ring in the colour it asks for.
local talent=widget(); NS.Glow(talent,true,{color={1,0.82,0}},false,true)
assert(talent.EverfrostMark.ring:IsShown() and talent.EverfrostMark.ring.vertex[1]==1 and talent.EverfrostMark.pulse:IsPlaying())
NS.Glow(talent,false); assert(not shown(talent) and not talent.EverfrostMark.ring:IsShown())
-- Plain Unique-Equipped items report category -1 and limit copies of themselves.
fixture('item:300',{ITEM_MOD_STRENGTH_SHORT=9}); itemInfo['item:300'][9]='INVTYPE_TRINKET'
fixture('item:301',{ITEM_MOD_STRENGTH_SHORT=2}); itemInfo['item:301'][9]='INVTYPE_TRINKET'
local plainUnique=C_Item.GetItemUniqueness
C_Item.GetItemUniqueness=function(link) if link=='item:300' then return -1,1 end; return 0,0 end
local duplicate=G.ReadItem('item:300'); assert(duplicate.unique==-300 and duplicate.limit==1)
local twoTrinkets={}; for i=1,19 do twoTrinkets[i]=false end
twoTrinkets[13]=duplicate; twoTrinkets[14]=G.ReadItem('item:301')
local dupeResult=G.Compare(duplicate,twoTrinkets,G.context)
assert(dupeResult.kind=='greed' and dupeResult.verdict=='unusable' and dupeResult.reason:find('Not a valid',1,true))
twoTrinkets[13]=false; assert(G.Compare(duplicate,twoTrinkets,G.context).kind=='need')
C_Item.GetItemUniqueness=plainUnique
-- A plain armour upgrade explains itself without a score.
GameTooltip:ClearLines()
G.Tooltip(GameTooltip,{kind='need',verdict='clear',reason='More armour, no useful stats lost (+32 Armour)',armorOnly=true,score=0,previous=0,delta=0})
local armorLines=lines()
assert(armorLines:find('Everfrost: Clear upgrade',1,true) and armorLines:find('+32 Armour',1,true) and not armorLines:find('Estimated score',1,true))
-- Missing and secret metadata defer rather than treating an occupied slot as empty.
itemInfo['item:100']=nil; G.items={}; G.Refresh(); assert(G.bags[0][1].result.kind=='unknown')
-- Passive "Equip:" effects written on the tooltip count, for clients whose item stats leave them out.
tooltipLines={['item:301']={{leftText='Staff of Testing'},
 {leftText='Equip: Increases damage and healing done by magical spells and effects by up to 12.'},
 {leftText='Use: Increases spell power by 100 for 20 sec.'},{leftText='Chance on hit: Increases attack power by 50.'},
 {leftText='Equip: Increases damage done by Fire spells and effects by up to 7.'},{leftText='Equip: Restores 4 mana per 5 sec.'},
 {leftText='Equip: Increases healing done by spells and effects by up to 20.'},{leftText='Equip: +14 Attack Power.'}}}
C_TooltipInfo={GetHyperlink=function(link) assert(not combat); return tooltipLines[link] and {lines=tooltipLines[link]} end}
fixture('item:301',{ITEM_MOD_INTELLECT_SHORT=2}); G.items={}
local effects=G.ReadItem('item:301')
assert(effects.stats.spell==12 and effects.stats.fire==7 and effects.stats.mp5==4 and effects.stats.healing==20 and effects.stats.attack==14)
assert(effects.fromTooltip and effects.stats.intellect==2)
-- Use and chance-on-hit effects are recorded as unscored, never given a number.
assert(effects.unscored.use and effects.unscored.proc and not effects.unscored.equip)
-- An effect the client already reports is not counted twice.
fixture('item:302',{ITEM_MOD_SPELL_POWER_SHORT=12})
tooltipLines['item:302']={{leftText='Equip: Increases damage and healing done by magical spells and effects by up to 12.'}}
assert(G.ReadItem('item:302').stats.spell==12 and not G.ReadItem('item:302').fromTooltip and not G.ReadItem('item:302').unscored)
-- Tank lines: defence, block value, dodge and parry; an unreadable Equip line is flagged.
fixture('item:304',{})
tooltipLines['item:304']={{leftText='Equip: Increased Defense +7.'},{leftText='Equip: Increases the block value of your shield by 15.'},
 {leftText='Equip: Increases your chance to dodge an attack by 1%.'},{leftText='Equip: Increases your chance to parry an attack by 1%.'},
 {leftText='Equip: Improves your chance to hit by 2%.'},{leftText='Equip: Your attacks ignore 50 armour.'}}
local tankBits=G.ReadItem('item:304')
assert(tankBits.stats.defense==7 and tankBits.stats.block==15 and tankBits.stats.dodge==1 and tankBits.stats.parry==1 and tankBits.stats.hit==2)
assert(tankBits.unscored.equip and not tankBits.unscored.use)
-- Secret or missing tooltip text changes nothing.
fixture('item:303',{ITEM_MOD_INTELLECT_SHORT=1}); tooltipLines['item:303']={{leftText=secret},{}}
assert(G.ReadItem('item:303').stats.spell==0 and G.ReadItem('item:303').stats.intellect==1)
-- A trinket whose only worth is its Use effect is left unscored, and says why.
fixture('item:305',{}); itemInfo['item:305'][9]='INVTYPE_TRINKET'; itemInfo['item:305'][12]=4; itemInfo['item:305'][13]=0
tooltipLines['item:305']={{leftText='Use: Increases armour by 2000 for 20 sec.'}}
local onUse=G.Compare(G.ReadItem('item:305'),twoTrinkets,G.context)
assert(onUse.kind=='unknown' and onUse.reason:find("can't be scored",1,true) and not onUse.waiting)
-- With stats as well, it is judged on those stats and the tooltip names the unscored effect.
fixture('item:306',{ITEM_MOD_STRENGTH_SHORT=20}); itemInfo['item:306'][9]='INVTYPE_TRINKET'
tooltipLines['item:306']={{leftText='Use: Increases attack power by 200 for 20 sec.'}}
local withStats=G.Compare(G.ReadItem('item:306'),twoTrinkets,G.context)
assert(withStats.kind=='need' and withStats.unscored.use)
GameTooltip:ClearLines(); G.Tooltip(GameTooltip,withStats)
assert(lines():find("Its Use effect can't be scored",1,true))
-- Rings and trinkets name the weaker of the two they replace.
twoTrinkets[13]=G.ReadItem('item:300')
local trinketResult=G.Compare(G.ReadItem('item:306'),twoTrinkets,G.context)
assert(trinketResult.slot==14 and trinketResult.slotNote:find('weaker of your two trinkets',1,true))
C_TooltipInfo=nil; tooltipLines=nil; G.items={}
print('Equip effects from tooltips: spell, healing, school, attack power, mana, tank lines; unscored Use/proc/Equip effects reported, never scored: passed')
fixture('item:100',{ITEM_MOD_STRENGTH_SHORT=3}); rawStats['item:100'].ITEM_MOD_STRENGTH_SHORT=secret
G.Refresh(); assert(G.bags[0][1].result.kind=='unknown')
fixture('item:100',{ITEM_MOD_STRENGTH_SHORT=3})
-- Legacy APIs and absent optional UI hooks fail safely.
GetItemInfo=C_Item.GetItemInfo; GetItemStats=C_Item.GetItemStats; C_Item=nil
GetContainerNumSlots=C_Container.GetContainerNumSlots; GetContainerItemLink=C_Container.GetContainerItemLink; C_Container=nil
G.Refresh(); assert(G.bags[0][1].result.kind=='need')
-- Scan the whole inventory before painting: a partner in a later bag counts.
inventory[5]=nil; inventory[16]='item:200'; bagLinks[1]='item:201'; bagLinks[2]=nil; extraBagLink='item:202'
fixture('item:200',{ITEM_MOD_SPELL_POWER_SHORT=20}); itemInfo['item:200'][9]='INVTYPE_2HWEAPON'; itemInfo['item:200'][12]=2; itemInfo['item:200'][13]=10
fixture('item:201',{ITEM_MOD_SPELL_POWER_SHORT=12}); itemInfo['item:201'][9]='INVTYPE_WEAPONMAINHAND'; itemInfo['item:201'][12]=2; itemInfo['item:201'][13]=7
fixture('item:202',{ITEM_MOD_SPELL_POWER_SHORT=10}); itemInfo['item:202'][9]='INVTYPE_HOLDABLE'; itemInfo['item:202'][13]=0
G.SetContext('MAGE',2,30,'damage',{}); tick()
local offBag=widget(); G.TrackBag(offBag,1,1)
assert(shown(bag) and shown(offBag))
assert(G.bags[0][1].result.companion=='item:202' and G.bags[1][1].result.companion=='item:201')
GameTooltip:ClearLines(); bag.hooks.OnEnter(bag)
assert(lines():find('Pair with: Item',1,true))
assert(lines():find('Clear upgrade (+10%) (equip both)',1,true))
-- Loot hints use the same carried partners and react to partner removal/loading.
frame.rollID=2; rollLinks[2]='item:201'; fire('START_LOOT_ROLL',2); tick()
assert(shown(need) and G.rolls[2].result.companion=='item:202')
GameTooltip:ClearLines(); need.hooks.OnEnter(need)
assert(lines():find('(equip both) / Need',1,true))
extraBagLink=nil; fire('BAG_UPDATE',1); tick()
assert(G.bags[0][1].result.kind=='unknown' and not shown(bag))
assert(not shown(offBag) and not shown(need))
extraBagLink='item:202'; rawStats['item:202']=nil; G.items={}; fire('BAG_UPDATE',1); tick()
assert(G.bags[0][1].result.kind=='unknown')
rawStats['item:202']={ITEM_MOD_SPELL_POWER_SHORT=10}; fire('ITEM_DATA_LOAD_RESULT',202); tick()
assert(shown(bag) and shown(offBag) and shown(need))
local pairCalls=metadataCalls; combat=true; fire('PLAYER_REGEN_DISABLED'); tick()
assert(metadataCalls==pairCalls and not shown(bag) and not shown(offBag))
combat=false; fire('PLAYER_REGEN_ENABLED'); tick(); assert(shown(bag))
-- Starter tooltips explain themselves in plain words.
G.SetContext('MAGE',2,9,'damage',{}); tick()
assert(G.bags[0][1].result.delta and shown(bag))
GameTooltip:ClearLines(); bag.hooks.OnEnter(bag)
local starterLines=lines()
assert(starterLines:find('Starter priority: Intellect',1,true) and not starterLines:find('Estimated score',1,true))
assert(starterLines:find('Simple estimate',1,true) and not starterLines:find('|Priority:',1,true))
G.SetContext('MAGE',0,30,'damage',{}); tick()
assert(G.bags[0][1].result.kind=='unknown' and not shown(bag))
-- Permanent "not scored" results must not trigger a full rescan on item-data events.
local quiet=metadataCalls
fire('GET_ITEM_INFO_RECEIVED',1); fire('ITEM_DATA_LOAD_RESULT',1); tick()
assert(metadataCalls==quiet and not G.pending)
EverfrostDB.gear=false; G.Refresh(); assert(not shown(bag))
-- Disabled highlights skip item reads entirely, then resume when re-enabled.
local off=metadataCalls; G.Refresh(); assert(metadataCalls==off and next(G.bags)==nil)
assert(G.Evaluate('item:201').reason=='Gear highlights are disabled')
EverfrostDB.gear=true; G.SetContext('MAGE',2,30,'damage',{}); tick()
assert(next(G.bags)~=nil and shown(bag))
-- Quest rewards: recommend the best upgrade among the choices.
bagLinks={}; extraBagLink=nil; inventory={[5]='item:100'}; G.SetContext('WARRIOR',1,5,'damage',{})
local function questFixture(link,stat,price) fixture(link,stat); itemInfo[link][11]=price end
questFixture('item:400',{ITEM_MOD_STRENGTH_SHORT=5},10)
questFixture('item:401',{ITEM_MOD_STRENGTH_SHORT=9},1)
questFixture('item:402',{ITEM_MOD_STRENGTH_SHORT=1},7)
questFixture('item:403',{ITEM_MOD_STRENGTH_SHORT=1},90)
local rewardFrame=widget(); QuestInfoRewardsFrame=rewardFrame
local function reward(id,kind,objectType) local b=widget(); b.id=id; b.type=kind or 'choice'; b.objectType=objectType or 'item'; return b end
local r1,r2,r3=reward(1),reward(2),reward(1,'reward')
rewardFrame.RewardButtons={r1,r2,r3}
questLinks={'item:400','item:401'}
function GetQuestItemLink(kind,id) return kind=='choice' and questLinks[id] or nil end
function QuestInfo_Display() end
function MerchantFrame_Update() end
fire('BAG_UPDATE',0); tick(); assert(hooks.QuestInfo_Display and hooks.MerchantFrame_Update)
hooks.QuestInfo_Display(); tick()
-- One small "Recommended" word on the best upgrade; the other upgrade stays unmarked.
assert(styleOf(r2)==STYLE.clear and r2.EverfrostMark.label:IsShown() and r2.EverfrostMark.label.text=='Recommended')
assert(r2.EverfrostMark.label.template=='GameFontNormalSmall' and r2.EverfrostMark.label.points[1][1]=='BOTTOMRIGHT')
assert(not shown(r1) and not r3.EverfrostMark)
GameTooltip.owner=r2; GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
local questLines=lines()
assert(questLines:find('Clear upgrade',1,true) and questLines:find('Recommended: the best upgrade',1,true) and questLines:find('Better because it has more Strength',1,true))
GameTooltip.owner=r1; GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
assert(lines():find('upgrade',1,true) and not lines():find('Recommended',1,true))
-- Two close upgrades: the best is still recommended, and both tooltips call it a close call.
questFixture('item:405',{ITEM_MOD_STRENGTH_SHORT=8,ITEM_MOD_STAMINA_SHORT=1},1); questLinks={'item:405','item:401'}; fire('BAG_UPDATE',0); tick()
assert(r2.EverfrostMark.label.text=='Recommended' and not shown(r1))
GameTooltip.owner=r2; GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
assert(lines():find("close call with 1 other reward",1,true))
GameTooltip.owner=r1; GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
assert(lines():find('Close to the recommended reward',1,true))
-- With no upgrade on offer, the best sell value gets a gold border labelled as gold, no percentage.
inventory[5]='item:401'; questLinks={'item:402','item:403'}; fire('BAG_UPDATE',0); tick()
assert(styleOf(r2)==STYLE.sell and r2.EverfrostMark.label.text=='Best sell value' and not r2.EverfrostMark.gain:IsShown())
assert(r2.EverfrostMark.edges[1].vertex[1]==1 and r2.EverfrostMark.edges[1].vertex[2]==0.82)
assert(not shown(r1))
GameTooltip.owner=r2; GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
assert(lines():find('sells for the most',1,true) and lines():find('Downgrade',1,true))
-- Nothing is marked until every choice has loaded, or for a single forced reward.
questLinks={'item:402','item:404'}; fire('BAG_UPDATE',0); tick()
assert(not shown(r2) and not r2.EverfrostMark.label:IsShown())
questFixture('item:404',{ITEM_MOD_STRENGTH_SHORT=1},300); fire('GET_ITEM_INFO_RECEIVED',404); tick()
assert(shown(r2))
r2.shown=false; fire('BAG_UPDATE',0); tick(); assert(not shown(r2) and not shown(r1)); r2.shown=true
-- The quest log reads its own links, and currency choices are skipped.
QuestInfoFrame={questLog=true,rewardsFrame=rewardFrame}
inventory[5]='item:100'
function GetQuestLogItemLink(kind,id) return kind=='choice' and ({'item:400','item:401'})[id] or nil end
questLinks={}; fire('BAG_UPDATE',0); tick(); assert(r2.EverfrostMark.label.text=='Recommended')
r2.objectType='currency'; fire('BAG_UPDATE',0); tick(); assert(not shown(r2)); r2.objectType='item'
-- Combat and turning gear hints off both clear the marks.
fire('BAG_UPDATE',0); tick(); assert(shown(r2))
combat=true; fire('PLAYER_REGEN_DISABLED'); assert(not shown(r2) and not r2.EverfrostMark.label:IsShown()); tick(); combat=false; fire('PLAYER_REGEN_ENABLED'); tick()
assert(shown(r2))
EverfrostDB.gear=false; fire('BAG_UPDATE',0); tick(); assert(not shown(r2)); EverfrostDB.gear=true; fire('BAG_UPDATE',0); tick()
rewardFrame.shown=false; fire('BAG_UPDATE',0); tick(); assert(not shown(r2)); rewardFrame.shown=true
-- Quest icons: the border outlines the icon only, never the reward's name.
local iconReward=reward(1); iconReward.Icon=widget(); rewardFrame.RewardButtons={iconReward,r2}
fire('BAG_UPDATE',0); tick()
assert(not shown(iconReward) and shown(r2))
QuestInfoFrame.rewardsFrame.RewardButtons={r2,iconReward}
function GetQuestLogItemLink(kind,id) return kind=='choice' and ({'item:401','item:400'})[id] or nil end
fire('BAG_UPDATE',0); tick()
assert(shown(iconReward) and iconReward.EverfrostMark.target==iconReward.Icon and iconReward.EverfrostMark.edges[1].points[1][2]==iconReward.Icon)
-- When another focus or tree would pick a different reward, each pick says who it is best for.
QuestInfoFrame=nil; QuestInfoRewardsFrame=rewardFrame; rewardFrame.RewardButtons={r1,r2}
inventory={[5]='item:100'}; G.SetContext('PALADIN',2,30,'tank',{})
questFixture('item:410',{ITEM_MOD_STAMINA_SHORT=10},5)
questFixture('item:411',{ITEM_MOD_SPELL_HEALING_DONE=20,ITEM_MOD_INTELLECT_SHORT=10},50)
questLinks={'item:410','item:411'}; fire('BAG_UPDATE',0); tick()
assert(r1.EverfrostMark.label.text=='Recommended' and not shown(r2))
GameTooltip.owner=r1; GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
assert(lines():find('Best for tanking.',1,true) and lines():find('Balanced Tank priority: Stamina',1,true))
GameTooltip.owner=r2; GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
assert(lines():find('Best for healing.',1,true) and lines():find('Retribution damage',1,true) and lines():find('Better for Solo Levelling',1,true))
G.SetFocus('solo'); tick()
GameTooltip.owner=r1; GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
assert(r1.EverfrostMark.label.text=='Recommended' and lines():find('Best for solo damage.',1,true) and lines():find('Solo Levelling priority:',1,true))
G.SetFocus(nil); tick()
-- Same pick for every role: no "Best for" lines at all.
questFixture('item:412',{ITEM_MOD_STAMINA_SHORT=1},1); questLinks={'item:410','item:412'}; fire('BAG_UPDATE',0); tick()
GameTooltip.owner=r1; GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
assert(not lines():find('Best for',1,true))
G.SetContext('WARRIOR',1,5,'damage',{}); tick()
rewardFrame.RewardButtons={r1,r2,r3}
QuestInfoFrame=nil; QuestInfoRewardsFrame=nil
-- Merchants: upgrades you can afford get the border; the rest explain themselves in the tooltip.
MerchantFrame=widget(); MerchantFrame.selectedTab=1; MERCHANT_ITEMS_PER_PAGE=3
MerchantItem1ItemButton=widget(); MerchantItem1ItemButton.hasItem=true; MerchantItem1ItemButton.id=11
MerchantItem2ItemButton=widget(); MerchantItem2ItemButton.hasItem=true; MerchantItem2ItemButton.id=12
MerchantItem3ItemButton=widget(); MerchantItem3ItemButton.hasItem=nil; MerchantItem3ItemButton.id=13
local shopLinks={[11]='item:400',[12]='item:401',[13]='item:402'}; local affordable={[11]=true,[12]=false}
function GetMerchantItemLink(index) return shopLinks[index] end
function CanAffordMerchantItem(index) return affordable[index] end
hooks.MerchantFrame_Update(); tick()
assert(styleOf(MerchantItem1ItemButton)==STYLE.clear and MerchantItem1ItemButton.EverfrostMark.gain:IsShown() and MerchantItem1ItemButton.EverfrostMark.gain.text:find('%%$'))
assert(not MerchantItem1ItemButton.EverfrostMark.label)
assert(not MerchantItem2ItemButton.EverfrostMark and not MerchantItem3ItemButton.EverfrostMark)
GameTooltip.owner=MerchantItem2ItemButton; GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
assert(lines():find("You can't afford this yet.",1,true))
affordable[12]=true; hooks.MerchantFrame_Update(); tick(); assert(shown(MerchantItem2ItemButton))
MerchantFrame.selectedTab=2; hooks.MerchantFrame_Update(); tick(); assert(not shown(MerchantItem1ItemButton))
MerchantFrame.selectedTab=1; MerchantFrame.shown=false; hooks.MerchantFrame_Update(); tick(); assert(not shown(MerchantItem1ItemButton))
MerchantFrame=nil
-- Empty slots count only what the game confirms, and clear while results are pending.
inventory={[5]='item:100',[7]='item:100'}; fire('BAG_UPDATE',0); tick()
local noWeapon,emptyArmor=G.EmptySlots(); assert(noWeapon==true and emptyArmor==7)
inventory[16]='item:401'; fire('BAG_UPDATE',0); tick()
noWeapon,emptyArmor=G.EmptySlots(); assert(noWeapon==false and emptyArmor==7)
G.pending=true; noWeapon,emptyArmor=G.EmptySlots(); assert(noWeapon==false and emptyArmor==0); G.pending=false
local refreshed=0; G.OnRefreshed=function() refreshed=refreshed+1 end; fire('BAG_UPDATE',0); tick(); assert(refreshed==1); G.OnRefreshed=nil
print('Quest reward marks, close calls, sell-value fallback, merchant upgrades, affordability and empty slots: passed')
print('Gear UI: thin borders by tier, no sidegrade marks, bold roll rings and the roll icon percentage, widget reuse, async item data, secret rejection, combat deferral and legacy APIs passed')
`);
console.log('Gear checks passed. Forever client visuals and API behavior still require in-game testing.');
