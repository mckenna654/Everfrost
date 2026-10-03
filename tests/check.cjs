const fs = require('fs');
const path = require('path');
const parser = require('luaparse');
const {lua, lauxlib, lualib, to_luastring, to_jsstring} = require('fengari');
const root = path.resolve(__dirname, '../addon/Everfrost');
const sources = {};
for (const name of ['Profiles.lua','Core.lua','Main.lua']) {
 sources[name]=fs.readFileSync(path.join(root,name),'utf8');
 parser.parse(sources[name],{luaVersion:'5.1'});
 console.log(name+': Lua 5.1 syntax passed');
}
const L=lauxlib.luaL_newstate(); lualib.luaL_openlibs(L);
function run(s) { if(lauxlib.luaL_dostring(L,to_luastring(s))!==lua.LUA_OK) throw Error(to_jsstring(lua.lua_tostring(L,-1))); }
function load(name) { run(`local function loadAddon(...)\n${sources[name]}\nend\nloadAddon('Everfrost',NS)`); }
run('NS={}'); load('Profiles.lua'); load('Core.lua');
run(`
function issecretvalue(v) return v=='SECRET' end
combat=false
function InCombatLockdown() return combat end
local calls=NS.Call(function() return 1,nil,3,nil,nil,nil,7 end)
assert(calls[1]==1 and calls[3]==3 and calls[7]==7)
assert(NS.Call(function() error('unavailable') end)==nil)
local pts={0,0,11}
C_SpecializationInfo={GetSpecializationInfo=function(i) return i,'Tree',nil,nil,nil,nil,pts[i] end}
assert(NS.DetectSpec('PALADIN')==3)
pts={5,5,0}; local i,s=NS.DetectSpec('PALADIN'); assert(i==0 and s=='Hybrid')
pts={0,0,0}; i,s=NS.DetectSpec('PALADIN'); assert(i==0 and s=='Unspent')
C_SpecializationInfo=nil
GetTalentTabInfo=function(i) return 'Tree',nil,({0,6,1})[i] end
assert(NS.DetectSpec('MAGE')==2)
GetTalentTabInfo=function(i) return i,'Tree',nil,nil,({7,0,0})[i] end
assert(NS.DetectSpec('WARRIOR')==1)
GetTalentTabInfo=nil
C_SpecializationInfo={GetSpecialization=function() return 3 end}
assert(NS.DetectSpec('DRUID')==3)
C_SpecializationInfo=nil
assert(select(2,NS.DetectSpec('ROGUE'))=='Spec unavailable')
assert(NS.DetectSpec('DEATHKNIGHT')==0)
local count=0
for class,profiles in pairs(NS.profiles) do
 count=count+1
 local known={}
 for _,p in pairs(profiles) do
  for _,list in ipairs({p.steps,p.healing or {},p.bear or {},p.caster or {},p.melee or {}}) do
   for _,entry in ipairs(list) do known[entry.name]={name=entry.name,id=1,level=1} end
  end
 end
 for spec=0,3 do
  assert(profiles[spec])
  for _,level in ipairs({1,5,6,10,19,20,21,24,25,29,30,31}) do
   for _,mode in ipairs({'single','aoe'}) do
    for _,role in ipairs({'damage','heal','bear','melee','ranged'}) do
     local rows=NS.BuildRows(class,spec,level,known,mode,role)
     assert(#rows<=12)
     for _,row in ipairs(rows) do assert(known[row.key] and row.hint) end
     if level==31 then assert(#rows==0) end
     assert(#NS.BuildRows(class,spec,level,{},mode,role)==0)
    end
   end
  end
 end
end
assert(count==9)
function keys(rows) local t={}; for _,r in ipairs(rows) do t[#t+1]=r.key end; return table.concat(t,',') end
local p={['Holy Strike']={level=6},['Seal of Command']={level=20},['Consecration']={level=20},['Judgement']={level=4}}
assert(keys(NS.BuildRows('PALADIN',3,5,p,'single'))=='Judgement')
assert(keys(NS.BuildRows('PALADIN',3,6,p,'single'))=='Holy Strike,Judgement')
assert(not keys(NS.BuildRows('PALADIN',3,20,p,'single')):find('Consecration'))
assert(keys(NS.BuildRows('PALADIN',3,20,p,'aoe')):find('Consecration'))
local d={['Wrath']={},['Bear Form']={},['Maul']={},['Cat Form']={},['Claw']={}}
assert(keys(NS.BuildRows('DRUID',2,20,d,'single','damage'))=='Cat Form,Claw')
d['Cat Form']=nil
assert(keys(NS.BuildRows('DRUID',2,10,d,'single','damage'))=='Bear Form,Maul')
d['Bear Form']=nil
assert(keys(NS.BuildRows('DRUID',2,5,d,'single','damage'))=='Wrath')
assert(#NS.BuildRows('UNKNOWN',0,10,{},'single')==0)
print('27 specs, nine baselines, level boundaries, role/mode filters and talent API variants: passed')
Enum={SpellBookSpellBank={Player=0}}
book={
 {spellID=2,name='Judgement',subName='Rank 2',level=18},
 {spellID=1,name='Judgement',subName='Rank 1',level=4},
 {spellID=3,name='Holy Strike',future=true},
 {spellID=4,name='Consecration',isOffSpec=true},
 {spellID=5,name='Seal of Command',isPassive=true},
 {spellID='SECRET',name='Seal of Righteousness'},
}
C_SpellBook={
 GetNumSpellBookSkillLines=function() assert(not combat); return 1 end,
 GetSpellBookSkillLineInfo=function() return {itemIndexOffset=0,numSpellBookItems=#book} end,
 GetSpellBookItemInfo=function(slot) return book[slot] end,
 GetSpellBookItemLevelLearned=function(slot) return book[slot].level end,
 IsSpellKnown=function(id) for _,s in ipairs(book) do if s.spellID==id then return not s.future end end end,
}
C_Spell={GetSpellInfo=function() return nil end}
local known=NS.ScanSpells('PALADIN'); assert(known.Judgement.id==2)
local n=0; for _ in pairs(known) do n=n+1 end; assert(n==1)
book[1].level=4; known=NS.ScanSpells('PALADIN'); assert(known.Judgement.id==2)
combat=true; assert(NS.ScanSpells('PALADIN')==nil); combat=false
print('Learned-only scan, future/off-spec/passive/secret exclusion, rank selection and combat deferral: passed')
frames={}; currentLevel=5; currentClass='PALADIN'
local methods={}
function methods:SetScript(e,cb) self.scripts[e]=cb end
function methods:RegisterEvent(e) self.events[e]=true end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown~=false end
function methods:SetShown(v) self.shown=v end
function methods:SetText(v) self.text=v end
function methods:SetWidth(v) self.width=v end
function methods:SetHeight(v) self.height=v end
function methods:SetSize(w,h) self.width=w; self.height=h end
function methods:GetPoint() return 'CENTER',UIParent,'CENTER',100,40 end
function methods:SetCooldownFromDurationObject(v) assert(v==duration); self.duration=v end
function methods:Clear() self.duration=nil end
local function object() return setmetatable({scripts={},events={}},{__index=function(t,k) return methods[k] or function() end end}) end
function methods:CreateFontString() return object() end
function methods:CreateTexture() return object() end
function CreateFrame(kind,name,parent,template) local f=object(); frames[#frames+1]=f; if name then _G[name]=f end; return f end
UIParent=object(); GameTooltip=object(); STANDARD_TEXT_FONT='font'; SlashCmdList={}
function UnitLevel() return currentLevel end
function UnitClass() return currentClass,currentClass end
function fire(e,value) for _,f in ipairs(frames) do if f.events[e] then f.scripts.OnEvent(f,e,value) end end end
function visibleSpells() local n=0; for _,f in ipairs(frames) do if rawget(f,'spellID') and f:IsShown() then n=n+1 end end; return n end
duration={}; C_Spell.GetSpellCooldownDuration=function() return duration end
EverfrostDB={scale=1.2,locked=true,point='CENTER',relativePoint='CENTER',x=100,y=40}
GetTalentTabInfo=function(i) return 'Tree',nil,({0,0,2})[i] end
`);
load('Main.lua');
run(`
fire('PLAYER_LOGIN'); local f=EverfrostFrame
assert(f.title.text=='Retribution  PALADIN' and f.meta.text:find('5'))
assert(EverfrostDB.scale==1.2 and EverfrostDB.x==100)
assert(visibleSpells()==1 and f.width==310)
local cmd=SlashCmdList.EVERFROST
cmd('hide'); assert(not f:IsShown()); cmd('show'); assert(f:IsShown())
cmd('scale 1.4'); cmd('scale 99'); assert(EverfrostDB.scale==1.4)
combat=true; book[3].future=false; fire('PLAYER_LEVEL_UP',6); fire('SPELLS_CHANGED'); fire('SPELL_UPDATE_COOLDOWN')
assert(visibleSpells()==1 and f.meta.text:find('6'))
combat=false; fire('PLAYER_REGEN_ENABLED'); assert(visibleSpells()==2)
cmd('spec 1'); assert(f.title.text:find('Holy'))
cmd('spec auto'); assert(f.title.text:find('Retribution'))
cmd('aoe'); assert(EverfrostDB.aoe)
C_Spell.GetSpellCooldownDuration=nil; fire('SPELL_UPDATE_COOLDOWN')
cmd('reset'); assert(EverfrostDB.scale==1)
fire('PLAYER_LEVEL_UP',30); assert(visibleSpells()>0); fire('PLAYER_LEVEL_UP',31); assert(f.empty.text=='Level 1-30 guide')
for class in pairs(NS.profiles) do
 currentClass=class; currentLevel=10; EverfrostDB={}; fire('PLAYER_LOGIN')
 assert(EverfrostFrame.title.text:find(class))
end
currentClass='DRUID'; currentLevel=10; GetTalentTabInfo=function(i) return 'Tree',nil,({0,1,0})[i] end
book={{spellID=5487,name='Bear Form'},{spellID=6807,name='Maul'}}
EverfrostDB={}; fire('PLAYER_LOGIN')
assert(EverfrostFrame.role.label.text=='BEAR')
book={}; fire('SPELLS_CHANGED'); assert(EverfrostFrame.role.label.text=='CASTER')
print('Mock UI: all classes, migration, controls, talent override, leveling, combat refresh, cooldown fallback and feral labels: passed')
`);
console.log('All checks passed. Actual Forever client and visual rendering still require in-game verification.');

