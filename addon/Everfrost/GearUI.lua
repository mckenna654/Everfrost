local _, NS = ...
local G=NS.Gear
local eventFrame=CreateFrame("Frame")
local bags=setmetatable({},{__mode="k"})
local rolls=setmetatable({},{__mode="k"})
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
 end
end
local function glow(button, shown, item)
 if not button then return end
 if not shown then hide(button); return end
 -- Never create or hook widgets in combat; pre-existing cosmetic glows are safe.
 if not button.EverfrostGearGlow then
  if InCombatLockdown() then return end
  local texture=button:CreateTexture(nil,"OVERLAY",nil,7)
  texture:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
  texture:SetBlendMode("ADD")
  texture:SetPoint("TOPLEFT",button,"TOPLEFT",-12,12)
  texture:SetPoint("BOTTOMRIGHT",button,"BOTTOMRIGHT",12,-12)
  button.EverfrostGearGlow=texture
  -- Animate every layer together, so the outline also fades visibly.
  button.EverfrostGearEdges={}
  button.EverfrostGearPulses={}
  local function pulse(layer)
   if not layer.CreateAnimationGroup then return end
   local group=layer:CreateAnimationGroup()
   local alpha=group:CreateAnimation("Alpha")
   alpha:SetFromAlpha(0.18); alpha:SetToAlpha(1); alpha:SetDuration(0.7)
   group:SetLooping("BOUNCE")
   button.EverfrostGearPulses[#button.EverfrostGearPulses+1]=group
  end
  pulse(texture)
  local function edge(from,x1,y1,to,x2,y2,horizontal)
   local line=button:CreateTexture(nil,"OVERLAY",nil,7)
   line:SetColorTexture(1,1,1,1)
   line:SetPoint(from,button,from,x1,y1); line:SetPoint(to,button,to,x2,y2)
   if horizontal then line:SetHeight(3) else line:SetWidth(3) end
   button.EverfrostGearEdges[#button.EverfrostGearEdges+1]=line
   pulse(line)
  end
  edge("TOPLEFT",-1,1,"TOPRIGHT",1,1,true)
  edge("BOTTOMLEFT",-1,-1,"BOTTOMRIGHT",1,-1,true)
  edge("TOPLEFT",-1,1,"BOTTOMLEFT",-1,-1,false)
  edge("TOPRIGHT",1,1,"BOTTOMRIGHT",1,-1,false)
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
end
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
 if result.reason~=NS.gearLevelNote then tooltip:AddLine(NS.gearLevelNote,0.75,0.82,0.92,true) end
 if result.combined then
  tooltip:AddLine("Pair with: "..result.companionName,1,0.82,0.22,true)
  tooltip:AddLine("Combined pair compared with your equipped two-hander; equip both items.",0.85,0.9,1,true)
 end
 if result.delta then tooltip:AddLine(string.format("Estimated score: %.1f vs %.1f (%+.1f)",result.score,result.previous,result.delta),0.85,0.9,1,true) end
 local c=G.context
 local p=c and c.level>=NS.gearMinLevel and NS.GearProfile(c.class,c.spec,c.role)
 if p then tooltip:AddLine("Priority: "..NS.GearPriorityText(p),0.75,0.82,0.92,true) end
 tooltip:AddLine("Guide-based stat estimate. Check effects, weapon setup and group loot rules.",0.65,0.72,0.82,true)
 tooltip:Show()
end
function G.PaintBag(button)
 local entry=bags[button]
 if not entry then return end
 local cached=G.bags[entry.bag] and G.bags[entry.bag][entry.slot]
 glow(button,G.enabled and not G.pending and cached and cached.result.kind=="need" or false,cached and cached.item)
end
function G.TrackBag(button,bag,slot)
 if not button then return end
 if not public(bag,"number") or not public(slot,"number") or bag<0 or bag>4 then bags[button]=nil; hide(button); return end
 if not bags[button] then
  if InCombatLockdown() then return end
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
function G.PaintRoll(frame)
 if not frame then return end
 local need=frame.NeedButton or (frame.GetName and _G[(frame:GetName() or "").."NeedButton"])
 local greed=frame.GreedButton or (frame.GetName and _G[(frame:GetName() or "").."GreedButton"])
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
 glow(need,result.kind=="need" and data.canNeed and available(need),data.item)
 glow(greed,result.kind=="greed" and data.canGreed and available(greed),data.item)
end
function G.TrackRoll(frame)
 if not frame then return end
 if not rolls[frame] then
  if InCombatLockdown() then return end
  rolls[frame]=true
  if frame.HookScript then
   frame:HookScript("OnHide",function(self)
    hide(self.NeedButton); hide(self.GreedButton)
    local id=self.rollID
    if public(id,"number") then G.rolls[id]=nil; activeRolls[id]=nil; cancelledRolls[id]=true end
   end)
   frame:HookScript("OnShow",function(self) G.PaintRoll(self); G.Schedule() end)
  end
  for _,name in ipairs({"NeedButton","GreedButton"}) do
   local button=frame[name]
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
function G.Paint()
 for button in pairs(bags) do G.PaintBag(button) end
 for frame in pairs(rolls) do G.PaintRoll(frame) end
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
   if entry then G.Tooltip(tooltip,entry.result) end
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
 hook("ContainerFrame_Update",function(frame) discoverBags(); G.Schedule() end)
 hook("ContainerFrame_UpdateAll",function() discoverBags(); G.Schedule() end)
 hook("ContainerFrame_GenerateFrame",function() discoverBags(); G.Schedule() end)
 hook("GroupLootFrame_OnShow",function(frame) G.TrackRoll(frame); G.Schedule() end)
 local mixin=ContainerFrameItemButtonMixin
 if mixin and type(mixin.Initialize)=="function" and not hooked.bagMixin then
  hooksecurefunc(mixin,"Initialize",function(button,bag,slot) G.TrackBag(button,bag,slot) end)
  hooked.bagMixin=true
 end
 discoverBags()
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
  G.Paint()
 end)
end
for _,event in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","BAG_UPDATE_DELAYED","BAG_UPDATE","PLAYER_EQUIPMENT_CHANGED", "GET_ITEM_INFO_RECEIVED",
 "ITEM_DATA_LOAD_RESULT","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED","START_LOOT_ROLL","CANCEL_LOOT_ROLL","CANCEL_ALL_LOOT_ROLLS","ADDON_LOADED","SKILL_LINES_CHANGED"}) do
 pcall(eventFrame.RegisterEvent,eventFrame,event)
end
eventFrame:SetScript("OnEvent",function(_,event,value)
 if event=="START_LOOT_ROLL" and public(value,"number") then activeRolls[value]=true; cancelledRolls[value]=nil
 elseif event=="CANCEL_LOOT_ROLL" and public(value,"number") then activeRolls[value]=nil; G.rolls[value]=nil; cancelledRolls[value]=true
 elseif event=="CANCEL_ALL_LOOT_ROLLS" then
  for id in pairs(activeRolls) do cancelledRolls[id]=true end
  activeRolls={}; G.rolls={}
 elseif event=="PLAYER_REGEN_DISABLED" then G.pending=true; G.Paint(); return end
 if event=="GET_ITEM_INFO_RECEIVED" or event=="ITEM_DATA_LOAD_RESULT" then
  -- Cache hits may also emit this event; only missing data should trigger a rescan.
  local waiting=false
  for _,bag in pairs(G.bags) do for _,item in pairs(bag) do if item.result.kind=="unknown" then waiting=true end end end
  for _,item in pairs(G.rolls) do if item.result.kind=="unknown" then waiting=true end end
  if not waiting then return end
 end
 G.pending=true; G.Paint(); G.Schedule()
end)
