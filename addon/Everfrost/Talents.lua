local _, NS = ...
-- luacheck: read globals EventRegistry C_Timer GetUnspentTalentPoints GetTalentPrereqs
-- Talent recommendations: the Icy Veins levelling build for the player's tree (TalentData.lua),
-- compared with the talents already taken, shown as "next talent" text and as a highlight and
-- tooltip lines in the game's talent window. Reference only: Everfrost never spends a point and
-- never touches the window's own controls.
--
-- The next pick is the first point of the build not yet taken that the game would accept now:
-- its prerequisites are met (node edges), the tree has enough points for its row (gates) and the
-- player's level allows it. A build point that can't be taken yet is passed over, with the reason
-- kept for the tooltip and summary, and the next legal build point is suggested instead.
local T={enabled=true}
NS.Talents=T
local function public(v,kind) return NS.Public(v) and type(v)==kind end
local function first(fn,...)
 local result=NS.Call(fn,...); return result and result[1]
end
local function number(v) return public(v,"number") and v or nil end
local function flag(v) if public(v,"boolean") then return v end end
-- Names are compared without case, spaces or punctuation, so "Nature's Grasp" is "naturesgrasp".
local function key(name) return (name:lower():gsub("[^%a%d]","")) end
T.Key=key

-- The guide's picks in order: one entry per talent point, the first at level 10.
local plans={}
function T.Plan(class,spec)
 local data=NS.talentData and NS.talentData[class]
 local build=data and data.builds[spec]
 if not build then return nil end
 local id=class..spec
 if plans[id] then return plans[id] end
 local plan,count={picks={},talents={}},{}
 for index=1,#build do
  local letter=build:sub(index,index)
  local name=data.names[letter]
  local k=key(name)
  count[k]=(count[k] or 0)+1
  plan.picks[index]={key=k,name=name,level=9+index,rank=count[k],index=index}
  local talent=plan.talents[k] or {name=name,levels={},picks={}}
  talent.levels[#talent.levels+1]=9+index
  talent.picks[#talent.picks+1]=index
  plan.talents[k]=talent
 end
 plans[id]=plan
 return plan
end

-- Reading the talents. Each read gives a snapshot:
--  ranks[key]  = {name, rank, max, maxed, node or tab/index, ...} for every talent found by name
--  points      = unspent talent points, when the client says
--  spent       = points spent in all trees
-- Anything restricted (a secret value) is left out rather than guessed.

-- The trait config the native talent window shows for the active spec group (Forever's
-- ClassTalentsFrame uses GetCombatConfigIDForSpecGroup), else the generic active config.
local function activeConfig()
 local api=C_SpecializationInfo or {}
 local group=number(first(api.GetActiveSpecGroup or GetActiveTalentGroup))
 local configID=group and number(first(api.GetCombatConfigIDForSpecGroup,group))
 return configID or number(first(C_ClassTalents and C_ClassTalents.GetActiveConfigID))
end
local function definitionName(traits,configID,entryID)
 local entry=public(entryID,"number") and first(traits.GetEntryInfo,configID,entryID)
 local definition=public(entry,"table") and public(entry.definitionID,"number") and first(traits.GetDefinitionInfo,entry.definitionID)
 if not public(definition,"table") then return nil end
 local name=definition.overrideName
 if not public(name,"string") or name=="" then
  local spell=public(definition.spellID,"number") and first(C_Spell and C_Spell.GetSpellInfo,definition.spellID)
  name=public(spell,"table") and spell.name or nil
 end
 return public(name,"string") and name~="" and name or nil
end
local function traitSnapshot()
 local traits=C_Traits
 if not traits or type(traits.GetConfigInfo)~="function" or type(traits.GetTreeNodes)~="function"
  or type(traits.GetNodeInfo)~="function" or type(traits.GetEntryInfo)~="function" or type(traits.GetDefinitionInfo)~="function" then return nil end
 local configID=activeConfig()
 if not configID then return nil end
 local info=first(traits.GetConfigInfo,configID)
 if not public(info,"table") or not public(info.treeIDs,"table") then return nil end
 local snap={kind="traits",configID=configID,ranks={},byNode={},incoming={},groups={},spent=0}
 local found=false
 for _,treeID in ipairs(info.treeIDs) do
  local nodes=public(treeID,"number") and first(traits.GetTreeNodes,treeID)
  if public(nodes,"table") then
   for _,nodeID in ipairs(nodes) do
    local node=public(nodeID,"number") and first(traits.GetNodeInfo,configID,nodeID)
    if public(node,"table") and flag(node.isVisible)~=false then
     -- Purchased ranks include points staged in the open window, as the window itself shows.
     local rank=number(node.ranksPurchased) or number(node.activeRank) or number(node.currentRank)
     local active=number(node.activeRank) or rank
     local max=number(node.maxRanks)
     local activeEntry=public(node.activeEntry,"table") and number(node.activeEntry.entryID)
     local entries=public(node.entryIDs,"table") and node.entryIDs or {}
     if #entries==0 and activeEntry then entries={activeEntry} end
     local groups={}
     if public(node.groupIDs,"table") then
      for _,groupID in ipairs(node.groupIDs) do
       if public(groupID,"number") then groups[#groups+1]=groupID; snap.groups[groupID]=snap.groups[groupID] or {} end
      end
     end
     if public(node.visibleEdges,"table") then
      for _,edge in ipairs(node.visibleEdges) do
       local target=public(edge,"table") and number(edge.targetNode)
       local kind=public(edge,"table") and number(edge.type)
       -- Visual-only (0) and mutually exclusive (4) edges are not prerequisites.
       if target and kind~=0 and kind~=4 then
        local list=snap.incoming[target] or {}
        list[#list+1]={from=nodeID,active=flag(edge.isActive)}
        snap.incoming[target]=list
       end
      end
     end
     if rank then
      snap.spent=snap.spent+rank
      for _,entryID in ipairs(entries) do
       local name=definitionName(traits,configID,entryID)
       if name then
        -- A choice node counts only its chosen option as taken.
        local chosen=#entries==1 or entryID==activeEntry
        local own=chosen and rank or 0
        local item={name=name,rank=own,max=max,node=nodeID,groups=groups,
         -- Ranks granted for free count too: a full talent is never pending.
         maxed=chosen and max~=nil and max>0 and (active or own)>=max,
         available=flag(node.isAvailable),edges=flag(node.meetsEdgeRequirements),canBuy=flag(node.canPurchaseRank),
         conditions=public(node.conditionIDs,"table") and node.conditionIDs or nil}
        snap.ranks[key(name)]=item
        snap.byNode[nodeID]=snap.byNode[nodeID] or item
        found=true
       end
      end
     end
    end
   end
  end
  -- Unspent points, including any the window has staged.
  local currency=number(treeID) and first(traits.GetTreeCurrencyInfo,configID,treeID,false)
  local quantity=public(currency,"table") and public(currency[1],"table") and number(currency[1].quantity)
  if quantity then snap.points=(snap.points or 0)+quantity end
  -- Tree names and points spent per tree, for "needs N points in Arms".
  local display=number(treeID) and first(traits.GetGroupDisplayInfoByTreeID,treeID)
  if public(display,"table") then
   for _,group in ipairs(display) do
    if public(group,"table") and number(group.groupID) and public(group.displayName,"string") then
     snap.groups[group.groupID]=snap.groups[group.groupID] or {}
     snap.groups[group.groupID].name=group.displayName
    end
   end
  end
 end
 if not found then return nil end
 local ids={}
 for groupID in pairs(snap.groups) do ids[#ids+1]=groupID end
 table.sort(ids)
 local spent=#ids>0 and first(traits.GetGroupCurrencyInfo,configID,ids)
 if public(spent,"table") then
  for _,group in ipairs(spent) do
   local id=public(group,"table") and number(group.traitNodeGroupID)
   local currency=id and public(group.currencyInfos,"table") and group.currencyInfos[1]
   local amount=public(currency,"table") and number(currency.spent)
   if id and amount and snap.groups[id] then snap.groups[id].spent=amount end
  end
 end
 return snap
end
-- The older talent API: tabs of numbered talents, rows needing five points each.
local function tabSnapshot()
 if type(GetNumTalentTabs)~="function" or type(GetNumTalents)~="function" or type(GetTalentInfo)~="function" then return nil end
 local tabs=number(first(GetNumTalentTabs))
 if not tabs then return nil end
 local snap={kind="tabs",ranks={},tabs={},spent=0}
 local found,places=false,{}
 for tab=1,tabs do
  local count=number(first(GetNumTalents,tab))
  local tabInfo=NS.Call(GetTalentTabInfo,tab)
  snap.tabs[tab]={spent=0,name=tabInfo and public(tabInfo[1],"string") and tabInfo[1] or nil}
  for index=1,count or 0 do
   local info=NS.Call(GetTalentInfo,tab,index)
   local name=info and public(info[1],"string") and info[1]
   local rank=info and number(info[5])
   if name and rank then
    local max=info and number(info[6])
    local item={name=name,rank=rank,max=max,maxed=rank>0 and max~=nil and rank>=max,tab=tab,index=index,
     tier=number(info[3]),column=number(info[4])}
    local prereq=NS.Call(GetTalentPrereqs,tab,index)
    if prereq and number(prereq[1]) and number(prereq[2]) then item.prereq={tier=prereq[1],column=prereq[2]} end
    if item.tier and item.column then places[tab..":"..item.tier..":"..item.column]=item end
    snap.ranks[key(name)]=item
    snap.tabs[tab].spent=snap.tabs[tab].spent+rank
    snap.spent=snap.spent+rank
    found=true
   end
  end
 end
 if not found then return nil end
 for _,item in pairs(snap.ranks) do
  if item.prereq then item.prereq=places[item.tab..":"..item.prereq.tier..":"..item.prereq.column] end
 end
 snap.points=number(first(GetUnspentTalentPoints))
 return snap
end
function T.Read()
 if InCombatLockdown() then return nil end
 return traitSnapshot() or tabSnapshot()
end

-- Why a talent can't take a point right now, in words; nil when it can.
local function plural(n,word) return n.." "..word..(n==1 and "" or "s") end
local function treeNeed(required,name,spent)
 return "needs "..plural(required,"point").." spent in "..(name or "its tree")..(spent and (" (you have "..spent..")") or "")
end
local function nameOfNode(snap,nodeID)
 local item=snap.byNode and snap.byNode[nodeID]
 return item and item.name
end
function T.Blocker(item,snap)
 if not item or not snap then return nil end
 local reasons={}
 if item.tab then
  local need=item.tier and (item.tier-1)*5 or 0
  local tab=snap.tabs and snap.tabs[item.tab] or {}
  if need>0 and (tab.spent or 0)<need then reasons[#reasons+1]=treeNeed(need,tab.name,tab.spent or 0) end
  local before=item.prereq
  if before and before.max and before.rank<before.max then reasons[#reasons+1]="needs "..before.name.." ("..before.max.."/"..before.max..") first" end
  return #reasons>0 and table.concat(reasons," and ") or nil
 end
 local gate,levelNeed
 if item.available==false or item.canBuy==false then
  -- The native tooltip shows the same conditions: the strictest unmet row gate and the lowest
  -- unmet level requirement.
  local traits=C_Traits or {}
  for _,condID in ipairs(item.conditions or {}) do
   local info=public(condID,"number") and first(traits.GetConditionInfo,snap.configID,condID)
   if public(info,"table") and flag(info.isMet)==false then
    local required=number(info.spentAmountRequired)
    if flag(info.isGate) and required and (not gate or required>gate) then gate=required end
    local wanted=number(info.playerLevel)
    if wanted and (not levelNeed or wanted<levelNeed) then levelNeed=wanted end
   end
  end
 end
 if gate then
  local group=item.groups and item.groups[1] and snap.groups[item.groups[1]] or {}
  reasons[#reasons+1]=treeNeed(gate,group.name,group.spent)
 end
 if levelNeed then reasons[#reasons+1]="needs level "..levelNeed end
 if item.edges==false then
  local missing={}
  for _,edge in ipairs(item.node and snap.incoming[item.node] or {}) do
   local name=edge.active~=true and nameOfNode(snap,edge.from)
   if name then missing[#missing+1]=name end
  end
  reasons[#reasons+1]=#missing>0 and ("needs "..table.concat(missing," and ").." first") or "needs its prerequisite first"
 end
 if #reasons==0 and item.available==false then reasons[1]="isn't available yet" end
 return #reasons>0 and table.concat(reasons," and ") or nil
end

-- Works out the next recommended point from a snapshot. Pure: no client calls except condition
-- lookups for talents that are blocked.
function T.Decide(plan,snap,level)
 local state={plan=plan,ranks=snap and snap.ranks,snap=snap,level=level,blocked={}}
 if not snap then return state end
 local points=snap.points
 -- Without a currency reading, one point per level from 10.
 if points==nil and public(level,"number") then points=math.max(0,level-9-snap.spent) end
 state.points=points
 local passed={}
 for index,pick in ipairs(plan.picks) do
  local have=snap.ranks[pick.key]
  -- A talent the client names differently can't be checked, so it is passed over rather than
  -- recommended for ever.
  if have and not have.maxed and have.rank<pick.rank and not passed[pick.key] then
   if not state.next then state.next=pick; state.index=index end
   local why=T.Blocker(have,snap)
   if why then
    passed[pick.key]=true
    state.blocked[#state.blocked+1]={pick=pick,why=why}
    state.blockedBy=state.blockedBy or {}
    state.blockedBy[pick.key]=why
   else state.pick=pick; break end
  end
 end
 state.complete=state.next==nil
 -- No point to spend: the pick is named, but nothing glows until the next level.
 state.waiting=state.pick~=nil and points==0
 return state
end

-- The arguments of the last refresh, so the talent window can ask for a repaint itself.
local last
function T.Refresh(class,spec,level,treeName)
 last={class,spec,level,treeName}
 if InCombatLockdown() then return end
 T.state=nil
 local plan=T.enabled and T.Plan(class,spec)
 if not plan then if T.Paint then T.Paint() end; return end
 local state=T.Decide(plan,T.Read(),level)
 state.tree=treeName
 T.state=state
 if T.Paint then T.Paint() end
end

local function buildName(state) return "Icy Veins "..(state.tree or "").." build" end
local function shownName(state,pick)
 local have=state.ranks and state.ranks[pick.key]
 return have and have.name or pick.name
end
local function pickText(state,pick)
 return shownName(state,pick).." "..pick.rank.."/"..#state.plan.talents[pick.key].levels
end
-- One line for the panel's hover text and the settings window; nil when there is nothing to say.
function T.Summary()
 local state=T.state
 -- Where the client won't say which talents are taken there is nothing useful to add.
 if not state or not state.ranks then return nil end
 local build=buildName(state)
 if state.complete then return "Talents: you have every point of the "..build.."." end
 local pick,level=state.pick,state.level or 0
 if not pick then
  -- Every remaining build point is locked for now.
  local blocked=state.blocked[1]
  return "Next talent, "..build..": "..pickText(state,blocked.pick).." "..blocked.why.."."
 end
 local text="Next talent, "..build..": "..pickText(state,pick)
 if pick.level>level then text=text.." (the guide takes it at level "..pick.level..")"
 elseif state.waiting then text=text.." (your next talent point comes at level "..(level+1)..")" end
 if state.next~=pick then
  text=text..". The build's next pick, "..shownName(state,state.next)..", "..state.blockedBy[state.next.key]
 end
 return text
end
-- The next few build points, for /everfrost talents: "13: Deflection", with a reason when locked.
function T.Upcoming(count)
 local state=T.state
 if not state or not state.next then return nil end
 local out={}
 for index=state.index,#state.plan.picks do
  if #out>=count then break end
  local pick=state.plan.picks[index]
  local have=state.ranks[pick.key]
  if have and not have.maxed and have.rank<pick.rank then
   local why=state.blockedBy and state.blockedBy[pick.key]
   out[#out+1]=pick.level..": "..(have.name or pick.name)..(why and (" ("..why..")") or "")
  end
 end
 return out
end

-- The talent window. Forever's is PlayerSpellsFrame.TalentsFrame (Blizzard_PlayerSpells, a
-- ClassTalentsFrame on TalentFrameBaseMixin); its buttons come from a pool, so the same button can
-- show another talent after a refresh. Each button gets at most one Everfrost overlay, made the
-- first time it is needed and reused after that.
local hooked=setmetatable({},{__mode="k"})
local hookedFrames=setmetatable({},{__mode="k"})
local overlays=setmetatable({},{__mode="k"})
local legacyNames=setmetatable({},{__mode="k"})
local active={}
local windows={}
local GOLD={1,0.82,0}
local function buttonItem(button)
 local state=T.state
 if not state or not state.snap then return nil end
 if button.GetNodeID then
  local node=first(button.GetNodeID,button)
  if public(node,"number") then
   local item=state.snap.byNode and state.snap.byNode[node]
   return item and key(item.name),item
  end
  return nil
 end
 local name=legacyNames[button]
 if not name then return nil end
 return key(name),state.ranks[key(name)]
end
T.ButtonKey=buttonItem
local function levelsText(levels) return table.concat(levels,", ") end
local function tooltip(button)
 local state=T.state
 if not T.enabled or not state or not state.ranks or InCombatLockdown() then return end
 local k,item=buttonItem(button)
 if not k then return end
 local build=buildName(state)
 local planned=state.plan.talents[k]
 GameTooltip:AddLine(" ")
 if not planned then
  GameTooltip:AddLine("Everfrost: not in the "..build..".",0.75,0.82,0.92,true)
  GameTooltip:Show(); return
 end
 local total=#planned.levels
 GameTooltip:AddLine("Everfrost: the "..build.." puts "..plural(total,"point").." here, at level "..levelsText(planned.levels)..".",1,0.82,0.22,true)
 local have=item and item.rank or 0
 local pick=state.pick
 if have>=total or (item and item.maxed) then
  GameTooltip:AddLine("Done: you have all "..plural(total,"planned point")..".",0.6,0.85,0.6,true)
 elseif pick and pick.key==k then
  local where="build pick "..pick.index.." of "..#state.plan.picks..", level "..pick.level
  if state.waiting then
   GameTooltip:AddLine("Your next point goes here ("..where.."), once you have a talent point.",0.85,0.9,1,true)
  else
   GameTooltip:AddLine("Your next point goes here: rank "..pick.rank.." of "..total.." ("..where..").",0.85,0.9,1,true)
  end
  if state.next~=pick then
   GameTooltip:AddLine("Suggested because the build's next pick, "..shownName(state,state.next)..", "..state.blockedBy[state.next.key]..".",0.85,0.9,1,true)
  end
 else
  local why=state.blockedBy and state.blockedBy[k]
  if why then
   GameTooltip:AddLine("Not yet: this talent "..why..".",1,0.5,0.4,true)
  elseif state.next and state.next.key==k then
   GameTooltip:AddLine("The build's next point goes here.",0.85,0.9,1,true)
  else
   GameTooltip:AddLine("You have "..have.." of "..total..".",0.75,0.82,0.92,true)
  end
 end
 GameTooltip:Show()
end
-- A thin gold outline just outside the button's edge, pulsing gently. It sits outside the icon
-- and the rank counter, takes no mouse input, and so leaves the native tooltip and clicks alone.
local function overlayFor(button)
 local overlay=overlays[button]
 if overlay or type(CreateFrame)~="function" then return overlay end
 overlay=CreateFrame("Frame",nil,button)
 if overlay.EnableMouse then overlay:EnableMouse(false) end
 overlay:SetPoint("TOPLEFT",button,"TOPLEFT",-2,2)
 overlay:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",2,-2)
 local level=number(first(button.GetFrameLevel,button))
 if level and overlay.SetFrameLevel then overlay:SetFrameLevel(level+3) end
 local function edge(from,to,horizontal)
  local line=overlay:CreateTexture(nil,"OVERLAY")
  line:SetColorTexture(GOLD[1],GOLD[2],GOLD[3],0.95)
  line:SetPoint(from,overlay,from); line:SetPoint(to,overlay,to)
  if horizontal then line:SetHeight(2) else line:SetWidth(2) end
 end
 edge("TOPLEFT","TOPRIGHT",true); edge("BOTTOMLEFT","BOTTOMRIGHT",true)
 edge("TOPLEFT","BOTTOMLEFT",false); edge("TOPRIGHT","BOTTOMRIGHT",false)
 if overlay.CreateAnimationGroup then
  local pulse=overlay:CreateAnimationGroup()
  pulse:SetLooping("BOUNCE")
  local fade=pulse:CreateAnimation("Alpha")
  fade:SetFromAlpha(1); fade:SetToAlpha(0.35); fade:SetDuration(0.9)
  if fade.SetSmoothing then fade:SetSmoothing("IN_OUT") end
  overlay.pulse=pulse
 end
 overlay:Hide()
 overlays[button]=overlay
 return overlay
end
local function setOverlay(button,shown)
 local overlay=shown and overlayFor(button) or overlays[button]
 if not overlay then return end
 if shown then
  overlay:Show()
  if overlay.pulse and not overlay.pulse:IsPlaying() then overlay.pulse:Play() end
 else
  if overlay.pulse then overlay.pulse:Stop() end
  overlay:Hide()
 end
end
T.Overlay=function(button) return overlays[button] end
-- Hides every highlight, for a closed window or recommendations turned off.
function T.Clear()
 for _,overlay in pairs(overlays) do
  if overlay.pulse then overlay.pulse:Stop() end
  overlay:Hide()
 end
end
-- Repaints after the window changes (a point spent or staged, a respec, the tree reloading).
-- Batched to the next frame where the client can, so a burst of updates is one repaint.
local requested=false
function T.Request()
 if requested then return end
 local function run()
  requested=false
  if last then T.Refresh(last[1],last[2],last[3],last[4]) end
  T.Show()
 end
 if C_Timer and type(C_Timer.After)=="function" then requested=true; C_Timer.After(0,run) else run() end
end
local function track(button)
 if type(button)~="table" then return end
 active[button]=true
 if hooked[button] or not button.HookScript then return end
 hooked[button]=true
 button:HookScript("OnEnter",tooltip)
end
local listening=false
local function discover()
 for button in pairs(active) do active[button]=nil end
 for index in ipairs(windows) do windows[index]=nil end
 for _,frame in ipairs({PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame,ClassTalentFrame and ClassTalentFrame.TalentsTab,
  ClassTalentFrame,PlayerTalentFrame,TalentFrame}) do
  if type(frame)=="table" then
   if type(frame.EnumerateAllTalentButtons)=="function" then
    windows[#windows+1]=frame
    local iterate=NS.Call(frame.EnumerateAllTalentButtons,frame)
    if iterate and type(iterate[1])=="function" then
     -- Frame pools hand the button back as the first value; plain lists as the second.
     for a,b in iterate[1],iterate[2],iterate[3] do track(type(a)=="table" and a or b) end
    end
   end
   if not hookedFrames[frame] and frame.HookScript then
    hookedFrames[frame]=true
    frame:HookScript("OnShow",T.Request)
    frame:HookScript("OnHide",T.Clear)
   end
  end
 end
 -- The native window announces each time its buttons are rebuilt or updated.
 if not listening and type(EventRegistry)=="table" and type(EventRegistry.RegisterCallback)=="function" then
  listening=true
  EventRegistry:RegisterCallback("TalentFrameBase.ButtonsUpdated",T.Request,T)
 end
 -- Numbered talent buttons of the older window: the button's ID is its place in the open tab.
 for _,prefix in ipairs({"PlayerTalentFrameTalent","TalentFrameTalent"}) do
  local owner=prefix=="PlayerTalentFrameTalent" and PlayerTalentFrame or TalentFrame
  local tab=type(owner)=="table" and (owner.selectedTab or owner.currentSelectedTab) or nil
  for index=1,40 do
   local button=_G[prefix..index]
   if type(button)=="table" then
    local id=first(button.GetID,button)
    local info=public(tab,"number") and public(id,"number") and type(GetTalentInfo)=="function" and NS.Call(GetTalentInfo,tab,id)
    legacyNames[button]=info and public(info[1],"string") and info[1] or nil
    track(button)
   end
  end
 end
end
-- The window may show the other spec group's talents, or someone being inspected: no highlight then.
local function showsOwnConfig()
 local state=T.state
 local configID=state and state.snap and state.snap.configID
 for _,frame in ipairs(windows) do
  if first(frame.IsInspecting,frame)==true then return false end
  local shown=configID and number(first(frame.GetConfigID,frame))
  if shown and shown~=configID then return false end
 end
 return true
end
function T.Paint()
 local state=T.state
 local wanted=T.enabled and state and state.pick and not state.waiting and showsOwnConfig() and state.pick.key or nil
 for button,overlay in pairs(overlays) do
  if not active[button] then
   if overlay.pulse then overlay.pulse:Stop() end
   overlay:Hide()
  end
 end
 for button in pairs(active) do
  setOverlay(button,wanted~=nil and buttonItem(button)==wanted)
 end
end
-- Finds the talent window's buttons (it loads on demand) and repaints.
function T.Show()
 if InCombatLockdown() then return end
 discover(); T.Paint()
end
