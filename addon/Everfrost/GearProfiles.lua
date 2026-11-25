local _, NS = ...
NS.gearMinLevel=10
NS.gearLevelNote="Below level 10, gear hints use a simple starter priority for your class. Talent-based priorities start at level 10."
-- Two kinds of profile:
--   simulated  numeric weights measured by the wowsims Forever simulator (https://wowsims.com/forever,
--              MIT licence), copied from its per-spec presets at commit d45287b (2026-11-24) and
--              listed in docs/GEAR.md. They are level 60 values against a raid boss.
--   estimate   no simulator publishes weights for the spec, so the Stats order of its Icy Veins
--              Forever levelling guide (reviewed 2026-11-11) is turned into rank weights.
-- A weight is the value of one point as the item shows it. Forever writes Hit, Crit and the like
-- as whole percentages, and the simulator weighs them per rating point, so those are multiplied
-- by the simulator's rating per 1% (ui/sim/constants/mechanics.ts).
NS.gearStatUnits={hit=10,crit=14,haste=10,expertise=10,dodge=12,parry=15,blockpct=5}
NS.gearWeightSource={name="wowsims Forever",url="wowsims.com/forever",commit="d45287b",date="2026-11-24"}
NS.gearProfiles = {}
local caster={caster=true,healer=true}
-- Rank weights for an estimate. Weapon DPS and armour keep the scales they have always had here.
local estimateUnits={dps=12,armor=0.1}
local function build(class, spec, order, options)
 local p = {}
 for key, value in pairs(options or {}) do p[key] = value end
 p.order = order; p.weights = {}
 for rank, group in ipairs(order) do
  for key in group:gmatch("%S+") do
   p.weights[key] = (#order - rank + 1) * (estimateUnits[key] or NS.gearStatUnits[key] or 1)
  end
 end
 local w = p.weights
 -- "block" in an order covers block value and block chance alike.
 if w.block then w.blockpct = w.block * NS.gearStatUnits.blockpct end
 -- Attack power follows the better of Strength and Agility when the order leaves it out.
 if not caster[p.kind] and not w.attack then
  local primary = math.max(w.strength or 0, w.agility or 0)
  w.attack = (primary > 0 and primary or 1) / 2
 end
 -- Armour counts a little for everyone; a profile that ranks it treats it as one of its stats.
 p.armorRanked = w.armor ~= nil
 w.armor = w.armor or estimateUnits.armor
 -- A wand is a caster's Shoot damage. No guide ranks it, so its DPS earns a small fixed credit.
 if caster[p.kind] then w.wand = 1 end
 p.source = NS.profiles[class][spec].source
 p.class, p.spec = class, spec
 p.id = class..":"..spec
 p.weightSource = "Everfrost estimate from the Icy Veins stat order"
 return p
end
-- The stat order a set of weights implies, heaviest first, for the priority line and the
-- reasons tooltips give. Percentage stats are compared per rating point, as the simulator
-- lists them. Stats within a hair of each other share a group.
local orderKeys={"dps","hit","expertise","crit","haste","spell","healing","strength","agility","attack","intellect",
 "stamina","spirit","mp5","defense","dodge","parry","block","armor"}
function NS.GearOrderFromWeights(p)
 local list = {}
 for index, key in ipairs(orderKeys) do
  local weight = p.weights[key] or 0
  if weight > 0 and (key ~= "armor" or p.armorRanked) then
   list[#list+1] = {key=key, value=weight / (NS.gearStatUnits[key] or 1), index=index}
  end
 end
 table.sort(list, function(a, b) if a.value ~= b.value then return a.value > b.value end; return a.index < b.index end)
 local order, last = {}, nil
 for _, entry in ipairs(list) do
  if last and math.abs(last - entry.value) < 1e-9 then order[#order] = order[#order].." "..entry.key
  else order[#order+1] = entry.key end
  last = entry.value
 end
 return order
end
-- The simulator measures damage (or threat and survival for tanks), so Stamina and armour are
-- worth nothing to its damage specs. While levelling they are not, so each simulated damage or
-- healing profile gets a small Everfrost allowance for them, on that profile's own scale.
local MELEE={stamina=0.25,armor=0.02}   -- attack power = 1, Strength about 2.2
local CAT={stamina=0.07,armor=0.006}    -- Agility about 0.65
local RANGED={stamina=0.12,armor=0.01}  -- Agility = 1
local SPELL={stamina=0.1,armor=0.005}   -- spell or healing power = 1
-- A simulated profile: weights as the preset lists them (per rating point for percentage stats).
local function simulated(class, spec, preset, listed, options)
 local p = {}
 for key, value in pairs(options or {}) do p[key] = value end
 p.weights = {}
 for key, value in pairs(listed) do p.weights[key] = value * (NS.gearStatUnits[key] or 1) end
 local w, allowance = p.weights, p.allowance
 p.armorRanked = w.armor ~= nil
 if allowance then
  w.stamina = math.max(w.stamina or 0, allowance.stamina)
  w.armor = w.armor or allowance.armor
 end
 if caster[p.kind] then w.wand = 0.15 end
 p.order = NS.GearOrderFromWeights(p)
 p.source = NS.profiles[class][spec].source
 p.class, p.spec = class, spec
 p.id = class..":"..spec
 p.sim = preset
 p.weightSource = NS.gearWeightSource.name.." simulator ("..preset..")"
 return p
end
local function profile(class, spec, order, options)
 NS.gearProfiles[class] = NS.gearProfiles[class] or {}
 NS.gearProfiles[class][spec] = build(class, spec, order, options)
end
local function sim(class, spec, preset, listed, options)
 NS.gearProfiles[class] = NS.gearProfiles[class] or {}
 NS.gearProfiles[class][spec] = simulated(class, spec, preset, listed, options)
end
-- Paladin. Holy and Protection have no simulator weights yet.
profile("PALADIN",1,{"healing","intellect","mp5","crit","haste","spirit"},{kind="healer"})
profile("PALADIN",2,{"stamina","spell","strength","block","hit","defense","armor","intellect","agility"},{kind="tank",shield=true,school="holy"})
sim("PALADIN",3,"Unsealed Wrath",{strength=2.4,agility=1.91,intellect=1.48,spell=1.95,attack=1,hit=7.76,crit=2.74,
 haste=3.53,expertise=5.45,mp5=0.01,dps=14.14},{kind="melee",schools={holy=1.59/1.95},allowance=MELEE})
-- Hunter. Beast Mastery and Marksmanship stay at range; Survival's melee build has its own preset.
for spec=1,2 do
 sim("HUNTER",spec,"Turret",{agility=1,intellect=0.64,attack=0.34,hit=1.26,crit=0.87,haste=0.75,mp5=0.41,dps=3.29},
  {kind="ranged",allowance=RANGED})
end
sim("HUNTER",3,"Melee",{agility=1,strength=0.41,intellect=0.7,attack=0.37,hit=2.48,crit=1,haste=0.91,mp5=0.23,
 dps=4.86,dps2=1.18},{kind="melee",allowance=RANGED})
-- Mage: no simulator weights yet.
profile("MAGE",1,{"spell","intellect","spirit","crit","hit","stamina","mp5"},{kind="caster",school="arcane"})
profile("MAGE",2,{"spell","crit","intellect","spirit","hit","stamina","mp5"},{kind="caster",school="fire"})
profile("MAGE",3,{"hit","spell","crit","spirit","intellect","stamina"},{kind="caster",school="frost"})
-- Warrior. Arms is measured with a two-hander, so an off-hand weapon's damage is worth nothing to it.
sim("WARRIOR",1,"Pre-BiS Arms",{strength=2.2,agility=1.76,attack=1,hit=5.03,haste=1.29,crit=2.32,expertise=1.57,
 dps=16.71,dps2=0},{kind="melee",allowance=MELEE})
sim("WARRIOR",2,"Pre-BiS Fury",{strength=2.2,agility=1.7,attack=1,hit=1.69,haste=1.76,crit=2.26,expertise=2.35,
 dps=12.59,dps2=2.66},{kind="melee",allowance=MELEE})
sim("WARRIOR",3,"Pre-BiS Balanced",{stamina=1.15,strength=0.62,agility=0.66,attack=0.27,hit=0.04,crit=0.43,haste=0.17,
 expertise=2.35,defense=0.53,blockpct=0,block=0.76,dodge=0.29,parry=0.26,armor=0.06,dps=1.42},{kind="tank",shield=true})
-- Rogue. Combat uses the simulator's default, the slow main hand (Sinister Strike) preset.
sim("ROGUE",1,"Assassination",{stamina=0.01,agility=2.06,strength=1.1,crit=2.02,haste=1.93,hit=2.8,expertise=2.77,
 attack=1,dps=8.44,dps2=4.16},{kind="melee",allowance=MELEE})
sim("ROGUE",2,"Combat Sinister",{stamina=0.01,agility=1.96,strength=1.1,crit=1.7,haste=1.72,hit=2.42,expertise=2.55,
 attack=1,dps=10.57,dps2=2.93},{kind="melee",allowance=MELEE})
sim("ROGUE",3,"Subtlety",{stamina=0.01,agility=1.93,strength=1.1,crit=1.63,haste=1.43,hit=2.12,expertise=2.42,
 attack=1,dps=10.47,dps2=2.27},{kind="melee",allowance=MELEE})
-- Priest. The healing trees use the simulator's single-target presets, the closer fit for dungeons.
sim("PRIEST",1,"Disc Single-Target",{healing=1,crit=0.7,haste=0.15,intellect=0.2,spirit=0.15,mp5=0.4},{kind="healer",allowance=SPELL})
sim("PRIEST",2,"Holy Single-Target",{healing=1,crit=0.3,haste=0.5,intellect=0.35,spirit=0.3,mp5=0.6},{kind="healer",allowance=SPELL})
sim("PRIEST",3,"Shadow",{intellect=0.24,spell=1,spirit=0.01,hit=1.14,crit=0.84,haste=0.73},{kind="caster",school="shadow",allowance=SPELL})
-- Warlock: no simulator weights yet.
profile("WARLOCK",1,{"spell","crit","spirit","intellect stamina","hit","haste"},{kind="caster",school="shadow"})
-- Demonology's Searing Pain is Fire and its other spells Shadow; the guide asks for general spell damage.
profile("WARLOCK",2,{"spell","crit","hit","intellect stamina","spirit","haste"},{kind="caster",schools={fire=0.5,shadow=0.5}})
-- Destruction's main attacks are Fire; Shadow Bolt and Shadowburn still use Shadow.
profile("WARLOCK",3,{"spell","hit","crit","intellect stamina","spirit","haste"},{kind="caster",schools={fire=1,shadow=0.5}})
-- Druid. Feral's default is Cat; Bear is a scoring focus below. Restoration has no simulator weights yet.
sim("DRUID",1,"Pre-BiS",{intellect=0.2,spell=1,hit=1.45,crit=0.76,haste=0.95},{kind="caster",schools={arcane=0.68,nature=0.32},allowance=SPELL})
sim("DRUID",2,"Cat",{strength=0.594,agility=0.655,attack=0.244,hit=0.521,crit=0.506,haste=0.393,expertise=0.49,dps=2.142},
 {kind="melee",allowance=CAT})
profile("DRUID",3,{"healing","intellect","crit","haste","spirit","mp5"},{kind="healer"})
-- Shaman. Restoration has no simulator weights yet.
sim("SHAMAN",1,"Default",{intellect=0.19,spirit=0.02,spell=1,hit=1.18,crit=0.61,haste=1.23,mp5=0.04},
 {kind="caster",schools={fire=0.31,nature=0.69},allowance=SPELL})
sim("SHAMAN",2,"Pre-BiS",{strength=2.2,agility=1.32,intellect=1.99,attack=1,hit=5.2,crit=2.42,haste=2.81,expertise=3.5,
 spell=1.27,dps=14.18},{kind="melee",schools={nature=0.72/1.27},allowance=MELEE})
profile("SHAMAN",3,{"healing","crit","intellect","spirit","mp5","stamina"},{kind="healer"})
-- What each spec's default profile is best for, in the words quest tooltips use.
for class, specs in pairs(NS.gearProfiles) do
 for spec, p in pairs(specs) do
  p.specName = NS.trees[class][spec]
  p.bestFor = p.kind=="healer" and "healing" or p.kind=="tank" and "tanking" or (p.specName.." damage")
 end
end

-- Scoring focus: a spec can offer other weightings, chosen in Settings and read from
-- NS.Gear.focus (a key below, or nil for the default). A focus is either another simulator
-- preset (sim=..., weights=...) or an Everfrost estimate that reorders the stats for one goal
-- (order=...). Keys are shared where the idea is the same, so one saved choice carries across
-- tank specs; an unknown key falls back to the default.
NS.gearFocus = {}
local function focus(class, spec, list)
 local base = NS.gearProfiles[class][spec]
 local entry = {list={}, byKey={}}
 for index, choice in ipairs(list) do
  local p = base
  if choice.order or choice.weights then
   local options = {}
   for _, key in ipairs({"kind","shield","school","schools"}) do options[key] = base[key] end
   for key, value in pairs(choice.options or {}) do options[key] = value end
   if choice.weights then p = simulated(class, spec, choice.sim, choice.weights, options)
   else p = build(class, spec, choice.order, options) end
   p.specName = base.specName
   p.id = base.id..":"..choice.key
  end
  p.focusKey, p.focusLabel, p.bestFor = choice.key, choice.label, choice.bestFor
  local item = {key=choice.key, label=choice.label, profile=p, default=index==1}
  entry.list[index] = item; entry.byKey[choice.key] = item
 end
 NS.gearFocus[class] = NS.gearFocus[class] or {}
 NS.gearFocus[class][spec] = entry
end
-- Protection Paladin: every focus is an estimate. Holy spell power drives Seal, Consecration
-- and Holy Shield threat.
focus("PALADIN", 2, {
 {key="balanced", label="Balanced Tank", bestFor="tanking"},
 {key="survival", label="Tank Survivability", bestFor="tank survivability",
  order={"stamina","armor defense","block dodge parry","agility","strength","spell","hit","intellect"}},
 {key="threat", label="Tank Threat", bestFor="tank threat",
  order={"spell","dps","strength attack","hit","stamina","crit","block","defense armor","intellect"}},
 {key="solo", label="Solo Levelling", bestFor="solo damage",
  order={"dps","spell","strength attack","stamina","crit hit","intellect mp5","armor","block"}},
})
-- Protection Warrior. Balanced and Threat are the simulator's two tank presets (its "Offensive"
-- set is built for threat); Survivability and Solo Levelling are estimates.
focus("WARRIOR", 3, {
 {key="balanced", label="Balanced Tank", bestFor="tanking"},
 {key="survival", label="Tank Survivability", bestFor="tank survivability",
  order={"stamina armor","defense","block dodge parry","agility","strength attack","dps","hit"}},
 {key="threat", label="Tank Threat", bestFor="tank threat", sim="Pre-BiS Offensive",
  weights={stamina=1.15,strength=0.62,agility=0.56,attack=0.27,hit=0.06,crit=0.43,haste=0.29,expertise=3.07,
   defense=0.45,blockpct=0,block=0.63,dodge=0.23,parry=0.22,armor=0.05,dps=1.45}},
 {key="solo", label="Solo Levelling", bestFor="solo damage",
  order={"dps","strength attack","crit agility","hit expertise","stamina","armor"}},
})
-- Feral shares one tree for Cat and Bear. Bear Balanced is the simulator's Bear preset; the other
-- two Bear focuses are estimates. The simulator finds weapon DPS valuable in both forms, so they
-- rank it too. A bear holds no shield.
focus("DRUID", 2, {
 {key="damage", label="Cat Damage", bestFor="cat damage"},
 {key="balanced", label="Bear Balanced", bestFor="bear tanking", sim="Bear",
  weights={stamina=1.003,strength=0.486,agility=0.433,attack=0.221,hit=0.688,crit=0.363,haste=0.358,expertise=1.776,
   defense=0.876,dodge=0.107,armor=0.174,dps=3.093},options={kind="tank"}},
 {key="survival", label="Bear Survivability", bestFor="bear survivability",
  order={"armor stamina","defense dodge","agility","strength attack","dps","hit"},options={kind="tank"}},
 {key="threat", label="Bear Threat", bestFor="bear threat",
  order={"dps","strength attack","hit expertise","agility crit","stamina","armor","defense dodge"},options={kind="tank"}},
})

-- Your own weights ----------------------------------------------------------------------------
-- Saved per character as {[profile id]={[stat]=weight}}; only the stats you changed are kept.
-- NS.SetGearWeights hands the saved table over at login; NS.GearSetWeight changes one value.
NS.gearCustom = nil
NS.gearWeightMax = 999
local customised = {}
local function forget()
 customised = {}
 if NS.Gear then
  NS.Gear.alternatives = nil
  if NS.Gear.Rescan then NS.Gear.Rescan() end
 end
end
local function usable(value)
 return type(value)=="number" and value==value and value>=0 and value<=NS.gearWeightMax
end
function NS.SetGearWeights(saved)
 NS.gearCustom = type(saved)=="table" and saved or nil
 forget()
end
-- The stats the settings page lists, in its three columns, with what one point means.
NS.gearWeightRows = {
 {"dps","Weapon DPS"},{"dps2","Off-hand DPS"},{"attack","Attack power"},{"strength","Strength"},{"agility","Agility"},
 {"stamina","Stamina"},{"armor","Armour"},
 {"intellect","Intellect"},{"spirit","Spirit"},{"spell","Spell power"},{"healing","Healing power"},{"mp5","MP5"},
 {"hit","Hit (1%)"},{"crit","Crit (1%)"},
 {"haste","Haste (1%)"},{"expertise","Expertise (1%)"},{"defense","Defence"},{"dodge","Dodge (1%)"},{"parry","Parry (1%)"},
 {"block","Block value"},{"blockpct","Block chance (1%)"},
}
local editable = {}
for _, row in ipairs(NS.gearWeightRows) do editable[row[1]] = true end
-- One stat's weight in a profile. An off-hand weapon scores as a main hand unless told otherwise.
function NS.GearWeight(p, key)
 local value = p.weights[key]
 if value == nil and key == "dps2" then value = p.weights.dps end
 return value or 0
end
-- The profile with your saved weights applied, or the profile itself when you have none.
function NS.GearCustomised(p)
 local saved = p and NS.gearCustom and NS.gearCustom[p.id]
 if type(saved)~="table" then return p end
 local c = customised[p.id]
 if c then return c end
 local changed = false
 c = {}
 for key, value in pairs(p) do c[key] = value end
 c.weights = {}
 for key, value in pairs(p.weights) do c.weights[key] = value end
 for key, value in pairs(saved) do
  if editable[key] and usable(value) then c.weights[key] = value; changed = true end
 end
 if not changed then return p end
 -- Armour you weigh yourself is one of your stats, not a quiet allowance.
 if saved.armor and usable(saved.armor) then c.armorRanked = true end
 c.base, c.custom = p, true
 c.order = NS.GearOrderFromWeights(c)
 c.weightSource = "your own weights"
 customised[p.id] = c
 return c
end
-- Sets one weight on a profile (base or customised); nil, or the default value, removes yours.
-- Returns false when the value is not a number from 0 to NS.gearWeightMax.
function NS.GearSetWeight(p, key, value)
 p = p and (p.base or p)
 if not (p and p.id and editable[key]) then return false end
 if value ~= nil and not usable(value) then return false end
 if type(NS.gearCustom)~="table" then return false end
 local saved = NS.gearCustom[p.id]
 if value ~= nil and math.abs(value - NS.GearWeight(p, key)) < 1e-9 then value = nil end
 if value == nil then
  if type(saved)=="table" then
   saved[key] = nil
   if next(saved) == nil then NS.gearCustom[p.id] = nil end
  end
 else
  if type(saved)~="table" then saved = {}; NS.gearCustom[p.id] = saved end
  saved[key] = value
 end
 forget()
 return true
end
-- Drops every weight you set on one profile.
function NS.GearResetWeights(p)
 p = p and (p.base or p)
 if not (p and p.id) or type(NS.gearCustom)~="table" then return end
 NS.gearCustom[p.id] = nil
 forget()
end

-- The choices Settings offers for one spec, default first: {key=..., label=..., default=true|nil}.
-- nil when the spec has a single profile.
function NS.GearFocusChoices(class, spec)
 local entry = NS.gearFocus[class] and NS.gearFocus[class][spec]
 if not entry then return nil end
 local out = {}
 for index, item in ipairs(entry.list) do out[index] = {key=item.key, label=item.label, default=item.default or nil} end
 return out
end

-- The profile for a focus key, or the spec's default when the key is nil or not offered, with
-- your own weights applied.
function NS.GearFocusProfile(class, spec, key)
 local entry = NS.gearFocus[class] and NS.gearFocus[class][spec]
 if not entry then return NS.GearCustomised(NS.gearProfiles[class] and NS.gearProfiles[class][spec]) end
 local item = (key and entry.byKey[key]) or entry.list[1]
 return NS.GearCustomised(item.profile)
end

-- Below level 10 there is usually no talent tree to read, so each class gets one short list.
-- These are Everfrost estimates based on the class's usual stats, not guide rankings.
NS.gearStarter = {}
local function starter(class, kind, order)
 local p = build(class, 0, order, {kind=kind})
 p.starter = true
 p.weightSource = "Everfrost starter estimate"
 NS.gearStarter[class] = p
end
starter("WARRIOR","melee",{"dps","strength","agility","stamina","armor"})
starter("PALADIN","melee",{"dps","strength","stamina","intellect","armor"})
starter("HUNTER","ranged",{"dps","agility","stamina","intellect","armor"})
starter("ROGUE","melee",{"dps","agility","strength","stamina","armor"})
starter("SHAMAN","melee",{"dps","intellect","strength","stamina","spirit","armor"})
starter("MAGE","caster",{"intellect","spirit","spell","stamina","armor"})
starter("PRIEST","caster",{"intellect","spirit","spell","stamina","armor"})
starter("WARLOCK","caster",{"intellect","stamina","spirit","spell","armor"})
starter("DRUID","caster",{"intellect","spirit","stamina","spell","armor"})

-- The active profile, with your own weights applied. From level 10 it follows the scoring
-- focus in NS.Gear.focus.
function NS.GearProfile(class, spec, role, level)
 if level and level<NS.gearMinLevel then return NS.GearCustomised(NS.gearStarter[class]) end
 -- A tied/unspent/unknown tree is intentionally unscored until a tree is selected.
 if class=="HUNTER" and spec==3 and role=="ranged" then return NS.GearCustomised(NS.gearProfiles.HUNTER[2]) end
 if not (NS.gearProfiles[class] and NS.gearProfiles[class][spec]) then return nil end
 return NS.GearFocusProfile(class, spec, NS.Gear and NS.Gear.focus)
end

NS.gearStatLabels={dps="Weapon DPS",hit="Hit",expertise="Expertise",crit="Crit",spell="Spell power",healing="Healing power",
 strength="Strength",agility="Agility",intellect="Intellect",stamina="Stamina",spirit="Spirit",mp5="MP5",
 haste="Haste",attack="Attack power",armor="Armour",block="Block",defense="Defence",dodge="Dodge",parry="Parry"}
-- The stat order alone; limit keeps the first few groups for a tooltip.
function NS.GearOrderText(p, limit)
 local labels=NS.gearStatLabels
 local groups={}
 for index,group in ipairs(p.order) do
  if limit and index>limit then break end
  local parts={}; for key in group:gmatch("%S+") do parts[#parts+1]=labels[key] or key end
  groups[#groups+1]=table.concat(parts," / ")
 end
 return table.concat(groups," > ")
end
-- The stat order, named by its focus when the spec offers more than one.
function NS.GearPriorityText(p)
 return (p.focusLabel and (p.focusLabel..": ") or "")..NS.GearOrderText(p)
end
-- Where a profile's numbers come from, for settings and tooltips.
function NS.GearSourceText(p)
 return "Weights: "..(p.weightSource or "Everfrost estimate")
end
