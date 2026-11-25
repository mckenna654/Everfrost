// Talent recommendations (addon/Everfrost/Talents.lua) against mocked Forever trait APIs and a
// mocked talent window, in fengari. Simulated only: this does not prove the game behaves this way.
const fs = require('fs');
const path = require('path');
const parser = require('luaparse');
const {lua, lauxlib, lualib, to_luastring, to_jsstring} = require('fengari');
const root = path.resolve(__dirname, '../addon/Everfrost');
const sources = {};
for (const name of ['Core.lua', 'TalentData.lua', 'Talents.lua']) {
  sources[name] = fs.readFileSync(path.join(root, name), 'utf8');
  parser.parse(sources[name], {luaVersion: '5.1'});
}
const L = lauxlib.luaL_newstate(); lualib.luaL_openlibs(L);
function run(s) { if (lauxlib.luaL_dostring(L, to_luastring(s)) !== lua.LUA_OK) throw Error(to_jsstring(lua.lua_tostring(L, -1))); }
function load(name) { run(`local function loadAddon(...)\n${sources[name]}\nend\nloadAddon('Everfrost',NS)`); }
let passed = 0;
function test(title, body) { run(`do\n${body}\nend`); passed++; console.log(title + ': passed'); }

run(`
NS={}
function issecretvalue(v) return v=='SECRET' end
combat=false
function InCombatLockdown() return combat end
-- Frames: enough of the widget API for overlays, with a count of what was made.
created={}
local methods={}
function methods:SetPoint(...) self.points[#self.points+1]={...} end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:SetFrameLevel(v) self.level=v end
function methods:GetFrameLevel() return self.level or 5 end
function methods:EnableMouse(v) self.mouse=v end
function methods:HookScript(name,fn) self.hooks[name]=self.hooks[name] or {}; table.insert(self.hooks[name],fn) end
function methods:CreateTexture() local t=newObject(); self.textures[#self.textures+1]=t; return t end
function methods:SetColorTexture(r,g,b,a) self.color={r,g,b,a} end
function methods:SetVertexColor(r,g,b,a) self.vertex={r,g,b,a} end
function methods:SetTexture(path) self.texture=path end
function methods:SetBlendMode(mode) self.blend=mode end
function methods:SetHeight(v) self.height=v end
function methods:SetWidth(v) self.width=v end
function methods:SetText(v) self.text=v end
function methods:SetTextColor(r,g,b) self.textColor={r,g,b} end
function methods:SetFromAlpha(v) self.from=v end
function methods:SetToAlpha(v) self.to=v end
function methods:SetDuration(v) self.duration=v end
function methods:CreateFontString(_,layer,template) local t=newObject(); t.template=template; self.fontStrings=self.fontStrings or {}; self.fontStrings[#self.fontStrings+1]=t; return t end
function methods:CreateAnimationGroup()
 local g=newObject(); self.groups[#self.groups+1]=g
 function g:Play() self.playing=true end
 function g:Stop() self.playing=false end
 function g:IsPlaying() return self.playing==true end
 function g:CreateAnimation() local a=newObject(); self.animation=a; return a end
 return g
end
function newObject() return setmetatable({points={},hooks={},textures={},groups={},shown=true},{__index=function(_,k) if methods[k] then return methods[k] end; if type(k)=='string' and k:match('^%u') then return function() end end end}) end
function CreateFrame(kind,name,parent)
 local f=newObject(); f.kind=kind; f.parent=parent; created[#created+1]=f
 if name then _G[name]=f end
 return f
end
GameTooltip=newObject(); lines={}
function GameTooltip:AddLine(text) lines[#lines+1]=text end
function tipFor(button) lines={}; for _,fn in ipairs(button.hooks.OnEnter or {}) do fn(button) end; return lines end
function overlaysOf(button) local n=0; for _,f in ipairs(created) do if f.parent==button then n=n+1 end end; return n end
function find(list,text) for _,line in ipairs(list) do if line:find(text,1,true) then return line end end end

-- A mocked trait tree holding every talent of a class: node IDs in name order, all purchasable.
-- Tests then change ranks, availability, edges, conditions and the unspent points.
function setup(class)
 nodes,byName,conds,groupSpent,points={},{},{},{},nil
 local names={}; for _,name in pairs(NS.talentData[class].names) do names[#names+1]=name end; table.sort(names)
 for id,name in ipairs(names) do
  local letter; for l,n in pairs(NS.talentData[class].names) do if n==name then letter=l end end
  nodes[id]={name=name,ranksPurchased=0,activeRank=0,maxRanks=NS.talentData[class].ranks[letter],isAvailable=true,isVisible=true,
   meetsEdgeRequirements=true,canPurchaseRank=true,conditionIDs={},groupIDs={31},visibleEdges={}}
  byName[name]=id
 end
 C_SpecializationInfo={GetActiveSpecGroup=function() assert(not combat); return 1 end,GetCombatConfigIDForSpecGroup=function(g) return g==1 and 9 or 8 end}
 C_Traits={
  GetConfigInfo=function(id) assert(id==9); return {treeIDs={1}} end,
  GetTreeNodes=function() local ids={}; for id in ipairs(nodes) do ids[id]=id end; return ids end,
  GetNodeInfo=function(_,id) local n=nodes[id]; local copy={}; for k,v in pairs(n) do copy[k]=v end; copy.activeEntry={entryID=id+100}; copy.entryIDs={id+100}; return copy end,
  GetEntryInfo=function(_,entry) return {definitionID=entry+100} end,
  GetDefinitionInfo=function(definition) return {overrideName=nodes[definition-200].name} end,
  GetConditionInfo=function(_,id) return conds[id] end,
  GetTreeCurrencyInfo=function() if points then return {{quantity=points}} end; return {} end,
  GetGroupDisplayInfoByTreeID=function() return {{groupID=31,displayName='Main'},{groupID=32,displayName='Other'}} end,
  GetGroupCurrencyInfo=function(_,ids) local out={}; for _,id in ipairs(ids) do out[#out+1]={traitNodeGroupID=id,currencyInfos={{spent=groupSpent[id] or 0}}} end; return out end}
end
function take(name,rank) local n=nodes[byName[name]]; assert(n,name); n.ranksPurchased=rank; n.activeRank=rank end
-- Gives a player the build's first count points, as the guide spends them.
function follow(plan,count) for i=1,count do local p=plan.picks[i]; take(p.name,p.rank) end end
-- A mocked talent window: one pooled button per node, like the Forever TalentsFrame.
function window()
 local buttons={}
 for id in ipairs(nodes) do local b=CreateFrame('Button'); b.node=id; function b:GetNodeID() return self.node end; buttons[id]=b end
 shownConfig=9
 PlayerSpellsFrame={TalentsFrame=CreateFrame('Frame')}
 local frame=PlayerSpellsFrame.TalentsFrame
 function frame:EnumerateAllTalentButtons() local i=0; return function() i=i+1; while buttons[i] and buttons[i].released do i=i+1 end; return buttons[i] end end
 function frame:GetConfigID() return shownConfig end
 return buttons,frame
end
function glowing(buttons) local out={}; for id,b in ipairs(buttons) do local o=NS.Talents.Overlay(b); if o and o.shown then out[#out+1]=nodes[id].name end end; return out end
`);
load('Core.lua');
load('TalentData.lua');
load('Talents.lua');

