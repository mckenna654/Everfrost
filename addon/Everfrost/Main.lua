local _, NS=...
local frame,db,known=nil,nil,{}
local class,className,level,spec,status="","",1,0,""
local detectedSpec,detectedStatus=0,""
local detectedPoints,detectedSource=nil,nil
local gearSpec,gearReason=0,nil
local pending,scanError=false,nil
local inCombat=false
local hudDirty=false
local activeMode="single"
local lastResult
local function say(s) print("|cffb8c6d9Everfrost:|r "..s) end
local function text(parent,size,font)
 local t=parent:CreateFontString(nil,"OVERLAY",font or (size>=12 and "GameFontHighlight" or "GameFontHighlightSmall"))
 t:SetJustifyH("LEFT"); t:SetJustifyV("TOP"); return t
end
local function tip(owner,title,description)
 GameTooltip:SetOwner(owner,"ANCHOR_BOTTOM"); GameTooltip:SetText(title,1,1,1)
 GameTooltip:AddLine(description,0.75,0.8,0.86,true); GameTooltip:Show()
end
-- HUD settings, per character (EverfrostDB.hud). Version 2 added the HUD; version 1 had the
-- static panel and db.aoe, which becomes a manual AoE mode so nobody's choice is lost.
local hudDefaults={layout="track",upcoming=3,combatOnly=true,mode="auto",source="assist",utility="auto",
 enemyCount=true,autoDetect=true,input="auto",autoSwitch=true,animate=true,speed=1,preview=false,
 grace=1.5,stale=5,padScale=1}
-- HUD choices that follow you to a new character, like the panel's size and opacity always have.
local hudLookKeys={"layout","upcoming","combatOnly","source","utility","enemyCount","autoDetect","input","autoSwitch","animate","speed","padScale"}
local function sanitiseHUD(hud,legacyAoE)
 if type(hud)~="table" then hud={mode=legacyAoE and "aoe" or "auto"} end
 for key,value in pairs(hudDefaults) do
  if type(hud[key])~=type(value) then hud[key]=value end
 end
 local layouts={track=true,classic=true,minimal=true,tank=true}
 if not layouts[hud.layout] then hud.layout="track" end
 hud.mode=NS.Modes.Normal(hud.mode) or "auto"
 if hud.source~="assist" and hud.source~="guide" then hud.source="assist" end
 if hud.utility~="auto" and hud.utility~="on" and hud.utility~="off" then hud.utility="auto" end
 if hud.input~="auto" and hud.input~="pad" and hud.input~="kbm" and hud.input~="custom" then hud.input="auto" end
 hud.upcoming=math.max(0,math.min(6,math.floor(hud.upcoming)))
 hud.speed=math.max(0.5,math.min(2,hud.speed))
 hud.grace=math.max(0,math.min(5,hud.grace)); hud.stale=math.max(1,math.min(15,hud.stale))
 hud.padScale=math.max(0.6,math.min(2,hud.padScale))
 if type(hud.thresholds)~="table" then hud.thresholds={} end
 if type(hud.pad)~="table" then hud.pad=nil end
 return hud
end
local function refresh()
 if InCombatLockdown() then pending=true; return end
 local talentPointsAvailable
 detectedSpec,detectedStatus,talentPointsAvailable,detectedPoints,detectedSource=NS.DetectSpec(class)
 spec,status=detectedSpec,detectedStatus
 if db.spec==0 or (NS.trees[class] and NS.trees[class][db.spec]) then spec,status=db.spec,"Manual" end
 gearSpec,gearReason=spec,nil
 if level<NS.gearMinLevel then
  gearSpec=0
 elseif spec==0 then
  if not talentPointsAvailable then
   gearReason="Talent points are unavailable. Choose a specialisation on the Rotation page to score gear."
  elseif detectedSpec>0 then gearSpec=detectedSpec
  elseif detectedStatus=="Hybrid" then
   gearReason="Your talent trees are tied. Spend more points or choose a specialisation to score gear."
  else gearReason="No talent points spent yet. Spend a talent point or choose a specialisation to score gear." end
 end
 local spells,err=NS.ScanSpells(class)
 if spells then known=spells end
 scanError=err; pending=false
 if NS.Talents then
  -- The chosen tree's build, or the detected tree's while the general Levelling guide is shown.
  local tree=spec>0 and spec or detectedSpec
  NS.Talents.enabled=db.talents~=false
  NS.Talents.Refresh(class,tree,level,NS.trees[class] and NS.trees[class][tree])
  NS.Talents.Show()
 end
end
local render
local updateGuideMenu
local function selectGuide(value)
 db.spec=value
 if frame.guideMenu then frame.guideMenu:Hide() end
 refresh(); render()
end
local function effectiveRole(selectedSpec)
 local p=NS.profiles[class] and NS.profiles[class][selectedSpec or spec]
 if not p then return "damage" end
 if p.melee then
  if level>=30 and known["Strider Kick"] and db.role~="ranged" then return "melee" end
  return "ranged"
 end
 if p.healing then return db.role=="damage" and "damage" or "heal" end
 if p.bear then
  if known["Bear Form"] and (db.role=="bear" or not known["Cat Form"]) then return "bear" end
  return known["Cat Form"] and "damage" or "caster"
 end
 return "damage"
end
local function toggleRole()
 local p=NS.profiles[class] and NS.profiles[class][spec]
 if p and p.melee then db.role=effectiveRole()=="melee" and "ranged" or "melee"
 elseif p and p.healing then db.role=effectiveRole()=="heal" and "damage" or "heal"
 else db.role=effectiveRole()=="bear" and "damage" or "bear" end
 render()
end
-- Survival's melee view needs level 30 and Strider Kick, so until then there is nothing to switch.
local function hasRoleChoice(p)
 if not p then return false end
 if p.melee then return level>=30 and known["Strider Kick"]~=nil end
 -- Cat or Bear is a choice only with both forms learned.
 if p.bear then return known["Cat Form"]~=nil and known["Bear Form"]~=nil end
 return p.healing and true or false
