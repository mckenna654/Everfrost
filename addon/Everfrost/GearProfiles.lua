local _, NS = ...
NS.gearMinLevel=10
NS.gearLevelNote="Below level 10, gear hints use a simple starter priority for your class. Talent-based priorities start at level 10."
-- Stat orders follow the Stats section of each Icy Veins Forever levelling guide, reviewed
-- 2026-11-11 (after the guides' level 60 update). Hit, and for melee Expertise, keep the place
-- the stat pages give them where a levelling guide leaves them out as rare on early gear.
-- These ordinal weights are Everfrost estimates, not published simulation weights.
NS.gearProfiles = {}
local function profile(class, spec, order, options)
 local p = options or {}
 p.order = order; p.weights = {}
 for rank, group in ipairs(order) do
  for key in group:gmatch("%S+") do p.weights[key] = #order - rank + 1 end
 end
 p.source = NS.profiles[class][spec].source
 NS.gearProfiles[class] = NS.gearProfiles[class] or {}
 NS.gearProfiles[class][spec] = p
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

-- Below level 10 there is usually no talent tree to read, so each class gets one short list.
-- These are Everfrost estimates based on the class's usual stats, not guide rankings.
NS.gearStarter = {}
local function starter(class, kind, order)
 local p = {kind=kind,order=order,weights={},starter=true,source=NS.profiles[class][0].source}
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

function NS.GearProfile(class, spec, role, level)
 if level and level<NS.gearMinLevel then return NS.gearStarter[class] end
 -- A tied/unspent/unknown tree is intentionally unscored until a tree is selected.
 local p = NS.gearProfiles[class] and NS.gearProfiles[class][spec]
 if class=="HUNTER" and spec==3 and role=="ranged" then return NS.gearProfiles.HUNTER[2] end
 return p
end

NS.gearStatLabels={dps="Weapon DPS",hit="Hit",expertise="Expertise",crit="Crit",spell="Spell power",healing="Healing power",
 strength="Strength",agility="Agility",intellect="Intellect",stamina="Stamina",spirit="Spirit",mp5="MP5",
 haste="Haste",attack="Attack power",armor="Armour",block="Block",defense="Defence"}
function NS.GearPriorityText(p)
 local labels=NS.gearStatLabels
 local groups={}
 for _,group in ipairs(p.order) do
  local parts={}; for key in group:gmatch("%S+") do parts[#parts+1]=labels[key] or key end
  groups[#groups+1]=table.concat(parts," / ")
 end
 return table.concat(groups," > ")
end