test('Build data: every class has three 51-point builds, levels 10 to 60, within each talent\'s ranks', `
local T=NS.Talents
for class,data in pairs(NS.talentData) do
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
`);

test('First available talent at level 10', `
setup('WARRIOR'); local T=NS.Talents; T.enabled=true
T.Refresh('WARRIOR',1,10,'Arms')
assert(T.state.pick.name=='Improved Rend' and T.state.pick.rank==1 and not T.state.waiting)
assert(T.Summary()=='Next talent, Icy Veins Arms build: Improved Rend 1/3')
`);

test('Already allocated ranks are never pending', `
setup('WARRIOR'); local T=NS.Talents; local plan=T.Plan('WARRIOR',1)
take('Improved Rend',2); T.Refresh('WARRIOR',1,12,'Arms')
assert(T.state.pick.name=='Improved Rend' and T.state.pick.rank==3)
take('Improved Rend',3); points=1; T.Refresh('WARRIOR',1,13,'Arms')
assert(T.state.pick.name==plan.picks[4].name and T.state.pick.rank==1)
-- A talent already full (here a granted rank, none bought) is never pending.
local full=nodes[byName[plan.picks[4].name]]; full.maxRanks=1; full.activeRank=1; full.ranksPurchased=0
T.Refresh('WARRIOR',1,13,'Arms'); assert(T.state.pick.key~=plan.picks[4].key and T.state.next.key~=plan.picks[4].key)
-- The whole build taken.
setup('WARRIOR'); follow(plan,51); points=0; T.Refresh('WARRIOR',1,60,'Arms')
assert(T.state.complete and T.state.pick==nil and T.Summary()=='Talents: you have every point of the Icy Veins Arms build.')
`);

