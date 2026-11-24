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
-- Arms ranks Strength at 2 points: 50 Strength scores 100.
local arms=ctx('WARRIOR',1)
local worn=empty(); worn[5]=item(1,nil,{[STR]=50})
local function verdict(raw,equipment,context) return G.Compare(item(2,nil,raw),equipment or worn,context or arms) end
local r=verdict({[STR]=60}); check(r.verdict=='clear' and r.kind=='need' and math.abs(r.pct-0.2)<1e-9,'20% is a clear upgrade')
r=verdict({[STR]=55}); check(r.verdict=='clear','exactly 10% is clear')
r=verdict({[STR]=52,[STA]=1}); check(r.verdict=='minor' and r.kind=='need','5% is a minor upgrade')
r=verdict({[STR]=50,[STA]=2}); check(r.verdict=='sidegrade' and r.kind=='greed','2% up is a sidegrade, never a Need')
check(r.why=='About the same as your current item.','a one-sided sidegrade says so')
r=verdict({[STR]=49,[STA]=2}); check(r.verdict=='sidegrade' and r.why=='More Stamina, but less Strength.','a sidegrade names its trade-off')
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
local slightly=item(44,'INVTYPE_2HWEAPON',{[DPS]=10.4},2,5)
check(G.Compare(slightly,loadout,ret).verdict=='downgrade','shield armour outweighs 4% more weapon DPS')
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
check(G.Compare(fast,sword,tank).verdict=='minor','balanced: weapon damage is a minor upgrade')
G.focus='survival'; r=G.Compare(fast,sword,tank)
check(r.verdict=='spec' and r.why=='Your current item has more Stamina.','survival: lost Stamina')
G.focus=nil

-- Feral: Bear ignores weapon damage that Cat wants.
local druid=ctx('DRUID',2)
local paw=empty(); paw[16]=item(60,'INVTYPE_WEAPON',{[DPS]=10},2,4)
check(G.Compare(item(61,'INVTYPE_WEAPON',{[DPS]=20},2,4),paw,druid).verdict=='clear','cat: weapon DPS')
G.focus='balanced'
r=G.Compare(item(61,'INVTYPE_WEAPON',{[DPS]=20},2,4),paw,druid)
check(r.kind=='greed' and r.verdict=='spec' and r.altLabel=='Cat Damage','bear: better for Cat')
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
print('Gear verdicts: '..checks..' checks on tiers, unusable, spell power, weapon DPS, rings/trinkets, focus profiles, shields, two-handers, Feral and rescans passed')
`);
