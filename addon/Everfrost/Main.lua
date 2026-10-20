local _, NS=...
local frame,db,known=nil,nil,{}
local class,className,level,spec,status="","",1,0,""
local detectedSpec,detectedStatus=0,""
local detectedPoints,detectedSource=nil,nil
local gearSpec,gearReason=0,nil
local pending,scanError=false,nil
local tiles={}
local function say(s) print("|cffb8c6d9Everfrost:|r "..s) end
local function text(parent,size,font)
 local t=parent:CreateFontString(nil,"OVERLAY",font or (size>=12 and "GameFontHighlight" or "GameFontHighlightSmall"))
 t:SetJustifyH("LEFT"); t:SetJustifyV("TOP"); return t
end
local function tip(owner,title,description)
 GameTooltip:SetOwner(owner,"ANCHOR_BOTTOM"); GameTooltip:SetText(title,1,1,1)
 GameTooltip:AddLine(description,0.75,0.8,0.86,true); GameTooltip:Show()
end
local function refresh()
 if InCombatLockdown() then pending=true; return end
 local talentPointsAvailable
 detectedSpec,detectedStatus,talentPointsAvailable,detectedPoints,detectedSource=NS.DetectSpec(class)
 spec,status=detectedSpec,detectedStatus
 if db.spec==0 or (NS.trees[class] and NS.trees[class][db.spec]) then spec,status=db.spec,"Manual" end
 gearSpec,gearReason=spec,nil
 if level<NS.gearMinLevel then
  gearSpec=0; gearReason=NS.gearLevelNote
 elseif spec==0 then
  if not talentPointsAvailable then
   gearReason="Talent points are unavailable. Choose a specialization on the Specialization page to score gear."
  elseif detectedSpec>0 then gearSpec=detectedSpec
  elseif detectedStatus=="Hybrid" then
   gearReason="Your talent trees are tied. Spend more points or choose a specialization to score gear."
  else gearReason="No talent points spent yet. Spend a talent point or choose a specialization to score gear." end
 end
 local spells,err=NS.ScanSpells(class)
 if spells then known=spells end
 scanError=err; pending=false
end
local function cooldowns()
 if not frame or not frame:IsShown() then return end
 for _,tile in ipairs(tiles) do
  if tile:IsShown() and tile.spellID then
   local result=NS.Call(C_Spell and C_Spell.GetSpellCooldownDuration,tile.spellID,true)
   local duration=result and result[1]
   if duration and tile.cd.SetCooldownFromDurationObject then
    tile.cd:SetCooldownFromDurationObject(duration)
   else tile.cd:Clear() end
  end
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
  if db.role=="bear" or (not known["Cat Form"] and known["Bear Form"]) then return "bear" end
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
local function makeTile(index)
 local tile=CreateFrame("Frame",nil,frame); tile:SetSize(44,44); tile:EnableMouse(true)
 tile.icon=tile:CreateTexture(nil,"ARTWORK"); tile.icon:SetAllPoints(); tile.icon:SetTexCoord(0.07,0.93,0.07,0.93)
 tile.border=tile:CreateTexture(nil,"OVERLAY")
 tile.border:SetTexture("Interface\\Buttons\\UI-Quickslot2"); tile.border:SetSize(76,76); tile.border:SetPoint("CENTER")
 tile.cd=CreateFrame("Cooldown",nil,tile,"CooldownFrameTemplate"); tile.cd:SetAllPoints(); tile.cd:SetDrawEdge(false)
 tile:SetScript("OnEnter",function(self)
  if self.spellID then
   GameTooltip:SetOwner(self,"ANCHOR_BOTTOM"); GameTooltip:SetSpellByID(self.spellID)
   GameTooltip:AddLine(" "); GameTooltip:AddLine(self.hint,0.85,0.9,1,true); GameTooltip:Show()
   frame.caption:SetText(self.hint)
  end
 end)
 tile:SetScript("OnLeave",function() GameTooltip:Hide(); frame.caption:SetText(frame.defaultCaption) end)
 tiles[index]=tile; return tile
