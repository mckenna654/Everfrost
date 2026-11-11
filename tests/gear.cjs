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
equipment=empty(); equipment[5]=item(10,nil,{ITEM_MOD_CRIT_RATING_SHORT=10})
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
local warrior=ctx('WARRIOR',1)
local weapon=item(57,'INVTYPE_WEAPON',{ITEM_MOD_DAMAGE_PER_SECOND_SHORT=12},2,7)
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
-- Melee specs without an Attack Power rank use half their higher Strength or Agility weight.
local combatProfile=NS.gearProfiles.ROGUE[2]
assert(G.Score(apItem,ctx('ROGUE',2),combatProfile)==10*combatProfile.weights.agility/2)
-- The warrior guides rank Attack Power beside Strength, so it scores at that rank in full.
assert(G.Score(apItem,ctx('WARRIOR',1),NS.gearProfiles.WARRIOR[1])==10*NS.gearProfiles.WARRIOR[1].weights.attack)
assert(NS.gearProfiles.WARRIOR[1].weights.attack==NS.gearProfiles.WARRIOR[1].weights.strength)
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
local sturdy=G.Compare(belt(93,3,150,{ITEM_MOD_STRENGTH_SHORT=3}),worn,ret)
assert(sturdy.kind=='need' and not sturdy.armorOnly and sturdy.reason:find('outweighs',1,true) and sturdy.reason:find('+132',1,true))
local strengthWeight=NS.gearProfiles.PALADIN[3].weights.strength
assert(math.abs(sturdy.armorCredit-13.2)<0.001 and math.abs(sturdy.delta-(13.2-strengthWeight))<0.001)
-- A little more armour does not buy back a real stat loss.
assert(G.Compare(belt(94,3,50,{ITEM_MOD_STRENGTH_SHORT=3}),worn,ret).kind=='greed')
-- Less armour counts against a piece too: one more Strength no longer beats 100 lost armour.
worn[6]=belt(95,3,150,{ITEM_MOD_STRENGTH_SHORT=3})
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
function methods:CreateTexture() local t=widget(); t.owner=self; return t end
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
G.SetContext('WARRIOR',1,30,'damage',{})
fire('PLAYER_LOGIN'); tick()
assert(G.equipment[1]==false and G.equipment[5].link=='item:100')
-- Passive equipment can be equippable while its item-use action is unavailable.
assert(G.ReadItem('item:101').usable==true and itemUseCalls==0)
assert(G.bags[0][1].result.kind=='need')
local bag=widget(); G.TrackBag(bag,0,1)
assert(bag.EverfrostGearGlow and bag.EverfrostGearGlow:IsShown())
assert(#bag.EverfrostGearEdges==4)
-- A thin outline flush with the slot: two-pixel lines, none poking out past the button.
for index,edge in ipairs(bag.EverfrostGearEdges) do
 assert((index<=2 and edge.height or edge.width)==2)
 for _,point in ipairs(edge.points) do assert(point[4]==0 and math.abs(point[5])<=2) end
end
-- The soft glow's overhang follows the button's size (12 where the size is unknown).
assert(bag.EverfrostGearGlow.points[1][4]==-12 and bag.EverfrostGearGlow.points[1][5]==12)
for _,edge in ipairs(bag.EverfrostGearEdges) do assert(edge:IsShown()) end
local function assertColor(button,r,g,b)
 for _,layer in ipairs({button.EverfrostGearGlow,table.unpack(button.EverfrostGearEdges)}) do
  assert(layer.vertex[1]==r and layer.vertex[2]==g and layer.vertex[3]==b)
 end
end
assertColor(bag,0.12,1,0)
-- Upgrades get the native green arrow, which follows the glow on and off.
local arrow=bag.EverfrostGearArrow
assert(arrow and arrow:IsShown() and arrow.atlas=='bags-greenarrow' and arrow.atlasSize==true)
assert(#bag.EverfrostGearPulses==5)
for _,pulse in ipairs(bag.EverfrostGearPulses) do
 assert(pulse:IsPlaying() and pulse.looping=='BOUNCE')
 -- A gentle breathe, never a blink: it stays at least 40% lit and eases in and out.
 assert(pulse.animation.from==0.4 and pulse.animation.to==1 and pulse.animation.duration==0.9 and pulse.animation.smoothing=='IN_OUT')
end
local plays=bag.EverfrostGearPulses[1].plays; local calls=qualityCalls
G.PaintBag(bag); assert(bag.EverfrostGearPulses[1].plays==plays and qualityCalls==calls)
-- Reused buttons pick up new rarity colors, with safe neutral missing-data fallbacks.
itemInfo['item:101'][3]=3; G.items={}; G.Refresh(); assertColor(bag,0,0.44,0.87)
itemInfo['item:101'][3]=4; G.items={}; G.Refresh(); assertColor(bag,0.64,0.21,0.93)
itemInfo['item:101'][3]=secret; G.items={}; G.Refresh(); assertColor(bag,1,1,1)
assert(G.bags[0][1].result.kind=='need')
itemInfo['item:101'][3]=2; C_Item.GetItemQualityColor=function() return secret,1,1 end
G.items={}; G.Refresh(); assertColor(bag,1,1,1)
C_Item.GetItemQualityColor=nil; G.items={}; G.Refresh(); assertColor(bag,1,1,1)
C_Item.GetItemQualityColor=qualityColor; G.items={}; G.Refresh(); assertColor(bag,0.12,1,0)
-- Native tooltip rebuilds keep the label, without duplicate OnEnter additions.
GameTooltip.owner=bag; GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
assert(table.concat(GameTooltip.lines,'|'):find('Everfrost: UPGRADE',1,true))
assert(not table.concat(GameTooltip.lines,'|'):find(NS.gearLevelNote,1,true))
local lineCount=#GameTooltip.lines; bag.hooks.OnEnter(bag); assert(#GameTooltip.lines==lineCount)
GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
assert(#GameTooltip.lines==lineCount and tooltipRegistrations==1)
G.TrackBag(bag,0,2); assert(not bag.EverfrostGearGlow:IsShown() and not arrow:IsShown())
for _,edge in ipairs(bag.EverfrostGearEdges) do assert(not edge:IsShown()) end
for _,pulse in ipairs(bag.EverfrostGearPulses) do assert(not pulse:IsPlaying()) end
GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
assert(table.concat(GameTooltip.lines,'|'):find('Everfrost: No upgrade',1,true))
G.TrackBag(bag,0,1); assert(bag.EverfrostGearGlow:IsShown() and arrow:IsShown() and bag.EverfrostGearArrow==arrow)
G.TrackBag(bag,-1,1); assert(not bag.EverfrostGearGlow:IsShown() and not arrow:IsShown())
G.TrackBag(bag,0,1); bag.hooks.OnEnter(bag); assert(#GameTooltip.lines>0)
fire('START_LOOT_ROLL',1); tick()
local frame=GroupLootFrame1
assert(frame.NeedButton.EverfrostGearGlow:IsShown())
-- Roll buttons keep the glow only: the arrow marks items, not the Need button.
assert(not frame.NeedButton.EverfrostGearArrow)
-- Roll buttons are round, so they pulse without the square outline.
assert(#frame.NeedButton.EverfrostGearEdges==0 and #frame.NeedButton.EverfrostGearPulses==1)
assertColor(frame.NeedButton,0.12,1,0)
local rollPlays=frame.NeedButton.EverfrostGearPulses[1].plays
G.PaintRoll(frame); assert(frame.NeedButton.EverfrostGearPulses[1].plays==rollPlays)
itemInfo['item:101'][3]=3; G.items={}; fire('START_LOOT_ROLL',1); tick()
assertColor(frame.NeedButton,0,0.44,0.87)
rollLinks[1]='item:102'; fire('START_LOOT_ROLL',1); tick()
assert(not frame.NeedButton.EverfrostGearGlow:IsShown() and frame.GreedButton.EverfrostGearGlow:IsShown())
rollLinks[1]='item:101'; rollEligibility[1]={false,true}; fire('START_LOOT_ROLL',1); tick()
assert(not frame.NeedButton.EverfrostGearGlow:IsShown() and not frame.GreedButton.EverfrostGearGlow:IsShown())
rollEligibility[1]={true,true}; rollLinks[1]='item:999'; fire('START_LOOT_ROLL',1); tick()
assert(G.rolls[1].result.kind=='unknown' and not frame.GreedButton.EverfrostGearGlow:IsShown())
fixture('item:999',{ITEM_MOD_STRENGTH_SHORT=12}); fire('GET_ITEM_INFO_RECEIVED',999); tick()
assert(frame.NeedButton.EverfrostGearGlow:IsShown())
-- Combat events do not read item APIs or modify protected roll actions.
local before=metadataCalls; combat=true; fire('PLAYER_REGEN_DISABLED'); fire('BAG_UPDATE',0); tick()
assert(G.pending and metadataCalls==before and not bag.EverfrostGearGlow:IsShown() and not arrow:IsShown())
for _,edge in ipairs(bag.EverfrostGearEdges) do assert(not edge:IsShown()) end
GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip); assert(#GameTooltip.lines==0)
assert(not frame.NeedButton.EverfrostGearGlow:IsShown())
combat=false; fire('PLAYER_REGEN_ENABLED'); tick(); assert(frame.NeedButton.EverfrostGearGlow:IsShown())
fire('CANCEL_LOOT_ROLL',1); tick()
assert(G.rolls[1]==nil and not frame.NeedButton.EverfrostGearGlow:IsShown())
-- Hiding the whole UI is not the end of a roll: its highlight returns with the frame.
rollLinks[2]='item:101'; frame.rollID=2; fire('START_LOOT_ROLL',2); tick()
assert(G.rolls[2] and frame.NeedButton.EverfrostGearGlow:IsShown())
frame.shown=false; frame.hooks.OnHide(frame); assert(not frame.NeedButton.EverfrostGearGlow:IsShown())
frame.shown=true; frame.hooks.OnShow(frame); tick()
assert(G.rolls[2] and frame.NeedButton.EverfrostGearGlow:IsShown())
GameTooltip:ClearLines(); frame.NeedButton.hooks.OnEnter(frame.NeedButton)
assert(table.concat(GameTooltip.lines,'|'):find('UPGRADE / Need',1,true))
fire('CANCEL_LOOT_ROLL',2); tick(); assert(G.rolls[2]==nil and not frame.NeedButton.EverfrostGearGlow:IsShown())
-- Forever nests its roll buttons inside LootButtonContainer.
local nested=widget(); local widgetIndex=getmetatable(nested).__index
setmetatable(nested,{__index=function(t,k) if k=='NeedButton' or k=='GreedButton' then return nil end; return widgetIndex(t,k) end})
nested.LootButtonContainer=widget(); nested.LootButtonContainer.NeedButton=widget(); nested.LootButtonContainer.GreedButton=widget()
nested.rollID=3; rollLinks[3]='item:101'; G.TrackRoll(nested); fire('START_LOOT_ROLL',3); tick()
assert(nested.LootButtonContainer.NeedButton.EverfrostGearGlow:IsShown() and nested.LootButtonContainer.NeedButton.hooks.OnEnter)
nested.shown=false; nested.hooks.OnHide(nested); assert(not nested.LootButtonContainer.NeedButton.EverfrostGearGlow:IsShown())
fire('CANCEL_LOOT_ROLL',3); tick()
-- Forever calls Initialize(containerFrame, bag, slot); the older form has no container.
local pooled=widget(); hooks.Initialize(pooled,widget(),0,1)
assert(pooled.EverfrostGearGlow and pooled.EverfrostGearGlow:IsShown())
local legacyButton=widget(); hooks.Initialize(legacyButton,0,1); assert(legacyButton.EverfrostGearGlow:IsShown())
-- A reused button keeps one set of hooks, even after showing a bank bag.
hooks.Initialize(pooled,widget(),6,1); assert(not pooled.EverfrostGearGlow:IsShown())
hooks.Initialize(pooled,widget(),0,1); assert(pooled.EverfrostGearGlow:IsShown() and pooled.hookCounts.OnEnter==1 and pooled.hookCounts.OnShow==1)
-- Bag changes outside combat keep the pulse running and reuse cached items.
fire('BAG_UPDATE',0); tick()
local pulsePlays=pooled.EverfrostGearPulses[1].plays; local reads=metadataCalls
fire('BAG_UPDATE',0); assert(pooled.EverfrostGearPulses[1]:IsPlaying()); tick()
assert(pooled.EverfrostGearGlow:IsShown() and pooled.EverfrostGearPulses[1].plays==pulsePlays and metadataCalls==reads)
-- A walk of every bag button happens when needed, not on every bag change.
local walks=0; ContainerFrame1={EnumerateValidItems=function() walks=walks+1; return function() end end}
fire('ADDON_LOADED','x'); tick(); assert(walks==1)
fire('BAG_UPDATE',0); tick(); assert(walks==1)
ContainerFrame1=nil
-- Plain Unique-Equipped items report category -1 and limit copies of themselves.
fixture('item:300',{ITEM_MOD_STRENGTH_SHORT=9}); itemInfo['item:300'][9]='INVTYPE_TRINKET'
fixture('item:301',{ITEM_MOD_STRENGTH_SHORT=2}); itemInfo['item:301'][9]='INVTYPE_TRINKET'
local plainUnique=C_Item.GetItemUniqueness
C_Item.GetItemUniqueness=function(link) if link=='item:300' then return -1,1 end; return 0,0 end
local duplicate=G.ReadItem('item:300'); assert(duplicate.unique==-300 and duplicate.limit==1)
local twoTrinkets={}; for i=1,19 do twoTrinkets[i]=false end
twoTrinkets[13]=duplicate; twoTrinkets[14]=G.ReadItem('item:301')
local dupeResult=G.Compare(duplicate,twoTrinkets,G.context)
assert(dupeResult.kind=='greed' and dupeResult.reason:find('Not a valid',1,true))
twoTrinkets[13]=false; assert(G.Compare(duplicate,twoTrinkets,G.context).kind=='need')
C_Item.GetItemUniqueness=plainUnique
-- A plain armor upgrade explains itself without a meaningless 0.0 vs 0.0 score.
GameTooltip:ClearLines()
G.Tooltip(GameTooltip,{kind='need',reason='More armour, no useful stats lost (+32 Armour)',armorOnly=true,score=0,previous=0,delta=0})
local armorLines=table.concat(GameTooltip.lines,'|')
assert(armorLines:find('Everfrost: UPGRADE',1,true) and armorLines:find('+32 Armour',1,true) and not armorLines:find('Estimated score',1,true))
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
-- An effect the client already reports is not counted twice.
fixture('item:302',{ITEM_MOD_SPELL_POWER_SHORT=12})
tooltipLines['item:302']={{leftText='Equip: Increases damage and healing done by magical spells and effects by up to 12.'}}
assert(G.ReadItem('item:302').stats.spell==12 and not G.ReadItem('item:302').fromTooltip)
-- Secret or missing tooltip text changes nothing.
fixture('item:303',{ITEM_MOD_INTELLECT_SHORT=1}); tooltipLines['item:303']={{leftText=secret},{}}
assert(G.ReadItem('item:303').stats.spell==0 and G.ReadItem('item:303').stats.intellect==1)
C_TooltipInfo=nil; tooltipLines=nil; G.items={}
print('Equip effects from tooltips: spell, healing, school, attack power and mana regeneration; no double counting; secrets ignored: passed')
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
assert(bag.EverfrostGearGlow:IsShown() and offBag.EverfrostGearGlow:IsShown())
assert(G.bags[0][1].result.companion=='item:202' and G.bags[1][1].result.companion=='item:201')
GameTooltip:ClearLines(); bag.hooks.OnEnter(bag)
assert(table.concat(GameTooltip.lines,'|'):find('Pair with: Item',1,true))
assert(table.concat(GameTooltip.lines,'|'):find('UPGRADE (equip both)',1,true))
-- Loot hints use the same carried partners and react to partner removal/loading.
frame.rollID=2; rollLinks[2]='item:201'; fire('START_LOOT_ROLL',2); tick()
assert(frame.NeedButton.EverfrostGearGlow:IsShown() and G.rolls[2].result.companion=='item:202')
GameTooltip:ClearLines(); frame.NeedButton.hooks.OnEnter(frame.NeedButton)
assert(table.concat(GameTooltip.lines,'|'):find('UPGRADE (equip both) / Need',1,true))
extraBagLink=nil; fire('BAG_UPDATE',1); tick()
assert(G.bags[0][1].result.kind=='unknown' and not bag.EverfrostGearGlow:IsShown())
assert(not offBag.EverfrostGearGlow:IsShown() and not frame.NeedButton.EverfrostGearGlow:IsShown())
extraBagLink='item:202'; rawStats['item:202']=nil; G.items={}; fire('BAG_UPDATE',1); tick()
assert(G.bags[0][1].result.kind=='unknown')
rawStats['item:202']={ITEM_MOD_SPELL_POWER_SHORT=10}; fire('ITEM_DATA_LOAD_RESULT',202); tick()
assert(bag.EverfrostGearGlow:IsShown() and offBag.EverfrostGearGlow:IsShown() and frame.NeedButton.EverfrostGearGlow:IsShown())
local pairCalls=metadataCalls; combat=true; fire('PLAYER_REGEN_DISABLED'); tick()
assert(metadataCalls==pairCalls and not bag.EverfrostGearGlow:IsShown() and not offBag.EverfrostGearGlow:IsShown())
combat=false; fire('PLAYER_REGEN_ENABLED'); tick(); assert(bag.EverfrostGearGlow:IsShown())
-- Starter tooltips explain themselves in plain words, without a score.
G.SetContext('MAGE',2,9,'damage',{}); tick()
assert(G.bags[0][1].result.delta and bag.EverfrostGearGlow:IsShown())
GameTooltip:ClearLines(); bag.hooks.OnEnter(bag)
local starterLines=table.concat(GameTooltip.lines,'|')
assert(starterLines:find('Starter priority: Intellect',1,true) and not starterLines:find('Estimated score',1,true))
assert(starterLines:find('Simple estimate',1,true) and not starterLines:find('|Priority:',1,true))
G.SetContext('MAGE',0,30,'damage',{}); tick()
assert(G.bags[0][1].result.kind=='unknown' and not bag.EverfrostGearGlow:IsShown())
-- Permanent "not scored" results must not trigger a full rescan on item-data events.
local quiet=metadataCalls
fire('GET_ITEM_INFO_RECEIVED',1); fire('ITEM_DATA_LOAD_RESULT',1); tick()
assert(metadataCalls==quiet and not G.pending)
EverfrostDB.gear=false; G.Refresh(); assert(not bag.EverfrostGearGlow:IsShown())
-- Disabled highlights skip item reads entirely, then resume when re-enabled.
local off=metadataCalls; G.Refresh(); assert(metadataCalls==off and next(G.bags)==nil)
assert(G.Evaluate('item:201').reason=='Gear highlights are disabled')
EverfrostDB.gear=true; G.SetContext('MAGE',2,30,'damage',{}); tick()
assert(next(G.bags)~=nil and bag.EverfrostGearGlow:IsShown())
-- Quest rewards: mark the best upgrade among the choices.
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
assert(r2.EverfrostGearGlow:IsShown() and r2.EverfrostGearArrow:IsShown() and not r1.EverfrostGearGlow and not r3.EverfrostGearGlow)
GameTooltip.owner=r2; GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
local questLines=table.concat(GameTooltip.lines,'|')
assert(questLines:find('UPGRADE',1,true) and questLines:find('Best reward choice for you.',1,true) and questLines:find('Better because it has more Strength',1,true))
GameTooltip.owner=r1; GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
assert(table.concat(GameTooltip.lines,'|'):find('UPGRADE',1,true) and not table.concat(GameTooltip.lines,'|'):find('Best reward',1,true))
-- With no upgrade on offer, the best sell value gets a gold mark and no arrow.
inventory[5]='item:401'; questLinks={'item:402','item:403'}; fire('BAG_UPDATE',0); tick()
assert(r2.EverfrostGearGlow:IsShown() and not r2.EverfrostGearArrow:IsShown())
assert(r2.EverfrostGearGlow.vertex[1]==1 and r2.EverfrostGearGlow.vertex[2]==0.82)
assert(G.Paint and not (r1.EverfrostGearGlow and r1.EverfrostGearGlow:IsShown()))
GameTooltip.owner=r2; GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
assert(table.concat(GameTooltip.lines,'|'):find('sells for the most',1,true))
-- Nothing is marked until every choice has loaded, or for a single forced reward.
questLinks={'item:402','item:404'}; fire('BAG_UPDATE',0); tick()
assert(not r2.EverfrostGearGlow:IsShown())
questFixture('item:404',{ITEM_MOD_STRENGTH_SHORT=1},300); fire('GET_ITEM_INFO_RECEIVED',404); tick()
assert(r2.EverfrostGearGlow:IsShown())
r2.shown=false; fire('BAG_UPDATE',0); tick(); assert(not r2.EverfrostGearGlow:IsShown() and not (r1.EverfrostGearGlow and r1.EverfrostGearGlow:IsShown())); r2.shown=true
-- The quest log reads its own links, and currency choices are skipped.
QuestInfoFrame={questLog=true,rewardsFrame=rewardFrame}
inventory[5]='item:100'
function GetQuestLogItemLink(kind,id) return kind=='choice' and ({'item:400','item:401'})[id] or nil end
questLinks={}; fire('BAG_UPDATE',0); tick(); assert(r2.EverfrostGearArrow:IsShown())
r2.objectType='currency'; fire('BAG_UPDATE',0); tick(); assert(not r2.EverfrostGearGlow:IsShown()); r2.objectType='item'
-- Combat and turning gear hints off both clear the marks.
fire('BAG_UPDATE',0); tick(); assert(r2.EverfrostGearGlow:IsShown())
combat=true; fire('PLAYER_REGEN_DISABLED'); assert(not r2.EverfrostGearGlow:IsShown()); tick(); combat=false; fire('PLAYER_REGEN_ENABLED'); tick()
assert(r2.EverfrostGearGlow:IsShown())
EverfrostDB.gear=false; fire('BAG_UPDATE',0); tick(); assert(not r2.EverfrostGearGlow:IsShown()); EverfrostDB.gear=true; fire('BAG_UPDATE',0); tick()
rewardFrame.shown=false; fire('BAG_UPDATE',0); tick(); assert(not r2.EverfrostGearGlow:IsShown()); rewardFrame.shown=true
QuestInfoFrame=nil; QuestInfoRewardsFrame=nil
-- Merchants: upgrades you can afford glow; the rest explain themselves in the tooltip.
MerchantFrame=widget(); MerchantFrame.selectedTab=1; MERCHANT_ITEMS_PER_PAGE=3
MerchantItem1ItemButton=widget(); MerchantItem1ItemButton.hasItem=true; MerchantItem1ItemButton.id=11
MerchantItem2ItemButton=widget(); MerchantItem2ItemButton.hasItem=true; MerchantItem2ItemButton.id=12
MerchantItem3ItemButton=widget(); MerchantItem3ItemButton.hasItem=nil; MerchantItem3ItemButton.id=13
local shopLinks={[11]='item:400',[12]='item:401',[13]='item:402'}; local affordable={[11]=true,[12]=false}
function GetMerchantItemLink(index) return shopLinks[index] end
function CanAffordMerchantItem(index) return affordable[index] end
hooks.MerchantFrame_Update(); tick()
assert(MerchantItem1ItemButton.EverfrostGearGlow:IsShown() and MerchantItem1ItemButton.EverfrostGearArrow:IsShown())
assert(not MerchantItem2ItemButton.EverfrostGearGlow and not MerchantItem3ItemButton.EverfrostGearGlow)
GameTooltip.owner=MerchantItem2ItemButton; GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
assert(table.concat(GameTooltip.lines,'|'):find("You can't afford this yet.",1,true))
affordable[12]=true; hooks.MerchantFrame_Update(); tick(); assert(MerchantItem2ItemButton.EverfrostGearGlow:IsShown())
MerchantFrame.selectedTab=2; hooks.MerchantFrame_Update(); tick(); assert(not MerchantItem1ItemButton.EverfrostGearGlow:IsShown())
MerchantFrame.selectedTab=1; MerchantFrame.shown=false; hooks.MerchantFrame_Update(); tick(); assert(not MerchantItem1ItemButton.EverfrostGearGlow:IsShown())
MerchantFrame=nil
-- Empty slots count only what the game confirms, and clear while results are pending.
inventory={[5]='item:100',[7]='item:100'}; fire('BAG_UPDATE',0); tick()
local noWeapon,emptyArmor=G.EmptySlots(); assert(noWeapon==true and emptyArmor==7)
inventory[16]='item:401'; fire('BAG_UPDATE',0); tick()
noWeapon,emptyArmor=G.EmptySlots(); assert(noWeapon==false and emptyArmor==7)
G.pending=true; noWeapon,emptyArmor=G.EmptySlots(); assert(noWeapon==false and emptyArmor==0); G.pending=false
local refreshed=0; G.OnRefreshed=function() refreshed=refreshed+1 end; fire('BAG_UPDATE',0); tick(); assert(refreshed==1); G.OnRefreshed=nil
print('Quest reward marks, sell-value fallback, merchant upgrades, affordability and empty slots: passed')
print('Gear UI: bag reuse, loot eligibility, async item data, secret rejection, combat deferral, cancellation and legacy APIs passed')
`);
console.log('Gear checks passed. Forever client visuals and API behavior still require in-game testing.');
