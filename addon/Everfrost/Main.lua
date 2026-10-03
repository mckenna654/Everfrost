local _, NS=...
local frame,db,known=nil,nil,{}
local class,className,level,spec,status="","",1,0,""
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
 spec,status=NS.DetectSpec(class)
 if db.spec and NS.trees[class] and NS.trees[class][db.spec] then spec,status=db.spec,"Manual" end
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
 local list,note,profile=NS.BuildRows(class,spec,level,known,db.aoe and "aoe" or "single",role)
 local specName=NS.trees[class] and NS.trees[class][spec] or "Leveling"
 frame.title:SetText(specName.."  "..className)
 frame.meta:SetText("LEVEL "..level.."   /   "..status:upper())
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
 frame.title=text(drag,12); frame.title:SetPoint("TOPLEFT",14,-13); frame.title:SetWidth(285)
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
  if arg=="auto" then db.spec=nil; refresh()
  elseif n and NS.trees[class] and NS.trees[class][n] then db.spec=n; refresh()
  else say("/everfrost spec auto, or 1/2/3 in talent-tree order.") end
 elseif command=="refresh" then refresh()
 elseif command=="reset" then resetPosition(); db.scale=1; frame:SetScale(1); db.hidden=false
 elseif command=="scale" then
  local n=tonumber(arg); if n and n>=0.6 and n<=2 then db.scale=n; frame:SetScale(n) else say("Scale must be 0.6-2.") end
 elseif command=="source" then say(frame.profile and frame.profile.source or "No profile for this class.")
 elseif command=="status" then say(class.." / "..spec.." / "..level.." / "..status..(scanError and " / "..scanError or ""))
 else say("/everfrost show | hide | lock | unlock | single | aoe | heal | damage | bear | cat | ranged | melee | spec auto/1/2/3 | scale 1 | reset | refresh | source | status") end
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




