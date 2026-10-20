const fs = require('fs');
const assert = require('node:assert/strict');
const path = require('path');
const parser = require('luaparse');
const {lua, lauxlib, lualib, to_luastring, to_jsstring} = require('fengari');
const root = path.resolve(__dirname, '../addon/Everfrost');
const sources = {};
for (const name of ['Profiles.lua','Core.lua','GearProfiles.lua','Gear.lua','GearUI.lua','Settings.lua','Main.lua']) {
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
assert(select(3,NS.DetectSpec('PALADIN'))==true)
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
assert(select(3,NS.DetectSpec('DRUID'))==false)
C_SpecializationInfo=nil
assert(select(2,NS.DetectSpec('ROGUE'))=='Spec unavailable')
assert(NS.DetectSpec('DEATHKNIGHT')==0)
GetTalentTabInfo=function(i) if i==1 then return 'Tree',nil,3 end end
assert(select(3,NS.DetectSpec('MAGE'))==false)
GetTalentTabInfo=nil
-- Forever's visible 9/0/0 headers come from trait currency, even when the
-- specialization pointsSpent tuple is present but reports three zeroes.
local traitReads,tupleReads=0,0
local group,ready,staged,mode=1,true,false,nil
local splits={{9,0,0},{0,4,1}}
local function traitRead() assert(not combat); traitReads=traitReads+1 end
C_SpecializationInfo={GetActiveSpecGroup=function() traitRead(); return group end,
 GetCombatConfigIDForSpecGroup=function(g) traitRead(); assert(g==group); if ready then return g*100 end end,
 GetSpecializationInfo=function(i) tupleReads=tupleReads+1; return i,'Tree',nil,nil,nil,nil,0 end}
C_Traits={ConfigHasStagedChanges=function() traitRead(); return staged end,
 GetConfigInfo=function(id) traitRead(); assert(id==group*100); return {treeIDs={77}} end,
 GetGroupDisplayInfoByTreeID=function(tree)
  traitRead(); assert(tree==77); return {{groupID=31},{groupID=32},{groupID=33}}
 end,
 GetGroupCurrencyInfo=function(id,ids)
  traitRead(); assert(id==group*100 and ids[1]==31 and ids[2]==32 and ids[3]==33)
  if mode=='secretTable' then return 'SECRET' end
  local spent=splits[group]
  local result={{traitNodeGroupID=33,currencyInfos={{spent=spent[3]}}},
   {traitNodeGroupID=31,currencyInfos={{spent=mode=='secretSpent' and 'SECRET' or spent[1]}}},
   {traitNodeGroupID=32,currencyInfos={{spent=spent[2]}}}}
  if mode=='missingCurrency' then result[3].currencyInfos={} end
  if mode=='omittedZeroGroups' then return {result[2]} end
  return result
 end}
local tree,status,complete,points,source=NS.DetectSpec('SHAMAN')
assert(tree==1 and status=='Auto' and complete and points[1]==9 and points[2]==0 and points[3]==0)
assert(source=='Trait currency' and tupleReads==0)
mode='omittedZeroGroups'; tree,status,complete,points=NS.DetectSpec('SHAMAN')
assert(tree==1 and complete and points[1]==9 and points[2]==0 and points[3]==0)
mode=nil
group=2; assert(NS.DetectSpec('SHAMAN')==2)
splits[2]={0,0,0}; assert(select(2,NS.DetectSpec('SHAMAN'))=='Unspent')
splits[2]={4,4,0}; assert(select(2,NS.DetectSpec('SHAMAN'))=='Hybrid')
for _,failure in ipairs({'missingCurrency','secretSpent','secretTable'}) do
 mode=failure; tree,status,complete=NS.DetectSpec('SHAMAN')
 assert(tree==0 and status=='Spec unavailable' and not complete and tupleReads==0)
end
mode=nil; ready=false
assert(select(2,NS.DetectSpec('SHAMAN'))=='Spec unavailable' and tupleReads==0)
ready=true; staged=true
assert(select(2,NS.DetectSpec('SHAMAN'))=='Spec unavailable')
staged=false; local before=traitReads; combat=true
assert(select(2,NS.DetectSpec('SHAMAN'))=='Spec unavailable' and traitReads==before)
combat=false; splits[2]={0,1,6}
C_SpecializationInfo.GetCombatConfigIDForSpecGroup=nil
C_ClassTalents={GetActiveConfigID=function() traitRead(); return group*100 end}
assert(NS.DetectSpec('SHAMAN')==3)
C_Traits=nil; C_ClassTalents=nil
assert(select(2,NS.DetectSpec('SHAMAN'))=='Unspent' and tupleReads==3)
C_SpecializationInfo=nil
print('Forever traits: native 9/0/0 despite zero specialization tuples, active groups, shuffled currencies, ties/unspent, pending/staged/secret data and combat safety: passed')
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
function methods:GetScript(e) return self.scripts[e] end
function methods:GetFrameLevel() return 1 end
function methods:SetScale(v) self.scale=v end
function methods:SetAlpha(v) self.alpha=v end
function methods:SetBackdrop(v) self.backdrop=v end
function methods:GetScale() return self.scale or 1 end
function methods:RegisterEvent(e) self.events[e]=true end
function methods:Show() self.shown=true end
function methods:Hide() if self.shown~=false then self.shown=false; if self.scripts.OnHide then self.scripts.OnHide(self) end end end
function methods:IsShown() return self.shown~=false end
function methods:SetShown(v) if v then self:Show() else self:Hide() end end
function methods:SetText(v) self.text=v end
function methods:SetWidth(v) self.width=v end
function methods:SetHeight(v) self.height=v end
function methods:SetSize(w,h) self.width=w; self.height=h end
function methods:GetWidth() return self.width or 140 end
function methods:GetCenter() return 100,100 end
function methods:GetEffectiveScale() return 1 end
function methods:SetPoint(...) self.point={...} end
function methods:SetChecked(value) self.checked=value end
function methods:GetChecked() return self.checked==true end
function methods:SetEnabled(value) self.enabled=value end
function methods:SetTabSelected(value) self.isSelected=value; self:SetEnabled(not value) end
function methods:SetJustifyV(value) self.justifyV=value end
function methods:SetMinMaxValues(low,high) self.minimum=low; self.maximum=high end
function methods:SetValue(value)
 self.value=math.max(self.minimum,math.min(self.maximum,value))
 if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,self.value) end