test('Locked prerequisite: passed over with the reason, next legal build talent suggested', `
setup('WARRIOR'); local T=NS.Talents; local plan=T.Plan('WARRIOR',1)
follow(plan,3); points=1
local blockedName=plan.picks[4].name
local id=byName[blockedName]
nodes[id].meetsEdgeRequirements=false; nodes[id].canPurchaseRank=false
-- Improved Rend leads to it, and that edge is not yet active.
table.insert(nodes[byName['Mortal Strike']].visibleEdges,{targetNode=id,type=3,isActive=false})
table.insert(nodes[byName['Improved Rend']].visibleEdges,{targetNode=id,type=0,isActive=false})
T.Refresh('WARRIOR',1,13,'Arms')
assert(T.state.next.name==blockedName and T.state.pick.name~=blockedName)
assert(T.state.blockedBy[T.Key(blockedName)]=='needs Mortal Strike first')
local summary=T.Summary()
assert(summary:find("The build's next pick, "..blockedName..", needs Mortal Strike first",1,true),summary)
local upcoming=T.Upcoming(3); assert(upcoming[1]=='13: '..blockedName..' (needs Mortal Strike first)',upcoming[1])
-- Without readable edges the reason stays general.
nodes[byName['Mortal Strike']].visibleEdges={}
T.Refresh('WARRIOR',1,13,'Arms'); assert(T.state.blockedBy[T.Key(blockedName)]=='needs its prerequisite first')
`);

test('Tier thresholds: a row gate names the points needed in that tree', `
setup('MAGE'); local T=NS.Talents; local plan=T.Plan('MAGE',3)
points=5
local target=plan.picks[1].name
local id=byName[target]
nodes[id].isAvailable=false; nodes[id].canPurchaseRank=false; nodes[id].conditionIDs={71,72}
conds[71]={isMet=false,isGate=true,spentAmountRequired=5,type=0}
conds[72]={isMet=false,isGate=true,spentAmountRequired=10,type=0}
groupSpent[31]=3
T.Refresh('MAGE',3,14,'Frost')
assert(T.state.blockedBy[T.Key(target)]=='needs 10 points spent in Main (you have 3)',T.state.blockedBy[T.Key(target)])
assert(T.state.pick and T.state.pick.key~=T.Key(target))
-- A gate that is met no longer blocks it.
conds[71].isMet=true; conds[72].isMet=true; nodes[id].isAvailable=true; nodes[id].canPurchaseRank=true
T.Refresh('MAGE',3,14,'Frost'); assert(T.state.pick.name==target and T.state.blocked[1]==nil)
-- Unavailable with no readable condition still says so.
nodes[id].isAvailable=false; nodes[id].conditionIDs={}
T.Refresh('MAGE',3,14,'Frost'); assert(T.state.blockedBy[T.Key(target)]=="isn't available yet")
`);

test('Level restrictions: no points means no highlight, and a level condition is named', `
setup('WARRIOR'); local T=NS.Talents; local plan=T.Plan('WARRIOR',1)
local buttons=window()
-- Level 12 with three points spent: nothing to spend until 13.
follow(plan,3); T.Refresh('WARRIOR',1,12,'Arms'); T.Show()
assert(T.state.points==0 and T.state.waiting and #glowing(buttons)==0)
assert(T.Summary()=='Next talent, Icy Veins Arms build: '..plan.picks[4].name..' 1/'..#plan.talents[plan.picks[4].key].levels..' (the guide takes it at level 13)')
local tip=tipFor(buttons[byName[plan.picks[4].name]])
assert(find(tip,'once you have a talent point'))
-- The client's own count of unspent points wins over the level estimate.
points=1; T.Refresh('WARRIOR',1,12,'Arms'); T.Show(); assert(#glowing(buttons)==1)
-- Behind the build with a point owed: say when the next point comes.
setup('WARRIOR'); buttons=window(); follow(plan,2); points=0
T.Refresh('WARRIOR',1,20,'Arms'); assert(T.Summary():find('your next talent point comes at level 21',1,true))
-- A rank held back by a level condition.
setup('WARRIOR'); buttons=window(); points=3
local id=byName['Improved Rend']; nodes[id].canPurchaseRank=false; nodes[id].conditionIDs={81}
conds[81]={isMet=false,isGate=false,type=5,playerLevel=12}
T.Refresh('WARRIOR',1,11,'Arms')
assert(T.state.blockedBy[T.Key('Improved Rend')]=='needs level 12' and T.state.pick.name==plan.picks[4].name)
`);

