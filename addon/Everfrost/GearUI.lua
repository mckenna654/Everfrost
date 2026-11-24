local _, NS = ...
local G=NS.Gear
local eventFrame=CreateFrame("Frame")
local bags=setmetatable({},{__mode="k"})
local rolls=setmetatable({},{__mode="k"})
local hookedBags=setmetatable({},{__mode="k"})
-- Quest reward and merchant buttons, each with its comparison and how to mark it.
local overlays=setmetatable({},{__mode="k"})
local hookedOverlays=setmetatable({},{__mode="k"})
local discoverDue=true
local hooked={}
local queued=false
local activeRolls={}
local cancelledRolls={}
local function public(v,kind) return NS.Public(v) and type(v)==kind end
local function first(fn,...)
 local result=NS.Call(fn,...); return result and result[1]
end

-- Marks are deliberately quiet. Square item buttons get a thin border drawn just inside their
-- edge, never past it and never over the whole icon; a clear upgrade's border is a little
-- thicker and brighter than a minor one's, and only a clear upgrade gets the native green arrow.
-- Round loot-roll buttons get a faint ring instead, since a square around a round button reads
-- as a stray box; only a clear upgrade's Need ring breathes, slowly. Sidegrades get no mark.
NS.gearMarkStyles={
 clear={color={0.30,0.90,0.35},alpha=0.95,line=2,arrow=true},
 minor={color={0.45,0.80,0.50},alpha=0.70,line=1},
 sell={color={1,0.82,0},alpha=0.75,line=1},
 -- Roll buttons.
 needClear={color={0.30,0.90,0.35},alpha=0.70,ring=true,pulse={from=0.55,to=1,seconds=1.6}},
 needMinor={color={0.45,0.80,0.50},alpha=0.45,ring=true},
 greedHint={color={0.60,0.60,0.60},alpha=0.30,ring=true},
}
local STYLE=NS.gearMarkStyles
local RING_TEXTURE="Interface\\Buttons\\UI-ActionButton-Border"

local function hide(button)
 local m=button and button.EverfrostMark
 if not m then return end
 for _,edge in ipairs(m.edges) do edge:Hide() end
 if m.ring then m.ring:Hide() end
 if m.pulse then m.pulse:Stop() end
 if m.arrow then m.arrow:Hide() end
 if m.label then m.label:Hide() end
 m.style=nil
end
-- The mark's widgets, created once per button and reused when the button is.
local function parts(button,target)
 local m=button.EverfrostMark
 if m then return m end
 -- Never create widgets in combat; existing marks can still be shown or hidden.
 if InCombatLockdown() or not button.CreateTexture then return nil end
 m={edges={},target=target or button}
 for i=1,4 do
  local edge=button:CreateTexture(nil,"OVERLAY",nil,6)
  edge:SetColorTexture(1,1,1,1); edge:Hide(); m.edges[i]=edge
 end
 button.EverfrostMark=m
 return m
end
local function layoutEdges(m,line)
 if m.line==line then return end
 m.line=line
 local t,e=m.target,m.edges
 -- Top and bottom run the full width; the sides fit between them, so no corner doubles up.
 local spots={
  {"TOPLEFT",0,0,"TOPRIGHT",0,0,true},{"BOTTOMLEFT",0,0,"BOTTOMRIGHT",0,0,true},
  {"TOPLEFT",0,-line,"BOTTOMLEFT",0,line},{"TOPRIGHT",0,-line,"BOTTOMRIGHT",0,line}}
 for i,spot in ipairs(spots) do
  local edge=e[i]
  edge:ClearAllPoints()
  edge:SetPoint(spot[1],t,spot[1],spot[2],spot[3]); edge:SetPoint(spot[4],t,spot[4],spot[5],spot[6])
  if spot[7] then edge:SetHeight(line) else edge:SetWidth(line) end
 end
