local _, NS = ...
local S={page="Guide"}
NS.Settings=S
local api,window,minimap
local function label(parent,value,size,x,y,width)
 local font=(size or 12)>=14 and "GameFontNormalLarge" or (size or 12)<=11 and "GameFontHighlightSmall" or "GameFontHighlight"
 local t=parent:CreateFontString(nil,"OVERLAY",font)
 t:SetPoint("TOPLEFT",x,y)
 t:SetJustifyH("LEFT"); t:SetJustifyV("TOP"); t:SetText(value)
 if width then t:SetWidth(width); t:SetWordWrap(true) end
 return t
end
local function button(parent,value,x,y,width,action)
 local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
 b:SetSize(width or 130,22); b:SetPoint("TOPLEFT",x,y); b:SetText(value)
 b:SetScript("OnClick",action); return b
end
local function check(parent,value,y,action)
 local b=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate")
 b:SetSize(24,24); b:SetPoint("TOPLEFT",0,y)
 b.label=label(b,value,12,26,-6,350)
 b:SetScript("OnClick",function(self) action(self:GetChecked()==true) end)
 return b
end
local function command(value) api.Command(value) end
local function positionMinimap()
 if not minimap then return end
 local db=api.DB()
 local angle=db.minimapAngle
 if type(angle)~="number" or angle~=angle or angle==math.huge or angle==-math.huge then angle=225 end
 local width=Minimap:GetWidth()
 local radius=type(width)=="number" and width/2+10 or 80
 minimap:ClearAllPoints()
 minimap:SetPoint("CENTER",Minimap,"CENTER",math.cos(math.rad(angle))*radius,math.sin(math.rad(angle))*radius)
 minimap:SetShown(db.minimap~=false)
end
local function createMinimap()
 if not Minimap or minimap then return end
 minimap=CreateFrame("Button","EverfrostMinimapButton",Minimap)
 S.minimap=minimap
 minimap:SetSize(31,31); minimap:SetFrameStrata("MEDIUM"); minimap:SetFrameLevel(Minimap:GetFrameLevel()+5)
 minimap:RegisterForClicks("LeftButtonUp","RightButtonUp"); minimap:RegisterForDrag("LeftButton")
 minimap:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
 local icon=minimap:CreateTexture(nil,"BACKGROUND")
 icon:SetTexture("Interface\\AddOns\\Everfrost\\Media\\Icon.tga")
 icon:SetSize(20,20); icon:SetPoint("TOPLEFT",7,-5); icon:SetTexCoord(0.08,0.92,0.08,0.92)
 local border=minimap:CreateTexture(nil,"OVERLAY")
 border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); border:SetSize(54,54); border:SetPoint("TOPLEFT")
 minimap:SetScript("OnClick",function(_,mouse)
  if mouse=="RightButton" then command(api.DB().hidden and "show" or "hide") else S:Toggle() end
 end)
 minimap:SetScript("OnEnter",function(self)
  GameTooltip:SetOwner(self,"ANCHOR_LEFT"); GameTooltip:SetText("Everfrost",1,0.82,0)
  GameTooltip:AddLine("Left-click: settings",1,1,1)
  GameTooltip:AddLine("Right-click: show / hide panel",0.8,0.8,0.8)
  GameTooltip:AddLine("Drag to move around the minimap",0.8,0.8,0.8); GameTooltip:Show()
 end)
 minimap:SetScript("OnLeave",function() GameTooltip:Hide() end)
 minimap:SetScript("OnDragStart",function(self)
  if InCombatLockdown() then return end
  GameTooltip:Hide()
  self:SetScript("OnUpdate",function()
   if InCombatLockdown() then self:SetScript("OnUpdate",nil); return end
   local x,y=GetCursorPosition(); local cx,cy=Minimap:GetCenter(); local scale=Minimap:GetEffectiveScale()
   if not (NS.Public(x) and NS.Public(y) and type(x)=="number" and type(y)=="number" and cx and cy and scale and scale>0) then return end
   x,y=x/scale-cx,y/scale-cy
   local angle
   if x>0 then angle=math.atan(y/x)
   elseif x<0 then angle=math.atan(y/x)+(y>=0 and math.pi or -math.pi)
   else angle=y>=0 and math.pi/2 or -math.pi/2 end
   api.DB().minimapAngle=math.deg(angle); positionMinimap()
  end)
 end)
 minimap:SetScript("OnDragStop",function(self) self:SetScript("OnUpdate",nil) end)
 minimap:SetScript("OnHide",function(self) self:SetScript("OnUpdate",nil); GameTooltip:Hide() end)
