const fs = require('fs');
const assert = require('node:assert/strict');
const path = require('path');
const parser = require('luaparse');
const {lua, lauxlib, lualib, to_luastring, to_jsstring} = require('fengari');
const root = path.resolve(__dirname, '../addon/Everfrost');
const sources = {};
for (const name of ['Profiles.lua','Core.lua','GearProfiles.lua','Gear.lua','GearUI.lua','TalentData.lua','Talents.lua','Settings.lua','Main.lua']) {
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
  for _,level in ipairs({1,5,6,10,19,20,21,24,25,29,30,31,39,40,44,59,60,61}) do
   for _,mode in ipairs({'single','aoe'}) do
    for _,role in ipairs({'damage','heal','bear','melee','ranged'}) do
     local rows=NS.BuildRows(class,spec,level,known,mode,role)
     -- Three rows of six at most, so the panel stays compact with every spell learned.
     if #rows>(MAXROWS or 0) then MAXROWS=#rows; MAXWHERE=class..spec..' '..level..' '..mode..' '..role end
     assert(#rows<=15,class..spec..' '..level..' '..mode..' '..role..' '..#rows)
     for _,row in ipairs(rows) do assert(known[row.key] and row.hint) end
     if level==61 then assert(#rows==0) end
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
-- Localized names are cached only after every known spell ID has resolved.
local lookups,resolve=0,false
local originalInfo=C_Spell.GetSpellInfo
C_Spell.GetSpellInfo=function(id) lookups=lookups+1; if resolve then return {name='Loc'..id} end end
local partial=NS.SpellNames('PRIEST'); local firstPass=lookups
assert(partial.Smite=='Smite' and firstPass>0)
NS.SpellNames('PRIEST'); assert(lookups==2*firstPass)
resolve=true; local names=NS.SpellNames('PRIEST'); local resolved=lookups
assert(names.Loc585=='Smite' and names.Smite=='Smite')
assert(NS.SpellNames('PRIEST')==names and lookups==resolved)
C_Spell.GetSpellInfo=originalInfo
print('Spell name cache: incomplete localization retried, complete map reused: passed')
frames={}; currentLevel=5; currentClass='PALADIN'
local methods={}
function methods:SetScript(e,cb) self.scripts[e]=cb end
function methods:GetScript(e) return self.scripts[e] end
function methods:GetFrameLevel() return 1 end
function methods:SetScale(v) self.scale=v end
function methods:SetAlpha(v) self.alpha=v end
function methods:SetBackdrop(v) self.backdrop=v end
function methods:GetScale() return self.scale or 1 end
function methods:GetLeft() return self.left end
function methods:GetTop() return self.top end
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
-- Events are gathered into one refresh on the next frame; flush() is that frame.
function flush() for _,f in ipairs(frames) do local update=f.scripts.OnUpdate; if update then update(f) end end end
-- Each login in these tests is a different pretend character on a fresh account, unless a test
-- sets keepAccount to check what carries over between characters.
function dispatch(e,value)
 if e=='PLAYER_LOGIN' and not keepAccount then EverfrostAccountDB=nil end
 for _,f in ipairs(frames) do if f.events[e] then f.scripts.OnEvent(f,e,value) end end
end
function fire(e,value) dispatch(e,value); flush() end
function visibleSpells() local n=0; for _,f in ipairs(frames) do if rawget(f,'spellID') and f:IsShown() then n=n+1 end end; return n end
duration={}; C_Spell.GetSpellCooldownDuration=function() return duration end
EverfrostDB={scale=1.2,locked=true,point='CENTER',relativePoint='CENTER',x=100,y=40}
GetTalentTabInfo=function(i) return 'Tree',nil,({0,0,2})[i] end
`);
load('GearProfiles.lua');
load('TalentData.lua');
load('Talents.lua');
run(`
NS.Gear={SetContext=function(...) lastGearContext={...} end,Schedule=function() gearScheduled=true end,Paint=function() end}
`);
load('Settings.lua');
load('Main.lua');
run(`
fire('PLAYER_LOGIN'); local f=EverfrostFrame
assert(f.title.text=='Retribution PALADIN' and f.meta.text:find('5'))
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
assert(EverfrostDB.spec==0 and window.pages.Gear.priority.text:find('Weapon DPS',1,true)==1)
assert(window.pages.Gear.priorityTitle.text=='Starter priority: PALADIN')
assert(window.pages.Gear.levelNote.text==NS.gearLevelNote)
-- Empty slots reach both the settings page and, for a missing weapon, the panel caption.
NS.Gear.EmptySlots=function() return true,2 end
local mainRefresh=NS.Gear.OnRefreshed; assert(mainRefresh); mainRefresh()
assert(f.caption.text=='No weapon equipped: check your bags or a vendor')
assert(window.pages.Gear.empty.text=='No weapon equipped. 2 empty armour slots.')
NS.Gear.EmptySlots=function() return false,1 end; mainRefresh()
assert(f.caption.text=='Hover a spell for its place in the rotation' and window.pages.Gear.empty.text=='1 empty armour slot.')
NS.Gear.EmptySlots=function() return false,0 end; mainRefresh(); assert(window.pages.Gear.empty.text=='')
NS.Gear.EmptySlots=nil
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
assert(f.guideMenu.rows[1].check:IsShown() and f.guideMenu.rows[1].label.text=='Automatic (Retribution)')
assert(f.guideMenu.footer:IsShown() and f.guideMenu.footer.text=='Full stat priorities need talents.')
f.guideMenu.rows[2].scripts.OnClick()
assert(EverfrostDB.spec==0 and f.title.text=='Levelling PALADIN' and lastGearContext[2]==0)
assert(not f.guideMenu:IsShown() and not f.guideCatcher:IsShown())
f.guide.scripts.OnClick(); assert(f.guideMenu.rows[2].check:IsShown())
f.guideMenu.rows[3].scripts.OnClick(); assert(EverfrostDB.spec==1 and f.title.text=='Holy PALADIN')
f.guide.scripts.OnClick(); f.guideCatcher.scripts.OnClick(); assert(not f.guideMenu:IsShown())
cmd('spec auto'); assert(EverfrostDB.spec==nil and f.title.text=='Retribution PALADIN')
combat=true; f.guide.scripts.OnClick(); assert(f.guideMenu.footer.text=='Changes apply after combat.'); f.guideMenu.rows[4].scripts.OnClick()
assert(EverfrostDB.spec==2 and f.title.text=='Retribution PALADIN' and f.meta.text:find('Pending'))
assert(window.status.text:find('Changes after combat') and not window.pages.Gear.rescan.enabled)
combat=false; fire('PLAYER_REGEN_ENABLED'); assert(f.title.text=='Protection PALADIN' and lastGearContext[2]==0)
cmd('spec leveling'); fire('PLAYER_ENTERING_WORLD')
assert(f.title.text=='Levelling PALADIN' and EverfrostDB.spec==0)
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
fire('PLAYER_LEVEL_UP',60); assert(visibleSpells()>0); fire('PLAYER_LEVEL_UP',61); assert(f.empty.text=='Level 1-60 guide')
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
assert(EverfrostFrame.title.text=='Levelling SHAMAN' and lastGearContext[2]==0)
assert(window.pages.Gear.priorityTitle.text=='Starter priority: SHAMAN' and window.pages.Gear.priority.text==NS.GearPriorityText(NS.gearStarter.SHAMAN))
cmd('spec 1'); assert(EverfrostDB.spec==1 and lastGearContext[2]==0)
cmd('spec leveling')
fire('PLAYER_LEVEL_UP',10)
assert(EverfrostDB.spec==0 and EverfrostFrame.title.text=='Levelling SHAMAN' and lastGearContext[2]==2)
assert(window.pages.Gear.priorityTitle.text=='Stat priority: Enhancement (talents)')
assert(window.pages.Gear.priority.text:find('Weapon DPS',1,true)==1)
talentPoints={4,2,0}; fire('PLAYER_TALENT_UPDATE')
assert(lastGearContext[2]==1 and window.pages.Gear.priorityTitle.text=='Stat priority: Elemental (talents)')
assert(window.pages.Gear.priority.text:find('Spell power',1,true)==1)
cmd('spec 3'); assert(lastGearContext[2]==3 and EverfrostDB.spec==3)
cmd('spec leveling'); assert(lastGearContext[2]==1 and EverfrostDB.spec==0)
cmd('spec auto'); cmd('spec levelling'); assert(lastGearContext[2]==1 and EverfrostDB.spec==0)
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
-- With no form learned there is no Cat or Bear to choose, and a saved Bear view cannot empty the panel.
assert(not EverfrostFrame.role:IsShown())
book={{spellID=5176,name='Wrath'}}; EverfrostDB.role='bear'; fire('SPELLS_CHANGED')
assert(visibleSpells()==1 and EverfrostFrame.role.text=='Caster' and not EverfrostFrame.role:IsShown())
EverfrostDB.role=nil
-- A burst of spell, talent and trait events becomes one rescan and redraw on the next frame.
local scans=0; local skillLines=C_SpellBook.GetNumSpellBookSkillLines
C_SpellBook.GetNumSpellBookSkillLines=function(...) scans=scans+1; return skillLines(...) end
for i=1,50 do dispatch('SPELLS_CHANGED'); dispatch('SPELL_DATA_LOAD_RESULT',i,true); dispatch('TRAIT_CONFIG_UPDATED') end
assert(scans==0); flush(); assert(scans==1); flush(); assert(scans==1)
C_SpellBook.GetNumSpellBookSkillLines=skillLines
-- Past the last guide level the panel steps aside once, with one line in chat, and can be brought back.
local said={}; local realPrint=print; print=function(line) said[#said+1]=line end
fire('PLAYER_LEVEL_UP',61)
assert(not EverfrostFrame:IsShown() and #said==1 and said[1]:find('/everfrost show',1,true) and EverfrostDB.pastGuideNoted)
fire('SPELLS_CHANGED'); assert(#said==1 and not EverfrostFrame:IsShown())
cmd('show'); assert(EverfrostFrame:IsShown() and EverfrostDB.showPastGuide and EverfrostFrame.empty.text=='Level 1-60 guide')
cmd('hide'); assert(not EverfrostFrame:IsShown())
fire('PLAYER_LEVEL_UP',10); cmd('show'); assert(EverfrostFrame:IsShown())
-- /everfrost spellids lists what the spellbook has for guide spells with no ID on record.
book={{spellID=777,name='Primal Bite'},{spellID=5487,name='Bear Form'}}; fire('SPELLS_CHANGED'); said={}
cmd('spellids'); assert(said[1]:find('Primal Bite=777',1,true) and not said[1]:find('Bear Form',1,true))
print=realPrint
-- The key binding shows and hides the panel.
EverfrostTogglePanel(); assert(not EverfrostFrame:IsShown() and EverfrostDB.hidden==true)
EverfrostTogglePanel(); assert(EverfrostFrame:IsShown() and EverfrostDB.hidden==false)
assert(BINDING_HEADER_EVERFROST=='Everfrost' and BINDING_NAME_EVERFROST_TOGGLE)
-- A new character starts with the look last used on another one; its guide choices and position are its own.
keepAccount=true
cmd('scale 1.4'); cmd('opacity 70'); cmd('minimap off'); cmd('gear off'); cmd('lock'); EverfrostDB.spec=2; EverfrostDB.x=55
EverfrostDB={}; fire('PLAYER_LOGIN')
assert(EverfrostDB.scale==1.4 and EverfrostDB.opacity==0.7 and EverfrostDB.minimap==false and EverfrostDB.gear==false and EverfrostDB.locked==true)
assert(EverfrostDB.spec==nil and EverfrostDB.x==nil)
-- An existing character keeps its own settings, whatever the account last used.
EverfrostDB={scale=0.8,opacity=1}; fire('PLAYER_LOGIN'); assert(EverfrostDB.scale==0.8 and EverfrostDB.minimap==nil)
-- Damaged account data is ignored rather than trusted.
EverfrostAccountDB={scale='big',opacity=99,gear='yes',locked='no'}; EverfrostDB={}; fire('PLAYER_LOGIN')
assert(EverfrostDB.scale==1 and EverfrostDB.opacity==1 and EverfrostDB.gear==nil and EverfrostDB.locked==nil)
keepAccount=nil; EverfrostAccountDB=nil; EverfrostDB={}; fire('PLAYER_LOGIN')
print('Event batching, past-level-30 panel, Feral view choice, spell ID report, key binding and account-wide look: passed')
-- Talent builds: every class has three builds of 51 points, level 10 to 60, within each talent's ranks.
local T=NS.Talents
for class,data in pairs(NS.talentData) do
 assert(NS.trees[class] and #data.builds==3)
 for spec=1,3 do
  local plan=T.Plan(class,spec)
  assert(#plan.picks==51 and plan.picks[1].level==10 and plan.picks[51].level==60)
  for k,talent in pairs(plan.talents) do
   local letter; for l,name in pairs(data.names) do if T.Key(name)==k then letter=l end end
   assert(letter and #talent.levels<=data.ranks[letter],class..spec..' '..k)
  end
 end
end
assert(T.Plan('WARRIOR',0)==nil and T.Plan('DEATHKNIGHT',1)==nil and T.Key("Nature's Grasp")=='naturesgrasp')
-- Arms takes Improved Rend at 10, 11 and 12, then Deflection at 13 and 14.
local arms=T.Plan('WARRIOR',1)
assert(arms.picks[1].name=='Improved Rend' and arms.picks[3].rank==3 and arms.picks[4].name=='Deflection' and arms.picks[4].level==13)
-- Talents taken are read from the trait tree, by name, never in combat.
local taken={['Improved Rend']=2,['Deflection']=0,['Improved Overpower']=0,['Improved Charge']=0,['Mortal Strike']=0}
local nodeNames={}; for name in pairs(taken) do nodeNames[#nodeNames+1]=name end; table.sort(nodeNames)
local savedTraits,savedClassTalents=C_Traits,C_ClassTalents
C_ClassTalents={GetActiveConfigID=function() assert(not combat); return 7 end}
C_Traits={GetConfigInfo=function(id) assert(id==7); return {treeIDs={1}} end,
 GetTreeNodes=function() local ids={}; for index in ipairs(nodeNames) do ids[index]=index end; return ids end,
 GetNodeInfo=function(_,node) return {ranksPurchased=taken[nodeNames[node]],activeEntry={entryID=node+100}} end,
 GetEntryInfo=function(_,entry) return {definitionID=entry+100} end,
 GetDefinitionInfo=function(definition) return {overrideName=nodeNames[definition-200]} end}
T.enabled=true; T.Refresh('WARRIOR',1,12,'Arms')
assert(T.state.next.name=='Improved Rend' and T.state.next.rank==3 and T.state.index==3)
assert(T.Summary()=='Next talent, Icy Veins Arms build: Improved Rend 3/3')
-- A point the guide takes later says when.
taken['Improved Rend']=3; T.Refresh('WARRIOR',1,12,'Arms')
assert(T.Summary()=='Next talent, Icy Veins Arms build: Deflection 1/2 (the guide takes it at level 13)')
local upcoming=T.Upcoming(3); assert(upcoming[1]=='13: Deflection' and upcoming[2]=='14: Deflection' and #upcoming==3)
-- A talent the client names differently is passed over rather than recommended for ever.
local kept=taken['Deflection']; taken['Deflection']=nil; nodeNames={}; for name in pairs(taken) do nodeNames[#nodeNames+1]=name end; table.sort(nodeNames)
T.Refresh('WARRIOR',1,12,'Arms'); assert(T.state.next.name=='Improved Overpower')
taken['Deflection']=kept; nodeNames={}; for name in pairs(taken) do nodeNames[#nodeNames+1]=name end; table.sort(nodeNames)
-- Restricted values and combat leave nothing to say, and nothing is read.
local realNode=C_Traits.GetNodeInfo
C_Traits.GetNodeInfo=function() return {ranksPurchased='SECRET',activeEntry={entryID=101}} end
T.Refresh('WARRIOR',1,12,'Arms'); assert(T.state.ranks==nil and T.Summary()==nil)
C_Traits.GetNodeInfo=realNode
combat=true; assert(T.Read()==nil); combat=false
-- The talent window: the next talent's button is highlighted, and every button explains itself.
local glowing={}
NS.Glow=function(button,shown) glowing[button]=shown or nil end
local function talentButton(node)
 local b=CreateFrame('Button'); b.hooks={}
 function b:GetNodeID() return node end
 function b:HookScript(name,fn) self.hooks[name]=fn end
 return b
end
local talentButtons={}; for index in ipairs(nodeNames) do talentButtons[index]=talentButton(index) end
local shownHooks={}
PlayerSpellsFrame={TalentsFrame={EnumerateAllTalentButtons=function() return pairs(talentButtons) end,
 HookScript=function(_,name,fn) shownHooks[name]=fn end}}
T.Refresh('WARRIOR',1,13,'Arms'); T.Show()
local function buttonFor(name) for index,n in ipairs(nodeNames) do if n==name then return talentButtons[index] end end end
assert(glowing[buttonFor('Deflection')]==true and not glowing[buttonFor('Improved Rend')] and shownHooks.OnShow)
local lines={}; GameTooltip.AddLine=function(_,text) lines[#lines+1]=text end
buttonFor('Deflection').hooks.OnEnter(buttonFor('Deflection'))
assert(lines[2]:find('puts 2 points here, at level 13, 14',1,true) and lines[3]=='Your next point goes here.')
lines={}; buttonFor('Mortal Strike').hooks.OnEnter(buttonFor('Mortal Strike'))
assert(lines[2]:find('puts 1 point here, at level 40',1,true) and #lines==2)
-- Turning recommendations off clears the highlight and the tooltip lines.
T.enabled=false; T.Refresh('WARRIOR',1,13,'Arms'); assert(not glowing[buttonFor('Deflection')] and T.Summary()==nil)
lines={}; buttonFor('Deflection').hooks.OnEnter(buttonFor('Deflection')); assert(#lines==0)
T.enabled=true
-- The older numbered-talent API works too.
C_Traits=nil; C_ClassTalents=nil; PlayerSpellsFrame=nil
GetNumTalentTabs=function() return 1 end; GetNumTalents=function() return 2 end
GetTalentInfo=function(tab,index) return ({'Improved Rend','Deflection'})[index],nil,1,index,({3,1})[index],({3,5})[index] end
T.Refresh('WARRIOR',1,14,'Arms'); assert(T.state.next.name=='Deflection' and T.state.next.rank==2)
GetNumTalentTabs=nil; GetNumTalents=nil; GetTalentInfo=nil
-- In the addon: the panel's hover text, the settings page and /everfrost talents all carry the next talent.
C_ClassTalents={GetActiveConfigID=function() return 7 end}
C_Traits={GetConfigInfo=function() return {treeIDs={1}} end,GetTreeNodes=function() return {1} end,
 GetNodeInfo=function() return {ranksPurchased=1,activeEntry={entryID=1}} end,GetEntryInfo=function() return {definitionID=1} end,
 GetDefinitionInfo=function() return {overrideName='Improved Rend'} end}
currentClass='WARRIOR'; currentLevel=11; EverfrostDB={spec=1}; fire('PLAYER_LOGIN')
assert(NS.Settings.window.pages.Guide.note.text:find('Next talent, Icy Veins Arms build: Improved Rend 2/3',1,true))
local said={}; local realPrint=print; print=function(line) said[#said+1]=line end
cmd('talents'); assert(said[1]:find('Improved Rend 2/3',1,true))
cmd('talents off'); assert(EverfrostDB.talents==false and not NS.Settings.window.pages.Guide.note.text:find('Next talent',1,true))
said={}; cmd('talents'); assert(said[1]:find('OFF',1,true))
cmd('talents on'); assert(NS.Settings.window.pages.Guide.note.text:find('Next talent',1,true))
print=realPrint
C_Traits=savedTraits; C_ClassTalents=savedClassTalents
print('Talent builds: data, next pick from trait and numbered APIs, name mismatches, secrets, talent-window highlight and tooltips, on/off: passed')
-- Dragging the corner resizes the panel about its top-left corner, within 60% to 200%.
EverfrostDB={}; fire('PLAYER_LOGIN'); local panel=EverfrostFrame; local grip=panel.grip
assert(grip:IsShown() and panel.scale==1)
panel.left=100; panel.top=500; cursorX,cursorY=420,300
grip.scripts.OnMouseDown(grip); assert(grip.Resizing() and grip.scripts.OnUpdate)
cursorX,cursorY=580,200; grip.scripts.OnUpdate(grip)
assert(EverfrostDB.scale==1.5 and panel.scale==1.5 and EverfrostDB.point=='TOPLEFT' and EverfrostDB.relativePoint=='BOTTOMLEFT')
assert(math.abs(EverfrostDB.x-100/1.5)<0.001 and math.abs(EverfrostDB.y-500/1.5)<0.001)
cursorX,cursorY=3000,-3000; grip.scripts.OnUpdate(grip); assert(EverfrostDB.scale==2)
cursorX,cursorY=101,499; grip.scripts.OnUpdate(grip); assert(EverfrostDB.scale==0.6)
grip.scripts.OnMouseUp(grip); assert(not grip.Resizing() and grip.scripts.OnUpdate==nil and EverfrostAccountDB.scale==0.6)
assert(NS.Settings.window.pages.Panel.scale.text=='60%')
-- A locked panel has no corner to drag, and nothing resizes in combat.
cmd('lock'); assert(not grip:IsShown()); grip.scripts.OnMouseDown(grip); assert(not grip.Resizing())
cmd('unlock'); assert(grip:IsShown()); combat=true; grip.scripts.OnMouseDown(grip); assert(not grip.Resizing()); combat=false
cursorX,cursorY=100,200; EverfrostDB={}; fire('PLAYER_LOGIN')
print('Resize corner: scales about the top-left corner, clamps, saves, respects lock and combat: passed')
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
assert(NS.maxLevel==60)
local spells=learned('Slam','Spearing Strike','Holy Shock','Stormstrike','Swiftmend','Insect Swarm','Summon Hawk','Hellfire','Conflagrate','Immolate','Hemorrhage','Backstab','Sinister Strike','Rupture','Strider Kick','Raptor Strike','Auto Shot')
assert(not has('WARRIOR',1,19,spells,'Slam')); assert(has('WARRIOR',1,20,spells,'Slam'))
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
-- Below 30 Survival has one view, so there is no button to press.
assert(EverfrostFrame.role.text=='Ranged' and not EverfrostFrame.role:IsShown())
assert(NS.Settings.window.pages.Guide.role:IsShown()==false)
fire('PLAYER_LEVEL_UP',30); assert(EverfrostFrame.role.text=='Melee' and EverfrostFrame.role:IsShown())
assert(NS.Settings.window.pages.Guide.role:IsShown()==true)
SlashCmdList.EVERFROST('ranged'); assert(EverfrostFrame.role.text=='Ranged')
SlashCmdList.EVERFROST('melee'); assert(EverfrostFrame.role.text=='Melee')
book[1].future=true; fire('SPELLS_CHANGED'); assert(EverfrostFrame.role.text=='Ranged' and not EverfrostFrame.role:IsShown())
print('Level 21-30 additions, rank level gates, spec isolation, talent removal and Survival transition: passed')
-- Levels 31-60: each tree's later abilities appear once learned, in the right view, and only for that tree.
local late=learned('Mortal Strike','Sweeping Strikes','Whirlwind','Bloodthirst','Shield Slam','Execute','Thunder Clap','Rend','Slam','Charge','Cleave',
 'Sunder Armor','Death Wish','Hammer of Wrath','Consecration','Holy Shock',"Light's Vigil",'Sniper Shot','Serpent Sting','Multi-Shot','Explosive Trap','Volley',
 'Strider Kick','Raptor Strike','Mongoose Bite','Arcane Shot','Frostfire Bolt','Scorch','Fire Blast','Arcane Wrath','Frostbolt','Frost Nova','Ice Barrier',
 'Cheap Shot','Stealth','Ghostly Strike','Shank','Hemorrhage','Penance','Smite','Power Word: Shield','Wrack','Drain Life','Searing Pain','Incinerate','Immolate',
 'Starfire','Hurricane','Wrath','Cat Form','Bear Form','Ravage','Rake','Rip','Faerie Fire','Lacerate','Primal Bite','Enrage','Tranquility','Innervate','Regrowth',
 'Chain Lightning','Lightning Bolt','Lightning Mastery','Water Shield','Rage of the Farseer','Stormstrike','Riptide','Chain Heal','Mana Tide Totem','Healing Stream Totem')
local function order(class,spec,level,first,second,mode,role)
 local at={}
 for index,row in ipairs(NS.BuildRows(class,spec,level,late,mode or 'single',role or 'damage')) do at[row.key]=index end
 return at[first] and at[second] and at[first]<at[second]
end
assert(has('WARRIOR',1,40,late,'Mortal Strike') and not has('WARRIOR',2,40,late,'Mortal Strike') and order('WARRIOR',1,40,'Slam','Mortal Strike'))
assert(has('WARRIOR',1,40,late,'Sweeping Strikes','aoe') and not has('WARRIOR',1,40,late,'Sweeping Strikes','single'))
assert(order('WARRIOR',2,40,'Whirlwind','Bloodthirst') and not has('WARRIOR',1,40,late,'Bloodthirst'))
assert(has('WARRIOR',3,40,late,'Shield Slam') and not has('WARRIOR',3,40,late,'Execute') and has('WARRIOR',0,40,late,'Execute'))
assert(not has('PALADIN',3,43,late,'Hammer of Wrath') and has('PALADIN',3,44,late,'Hammer of Wrath') and not has('PALADIN',2,60,late,'Hammer of Wrath'))
assert(has('PALADIN',1,52,late,"Light's Vigil",'single','heal') and not has('PALADIN',1,52,late,"Light's Vigil",'single','damage'))
assert(has('HUNTER',2,40,late,'Sniper Shot') and not has('HUNTER',1,40,late,'Sniper Shot'))
assert(has('HUNTER',1,40,late,'Volley','aoe') and not has('HUNTER',1,40,late,'Volley','single'))
assert(order('HUNTER',3,40,'Arcane Shot','Raptor Strike','single','melee') and has('HUNTER',3,40,late,'Explosive Trap','aoe','melee'))
assert(order('MAGE',2,40,'Frostfire Bolt','Scorch') and not has('MAGE',3,40,late,'Scorch') and has('MAGE',1,40,late,'Arcane Wrath'))
assert(has('MAGE',3,40,late,'Ice Barrier','aoe'))
for spec=0,3 do assert(order('ROGUE',spec,30,'Stealth','Cheap Shot')) end
assert(order('ROGUE',3,40,'Hemorrhage','Ghostly Strike') and not has('ROGUE',2,40,late,'Shank'))
assert(has('PRIEST',1,30,late,'Penance') and has('PRIEST',1,30,late,'Penance','single','heal') and not has('PRIEST',2,30,late,'Penance'))
assert(has('WARLOCK',1,51,late,'Wrack') and not has('WARLOCK',3,51,late,'Wrack'))
assert(has('WARLOCK',2,25,late,'Searing Pain') and order('WARLOCK',3,40,'Immolate','Incinerate'))
assert(has('DRUID',1,40,late,'Starfire') and not has('DRUID',3,40,late,'Starfire'))
assert(not has('DRUID',1,39,late,'Hurricane','aoe') and has('DRUID',1,40,late,'Hurricane','aoe') and has('DRUID',3,40,late,'Hurricane','aoe'))
assert(order('DRUID',2,40,'Cat Form','Ravage') and order('DRUID',2,40,'Rip','Rake') and order('DRUID',2,40,'Primal Bite','Lacerate','single','bear'))
assert(has('DRUID',3,40,late,'Innervate','single','heal') and not has('DRUID',3,39,late,'Innervate','single','heal'))
assert(has('SHAMAN',1,40,late,'Lightning Mastery','aoe') and has('SHAMAN',1,40,late,'Chain Lightning','aoe') and not has('SHAMAN',1,40,late,'Chain Lightning','single'))
assert(has('SHAMAN',2,40,late,'Rage of the Farseer') and order('SHAMAN',3,40,'Riptide','Chain Heal','single','heal'))
-- The shared lists stay separate: one tree's addition never leaks into another or into the base guide.
assert(not has('HUNTER',0,60,late,'Sniper Shot') and not has('WARRIOR',0,60,late,'Mortal Strike') and not has('DRUID',0,60,late,'Starfire'))
print('Level 31-60 additions: tree-specific abilities, views, order, level gates and shared-list isolation: passed')
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
assert(EverfrostFrame.title.text=='Levelling SHAMAN' and lastGearContext[2]==1)
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
SlashCmdList.EVERFROST('spec auto'); assert(EverfrostFrame.title.text=='Elemental SHAMAN')
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

// CurseForge packages the whole repository as Everfrost-Source, then moves the
// addon out. Any top-level file it keeps (CLAUDE.md in 0.6.3) leaves a folder
// without a .toc, and CurseForge rejects the upload.
{
  const repo = path.resolve(__dirname, '..');
  const pkgmeta = fs.readFileSync(path.join(repo, '.pkgmeta'), 'utf8');
  const ignoreBlock = pkgmeta.split(/^ignore:\s*$/m)[1].split(/^\S/m)[0];
  const ignored = new Set([...ignoreBlock.matchAll(/^\s*-\s*(.+?)\s*$/gm)].map(m => m[1]));
  // Dotfiles are excluded by CurseForge; addon/Everfrost is moved to Everfrost.
  const packaged = fs.readdirSync(repo).filter(name => !name.startsWith('.') && name !== 'addon' && !ignored.has(name));
  assert.deepEqual(packaged, [], 'Add these to .pkgmeta ignore: ' + packaged.join(', '));
  assert.deepEqual(fs.readdirSync(path.join(repo, 'addon')), ['Everfrost']);
  console.log('CurseForge packaging: only addon/Everfrost is packaged: passed');
}

// Guide spells are matched to the spellbook by name. An ID lets a non-English client find the
// localised name; without one the step only appears in English. These are spells new to WoW Forever,
// whose IDs have to be read in game (/everfrost spellids). Give a new guide spell an ID where it has
// a known one rather than adding to this list.
{
  const ids = new Set([...sources['Core.lua'].matchAll(/\["([^"]+)"\]=\d+/g)].map(m => m[1]));
  const names = new Set([...sources['Profiles.lua'].matchAll(/S\("([^"]+)"/g)].map(m => m[1]));
  const missing = [...names].filter(name => !ids.has(name)).sort();
  assert.deepEqual(missing, ['Arcane Wrath', 'Bane of Agony', 'Bane of Havoc', 'Fire Nova', 'Holy Strike', "Light's Vigil",
    'Lightning Mastery', 'Primal Bite', 'Rage of the Farseer', 'Seal of Fury', 'Shank', 'Shifting Power', 'Sniper Shot',
    'Spearing Strike', 'Strider Kick', 'Summon Hawk', 'Wrack'], 'Guide spells without an ID in Core.lua baseIDs');
  console.log('Guide spell IDs: no new English-only spells: passed');
}

const packageVersion = require('../package.json').version;
for (const toc of ['addon/Everfrost/Everfrost.toc', 'Everfrost-Source.toc']) {
  const metadata = require('fs').readFileSync(toc, 'utf8');
  assert(metadata.includes('## Version: ' + packageVersion));
  assert(metadata.includes('## Interface: 16001'));
}
