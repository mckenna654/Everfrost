local _, NS=...
local frame,db,known=nil,nil,{}
local class,className,level,spec,status="","",1,0,""
local detectedSpec,detectedStatus=0,""
local pending,scanError=false,nil
local tiles={}
local function say(s) print("|cffb8c6d9Everfrost:|r "..s) end
local function text(parent,size)
 local t=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 t:SetFont(STANDARD_TEXT_FONT,size); t:SetJustifyH("LEFT"); return t
end
local function tip(owner,title,description)
 GameTooltip:SetOwner(owner,"ANCHOR_BOTTOM"); GameTooltip:SetText(title,1,1,1)
 GameTooltip:AddLine(description,0.75,0.8,0.86,true); GameTooltip:Show()
end
local function refresh()
 if InCombatLockdown() then pending=true; return end
 detectedSpec,detectedStatus=NS.DetectSpec(class)
 spec,status=detectedSpec,detectedStatus
 if db.spec==0 or (NS.trees[class] and NS.trees[class][db.spec]) then spec,status=db.spec,"Manual" end
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
local function effectiveRole()
 local p=NS.profiles[class] and NS.profiles[class][spec]
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
local function makeTile(index)
 local tile=CreateFrame("Frame",nil,frame); tile:SetSize(44,44); tile:EnableMouse(true)
 tile.icon=tile:CreateTexture(nil,"ARTWORK"); tile.icon:SetAllPoints(); tile.icon:SetTexCoord(0.07,0.93,0.07,0.93)
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
 if NS.Gear then NS.Gear.SetContext(class,spec,level,role,known) end
 local list,note,profile=NS.BuildRows(class,spec,level,known,db.aoe and "aoe" or "single",role)
 local specName=NS.trees[class] and NS.trees[class][spec] or "Leveling"
 frame.title:SetText(specName.."  "..className)
 frame.meta:SetText("LEVEL "..level.."   /   "..status:upper())
 if pending then frame.meta:SetText("LEVEL "..level.."   /   PENDING") end
 local color=RAID_CLASS_COLORS and RAID_CLASS_COLORS[class] or {r=0.6,g=0.7,b=0.9}
 frame.accent:SetColorTexture(color.r,color.g,color.b,1)
 frame.mode.label:SetText(db.aoe and "AOE" or "SINGLE")
 frame.role:SetShown(profile and (profile.healing or profile.bear or profile.melee) and true or false)
 frame.role.label:SetText(role=="melee" and "MELEE" or role=="ranged" and "RANGED" or role=="heal" and "HEAL" or role=="bear" and "BEAR" or role=="caster" and "CASTER" or (profile and profile.bear and "CAT" or "DAMAGE"))
 for _,tile in ipairs(tiles) do tile:Hide(); tile.cd:Clear(); tile.spellID=nil end
 local columns=math.min(6,math.max(1,#list))
 local width=math.max(310,28+columns*52-8); frame:SetWidth(width)
 for i,entry in ipairs(list) do
  local tile=tiles[i] or makeTile(i)
  tile:ClearAllPoints(); tile:SetPoint("TOPLEFT",14+((i-1)%6)*52,-62-math.floor((i-1)/6)*52)
  tile.icon:SetTexture(entry.spell.icon or 134400); tile.spellID=entry.spell.id; tile.hint=entry.hint; tile:Show()
 end
 local height=math.ceil(#list/6)*52; frame.empty:SetShown(#list==0)
 if #list==0 then height=40; frame.empty:SetText(not profile and note or level>NS.maxLevel and ("Level 1-"..NS.maxLevel.." guide") or scanError or "Train a spell to get started") end
 frame.caption:ClearAllPoints(); frame.caption:SetPoint("TOPLEFT",14,-65-height)
 frame.caption:SetWidth(width-28); frame.caption:SetHeight(30)
 frame.defaultCaption=scanError or (pending and "Updates after combat") or "Hover a spell for its place in the rotation"
 frame.caption:SetText(frame.defaultCaption); frame:SetHeight(106+height)
 frame.info=note or ""; frame.profile=profile; cooldowns()
 if frame.guideMenu and frame.guideMenu:IsShown() then updateGuideMenu() end
end
local function resetPosition()
 frame:ClearAllPoints(); frame:SetPoint("CENTER",UIParent,"CENTER",0,-190)
 db.point,db.relativePoint,db.x,db.y=nil,nil,nil,nil
end
local function chip(parent,width)
 local b=CreateFrame("Button",nil,parent); b:SetSize(width,20)
 local bg=b:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(1,1,1,0.07)
 b.label=text(b,9); b.label:SetPoint("CENTER"); b.label:SetTextColor(0.8,0.85,0.92)
 b:SetScript("OnEnter",function() bg:SetColorTexture(1,1,1,0.14) end)
 b:SetScript("OnLeave",function() bg:SetColorTexture(1,1,1,0.07) end)
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
   elseif index==2 then detail="General class guide; gear is unscored"
   else detail="Ability guide and gear priorities" end
   row.detail:SetText(detail)
  end
  menu.footer:SetText(InCombatLockdown() and "Guide changes apply after combat." or spec==0 and "Choose a spec for gear highlights." or "Your choice is saved for this character.")
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
 frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
 frame:SetBackdropColor(0.035,0.045,0.065,0.93); frame:SetBackdropBorderColor(0.3,0.35,0.43,0.5)
 frame:SetScale(db.scale)
 if db.point and db.relativePoint and type(db.x)=="number" and type(db.y)=="number" then frame:SetPoint(db.point,UIParent,db.relativePoint,db.x,db.y) else resetPosition() end
 frame.accent=frame:CreateTexture(nil,"OVERLAY"); frame.accent:SetPoint("TOPLEFT",1,-1)
 frame.accent:SetPoint("TOPRIGHT",-1,-1); frame.accent:SetHeight(2)
 local drag=CreateFrame("Frame",nil,frame); drag:SetPoint("TOPLEFT"); drag:SetPoint("TOPRIGHT"); drag:SetHeight(58)
 drag:EnableMouse(true); drag:RegisterForDrag("LeftButton")
 drag:SetScript("OnDragStart",function() if not db.locked then frame:StartMoving() end end)
 drag:SetScript("OnDragStop",function()
  frame:StopMovingOrSizing(); local p,_,rp,x,y=frame:GetPoint(); db.point,db.relativePoint,db.x,db.y=p,rp,x,y
 end)
 drag:SetScript("OnEnter",function(self) tip(self,"Everfrost",frame.info.."\n\nReference priorities, not a live next-cast queue.\nDrag to move. /everfrost help for settings.") end)
 drag:SetScript("OnLeave",function() GameTooltip:Hide() end)
 frame.guide=CreateFrame("Button",nil,drag)
 frame.guide:SetPoint("TOPLEFT",8,-7); frame.guide:SetPoint("TOPRIGHT",-8,-7); frame.guide:SetHeight(23)
 local guideHover=frame.guide:CreateTexture(nil,"HIGHLIGHT"); guideHover:SetAllPoints(); guideHover:SetColorTexture(1,1,1,0.06)
 frame.guide.arrow=frame.guide:CreateTexture(nil,"ARTWORK"); frame.guide.arrow:SetSize(16,16)
 frame.guide.arrow:SetPoint("RIGHT",-3,0); frame.guide.arrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
 frame.title=text(frame.guide,12); frame.title:SetPoint("LEFT",6,0); frame.title:SetPoint("RIGHT",frame.guide.arrow,"LEFT",-6,0)
 frame.title:SetWordWrap(false)
 frame.guide:RegisterForDrag("LeftButton")
 frame.guide:SetScript("OnDragStart",function() if not db.locked then frame:StartMoving() end end)
 frame.guide:SetScript("OnDragStop",drag:GetScript("OnDragStop"))
 frame.guide:SetScript("OnEnter",function(self) tip(self,"Choose a guide","Automatic, Leveling, or a class specialization.\nDrag to move the panel.") end)
 frame.guide:SetScript("OnLeave",function() GameTooltip:Hide() end)
 frame.guide:SetScript("OnClick",function()
  GameTooltip:Hide()
  if frame.guideMenu:IsShown() then frame.guideMenu:Hide(); return end
  updateGuideMenu()
  frame.guideMenu:SetScale(frame:GetScale())
  frame.guideMenu:ClearAllPoints(); frame.guideMenu:SetPoint("TOPLEFT",frame.guide,"BOTTOMLEFT",-4,-3)
  frame.guideCatcher:Show(); frame.guideMenu:Show()
 end)
 frame.meta=text(drag,9); frame.meta:SetPoint("TOPLEFT",14,-37); frame.meta:SetWidth(160); frame.meta:SetWordWrap(false); frame.meta:SetTextColor(0.5,0.58,0.68)
 frame.mode=chip(drag,52); frame.mode:SetPoint("TOPRIGHT",-14,-31)
 frame.mode:SetScript("OnClick",function() db.aoe=not db.aoe; render() end)
 frame.role=chip(drag,56); frame.role:SetPoint("RIGHT",frame.mode,"LEFT",-5,0)
 frame.role:SetScript("OnClick",function()
  local p=NS.profiles[class] and NS.profiles[class][spec]
  if p and p.melee then db.role=effectiveRole()=="melee" and "ranged" or "melee"
  elseif p and p.healing then db.role=effectiveRole()=="heal" and "damage" or "heal" else db.role=effectiveRole()=="bear" and "damage" or "bear" end
  render()
 end)
 frame.caption=text(frame,10); frame.caption:SetTextColor(0.6,0.67,0.76)
 frame.empty=text(frame,12); frame.empty:SetPoint("TOPLEFT",14,-67); frame.empty:SetWidth(282)
 createGuideMenu()
 frame:SetScript("OnHide",function() frame.guideMenu:Hide() end)
end
SLASH_EVERFROST1="/everfrost"
SLASH_EVERFROST2="/fguide"
SLASH_EVERFROST3="/frh"
SlashCmdList.EVERFROST=function(message)
 if not frame then return end
 local command,arg=message:lower():match("^%s*(%S*)%s*(.-)%s*$")
 if command=="" or command=="show" then db.hidden=false
 elseif command=="hide" then db.hidden=true
 elseif command=="lock" then db.locked=true
 elseif command=="unlock" then db.locked=false
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
   local p=NS.GearProfile(class,spec,effectiveRole())
   say((db.gear==false and "Gear highlights OFF. " or "Gear highlights ON. ")..(p and ("Stat order: "..NS.GearPriorityText(p)..". Estimated weights; inspect special effects.") or "Select a talent tree to score gear."))
  end
 elseif command=="reset" then resetPosition(); db.scale=1; frame:SetScale(1); db.hidden=false
 elseif command=="scale" then
  local n=tonumber(arg); if n and n>=0.6 and n<=2 then db.scale=n; frame:SetScale(n) else say("Scale must be 0.6-2.") end
 elseif command=="source" then say(frame.profile and frame.profile.source or "No profile for this class.")
 elseif command=="status" then say(class.." / "..spec.." / "..level.." / "..status..(scanError and " / "..scanError or ""))
 else say("/everfrost show | hide | lock | unlock | single | aoe | heal | damage | bear | cat | ranged | melee | spec auto/1/2/3 | gear on/off | scale 1 | reset | refresh | source | status") end
 render()
end
local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_LOGIN","PLAYER_ENTERING_WORLD","PLAYER_LEVEL_UP","SPELLS_CHANGED","LEARNED_SPELL_IN_TAB",
 "PLAYER_TALENT_UPDATE","CHARACTER_POINTS_CHANGED","ACTIVE_TALENT_GROUP_CHANGED","PLAYER_SPECIALIZATION_CHANGED",
 "PLAYER_REGEN_ENABLED","SPELL_UPDATE_COOLDOWN","SPELL_DATA_LOAD_RESULT"}) do
 pcall(events.RegisterEvent,events,event)
end
events:SetScript("OnEvent",function(_,event,value)
 if event=="PLAYER_LOGIN" then
  EverfrostDB=type(EverfrostDB)=="table" and EverfrostDB or {}
  db=EverfrostDB; db.scale=type(db.scale)=="number" and math.max(0.6,math.min(2,db.scale)) or 1
  className,class=UnitClass("player"); level=UnitLevel("player"); refresh(); createUI(); render()
 elseif not frame then return
 elseif event=="SPELL_UPDATE_COOLDOWN" then cooldowns()
 elseif event=="PLAYER_LEVEL_UP" then level=value; refresh(); render()
 elseif event=="PLAYER_REGEN_ENABLED" then if pending then refresh(); render() end
 else refresh(); render() end
end)




