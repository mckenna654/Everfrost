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
for level=1,9 do
 young.level=level
 local unscored=G.Compare(item(2,nil,{ITEM_MOD_STRENGTH_SHORT=8}),equipment,young)
 assert(unscored.kind=='unknown' and unscored.reason==NS.gearLevelNote)
end
young.level=10
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
equipment=empty(); equipment[5]=item(10,nil,{ITEM_MOD_SPIRIT_SHORT=10})
local power=item(11,nil,{ITEM_MOD_SPELL_POWER_SHORT=10})
assert(G.Compare(power,equipment,ctx('MAGE',1)).kind=='greed')
assert(G.Compare(power,equipment,ctx('MAGE',2)).kind=='need')
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
-- Melee specs without an Attack Power rank keep the existing half-Strength credit.
local combatProfile=NS.gearProfiles.ROGUE[2]
assert(G.Score(apItem,ctx('ROGUE',2),combatProfile)==10*combatProfile.weights.strength/2)
-- Only results that depend on missing item data wait for item-data events.
assert(G.Compare(nil,equipment,c).waiting==true)
local unscoredYoung=ctx('WARRIOR',1); unscoredYoung.level=9
assert(not G.Compare(nil,equipment,unscoredYoung).waiting)
assert(not G.Compare(item(2,nil,{ITEM_MOD_STRENGTH_SHORT=8}),equipment,ctx('WARRIOR',0)).waiting)
print('Gear profiles: 27 specs; stat reversals, aliases, eligibility, paired slots, unique limits and weapon layouts passed')
`);
run(`
frames={}; hooks={}; metadataCalls=0; inventory={}; bagLinks={}; itemInfo={}; rawStats={}; rollLinks={}; rollEligibility={}
local methods={}
function methods:SetScript(name,fn) self.scripts[name]=fn end
function methods:HookScript(name,fn) self.hooks[name]=fn end
function methods:RegisterEvent(name) self.events[name]=true end
function methods:CreateTexture() local t=widget(); t.owner=self; return t end
function methods:CreateAnimationGroup() local g=widget(); g.owner=self; return g end
function methods:CreateAnimation() local a=widget(); self.animation=a; return a end
function methods:SetFromAlpha(value) self.from=value end
function methods:SetToAlpha(value) self.to=value end
function methods:SetDuration(value) self.duration=value end
function methods:SetLooping(value) self.looping=value end
function methods:SetVertexColor(r,g,b,a) self.vertex={r,g,b,a} end
function methods:IsPlaying() return self.playing==true end
function methods:Play() self.playing=true; self.plays=(self.plays or 0)+1 end
function methods:Stop() self.playing=false end
function methods:IsShown() return self.shown~=false end
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
for _,edge in ipairs(bag.EverfrostGearEdges) do assert(edge:IsShown()) end
local function assertColor(button,r,g,b)
 for _,layer in ipairs({button.EverfrostGearGlow,table.unpack(button.EverfrostGearEdges)}) do
  assert(layer.vertex[1]==r and layer.vertex[2]==g and layer.vertex[3]==b)
 end
