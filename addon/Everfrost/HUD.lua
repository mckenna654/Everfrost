local _, NS = ...
-- The rotation HUD's icons. Main.lua owns the frame, its header and its settings; this file
-- draws the NOW icon, the upcoming track and the defensive/utility row for any of the four
-- layouts, all fed by the one rotation engine (Combat.lua).
local H={}
NS.HUD=H
H.layouts={"track","classic","minimal","tank"}
H.layoutLabel={track="Guitar Hero",classic="Classic row",minimal="Minimal",tank="Tank"}
H.layoutHelp={
 track="Upcoming spells slide towards a fixed NOW icon.",
 classic="A plain row of recommended spells, no movement.",
 minimal="One large spell and two small ones.",
 tank="The track plus a separate defensive and utility row.",
}
-- Base icon sizes in pixels (before the layout's scale), per input layout.
H.sizes={kbm={now=48,up=36,util=28},pad={now=60,up=44,util=34}}
local GAP=6
local ACCENT={0.55,0.8,1}

local function iconTexture(spell)
 if spell.icon then return spell.icon end
 local result=NS.Call(C_Spell and C_Spell.GetSpellTexture,spell.id)
 -- A secret texture may still be handed to the widget; it just can't be inspected.
 return result and result[1] or 134400
end

local function tooltip(self)
 local row=self.row
 if not row or not row.spell then return end
 GameTooltip:SetOwner(self,"ANCHOR_TOP")
 NS.Call(GameTooltip.SetSpellByID,GameTooltip,row.spell.id)
 GameTooltip:AddLine(" ")
 if self.role=="now" then
  GameTooltip:AddLine(row.assist and "NOW: Blizzard's rotation assistant suggests this." or "NOW: highest Everfrost guide priority that is ready.",ACCENT[1],ACCENT[2],ACCENT[3],true)
 elseif self.role=="up" then
  GameTooltip:AddLine("Coming up in priority order. A priority, not a guaranteed cast order.",0.75,0.8,0.86,true)
 elseif self.role=="util" then
  local kind=row.kind=="interrupt" and "Interrupt" or row.kind=="taunt" and "Taunt" or row.kind=="emergency" and "Emergency" or "Defensive"
  GameTooltip:AddLine(kind..(row.major and ": situational. Save it for real danger, not just because it's ready." or ": available when the situation calls for it."),0.75,0.8,0.86,true)
 elseif self.role=="reminder" then
  GameTooltip:AddLine("Missing buff: put it back up before the pull.",1,0.82,0,true)
 end
 if row.hint then GameTooltip:AddLine(row.hint,0.85,0.9,1,true) end
 if row.usable==false then GameTooltip:AddLine(row.noPower and "Not enough mana, rage or energy." or "Not usable right now.",1,0.4,0.4,true) end
 GameTooltip:Show()
end

local function makeIcon(parent,role)
 local b=CreateFrame("Button",nil,parent)
 b.role=role
 b:EnableMouse(parent.hud==nil or parent.hud.interactive~=false); b:RegisterForDrag("LeftButton")
 b.edge=b:CreateTexture(nil,"BACKGROUND"); b.edge:SetPoint("TOPLEFT",-1,1); b.edge:SetPoint("BOTTOMRIGHT",1,-1)
 b.edge:SetColorTexture(0,0,0,0.85)
 b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetAllPoints(); b.icon:SetTexCoord(0.08,0.92,0.08,0.92)
 b.cd=CreateFrame("Cooldown",nil,b,"CooldownFrameTemplate"); b.cd:SetAllPoints(); b.cd:SetDrawEdge(false)
 if b.cd.SetHideCountdownNumbers then b.cd:SetHideCountdownNumbers(role~="now") end
 b:SetScript("OnEnter",tooltip)
 b:SetScript("OnLeave",function() GameTooltip:Hide() end)
 b:SetScript("OnDragStart",function() if parent.StartDrag then parent.StartDrag() end end)
 b:SetScript("OnDragStop",function() if parent.StopDrag then parent.StopDrag() end end)
 b:SetScript("OnMouseUp",function(_,mouse) if mouse=="RightButton" and parent.OpenSettings then parent.OpenSettings() end end)
 b:Hide()
 return b
end

-- Builds the icon pool on the HUD frame. Called once.
function H.Attach(frame)
 frame.hud={queue={},util={},anim=nil}
 local hud=frame.hud
 hud.now=makeIcon(frame,"now")
 -- The strike zone: two thin accent bars marking where the next press lands.
 hud.zoneTop=frame:CreateTexture(nil,"OVERLAY"); hud.zoneTop:SetColorTexture(ACCENT[1],ACCENT[2],ACCENT[3],0.9)
 hud.zoneBottom=frame:CreateTexture(nil,"OVERLAY"); hud.zoneBottom:SetColorTexture(ACCENT[1],ACCENT[2],ACCENT[3],0.9)
 -- A faint lane behind the upcoming icons, so the track reads as one piece.
 hud.lane=frame:CreateTexture(nil,"BACKGROUND"); hud.lane:SetColorTexture(0,0,0,0.25)
 -- The pulse: a soft border that fades out when a new spell takes the NOW spot.
 hud.flash=hud.now:CreateTexture(nil,"OVERLAY"); hud.flash:SetPoint("TOPLEFT",-3,3); hud.flash:SetPoint("BOTTOMRIGHT",3,-3)
 hud.flash:SetTexture("Interface\\Buttons\\UI-ActionButton-Border"); hud.flash:SetBlendMode("ADD")
 hud.flash:SetVertexColor(ACCENT[1],ACCENT[2],ACCENT[3]); hud.flash:SetAlpha(0)
 hud.placeholder=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 hud.placeholder:SetJustifyH("LEFT")
 return hud
end

local function setIcon(b,row,size)
 b.row=row; b:SetSize(size,size)
 b.icon:SetTexture(iconTexture(row.spell))
 b.spellID=row.spell.id
 if row.usable==false then
  b.icon:SetDesaturated(true)
  if row.noPower then b.icon:SetVertexColor(0.5,0.6,1) else b.icon:SetVertexColor(0.7,0.7,0.7) end
 else b.icon:SetDesaturated(false); b.icon:SetVertexColor(1,1,1) end
 b:SetAlpha(row.major and 0.7 or 1)
 b:Show()
end

local function cooldown(b)
 if not (b:IsShown() and b.spellID) then return end
 local result=NS.Call(C_Spell and C_Spell.GetSpellCooldownDuration,b.spellID,true)
 local duration=result and result[1]
 -- Duration objects go straight to the widget; they are never read here.
 if duration and b.cd.SetCooldownFromDurationObject then b.cd:SetCooldownFromDurationObject(duration)
 else b.cd:Clear() end
end
-- Icons take the mouse only when tooltips are wanted, so the HUD never eats a click in combat.
function H.SetInteractive(frame,on)
 local hud=frame.hud
 if not hud or hud.interactive==on then return end
 hud.interactive=on
 hud.now:EnableMouse(on)
 for _,b in ipairs(hud.queue) do b:EnableMouse(on) end
 for _,b in ipairs(hud.util) do b:EnableMouse(on) end
end
function H.Cooldowns(frame)
 local hud=frame and frame.hud
 if not hud or not frame:IsShown() then return end
 cooldown(hud.now)
 for _,b in ipairs(hud.queue) do cooldown(b) end
 for _,b in ipairs(hud.util) do cooldown(b) end
end

local function rowKey(row) return row and not row.secret and row.spell and row.spell.id or nil end

-- Animation: one OnUpdate, running only while something is moving.
local function animate(frame)
 local hud=frame.hud
 local anim=hud.anim
 if not anim then frame:SetScript("OnUpdate",nil); return end
 frame:SetScript("OnUpdate",function(_,elapsed)
  anim.t=anim.t+(elapsed or 0)
  local p=math.min(1,anim.t/anim.duration)
  local ease=1-(1-p)*(1-p)
  for _,b in ipairs(hud.queue) do
   if b:IsShown() then
    b:ClearAllPoints(); b:SetPoint("TOPLEFT",frame,"TOPLEFT",b.baseX+(anim.shift or 0)*(1-ease),b.baseY)
   end
  end
  hud.flash:SetAlpha(anim.flash and (1-p)*0.9 or 0)
  if p>=1 then hud.anim=nil; frame:SetScript("OnUpdate",frame.Ticker) end
 end)
end

-- state: layout, device ("kbm"/"pad"), scale (number), upcoming (count), showUtility (bool),
-- animate (bool), speed (0.5-2), result (Rotation.Build), placeholder (text when empty).
-- Returns the width and height the icons use, for sizing the frame.
function H.Apply(frame,state,top)
 local hud=frame.hud
 local base=H.sizes[state.device] or H.sizes.kbm
 local layout=state.layout or "track"
 local nowSize,upSize,utilSize=base.now,base.up,base.util
 local count=math.max(0,math.min(6,state.upcoming or 3))
 if layout=="classic" then upSize=math.floor(nowSize*0.8+0.5)
 elseif layout=="minimal" then count=math.min(count,2); upSize=math.floor(nowSize*0.6+0.5) end
 local showUtility=state.showUtility or layout=="tank"
 local result=state.result or {upcoming={},utility={},reminders={}}
 top=top or 0
 local y=-top
 local x=0
 local oldNow=hud.nowKey
 -- NOW
 local nowRow=result.now
 if nowRow then
  setIcon(hud.now,nowRow,nowSize)
  hud.now:ClearAllPoints(); hud.now:SetPoint("TOPLEFT",frame,"TOPLEFT",x,y)
  hud.placeholder:Hide()
 else
  hud.now:Hide(); hud.now.row=nil; hud.now.spellID=nil
  hud.placeholder:SetText(state.placeholder or "")
  hud.placeholder:ClearAllPoints(); hud.placeholder:SetPoint("TOPLEFT",frame,"TOPLEFT",0,y-4)
  hud.placeholder:SetWidth(240); hud.placeholder:Show()
 end
 local zone=layout~="classic" and nowRow~=nil
 hud.zoneTop:SetShown(zone); hud.zoneBottom:SetShown(zone)
 if zone then
  hud.zoneTop:ClearAllPoints(); hud.zoneTop:SetPoint("BOTTOMLEFT",hud.now,"TOPLEFT",0,3); hud.zoneTop:SetSize(nowSize,2)
  hud.zoneBottom:ClearAllPoints(); hud.zoneBottom:SetPoint("TOPLEFT",hud.now,"BOTTOMLEFT",0,-3); hud.zoneBottom:SetSize(nowSize,2)
 end
 x=nowRow and nowSize+GAP*2 or 0
 -- Upcoming: aligned to the NOW icon's middle.
 local upY=y-math.floor((nowSize-upSize)/2)
 local newKeys={}
 for index=1,math.max(count,#hud.queue) do
  local b=hud.queue[index]
  local row=index<=count and result.upcoming[index] or nil
  if row then
   b=b or makeIcon(frame,"up"); hud.queue[index]=b
   setIcon(b,row,upSize)
   b.baseX=x+(index-1)*(upSize+GAP); b.baseY=upY
   b:ClearAllPoints(); b:SetPoint("TOPLEFT",frame,"TOPLEFT",b.baseX,b.baseY)
   newKeys[index]=rowKey(row)
  elseif b then b:Hide(); b.row=nil; b.spellID=nil; b.cd:Clear() end
 end
 local shown=0
 for index=1,count do if result.upcoming[index] then shown=index end end
 local width=nowRow and nowSize or 240
 if shown>0 then width=x+shown*(upSize+GAP)-GAP end
 hud.lane:SetShown(layout=="track" and shown>0)
 if layout=="track" and shown>0 then
  hud.lane:ClearAllPoints(); hud.lane:SetPoint("TOPLEFT",frame,"TOPLEFT",x-GAP,upY+3)
  hud.lane:SetSize(width-x+GAP*2,upSize+6)
 end
 local height=nowRow and nowSize or 20
 -- Defensive and utility row, then missing-buff reminders, under the track.
 local extras={}
 if showUtility then for _,entry in ipairs(result.utility or {}) do extras[#extras+1]=entry end end
 local reminderStart=#extras+1
 for _,row in ipairs(result.reminders or {}) do extras[#extras+1]=row end
 local utilY=y-height-GAP-(zone and 4 or 0)
 local pool=hud.util
 for index=1,math.max(#extras,#pool) do
  local b=pool[index]
  local entry=extras[index]
  if entry then
   b=b or makeIcon(frame,"util"); pool[index]=b
   b.role=index>=reminderStart and "reminder" or "util"
   setIcon(b,entry,utilSize)
   b:ClearAllPoints(); b:SetPoint("TOPLEFT",frame,"TOPLEFT",(index-1)*(utilSize+GAP),utilY)
  elseif b then b:Hide(); b.row=nil; b.spellID=nil; b.cd:Clear() end
 end
 if #extras>0 then
  height=height+GAP+(zone and 4 or 0)+utilSize
  width=math.max(width,#extras*(utilSize+GAP)-GAP)
 end
 -- Movement: when the first upcoming spell becomes NOW, the track slides one slot left.
 local nowKey=rowKey(nowRow)
 hud.nowKey=nowKey
 local moved=oldNow~=nil and nowKey~=nil and nowKey~=oldNow
 -- The same NOW spell turning usable (mana back, cooldown over) gets the pulse too.
 local ready=nowKey~=nil and nowKey==oldNow and hud.nowUsable==false and nowRow.usable~=false
 hud.nowUsable=nowRow and nowRow.usable
 if (moved or ready) and state.animate~=false then
  local slid=moved and hud.lastFirst~=nil and hud.lastFirst==nowKey and layout=="track"
  local speed=math.max(0.5,math.min(2,state.speed or 1))
  hud.anim={t=0,duration=0.22/speed,shift=slid and (upSize+GAP) or nil,flash=true}
  animate(frame)
 end
 hud.lastFirst=newKeys[1]
 return width,height
end
