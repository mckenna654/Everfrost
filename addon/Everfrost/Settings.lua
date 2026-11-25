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
local function pct(value) return string.format("%d%%",math.floor((value or 1)*100+0.5)) end
-- A weight as short as it can be written: 2.2, 0.06, 50.3, 12.
local function weightText(value)
 local text=string.format("%.2f",value or 0):gsub("%.?0+$","")
 return text=="" and "0" or text
end
local function choiceRow(row,current)
 for _,b in ipairs(row) do b:SetEnabled(b.value~=current) end
end
function S:Refresh()
 if not window or not api then return end
 local db=api.DB(); local state=api.State(); local hud=db.hud or {}
 window.status:SetText(state.className.." / Level "..state.level..(state.pending and " / Changes after combat" or ""))
 for name,page in pairs(window.pages) do
  page:SetShown(name==self.page)
  -- The stat weights page has no tab of its own: it belongs to Gear & Loot.
  local tab=window.tabs[name]
  if tab then tab:SetTabSelected(name==self.page or (name=="Gear" and self.page=="Weights")) end
 end
 -- Rotation
 local guide=window.pages.Guide
 guide.detected:SetText("Detected: "..state.detected)
 guide.note:SetText((state.levelingHint or NS.gearLevelNote)..(state.talents and ("\n"..state.talents) or ""))
 for index,row in ipairs(guide.rows) do
  local value=index-2
  if index==1 then value=nil end
  row:SetChecked(db.spec==value)
  row.label:SetText(index==1 and "Automatic" or index==2 and "Levelling" or (NS.trees[state.class] or {})[index-2] or "Unavailable")
 end
 choiceRow(guide.modes,hud.mode)
 local modeLabels=NS.Modes and NS.Modes.label or {}
 guide.modeNote:SetText(hud.mode=="auto" and ("Automatic: now "..(modeLabels[state.activeMode or "single"] or "single target")..".") or "Manual: stays until you change it.")
 guide.role:SetShown(state.hasRole); guide.role:SetText("View: "..state.roleLabel)
 guide.assist:SetChecked(hud.source=="assist")
 guide.assistNote:SetText(state.assistReason and ("Not available here: "..state.assistReason.." Everfrost's guide priority is used instead.")
  or "NOW comes from the game's own suggestion, which can see cooldowns and resources. The upcoming icons follow the guide.")
 guide.updating=true; guide.upcoming:SetValue(hud.upcoming or 3); guide.updating=false
 guide.upcomingValue:SetText(tostring(hud.upcoming or 3))
 guide.utility:SetText("Defensive row: "..(hud.utility=="on" and "On" or hud.utility=="off" and "Off" or ("Tanks only"..(state.tank and " (on)" or " (off)"))))
 -- HUD
 local panel=window.pages.Panel
 local shown=state.panelShown; if shown==nil then shown=not db.hidden end
 panel.visible:SetChecked(shown); panel.locked:SetChecked(db.locked==true); panel.minimap:SetChecked(db.minimap~=false)
 panel.combatOnly:SetChecked(hud.combatOnly~=false); panel.preview:SetChecked(hud.preview==true)
 panel.animate:SetChecked(hud.animate~=false)
 choiceRow(panel.layouts,hud.layout)
 panel.layoutNote:SetText(NS.HUD and NS.HUD.layoutHelp[hud.layout] or "")
 panel.scaleLabel:SetText(state.layout=="pad" and "Size (controller)" or "Size (keyboard)")
 local scale=state.layoutScale or db.scale or 1
 panel.scale:SetText(pct(scale)); panel.opacity:SetText(pct(db.opacity))
 panel.updating=true
 panel.slider:SetValue(scale); panel.opacitySlider:SetValue((db.opacity or 1)*100)
 panel.updating=false
 -- Controller
 local input=window.pages.Input
 choiceRow(input.modes,hud.input)
 input.autoSwitch:SetChecked(hud.autoSwitch~=false)
 input.current:SetText("Using now: "..(state.layout=="pad" and "controller layout" or "keyboard and mouse layout")..
  (hud.input=="auto" and " (switches by itself)" or hud.input=="custom" and " (one position for both)" or " (fixed)"))
 -- Detection
 local detect=window.pages.Detect
 detect.auto:SetChecked(hud.autoDetect~=false); detect.count:SetChecked(hud.enemyCount~=false)
 detect.title:SetText("Thresholds for "..((NS.trees[state.class] or {})[state.spec] or "Levelling").." "..state.className)
 detect.updating=true
 detect.cleave:SetValue(state.cleave or 2); detect.aoe:SetValue(state.aoe or 3)
 detect.grace:SetValue(hud.grace or 1.5); detect.stale:SetValue(hud.stale or 5)
 detect.updating=false
 detect.cleaveValue:SetText(tostring(state.cleave or 2)); detect.aoeValue:SetText(tostring(state.aoe or 3))
 detect.graceValue:SetText(string.format("%.1fs",hud.grace or 1.5)); detect.staleValue:SetText(string.format("%ds",hud.stale or 5))
 -- Gear
 local gear=window.pages.Gear
 gear.enabled:SetChecked(db.gear~=false)
 gear.priorityTitle:SetText(state.gearTitle or "Current stat priority")
 gear.priority:SetText(state.priority or state.gearReason or "Choose a specialisation or spend talent points to score gear.")
 gear.source:SetText(state.gearSource and (state.gearSource..".") or "")
 gear.empty:SetText(state.emptySlots or "")
 gear.rescan:SetEnabled(not InCombatLockdown())
 gear.weights:SetEnabled(state.gearProfile~=nil)
 -- Stat weights: the active profile's numbers, yours in gold.
 local weights=window.pages.Weights
 local p=state.gearProfile
 weights.profile=p
 local base=p and (p.base or p)
 local changed=0
 for _,row in ipairs(weights.rows) do
  row.box:SetShown(p~=nil); row.label:SetShown(p~=nil)
  if p then
   local value=NS.GearWeight(p,row.key)
   local mine=math.abs(value-NS.GearWeight(base,row.key))>1e-9
   if mine then changed=changed+1; row.label:SetTextColor(1,0.82,0) else row.label:SetTextColor(1,1,1) end
   -- Never overwrite a number while it is being typed.
   if not row.box:HasFocus() then row.box:SetText(weightText(value)) end
  end
 end
 if p then
  weights.title:SetText("Stat weights: "..(p.starter and (state.className.." starter (levels 1-9)") or ((p.specName or "")..(p.focusLabel and (" / "..p.focusLabel) or ""))))
  local origin=base.sim and ("Defaults: "..NS.gearWeightSource.name.." simulator, "..base.sim.." preset ("..NS.gearWeightSource.url.."). Level 60 raid values; Stamina and armour are Everfrost's levelling allowance.")
   or base.starter and "Defaults: an Everfrost starter estimate from your class's usual stats."
   or "Defaults: an Everfrost estimate from the Icy Veins stat order. No simulator publishes weights for this spec yet."
  weights.source:SetText(origin)
  weights.changed:SetText(changed==0 and "Using the defaults." or (changed.." changed (gold). Reset brings back the defaults."))
 else
  weights.title:SetText("Stat weights")
  weights.source:SetText(state.gearReason or "Choose a specialisation or spend talent points to score gear.")
  weights.changed:SetText("")
 end
 weights.reset:SetEnabled(p~=nil and changed>0)
 local choices=NS.GearFocusChoices and NS.GearFocusChoices(state.class,state.gearSpec or 0)
 gear.focus:SetShown(choices~=nil and #choices>1)
 if choices and #choices>1 then
  local current=type(db.gearFocus)=="table" and db.gearFocus[state.class..tostring(state.gearSpec)] or nil
  local labelText=choices[1].label
  for _,choice in ipairs(choices) do if choice.key==current then labelText=choice.label end end
  gear.focus:SetText("Scoring: "..labelText)
 end
 -- Talents
 local talents=window.pages.Talents
 talents.enabled:SetChecked(db.talents~=false)
 local upcoming=db.talents~=false and NS.Talents and NS.Talents.Upcoming and NS.Talents.Upcoming(5)
 talents.summary:SetText(db.talents==false and "Talent highlights are off." or (state.talents or "Choose a specialisation, or spend a talent point, to see its Icy Veins build.")
  ..(upcoming and #upcoming>1 and ("\n\nComing up, by level:\n"..table.concat(upcoming,"\n")) or ""))
 positionMinimap()
end
local function slider(parent,title,x,y,low,high,step,lowText,highText,onChange)
 label(parent,title,12,x,y)
 local s=CreateFrame("Slider",nil,parent,"UISliderTemplateWithLabels")
 s:SetPoint("TOPLEFT",x+150,y+4); s:SetSize(260,16)
 s:SetOrientation("HORIZONTAL"); s:SetMinMaxValues(low,high)
 s:SetValueStep(step); s:SetObeyStepOnDrag(true)
 s.Text:Hide(); s.Low:SetText(lowText); s.High:SetText(highText)
 s:SetScript("OnValueChanged",function(_,value) if not parent.updating then onChange(value) end end)
 local value=label(parent,"",12,x+420,y,60); value:SetJustifyH("RIGHT")
 return s,value
end
local function choices(parent,y,list,action,width)
 local row={}
 for index,entry in ipairs(list) do
  local b=button(parent,entry[2],(index-1)*((width or 112)+6),y,width or 112,function() action(entry[1]) end)
  b.value=entry[1]; row[index]=b
 end
 return row
end
local function hudSet(key,value) api.DB().hud[key]=value; api.Redraw() end
function NS.CreateSettings(controller)
 api=controller
 if window then S:Refresh(); return end
 window=CreateFrame("Frame","EverfrostSettingsWindow",UIParent,"DefaultPanelTemplate")
 S.window=window
 window:SetSize(560,430); window:SetPoint("CENTER"); window:SetFrameStrata("DIALOG")
 window:SetClampedToScreen(true); window:SetMovable(true); window:EnableMouse(true)
 window.TitleContainer.TitleText:SetText("Everfrost Settings")
 window:Hide()
 -- The HUD shows while settings are open, so changes can be seen as they're made.
 window:SetScript("OnShow",function() if NS.UpdateHUD then NS.UpdateHUD() end end)
 window:SetScript("OnHide",function() if NS.UpdateHUD then NS.UpdateHUD() end end)
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
 local tabs={{key="Guide",label="Rotation"},{key="Panel",label="HUD"},{key="Input",label="Controller"},
  {key="Detect",label="Detection"},{key="Gear",label="Gear & Loot"},{key="Talents",label="Talents"}}
 local tabX=14
 for _,entry in ipairs(tabs) do
  local name=entry.key
  local pageName=name
  -- Native tab art without a TabSystem owner; selection stays in this controller.
  local tab=CreateFrame("Button",nil,window,"TabSystemButtonArtTemplate")
  tab.isTabOnTop=true; tab:HandleRotation(); tab:SetSize(84,28); tab:SetTabHeight(28)
  tab:SetPoint("TOPLEFT",tabX,-34); tab:SetText(entry.label)
  tabX=tabX+84+4
  tab:SetScript("OnClick",function() S.page=pageName; S:Refresh() end); window.tabs[name]=tab
  local page=CreateFrame("Frame",nil,window.inset)
  page:SetPoint("TOPLEFT",16,-14); page:SetSize(510,310)
  label(page,entry.label,14,0,0)
  window.pages[name]=page
 end
 -- Rotation: guide, mode and what the HUD recommends.
 local guide=window.pages.Guide; guide.rows={}
 guide.detected=label(guide,"",11,120,-4,390)
 for index=1,5 do
  local value=index-2
  if index==1 then value=nil end
  local row=check(guide,"",-24-(index-1)*22,function() api.SelectGuide(value) end)
  row.label:SetWidth(200); guide.rows[index]=row
 end
 guide.note=label(guide,"",11,240,-26,270); guide.note:SetTextColor(0.8,0.8,0.8)
 label(guide,"Rotation mode",12,0,-140)
 guide.modes=choices(guide,-158,{{"auto","Automatic"},{"single","Single"},{"cleave","Cleave"},{"aoe","AoE"}},function(mode) api.SetMode(mode) end,112)
 guide.modeNote=label(guide,"",11,0,-184,500); guide.modeNote:SetTextColor(0.8,0.8,0.8)
 guide.assist=check(guide,"NOW from Blizzard's rotation assistant, when the game offers it",-200,function(on) hudSet("source",on and "assist" or "guide") end)
 guide.assistNote=label(guide,"",11,26,-224,480); guide.assistNote:SetTextColor(0.8,0.8,0.8)
 guide.upcoming,guide.upcomingValue=slider(guide,"Upcoming icons",0,-258,0,6,1,"0","6",function(value) hudSet("upcoming",math.floor(value+0.5)) end)
 guide.utility=button(guide,"Defensive row",0,-284,250,function()
  local hud=api.DB().hud
  hudSet("utility",hud.utility=="auto" and "on" or hud.utility=="on" and "off" or "auto")
 end)
 guide.utility:SetScript("OnEnter",function(self)
  GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText("Defensive and utility row",1,1,1)
  GameTooltip:AddLine("Interrupts, taunts and defensive cooldowns you've learned, apart from the damage track. Everfrost can't see how much danger you're in, so these show as available, and big cooldowns are marked situational.",0.8,0.8,0.8,true)
  GameTooltip:Show()
 end)
 guide.utility:SetScript("OnLeave",function() GameTooltip:Hide() end)
 guide.role=button(guide,"View",260,-284,250,function() api.ToggleRole() end)
 -- HUD: layout and look.
 local panel=window.pages.Panel
 panel.layouts=choices(panel,-24,{{"track","Guitar Hero"},{"classic","Classic"},{"minimal","Minimal"},{"tank","Tank"}},function(layout) hudSet("layout",layout) end,112)
 panel.layoutNote=label(panel,"",11,0,-50,500); panel.layoutNote:SetTextColor(0.8,0.8,0.8)
 panel.visible=check(panel,"Show the rotation HUD",-68,function(on) command(on and "show" or "hide") end)
 panel.combatOnly=check(panel,"Only in combat (missing buffs still show)",-92,function(on) hudSet("combatOnly",on) end)
 panel.preview=check(panel,"Preview out of combat",-116,function(on) hudSet("preview",on) end)
 panel.locked=check(panel,"Lock position",-140,function(on) command(on and "lock" or "unlock") end)
 panel.animate=check(panel,"Animate the track",-164,function(on) hudSet("animate",on) end)
 panel.minimap=check(panel,"Show minimap button",-188,function(on) command(on and "minimap on" or "minimap off") end)
 panel.slider,panel.scale=slider(panel,"Size",0,-222,0.6,2,0.1,"60%","200%",function(value) command("scale "..string.format("%.1f",value)) end)
 panel.scaleLabel=label(panel,"",11,0,-238,150); panel.scaleLabel:SetTextColor(0.8,0.8,0.8)
 panel.opacitySlider,panel.opacity=slider(panel,"Opacity",0,-256,10,100,5,"10%","100%",function(value) command("opacity "..math.floor(value+0.5)) end)
 panel.reset=button(panel,"Reset position & size",0,-286,180,function() command("reset") end)
 panel.resetAll=button(panel,"Reset HUD settings",190,-286,160,function()
  api.ResetHUD()
 end)
 -- Controller: which layout, and whether it follows the device in use.
 local input=window.pages.Input
 label(input,"Each layout keeps its own position and size. The controller layout starts where you put the keyboard one; move the HUD while using a controller to give it a place of its own.",11,0,-24,500):SetTextColor(0.8,0.8,0.8)
 input.modes=choices(input,-58,{{"auto","Automatic"},{"pad","Controller"},{"kbm","Keyboard"},{"custom","One position"}},function(mode) command("input "..mode) end,112)
 input.autoSwitch=check(input,"Switch as soon as the game changes input style",-92,function(on) hudSet("autoSwitch",on) end)
 input.current=label(input,"",12,0,-124,500)
 label(input,"Automatic follows the game's own input style (gamepad mode and ConsolePort use it). A connected controller on its own isn't treated as in use. Controller layout: larger icons (60 px NOW, 44 px upcoming), placed above the gamepad action bars. Keyboard layout: 48 px and 36 px, below your character.",11,0,-150,500):SetTextColor(0.8,0.8,0.8)
 input.reset=button(input,"Reset this layout's position",0,-230,220,function() command("reset") end)
 -- Detection: when automatic mode switches.
 local detect=window.pages.Detect
 detect.auto=check(detect,"Detect single target, cleave and AoE automatically",-24,function(on) hudSet("autoDetect",on) end)
 detect.count=check(detect,"Show the enemy estimate next to the mode",-48,function(on) hudSet("enemyCount",on) end)
 detect.title=label(detect,"",12,0,-82,500); detect.title:SetTextColor(1,0.82,0)
 local function threshold(field,value)
  local db=api.DB(); local key=api.State().specKey
  db.hud.thresholds=db.hud.thresholds or {}
  local t=db.hud.thresholds[key] or {}
  t[field]=math.floor(value+0.5); db.hud.thresholds[key]=t; api.Redraw()
 end
 detect.cleave,detect.cleaveValue=slider(detect,"Cleave from",0,-106,2,5,1,"2","5",function(value) threshold("cleave",value) end)
 detect.aoe,detect.aoeValue=slider(detect,"AoE from",0,-136,2,8,1,"2","8",function(value) threshold("aoe",value) end)
 detect.grace,detect.graceValue=slider(detect,"Step-down delay",0,-170,0,5,0.5,"0s","5s",function(value) hudSet("grace",value) end)
 detect.stale,detect.staleValue=slider(detect,"Forget unseen after",0,-200,1,15,1,"1s","15s",function(value) hudSet("stale",value) end)
 label(detect,"Enemies are counted from enemy nameplates in combat: alive, attackable, fighting and, where the game shares threat, on your group's list. Turn enemy nameplates on. The count is an estimate; when the game won't share it, the HUD shows ? and stays on single target. Use the mode buttons or key bindings to override.",11,0,-232,500):SetTextColor(0.8,0.8,0.8)
 -- Gear
 local gear=window.pages.Gear
 gear.enabled=check(gear,"Highlight gear upgrades (bags, loot rolls, quest rewards, vendors)",-30,function(on) command(on and "gear on" or "gear off") end)
 label(gear,"A thin green border marks an upgrade, with how much better it is as a green percentage. Hover an item for its comparison and any required weapon partner. Everfrost never rolls, equips or picks a reward for you.",11,0,-62,500):SetTextColor(0.8,0.8,0.8)
 gear.levelNote=label(gear,NS.gearLevelNote,11,0,-98,500); gear.levelNote:SetTextColor(1,0.82,0)
 gear.priorityTitle=label(gear,"Current stat priority",12,0,-132,500); gear.priorityTitle:SetTextColor(1,0.82,0)
 gear.priority=label(gear,"",12,0,-154,500); gear.priority:SetHeight(48)
 gear.source=label(gear,"",11,0,-203,500); gear.source:SetTextColor(0.8,0.8,0.8)
 gear.empty=label(gear,"",11,0,-217,500); gear.empty:SetTextColor(0.8,0.8,0.8)
 gear.rescan=button(gear,"Rescan bags",0,-232,124,function() command("refresh") end)
 gear.rescan:SetScript("OnEnter",function(self)
  GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText("Rescan bags",1,1,1)
  GameTooltip:AddLine("Refresh gear comparisons outside combat. Scores are estimates; check item effects and group loot rules.",0.8,0.8,0.8,true)
  GameTooltip:Show()
 end)
 gear.rescan:SetScript("OnLeave",function() GameTooltip:Hide() end)
 gear.focus=button(gear,"Scoring",134,-232,240,function()
  local state=api.State(); local db=api.DB()
  local list=NS.GearFocusChoices and NS.GearFocusChoices(state.class,state.gearSpec or 0)
  if not list or #list<2 then return end
  local key=state.class..tostring(state.gearSpec)
  db.gearFocus=type(db.gearFocus)=="table" and db.gearFocus or {}
  local current,nextKey=db.gearFocus[key],list[1].key
  for index,choice in ipairs(list) do if choice.key==current then nextKey=list[index%#list+1].key end end
  if current==nil then nextKey=list[2].key end
  db.gearFocus[key]=nextKey
  command("refresh")
 end)
 gear.weights=button(gear,"Stat weights",384,-232,126,function() S.page="Weights"; S:Refresh() end)
 gear.weights:SetScript("OnEnter",function(self)
  GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText("Stat weights",1,1,1)
  GameTooltip:AddLine("See the value Everfrost gives each stat for your spec, where the numbers come from, and change any of them.",0.8,0.8,0.8,true)
  GameTooltip:Show()
 end)
 gear.weights:SetScript("OnLeave",function() GameTooltip:Hide() end)
 -- Stat weights: a page of Gear & Loot, reached from its button rather than a tab.
 local weights=CreateFrame("Frame",nil,window.inset)
 weights:SetPoint("TOPLEFT",16,-14); weights:SetSize(510,310)
 window.pages.Weights=weights
 weights.title=label(weights,"Stat weights",14,0,0)
 weights.source=label(weights,"",11,0,-22,500); weights.source:SetTextColor(0.8,0.8,0.8)
 weights.rows={}
 local function commit(row)
  local p=weights.profile
  if not p then return end
  local text=row.box:GetText()
  local value=type(text)=="string" and tonumber((text:gsub(",","."))) or nil
  -- Anything that isn't a number from 0 to the limit is dropped and the old value comes back.
  if value then NS.GearSetWeight(p,row.key,value) end
  S:Refresh()
 end
 for index,entry in ipairs(NS.gearWeightRows or {}) do
  local column,line=math.floor((index-1)/7),(index-1)%7
  local x,y=column*172,-58-line*24
  local row={key=entry[1]}
  row.label=label(weights,entry[2],12,x,y-4,118)
  local box=CreateFrame("EditBox",nil,weights,"InputBoxTemplate")
  box:SetSize(42,20); box:SetPoint("TOPLEFT",x+124,y); box:SetAutoFocus(false); box:SetMaxLetters(6)
  box:SetScript("OnEnterPressed",function(self) self:ClearFocus() end)
  box:SetScript("OnEscapePressed",function(self) row.cancelled=true; self:ClearFocus() end)
  box:SetScript("OnEditFocusLost",function()
   if row.cancelled then row.cancelled=nil; S:Refresh() else commit(row) end
  end)
  row.box=box; weights.rows[index]=row
 end
 label(weights,"The value of one point of each stat, or of 1% where marked. Only the sizes relative to each other matter. Type a number and press Enter; 0 ignores a stat.",11,0,-230,500):SetTextColor(0.8,0.8,0.8)
 weights.changed=label(weights,"",11,0,-262,500); weights.changed:SetTextColor(1,0.82,0)
 weights.reset=button(weights,"Reset to defaults",0,-284,150,function()
  if weights.profile then NS.GearResetWeights(weights.profile) end
  S:Refresh()
 end)
 weights.back=button(weights,"Back to Gear & Loot",160,-284,170,function() S.page="Gear"; S:Refresh() end)
 -- Talents
 local talents=window.pages.Talents
 talents.enabled=check(talents,"Highlight the next talent in the Icy Veins build",-30,function(on) command(on and "talents on" or "talents off") end)
 talents.summary=label(talents,"",12,0,-64,500)
 label(talents,"Open the talent window with a point to spend: the next talent glows, and every talent's tooltip shows its place in the build.",11,0,-270,500):SetTextColor(0.8,0.8,0.8)
 window.status=label(window,"",11,16,-409,520); window.status:SetTextColor(0.6,0.6,0.6)
 UISpecialFrames=UISpecialFrames or {}; UISpecialFrames[#UISpecialFrames+1]="EverfrostSettingsWindow"
 createMinimap(); registerSettings(); S:Refresh()
end
