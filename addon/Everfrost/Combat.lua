local _, NS = ...
-- Combat awareness for the rotation HUD: an estimated enemy count, the input device in use, and
-- the rotation engine that turns the guide's priorities into NOW, upcoming and utility icons.
--
-- Forever (1.60.1) hides much of combat from addons. Checked against Blizzard's Forever API
-- definitions: the combat log is restricted, spell cooldowns, threat and unit identity can be
-- secret while restrictions are active, and secret values must never be compared or branched on.
-- So every reading here goes through NS.Public, and anything secret counts as "unknown", never
-- as a guess. Cooldown duration objects go straight to Cooldown widgets.

local function now() return GetTime and GetTime() or 0 end
local function public(value) return NS.Public(value) end
local function first(fn,...)
 local result=NS.Call(fn,...); return result and result[1]
end

-------------------------------------------------------------------------------
-- Enemy tracker: hostile, in-combat enemies with visible nameplates.
-------------------------------------------------------------------------------
local E={entries={},ghosts={},plates={},grace=1.5,stale=5,count=nil,estimated=true,unknown=false}
NS.Enemies=E
-- One reading of a unit: true (engaged enemy), false (not one), nil (the game won't say).
local function engaged(unit)
 local exists=first(UnitExists,unit)
 if not public(exists) then return nil end
 if not exists then return false end
 local attackable=first(UnitCanAttack,"player",unit)
 if not public(attackable) then return nil end
 if not attackable then return false end
 local dead=first(UnitIsDead,unit)
 if not public(dead) then return nil end
 if dead then return false,true end
 -- Pets, totems and players are left out: they aren't the pack being pulled.
 local controlled=first(UnitPlayerControlled,unit)
 if public(controlled) and controlled then return false end
 local creature=first(UnitCreatureType,unit)
 if public(creature) and creature=="Totem" then return false end
 local fighting=first(UnitAffectingCombat,unit)
 if not public(fighting) then return nil end
 if not fighting then return false end
 -- Where threat is readable, it must be on your group's threat table, not just fighting someone.
 local threat=type(UnitThreatSituation)=="function" and NS.Call(UnitThreatSituation,"player",unit)
 if threat and public(threat[1]) and threat[1]==nil then
  local targeting=first(UnitIsUnit,unit.."target","player")
  if public(targeting) and targeting then return true end
  -- Not on your threat table: in a group, the pull may still be your party's.
  local inGroup=first(IsInGroup)
  if not (public(inGroup) and inGroup) then return false end
 end
 return true
end
E.Engaged=engaged
function E.PlateAdded(unit) E.plates[unit]=true end
function E.PlateRemoved(unit)
 E.plates[unit]=nil
 local entry=E.entries[unit]
 -- The token is reused by the next plate, so an enemy that walked out of view is kept apart
 -- until it goes stale; a dead one is gone at once.
 if entry and not entry.dead then E.ghosts[#E.ghosts+1]={seen=entry.seen} end
 E.entries[unit]=nil
end
function E.Clear()
 E.entries={}; E.ghosts={}; E.count=nil; E.unknown=false; E.lowered=nil
end
-- Reads every visible plate (and the target, for players with enemy plates off). Returns the
-- count, or nil when nothing could be read reliably.
function E.Scan(time)
 time=time or now()
 local readable,unknown=0,0
 local seenTarget=false
 for unit in pairs(E.plates) do
  local yes=engaged(unit)
  if yes==nil then unknown=unknown+1
  else
   readable=readable+1
   if yes then
    E.entries[unit]=E.entries[unit] or {}
    E.entries[unit].seen=time; E.entries[unit].dead=nil
    local same=first(UnitIsUnit,unit,"target")
    if public(same) and same then seenTarget=true end
   else E.entries[unit]=nil end
  end
 end
 if not seenTarget then
  local yes=engaged("target")
  if yes then E.entries.target={seen=time}
  elseif yes==false then E.entries.target=nil
  else unknown=unknown+1 end
 else E.entries.target=nil end
 local count=0
 for _,entry in pairs(E.entries) do if time-entry.seen<=E.stale then count=count+1 end end
 local kept={}
 for _,ghost in ipairs(E.ghosts) do
  if time-ghost.seen<=E.stale then kept[#kept+1]=ghost; count=count+1 end
 end
 E.ghosts=kept
 for key,entry in pairs(E.entries) do if time-entry.seen>E.stale then E.entries[key]=nil end end
 E.unknown=readable==0 and unknown>0
 E.count=not E.unknown and count or nil
 return E.count
end

-------------------------------------------------------------------------------
-- Rotation mode: manual or automatic, with a grace period before stepping down.
-------------------------------------------------------------------------------
local M={}
NS.Modes=M
M.order={"auto","single","cleave","aoe"}
M.short={auto="AUTO",single="ST",cleave="CLV",aoe="AOE"}
M.label={auto="Automatic",single="Single target",cleave="Cleave (2 enemies)",aoe="AoE (3 or more)"}
function M.Normal(value)
 if value=="st" then return "single" end
 if value=="clv" then return "cleave" end
 for _,key in ipairs(M.order) do if key==value then return key end end
 return nil
end
-- Thresholds per spec key ("PALADIN2"); defaults 2 and 3.
function M.Thresholds(db,key)
 local t=db and db.thresholds and db.thresholds[key]
 local cleave=type(t)=="table" and tonumber(t.cleave) or 2
 local aoe=type(t)=="table" and tonumber(t.aoe) or 3
 cleave=math.max(2,math.min(5,cleave)); aoe=math.max(cleave,math.min(8,aoe))
 return cleave,aoe
end
-- The mode for a count, before any grace period.
function M.ForCount(count,cleave,aoe)
 if not count then return "single" end
 if count>=aoe then return "aoe" end
 if count>=cleave then return "cleave" end
 return "single"
end
-- Steps up at once; steps down only after the lower count has held for `grace` seconds.
local current,lowerSince="single",nil
function M.Auto(count,cleave,aoe,grace,time)
 time=time or now()
 local wanted=M.ForCount(count,cleave,aoe)
 local rank={single=1,cleave=2,aoe=3}
 if rank[wanted]>=rank[current] then current=wanted; lowerSince=nil
 elseif not lowerSince then lowerSince=time
 elseif time-lowerSince>=(grace or 1.5) then current=wanted; lowerSince=nil end
 return current
end
function M.Reset() current,lowerSince="single",nil end

-------------------------------------------------------------------------------
-- Input layout: controller or keyboard and mouse, with a debounce.
-------------------------------------------------------------------------------
local I={device="kbm",pendingDevice=nil,pendingAt=nil,debounce=0.75}
NS.Input=I
-- What the game says is in use now: "pad", "kbm", or nil if it can't tell.
function I.Detect()
 local style=C_InputInterfaceStyle and first(C_InputInterfaceStyle.GetCurrentStyle)
 local pad=Enum and Enum.InputDeviceInterfaceType and Enum.InputDeviceInterfaceType.Gamepad or 1
 if public(style) and type(style)=="number" then return style==pad and "pad" or "kbm" end
 -- Older path: gamepad mode switched on in the game's settings (ConsolePort uses it too).
 local enabled=C_GamePad and first(C_GamePad.IsEnabled)
 if public(enabled) and type(enabled)=="boolean" then return enabled and "pad" or "kbm" end
 return nil
end
-- Which saved layout to use, given the setting: auto, pad, kbm or custom.
function I.Layout(setting)
 if setting=="pad" or setting=="kbm" then return setting end
 if setting=="custom" then return "kbm" end
 return I.device
end
-- Called on device events and from the HUD's ticker. Returns true when the layout changed.
function I.Offer(device,time)
 time=time or now()
 if device~="pad" and device~="kbm" then return false end
 if device==I.device then I.pendingDevice=nil; return false end
 if I.pendingDevice~=device then I.pendingDevice=device; I.pendingAt=time; return false end
 if time-I.pendingAt<I.debounce then return false end
 I.device=device; I.pendingDevice=nil
 return true
end

-------------------------------------------------------------------------------
-- Rotation engine. One engine for every HUD layout.
-------------------------------------------------------------------------------
local R={}
NS.Rotation=R
-- Blizzard's rotation assistant: the game's own next-cast suggestion, which knows cooldowns,
-- resources and procs that addons can't read in combat. Nil when unavailable.
function R.AssistSpell()
 local api=C_AssistedCombat
 if not api then return nil end
 local available=first(api.IsAvailable)
 if public(available) and available==false then return nil end
 local spell=first(api.GetNextCastSpell,false)
 if spell==nil then return nil end
 return spell
end
function R.AssistReason()
 local api=C_AssistedCombat
 if not api or type(api.IsAvailable)~="function" then return "Blizzard's rotation assistant isn't in this client." end
 local result=NS.Call(api.IsAvailable)
 if not result then return "Blizzard's rotation assistant didn't answer." end
 if public(result[1]) and result[1]==false then
  return public(result[2]) and type(result[2])=="string" and result[2]~="" and result[2] or "Blizzard's rotation assistant isn't available for this character."
 end
 return nil
end
-- Usable now (true), not usable (false), or unknown (nil). Not usable covers missing mana or rage
-- and spells the target can't take (Exorcism needs Undead or Demons).
function R.Usable(id)
 local result=NS.Call(C_Spell and C_Spell.IsSpellUsable,id)
 if not result or not public(result[1]) or type(result[1])~="boolean" then return nil end
 return result[1],public(result[2]) and result[2]==true
end
-- Seconds of cooldown left beyond the global cooldown, or nil when the game keeps it secret.
function R.CooldownLeft(id)
 local info=first(C_Spell and C_Spell.GetSpellCooldown,id)
 if type(info)~="table" then return nil end
 local start,duration=info.startTime,info.duration
 if not (public(start) and public(duration)) or type(start)~="number" or type(duration)~="number" then return nil end
 if duration<=1.5 then return 0 end
 return math.max(0,start+duration-now())
end
-- Whether the player has a buff from this spell: true, false, or nil when it can't be read.
function R.HasBuff(id)
 -- In combat an aura can be hidden and read as missing, so reminders wait for combat to end.
 if InCombatLockdown and InCombatLockdown() then return nil end
 local api=C_UnitAuras
 if not (api and type(api.GetPlayerAuraBySpellID)=="function") then return nil end
 local result=NS.Call(api.GetPlayerAuraBySpellID,id)
 if not result then return nil end
 local aura=result[1]
 if aura==nil then return false end
 if not public(aura) then return nil end
 return true
end
-- rows: NS.BuildRows output for the active mode; utility: NS.utility[class] entries with .spell
-- (learned only). opts: assist (spell ID or secret), count (upcoming icons), probe (functions,
-- replaceable in tests). Returns {now, upcoming={...}, utility={...}, reminders={...}, source}.
function R.Build(rows,utility,opts)
 opts=opts or {}
 local probe=opts.probe or R
 local result={upcoming={},utility={},reminders={},source="guide"}
 local isUtility={}
 for _,entry in ipairs(utility or {}) do isUtility[entry.name]=true end
 local offence={}
 for _,row in ipairs(rows) do
  if NS.upkeep[row.key] then
   -- Buff reminders: only when the game says it's missing. Unknown (secret) shows nothing.
   if probe.HasBuff(row.spell.id)==false then result.reminders[#result.reminders+1]=row end
  elseif not isUtility[row.key] then offence[#offence+1]=row end
 end
 -- Ready spells first, in guide order; then those the game says are cooling down or unusable.
 -- When the game won't say, guide order stands and the icon's cooldown sweep tells the rest.
 local ready,later={},{}
 for _,row in ipairs(offence) do
  local usable=probe.Usable(row.spell.id)
  local left=probe.CooldownLeft(row.spell.id)
  row.usable=usable; row.cooldown=left
  if usable==false or (left and left>0) then later[#later+1]=row else ready[#ready+1]=row end
 end
 -- Soonest off cooldown first; spells the game says can't be cast (no mana, wrong target) last.
 local function wait(row) if row.usable==false then return math.huge end return row.cooldown or 0 end
 for index,row in ipairs(offence) do row.order=index end
 table.sort(later,function(a,b)
  local la,lb=wait(a),wait(b)
  if la~=lb then return la<lb end
  return (a.order or 0)<(b.order or 0)
 end)
 local ordered={}
 for _,row in ipairs(ready) do ordered[#ordered+1]=row end
 for _,row in ipairs(later) do ordered[#ordered+1]=row end
 local assist=opts.assist
 local nowRow
 if assist~=nil then
  result.source="assist"
  if public(assist) then
   -- Matched by ID, or by name when the assistant names another rank of the same spell.
   local name=first(C_Spell and C_Spell.GetSpellName,assist)
   if not (public(name) and type(name)=="string") then name=nil end
   for index,row in ipairs(ordered) do
    if row.spell.id==assist or (name and row.spell.name==name) then nowRow=row; table.remove(ordered,index); break end
   end
   nowRow=nowRow or {spell={id=assist}}
   nowRow.assist=assist
  else
   -- A secret suggestion is shown as it is and compared with nothing.
   nowRow={assist=assist,spell={id=assist},secret=true}
  end
 else
  -- Steps that wait for a proc the addon can't see in combat (Missile Barrage, Nightfall) are
  -- never NOW on the guide's word alone; they stay in the upcoming list with their hint.
  for index,row in ipairs(ordered) do
   if not row.proc then nowRow=table.remove(ordered,index); break end
  end
 end
 result.now=nowRow
 for index=1,math.min(opts.count or 3,#ordered) do result.upcoming[index]=ordered[index] end
 for _,entry in ipairs(utility or {}) do
  if entry.spell then result.utility[#result.utility+1]=entry end
 end
 return result
end
