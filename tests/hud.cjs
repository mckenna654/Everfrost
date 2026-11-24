// Rotation HUD: enemy estimate, mode switching, the rotation engine, input layouts, the four
// HUD layouts and saved-settings migration. Simulated with mock game APIs; nothing here proves
// how the Forever client behaves.
const fs = require('fs');
const path = require('path');
const parser = require('luaparse');
const {lua, lauxlib, lualib, to_luastring, to_jsstring} = require('fengari');
const root = path.resolve(__dirname, '../addon/Everfrost');
const L = lauxlib.luaL_newstate(); lualib.luaL_openlibs(L);
function run(s) { if (lauxlib.luaL_dostring(L, to_luastring(s)) !== lua.LUA_OK) throw Error(to_jsstring(lua.lua_tostring(L, -1))); }
function load(name) {
 const src = fs.readFileSync(path.join(root, name), 'utf8');
 parser.parse(src, {luaVersion: '5.1'});
 run(`local function loadAddon(...)\n${src}\nend\nloadAddon('Everfrost',NS)`);
}
run(`
NS={}
function issecretvalue(v) return v=='SECRET' end
clock=100; function GetTime() return clock end
combat=false; function InCombatLockdown() return combat end
`);
load('Profiles.lua'); load('Core.lua'); load('Combat.lua');

