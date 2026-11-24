local _, NS = ...
NS.gearMinLevel=10
NS.gearLevelNote="Below level 10, gear hints use a simple starter priority for your class. Talent-based priorities start at level 10."
-- Stat orders follow the Stats section of each Icy Veins Forever levelling guide, reviewed
-- 2026-11-11 (after the guides' level 60 update). Hit, and for melee Expertise, keep the place
-- the stat pages give them where a levelling guide leaves them out as rare on early gear.
-- These ordinal weights are Everfrost estimates, not published simulation weights.
NS.gearProfiles = {}
local function build(class, spec, order, options)
 local p = {}
 for key, value in pairs(options or {}) do p[key] = value end
 p.order = order; p.weights = {}
 for rank, group in ipairs(order) do
  for key in group:gmatch("%S+") do p.weights[key] = #order - rank + 1 end
 end
 p.source = NS.profiles[class][spec].source
 p.class, p.spec = class, spec
 return p
end
local function profile(class, spec, order, options)
 NS.gearProfiles[class] = NS.gearProfiles[class] or {}
 NS.gearProfiles[class][spec] = build(class, spec, order, options)
end
profile("PALADIN",1,{"healing","intellect","mp5","crit","haste","spirit"},{kind="healer"})
profile("PALADIN",2,{"stamina","spell","strength","block","hit","defense","armor","intellect","agility"},{kind="tank",shield=true,school="holy"})
profile("PALADIN",3,{"dps","hit expertise","spell","intellect","crit","strength","agility","stamina","spirit"},{kind="melee",school="holy"})
for spec=1,2 do
 profile("HUNTER",spec,{"dps","hit","agility","crit","intellect","spirit","stamina"},{kind="ranged"})
end
profile("HUNTER",3,{"dps","hit","agility","crit","intellect","spirit","stamina"},{kind="melee"})
profile("MAGE",1,{"spell","intellect","spirit","crit","hit","stamina","mp5"},{kind="caster",school="arcane"})
profile("MAGE",2,{"spell","crit","intellect","spirit","hit","stamina","mp5"},{kind="caster",school="fire"})
profile("MAGE",3,{"hit","spell","crit","spirit","intellect","stamina"},{kind="caster",school="frost"})
profile("WARRIOR",1,{"dps","hit expertise","agility crit","strength attack","stamina"},{kind="melee"})
profile("WARRIOR",2,{"dps","hit expertise","strength attack","agility crit","stamina"},{kind="melee"})
profile("WARRIOR",3,{"dps","hit expertise","strength attack","agility crit","armor stamina","defense block"},{kind="tank",shield=true})
for spec=1,2 do
 profile("ROGUE",spec,{"dps","hit expertise","agility","crit","strength","stamina"},{kind="melee"})
end
profile("ROGUE",3,{"dps","hit expertise","agility","attack","crit","strength"},{kind="melee"})
profile("PRIEST",1,{"healing","mp5","intellect","spirit","crit"},{kind="healer"})
profile("PRIEST",2,{"healing","mp5","spirit","intellect","crit"},{kind="healer"})
profile("PRIEST",3,{"spell","crit","hit","intellect","spirit","stamina","mp5"},{kind="caster",school="shadow"})
profile("WARLOCK",1,{"spell","crit","spirit","intellect stamina","hit","haste"},{kind="caster",school="shadow"})
-- Demonology's Searing Pain is Fire and its other spells Shadow; the guide asks for general spell damage.
profile("WARLOCK",2,{"spell","crit","hit","intellect stamina","spirit","haste"},{kind="caster",schools={fire=0.5,shadow=0.5}})
-- Destruction's main attacks are Fire; Shadow Bolt and Shadowburn still use Shadow.
profile("WARLOCK",3,{"spell","hit","crit","intellect stamina","spirit","haste"},{kind="caster",schools={fire=1,shadow=0.5}})
profile("DRUID",1,{"intellect","spell","crit","haste","spirit","mp5"},{kind="caster",schools={nature=0.5,arcane=0.5}})
profile("DRUID",2,{"dps","hit expertise","crit","agility","strength attack","stamina"},{kind="melee"})
profile("DRUID",3,{"healing","intellect","crit","haste","spirit","mp5"},{kind="healer"})
profile("SHAMAN",1,{"spell","crit","hit","intellect","mp5","spirit","stamina"},{kind="caster",school="nature"})
profile("SHAMAN",2,{"dps","hit expertise","intellect","strength","spirit","agility","crit","spell","stamina"},{kind="melee"})
profile("SHAMAN",3,{"healing","crit","intellect","spirit","mp5","stamina"},{kind="healer"})
-- What each spec's default profile is best for, in the words quest tooltips use.
for class, specs in pairs(NS.gearProfiles) do
 for spec, p in pairs(specs) do
  p.specName = NS.trees[class][spec]
  p.bestFor = p.kind=="healer" and "healing" or p.kind=="tank" and "tanking" or (p.specName.." damage")
 end
end

-- Scoring focus: a spec can offer other stat orders, chosen in Settings and read from
-- NS.Gear.focus (a key below, or nil for the default). The default is always the guide order
-- above. The others are Everfrost estimates that reorder the same stats for one goal; no guide
-- publishes numerical weights for them. Keys are shared where the idea is the same, so one saved
-- choice carries across tank specs; an unknown key falls back to the default.
NS.gearFocus = {}
local function focus(class, spec, list)
 local base = NS.gearProfiles[class][spec]
 local entry = {list={}, byKey={}}
 for index, choice in ipairs(list) do
  local p = base
  if choice.order then
   local options = {}
   for _, key in ipairs({"kind","shield","school","schools"}) do options[key] = base[key] end
   for key, value in pairs(choice.options or {}) do options[key] = value end
   p = build(class, spec, choice.order, options)
   p.specName = base.specName
  end
  p.focusKey, p.focusLabel, p.bestFor = choice.key, choice.label, choice.bestFor
  local item = {key=choice.key, label=choice.label, profile=p, default=index==1}
  entry.list[index] = item; entry.byKey[choice.key] = item
 end
 NS.gearFocus[class] = NS.gearFocus[class] or {}
 NS.gearFocus[class][spec] = entry
end
-- Protection Paladin. Holy spell power drives Seal, Consecration and Holy Shield threat.
focus("PALADIN", 2, {
 {key="balanced", label="Balanced Tank", bestFor="tanking"},
 {key="survival", label="Tank Survivability", bestFor="tank survivability",
  order={"stamina","armor defense","block dodge parry","agility","strength","spell","hit","intellect"}},
 {key="threat", label="Tank Threat", bestFor="tank threat",
  order={"spell","dps","strength attack","hit","stamina","crit","block","defense armor","intellect"}},
 {key="solo", label="Solo Levelling", bestFor="solo damage",
  order={"dps","spell","strength attack","stamina","crit hit","intellect mp5","armor","block"}},
})
-- Protection Warrior.
focus("WARRIOR", 3, {
 {key="balanced", label="Balanced Tank", bestFor="tanking"},
 {key="survival", label="Tank Survivability", bestFor="tank survivability",
  order={"stamina armor","defense","block dodge parry","agility","strength attack","dps","hit"}},
 {key="threat", label="Tank Threat", bestFor="tank threat",
  order={"dps","hit expertise","strength attack","crit agility","stamina","armor","defense block"}},
 {key="solo", label="Solo Levelling", bestFor="solo damage",
  order={"dps","strength attack","crit agility","hit expertise","stamina","armor"}},
})
-- Feral shares one tree for Cat and Bear. Bear form ignores weapon damage and holds no shield.
focus("DRUID", 2, {
 {key="damage", label="Cat Damage", bestFor="cat damage"},
 {key="balanced", label="Bear Balanced", bestFor="bear tanking",
  order={"armor stamina","agility","strength attack","defense dodge","hit expertise","crit"},options={kind="tank"}},
 {key="survival", label="Bear Survivability", bestFor="bear survivability",
  order={"armor stamina","defense dodge","agility","strength attack","hit"},options={kind="tank"}},
 {key="threat", label="Bear Threat", bestFor="bear threat",
  order={"strength attack","hit expertise","agility crit","stamina","armor","defense dodge"},options={kind="tank"}},
})

-- The choices Settings offers for one spec, default first: {key=..., label=..., default=true|nil}.
-- nil when the spec has a single profile.
function NS.GearFocusChoices(class, spec)
 local entry = NS.gearFocus[class] and NS.gearFocus[class][spec]
 if not entry then return nil end
 local out = {}
 for index, item in ipairs(entry.list) do out[index] = {key=item.key, label=item.label, default=item.default or nil} end
 return out
end

-- The profile for a focus key, or the spec's default when the key is nil or not offered.
function NS.GearFocusProfile(class, spec, key)
 local entry = NS.gearFocus[class] and NS.gearFocus[class][spec]
 if not entry then return NS.gearProfiles[class] and NS.gearProfiles[class][spec] end
 local item = (key and entry.byKey[key]) or entry.list[1]
 return item.profile
end

-- Below level 10 there is usually no talent tree to read, so each class gets one short list.
-- These are Everfrost estimates based on the class's usual stats, not guide rankings.
NS.gearStarter = {}
local function starter(class, kind, order)
 local p = {kind=kind,order=order,weights={},starter=true,source=NS.profiles[class][0].source,class=class}
 for rank, key in ipairs(order) do p.weights[key] = #order - rank + 1 end
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

-- The active profile. From level 10 it follows the scoring focus in NS.Gear.focus.
function NS.GearProfile(class, spec, role, level)
 if level and level<NS.gearMinLevel then return NS.gearStarter[class] end
 -- A tied/unspent/unknown tree is intentionally unscored until a tree is selected.
 if class=="HUNTER" and spec==3 and role=="ranged" then return NS.gearProfiles.HUNTER[2] end
 if not (NS.gearProfiles[class] and NS.gearProfiles[class][spec]) then return nil end
 return NS.GearFocusProfile(class, spec, NS.Gear and NS.Gear.focus)
end

NS.gearStatLabels={dps="Weapon DPS",hit="Hit",expertise="Expertise",crit="Crit",spell="Spell power",healing="Healing power",
 strength="Strength",agility="Agility",intellect="Intellect",stamina="Stamina",spirit="Spirit",mp5="MP5",
 haste="Haste",attack="Attack power",armor="Armour",block="Block",defense="Defence",dodge="Dodge",parry="Parry"}
-- The stat order alone.
function NS.GearOrderText(p)
 local labels=NS.gearStatLabels
 local groups={}
 for _,group in ipairs(p.order) do
  local parts={}; for key in group:gmatch("%S+") do parts[#parts+1]=labels[key] or key end
  groups[#groups+1]=table.concat(parts," / ")
 end
 return table.concat(groups," > ")
end
-- The stat order, named by its focus when the spec offers more than one.
function NS.GearPriorityText(p)
 return (p.focusLabel and (p.focusLabel..": ") or "")..NS.GearOrderText(p)
end