end
function methods:GetPoint() return 'CENTER',UIParent,'CENTER',100,40 end
function methods:SetCooldownFromDurationObject(v) assert(v==duration); self.duration=v end
function methods:Clear() self.duration=nil end
local function object() return setmetatable({scripts={},events={}},{__index=function(t,k) if k=="value" then return nil end; return methods[k] or function() end end}) end
function methods:CreateFontString() return object() end
function methods:CreateTexture() return object() end
function CreateFrame(kind,name,parent,template)
 local f=object(); f.template=template; frames[#frames+1]=f
 if template=='DefaultPanelTemplate' then f.TitleContainer=object(); f.TitleContainer.TitleText=object() end
 if template=='UISliderTemplateWithLabels' then f.Text=object(); f.Low=object(); f.High=object() end
 if name then _G[name]=f end; return f
end
UIParent=object(); GameTooltip=object(); STANDARD_TEXT_FONT='font'; SlashCmdList={}
Minimap=object(); cursorX,cursorY=100,200
function GetCursorPosition() return cursorX,cursorY end
settingsRegistrations=0
Settings={RegisterCanvasLayoutCategory=function(panel,name) assert(name=='Everfrost'); return {ID=123,panel=panel} end,
 RegisterAddOnCategory=function(category) settingsRegistrations=settingsRegistrations+1; registeredCategory=category end}
function UnitLevel() return currentLevel end
function UnitClass() return currentClass,currentClass end
function fire(e,value) for _,f in ipairs(frames) do if f.events[e] then f.scripts.OnEvent(f,e,value) end end end
function visibleSpells() local n=0; for _,f in ipairs(frames) do if rawget(f,'spellID') and f:IsShown() then n=n+1 end end; return n end
duration={}; C_Spell.GetSpellCooldownDuration=function() return duration end
EverfrostDB={scale=1.2,locked=true,point='CENTER',relativePoint='CENTER',x=100,y=40}
GetTalentTabInfo=function(i) return 'Tree',nil,({0,0,2})[i] end
`);
load('GearProfiles.lua');
run(`
NS.Gear={SetContext=function(...) lastGearContext={...} end,Schedule=function() gearScheduled=true end,Paint=function() end}
`);
load('Settings.lua');
load('Main.lua');
run(`
fire('PLAYER_LOGIN'); local f=EverfrostFrame
assert(f.title.text=='Retribution  PALADIN' and f.meta.text:find('5'))
assert(EverfrostDB.scale==1.2 and EverfrostDB.x==100)
assert(visibleSpells()==1 and f.width==320)
assert(EverfrostDB.opacity==1 and f.alpha==1)
assert(f.backdrop.edgeFile=='Interface'..string.char(92)..'DialogFrame'..string.char(92)..'UI-DialogBox-Border')
assert(f.mode.template=='UIPanelButtonTemplate' and f.role.template=='UIPanelButtonTemplate')
assert(lastGearContext[1]=='PALADIN' and lastGearContext[2]==0)
local cmd=SlashCmdList.EVERFROST
local settings=NS.Settings; local window=settings.window
assert(settingsRegistrations==1 and registeredCategory==settings.category)
assert(window.template=='DefaultPanelTemplate' and window.inset.template=='InsetFrameTemplate')
assert(window.pages.Gear.priority.justifyV=='TOP')
assert(not window:IsShown() and settings.minimap:IsShown())
cmd(''); assert(window:IsShown() and window.pages.Guide:IsShown())
cmd('hide'); cmd(''); assert(window:IsShown() and not f:IsShown())
window.tabs.Panel.scripts.OnClick(); assert(window.pages.Panel:IsShown() and not window.pages.Guide:IsShown())
assert(window.tabs.Panel.isSelected and not window.tabs.Guide.isSelected)
local panel=window.pages.Panel
panel.visible:SetChecked(true); panel.visible.scripts.OnClick(panel.visible); assert(f:IsShown())
panel.locked:SetChecked(false); panel.locked.scripts.OnClick(panel.locked); assert(not EverfrostDB.locked)
panel.locked:SetChecked(true); panel.locked.scripts.OnClick(panel.locked); assert(EverfrostDB.locked)
panel.slider:SetValue(1.3); assert(EverfrostDB.scale==1.3)
panel.slider:SetValue(0.1); assert(EverfrostDB.scale==0.6)
panel.slider:SetValue(3); assert(EverfrostDB.scale==2)
panel.slider:SetValue(1.2); assert(EverfrostDB.scale==1.2)
-- Live opacity applies to the reference frame only, survives redraws and rejects bad commands.
assert(panel.opacitySlider.minimum==10 and panel.opacitySlider.maximum==100 and panel.opacity.text=='100%')
panel.opacitySlider:SetValue(60); assert(EverfrostDB.opacity==0.6 and f.alpha==0.6 and panel.opacity.text=='60%')
assert(rawget(window,'alpha')==nil and rawget(f.guideMenu,'alpha')==nil and rawget(GameTooltip,'alpha')==nil)
cmd('aoe'); assert(f.alpha==0.6); cmd('single')
cmd('opacity 0'); cmd('opacity 101'); cmd('opacity nonsense'); assert(EverfrostDB.opacity==0.6 and f.alpha==0.6)
panel.opacitySlider:SetValue(1); assert(EverfrostDB.opacity==0.1 and f.alpha==0.1)
panel.opacitySlider:SetValue(200); assert(EverfrostDB.opacity==1 and f.alpha==1)
combat=true; panel.opacitySlider:SetValue(65); assert(EverfrostDB.opacity==0.65 and f.alpha==0.65); combat=false
cmd('reset'); assert(EverfrostDB.opacity==0.65 and f.alpha==0.65)
local savedOpacityDB=EverfrostDB
fire('PLAYER_LOGIN'); f=EverfrostFrame; assert(EverfrostDB==savedOpacityDB and f.alpha==0.65 and panel.opacity.text=='65%')
cmd('opacity 100')
panel.minimap:SetChecked(false); panel.minimap.scripts.OnClick(panel.minimap); assert(not settings.minimap:IsShown())
cmd('minimap on'); assert(settings.minimap:IsShown())
window.close.scripts.OnClick(); settings.minimap.scripts.OnClick(settings.minimap,'LeftButton'); assert(window:IsShown())
settings.minimap.scripts.OnClick(settings.minimap,'RightButton'); assert(not f:IsShown())
settings.minimap.scripts.OnClick(settings.minimap,'RightButton'); assert(f:IsShown())
settings.minimap.scripts.OnDragStart(settings.minimap); settings.minimap.scripts.OnUpdate()
assert(math.abs(EverfrostDB.minimapAngle-90)<0.01)
settings.minimap.scripts.OnDragStop(settings.minimap); assert(settings.minimap.scripts.OnUpdate==nil)
settings.gameButton.scripts.OnClick(); assert(window:IsShown())
window.tabs.Guide.scripts.OnClick()
window.pages.Guide.rows[2].scripts.OnClick(window.pages.Guide.rows[2])
assert(EverfrostDB.spec==0 and window.pages.Gear.priority.text=='Not active yet.')
assert(window.pages.Gear.levelNote.text==NS.gearLevelNote)
window.pages.Guide.rows[1].scripts.OnClick(window.pages.Guide.rows[1]); assert(EverfrostDB.spec==nil)
local gear=window.pages.Gear
gear.enabled:SetChecked(false); gear.enabled.scripts.OnClick(gear.enabled); assert(EverfrostDB.gear==false and gearScheduled)
gear.enabled:SetChecked(true); gear.enabled.scripts.OnClick(gear.enabled); assert(EverfrostDB.gear==true)
gear.rescan.scripts.OnClick(); assert(gearScheduled)
window:Hide(); combat=true; cmd(''); assert(not window:IsShown()); combat=false
cmd('config'); assert(window:IsShown()); window:Hide()
combat=true; fire('PLAYER_REGEN_DISABLED'); assert(not gear.rescan.enabled)
combat=false; fire('PLAYER_REGEN_ENABLED'); assert(gear.rescan.enabled)
assert(#f.guideMenu.rows==5 and not f.guideMenu:IsShown())
f.guide.scripts.OnClick(); assert(f.guideMenu:IsShown() and f.guideCatcher:IsShown())
assert(f.guideMenu.rows[1].check:IsShown() and f.guideMenu.rows[1].detail.text=='Detected: Retribution')
f.guideMenu.rows[2].scripts.OnClick()
assert(EverfrostDB.spec==0 and f.title.text=='Leveling  PALADIN' and lastGearContext[2]==0)
assert(not f.guideMenu:IsShown() and not f.guideCatcher:IsShown())
f.guide.scripts.OnClick(); assert(f.guideMenu.rows[2].check:IsShown())
f.guideMenu.rows[3].scripts.OnClick(); assert(EverfrostDB.spec==1 and f.title.text=='Holy  PALADIN')
f.guide.scripts.OnClick(); f.guideCatcher.scripts.OnClick(); assert(not f.guideMenu:IsShown())
cmd('spec auto'); assert(EverfrostDB.spec==nil and f.title.text=='Retribution  PALADIN')
combat=true; f.guide.scripts.OnClick(); f.guideMenu.rows[4].scripts.OnClick()
assert(EverfrostDB.spec==2 and f.title.text=='Retribution  PALADIN' and f.meta.text:find('PENDING'))
assert(window.status.text:find('Changes after combat') and not window.pages.Gear.rescan.enabled)
combat=false; fire('PLAYER_REGEN_ENABLED'); assert(f.title.text=='Protection  PALADIN' and lastGearContext[2]==0)
cmd('spec leveling'); fire('PLAYER_ENTERING_WORLD')
assert(f.title.text=='Leveling  PALADIN' and EverfrostDB.spec==0)
cmd('spec auto')
cmd('gear off'); assert(EverfrostDB.gear==false and gearScheduled)
cmd('gear on'); assert(EverfrostDB.gear==true)
cmd('gear')
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
-- Leveling keeps its spell profile, but gear follows the dominant talent tree at 10+.
local talentCalls=0
local talentPoints={0,2,0}
GetTalentTabInfo=function(i) assert(not combat); talentCalls=talentCalls+1; return 'Tree',nil,talentPoints[i] end
for _,value in ipairs({'bad',false,0/0,math.huge,-math.huge}) do
 EverfrostDB={opacity=value}; fire('PLAYER_LOGIN'); assert(EverfrostDB.opacity==1 and EverfrostFrame.alpha==1)
end
EverfrostDB={opacity=-1}; fire('PLAYER_LOGIN'); assert(EverfrostDB.opacity==0.1)
EverfrostDB={opacity=2}; fire('PLAYER_LOGIN'); assert(EverfrostDB.opacity==1)
currentClass='SHAMAN'; currentLevel=9; EverfrostDB={spec=0}; fire('PLAYER_LOGIN')
assert(EverfrostFrame.title.text=='Leveling  SHAMAN' and lastGearContext[2]==0)
assert(window.pages.Gear.priority.text=='Not active yet.')
cmd('spec 1'); assert(EverfrostDB.spec==1 and lastGearContext[2]==0)
cmd('spec leveling')
fire('PLAYER_LEVEL_UP',10)
assert(EverfrostDB.spec==0 and EverfrostFrame.title.text=='Leveling  SHAMAN' and lastGearContext[2]==2)
assert(window.pages.Gear.priorityTitle.text=='Stat priority: Enhancement (talents)')
assert(window.pages.Gear.priority.text:find('Weapon DPS',1,true)==1)
talentPoints={4,2,0}; fire('PLAYER_TALENT_UPDATE')
assert(lastGearContext[2]==1 and window.pages.Gear.priorityTitle.text=='Stat priority: Elemental (talents)')
assert(window.pages.Gear.priority.text:find('Spell power',1,true)==1)
cmd('spec 3'); assert(lastGearContext[2]==3 and EverfrostDB.spec==3)
cmd('spec leveling'); assert(lastGearContext[2]==1 and EverfrostDB.spec==0)
talentPoints={4,4,0}; fire('PLAYER_TALENT_UPDATE')
assert(lastGearContext[2]==0 and window.pages.Gear.priority.text:find('tied'))
talentPoints={0,0,0}; fire('PLAYER_TALENT_UPDATE')
assert(lastGearContext[2]==0 and window.pages.Gear.priority.text:find('No talent points'))
-- An active spec index or incomplete point data cannot establish the dominant tree.
GetTalentTabInfo=function() assert(not combat); return nil end
C_SpecializationInfo={GetSpecialization=function() assert(not combat); return 1 end}
fire('PLAYER_TALENT_UPDATE'); assert(lastGearContext[2]==0 and window.pages.Gear.priority.text:find('unavailable'))
C_SpecializationInfo=nil
GetTalentTabInfo=function(i) assert(not combat); if i==1 then return 'Tree',nil,4 end end
fire('PLAYER_TALENT_UPDATE'); assert(lastGearContext[2]==0)
GetTalentTabInfo=function(i) assert(not combat); talentCalls=talentCalls+1; return 'Tree',nil,talentPoints[i] end
talentPoints={1,3,0}; fire('PLAYER_TALENT_UPDATE'); assert(lastGearContext[2]==2)
combat=true; local before=talentCalls; talentPoints={1,3,5}; fire('PLAYER_TALENT_UPDATE')
assert(talentCalls==before and lastGearContext[2]==2 and window.status.text:find('Changes after combat'))
combat=false; fire('PLAYER_REGEN_ENABLED'); assert(lastGearContext[2]==3)
-- Forever exposes pointsSpent as return 7 and accepts the active group as argument 6.
local activeGroup=2
C_SpecializationInfo={GetActiveSpecGroup=function() assert(not combat); return activeGroup end,
 GetSpecializationInfo=function(i,inspect,pet,target,sex,group)
  assert(not combat and group==activeGroup and inspect==false and pet==false)
  return i,'Tree',nil,nil,nil,nil,(group==2 and {5,2,0} or {0,1,4})[i]
 end}
fire('ACTIVE_TALENT_GROUP_CHANGED'); assert(lastGearContext[2]==1)
activeGroup=1; fire('ACTIVE_TALENT_GROUP_CHANGED'); assert(lastGearContext[2]==3)
C_SpecializationInfo=nil
-- Talent-inferred gear still respects Survival's ranged/melee requirements.
currentClass='HUNTER'; currentLevel=18; talentPoints={0,0,9}; EverfrostDB={spec=0}; fire('PLAYER_LOGIN')
assert(lastGearContext[2]==3 and lastGearContext[4]=='ranged')
assert(window.pages.Gear.priority.text==NS.GearPriorityText(NS.gearProfiles.HUNTER[2]))
book={{spellID=1,name='Strider Kick'}}; fire('PLAYER_LEVEL_UP',30)
assert(lastGearContext[2]==3 and lastGearContext[4]=='melee')
cmd('ranged'); assert(lastGearContext[4]=='ranged')
-- All nine classes use the same dominant-tree rule, including saved Leveling choices.
for class in pairs(NS.profiles) do
 currentClass=class; currentLevel=10; EverfrostDB={spec=0}; talentPoints={0,3,1}; fire('PLAYER_LOGIN')
 assert(EverfrostFrame.title.text:find(class))
 assert(EverfrostDB.spec==0 and lastGearContext[2]==2)
 assert(window.pages.Gear.priorityTitle.text=='Stat priority: '..NS.trees[class][2]..' (talents)')
 assert(#EverfrostFrame.guideMenu.rows==5)
 for index=1,3 do assert(EverfrostFrame.guideMenu.rows[index+2].label.text==NS.trees[class][index]) end
 for index=1,3 do assert(window.pages.Guide.rows[index+2].label.text==NS.trees[class][index]) end
 assert(settingsRegistrations==1)
end
currentClass='DRUID'; currentLevel=10; GetTalentTabInfo=function(i) return 'Tree',nil,({0,1,0})[i] end
book={{spellID=5487,name='Bear Form'},{spellID=6807,name='Maul'}}
EverfrostDB={}; fire('PLAYER_LOGIN')
assert(EverfrostFrame.role.text=='Bear')
book={}; fire('SPELLS_CHANGED'); assert(EverfrostFrame.role.text=='Caster')
print('Mock UI: all classes, migration, controls, talent override, leveling, combat refresh, cooldown fallback and feral labels: passed')
print('Settings UI: slash/minimap/native entry points, guide selection, persistent controls, scale, minimap dragging, class changes and combat deferral: passed')
print('Leveling gear: level-10 boundary, dominant talents, ties/unspent/unavailable/partial data, overrides, respec, combat caching, Survival roles and all classes: passed')
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
assert(EverfrostFrame.role.text=='Ranged')
fire('PLAYER_LEVEL_UP',30); assert(EverfrostFrame.role.text=='Melee')
SlashCmdList.EVERFROST('ranged'); assert(EverfrostFrame.role.text=='Ranged')
SlashCmdList.EVERFROST('melee'); assert(EverfrostFrame.role.text=='Melee')
book[1].future=true; fire('SPELLS_CHANGED'); assert(EverfrostFrame.role.text=='Ranged')
print('Level 21-30 additions, rank level gates, spec isolation, talent removal and Survival transition: passed')
`);



run(`
local function learned(...) local t={}; for _,name in ipairs({...}) do t[name]={id=1,level=1} end; return t end
local function rows(class,spec,known,mode,role,level)
 return keys(NS.BuildRows(class,spec,level or 30,known,mode or 'single',role or 'damage'))
end
local mage=learned('Frostbolt','Arcane Blast','Arcane Missiles','Fire Blast','Blizzard','Cone of Cold','Arcane Explosion','Flamestrike','Blast Wave','Ice Lance','Frost Nova')
assert(rows('MAGE',1,mage)=='Frostbolt,Arcane Blast,Arcane Missiles,Fire Blast')
mage['Arcane Blast']=nil
assert(rows('MAGE',1,mage)=='Frostbolt,Arcane Missiles')
assert(rows('MAGE',3,mage,'aoe')=='Cone of Cold,Ice Lance,Frost Nova,Blizzard,Arcane Explosion')
assert(rows('MAGE',3,learned('Arcane Explosion'),'aoe')=='Arcane Explosion')
assert(rows('MAGE',2,learned('Pyroblast','Fireball','Fire Blast'))=='Pyroblast,Fireball,Fire Blast')
local rogue=learned('Backstab','Sinister Strike','Mutilate','Blade Flurry','Riposte')
assert(rows('ROGUE',1,rogue)=='Mutilate')
rogue.Mutilate=nil
assert(rows('ROGUE',1,rogue)=='Backstab,Sinister Strike')
assert(rows('ROGUE',2,rogue)=='Blade Flurry,Riposte,Backstab,Sinister Strike')
local priest=learned('Smite','Mind Blast','Devouring Plague','Shadow Word: Pain','Mind Flay','Holy Nova')
assert(rows('PRIEST',3,priest)=='Mind Blast,Devouring Plague,Shadow Word: Pain,Mind Flay')
priest['Mind Flay']=nil
assert(rows('PRIEST',3,priest)=='Smite,Mind Blast,Devouring Plague,Shadow Word: Pain')
assert(rows('PRIEST',2,priest,'single','heal')=='Holy Nova')
assert(rows('PRIEST',1,priest,'single','heal')=='')
assert(rows('WARRIOR',2,learned('Victory Rush','Rend','Overpower'))=='Victory Rush,Rend,Overpower')
assert(rows('WARRIOR',3,learned('Revenge','Rend','Shield Block'))=='Revenge,Rend,Shield Block')
assert(rows('WARLOCK',1,learned('Bane of Agony','Siphon Life','Corruption'))=='Bane of Agony,Siphon Life,Corruption')
assert(rows('WARLOCK',2,learned('Siphon Life'))=='')
local shaman=learned('Searing Totem','Flametongue Totem','Magma Totem')
assert(rows('SHAMAN',2,shaman)=='Flametongue Totem')
assert(rows('SHAMAN',2,shaman,'aoe')=='Flametongue Totem,Magma Totem')
shaman['Flametongue Totem']=nil
assert(rows('SHAMAN',2,shaman)=='Searing Totem')
local hunter=learned('Summon Hawk','Disengage','Arcane Shot')
for spec=1,3 do assert(rows('HUNTER',spec,hunter):find('Disengage,Arcane Shot')) end
for _,row in ipairs(NS.BuildRows('HUNTER',1,30,hunter,'single','ranged')) do
 if row.key=='Arcane Shot' then assert(row.hint:find('six seconds')) end
 if row.key=='Disengage' then assert(row.hint:find('threat')) end
end
print('October 15 guide audit: talent fallbacks, priorities, AoE/healing branches and hunter conditions: passed')
`);

run(`
-- Feed the actual Forever trait schema through login, UI and gear context updates.
local activeGroup=1
local totals={{9,0,0},{0,0,6}}
local available=true
local nativeReads=0
local function reading() assert(not combat); nativeReads=nativeReads+1 end
C_SpecializationInfo={GetActiveSpecGroup=function() reading(); return activeGroup end,
 GetCombatConfigIDForSpecGroup=function(g) reading(); return available and g*100 or nil end,
 GetSpecializationInfo=function(i) return i,'Tree',nil,nil,nil,nil,0 end}
C_Traits={GetConfigInfo=function(id) reading(); assert(id==activeGroup*100); return {treeIDs={77}} end,
 GetGroupDisplayInfoByTreeID=function() reading(); return {{groupID=31},{groupID=32},{groupID=33}} end,
 GetGroupCurrencyInfo=function(id)
  reading(); assert(id==activeGroup*100)
  local p=totals[activeGroup]
  return {{traitNodeGroupID=31,currencyInfos={{spent=p[1]}}},
   {traitNodeGroupID=32,currencyInfos={{spent=p[2]}}},
   {traitNodeGroupID=33,currencyInfos={{spent=p[3]}}}}
 end}
currentClass='SHAMAN'; currentLevel=18; EverfrostDB={spec=0}; fire('PLAYER_LOGIN')
local settings=NS.Settings.window
assert(EverfrostFrame.title.text=='Leveling  SHAMAN' and lastGearContext[2]==1)
assert(settings.pages.Guide.detected.text=='Detected: Elemental (9 / 0 / 0)')
assert(settings.pages.Gear.priorityTitle.text=='Stat priority: Elemental (talents)')
totals[1]={2,8,0}; fire('TRAIT_TREE_CURRENCY_INFO_UPDATED',77)
assert(lastGearContext[2]==2 and settings.pages.Guide.detected.text:find('2 / 8 / 0',1,true))
activeGroup=2; fire('ACTIVE_COMBAT_CONFIG_CHANGED',200); assert(lastGearContext[2]==3)
available=false; fire('TRAIT_CONFIG_UPDATED',200)
assert(lastGearContext[2]==0 and settings.pages.Gear.priority.text:find('unavailable'))
available=true; fire('TRAIT_CONFIG_UPDATED',200); assert(lastGearContext[2]==3)
combat=true; local before=nativeReads; totals[2]={8,0,0}; fire('TRAIT_CONFIG_UPDATED',200)
assert(nativeReads==before and lastGearContext[2]==3)
combat=false; fire('PLAYER_REGEN_ENABLED'); assert(lastGearContext[2]==1)
SlashCmdList.EVERFROST('spec auto'); assert(EverfrostFrame.title.text=='Elemental  SHAMAN')
SlashCmdList.EVERFROST('spec 2'); assert(lastGearContext[2]==2)
SlashCmdList.EVERFROST('status')
C_Traits=nil; C_SpecializationInfo=nil
print('Forever traits integration: native totals drive settings, automatic/Leveling gear, active-group changes, delayed data and combat refresh: passed')
`);

run(`
-- An older client can register the same launcher without the modern Settings API.
local originalNS,originalSettings,originalMinimap=NS,Settings,Minimap
NS={Call=originalNS.Call,Public=originalNS.Public,gearLevelNote=originalNS.gearLevelNote,trees={MAGE={'Arcane','Fire','Frost'}}}
Settings=nil; Minimap=nil
function InterfaceOptions_AddCategory(panel) legacyPanel=panel end
`);
load('Settings.lua');
run(`
local saved={scale=1.4,minimap=false,minimapAngle=90}
NS.CreateSettings({DB=function() return saved end,Command=function(value) legacyCommand=value end,
 SelectGuide=function(value) saved.spec=value; NS.Settings:Refresh() end,ToggleRole=function() end,CloseGuide=function() end,
 State=function() return {class='MAGE',className='Mage',level=18,detected='Fire',roleLabel='Damage',hasRole=false} end})
assert(legacyPanel==NS.Settings.gamePanel and legacyPanel.name=='Everfrost' and NS.Settings.minimap==nil)
NS.Settings.gameButton.scripts.OnClick(); assert(NS.Settings.window:IsShown())
assert(NS.Settings.window.pages.Panel.scale.text=='140%')
local row=NS.Settings.window.pages.Guide.rows[5]; row.scripts.OnClick(row); assert(saved.spec==3)
print('Legacy native settings registration and missing minimap fallback: passed')
`);

const packageVersion = require('../package.json').version;
for (const toc of ['addon/Everfrost/Everfrost.toc', 'Everfrost-Source.toc']) {
  const metadata = require('fs').readFileSync(toc, 'utf8');
  assert(metadata.includes('## Version: ' + packageVersion));
  assert(metadata.includes('## Interface: 16001'));
}