end
local function roleLabel(role,p)
 return role=="melee" and "Melee" or role=="ranged" and "Ranged" or role=="heal" and "Heal" or role=="bear" and "Bear" or role=="caster" and "Caster" or (p and p.bear and "Cat" or "Damage")
end
local function emptySlotText()
 if not (NS.Gear and NS.Gear.EmptySlots) then return nil end
 local noWeapon,armor=NS.Gear.EmptySlots()
 local parts={}
 if noWeapon then parts[#parts+1]="No weapon equipped." end
 if armor>0 then parts[#parts+1]=armor..(armor==1 and " empty armour slot." or " empty armour slots.") end
 return #parts>0 and table.concat(parts," ") or nil,noWeapon
end
-- How the HUD looks is remembered for the whole account, so a new character starts with the
-- size, opacity and switches last used on another one. Guide choices and position stay per character.
local lookKeys={"scale","opacity","minimap","minimapAngle","gear","locked"}
local function rememberLook()
 if type(EverfrostAccountDB)~="table" then EverfrostAccountDB={} end
 for _,key in ipairs(lookKeys) do EverfrostAccountDB[key]=db[key] end
 local hud={}
 for _,key in ipairs(hudLookKeys) do hud[key]=db.hud[key] end
 EverfrostAccountDB.hud=hud
end
-- Past the guide's last level there is nothing to show, so the HUD steps aside (once, with a
-- line in chat) instead of leaving an empty box on screen. /everfrost show brings it back.
local function pastGuide() return level>NS.maxLevel end
local function panelShown() return not db.hidden and (not pastGuide() or db.showPastGuide==true) end

-------------------------------------------------------------------------------
-- Layout: controller or keyboard and mouse, each with its own position and size.
-------------------------------------------------------------------------------
-- While a layout is being placed from Settings > Controller (NS.Input.placing), the HUD stays
-- on that layout whatever device is in use: dragging needs the mouse, and the mouse would
-- otherwise switch the HUD back to the keyboard layout before the controller one could be moved.
local function layoutKey() return NS.Input.placing or NS.Input.Layout(db.hud.input) end
-- The HUD can be dragged and resized when unlocked, and always while a layout is being placed.
local function movable() return not db.locked or NS.Input.placing~=nil end
local function layoutScale() return layoutKey()=="pad" and db.hud.padScale or db.scale end
local defaultPositions={
 -- Below the character, above the standard action bars.
 kbm={"CENTER","CENTER",0,-190},
 -- Higher, clearing the gamepad action bars and their button prompts at the bottom.
 pad={"CENTER","CENTER",0,-120},
}
local function applyPosition()
 if not frame then return end
 local key=layoutKey()
 frame:SetScale(layoutScale())
 frame:ClearAllPoints()
 local function placed(spot)
  return spot and spot.point and spot.relativePoint and type(spot.x)=="number" and type(spot.y)=="number" and spot or nil
 end
 local keyboard=placed(db.point and {point=db.point,relativePoint=db.relativePoint,x=db.x,y=db.y})
 local saved=keyboard
 if key=="pad" then
  saved=placed(db.hud.pad)
  -- A controller layout that has never been moved starts where the keyboard layout was put,
  -- not back in the middle of the screen. Offsets are in the frame's own scale, so they are
  -- converted to keep the same spot on screen at the controller size.
  if not saved and keyboard then
   local ratio=(db.scale or 1)/layoutScale()
   saved={point=keyboard.point,relativePoint=keyboard.relativePoint,x=keyboard.x*ratio,y=keyboard.y*ratio}
  end
 end
 if saved then
  frame:SetPoint(saved.point,UIParent,saved.relativePoint,saved.x,saved.y)
 else
  local d=defaultPositions[key]; frame:SetPoint(d[1],UIParent,d[2],d[3],d[4])
 end
end
local function savePosition(point,relativePoint,x,y)
 if layoutKey()=="pad" then db.hud.pad={point=point,relativePoint=relativePoint,x=x,y=y}
 else db.point,db.relativePoint,db.x,db.y=point,relativePoint,x,y end
end
local function setScale(value)
 if layoutKey()=="pad" then db.hud.padScale=value else db.scale=value end
 if frame then frame:SetScale(value) end
end
local function resetPosition()
 if layoutKey()=="pad" then db.hud.pad=nil else db.point,db.relativePoint,db.x,db.y=nil,nil,nil,nil end
 applyPosition()
end

-------------------------------------------------------------------------------
-- Rotation: mode, engine and drawing.
-------------------------------------------------------------------------------
local function specKey() return class..tostring(spec) end
local function currentMode()
 if db.hud.mode~="auto" then return db.hud.mode end
 if not db.hud.autoDetect then return "single" end
 local cleave,aoe=NS.Modes.Thresholds(db.hud,specKey())
 -- Out of combat, or when the game won't say how many enemies there are, the safe default is
 -- single target; the HUD says the count is unknown rather than guessing.
 if not inCombat then NS.Modes.Reset(); return "single" end
 return NS.Modes.Auto(NS.Enemies.count,cleave,aoe,db.hud.grace)
end
local function utilityRows()
 local rows={}
 for _,entry in ipairs(NS.utility[class] or {}) do
  local spell=known[entry.name]
  if spell and level>=(spell.level or 0) then
   rows[#rows+1]={name=entry.name,key=entry.name,kind=entry.kind,major=entry.major,spell=spell}
  end
 end
 return rows
end
local function showUtility(role)
 local setting=db.hud.utility
 if setting=="on" then return true end
 if setting=="off" then return false end
 return NS.IsTank(class,spec,role) and true or false
end
local function modeText()
 local label=NS.Modes.short[db.hud.mode]
 if db.hud.mode=="auto" then label=label.." · "..NS.Modes.short[activeMode] end
 if db.hud.enemyCount and db.hud.mode=="auto" and inCombat then
  local count=NS.Enemies.count
  label=label.."   "..(count and ("~"..count) or "?")
 end
 return label
end
-- A short line under the icons, out of combat only: a missing weapon, or changes held until
-- combat ends. A missing weapon also brings the HUD up out of combat, like a missing buff.
local function captionText()
 local _,noWeapon=emptySlotText()
 if noWeapon then return "No weapon equipped: check your bags or a vendor",true end
 if pending then return "Updates after combat" end
 return ""
end
local function hudVisible(result,urgent)
 if not panelShown() then return false end
 if urgent and not inCombat then return true end
 if inCombat or not db.hud.combatOnly or db.hud.preview or frame.moving==true then return true end
 if NS.Settings and NS.Settings.window and NS.Settings.window:IsShown() then return true end
 -- Out of combat, a missing buff (Righteous Fury, a seal, a stance) still shows as a reminder.
 return result~=nil and #result.reminders>0
end
local function placeholder(profile,note)
 if not profile then return note or "Class not supported" end
 if level>NS.maxLevel then return "Level 1-"..NS.maxLevel.." guide" end
 return scanError or "Train a spell to get started"
end
-- Recomputes the recommendation and redraws the icons. Cheap: it runs on combat events and on
-- the HUD's ticker, not every frame.
local function updateHUD()
 if not frame then return end
 local role=effectiveRole()
 activeMode=currentMode()
 local rows,note,profile=NS.BuildRows(class,spec,level,known,activeMode,role)
 local assist
 if db.hud.source=="assist" then assist=NS.Rotation.AssistSpell() end
 -- The Tank layout is the track plus the defensive row, whatever the row's own setting.
 local withUtility=showUtility(role) or db.hud.layout=="tank"
 local result=NS.Rotation.Build(rows,withUtility and utilityRows() or {},{assist=assist,count=db.hud.upcoming})
 if not profile then result.now=nil end
 lastResult=result
 local caption,urgent=captionText()
 if inCombat then caption="" end
 local visible=hudVisible(result,urgent)
 frame:SetShown(visible)
 frame.mode:SetText(modeText())
 frame.caption:SetText(caption)
 -- Locked, the HUD lets clicks through to the world; in combat its icons do too (tooltips
 -- work out of combat). The mode button stays clickable.
 frame:EnableMouse(movable())
 NS.HUD.SetInteractive(frame,not inCombat)
 if not visible then return end
 local width,height=NS.HUD.Apply(frame,{layout=db.hud.layout,device=layoutKey(),upcoming=db.hud.upcoming,
  showUtility=withUtility,animate=db.hud.animate,speed=db.hud.speed,result=result,
  placeholder=placeholder(profile,note)},20)
 frame:SetWidth(math.max(width,180))
 frame.caption:ClearAllPoints(); frame.caption:SetPoint("TOPLEFT",frame,"TOPLEFT",0,-20-height-4)
 frame.caption:SetWidth(math.max(width,180))
 frame:SetHeight(20+height+(caption~="" and 18 or 0))
 NS.HUD.Cooldowns(frame)
end
NS.UpdateHUD=updateHUD
render=function()
 if not frame then return end
 if pastGuide() and not db.pastGuideNoted then
  db.pastGuideNoted=true
  if not db.hidden then say("You've outlevelled Everfrost's level 1-"..NS.maxLevel.." guides, so the HUD is now hidden. Type /everfrost show to bring it back.") end
 end
 rememberLook()
 frame.grip:SetShown(movable())
 frame.backdropShown=movable()
 frame.bg:SetShown(movable())
 local role=effectiveRole()
 if NS.Gear then
  -- The scoring focus chosen for this spec (Balanced Tank, Survivability, ...), if any.
  NS.Gear.SetContext(class,gearSpec,level,effectiveRole(gearSpec),known)
  local focus=type(db.gearFocus)=="table" and db.gearFocus[class..tostring(gearSpec)] or nil
  if NS.Gear.SetFocus then NS.Gear.SetFocus(focus) else NS.Gear.focus=focus end
 end
 local profile=NS.profiles[class] and NS.profiles[class][spec]
 local specName=NS.trees[class] and NS.trees[class][spec] or "Levelling"
 frame.title:SetText(specName.." "..className)
 frame.meta:SetText("Level "..level.." / "..(pending and "Pending" or status))
 frame.role:SetShown(hasRoleChoice(profile))
 frame.role:SetText(roleLabel(role,profile))
 frame.info=profile and profile.note or ""; frame.profile=profile
 frame:SetAlpha(db.opacity)
 updateHUD()
 if frame.guideMenu and frame.guideMenu:IsShown() then updateGuideMenu() end
 if NS.Settings then NS.Settings:Refresh() end
end
local function setMode(mode)
 db.hud.mode=mode; NS.Modes.Reset()
 if frame then updateHUD() end
 if NS.Settings then NS.Settings:Refresh() end
end
local function cycleMode()
 local order=NS.Modes.order
 for index,key in ipairs(order) do
  if key==db.hud.mode then setMode(order[index%#order+1]); return end
 end
 setMode("auto")
end
local function flatButton(parent,width)
 local b=CreateFrame("Button",nil,parent)
 b:SetSize(width,16)
 b.label=text(b,10); b.label:SetPoint("LEFT",4,0); b.label:SetTextColor(0.75,0.85,1)
 b.bg=b:CreateTexture(nil,"BACKGROUND"); b.bg:SetAllPoints(); b.bg:SetColorTexture(0,0,0,0.45)
 b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
 function b:SetText(value) self.text=value; self.label:SetText(value) end
 return b
end
local function createGuideMenu()
 -- A small, game-style list. The transparent catcher dismisses it on an outside click.
 local catcher=CreateFrame("Button",nil,UIParent)
 catcher:SetAllPoints(UIParent); catcher:SetFrameStrata("DIALOG"); catcher:EnableMouse(true)
 catcher:Hide()
 local menu=CreateFrame("Frame","EverfrostGuideMenu",catcher,"BackdropTemplate")
 menu:SetFrameStrata("DIALOG"); menu:SetFrameLevel(catcher:GetFrameLevel()+1)
 menu:SetSize(244,188); menu:SetClampedToScreen(true); menu:EnableMouse(true)
 menu:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
 menu:SetBackdropColor(0.055,0.05,0.04,0.98); menu:SetBackdropBorderColor(0.65,0.6,0.46,1)
 menu.heading=text(menu,12); menu.heading:SetPoint("TOPLEFT",16,-14); menu.heading:SetText("Choose a Spec")
 menu.heading:SetTextColor(1,0.82,0)
 local close=CreateFrame("Button",nil,menu,"UIPanelCloseButton")
 close:SetSize(24,24); close:SetPoint("TOPRIGHT",-5,-5); close:SetScript("OnClick",function() menu:Hide() end)
 local choices={{label="Automatic",value=nil},{label="Levelling",value=0}}
 for index,name in ipairs(NS.trees[class] or {}) do choices[#choices+1]={label=name,value=index} end
 menu.rows={}
 for index,choice in ipairs(choices) do
  local value=choice.value
  local row=CreateFrame("Button",nil,menu); row:SetSize(220,26)
  row:SetPoint("TOPLEFT",12,-37-(index-1)*28)
  row.selected=row:CreateTexture(nil,"BACKGROUND"); row.selected:SetAllPoints(); row.selected:SetColorTexture(0.65,0.5,0.18,0.15)
  row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
  row.check=row:CreateTexture(nil,"OVERLAY"); row.check:SetSize(16,16); row.check:SetPoint("LEFT",4,0)
  row.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
  row.label=text(row,12); row.label:SetPoint("LEFT",26,0); row.label:SetWidth(186)
  row.label:SetWordWrap(false); row.label:SetText(choice.label)
  row.value=value
  row:SetScript("OnClick",function() selectGuide(value) end)
  menu.rows[index]=row
 end
 menu.footer=text(menu,10); menu.footer:SetPoint("BOTTOMLEFT",16,12); menu.footer:SetWidth(212); menu.footer:SetHeight(14)
 menu.footer:SetTextColor(0.6,0.6,0.6)
 updateGuideMenu=function()
  for index,row in ipairs(menu.rows) do
   local selected=db.spec==row.value
   row.check:SetShown(selected); row.selected:SetShown(selected)
   row.label:SetTextColor(selected and 1 or 0.9,selected and 0.82 or 0.88,selected and 0 or 0.8)
   if index==1 then
    local name=NS.trees[class] and NS.trees[class][detectedSpec]
    row.label:SetText("Automatic"..(name and (" ("..name..")") or ""))
   end
  end
  local footer=InCombatLockdown() and "Changes apply after combat." or level<NS.gearMinLevel and "Full stat priorities need talents." or nil
  menu.footer:SetText(footer or ""); menu.footer:SetShown(footer~=nil)
  menu:SetHeight(48+#menu.rows*28+(footer and 24 or 0))
 end
 menu:SetScript("OnHide",function() catcher:Hide() end)
 catcher:SetScript("OnClick",function() menu:Hide() end)
 catcher:SetScript("OnHide",function() menu:Hide() end)
 frame.guideMenu=menu; frame.guideCatcher=catcher
 -- Escape closes it. Only the entry is added: assigning the global itself from addon code would
 -- taint the list the game reads whenever it closes windows, the controller's B button included.
 if type(UISpecialFrames)=="table" then table.insert(UISpecialFrames,"EverfrostGuideMenu") end
 menu:Hide()
end
local function createUI()
 -- No permanent window: the HUD is its icons plus one thin header line. A faint background
 -- appears only while it's unlocked, to show where to drag it.
 frame=CreateFrame("Frame","EverfrostFrame",UIParent)
 frame:SetFrameStrata("MEDIUM"); frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true)
 frame:RegisterForDrag("LeftButton")
 frame.bg=frame:CreateTexture(nil,"BACKGROUND"); frame.bg:SetPoint("TOPLEFT",-6,6); frame.bg:SetPoint("BOTTOMRIGHT",6,-6)
 frame.bg:SetColorTexture(0.05,0.08,0.12,0.45)
 frame:SetAlpha(db.opacity)
 frame.StartDrag=function() if movable() and not InCombatLockdown() then frame.moving=true; frame:StartMoving() end end
 frame.StopDrag=function()
  if frame.moving~=true then return end
  frame.moving=false; frame:StopMovingOrSizing()
  local p,_,rp,x,y=frame:GetPoint(); savePosition(p,rp,x,y)
 end
 frame.OpenSettings=function() if NS.Settings then NS.Settings:Open() end end
 frame:SetScript("OnDragStart",frame.StartDrag)
 frame:SetScript("OnDragStop",frame.StopDrag)
 frame:SetScript("OnMouseUp",function(_,mouse) if mouse=="RightButton" then frame.OpenSettings() end end)
 frame:SetScript("OnEnter",function(self)
  tip(self,"Everfrost",(frame.info or "").."\n\nNOW is the spell to press; the icons to its right follow in priority order, not a guaranteed cast order."
   ..(lastResult and lastResult.source=="assist" and "\nNOW comes from Blizzard's rotation assistant." or "\nNOW is the highest guide priority that is ready.")
   .."\n"..NS.guideReviewed..(NS.Talents and NS.Talents.Summary() and ("\n"..NS.Talents.Summary()) or "")
   .."\nLeft-click the mode to switch it. Right-click for settings. Drag to move when unlocked.")
 end)
 frame:SetScript("OnLeave",function() GameTooltip:Hide() end)
 -- Header: mode and enemy count on the left; spec, which opens the guide menu, on the right.
 frame.mode=flatButton(frame,92); frame.mode:SetPoint("TOPLEFT",0,0)
 frame.mode:RegisterForClicks("LeftButtonUp","RightButtonUp")
 frame.mode:SetScript("OnClick",function(_,mouse) if mouse=="RightButton" then setMode("auto") else cycleMode() end end)
 frame.mode:SetScript("OnEnter",function(self)
  local cleave,aoe=NS.Modes.Thresholds(db.hud,specKey())
  tip(self,"Rotation mode: "..NS.Modes.label[db.hud.mode],
   (db.hud.mode=="auto" and ("Now: "..NS.Modes.label[activeMode]..". Cleave from "..cleave.." enemies, AoE from "..aoe..".\nThe count (~) is an estimate from enemy nameplates in combat; ? means the game isn't sharing it, so Everfrost stays on single target.") or "Manual: stays until you change it.")
   .."\nClick: AUTO, ST, CLV, AOE. Right-click: back to AUTO.")
 end)
 frame.mode:SetScript("OnLeave",function() GameTooltip:Hide() end)
 frame.role=flatButton(frame,52); frame.role:SetPoint("LEFT",frame.mode,"RIGHT",4,0)
 frame.role:SetScript("OnClick",toggleRole)
 frame.guide=CreateFrame("Button",nil,frame); frame.guide:SetHeight(16)
 frame.guide:SetPoint("TOPRIGHT",0,0); frame.guide:SetPoint("LEFT",frame.role,"RIGHT",4,0)
 frame.title=text(frame.guide,10); frame.title:SetPoint("RIGHT",0,0); frame.title:SetJustifyH("RIGHT"); frame.title:SetWordWrap(false)
 frame.title:SetTextColor(0.6,0.65,0.7)
 frame.meta=text(frame.guide,10); frame.meta:Hide()
 frame.guide:SetScript("OnClick",function()
  GameTooltip:Hide()
  if frame.guideMenu:IsShown() then frame.guideMenu:Hide(); return end
  updateGuideMenu()
  frame.guideMenu:SetScale(frame:GetScale())
  frame.guideMenu:ClearAllPoints(); frame.guideMenu:SetPoint("TOPRIGHT",frame.guide,"BOTTOMRIGHT",4,-3)
  frame.guideCatcher:Show(); frame.guideMenu:Show()
 end)
 frame.guide:SetScript("OnEnter",function(self) tip(self,"Choose a Spec","Automatic, Levelling, or a class specialisation.\n"..frame.meta:GetText()) end)
 frame.guide:SetScript("OnLeave",function() GameTooltip:Hide() end)
 frame.caption=text(frame,10); frame.caption:SetTextColor(1,0.82,0.4)
 NS.HUD.Attach(frame)
 -- Drag the corner to resize. The size is the current layout's scale, the same value as the
 -- settings slider; the top-left corner stays where it is while the rest grows or shrinks.
 local resizing
 local grip=CreateFrame("Button",nil,frame); grip:SetSize(14,14); grip:SetPoint("BOTTOMRIGHT",8,-8)
 grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
 grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
 grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
 frame.grip=grip
 grip.Resizing=function() return resizing~=nil end
 local function cursor()
  local x,y=GetCursorPosition(); local ui=UIParent:GetEffectiveScale()
  if not (NS.Public(x) and NS.Public(y) and type(x)=="number" and type(y)=="number" and type(ui)=="number" and ui>0) then return nil end
  return x/ui,y/ui
 end
 local function stopResize()
  if not resizing then return end
  resizing=nil; grip:SetScript("OnUpdate",nil)
  if NS.Settings then NS.Settings:Refresh() end
 end
 grip:SetScript("OnMouseDown",function(self)
  if not movable() or InCombatLockdown() then return end
  local scale,left,top=frame:GetScale(),frame:GetLeft(),frame:GetTop()
  local x,y=cursor()
  if not (x and type(left)=="number" and type(top)=="number") then return end
  -- In screen units, so the same corner can be pinned at any scale.
  left,top=left*scale,top*scale
  local reach=math.sqrt((x-left)^2+(y-top)^2)
  if reach<1 then return end
  resizing={scale=scale,left=left,top=top,reach=reach}
  self:SetScript("OnUpdate",function()
   local start=resizing
   if not start or InCombatLockdown() then stopResize(); return end
   local cx,cy=cursor()
   if not cx then return end
   local wanted=start.scale*math.sqrt((cx-start.left)^2+(cy-start.top)^2)/start.reach
   wanted=math.floor(math.max(0.6,math.min(2,wanted))*20+0.5)/20
   if wanted~=layoutScale() then
    setScale(wanted)
    frame:ClearAllPoints(); frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",start.left/wanted,start.top/wanted)
    savePosition("TOPLEFT","BOTTOMLEFT",start.left/wanted,start.top/wanted)
    rememberLook()
   end
  end)
 end)
 grip:SetScript("OnMouseUp",stopResize)
 grip:SetScript("OnHide",stopResize)
 grip:SetScript("OnEnter",function(self) tip(self,"Resize","Drag to make the HUD bigger or smaller. Controller and keyboard layouts keep separate sizes.") end)
 grip:SetScript("OnLeave",function() GameTooltip:Hide() end)
 createGuideMenu()
 frame:SetScript("OnHide",function() frame.guideMenu:Hide() end)
 applyPosition()
end

-------------------------------------------------------------------------------
-- Ticker: runs only in combat or while a device change is settling. Enemy counts every
-- quarter second, Blizzard's suggestion every tenth; animation has its own OnUpdate.
-------------------------------------------------------------------------------
local ticker=CreateFrame("Frame")
local sinceEnemies,sinceAssist,lastAssist=0,0,nil
local function inputChanged()
 applyPosition(); updateHUD()
 if NS.Settings then NS.Settings:Refresh() end
end
local function tick(_,elapsed)
 elapsed=elapsed or 0.1
 if NS.Input.pendingDevice then
  if NS.Input.Offer(NS.Input.pendingDevice) then inputChanged() end
 end
 if not inCombat then
  if not NS.Input.pendingDevice then ticker:SetScript("OnUpdate",nil) end
  return
 end
 sinceEnemies=sinceEnemies+elapsed; sinceAssist=sinceAssist+elapsed
 local changed=false
 if sinceEnemies>=0.25 then
  sinceEnemies=0
  local before,beforeMode=NS.Enemies.count,activeMode
  NS.Enemies.Scan()
  if NS.Enemies.count~=before or currentMode()~=beforeMode then changed=true end
 end
 if sinceAssist>=0.1 then
  sinceAssist=0
 end
 if sinceAssist==0 and db.hud.source=="assist" then
  local spell=NS.Rotation.AssistSpell()
  -- A secret suggestion can't be compared, so it is simply redrawn a few times a second.
  if not NS.Public(spell) then changed=changed or sinceEnemies==0
  elseif spell~=lastAssist then lastAssist=spell; changed=true end
 end
 if changed or (hudDirty and sinceAssist==0) then hudDirty=false; updateHUD() end
end
local function startTicker() ticker:SetScript("OnUpdate",tick) end
local function offerDevice(device)
 if not db or not db.hud.autoSwitch or db.hud.input~="auto" then return end
 if NS.Input.Offer(device) then inputChanged() elseif NS.Input.pendingDevice then startTicker() end
end

-- Key Bindings > AddOns > Everfrost (see Bindings.xml).
BINDING_HEADER_EVERFROST="Everfrost"
BINDING_NAME_EVERFROST_TOGGLE="Show or hide the Everfrost HUD"
BINDING_NAME_EVERFROST_MODE_CYCLE="Rotation mode: next (AUTO, ST, CLV, AOE)"
BINDING_NAME_EVERFROST_MODE_AUTO="Rotation mode: automatic"
BINDING_NAME_EVERFROST_MODE_SINGLE="Rotation mode: single target"
BINDING_NAME_EVERFROST_MODE_CLEAVE="Rotation mode: cleave"
BINDING_NAME_EVERFROST_MODE_AOE="Rotation mode: AoE"
function EverfrostTogglePanel()
 if frame and db then SlashCmdList.EVERFROST(db.hidden and "show" or "hide") end
end
function EverfrostSetMode(mode)
 if not db then return end
 if mode=="cycle" then cycleMode() else setMode(NS.Modes.Normal(mode) or "auto") end
end
local usage="/everfrost settings | show | hide | lock | unlock | mode auto/st/cleave/aoe | layout track/classic/minimal/tank | input auto/pad/kbm/custom | upcoming 0-6 | utility auto/on/off | preview | enemies | heal | damage | bear | cat | ranged | melee | spec auto/1/2/3 | gear on/off | weights | weights reset | minimap on/off | scale 1 | opacity 100 | talents on/off | reset | refresh | source | status | spellids"
SLASH_EVERFROST1="/everfrost"
SLASH_EVERFROST2="/fguide"
SLASH_EVERFROST3="/frh"
SlashCmdList.EVERFROST=function(message)
 if not frame then return end
 local command,arg=message:lower():match("^%s*(%S*)%s*(.-)%s*$")
 if command=="" or command=="settings" or command=="config" then
  if NS.Settings then NS.Settings:Open() end
  return
 elseif command=="show" then db.hidden=false; if pastGuide() then db.showPastGuide=true end
 elseif command=="hide" then db.hidden=true
 elseif command=="lock" then db.locked=true
 elseif command=="unlock" then db.locked=false
 elseif command=="minimap" then
  if arg=="on" or arg=="off" then db.minimap=arg=="on"
  else say("/everfrost minimap on | off") end
 elseif command=="mode" then
  local mode=NS.Modes.Normal(arg)
  if mode then setMode(mode) else say("/everfrost mode auto | st | cleave | aoe") end
 -- Older commands: a manual mode, as they always were.
 elseif command=="aoe" then setMode("aoe")
 elseif command=="single" or command=="st" then setMode("single")
 elseif command=="cleave" then setMode("cleave")
 elseif command=="auto" then setMode("auto")
 elseif command=="layout" then
  local found
  for _,key in ipairs(NS.HUD.layouts) do if key==arg then found=key end end
  if arg=="guitar" or arg=="hero" then found="track" end
  if found then db.hud.layout=found else say("/everfrost layout track | classic | minimal | tank") end
 elseif command=="input" then
  if arg=="auto" or arg=="pad" or arg=="kbm" or arg=="custom" then
   db.hud.input=arg
   if arg=="auto" then NS.Input.device=NS.Input.Detect() or NS.Input.device end
   applyPosition()
  else say("/everfrost input auto | pad | kbm | custom") end
 elseif command=="upcoming" then
  local n=tonumber(arg)
  if n and n>=0 and n<=6 then db.hud.upcoming=math.floor(n) else say("Upcoming icons must be 0-6.") end
 elseif command=="utility" then
  if arg=="auto" or arg=="on" or arg=="off" then db.hud.utility=arg else say("/everfrost utility auto | on | off") end
 elseif command=="preview" then db.hud.preview=not db.hud.preview
  say(db.hud.preview and "Preview on: the HUD shows out of combat. /everfrost preview again to turn it off." or "Preview off.")
 elseif command=="enemies" then
  local count=NS.Enemies.count
  say(inCombat and ("Estimated engaged enemies: "..(count and tostring(count) or "unknown (the game isn't sharing it)")..". Mode: "..NS.Modes.label[activeMode]..".")
   or "Enemies are counted in combat, from enemy nameplates. Turn enemy nameplates on for the best estimate.")
 elseif command=="heal" or command=="damage" or command=="bear" or command=="cat" or command=="melee" or command=="ranged" then db.role=command=="cat" and "damage" or command
 elseif command=="spec" then
  local n=tonumber(arg)
  if arg=="auto" then selectGuide(nil)
  elseif arg=="levelling" or arg=="leveling" or n==0 then selectGuide(0)
  elseif n and NS.trees[class] and NS.trees[class][n] then selectGuide(n)
  else say("/everfrost spec auto | levelling | 1/2/3, or click the spec name on the HUD.") end
 elseif command=="refresh" then refresh()
  if NS.Gear then NS.Gear.items={}; NS.Gear.pending=true; NS.Gear.Schedule() end
 elseif command=="gear" then
  if arg=="on" or arg=="off" then
   db.gear=arg=="on"
   if NS.Gear then NS.Gear.enabled=db.gear; NS.Gear.pending=true; NS.Gear.Paint(); NS.Gear.Schedule() end
  elseif NS.Gear then
   local p=NS.GearProfile(class,gearSpec,effectiveRole(gearSpec),level)
   local name=gearSpec>0 and NS.trees[class][gearSpec] or nil
   say((db.gear==false and "Gear highlights OFF. " or "Gear highlights ON. ")..(p and ((p.starter and "Starter priorities until level 10. " or spec==0 and (name.." talents. ") or "").."Stat order: "..NS.GearPriorityText(p)..". "..NS.GearSourceText(p)..". /everfrost weights to change them; inspect special effects.") or gearReason or "Select a talent tree to score gear."))
  end
 elseif command=="weights" then
  local p=NS.Gear and NS.GearProfile(class,gearSpec,effectiveRole(gearSpec),level)
  if arg=="reset" then
   if p then NS.GearResetWeights(p); say("Stat weights for this spec are back to their defaults.") else say(gearReason or "Select a talent tree first.") end
  elseif NS.Settings then NS.Settings.page="Weights"; NS.Settings:Open() end
 elseif command=="reset" then setScale(1); resetPosition(); db.hidden=false
 elseif command=="talents" then
  if arg=="on" or arg=="off" then db.talents=arg=="on"; refresh()
  elseif NS.Talents then
   local summary=NS.Talents.Summary()
   say(db.talents==false and "Talent recommendations are OFF. /everfrost talents on" or summary
    or (NS.Talents.state and "Your talents can't be read right now; try again out of combat with the talent window open.")
    or "Choose a specialisation, or spend a talent point, to see its Icy Veins talent build.")
   local upcoming=db.talents~=false and NS.Talents.Upcoming(5)
   if upcoming and #upcoming>1 then say("Coming up, by level: "..table.concat(upcoming,"; ")) end
  end
 elseif command=="spellids" then
  -- Guide spells with no ID on record match by their English name only. In game, this lists the
  -- IDs this character's spellbook has for them, to report so other languages can be supported.
  local found={}
  for key,spell in pairs(known) do if not NS.baseIDs[key] then found[#found+1]=key.."="..tostring(spell.id) end end
  table.sort(found)
  say(#found>0 and ("Spell IDs to report: "..table.concat(found,", ")) or "This character has learned none of the guide spells that still need an ID.")
 elseif command=="scale" then
  local n=tonumber(arg); if n and n>=0.6 and n<=2 then setScale(n) else say("Scale must be 0.6-2.") end
 elseif command=="opacity" then
  local n=tonumber(arg)
  if n and n>=10 and n<=100 then db.opacity=n/100; frame:SetAlpha(db.opacity) else say("Opacity must be 10-100 percent.") end
 elseif command=="source" then say(frame.profile and frame.profile.source or "No profile for this class.")
 elseif command=="status" then
  say(class.." / "..spec.." / "..level.." / "..status..(detectedPoints and (" / Talents: "..table.concat(detectedPoints," / ")) or "")..(detectedSource and (" / "..detectedSource) or "")..(scanError and " / "..scanError or "")
   .." / Layout: "..layoutKey().." / Mode: "..db.hud.mode..(NS.Rotation.AssistReason() and (" / "..NS.Rotation.AssistReason()) or " / Blizzard assistant: available"))
 else say(usage) end
 render()
end
local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_LEVEL_UP","SPELLS_CHANGED","LEARNED_SPELL_IN_TAB",
 "PLAYER_TALENT_UPDATE","CHARACTER_POINTS_CHANGED","ACTIVE_TALENT_GROUP_CHANGED","PLAYER_SPECIALIZATION_CHANGED",
 "ACTIVE_PLAYER_SPECIALIZATION_CHANGED","ACTIVE_COMBAT_CONFIG_CHANGED","TRAIT_CONFIG_UPDATED","TRAIT_CONFIG_LIST_UPDATED","TRAIT_TREE_CHANGED","TRAIT_TREE_CURRENCY_INFO_UPDATED",
 "PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED","SPELL_UPDATE_COOLDOWN","SPELL_DATA_LOAD_RESULT","ADDON_LOADED",
 "SPELL_UPDATE_USABLE","PLAYER_TARGET_CHANGED","NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED","UNIT_AURA",
 "INPUT_DEVICE_INTERFACE_TRANSITION","GAME_PAD_ACTIVE_CHANGED","GAME_PAD_CONNECTED","GAME_PAD_DISCONNECTED"}) do
 pcall(events.RegisterEvent,events,event)
end
-- Spell, talent and trait events arrive in bursts (login, zoning, training, tooltips loading
-- spell data). They are gathered into one rescan and redraw on the next frame.
local queued=false
local function schedule()
 if queued then return end
 queued=true
 events:SetScript("OnUpdate",function(self)
  self:SetScript("OnUpdate",nil); queued=false
  refresh(); render()
 end)
end
if NS.Talents then NS.Talents.Schedule=schedule end
-- Combat-state events redraw the icons only, at most once per frame.
local hudQueued=false
local function scheduleHUD()
 if hudQueued or not frame then return end
 hudQueued=true
 events:SetScript("OnUpdate",function(self)
  self:SetScript("OnUpdate",nil); hudQueued=false
  if queued then queued=false; refresh(); render() else updateHUD() end
 end)
end
events:SetScript("OnEvent",function(_,event,value)
 if event=="PLAYER_LOGIN" then
  local firstLogin=type(EverfrostDB)~="table" or next(EverfrostDB)==nil
  EverfrostDB=type(EverfrostDB)=="table" and EverfrostDB or {}
  db=EverfrostDB
  if firstLogin and type(EverfrostAccountDB)=="table" then
   for _,key in ipairs(lookKeys) do if db[key]==nil then db[key]=EverfrostAccountDB[key] end end
   if type(EverfrostAccountDB.hud)=="table" and db.hud==nil then
    db.hud={}
    for _,key in ipairs(hudLookKeys) do db.hud[key]=EverfrostAccountDB.hud[key] end
   end
  end
  if db.gear~=nil and db.gear~=true and db.gear~=false then db.gear=nil end
  -- Your own stat weights, kept per character: {[profile id]={[stat]=weight}}.
  db.gearWeights=type(db.gearWeights)=="table" and db.gearWeights or {}
  if NS.SetGearWeights then NS.SetGearWeights(db.gearWeights) end
  if db.minimap~=nil and db.minimap~=true and db.minimap~=false then db.minimap=nil end
  if db.locked~=true then db.locked=nil end
  db.scale=type(db.scale)=="number" and math.max(0.6,math.min(2,db.scale)) or 1
  local opacity=db.opacity
  db.opacity=NS.Public(opacity) and type(opacity)=="number" and opacity==opacity and opacity~=math.huge and opacity~=-math.huge and math.max(0.1,math.min(1,opacity)) or 1
  db.hud=sanitiseHUD(db.hud,db.aoe==true); db.aoe=nil; db.version=2
  NS.Input.device=NS.Input.Detect() or "kbm"
  className,class=UnitClass("player"); level=UnitLevel("player"); refresh(); createUI()
  if NS.CreateSettings then
   NS.CreateSettings({DB=function() return db end,Command=function(message) SlashCmdList.EVERFROST(message) end,
    SelectGuide=selectGuide,ToggleRole=toggleRole,CloseGuide=function() frame.guideMenu:Hide() end,
    SetMode=setMode,Redraw=function() applyPosition(); render() end,
    -- Hold the HUD on one layout ("kbm" or "pad") so it can be dragged into place; nil lets go.
    PlaceLayout=function(key)
     if key~="kbm" and key~="pad" then key=nil end
     if key and db.hud.input=="custom" then key=nil end
     if NS.Input.placing==key then return end
     NS.Input.placing=key; applyPosition(); render()
    end,
    ResetHUD=function() db.hud=sanitiseHUD(nil,false); NS.Modes.Reset(); applyPosition(); render() end,
    State=function()
     local p=NS.profiles[class] and NS.profiles[class][spec]
     local gear=NS.GearProfile(class,gearSpec,effectiveRole(gearSpec),level)
     local gearName=gearSpec>0 and (NS.trees[class] or {})[gearSpec] or nil
     local role=effectiveRole()
     local cleave,aoe=NS.Modes.Thresholds(db.hud,specKey())
     return {class=class,className=className,level=level,pending=pending,spec=spec,gearSpec=gearSpec,
      detected=((NS.trees[class] or {})[detectedSpec] or detectedStatus)..(detectedPoints and (" ("..table.concat(detectedPoints," / ")..")") or ""),
      hasRole=hasRoleChoice(p),roleLabel=roleLabel(role,p),
      priority=gear and NS.GearPriorityText(gear) or nil,gearReason=gearReason,
      gearProfile=gear,gearSource=gear and NS.GearSourceText(gear) or nil,
      gearTitle=gear and gear.starter and ("Starter priority: "..className) or gearName and ("Stat priority: "..gearName..(spec==0 and " (talents)" or "")) or nil,
      emptySlots=emptySlotText(),panelShown=panelShown(),
      levelingHint=NS.gearLevelNote.." Levelling uses your dominant talent tree for gear.",
      talents=NS.Talents and NS.Talents.Summary() or nil,
      layout=layoutKey(),layoutScale=layoutScale(),placing=NS.Input.placing,activeMode=activeMode,specKey=specKey(),
      cleave=cleave,aoe=aoe,tank=NS.IsTank(class,spec,role) and true or false,
      assistReason=NS.Rotation.AssistReason()}
    end})
  end
  render()
  if NS.Gear then
   -- Equipment changes arrive through gear rescans, not through the HUD's own events.
   NS.Gear.OnRefreshed=function() updateHUD(); if NS.Settings then NS.Settings:Refresh() end end
  end
 elseif not frame then return
 elseif event=="PLAYER_REGEN_DISABLED" then
  inCombat=true; NS.Enemies.Clear(); NS.Enemies.stale=db.hud.stale; NS.Enemies.grace=db.hud.grace
  sinceEnemies,sinceAssist,lastAssist=1,1,nil; startTicker(); updateHUD()
  if NS.Settings then NS.Settings:Refresh() end
 elseif event=="PLAYER_REGEN_ENABLED" then
  inCombat=false; NS.Enemies.Clear(); NS.Modes.Reset()
  if pending then schedule() else updateHUD(); if NS.Settings then NS.Settings:Refresh() end end
 elseif event=="SPELL_UPDATE_COOLDOWN" then NS.HUD.Cooldowns(frame); if not inCombat then scheduleHUD() end
 elseif event=="SPELL_UPDATE_USABLE" or event=="PLAYER_TARGET_CHANGED" then
  -- In combat these fire constantly; the ticker redraws at most ten times a second.
  if inCombat then hudDirty=true else scheduleHUD() end
 elseif event=="UNIT_AURA" then if value=="player" and not inCombat then scheduleHUD() end
 elseif event=="NAME_PLATE_UNIT_ADDED" then if type(value)=="string" then NS.Enemies.PlateAdded(value) end
 elseif event=="NAME_PLATE_UNIT_REMOVED" then if type(value)=="string" then NS.Enemies.PlateRemoved(value) end
 elseif event=="INPUT_DEVICE_INTERFACE_TRANSITION" then
  local pad=Enum and Enum.InputDeviceInterfaceType and Enum.InputDeviceInterfaceType.Gamepad or 1
  if NS.Public(value) and type(value)=="number" then offerDevice(value==pad and "pad" or "kbm") end
 elseif event=="GAME_PAD_ACTIVE_CHANGED" then
  if NS.Public(value) and type(value)=="boolean" then offerDevice(value and "pad" or "kbm") end
 elseif event=="GAME_PAD_CONNECTED" or event=="GAME_PAD_DISCONNECTED" then
  -- A connected controller isn't proof it's in use: ask the game which style is active.
  local device=NS.Input.Detect(); if device then offerDevice(device) end
 elseif event=="PLAYER_LEVEL_UP" then level=value; schedule()
 elseif event=="ADDON_LOADED" then
  -- The talent window is its own addon, loaded the first time it is opened.
  if type(value)=="string" and (value:find("Talent") or value:find("PlayerSpells")) then schedule() end
 elseif event=="SPELL_DATA_LOAD_RESULT" then
  -- Fires for every spell the client loads. It only matters while a guide spell's name is
  -- still missing; once they have all resolved there is nothing left to pick up.
  if not NS.SpellNamesReady(class) then schedule() end
 else schedule() end
end)