run(`
local function learned(...) local t={}; for _,name in ipairs({...}) do t[name]={id=1,level=1} end; return t end
local function has(class,spec,level,spells,key,mode,role)
 for _,row in ipairs(NS.BuildRows(class,spec,level,spells,mode or 'single',role or 'damage')) do if row.key==key then return true end end
 return false
end
assert(NS.maxLevel==30)
local spells=learned('Slam','Spearing Strike','Holy Shock','Stormstrike','Swiftmend','Insect Swarm','Summon Hawk','Hellfire','Conflagrate','Immolate','Hemorrhage','Backstab','Sinister Strike','Rupture','Strider Kick','Raptor Strike','Auto Shot')
assert(not has('WARRIOR',1,29,spells,'Slam')); assert(has('WARRIOR',1,30,spells,'Slam'))
assert(has('PALADIN',1,30,spells,'Holy Shock','single','heal'))
assert(has('PALADIN',1,30,spells,'Holy Shock','single','damage'))
assert(has('SHAMAN',2,30,spells,'Stormstrike'))
assert(has('DRUID',3,30,spells,'Swiftmend','single','heal'))
spells['Insect Swarm'].level=25
assert(not has('DRUID',1,24,spells,'Insect Swarm')); assert(has('DRUID',1,25,spells,'Insect Swarm'))
assert(has('HUNTER',1,30,spells,'Summon Hawk')); assert(not has('HUNTER',2,30,spells,'Summon Hawk'))
assert(has('HUNTER',3,29,spells,'Auto Shot','single','melee'))
assert(has('HUNTER',3,30,spells,'Raptor Strike','single','melee'))
assert(not has('HUNTER',3,30,spells,'Auto Shot','single','melee'))
assert(has('HUNTER',3,30,spells,'Auto Shot','single','ranged'))
assert(has('ROGUE',3,30,spells,'Hemorrhage'))
assert(not has('ROGUE',3,30,spells,'Backstab'))
assert(not has('ROGUE',3,30,spells,'Sinister Strike'))
assert(has('ROGUE',2,30,spells,'Backstab'))
assert(not has('ROGUE',3,29,spells,'Rupture')); assert(has('ROGUE',3,30,spells,'Rupture'))
for spec=1,3 do
 assert(not has('WARLOCK',spec,29,spells,'Hellfire','aoe'))
 assert(has('WARLOCK',spec,30,spells,'Hellfire','aoe'))
 assert(not has('WARLOCK',spec,30,spells,'Hellfire','single'))
end
assert(has('WARLOCK',3,30,spells,'Conflagrate'))
spells.Immolate=nil; assert(not has('WARLOCK',3,30,spells,'Conflagrate'))
currentClass='HUNTER'; currentLevel=29; GetTalentTabInfo=function(i) return 'Tree',nil,({0,0,21})[i] end
book={{spellID=1,name='Strider Kick'},{spellID=2,name='Raptor Strike'},{spellID=3,name='Auto Shot'}}
EverfrostDB={}; fire('PLAYER_LOGIN')
assert(EverfrostFrame.role.label.text=='RANGED')
fire('PLAYER_LEVEL_UP',30); assert(EverfrostFrame.role.label.text=='MELEE')
SlashCmdList.EVERFROST('ranged'); assert(EverfrostFrame.role.label.text=='RANGED')
SlashCmdList.EVERFROST('melee'); assert(EverfrostFrame.role.label.text=='MELEE')
book[1].future=true; fire('SPELLS_CHANGED'); assert(EverfrostFrame.role.label.text=='RANGED')
print('Level 21-30 additions, rank level gates, spec isolation, talent removal and Survival transition: passed')
`);