end
function S:Refresh()
 if not window or not api then return end
 local db=api.DB(); local state=api.State()
 window.status:SetText(state.className.."  /  Level "..state.level..(state.pending and "  /  Changes after combat" or ""))
 for name,page in pairs(window.pages) do
  page:SetShown(name==self.page)
  window.tabs[name]:SetTabSelected(name==self.page)
 end
 local guide=window.pages.Guide
 guide.detected:SetText("Detected: "..state.detected)
 guide.note:SetText(state.levelingHint or NS.gearLevelNote)
 for index,row in ipairs(guide.rows) do
  local value=index-2
  if index==1 then value=nil end
  row:SetChecked(db.spec==value)
  row.label:SetText(index==1 and "Automatic" or index==2 and "Leveling" or (NS.trees[state.class] or {})[index-2] or "Unavailable")
 end
 guide.single:SetEnabled(db.aoe==true); guide.aoe:SetEnabled(db.aoe~=true)
 guide.role:SetShown(state.hasRole); guide.role:SetText("View: "..state.roleLabel)
 local panel=window.pages.Panel
 panel.visible:SetChecked(not db.hidden); panel.locked:SetChecked(db.locked==true); panel.minimap:SetChecked(db.minimap~=false)
 panel.scale:SetText(string.format("%d%%",math.floor((db.scale or 1)*100+0.5)))
 panel.updating=true; panel.slider:SetValue(db.scale or 1); panel.updating=false
 local gear=window.pages.Gear
 gear.enabled:SetChecked(db.gear~=false)
 gear.priorityTitle:SetText(state.gearTitle or "Current stat priority")
 gear.priority:SetText(state.priority or (state.gearReason==NS.gearLevelNote and "Not active yet.") or state.gearReason or "Choose a specialization or spend talent points to score gear.")
 gear.rescan:SetEnabled(not InCombatLockdown())
 positionMinimap()
end
function S:Open()
 if not window then return end
 if InCombatLockdown() then print("|cffb8c6d9Everfrost:|r Open settings after combat."); return end
 api.CloseGuide(); self:Refresh(); window:Show(); window:Raise()
end
function S:Toggle()
 if window and window:IsShown() then window:Hide() else self:Open() end
end
local function registerSettings()
 local panel=CreateFrame("Frame","EverfrostOptionsPanel",UIParent)
 panel.name="Everfrost"; panel:Hide(); S.gamePanel=panel
 label(panel,"Everfrost",16,20,-20)
 label(panel,"Basic spell guides and gear priorities",12,20,-46,400)
 label(panel,"Configure guides, panel layout and gear upgrade hints for this character.",11,20,-72,400)
 S.gameButton=button(panel,"Open Everfrost settings",20,-110,200,function() S:Open() end)
 label(panel,"You can also use /everfrost or the minimap button.",11,20,-148,400)
 if Settings and type(Settings.RegisterCanvasLayoutCategory)=="function" and type(Settings.RegisterAddOnCategory)=="function" then
  local result=NS.Call(Settings.RegisterCanvasLayoutCategory,panel,"Everfrost")
  if result and result[1] then NS.Call(Settings.RegisterAddOnCategory,result[1]); S.category=result[1]; return end
 end
 if type(InterfaceOptions_AddCategory)=="function" then NS.Call(InterfaceOptions_AddCategory,panel) end