run(`
-- Enemy tracker -----------------------------------------------------------------------------
local E=NS.Enemies
units={}
local function u(name) return units[name] end
function UnitExists(unit) return u(unit)~=nil end
function UnitCanAttack(_,unit) local x=u(unit); if x and x.secret then return 'SECRET' end; return x and not x.friend end
function UnitIsDead(unit) return u(unit) and u(unit).dead or false end
function UnitPlayerControlled(unit) return u(unit) and u(unit).pet or false end
function UnitCreatureType(unit) return u(unit) and u(unit).kind or 'Humanoid' end
function UnitAffectingCombat(unit) return u(unit) and u(unit).fighting or false end
function UnitThreatSituation(_,unit) local x=u(unit); if x and x.threat=='SECRET' then return 'SECRET' end; return x and x.threat end
function UnitIsUnit(a,b) return a==b end
function IsInGroup() return false end
local function enemy(token,extra)
 local x={fighting=true,threat=1}; for k,v in pairs(extra or {}) do x[k]=v end
 units[token]=x; E.PlateAdded(token)
end
E.Clear()
enemy('nameplate1'); assert(E.Scan(100)==1)
enemy('nameplate2'); enemy('nameplate3'); assert(E.Scan(100.25)==3)
-- Friendly, out-of-combat, pets, totems and enemies not on your threat table (solo) don't count.
enemy('nameplate4',{friend=true}); enemy('nameplate5',{fighting=false}); enemy('nameplate6',{pet=true})
enemy('nameplate7',{kind='Totem'}); enemy('nameplate8',{threat=false})
units.nameplate8.threat=nil
assert(E.Scan(100.5)==3)
-- In a group, an enemy fighting your party counts even if it isn't on your own threat table.
IsInGroup=function() return true end; assert(E.Scan(100.6)==4); IsInGroup=function() return false end
-- A death is removed at once, with no grace period.
units.nameplate3.dead=true; assert(E.Scan(101)==2)
E.PlateRemoved('nameplate3'); units.nameplate3=nil; assert(E.Scan(101.1)==2)
-- One that walks out of view is kept until it goes stale (5 s), even when its token is reused.
E.PlateRemoved('nameplate2'); units.nameplate2=nil
enemy('nameplate2',{friend=true})
assert(E.Scan(102)==2)
assert(E.Scan(106.5)==1)
-- No double counting: the target is the same unit as a counted plate.
units.target=units.nameplate1; UnitIsUnit=function(a,b) return (a=='nameplate1' and b=='target') or a==b end
assert(E.Scan(107)==1)
-- Enemy nameplates off: the target alone still counts.
for token in pairs(E.plates) do E.PlateRemoved(token) end
E.Clear(); units={target={fighting=true,threat=1}}
assert(E.Scan(110)==1)
-- Secret readings are unknown, never guessed.
E.Clear(); units={}; for token in pairs(E.plates) do E.plates[token]=nil end
enemy('nameplate1',{secret=true}); enemy('nameplate2',{secret=true})
assert(E.Scan(120)==nil and E.unknown)
-- Readable threat that is secret falls back to "fighting".
E.Clear(); units={}; for token in pairs(E.plates) do E.plates[token]=nil end
enemy('nameplate1',{threat='SECRET'}); assert(E.Scan(130)==1)
E.Clear(); assert(E.count==nil)
print('Enemy estimate: hostile/in-combat filter, pets/totems/friends out, deaths at once, out-of-view grace, token reuse, no double count, target fallback, secrets unknown: passed')

-- Modes -------------------------------------------------------------------------------------
local M=NS.Modes
assert(M.Normal('st')=='single' and M.Normal('clv')=='cleave' and M.Normal('aoe')=='aoe' and M.Normal('bogus')==nil)
local db={thresholds={PALADIN2={cleave=2,aoe=4}}}
local c,a=M.Thresholds(db,'PALADIN2'); assert(c==2 and a==4)
c,a=M.Thresholds(db,'MAGE3'); assert(c==2 and a==3)
c,a=M.Thresholds({thresholds={X={cleave=9,aoe=1}}},'X'); assert(c==5 and a==5)
assert(M.ForCount(1,2,3)=='single' and M.ForCount(2,2,3)=='cleave' and M.ForCount(5,2,3)=='aoe' and M.ForCount(nil,2,3)=='single')
M.Reset()
assert(M.Auto(1,2,3,1.5,0)=='single')
assert(M.Auto(3,2,3,1.5,1)=='aoe')        -- steps up at once
assert(M.Auto(1,2,3,1.5,1.5)=='aoe')      -- a brief dip doesn't flicker
assert(M.Auto(3,2,3,1.5,2)=='aoe')
assert(M.Auto(2,2,3,1.5,3)=='aoe')
assert(M.Auto(2,2,3,1.5,4.6)=='cleave')   -- after 1.5 s at the lower count
assert(M.Auto(nil,2,3,1.5,5)=='cleave')
assert(M.Auto(nil,2,3,1.5,6.6)=='single') -- unknown count settles on single target
print('Rotation modes: names, per-spec thresholds clamped, step up at once, step down after the grace period, unknown is single: passed')

-- Input layouts -----------------------------------------------------------------------------
local I=NS.Input
Enum={InputDeviceInterfaceType={Mkb=0,Gamepad=1}}
C_InputInterfaceStyle={GetCurrentStyle=function() return style end}
style=1; assert(I.Detect()=='pad'); style=0; assert(I.Detect()=='kbm')
style='SECRET'; C_GamePad={IsEnabled=function() return true end}; assert(I.Detect()=='pad')
C_InputInterfaceStyle=nil; C_GamePad=nil; assert(I.Detect()==nil)
I.device='kbm'
assert(I.Offer('pad',0)==false)          -- starts the debounce
assert(I.Offer('kbm',0.2)==false)        -- back to the mouse: cancelled
assert(I.Offer('pad',0.3)==false)
assert(I.Offer('pad',0.6)==false)
assert(I.Offer('pad',1.1)==true and I.device=='pad')
assert(I.Offer('pad',2)==false)
assert(I.Layout('auto')=='pad' and I.Layout('kbm')=='kbm' and I.Layout('custom')=='kbm' and I.Layout('pad')=='pad')
print('Input layouts: game input style, gamepad-mode fallback, debounce against quick switching, forced and custom layouts: passed')

-- Rotation engine ---------------------------------------------------------------------------
local R=NS.Rotation
local function spell(id,name) return {id=id,name=name} end
local known={['Righteous Fury']=spell(25780,'Righteous Fury'),['Seal of Righteousness']=spell(21084,'Seal of Righteousness'),
 Consecration=spell(26573,'Consecration'),Judgement=spell(20271,'Judgement'),['Holy Strike']=spell(9,'Holy Strike'),
 Exorcism=spell(879,'Exorcism'),['Holy Shield']=spell(20925,'Holy Shield'),['Divine Protection']=spell(498,'Divine Protection'),['Hammer of Justice']=spell(853,'Hammer of Justice')}
-- AoE rows: Protection uses Exorcism only on packs (guide of 4 Nov 2026).
local rows=NS.BuildRows('PALADIN',2,30,known,'aoe','damage')
local probe={usable={},cooldown={},buff={}}
function probe.Usable(id) local v=probe.usable[id]; if v==nil then return true end; return v end
function probe.CooldownLeft(id) return probe.cooldown[id] end
function probe.HasBuff(id) return probe.buff[id] end
local util={{name='Hammer of Justice',kind='interrupt',spell=known['Hammer of Justice']},{name='Divine Protection',kind='defensive',major=true,spell=known['Divine Protection']}}
local out=R.Build(rows,util,{probe=probe,count=3})
-- Buffs and seals are never the NOW spell; the guide order stands for the rest.
assert(out.now.key=='Consecration' and out.upcoming[1].key=='Judgement' and out.upcoming[2].key=='Holy Shield' and out.upcoming[3].key=='Exorcism')
assert(out.source=='guide' and #out.utility==2 and #out.reminders==0)
-- A missing buff becomes a reminder only when the game says it's missing.
probe.buff[25780]=false; out=R.Build(rows,util,{probe=probe}); assert(#out.reminders==1 and out.reminders[1].key=='Righteous Fury')
probe.buff[25780]=nil
-- Cooling down or unusable (out of mana, Exorcism on a non-Undead target) moves to the back.
probe.cooldown[26573]=6; probe.usable[879]=false
out=R.Build(rows,util,{probe=probe,count=4})
assert(out.now.key=='Judgement' and out.upcoming[1].key=='Holy Shield' and out.upcoming[2].key=='Holy Strike' and out.upcoming[3].key=='Consecration' and out.upcoming[4].key=='Exorcism')
assert(out.upcoming[4].usable==false)
-- Blizzard's suggestion is NOW, matched to the guide row by ID or by another rank's name.
out=R.Build(rows,util,{probe=probe,assist=9}); assert(out.now.key=='Holy Strike' and out.source=='assist')
for _,row in ipairs(out.upcoming) do assert(row.key~='Holy Strike') end
C_Spell={GetSpellName=function(id) return id==20999 and 'Judgement' or nil end}
out=R.Build(rows,util,{probe=probe,assist=20999}); assert(out.now.key=='Judgement')
-- A spell the guide doesn't list is still shown; a secret one is shown and compared with nothing.
out=R.Build(rows,util,{probe=probe,assist=4242}); assert(out.now.assist==4242 and not out.now.key and #out.upcoming==3)
out=R.Build(rows,util,{probe=probe,assist='SECRET'}); assert(out.now.secret and out.now.assist=='SECRET')
-- A proc step (Arcane Missiles waits for Missile Barrage) is never NOW on the guide's word alone.
local mageKnown={['Arcane Missiles']=spell(5143,'Arcane Missiles'),['Arcane Blast']=spell(30451,'Arcane Blast')}
out=R.Build(NS.BuildRows('MAGE',1,30,mageKnown,'single','damage'),{},{probe=probe})
assert(out.now.key=='Arcane Blast' and out.upcoming[1].key=='Arcane Missiles')
-- Blizzard's assistant can still pick it: it can see the proc.
out=R.Build(NS.BuildRows('MAGE',1,30,mageKnown,'single','damage'),{},{probe=probe,assist=5143}); assert(out.now.key=='Arcane Missiles')
-- Upcoming count is honoured, including zero.
out=R.Build(rows,util,{probe=probe,count=0}); assert(#out.upcoming==0)
-- Utility spells never enter the damage track (Lay on Hands is in Holy's healing list too).
local holyKnown={['Flash of Light']=spell(19750,'Flash of Light'),['Lay on Hands']=spell(633,'Lay on Hands')}
local holyRows=NS.BuildRows('PALADIN',1,30,holyKnown,'single','heal')
out=R.Build(holyRows,{{name='Lay on Hands',kind='emergency',major=true,spell=holyKnown['Lay on Hands']}},{probe=probe})
assert(out.now.key=='Flash of Light' and #out.upcoming==0)
-- Unknown readings (secret cooldowns in combat) keep guide order; nothing is invented.
probe.cooldown={}; probe.usable={}
local secretProbe={Usable=function() return nil end,CooldownLeft=function() return nil end,HasBuff=function() return nil end}
out=R.Build(rows,util,{probe=secretProbe}); assert(out.now.key=='Consecration' and #out.reminders==0)
print('Rotation engine: buffs out of the track, reminders only when known missing, cooldown/unusable ordering, Blizzard suggestion by ID or rank name, secret suggestion, utility kept apart, unknowns keep guide order: passed')

-- Cleave rows: single-target list plus AoE spells that pay off against two.
local warrior={Cleave=spell(845,'Cleave'),Whirlwind=spell(1680,'Whirlwind'),['Mortal Strike']=spell(12294,'Mortal Strike'),['Heroic Strike']=spell(78,'Heroic Strike')}
local function keys(list) local t={} for _,r in ipairs(list) do t[r.key]=true end return t end
local st=keys(NS.BuildRows('WARRIOR',1,50,warrior,'single','damage'))
local clv=keys(NS.BuildRows('WARRIOR',1,50,warrior,'cleave','damage'))
local aoe=keys(NS.BuildRows('WARRIOR',1,50,warrior,'aoe','damage'))
assert(clv.Cleave and not st.Cleave and aoe.Cleave)
assert(st['Mortal Strike'] and clv['Mortal Strike'])
-- A spec with no cleave spells learned uses its single-target list for two enemies.
local mage={Frostbolt=spell(116,'Frostbolt'),Blizzard=spell(10,'Blizzard')}
local mst=NS.BuildRows('MAGE',3,40,mage,'single','damage'); local mclv=NS.BuildRows('MAGE',3,40,mage,'cleave','damage')
assert(#mst==#mclv)
print('Cleave lists: AoE spells that suit two enemies join the single-target list; others fall back to single target: passed')
-- Every utility spell has an ID for other languages, and none collides with a rotation spell.
for class,list in pairs(NS.utility) do
 assert(NS.trees[class])
 for _,entry in ipairs(list) do assert(NS.baseIDs[entry.name],entry.name..' has no ID'); assert(not NS.upkeep[entry.name]) end
end
assert(NS.IsTank('PALADIN',2,'damage') and NS.IsTank('DRUID',2,'bear') and not NS.IsTank('MAGE',3,'damage'))
print('Utility data: every class known, IDs on record, tanks recognised: passed')
`);