test('Respec and changing build: highlights follow the new talents', `
setup('WARRIOR'); local T=NS.Talents; local arms=T.Plan('WARRIOR',1); local fury=T.Plan('WARRIOR',2)
local buttons=window()
follow(arms,10); points=2; T.Refresh('WARRIOR',1,21,'Arms'); T.Show()
local before=T.state.pick; assert(glowing(buttons)[1]==before.name)
-- Reset every point: back to the start of the build.
for _,n in ipairs(nodes) do n.ranksPurchased=0; n.activeRank=0 end; points=12
T.Refresh('WARRIOR',1,21,'Arms'); T.Show()
local after=glowing(buttons); assert(#after==1 and after[1]=='Improved Rend')
-- Change to the Fury build.
T.Refresh('WARRIOR',2,21,'Fury'); T.Show()
after=glowing(buttons); assert(#after==1 and after[1]==fury.picks[1].name)
-- The other spec group's tab, or an inspected player, shows no highlight.
shownConfig=8; T.Show(); assert(#glowing(buttons)==0)
shownConfig=9; T.Show(); assert(#glowing(buttons)==1)
`);

test('Spending a point moves the highlight; levelling 10 to 60 always shows the next build pick', `
setup('PRIEST'); local T=NS.Talents; local plan=T.Plan('PRIEST',3)
local buttons=window()
for level=10,60 do
 points=1
 T.Refresh('PRIEST',3,level,'Shadow'); T.Show()
 local pick=plan.picks[level-9]
 assert(T.state.pick==pick,'level '..level)
 local g=glowing(buttons); assert(#g==1 and g[1]==pick.name)
 -- Spend it, as the window would, and let the window announce the update.
 take(pick.name,pick.rank); points=0
 T.Request()
 assert(#glowing(buttons)==0)
end
assert(T.state.complete and #glowing(buttons)==0)
`);

test('Deviation: points spent off-build, the build carries on with what is still legal', `
setup('WARRIOR'); local T=NS.Talents; local plan=T.Plan('WARRIOR',1)
-- Five points in Fury talents instead.
take('Cruelty',5); points=0; T.Refresh('WARRIOR',1,14,'Arms')
assert(T.state.pick.name=='Improved Rend' and T.state.waiting)
points=1; T.Refresh('WARRIOR',1,15,'Arms'); assert(T.state.pick.name=='Improved Rend' and not T.state.waiting)
-- Part of the build taken out of order: the earliest missing point comes first.
setup('WARRIOR'); take(plan.picks[4].name,2); points=3
T.Refresh('WARRIOR',1,14,'Arms'); assert(T.state.pick.name=='Improved Rend' and T.state.pick.rank==1)
take('Improved Rend',3); T.Refresh('WARRIOR',1,14,'Arms')
-- Both planned Deflection points are already in, so the build moves on to pick 6.
assert(plan.picks[5].key==plan.picks[4].key and T.state.pick==plan.picks[6])
-- A talent the client names differently is passed over rather than recommended for ever.
setup('WARRIOR'); nodes[byName['Improved Rend']].name='Improved Rend (renamed)'; points=1
T.Refresh('WARRIOR',1,10,'Arms'); assert(T.state.pick.name==plan.picks[4].name)
-- Everything left in the build locked: the summary says why.
setup('WARRIOR'); points=1
for _,n in ipairs(nodes) do n.isAvailable=false; n.canPurchaseRank=false end
T.Refresh('WARRIOR',1,10,'Arms')
assert(T.state.pick==nil and T.Summary()=="Next talent, Icy Veins Arms build: Improved Rend 1/3 isn't available yet.")
`);

