local _, NS = ...
-- Talent recommendations: the Icy Veins levelling build for the player's tree (TalentData.lua),
-- compared with the talents already taken, shown as "next talent" text and as a highlight and
-- tooltip lines in the game's talent window. Reference only: Everfrost never spends a point.
local T={enabled=true}
NS.Talents=T
local function public(v,kind) return NS.Public(v) and type(v)==kind end
local function first(fn,...)
 local result=NS.Call(fn,...); return result and result[1]
end
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
  plan.picks[index]={key=k,name=name,level=9+index,rank=count[k]}
  local talent=plan.talents[k] or {name=name,levels={}}
  talent.levels[#talent.levels+1]=9+index
  plan.talents[k]=talent
 end
 plans[id]=plan
 return plan
end

-- Ranks taken so far, by name key: {rank=, name=, node=}. Nil when the client offers no way to
-- read them, or any part of the answer is restricted.
local function traitRanks()
 local traits=C_Traits
 if not traits or type(traits.GetConfigInfo)~="function" or type(traits.GetTreeNodes)~="function"
  or type(traits.GetNodeInfo)~="function" or type(traits.GetEntryInfo)~="function" or type(traits.GetDefinitionInfo)~="function" then return nil end
 local configID=first(C_ClassTalents and C_ClassTalents.GetActiveConfigID)
 if not public(configID,"number") then
  local api=C_SpecializationInfo or {}
  local group=first(api.GetActiveSpecGroup or GetActiveTalentGroup)
  if public(group,"number") then configID=first(api.GetCombatConfigIDForSpecGroup,group) end
 end
 if not public(configID,"number") then return nil end
 local info=first(traits.GetConfigInfo,configID)
 if not public(info,"table") or not public(info.treeIDs,"table") then return nil end
 local ranks,found={},false
 for _,treeID in ipairs(info.treeIDs) do
  local nodes=first(traits.GetTreeNodes,treeID)
  if public(nodes,"table") then
   for _,nodeID in ipairs(nodes) do
    local node=first(traits.GetNodeInfo,configID,nodeID)
    if public(node,"table") then
     local entryID=public(node.activeEntry,"table") and node.activeEntry.entryID or (public(node.entryIDs,"table") and node.entryIDs[1])
     local entry=public(entryID,"number") and first(traits.GetEntryInfo,configID,entryID)
     local definition=public(entry,"table") and public(entry.definitionID,"number") and first(traits.GetDefinitionInfo,entry.definitionID)
     if public(definition,"table") then
      local name=definition.overrideName
      if not public(name,"string") or name=="" then
       local spell=public(definition.spellID,"number") and first(C_Spell and C_Spell.GetSpellInfo,definition.spellID)
       name=public(spell,"table") and spell.name or nil
      end
      local rank=node.ranksPurchased
      if not public(rank,"number") then rank=node.currentRank end
      if public(name,"string") and name~="" and public(rank,"number") then
       ranks[key(name)]={rank=rank,name=name,node=nodeID}; found=true
      end
     end
    end
   end
  end
 end
 return found and ranks or nil
end
-- The older talent API: tabs of numbered talents.
local function tabRanks()
 if type(GetNumTalentTabs)~="function" or type(GetNumTalents)~="function" or type(GetTalentInfo)~="function" then return nil end
 local tabs=first(GetNumTalentTabs)
 if not public(tabs,"number") then return nil end
 local ranks,found={},false
 for tab=1,tabs do
  local count=first(GetNumTalents,tab)
  if public(count,"number") then
   for index=1,count do
    local info=NS.Call(GetTalentInfo,tab,index)
    if info and public(info[1],"string") and public(info[5],"number") then
     ranks[key(info[1])]={rank=info[5],name=info[1],tab=tab,index=index}; found=true
    end
   end
  end
 end
 return found and ranks or nil
end
function T.Read()
 if InCombatLockdown() then return nil end
 return traitRanks() or tabRanks()
end

-- Works out the next recommended point. Kept until the next refresh, so drawing and tooltips
-- never read talents themselves.
function T.Refresh(class,spec,level,treeName)
 if InCombatLockdown() then return end
 T.state=nil
 local plan=T.enabled and T.Plan(class,spec)
 if not plan then if T.Paint then T.Paint() end; return end
 local ranks=T.Read()
 local state={plan=plan,ranks=ranks,tree=treeName,level=level}
 if ranks then
  for index,pick in ipairs(plan.picks) do
   local have=ranks[pick.key]
   -- A talent the client names differently can't be checked, so it is passed over rather than
   -- recommended for ever.
   if have and have.rank<pick.rank then state.next=pick; state.index=index; break end
  end
  state.complete=state.next==nil
 end
 T.state=state
 if T.Paint then T.Paint() end
end
-- One line for the panel's hover text and the settings window; nil when there is nothing to say.
function T.Summary()
 local state=T.state
 if not state then return nil end
 local build="Icy Veins "..(state.tree or "").." build"
 -- Where the client won't say which talents are taken there is nothing useful to add.
 if not state.ranks then return nil end
 if state.complete then return "Talents: you have every point of the "..build.."." end
 local pick=state.next
 local shown=state.ranks[pick.key] and state.ranks[pick.key].name or pick.name
 local due=pick.level<=(state.level or 0) and "" or (" (the guide takes it at level "..pick.level..")")
 return "Next talent, "..build..": "..shown.." "..pick.rank.."/"..#state.plan.talents[pick.key].levels..due
end
-- The next few picks, for /everfrost talents.
function T.Upcoming(count)
 local state=T.state
 if not state or not state.next then return nil end
 local out={}
 for index=state.index,math.min(#state.plan.picks,state.index+count-1) do
  local pick=state.plan.picks[index]
  local have=state.ranks[pick.key]
  if have and have.rank<pick.rank then out[#out+1]=pick.level..": "..(have.name or pick.name) end
 end
 return out
end

-- The talent window. Its frame differs between clients, so buttons are found by what they can
-- do (report a trait node or a talent index) rather than by a fixed name.
local buttons=setmetatable({},{__mode="k"})
local hookedFrames=setmetatable({},{__mode="k"})
local gold={color={1,0.82,0}}
local function buttonKey(button)
 local state=T.state
 if not state or not state.ranks then return nil end
 local node=first(button.GetNodeID,button)
 if public(node,"number") then
  for k,have in pairs(state.ranks) do if have.node==node then return k end end
  return nil
 end
 local name=button.EverfrostTalentName
 return public(name,"string") and key(name) or nil
end
local function tooltip(button)
 local state=T.state
 if not T.enabled or not state or not state.ranks or InCombatLockdown() then return end
 local k=buttonKey(button)
 if not k then return end
 local build="Icy Veins "..(state.tree or "").." build"
 local planned=state.plan.talents[k]
 GameTooltip:AddLine(" ")
 if not planned then
  GameTooltip:AddLine("Everfrost: not in the "..build..".",0.75,0.82,0.92,true)
 else
  local levels=table.concat(planned.levels,", ")
  GameTooltip:AddLine("Everfrost: the "..build.." puts "..#planned.levels..(#planned.levels==1 and " point" or " points").." here, at level "..levels..".",1,0.82,0.22,true)
  if state.next and state.next.key==k then GameTooltip:AddLine("Your next point goes here.",0.85,0.9,1,true) end
 end
 GameTooltip:Show()
end
local function track(button)
 if not button or buttons[button] then return end
 if InCombatLockdown() then return end
 buttons[button]=true
 if button.HookScript then button:HookScript("OnEnter",tooltip) end
end
local function discover()
 local found=false
 for _,frame in ipairs({PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame,ClassTalentFrame and ClassTalentFrame.TalentsTab,
  ClassTalentFrame,PlayerTalentFrame,TalentFrame}) do
  if type(frame)=="table" then
   if type(frame.EnumerateAllTalentButtons)=="function" then
    local iterate=NS.Call(frame.EnumerateAllTalentButtons,frame)
    if iterate and type(iterate[1])=="function" then
     -- Frame pools hand the button back as the first value; plain lists as the second.
     for a,b in iterate[1],iterate[2],iterate[3] do
      local button=type(a)=="table" and a or b
      if type(button)=="table" then track(button); found=true end
     end
    end
   end
   if not hookedFrames[frame] and frame.HookScript and not InCombatLockdown() then
    hookedFrames[frame]=true
    frame:HookScript("OnShow",function() if T.Schedule then T.Schedule() end end)
   end
  end
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
    button.EverfrostTalentName=info and public(info[1],"string") and info[1] or nil
    track(button); found=true
   end
  end
 end
 return found
end
function T.Paint()
 if not NS.Glow then return end
 local state=T.state
 local wanted=T.enabled and state and state.ranks and state.next and state.next.key or nil
 for button in pairs(buttons) do
  NS.Glow(button,wanted~=nil and buttonKey(button)==wanted,gold,false,true)
 end
end
-- Finds the talent window's buttons (it loads on demand) and repaints.
function T.Show()
 if InCombatLockdown() then return end
 discover(); T.Paint()
end