// HUD drawing and Main integration ---------------------------------------------------------
run(`
frames={}
local methods={}
function methods:SetScript(e,cb) self.scripts[e]=cb end
function methods:GetScript(e) return self.scripts[e] end
function methods:RegisterEvent(e) self.events[e]=true end
function methods:Show() self.shown=true end
function methods:Hide() if self.shown~=false then self.shown=false; if self.scripts.OnHide then self.scripts.OnHide(self) end end end
function methods:IsShown() return self.shown~=false end
function methods:SetShown(v) if v then self:Show() else self:Hide() end end
function methods:SetText(v) self.text=v end
function methods:GetText() return self.text end
function methods:SetSize(w,h) self.width=w; self.height=h end
function methods:SetWidth(v) self.width=v end
function methods:SetHeight(v) self.height=v end
function methods:SetScale(v) self.scale=v end
function methods:GetScale() return self.scale or 1 end
function methods:GetFrameLevel() return 1 end
function methods:EnableMouse(v) self.mouse=v end
function methods:GetWidth() return self.width or 100 end
function methods:GetEffectiveScale() return 1 end
function methods:SetAlpha(v) self.alpha=v end
function methods:SetPoint(...) self.point={...} end
function methods:GetPoint() return 'CENTER',UIParent,'CENTER',12,34 end
function methods:SetTexture(v) self.texture=v end
function methods:SetDesaturated(v) self.desaturated=v end
function methods:SetChecked(v) self.checked=v end
function methods:GetChecked() return self.checked==true end
function methods:SetEnabled(v) self.enabled=v end
function methods:SetTabSelected(v) self.isSelected=v end
function methods:SetMinMaxValues(a,b) self.minimum=a; self.maximum=b end
function methods:SetValue(v) self.value=math.max(self.minimum,math.min(self.maximum,v)); if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,self.value) end end
function methods:SetCooldownFromDurationObject(v) self.duration=v end
function methods:Clear() self.duration=nil end
local function object() return setmetatable({scripts={},events={}},{__index=function(_,k) return methods[k] or function() end end}) end
function methods:CreateFontString() return object() end
function methods:CreateTexture() return object() end
function CreateFrame(kind,name,parent,template)
 local f=object(); f.kind=kind; f.template=template; f.parent=parent; frames[#frames+1]=f
 if template=='DefaultPanelTemplate' then f.TitleContainer=object(); f.TitleContainer.TitleText=object() end
 if template=='UISliderTemplateWithLabels' then f.Text=object(); f.Low=object(); f.High=object() end
 if name then _G[name]=f end
 return f
end
UIParent=object(); GameTooltip=object(); Minimap=object(); SlashCmdList={}
function GetCursorPosition() return 0,0 end
function UnitClass() return 'Paladin','PALADIN' end
function UnitLevel() return 30 end
book={}
C_SpellBook={GetNumSpellBookSkillLines=function() return 1 end,
 GetSpellBookSkillLineInfo=function() return {itemIndexOffset=0,numSpellBookItems=#book} end,
 GetSpellBookItemInfo=function(slot) local s=book[slot]; return {spellID=s.id,name=s.name,isPassive=false,isOffSpec=false,iconID=s.id} end,
 GetSpellBookItemLevelLearned=function() return 1 end,IsSpellKnown=function() return true end}
Enum.SpellBookSpellBank={Player=0}
C_Spell={GetSpellInfo=function() return nil end,GetSpellCooldownDuration=function() return 'duration' end,
 IsSpellUsable=function() return true,false end,GetSpellTexture=function(id) return 'tex'..tostring(id) end}
GetTalentTabInfo=function(i) return 'Tree',nil,({0,11,0})[i] end
for _,s in ipairs({{25780,'Righteous Fury'},{26573,'Consecration'},{20271,'Judgement'},{20925,'Holy Shield'},{9,'Holy Strike'},{879,'Exorcism'},{498,'Divine Protection'},{853,'Hammer of Justice'}}) do
 book[#book+1]={id=s[1],name=s[2]}
end
function flush() for _,f in ipairs(frames) do local up=f.scripts.OnUpdate; if up and rawget(f,'kind')=='Frame' and rawget(f,'parent')==nil then up(f,0.05) end end end
function dispatch(e,...) for _,f in ipairs(frames) do if f.events[e] then f.scripts.OnEvent(f,e,...) end end end
function fire(e,...) dispatch(e,...); flush() end
NS.Gear=nil
`);
load('GearProfiles.lua'); load('Settings.lua'); load('HUD.lua'); load('Main.lua');
run(`
local function icons(f,role)
 local n=0
 for _,b in ipairs(frames) do if rawget(b,'parent')==f and rawget(b,'role')==role and b:IsShown() and rawget(b,'spellID') then n=n+1 end end
 return n
end
-- Migration: an existing character's manual AoE choice is kept; its position and size stay.
EverfrostDB={aoe=true,scale=1.3,point='TOP',relativePoint='TOP',x=5,y=-50,opacity=0.8,locked=true}
fire('PLAYER_LOGIN')
local f=EverfrostFrame
assert(EverfrostDB.hud.mode=='aoe' and EverfrostDB.aoe==nil and EverfrostDB.version==2)
assert(EverfrostDB.scale==1.3 and f.scale==1.3 and f.point[1]=='TOP' and f.point[4]==5 and f.alpha==0.8)
assert(EverfrostDB.hud.layout=='track' and EverfrostDB.hud.upcoming==3 and EverfrostDB.hud.combatOnly)
-- Combat-only: hidden at rest (Righteous Fury's state is unknown here, so no reminder).
assert(not f:IsShown())
-- In combat: NOW plus three upcoming, and the defensive row for a Protection tank.
fire('PLAYER_REGEN_DISABLED')
assert(f:IsShown() and f.hud.now:IsShown() and icons(f,'up')==3 and icons(f,'util')==2)
assert(f.hud.now.spellID==26573 and f.hud.now.width==48 and f.hud.queue[1].width==36)
assert(f.mode.text=='AOE')
-- In combat the icons let clicks through to the world; locked, so does the HUD's background.
assert(f.hud.now.mouse==false and f.hud.queue[1].mouse==false and f.mouse==false)
-- Manual mode stays until changed; AUTO follows the enemy estimate.
SlashCmdList.EVERFROST('mode auto'); assert(EverfrostDB.hud.mode=='auto' and f.mode.text:find('AUTO',1,true))
-- Enemy plates: three engaged enemies switch to AoE through the ticker.
units={}
function UnitExists(u) return units[u]~=nil end
function UnitCanAttack(_,u) return units[u]~=nil end
function UnitIsDead(u) return units[u] and units[u].dead or false end
function UnitPlayerControlled() return false end
function UnitCreatureType() return 'Undead' end
function UnitAffectingCombat(u) return units[u]~=nil end
function UnitThreatSituation() return 1 end
for i=1,3 do units['nameplate'..i]={}; fire('NAME_PLATE_UNIT_ADDED','nameplate'..i) end
clock=clock+1; flush(); flush(); flush(); flush(); flush(); flush()
assert(NS.Enemies.count==3 and f.mode.text:find('AOE',1,true) and f.mode.text:find('~3',1,true))
-- Two die: Cleave only after the grace period.
units.nameplate2.dead=true; units.nameplate3.dead=true
clock=clock+0.3; for _=1,6 do flush() end
assert(NS.Enemies.count==1 and f.mode.text:find('AOE',1,true))
clock=clock+2; for _=1,6 do flush() end
assert(f.mode.text:find('ST',1,true))
-- Blizzard's suggestion becomes NOW.
C_AssistedCombat={IsAvailable=function() return true,'' end,GetNextCastSpell=function() return 879 end}
clock=clock+1; for _=1,4 do flush() end
assert(f.hud.now.spellID==879 and f.hud.now.row.assist)
-- Guide-only source ignores it.
SlashCmdList.EVERFROST('mode auto'); EverfrostDB.hud.source='guide'; NS.UpdateHUD(); assert(f.hud.now.spellID~=879)
EverfrostDB.hud.source='assist'; C_AssistedCombat=nil
-- Layouts share the engine: classic is a plain row, minimal caps upcoming at two, tank always has the utility row.
SlashCmdList.EVERFROST('layout classic'); assert(icons(f,'up')==3 and f.hud.queue[1].width==38 and not f.hud.zoneTop:IsShown())
SlashCmdList.EVERFROST('layout minimal'); assert(icons(f,'up')==2 and f.hud.queue[1].width==29)
SlashCmdList.EVERFROST('utility off'); assert(icons(f,'util')==0)
SlashCmdList.EVERFROST('layout tank'); assert(icons(f,'util')==2)
SlashCmdList.EVERFROST('layout track'); SlashCmdList.EVERFROST('utility auto')
-- Only three other spells are learned, so six upcoming slots still show three.
SlashCmdList.EVERFROST('upcoming 6'); assert(icons(f,'up')==3)
SlashCmdList.EVERFROST('upcoming 3')
-- The track slides when the first upcoming spell becomes NOW.
local first,current=f.hud.queue[1].spellID,f.hud.now.spellID
C_Spell.IsSpellUsable=function(id) return id~=current,false end
fire('SPELL_UPDATE_USABLE')
assert(f.hud.now.spellID==first and f.hud.anim and f.hud.anim.shift==42)
for _=1,10 do local up=f.scripts.OnUpdate; if up then up(f,0.05) end end
assert(f.hud.anim==nil)
C_Spell.IsSpellUsable=function() return true,false end
-- The NOW spell turning usable again pulses without sliding.
-- (Everything out of mana keeps guide order, so NOW is the same spell before and after.)
C_Spell.IsSpellUsable=function() return false,true end; NS.UpdateHUD()
for _=1,10 do local up=f.scripts.OnUpdate; if up then up(f,0.05) end end
current=f.hud.now.spellID; assert(f.hud.anim==nil and f.hud.now.row.usable==false)
C_Spell.IsSpellUsable=function() return true,false end; NS.UpdateHUD()
assert(f.hud.now.spellID==current and f.hud.anim and f.hud.anim.flash and f.hud.anim.shift==nil)
for _=1,10 do local up=f.scripts.OnUpdate; if up then up(f,0.05) end end
-- Animations off: no movement.
EverfrostDB.hud.animate=false; current=f.hud.now.spellID; C_Spell.IsSpellUsable=function(id) return id~=current,false end
fire('SPELL_UPDATE_USABLE'); assert(f.hud.anim==nil); EverfrostDB.hud.animate=true
C_Spell.IsSpellUsable=function() return true,false end
-- Bindings.
EverfrostSetMode('cycle'); assert(EverfrostDB.hud.mode=='single')
EverfrostSetMode('cycle'); assert(EverfrostDB.hud.mode=='cleave')
EverfrostSetMode('aoe'); assert(EverfrostDB.hud.mode=='aoe'); EverfrostSetMode('auto')
assert(BINDING_NAME_EVERFROST_MODE_CYCLE and BINDING_NAME_EVERFROST_MODE_AOE)
-- Combat ends: enemy tracking cleared, back to hidden.
fire('PLAYER_REGEN_ENABLED'); assert(not f:IsShown() and NS.Enemies.count==nil)
EverfrostDB.hud.preview=true; NS.UpdateHUD(); assert(f.hud.now.mouse==true); EverfrostDB.hud.preview=false; NS.UpdateHUD()
print('HUD: migration keeps manual AoE, position and size; combat-only; NOW, upcoming and tank utility; automatic AoE from nameplates with step-down grace; Blizzard suggestion; four layouts; slide animation and off switch; bindings: passed')

-- Controller layout: its own position and size, switched without a reload.
Enum.InputDeviceInterfaceType={Mkb=0,Gamepad=1}
EverfrostDB.hud.preview=true; NS.UpdateHUD()
assert(f.hud.now.width==48)
fire('INPUT_DEVICE_INTERFACE_TRANSITION',1)
assert(NS.Input.device=='kbm')                         -- debouncing
clock=clock+1; flush()
assert(NS.Input.device=='pad' and f.hud.now.width==60 and f.hud.queue[1].width==44)
assert(f.point[1]=='CENTER' and f.point[5]==-120 and f.scale==1)
SlashCmdList.EVERFROST('scale 1.5'); assert(EverfrostDB.hud.padScale==1.5 and EverfrostDB.scale==1.3)
f.moving=true; f.StopDrag(); assert(EverfrostDB.hud.pad.x==12 and EverfrostDB.x==5)
fire('INPUT_DEVICE_INTERFACE_TRANSITION',0); clock=clock+1; flush()
assert(NS.Input.device=='kbm' and f.scale==1.3 and f.point[4]==5 and f.hud.now.width==48)
-- Forced layouts and turning auto-switch off.
SlashCmdList.EVERFROST('input pad'); assert(f.scale==1.5 and f.hud.now.width==60)
SlashCmdList.EVERFROST('input auto'); EverfrostDB.hud.autoSwitch=false
fire('INPUT_DEVICE_INTERFACE_TRANSITION',1); clock=clock+1; flush(); assert(NS.Input.device=='kbm')
EverfrostDB.hud.autoSwitch=true
-- Reset puts this layout back to its default spot and size.
SlashCmdList.EVERFROST('reset'); assert(EverfrostDB.scale==1 and EverfrostDB.point==nil and f.point[5]==-190)
print('Input layouts in the HUD: debounced automatic switch, separate positions and sizes, forced layouts, auto-switch off, reset: passed')

-- Settings: the new pages drive the same saved values.
local window=NS.Settings.window
for _,key in ipairs({'Guide','Panel','Input','Detect','Gear','Talents'}) do assert(window.pages[key] and window.tabs[key]) end
window.pages.Panel.layouts[4].scripts.OnClick(); assert(EverfrostDB.hud.layout=='tank')
window.pages.Guide.modes[3].scripts.OnClick(); assert(EverfrostDB.hud.mode=='cleave')
window.pages.Input.modes[2].scripts.OnClick(); assert(EverfrostDB.hud.input=='pad')
window.pages.Detect.aoe:SetValue(5); assert(EverfrostDB.hud.thresholds.PALADIN2.aoe==5)
window.pages.Guide.upcoming:SetValue(2); assert(EverfrostDB.hud.upcoming==2)
window.pages.Guide.utility.scripts.OnClick(); assert(EverfrostDB.hud.utility=='on')
-- Gear scoring focus: the Gear & Loot button cycles the spec's choices and hands them to the gear engine.
NS.Gear={SetContext=function() end,SetFocus=function(key) focusSet=key or 'default' end,Schedule=function() end,EmptySlots=function() return false,0 end}
NS.GearFocusChoices=function(class,spec) if class=='PALADIN' and spec==2 then return {{key='balanced',label='Balanced Tank',default=true},{key='survival',label='Tank Survivability'},{key='threat',label='Tank Threat'}} end end
NS.Settings:Refresh(); local focus=window.pages.Gear.focus
assert(focus:IsShown() and focus.text=='Scoring: Balanced Tank')
focus.scripts.OnClick(); assert(EverfrostDB.gearFocus.PALADIN2=='survival' and focusSet=='survival' and focus.text=='Scoring: Tank Survivability')
focus.scripts.OnClick(); assert(EverfrostDB.gearFocus.PALADIN2=='threat')
focus.scripts.OnClick(); assert(EverfrostDB.gearFocus.PALADIN2=='balanced' and focusSet=='balanced')
NS.Gear=nil
window.pages.Panel.resetAll.scripts.OnClick(); assert(EverfrostDB.hud.layout=='track' and EverfrostDB.hud.mode=='auto' and EverfrostDB.hud.upcoming==3)
print('Settings: six pages; layout, mode, input, thresholds, upcoming count, defensive row and reset write the saved settings: passed')
`);
console.log('HUD checks passed. The Forever client, its secret-value rules and the look on screen still need in-game testing.');