end
render=function()
 if not frame then return end
 frame:SetShown(not db.hidden)
 local role=effectiveRole()
 if NS.Gear then NS.Gear.SetContext(class,gearSpec,level,effectiveRole(gearSpec),known) end
 local list,note,profile=NS.BuildRows(class,spec,level,known,db.aoe and "aoe" or "single",role)
 local specName=NS.trees[class] and NS.trees[class][spec] or "Leveling"
 frame.title:SetText(specName.."  "..className)
 frame.meta:SetText("LEVEL "..level.."   /   "..status:upper())
 if pending then frame.meta:SetText("LEVEL "..level.."   /   PENDING") end
 frame.mode:SetText(db.aoe and "AoE" or "Single")
 frame.role:SetShown(profile and (profile.healing or profile.bear or profile.melee) and true or false)
 frame.role:SetText(role=="melee" and "Melee" or role=="ranged" and "Ranged" or role=="heal" and "Heal" or role=="bear" and "Bear" or role=="caster" and "Caster" or (profile and profile.bear and "Cat" or "Damage"))
 for _,tile in ipairs(tiles) do tile:Hide(); tile.cd:Clear(); tile.spellID=nil end
 local columns=math.min(6,math.max(1,#list))
 local width=math.max(320,40+columns*52-8); frame:SetWidth(width)
 for i,entry in ipairs(list) do
  local tile=tiles[i] or makeTile(i)
  tile:ClearAllPoints(); tile:SetPoint("TOPLEFT",20+((i-1)%6)*52,-70-math.floor((i-1)/6)*52)
  tile.icon:SetTexture(entry.spell.icon or 134400); tile.spellID=entry.spell.id; tile.hint=entry.hint; tile:Show()
 end
 local height=math.ceil(#list/6)*52; frame.empty:SetShown(#list==0)
 if #list==0 then height=40; frame.empty:SetText(not profile and note or level>NS.maxLevel and ("Level 1-"..NS.maxLevel.." guide") or scanError or "Train a spell to get started") end
 frame.caption:ClearAllPoints(); frame.caption:SetPoint("TOPLEFT",20,-73-height)
 frame.caption:SetWidth(width-40); frame.caption:SetHeight(30)
 frame.defaultCaption=scanError or (pending and "Updates after combat") or "Hover a spell for its place in the rotation"
 frame.caption:SetText(frame.defaultCaption); frame:SetHeight(116+height)
 frame.info=note or ""; frame.profile=profile; cooldowns()
 if frame.guideMenu and frame.guideMenu:IsShown() then updateGuideMenu() end
 if NS.Settings then NS.Settings:Refresh() end
end
local function resetPosition()
 frame:ClearAllPoints(); frame:SetPoint("CENTER",UIParent,"CENTER",0,-190)
 db.point,db.relativePoint,db.x,db.y=nil,nil,nil,nil
end
local function chip(parent,width)
 local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate"); b:SetSize(width,22)
 return b
end
local function createGuideMenu()
 -- A small, game-style list. The transparent catcher dismisses it on an outside click.
 local catcher=CreateFrame("Button",nil,UIParent)
 catcher:SetAllPoints(UIParent); catcher:SetFrameStrata("DIALOG"); catcher:EnableMouse(true)
 catcher:Hide()
 local menu=CreateFrame("Frame","EverfrostGuideMenu",catcher,"BackdropTemplate")
 menu:SetFrameStrata("DIALOG"); menu:SetFrameLevel(catcher:GetFrameLevel()+1)
 menu:SetSize(276,264); menu:SetClampedToScreen(true); menu:EnableMouse(true)
 menu:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
 menu:SetBackdropColor(0.055,0.05,0.04,0.98); menu:SetBackdropBorderColor(0.65,0.6,0.46,1)
 menu.heading=text(menu,12); menu.heading:SetPoint("TOPLEFT",16,-14); menu.heading:SetText("Choose a guide")
 menu.heading:SetTextColor(1,0.82,0)
 local close=CreateFrame("Button",nil,menu,"UIPanelCloseButton")
 close:SetSize(24,24); close:SetPoint("TOPRIGHT",-5,-5); close:SetScript("OnClick",function() menu:Hide() end)
 local choices={{label="Automatic",value=nil},{label="Leveling",value=0}}
 for index,name in ipairs(NS.trees[class] or {}) do choices[#choices+1]={label=name,value=index} end
 menu.rows={}
 for index,choice in ipairs(choices) do
  local value=choice.value
  local row=CreateFrame("Button",nil,menu); row:SetSize(252,36)
  row:SetPoint("TOPLEFT",12,-37-(index-1)*38)
  row.selected=row:CreateTexture(nil,"BACKGROUND"); row.selected:SetAllPoints(); row.selected:SetColorTexture(0.65,0.5,0.18,0.15)
  row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
  row.check=row:CreateTexture(nil,"OVERLAY"); row.check:SetSize(16,16); row.check:SetPoint("LEFT",4,0)
  row.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
  row.label=text(row,12); row.label:SetPoint("TOPLEFT",26,-3); row.label:SetText(choice.label)
  row.detail=text(row,10); row.detail:SetPoint("TOPLEFT",26,-20); row.detail:SetTextColor(0.6,0.6,0.55)
  row.detail:SetWidth(218); row.detail:SetWordWrap(false)
  row.value=value
  row:SetScript("OnClick",function() selectGuide(value) end)
  menu.rows[index]=row
 end
 menu.divider=menu:CreateTexture(nil,"ARTWORK"); menu.divider:SetColorTexture(0.55,0.5,0.38,0.3)
 menu.divider:SetHeight(1); menu.divider:SetPoint("BOTTOMLEFT",14,33); menu.divider:SetPoint("BOTTOMRIGHT",-14,33)
 menu.footer=text(menu,10); menu.footer:SetPoint("BOTTOMLEFT",16,12); menu.footer:SetWidth(244); menu.footer:SetHeight(16)
 menu.footer:SetTextColor(0.7,0.68,0.6)
 updateGuideMenu=function()
  for index,row in ipairs(menu.rows) do
   local selected=db.spec==row.value
   row.check:SetShown(selected); row.selected:SetShown(selected)
   row.label:SetTextColor(selected and 1 or 0.9,selected and 0.82 or 0.88,selected and 0 or 0.8)
   local detail
   if index==1 then
    local name=NS.trees[class] and NS.trees[class][detectedSpec]
    detail=name and ("Detected: "..name) or detectedStatus=="Hybrid" and "Tied talents; uses Leveling" or detectedStatus=="Unspent" and "No talents spent; uses Leveling" or "No spec detected; uses Leveling"
   elseif index==2 then detail="Gear uses talents from level 10"
   else detail=level<NS.gearMinLevel and "Gear priorities start at level 10" or "Ability guide and gear priorities" end
   row.detail:SetText(detail)
  end
  local footer="Your choice is saved for this character."
  if level<NS.gearMinLevel then footer="Stat priorities start at level 10."
  elseif spec==0 then
   footer=gearSpec>0 and ("Gear: "..NS.trees[class][gearSpec].." (from talents)") or level<10 and "Gear follows talents from level 10." or "Choose a spec or spend talent points."
  end
  menu.footer:SetText(InCombatLockdown() and "Guide changes apply after combat." or footer)
 end
 menu:SetScript("OnHide",function() catcher:Hide() end)
 catcher:SetScript("OnClick",function() menu:Hide() end)
 catcher:SetScript("OnHide",function() menu:Hide() end)
 frame.guideMenu=menu; frame.guideCatcher=catcher
 UISpecialFrames=UISpecialFrames or {}; UISpecialFrames[#UISpecialFrames+1]="EverfrostGuideMenu"
 menu:Hide()
end
local function createUI()
 frame=CreateFrame("Frame","EverfrostFrame",UIParent,"BackdropTemplate")
 frame:SetFrameStrata("MEDIUM"); frame:SetClampedToScreen(true); frame:SetMovable(true)
 frame:SetBackdrop(BACKDROP_DIALOG_32_32 or {bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileEdge=true,tileSize=32,edgeSize=32,insets={left=11,right=12,top=12,bottom=11}})
 frame:SetBackdropColor(1,1,1,0.95); frame:SetBackdropBorderColor(1,1,1,1)
 frame:SetScale(db.scale); frame:SetAlpha(db.opacity)
 if db.point and db.relativePoint and type(db.x)=="number" and type(db.y)=="number" then frame:SetPoint(db.point,UIParent,db.relativePoint,db.x,db.y) else resetPosition() end
 local drag=CreateFrame("Frame",nil,frame); drag:SetPoint("TOPLEFT",12,-8); drag:SetPoint("TOPRIGHT",-12,-8); drag:SetHeight(54)
 drag:EnableMouse(true); drag:RegisterForDrag("LeftButton")
 drag:SetScript("OnDragStart",function() if not db.locked then frame:StartMoving() end end)
 drag:SetScript("OnDragStop",function()
  frame:StopMovingOrSizing(); local p,_,rp,x,y=frame:GetPoint(); db.point,db.relativePoint,db.x,db.y=p,rp,x,y
 end)
 drag:SetScript("OnEnter",function(self) tip(self,"Everfrost",frame.info.."\n\n"..NS.gearLevelNote.."\nReference priorities, not a live next-cast queue.\nDrag to move. /everfrost for settings.") end)
 drag:SetScript("OnLeave",function() GameTooltip:Hide() end)
 frame.guide=CreateFrame("Button",nil,drag)
 frame.guide:SetPoint("TOPLEFT",2,-2); frame.guide:SetPoint("TOPRIGHT",-2,-2); frame.guide:SetHeight(25)
 frame.guide:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight","ADD")
 frame.guide.arrow=frame.guide:CreateTexture(nil,"ARTWORK"); frame.guide.arrow:SetSize(16,16)
 frame.guide.arrow:SetPoint("RIGHT",-3,0); frame.guide.arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
 frame.title=text(frame.guide,12,"GameFontNormal"); frame.title:SetPoint("LEFT",6,0); frame.title:SetPoint("RIGHT",frame.guide.arrow,"LEFT",-6,0)
 frame.title:SetWordWrap(false)
 frame.guide:RegisterForDrag("LeftButton")
 frame.guide:SetScript("OnDragStart",function() if not db.locked then frame:StartMoving() end end)
 frame.guide:SetScript("OnDragStop",drag:GetScript("OnDragStop"))
 frame.guide:SetScript("OnEnter",function(self) tip(self,"Choose a guide","Automatic, Leveling, or a class specialization.\n"..NS.gearLevelNote.."\nDrag to move the panel.") end)
 frame.guide:SetScript("OnLeave",function() GameTooltip:Hide() end)
 frame.guide:SetScript("OnClick",function()
  GameTooltip:Hide()
  if frame.guideMenu:IsShown() then frame.guideMenu:Hide(); return end
  updateGuideMenu()
  frame.guideMenu:SetScale(frame:GetScale())
  frame.guideMenu:ClearAllPoints(); frame.guideMenu:SetPoint("TOPLEFT",frame.guide,"BOTTOMLEFT",-4,-3)
  frame.guideCatcher:Show(); frame.guideMenu:Show()
 end)
 frame.meta=text(drag,11); frame.meta:SetPoint("TOPLEFT",8,-35); frame.meta:SetWidth(130); frame.meta:SetWordWrap(false); frame.meta:SetTextColor(0.75,0.75,0.75)
 frame.mode=chip(drag,64); frame.mode:SetPoint("TOPRIGHT",-6,-29)
 frame.mode:SetScript("OnClick",function() db.aoe=not db.aoe; render() end)
 frame.role=chip(drag,66); frame.role:SetPoint("RIGHT",frame.mode,"LEFT",-4,0)
 frame.role:SetScript("OnClick",toggleRole)
 frame.caption=text(frame,11); frame.caption:SetTextColor(0.8,0.8,0.8)
 frame.empty=text(frame,12); frame.empty:SetPoint("TOPLEFT",20,-75); frame.empty:SetWidth(280)
 createGuideMenu()
 frame:SetScript("OnHide",function() frame.guideMenu:Hide() end)
end
SLASH_EVERFROST1="/everfrost"
SLASH_EVERFROST2="/fguide"
SLASH_EVERFROST3="/frh"
SlashCmdList.EVERFROST=function(message)
 if not frame then return end
 local command,arg=message:lower():match("^%s*(%S*)%s*(.-)%s*$")
 if command=="" or command=="settings" or command=="config" then
  if NS.Settings then NS.Settings:Open() end
  return
 elseif command=="show" then db.hidden=false
 elseif command=="hide" then db.hidden=true
 elseif command=="lock" then db.locked=true
 elseif command=="unlock" then db.locked=false
 elseif command=="minimap" then
  if arg=="on" or arg=="off" then db.minimap=arg=="on"
  else say("/everfrost minimap on | off") end
 elseif command=="aoe" then db.aoe=true
 elseif command=="single" then db.aoe=false
 elseif command=="heal" or command=="damage" or command=="bear" or command=="cat" or command=="melee" or command=="ranged" then db.role=command=="cat" and "damage" or command
 elseif command=="spec" then
  local n=tonumber(arg)
  if arg=="auto" then selectGuide(nil)
  elseif arg=="leveling" or n==0 then selectGuide(0)
  elseif n and NS.trees[class] and NS.trees[class][n] then selectGuide(n)
  else say("/everfrost spec auto | leveling | 1/2/3, or click the guide title.") end
 elseif command=="refresh" then refresh()
  if NS.Gear then NS.Gear.pending=true; NS.Gear.Schedule() end
 elseif command=="gear" then
  if arg=="on" or arg=="off" then
   db.gear=arg=="on"
   if NS.Gear then NS.Gear.enabled=db.gear; NS.Gear.pending=true; NS.Gear.Paint(); NS.Gear.Schedule() end
  elseif NS.Gear then
   local p=NS.GearProfile(class,gearSpec,effectiveRole(gearSpec))
   local name=gearSpec>0 and NS.trees[class][gearSpec] or nil
   say((db.gear==false and "Gear highlights OFF. " or "Gear highlights ON. ")..(p and ((spec==0 and (name.." talents. ") or "").."Stat order: "..NS.GearPriorityText(p)..". Estimated weights; inspect special effects.") or gearReason or "Select a talent tree to score gear."))
  end
 elseif command=="reset" then resetPosition(); db.scale=1; frame:SetScale(1); db.hidden=false
 elseif command=="scale" then
  local n=tonumber(arg); if n and n>=0.6 and n<=2 then db.scale=n; frame:SetScale(n) else say("Scale must be 0.6-2.") end
 elseif command=="opacity" then
  local n=tonumber(arg)
  if n and n>=10 and n<=100 then db.opacity=n/100; frame:SetAlpha(db.opacity) else say("Opacity must be 10-100 percent.") end
 elseif command=="source" then say(frame.profile and frame.profile.source or "No profile for this class.")
 elseif command=="status" then
  say(class.." / "..spec.." / "..level.." / "..status..(detectedPoints and (" / Talents: "..table.concat(detectedPoints," / ")) or "")..(detectedSource and (" / "..detectedSource) or "")..(scanError and " / "..scanError or ""))
 else say("/everfrost settings | show | hide | lock | unlock | single | aoe | heal | damage | bear | cat | ranged | melee | spec auto/1/2/3 | gear on/off | minimap on/off | scale 1 | opacity 100 | reset | refresh | source | status") end
 render()
end
local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_LEVEL_UP","SPELLS_CHANGED","LEARNED_SPELL_IN_TAB",
 "PLAYER_TALENT_UPDATE","CHARACTER_POINTS_CHANGED","ACTIVE_TALENT_GROUP_CHANGED","PLAYER_SPECIALIZATION_CHANGED",
 "ACTIVE_PLAYER_SPECIALIZATION_CHANGED","ACTIVE_COMBAT_CONFIG_CHANGED","TRAIT_CONFIG_UPDATED","TRAIT_CONFIG_LIST_UPDATED","TRAIT_TREE_CHANGED","TRAIT_TREE_CURRENCY_INFO_UPDATED",
 "PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED","SPELL_UPDATE_COOLDOWN","SPELL_DATA_LOAD_RESULT"}) do
 pcall(events.RegisterEvent,events,event)
end
events:SetScript("OnEvent",function(_,event,value)
 if event=="PLAYER_LOGIN" then
  EverfrostDB=type(EverfrostDB)=="table" and EverfrostDB or {}
  db=EverfrostDB; db.scale=type(db.scale)=="number" and math.max(0.6,math.min(2,db.scale)) or 1
  local opacity=db.opacity
  db.opacity=NS.Public(opacity) and type(opacity)=="number" and opacity==opacity and opacity~=math.huge and opacity~=-math.huge and math.max(0.1,math.min(1,opacity)) or 1
  className,class=UnitClass("player"); level=UnitLevel("player"); refresh(); createUI()
  if NS.CreateSettings then
   NS.CreateSettings({DB=function() return db end,Command=function(value) SlashCmdList.EVERFROST(value) end,
    SelectGuide=selectGuide,ToggleRole=toggleRole,CloseGuide=function() frame.guideMenu:Hide() end,
    State=function()
     local p=NS.profiles[class] and NS.profiles[class][spec]
     local gear=NS.GearProfile(class,gearSpec,effectiveRole(gearSpec))
     local gearName=gearSpec>0 and (NS.trees[class] or {})[gearSpec] or nil
     local role=effectiveRole()
     local roleLabel=role=="damage" and (p and p.bear and "Cat" or "Damage") or role:sub(1,1):upper()..role:sub(2)
     return {class=class,className=className,level=level,pending=pending,
      detected=((NS.trees[class] or {})[detectedSpec] or detectedStatus)..(detectedPoints and (" ("..table.concat(detectedPoints," / ")..")") or ""),
      hasRole=p and (p.melee or p.healing or p.bear) and true or false,roleLabel=roleLabel,
      priority=gear and NS.GearPriorityText(gear) or nil,gearReason=gearReason,
      gearTitle=gearName and ("Stat priority: "..gearName..(spec==0 and " (talents)" or "")) or nil,
      levelingHint=NS.gearLevelNote.." Leveling uses your dominant talent tree for gear."}
    end})
  end
  render()
 elseif not frame then return
 elseif event=="PLAYER_REGEN_DISABLED" then if NS.Settings then NS.Settings:Refresh() end
 elseif event=="SPELL_UPDATE_COOLDOWN" then cooldowns()
 elseif event=="PLAYER_LEVEL_UP" then level=value; refresh(); render()
 elseif event=="PLAYER_REGEN_ENABLED" then
  if pending then refresh(); render() elseif NS.Settings then NS.Settings:Refresh() end
 else refresh(); render() end
end)