end
function NS.CreateSettings(controller)
 api=controller
 if window then S:Refresh(); return end
 window=CreateFrame("Frame","EverfrostSettingsWindow",UIParent,"DefaultPanelTemplate")
 S.window=window
 window:SetSize(448,388); window:SetPoint("CENTER"); window:SetFrameStrata("DIALOG")
 window:SetClampedToScreen(true); window:SetMovable(true); window:EnableMouse(true)
 window.TitleContainer.TitleText:SetText("Everfrost Settings")
 window:Hide()
 local drag=CreateFrame("Frame",nil,window)
 drag:SetPoint("TOPLEFT",8,-1); drag:SetPoint("TOPRIGHT",-30,-1); drag:SetHeight(24)
 drag:EnableMouse(true); drag:RegisterForDrag("LeftButton")
 drag:SetScript("OnDragStart",function() window:StartMoving() end)
 drag:SetScript("OnDragStop",function() window:StopMovingOrSizing() end)
 local close=CreateFrame("Button",nil,window,"UIPanelCloseButton")
 close:SetPoint("TOPRIGHT",-2,-1); close:SetScript("OnClick",function() window:Hide() end)
 window.close=close; window.pages={}; window.tabs={}
 window.inset=CreateFrame("Frame",nil,window,"InsetFrameTemplate")
 window.inset:SetPoint("TOPLEFT",8,-62); window.inset:SetPoint("BOTTOMRIGHT",-8,30)
 local tabs={{key="Guide",label="Specialization",width=130},{key="Panel",label="Rotation Panel",width=130},{key="Gear",label="Gear Upgrades",width=130}}
 local tabX=18
 for _,entry in ipairs(tabs) do
  local name=entry.key
  local pageName=name
  -- Native tab art without a TabSystem owner; selection stays in this controller.
  local tab=CreateFrame("Button",nil,window,"TabSystemButtonArtTemplate")
  tab.isTabOnTop=true; tab:HandleRotation(); tab:SetSize(entry.width,28); tab:SetTabHeight(28)
  tab:SetPoint("TOPLEFT",tabX,-34); tab:SetText(entry.label)
  tabX=tabX+entry.width+6
  tab:SetScript("OnClick",function() S.page=pageName; S:Refresh() end); window.tabs[name]=tab
  local page=CreateFrame("Frame",nil,window.inset)
  page:SetPoint("TOPLEFT",16,-14); page:SetSize(400,270)
  label(page,entry.label,14,0,0)
  window.pages[name]=page
 end
 local guide=window.pages.Guide; guide.rows={}
 guide.detected=label(guide,"",11,0,-24,400)
 for index=1,5 do
  local value=index-2
  if index==1 then value=nil end
  guide.rows[index]=check(guide,"",-42-(index-1)*24,function() api.SelectGuide(value) end)
 end
 guide.note=label(guide,"",11,0,-172,400); guide.note:SetTextColor(0.7,0.7,0.7)
 guide.single=button(guide,"Single target",0,-212,140,function() command("single") end)
 guide.aoe=button(guide,"Multiple targets",148,-212,140,function() command("aoe") end)
 guide.role=button(guide,"View",0,-244,288,function() api.ToggleRole() end)
 local panel=window.pages.Panel
 panel.visible=check(panel,"Show reference panel",-30,function(on) command(on and "show" or "hide") end)
 panel.locked=check(panel,"Lock panel position",-58,function(on) command(on and "lock" or "unlock") end)
 panel.minimap=check(panel,"Show minimap button",-86,function(on) api.DB().minimap=on; S:Refresh() end)
 label(panel,"Panel size",12,0,-130)
 panel.scale=label(panel,"",12,352,-130,48); panel.scale:SetJustifyH("RIGHT")
 panel.slider=CreateFrame("Slider",nil,panel,"UISliderTemplateWithLabels")
 panel.slider:SetPoint("TOPLEFT",104,-126); panel.slider:SetSize(230,16)
 panel.slider:SetOrientation("HORIZONTAL"); panel.slider:SetMinMaxValues(0.6,2)
 panel.slider:SetValueStep(0.1); panel.slider:SetObeyStepOnDrag(true)
 panel.slider.Text:Hide(); panel.slider.Low:SetText("60%"); panel.slider.High:SetText("200%")
 panel.slider:SetScript("OnValueChanged",function(_,value)
  if not panel.updating then command("scale "..string.format("%.1f",value)) end
 end)
 label(panel,"Drag the panel header to move it. /everfrost opens settings even when the panel or minimap button is hidden.",11,0,-172,400):SetTextColor(0.7,0.7,0.7)
 panel.reset=button(panel,"Reset position & size",0,-220,180,function() command("reset") end)
 local gear=window.pages.Gear
 gear.enabled=check(gear,"Highlight gear upgrades",-30,function(on) command(on and "gear on" or "gear off") end)
 label(gear,"Upgrades pulse in the item's rarity colour. Hover an item for its comparison and any required weapon partner.",11,0,-62,400):SetTextColor(0.85,0.85,0.85)
 gear.levelNote=label(gear,NS.gearLevelNote,11,0,-98,400); gear.levelNote:SetTextColor(1,0.82,0)
 gear.priorityTitle=label(gear,"Current stat priority",12,0,-132,400); gear.priorityTitle:SetTextColor(1,0.82,0)
 gear.priority=label(gear,"",12,0,-154,400); gear.priority:SetHeight(66)
 gear.rescan=button(gear,"Rescan bags",0,-232,124,function() command("refresh") end)
 gear.rescan:SetScript("OnEnter",function(self)
  GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText("Rescan bags",1,1,1)
  GameTooltip:AddLine("Refresh gear comparisons outside combat. Scores are estimates; check item effects and group loot rules.",0.8,0.8,0.8,true)
  GameTooltip:Show()
 end)
 gear.rescan:SetScript("OnLeave",function() GameTooltip:Hide() end)
 window.status=label(window,"",11,16,-367,416); window.status:SetTextColor(0.7,0.7,0.7)
 UISpecialFrames=UISpecialFrames or {}; UISpecialFrames[#UISpecialFrames+1]="EverfrostSettingsWindow"
 createMinimap(); registerSettings(); S:Refresh()
end