end
assertColor(bag,0.12,1,0)
assert(#bag.EverfrostGearPulses==5)
for _,pulse in ipairs(bag.EverfrostGearPulses) do
 assert(pulse:IsPlaying() and pulse.looping=='BOUNCE')
 assert(pulse.animation.from==0.18 and pulse.animation.to==1 and pulse.animation.duration==0.7)
end
local plays=bag.EverfrostGearPulses[1].plays; local calls=qualityCalls
G.PaintBag(bag); assert(bag.EverfrostGearPulses[1].plays==plays and qualityCalls==calls)
-- Reused buttons pick up new rarity colors, with safe neutral missing-data fallbacks.
itemInfo['item:101'][3]=3; G.Refresh(); assertColor(bag,0,0.44,0.87)
itemInfo['item:101'][3]=4; G.Refresh(); assertColor(bag,0.64,0.21,0.93)
itemInfo['item:101'][3]=secret; G.Refresh(); assertColor(bag,1,1,1)
assert(G.bags[0][1].result.kind=='need')
itemInfo['item:101'][3]=2; C_Item.GetItemQualityColor=function() return secret,1,1 end
G.Refresh(); assertColor(bag,1,1,1)
C_Item.GetItemQualityColor=nil; G.Refresh(); assertColor(bag,1,1,1)
C_Item.GetItemQualityColor=qualityColor; G.Refresh(); assertColor(bag,0.12,1,0)
-- Native tooltip rebuilds keep the label, without duplicate OnEnter additions.
GameTooltip.owner=bag; GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
assert(table.concat(GameTooltip.lines,'|'):find('Everfrost: UPGRADE',1,true))
assert(table.concat(GameTooltip.lines,'|'):find(NS.gearLevelNote,1,true))
local lineCount=#GameTooltip.lines; bag.hooks.OnEnter(bag); assert(#GameTooltip.lines==lineCount)
GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
assert(#GameTooltip.lines==lineCount and tooltipRegistrations==1)
G.TrackBag(bag,0,2); assert(not bag.EverfrostGearGlow:IsShown())
for _,edge in ipairs(bag.EverfrostGearEdges) do assert(not edge:IsShown()) end
for _,pulse in ipairs(bag.EverfrostGearPulses) do assert(not pulse:IsPlaying()) end
GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip)
assert(table.concat(GameTooltip.lines,'|'):find('Everfrost: No upgrade',1,true))
G.TrackBag(bag,0,1); assert(bag.EverfrostGearGlow:IsShown())
G.TrackBag(bag,-1,1); assert(not bag.EverfrostGearGlow:IsShown())
G.TrackBag(bag,0,1); bag.hooks.OnEnter(bag); assert(#GameTooltip.lines>0)
fire('START_LOOT_ROLL',1); tick()
local frame=GroupLootFrame1
assert(frame.NeedButton.EverfrostGearGlow:IsShown())
assertColor(frame.NeedButton,0.12,1,0)
local rollPlays=frame.NeedButton.EverfrostGearPulses[1].plays
G.PaintRoll(frame); assert(frame.NeedButton.EverfrostGearPulses[1].plays==rollPlays)
itemInfo['item:101'][3]=3; fire('START_LOOT_ROLL',1); tick()
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
assert(G.pending and metadataCalls==before and not bag.EverfrostGearGlow:IsShown())
for _,edge in ipairs(bag.EverfrostGearEdges) do assert(not edge:IsShown()) end
GameTooltip:ClearLines(); itemTooltipPostCall(GameTooltip); assert(#GameTooltip.lines==0)
assert(not frame.NeedButton.EverfrostGearGlow:IsShown())
combat=false; fire('PLAYER_REGEN_ENABLED'); tick(); assert(frame.NeedButton.EverfrostGearGlow:IsShown())
fire('CANCEL_LOOT_ROLL',1); tick()
assert(G.rolls[1]==nil and not frame.NeedButton.EverfrostGearGlow:IsShown())
-- Missing and secret metadata defer rather than treating an occupied slot as empty.
itemInfo['item:100']=nil; G.Refresh(); assert(G.bags[0][1].result.kind=='unknown')
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
extraBagLink='item:202'; rawStats['item:202']=nil; fire('BAG_UPDATE',1); tick()
assert(G.bags[0][1].result.kind=='unknown')
rawStats['item:202']={ITEM_MOD_SPELL_POWER_SHORT=10}; fire('ITEM_DATA_LOAD_RESULT',202); tick()
assert(bag.EverfrostGearGlow:IsShown() and offBag.EverfrostGearGlow:IsShown() and frame.NeedButton.EverfrostGearGlow:IsShown())
local pairCalls=metadataCalls; combat=true; fire('PLAYER_REGEN_DISABLED'); tick()
assert(metadataCalls==pairCalls and not bag.EverfrostGearGlow:IsShown() and not offBag.EverfrostGearGlow:IsShown())
combat=false; fire('PLAYER_REGEN_ENABLED'); tick(); assert(bag.EverfrostGearGlow:IsShown())
G.SetContext('MAGE',2,9,'damage',{}); tick()
assert(G.bags[0][1].result.reason==NS.gearLevelNote and not bag.EverfrostGearGlow:IsShown())
GameTooltip:ClearLines(); bag.hooks.OnEnter(bag)
local notes=0
for _,line in ipairs(GameTooltip.lines) do
 if line==NS.gearLevelNote then notes=notes+1 end
 assert(not line:find('Priority:',1,true))
end
assert(notes==1)
-- Permanent "not scored" results must not trigger a full rescan on item-data events.
local quiet=metadataCalls
fire('GET_ITEM_INFO_RECEIVED',1); fire('ITEM_DATA_LOAD_RESULT',1); tick()
assert(metadataCalls==quiet and not G.pending)
EverfrostDB.gear=false; G.Refresh(); assert(not bag.EverfrostGearGlow:IsShown())
-- Disabled highlights skip item reads entirely, then resume when re-enabled.
local off=metadataCalls; G.Refresh(); assert(metadataCalls==off and next(G.bags)==nil)
assert(G.Evaluate('item:201').reason=='Gear highlights are disabled')
EverfrostDB.gear=true; G.SetContext('MAGE',2,30,'damage',{}); tick()
assert(metadataCalls>off and bag.EverfrostGearGlow:IsShown())
print('Gear UI: bag reuse, loot eligibility, async item data, secret rejection, combat deferral, cancellation and legacy APIs passed')
`);
console.log('Gear checks passed. Forever client visuals and API behavior still require in-game testing.');