end
local function ring(button,m,style)
 if not m.ring then
  if InCombatLockdown() then return nil end
  local texture=button:CreateTexture(nil,"OVERLAY",nil,6)
  texture:SetTexture(RING_TEXTURE); texture:SetBlendMode("ADD")
  -- The border art's ring sits about a third of the way in, so the overhang follows the button.
  local width=first(button.GetWidth,button)
  local pad=public(width,"number") and width>0 and math.floor(width*0.32+0.5) or 12
  texture:SetPoint("TOPLEFT",button,"TOPLEFT",-pad,pad)
  texture:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",pad,-pad)
  m.ring=texture
 end
 if style.pulse and not m.pulse and m.ring.CreateAnimationGroup and not InCombatLockdown() then
  local group=m.ring:CreateAnimationGroup()
  local alpha=group:CreateAnimation("Alpha")
  alpha:SetFromAlpha(style.pulse.from); alpha:SetToAlpha(style.pulse.to); alpha:SetDuration(style.pulse.seconds)
  if alpha.SetSmoothing then alpha:SetSmoothing("IN_OUT") end
  group:SetLooping("BOUNCE")
  m.pulse=group
 end
 return m.ring
end
-- Shows one style on a button (nil hides). target is the region the border outlines (default
-- the button). Repainting the same style keeps a running pulse going.
local function mark(button,style,target,label,labelColor)
 if not button then return end
 if not style then hide(button); return end
 local m=parts(button,target)
 if not m then return end
 local c=style.color
 if style.ring then
  for _,edge in ipairs(m.edges) do edge:Hide() end
  local texture=ring(button,m,style)
  if texture then
   texture:SetVertexColor(c[1],c[2],c[3],style.alpha); texture:Show()
   if m.pulse then
    if style.pulse then if not m.pulse:IsPlaying() then m.pulse:Play() end else m.pulse:Stop() end
   end
  end
 else
  if m.ring then m.ring:Hide() end
  if m.pulse then m.pulse:Stop() end
  layoutEdges(m,style.line or 1)
  for _,edge in ipairs(m.edges) do edge:SetVertexColor(c[1],c[2],c[3],style.alpha); edge:Show() end
 end
 -- The native bag upgrade arrow, in the corner opposite the stack count.
 if style.arrow and not m.arrow and not InCombatLockdown() then
  local icon=button:CreateTexture(nil,"OVERLAY",nil,7)
  if icon.SetAtlas then icon:SetAtlas("bags-greenarrow",true) end
  icon:SetPoint("TOPLEFT",m.target,"TOPLEFT",2,-2)
  m.arrow=icon
 end
 if m.arrow then if style.arrow then m.arrow:Show() else m.arrow:Hide() end end
 -- A small word in the button's bottom-right corner (quest rewards only).
 if label and not m.label and button.CreateFontString and not InCombatLockdown() then
  local text=button:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  text:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",-4,3)
  m.label=text
 end
 if m.label then
  if label then
   local lc=labelColor or c
   m.label:SetText(label); m.label:SetTextColor(lc[1],lc[2],lc[3]); m.label:Show()
  else m.label:Hide() end
 end
 m.style=style
end
-- The talent window borrows a gentle ring: NS.Glow(button, shown, {color={r,g,b}}).
local talentStyles=setmetatable({},{__mode="k"})
NS.Glow=function(button,shown,item)
 if not shown then mark(button,nil); return end
 local color=item and item.color or {1,1,1}
 local style=talentStyles[color]
 if not style then
  style={color=color,alpha=0.85,ring=true,pulse={from=0.5,to=1,seconds=1.6}}
  talentStyles[color]=style
 end
 mark(button,style)
end
-- The style for a square item button, from the verdict.
local function itemStyle(result)
 if not result or result.kind~="need" then return nil end
 return result.verdict=="clear" and STYLE.clear or result.verdict=="minor" and STYLE.minor or nil
end

-- Tooltip wording ----------------------------------------------------------------------------
local headColour={clear={0.35,0.95,0.45},minor={0.6,0.88,0.6},sidegrade={0.82,0.82,0.82},spec={0.55,0.75,1},
 unusable={0.85,0.5,0.45},downgrade={0.78,0.62,0.55},unknown={0.7,0.7,0.7}}
