local _, NS = ...
local G=NS.Gear
local eventFrame=CreateFrame("Frame")
local bags=setmetatable({},{__mode="k"})
local rolls=setmetatable({},{__mode="k"})
local hookedBags=setmetatable({},{__mode="k"})
-- Quest reward and merchant buttons, each with its comparison and how to mark it.
local overlays=setmetatable({},{__mode="k"})
local hookedOverlays=setmetatable({},{__mode="k"})
local sellValueColour={color={1,0.82,0}}
local discoverDue=true
local hooked={}
local queued=false
local activeRolls={}
local cancelledRolls={}
local function public(v,kind) return NS.Public(v) and type(v)==kind end
local function first(fn,...)
 local result=NS.Call(fn,...); return result and result[1]
end
local function hide(button)
 if button and button.EverfrostGearGlow then
  button.EverfrostGearGlow:Hide()
  for _,edge in ipairs(button.EverfrostGearEdges or {}) do edge:Hide() end
  for _,pulse in ipairs(button.EverfrostGearPulses or {}) do pulse:Stop() end
  if button.EverfrostGearArrow then button.EverfrostGearArrow:Hide() end
 end
end
-- The highlight's look, in one place. A soft glow sized to the button, with a thin outline that
-- sits exactly on a square button's edge. Roll buttons are round, so they get the glow alone:
-- a square drawn around a round button read as a stray box.
local GLOW={line=2,dim=0.4,bright=1,seconds=0.9}
local function glow(button, shown, item, arrow, round)
 if not button then return end
 if not shown then hide(button); return end
 -- Never create or hook widgets in combat; pre-existing cosmetic glows are safe.
 if not button.EverfrostGearGlow then
  if InCombatLockdown() then return end
  local texture=button:CreateTexture(nil,"OVERLAY",nil,7)
  texture:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  texture:SetBlendMode("ADD")
  -- The border art's ring sits about a third of the way in, so the overhang follows the
  -- button's size rather than a fixed 12 pixels that only suited bag slots.
  local width=first(button.GetWidth,button)
  local pad=public(width,"number") and width>0 and math.floor(width*0.32+0.5) or 12
  texture:SetPoint("TOPLEFT",button,"TOPLEFT",-pad,pad)
  texture:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",pad,-pad)
  button.EverfrostGearGlow=texture
  -- Animate every layer together, so the outline also fades visibly.
  button.EverfrostGearEdges={}
  button.EverfrostGearPulses={}
  local function pulse(layer)
   if not layer.CreateAnimationGroup then return end
   local group=layer:CreateAnimationGroup()
   local alpha=group:CreateAnimation("Alpha")
   alpha:SetFromAlpha(GLOW.dim); alpha:SetToAlpha(GLOW.bright); alpha:SetDuration(GLOW.seconds)
   -- Eases in and out, so it breathes rather than blinks.
   if alpha.SetSmoothing then alpha:SetSmoothing("IN_OUT") end
   group:SetLooping("BOUNCE")
   button.EverfrostGearPulses[#button.EverfrostGearPulses+1]=group
  end
  pulse(texture)
  local function edge(from,x1,y1,to,x2,y2,horizontal)
   local line=button:CreateTexture(nil,"OVERLAY",nil,7)
   line:SetColorTexture(1,1,1,1)
   line:SetPoint(from,button,from,x1,y1); line:SetPoint(to,button,to,x2,y2)
   if horizontal then line:SetHeight(GLOW.line) else line:SetWidth(GLOW.line) end
   button.EverfrostGearEdges[#button.EverfrostGearEdges+1]=line
   pulse(line)
  end
  if not round then
   -- Flush with the button: top and bottom run the full width, the sides fit between them,
   -- so no corner is drawn twice and nothing pokes out past the slot.
   edge("TOPLEFT",0,0,"TOPRIGHT",0,0,true)
   edge("BOTTOMLEFT",0,0,"BOTTOMRIGHT",0,0,true)
   edge("TOPLEFT",0,-GLOW.line,"BOTTOMLEFT",0,GLOW.line,false)
   edge("TOPRIGHT",0,-GLOW.line,"BOTTOMRIGHT",0,GLOW.line,false)
  end
 end
 local color=item and item.color or {1,1,1}
 button.EverfrostGearGlow:SetVertexColor(color[1],color[2],color[3],1)
 button.EverfrostGearGlow:Show()
 for _,edge in ipairs(button.EverfrostGearEdges) do
  edge:SetVertexColor(color[1],color[2],color[3],1); edge:Show()
 end
 for _,pulse in ipairs(button.EverfrostGearPulses) do
  if not pulse:IsPlaying() then pulse:Play() end
 end
 -- The native bag upgrade arrow, inset to clear the outline. It stays steady while the glow pulses.
 if arrow and not button.EverfrostGearArrow and button.CreateTexture and not InCombatLockdown() then
  local icon=button:CreateTexture(nil,"OVERLAY",nil,7)
  if icon.SetAtlas then icon:SetAtlas("bags-greenarrow",true) end
  icon:SetPoint("TOPLEFT",button,"TOPLEFT",2,-2)
  button.EverfrostGearArrow=icon
 end
 if button.EverfrostGearArrow then
  if arrow then button.EverfrostGearArrow:Show() else button.EverfrostGearArrow:Hide() end
 end
end
-- The talent window borrows the same highlight.
NS.Glow=glow
function G.Tooltip(tooltip,result,roll)
 if not tooltip or not result then return end
 roll=roll==true
 if tooltip.EverfrostGearResult==result and tooltip.EverfrostGearRoll==roll then return end
 tooltip.EverfrostGearResult=result; tooltip.EverfrostGearRoll=roll
 tooltip:AddLine(" ")
 local label=result.kind=="need" and (result.combined and "UPGRADE (equip both)" or "UPGRADE") or result.kind=="greed" and "No upgrade" or "Not scored"
 if roll and result.kind~="unknown" then label=label..(result.kind=="need" and " / Need" or " / Greed") end
 tooltip:AddLine("Everfrost: "..label,1,0.82,0.22)
 tooltip:AddLine(result.reason,0.85,0.9,1,true)
 if result.why then tooltip:AddLine(result.why,0.85,0.9,1,true) end
 if result.note then tooltip:AddLine(result.note,1,0.82,0.22,true) end
 if result.combined then
  tooltip:AddLine("Pair with: "..result.companionName,1,0.82,0.22,true)
  tooltip:AddLine("Combined pair compared with your equipped two-hander; equip both items.",0.85,0.9,1,true)
 end
 local c=G.context
 local p=c and NS.GearProfile(c.class,c.spec,c.role,c.level)
 local starter=p and p.starter
 -- Armor is not scored for most specs, so "0.0 vs 0.0" would only confuse here.
 -- Scores mean little on starter gear, where the reason above says enough.
 if result.delta and not result.armorOnly and not starter then
  tooltip:AddLine(string.format("Estimated score: %.1f vs %.1f (%+.1f)",result.score,result.previous,result.delta),0.85,0.9,1,true)
  local armour=result.armorCredit
  if armour and (armour>0.05 or armour<-0.05) then tooltip:AddLine(string.format("Armour accounts for %+.1f of that.",armour),0.85,0.9,1,true) end
 end
 if p then tooltip:AddLine((starter and "Starter priority: " or "Priority: ")..NS.GearPriorityText(p),0.75,0.82,0.92,true) end
 tooltip:AddLine(starter and "Simple estimate from your class's usual stats. Check effects and group loot rules." or "Guide-based stat estimate. Check effects, weapon setup and group loot rules.",0.65,0.72,0.82,true)
 tooltip:Show()
end
function G.PaintBag(button)
 local entry=bags[button]
 if not entry then return end
 local cached=G.bags[entry.bag] and G.bags[entry.bag][entry.slot]
 glow(button,G.enabled and not G.pending and cached and cached.result.kind=="need" or false,cached and cached.item,true)
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
 glow(need,result.kind=="need" and data.canNeed and available(need),data.item,false,true)
 glow(greed,result.kind=="greed" and data.canGreed and available(greed),data.item,false,true)
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
local function paintOverlay(button)
 local entry=overlays[button]
 if not entry then return end
 local shown=G.enabled and not G.pending and entry.mark~=nil
 glow(button,shown,entry.mark=="sell" and sellValueColour or entry.item,entry.mark=="upgrade")
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
-- Mark the best quest choice. With no upgrade on offer, mark what sells for the most instead.
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
 local best,seller
 for _,entry in ipairs(entries) do
  -- Wait for every choice's data, so the mark never settles on a partial list.
  if not entry.item or entry.result.waiting then return end
  if entry.result.kind=="need" and (not best or entry.result.delta>best.result.delta) then best=entry end
  if entry.item.sellPrice>0 and (not seller or entry.item.sellPrice>seller.item.sellPrice) then seller=entry end
 end
 if best then
  best.mark="upgrade"; best.result.note="Best reward choice for you."
 elseif seller then
  seller.mark="sell"; seller.result.note="None of these is an upgrade, so this one is marked because it sells for the most."
 end
end
-- Upgrades on the current merchant page. The glow waits until you can afford the item.
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
     if first(CanAffordMerchantItem,index)==false then entry.result.note="You can't afford this yet."
     else entry.mark="upgrade" end
    end
   end
  end
 end
end
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
 -- Outside combat the rescan lands next frame: keep the glows so their pulse carries on.
 if InCombatLockdown() then G.pending=true; G.Paint() end
 G.Schedule()
end)