test('Multiple classes: each class reads its own build', `
local T=NS.Talents
for _,case in ipairs({{'PALADIN',1,'Holy'},{'HUNTER',2,'Marksmanship'},{'MAGE',1,'Arcane'},{'ROGUE',3,'Subtlety'},{'DRUID',2,'Feral'},{'SHAMAN',3,'Restoration'},{'WARLOCK',1,'Affliction'}}) do
 local class,spec,tree=case[1],case[2],case[3]
 setup(class); local plan=T.Plan(class,spec)
 follow(plan,7); points=1
 T.Refresh(class,spec,17,tree)
 local expected=plan.picks[8]
 assert(T.state.pick==expected,class)
 assert(T.Summary():find('Icy Veins '..tree..' build: '..expected.name,1,true),T.Summary())
end
`);

test('Talent window: one overlay per button, reused after reopening, cleaned up on hide and refresh', `
setup('WARRIOR'); local T=NS.Talents; local plan=T.Plan('WARRIOR',1)
local buttons,frame=window(); points=1
T.Refresh('WARRIOR',1,10,'Arms'); T.Show()
local rend=buttons[byName['Improved Rend']]
local overlay=T.Overlay(rend)
assert(overlay and overlay.shown and overlay.pulse.playing and overlaysOf(rend)==1)
-- Hard to miss: a solid 3-pixel ice-blue outline (not gold, which the game uses for talents
-- with points in them), a glow drawn twice around the button, and the word NEXT above it.
-- No mouse, above the button.
assert(#overlay.textures==5 and overlay.mouse==false and overlay.level==8)
local ice=T.highlightColor; assert(ice[1]==0.35 and ice[2]==0.90 and ice[3]==1.00)
for index=1,4 do
 local line=overlay.textures[index]
 assert(line.color[1]==ice[1] and line.color[3]==ice[3] and line.color[4]==1 and (line.height==3 or line.width==3))
end
assert(overlay.points[1][4]==-3 and overlay.points[1][5]==3)
local glow=overlay.glow
assert(glow.parent==overlay and glow.mouse==false and #glow.textures==2 and overlay.pulse==glow.groups[1] and #overlay.groups==0)
for _,halo in ipairs(glow.textures) do
 assert(halo.texture=='Interface\\\\Buttons\\\\UI-ActionButton-Border' and halo.blend=='ADD' and halo.vertex[2]==ice[2] and halo.vertex[4]==1)
end
assert(glow.textures[2].points[1][4]<glow.textures[1].points[1][4])
-- Only the glow pulses, and never below 40%: the outline and label stay solid.
assert(overlay.pulse.animation.from==1 and overlay.pulse.animation.to==0.4 and overlay.pulse.animation.duration==0.7)
assert(overlay.label.text=='NEXT' and overlay.label.textColor[3]==1 and overlay.label.points[1][1]=='BOTTOM' and overlay.label.points[1][3]=='TOP')
assert(overlay.textures[5].color[4]==0.75)
-- Reopening the window many times and refreshing never adds frames.
local before=#created
for _=1,5 do
 for _,fn in ipairs(frame.hooks.OnHide) do fn(frame) end
 assert(not overlay.shown and not overlay.pulse.playing)
 for _,fn in ipairs(frame.hooks.OnShow) do fn(frame) end
 T.Refresh('WARRIOR',1,10,'Arms'); T.Show()
end
assert(#created==before and overlaysOf(rend)==1 and overlay.shown)
assert(#frame.hooks.OnShow==1 and #frame.hooks.OnHide==1 and #rend.hooks.OnEnter==1)
-- Only one button glows at a time, and the old one is cleared when the pick moves.
take('Improved Rend',1); points=1; T.Refresh('WARRIOR',1,11,'Arms'); T.Show()
assert(overlay.shown and #glowing(buttons)==1)
take('Improved Rend',3); points=1; T.Refresh('WARRIOR',1,13,'Arms'); T.Show()
assert(not overlay.shown and glowing(buttons)[1]==plan.picks[4].name)
-- A pooled button released from the window loses its highlight.
local current=buttons[byName[plan.picks[4].name]]; current.released=true; T.Show()
assert(not T.Overlay(current).shown)
current.released=nil
-- Turning recommendations off clears every highlight and the tooltip lines.
T.enabled=false; T.Refresh('WARRIOR',1,13,'Arms'); T.Show()
assert(#glowing(buttons)==0 and T.Summary()==nil and #tipFor(current)==0)
T.enabled=true
-- Combat: nothing is read and nothing is rebuilt.
combat=true; assert(T.Read()==nil); T.Show(); combat=false
-- The window's own update announcement repaints through EventRegistry.
local callbacks={}
EventRegistry={RegisterCallback=function(_,event,fn,owner) callbacks[#callbacks+1]={event,fn,owner} end}
T.Show(); T.Show(); assert(#callbacks==1 and callbacks[1][1]=='TalentFrameBase.ButtonsUpdated')
take(plan.picks[4].name,1); points=1; callbacks[1][2](callbacks[1][3],1)
assert(T.state.pick.rank==2 or T.state.pick.key~=plan.picks[4].key)
EventRegistry=nil
`);