local function percent(result)
 if not result.pct or (result.previous or 0)<1 then return "" end
 local n=math.floor(math.abs(result.pct)*100+0.5)
 if n>200 then return result.pct>0 and " (over +200%)" or "" end
 return string.format(" (%s%d%%)",result.pct>=0 and "+" or "-",n)
end
-- The verdict in two or three words, as the tooltip's first line shows it.
function G.Headline(result)
 local v=result.verdict
 local text
 if v=="clear" then text=result.empty and "Clear upgrade (empty slot)" or "Clear upgrade"..percent(result)
 elseif v=="minor" then text="Minor upgrade"..percent(result)
 elseif v=="sidegrade" then text="Sidegrade"
 elseif v=="spec" then text="Better for "..(result.altLabel or "another spec")
 elseif v=="unusable" then text="Not usable"
 elseif v=="downgrade" then text="Downgrade"..((result.pct and result.pct<0) and percent(result) or "")
 else text="Not scored" end
 if result.combined and result.kind=="need" then text=text.." (equip both)" end
 return text
end
local effectWords={use="Use effect",proc="chance-on-hit effect",equip="Equip effect"}
local function effectText(set)
 local words={}
 for _,key in ipairs({"use","proc","equip"}) do if set[key] then words[#words+1]=effectWords[key] end end
 return table.concat(words," and ")
end
local white,gold,dim={0.85,0.9,1},{1,0.82,0.22},{0.65,0.72,0.82}
function G.Tooltip(tooltip,result,roll)
 if not tooltip or not result then return end
 roll=roll==true
 if tooltip.EverfrostGearResult==result and tooltip.EverfrostGearRoll==roll then return end
 tooltip.EverfrostGearResult=result; tooltip.EverfrostGearRoll=roll
 local function line(text,colour) tooltip:AddLine(text,colour[1],colour[2],colour[3],true) end
 tooltip:AddLine(" ")
 local head=G.Headline(result)
 if roll and result.kind~="unknown" then head=head..(result.kind=="need" and " / Need" or " / Greed") end
 line("Everfrost: "..head,headColour[result.verdict] or headColour.unknown)
 -- One or two short lines of why: the specific reason, then the stat that decided it.
 if result.reason and not (result.generic and result.why) then line(result.reason,white) end
 if result.why then line(result.why,white) end
 if result.unscored then line("Its "..effectText(result.unscored).." can't be scored; judge that part yourself.",gold) end
 if result.oldUnscored then line("Your current item's "..effectText(result.oldUnscored).." isn't counted.",gold) end
 if result.slotNote then line(result.slotNote,dim) end
 for _,note in ipairs(result.notes or {}) do line(note,gold) end
 if result.combined then line("Pair with: "..result.companionName,gold) end
 local c=G.context
 local p=c and NS.GearProfile(c.class,c.spec,c.role,c.level)
 if p then
  local title=p.starter and "Starter priority: " or p.focusLabel and (p.focusLabel.." priority: ") or "Priority: "
  line(title..NS.GearOrderText(p),dim)
  if p.starter then line("Simple estimate from your class's usual stats.",dim) end
 end
 tooltip:Show()
end

-- Bags ---------------------------------------------------------------------------------------
function G.PaintBag(button)
 local entry=bags[button]
 if not entry then return end
 local cached=G.enabled and not G.pending and G.bags[entry.bag] and G.bags[entry.bag][entry.slot]
 mark(button,cached and itemStyle(cached.result) or nil)
end
function G.TrackBag(button,bag,slot)
 if not button then return end
 if not public(bag,"number") or not public(slot,"number") or bag<0 or bag>4 then bags[button]=nil; hide(button); return end
 -- Buttons are pooled and reassigned, so hooks are remembered apart from the bag they show.
 if not hookedBags[button] then
  if InCombatLockdown() then return end
  hookedBags[button]=true
  if button.HookScript then
   button:HookScript("OnEnter",function(self)
    local key=bags[self]
    local entry=key and G.bags[key.bag] and G.bags[key.bag][key.slot]
    if G.enabled and not G.pending and entry then G.Tooltip(GameTooltip,entry.result) end
   end)
   button:HookScript("OnHide",function(self) hide(self) end)
   button:HookScript("OnShow",function(self) G.PaintBag(self); G.Schedule() end)
  end
 end
 bags[button]={bag=bag,slot=slot}
 G.PaintBag(button)
end
local function trackButton(button)
 if not button then return end
 local bag=first(button.GetBagID,button)
 if not public(bag,"number") then
  local parent=first(button.GetParent,button)
  bag=parent and first(parent.GetID,parent)
 end
 local slot=first(button.GetID,button)
 G.TrackBag(button,bag,slot)
end
local function discoverBags()
 -- Modern combined bags and classic individual bags both expose item buttons.
 local function container(frame)
  if not frame then return end
  if frame.EnumerateValidItems then
   for _,button in frame:EnumerateValidItems() do trackButton(button) end
  elseif frame.Items then for _,button in pairs(frame.Items) do trackButton(button) end end
  local name=first(frame.GetName,frame)
  if public(name,"string") then
   for slot=1,40 do trackButton(_G[name.."Item"..slot]) end
  end
 end
 for i=1,13 do container(_G["ContainerFrame"..i]) end
 container(ContainerFrameCombinedBags)
end

-- Loot rolls ---------------------------------------------------------------------------------
-- Forever nests the roll buttons in LootButtonContainer; older clients use the frame or its name.
local function rollButton(frame,name)
 local holder=frame.LootButtonContainer
 return frame[name] or (holder and holder[name]) or (frame.GetName and _G[(frame:GetName() or "")..name])
end
function G.PaintRoll(frame)
 if not frame then return end
 local need=rollButton(frame,"NeedButton")
 local greed=rollButton(frame,"GreedButton")
 local id=frame.rollID
 if not G.enabled or G.pending or not public(id,"number") then hide(need); hide(greed); return end
 local data=G.rolls[id]
 if not data then hide(need); hide(greed); return end
 local result=data.result
 local function available(button)
  if not button then return false end
  local enabled=first(button.IsEnabled,button)
  local shown=first(button.IsShown,button)
  return public(enabled,"boolean") and enabled and public(shown,"boolean") and shown
 end
 -- A disabled Need option never changes an upgrade into a Greed recommendation.
 local needStyle=result.kind=="need" and data.canNeed and available(need) and
  (result.verdict=="clear" and STYLE.needClear or STYLE.needMinor) or nil
 -- Greed gets only a faint hint, and only for items you would not wear.
 local greedStyle=result.kind=="greed" and (result.verdict=="downgrade" or result.verdict=="unusable") and
  data.canGreed and available(greed) and STYLE.greedHint or nil
 mark(need,needStyle); mark(greed,greedStyle)
end
function G.TrackRoll(frame)
 if not frame then return end
 if not rolls[frame] then
  if InCombatLockdown() then return end
  rolls[frame]=true
  if frame.HookScript then
   frame:HookScript("OnHide",function(self)
    -- Hiding the whole UI also lands here, so only the loot events end a roll.
    hide(rollButton(self,"NeedButton")); hide(rollButton(self,"GreedButton"))
   end)
   frame:HookScript("OnShow",function(self) G.PaintRoll(self); G.Schedule() end)
  end
  for _,name in ipairs({"NeedButton","GreedButton"}) do
   local button=rollButton(frame,name)
   if button and button.HookScript then
    button:HookScript("OnEnter",function()
     local id=frame.rollID
     if G.enabled and not G.pending and public(id,"number") and G.rolls[id] then G.Tooltip(GameTooltip,G.rolls[id].result,true) end
    end)
   end
  end
 end
 G.PaintRoll(frame)
end
local function readRoll(id)
 if InCombatLockdown() or not public(id,"number") then return end
 G.rolls[id]=nil
 local link=first(GetLootRollItemLink,id)
 local info=NS.Call(GetLootRollItemInfo,id)
 if not public(link,"string") or not info then return end
 if not public(info[6],"boolean") or not public(info[7],"boolean") then return end
 G.rolls[id]={link=link,item=G.ReadItem(link),result=G.Evaluate(link),canNeed=info[6],canGreed=info[7]}
end

-- Quest rewards and merchants -----------------------------------------------------------------
local function paintOverlay(button)
 local entry=overlays[button]
 if not entry then return end
 if not (G.enabled and not G.pending and entry.mark) then hide(button); return end
 -- Quest rewards outline the icon only, leaving the reward's name clear.
 local icon=entry.kind=="quest" and button.Icon
 local target=type(icon)=="table" and icon or nil
 if entry.mark=="sell" then mark(button,STYLE.sell,target,"Best sell value")
 elseif entry.mark=="recommended" then mark(button,itemStyle(entry.result) or STYLE.minor,target,"Recommended",STYLE.clear.color)
 else mark(button,itemStyle(entry.result),target) end
end
function G.Paint()
 for button in pairs(bags) do G.PaintBag(button) end
 for frame in pairs(rolls) do G.PaintRoll(frame) end
 for button in pairs(overlays) do paintOverlay(button) end
end
local function clearOverlays(kind)
 for button,entry in pairs(overlays) do
  if entry.kind==kind then overlays[button]=nil; hide(button) end
 end
end
local function addOverlay(button,kind,link)
 local item=G.ReadItem(link)
 local entry={kind=kind,item=item,result=G.Compare(item,G.equipment,G.context,G.carried)}
 overlays[button]=entry
 if not hookedOverlays[button] and button.HookScript then
  hookedOverlays[button]=true
  button:HookScript("OnEnter",function(self)
   local current=overlays[self]
   if current and G.enabled and not G.pending then G.Tooltip(GameTooltip,current.result) end
  end)
 end
 return entry
end
local function note(entry,text)
 local notes=entry.result.notes or {}
 for _,existing in ipairs(notes) do if existing==text then return end end
 notes[#notes+1]=text; entry.result.notes=notes
end
-- The choice with the largest estimated gain that is a real upgrade under one profile.
local function bestChoice(entries,results)
 local best
 for index in ipairs(entries) do
  local r=results[index]
  if r.kind=="need" and (not best or r.delta>results[best].delta) then best=index end
 end
 return best and entries[best],best
end
-- Rewards within this share of the best gain are called a close call.
NS.gearCompetitive=0.85
-- Recommend the best quest upgrade. With none on offer, mark what sells for the most instead.
local function readQuestChoices()
 clearOverlays("quest")
 local info=QuestInfoFrame
 local rewards=(info and info.rewardsFrame) or QuestInfoRewardsFrame
 if not G.enabled or not rewards or not rewards.RewardButtons or not first(rewards.IsVisible or rewards.IsShown,rewards) then return end
 local getLink=info and info.questLog and GetQuestLogItemLink or GetQuestItemLink
 local entries={}
 for _,button in ipairs(rewards.RewardButtons) do
  if button.type=="choice" and (button.objectType==nil or button.objectType=="item") and first(button.IsShown,button) then
   local link=first(getLink,"choice",first(button.GetID,button))
   if public(link,"string") then entries[#entries+1]=addOverlay(button,"quest",link) end
  end
 end
 if #entries<2 then return end
 local results={}
 for index,entry in ipairs(entries) do
  -- Wait for every choice's data, so the mark never settles on a partial list.
  if not entry.item or entry.result.waiting then return end
  results[index]=entry.result
 end
 local best,bestIndex=bestChoice(entries,results)
 if best then
  best.mark="recommended"
  local close={}
  for index,entry in ipairs(entries) do
   local r=results[index]
   if index~=bestIndex and r.kind=="need" and r.delta>=results[bestIndex].delta*NS.gearCompetitive then
    close[#close+1]=entry; note(entry,"Close to the recommended reward; either is a good pick.")
   end
  end
  note(best,#close>0 and "Recommended, but it's a close call with "..#close..(#close==1 and " other reward." or " others.") or "Recommended: the best upgrade among these rewards.")
 else
  local seller
  for _,entry in ipairs(entries) do
   if entry.item.sellPrice>0 and (not seller or entry.item.sellPrice>seller.item.sellPrice) then seller=entry end
  end
  if seller then
   seller.mark="sell"; note(seller,"None of these is an upgrade, so this one is marked because it sells for the most.")
  end
 end
 -- When another focus or talent tree of your class would pick a different reward, say so.
 local p=G.context and NS.GearProfile(G.context.class,G.context.spec,G.context.role,G.context.level)
 local differs=false
 for _,alt in ipairs(G.Alternatives(G.context)) do
  local altResults={}
  for index,entry in ipairs(entries) do
   altResults[index]=G.Compare(entry.item,G.equipment,alt.context,G.carried,nil,alt.profile)
  end
  local altBest=bestChoice(entries,altResults)
  if altBest and altBest~=best then differs=true; note(altBest,"Best for "..alt.bestFor..".") end
 end
 if differs and best and p and p.bestFor then note(best,"Best for "..p.bestFor..".") end
end
-- Upgrades on the current merchant page. The mark waits until you can afford the item.
local function readMerchant()
 clearOverlays("merchant")
 local merchant=MerchantFrame
 if not G.enabled or not merchant or merchant.selectedTab~=1 or not first(merchant.IsShown,merchant) then return end
 for i=1,(MERCHANT_ITEMS_PER_PAGE or 12) do
  local button=_G["MerchantItem"..i.."ItemButton"]
  if button and button.hasItem then
   local index=first(button.GetID,button)
   local link=first(GetMerchantItemLink,index)
   if public(link,"string") then
    local entry=addOverlay(button,"merchant",link)
    if entry.result.kind=="need" then
     if first(CanAffordMerchantItem,index)==false then note(entry,"You can't afford this yet.")
     else entry.mark="upgrade" end
    end
   end
  end
 end
end

-- Hooks and scheduling -----------------------------------------------------------------------
local function installHooks()
 if InCombatLockdown() or not hooksecurefunc then return end
 if GameTooltip and not hooked.tooltipClear and GameTooltip.HookScript then
  GameTooltip:HookScript("OnTooltipCleared",function(tooltip)
   tooltip.EverfrostGearResult=nil; tooltip.EverfrostGearRoll=nil
  end)
  hooked.tooltipClear=true
 end
 -- Native bags rebuild their tooltip while hovered, after the first OnEnter.
 -- Append after each item build so the upgrade line survives those refreshes.
 if not hooked.bagTooltip then
  local function append(tooltip)
   if not G.enabled or G.pending then return end
   local owner=first(tooltip.GetOwner,tooltip)
   local key=owner and bags[owner]
   local entry=key and G.bags[key.bag] and G.bags[key.bag][key.slot]
   if entry then G.Tooltip(tooltip,entry.result)
   elseif owner and overlays[owner] then G.Tooltip(tooltip,overlays[owner].result) end
  end
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Item then
   TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item,append)
   hooked.bagTooltip=true
  elseif GameTooltip and type(GameTooltip.SetBagItem)=="function" then
   hooksecurefunc(GameTooltip,"SetBagItem",append); hooked.bagTooltip=true
  end
 end
 local function hook(name,fn)
  if not hooked[name] and type(_G[name])=="function" then
   hooksecurefunc(name,fn); hooked[name]=true
  end
 end
 -- These fire once per bag per change. The walk over every bag button waits for the batched
 -- rescan (see G.Schedule) instead of running each time.
 local function bagsChanged() discoverDue=true; G.Schedule() end
 hook("ContainerFrame_Update",bagsChanged)
 hook("ContainerFrame_UpdateAll",bagsChanged)
 hook("ContainerFrame_GenerateFrame",bagsChanged)
 hook("GroupLootFrame_OnShow",function(frame) G.TrackRoll(frame); G.Schedule() end)
 hook("QuestInfo_Display",function() G.Schedule() end)
 hook("MerchantFrame_Update",function() G.Schedule() end)
 local mixin=ContainerFrameItemButtonMixin
 if mixin and type(mixin.Initialize)=="function" and not hooked.bagMixin then
  -- Forever passes the container first: Initialize(containerFrame, bag, slot).
  hooksecurefunc(mixin,"Initialize",function(button,a,b,c)
   if type(a)=="table" then G.TrackBag(button,b,c) else G.TrackBag(button,a,b) end
  end)
  hooked.bagMixin=true
 end
 -- The hooks above keep buttons current; a full walk is only needed when something may be missed.
 if discoverDue or not (hooked.bagMixin or hooked.ContainerFrame_Update or hooked.ContainerFrame_UpdateAll or hooked.ContainerFrame_GenerateFrame) then
  discoverDue=false; discoverBags()
 end
 for i=1,4 do G.TrackRoll(_G["GroupLootFrame"..i]) end
 if GroupLootContainer and GroupLootContainer.rollFrames then
  for _,frame in pairs(GroupLootContainer.rollFrames) do G.TrackRoll(frame) end
 end
end
function G.Schedule()
 if queued then return end
 queued=true
 -- An OnUpdate callback works on clients without C_Timer and coalesces events.
 eventFrame:SetScript("OnUpdate",function(self)
  self:SetScript("OnUpdate",nil); queued=false
  if InCombatLockdown() then G.pending=true; G.Paint(); return end
  installHooks(); G.Refresh()
  for id in pairs(activeRolls) do readRoll(id) end
  for frame in pairs(rolls) do
   local id=frame.rollID
   local shown=first(frame.IsShown,frame)
   if public(id,"number") and not activeRolls[id] and not cancelledRolls[id] and public(shown,"boolean") and shown then
    activeRolls[id]=true; readRoll(id)
   end
  end
  readQuestChoices(); readMerchant()
  G.Paint()
 end)
end
for _,event in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","BAG_UPDATE_DELAYED","BAG_UPDATE","PLAYER_EQUIPMENT_CHANGED", "GET_ITEM_INFO_RECEIVED",
 "ITEM_DATA_LOAD_RESULT","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED","START_LOOT_ROLL","CANCEL_LOOT_ROLL","CANCEL_ALL_LOOT_ROLLS","ADDON_LOADED","SKILL_LINES_CHANGED"}) do
 pcall(eventFrame.RegisterEvent,eventFrame,event)
end
eventFrame:SetScript("OnEvent",function(_,event,value)
 -- Combat skips new buttons, and other addons can create or replace bag frames.
 if event=="PLAYER_ENTERING_WORLD" or event=="ADDON_LOADED" or event=="PLAYER_REGEN_ENABLED" then discoverDue=true end
 if event=="START_LOOT_ROLL" and public(value,"number") then activeRolls[value]=true; cancelledRolls[value]=nil
 elseif event=="CANCEL_LOOT_ROLL" and public(value,"number") then activeRolls[value]=nil; G.rolls[value]=nil; cancelledRolls[value]=true
 elseif event=="CANCEL_ALL_LOOT_ROLLS" then
  for id in pairs(activeRolls) do cancelledRolls[id]=true end
  activeRolls={}; G.rolls={}
 elseif event=="PLAYER_REGEN_DISABLED" then G.pending=true; G.Paint(); return end
 if event=="GET_ITEM_INFO_RECEIVED" or event=="ITEM_DATA_LOAD_RESULT" then
  -- Cache hits may also emit this event; only missing data should trigger a rescan.
  -- Permanent "not scored" results (below level 10, no tree) never wait on data.
  local waiting=false
  for _,bag in pairs(G.bags) do for _,item in pairs(bag) do if item.result and item.result.waiting then waiting=true end end end
  for _,item in pairs(G.rolls) do if item.result and item.result.waiting then waiting=true end end
  for _,entry in pairs(overlays) do if entry.result.waiting then waiting=true end end
  if not waiting then return end
 end
 -- Outside combat the rescan lands next frame: keep the marks so a running pulse carries on.
 if InCombatLockdown() then G.pending=true; G.Paint() end
 G.Schedule()
end)