test('Tooltips: place in the build, next point, and why a talent is locked', `
setup('WARRIOR'); local T=NS.Talents; local plan=T.Plan('WARRIOR',1)
local buttons=window(); follow(plan,3); points=1
T.Refresh('WARRIOR',1,13,'Arms'); T.Show()
local nextName=plan.picks[4].name
local tip=tipFor(buttons[byName[nextName]])
assert(find(tip,'puts 2 points here, at level 13, 14'),tip[2])
assert(find(tip,'Your next point goes here: rank 1 of 2 (build pick 4 of 51, level 13).'))
tip=tipFor(buttons[byName['Improved Rend']]); assert(find(tip,'Done: you have all 3 planned points.'))
tip=tipFor(buttons[byName['Mortal Strike']]); assert(find(tip,'puts 1 point here'))
assert(find(tip,'You have 0 of 1.'))
-- A talent outside the build.
local outside; for name in pairs(byName) do if not plan.talents[T.Key(name)] then outside=name end end
tip=tipFor(buttons[byName[outside]]); assert(find(tip,'not in the Icy Veins Arms build'))
-- Blocked next pick: the suggested talent says why, the blocked one names its prerequisite.
local id=byName[nextName]; nodes[id].meetsEdgeRequirements=false
table.insert(nodes[byName['Mortal Strike']].visibleEdges,{targetNode=id,type=3,isActive=false})
T.Refresh('WARRIOR',1,13,'Arms'); T.Show()
tip=tipFor(buttons[byName[nextName]]); assert(find(tip,'Not yet: this talent needs Mortal Strike first.'))
tip=tipFor(buttons[byName[T.state.pick.name]])
assert(find(tip,"Suggested because the build's next pick, "..nextName..", needs Mortal Strike first."))
`);

test('Secret values and the older numbered-talent API', `
local T=NS.Talents
setup('WARRIOR')
local real=C_Traits.GetNodeInfo
C_Traits.GetNodeInfo=function() return {ranksPurchased='SECRET',activeEntry={entryID=101}} end
T.Refresh('WARRIOR',1,12,'Arms'); assert(T.state.ranks==nil and T.Summary()==nil)
C_Traits.GetNodeInfo=real
-- A secret availability flag is treated as unknown, never compared.
nodes[byName['Improved Rend']].isAvailable='SECRET'; points=1
T.Refresh('WARRIOR',1,10,'Arms'); assert(T.state.pick.name=='Improved Rend')
C_Traits=nil; C_SpecializationInfo=nil; PlayerSpellsFrame=nil
-- Tab 1: Improved Rend (row 1) and Mortal Strike (row 7) needing Improved Rend.
GetNumTalentTabs=function() return 1 end; GetNumTalents=function() return 3 end
GetTalentTabInfo=function() return 'Arms' end
local ranks={3,0,0}
GetTalentInfo=function(_,index) return ({'Improved Rend','Deflection','Mortal Strike'})[index],nil,({1,1,7})[index],index,ranks[index],({3,5,1})[index] end
GetTalentPrereqs=function(_,index) if index==3 then return 1,1,true end end
GetUnspentTalentPoints=function() return 1 end
T.Refresh('WARRIOR',1,14,'Arms'); assert(T.state.pick.name=='Deflection' and T.state.pick.rank==1)
local ms=T.state.ranks[T.Key('Mortal Strike')]
assert(T.Blocker(ms,T.state.snap)=='needs 30 points spent in Arms (you have 3)')
ranks[1]=2; T.Refresh('WARRIOR',1,14,'Arms'); ms=T.state.ranks[T.Key('Mortal Strike')]
assert(T.Blocker(ms,T.state.snap):find('needs Improved Rend (3/3) first',1,true))
GetNumTalentTabs=nil; GetNumTalents=nil; GetTalentInfo=nil; GetTalentPrereqs=nil; GetUnspentTalentPoints=nil; GetTalentTabInfo=nil
`);

console.log(`Talent recommendations: ${passed} groups passed`);
