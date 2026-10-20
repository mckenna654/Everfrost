local _, NS = ...
NS.gearMinLevel=10
NS.gearLevelNote="Stat priorities and upgrade hints start at level 10."
-- Stat orders reviewed against all 27 Icy Veins Forever guides, 2026-10-20.
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
profile("PALADIN",3,{"dps","hit expertise","crit","spell","strength","intellect","agility","stamina","spirit"},{kind="melee",school="holy"})
for spec=1,2 do
 profile("HUNTER",spec,{"dps","hit","agility","crit","intellect","spirit","stamina"},{kind="ranged"})
end
profile("HUNTER",3,{"dps","hit","agility","crit","strength","intellect","spirit","stamina"},{kind="melee"})
profile("MAGE",1,{"hit","spirit","intellect","spell","crit","stamina","mp5"},{kind="caster",school="arcane"})
profile("MAGE",2,{"hit","spell","crit","spirit","intellect","stamina","mp5"},{kind="caster",school="fire"})
profile("MAGE",3,{"hit","spell","crit","spirit","intellect","stamina","agility","strength"},{kind="caster",school="frost"})
for spec=1,2 do
 profile("WARRIOR",spec,{"dps","hit","crit","strength","agility","stamina"},{kind="melee"})
end
profile("WARRIOR",3,{"dps","hit","strength","agility","armor","stamina","crit"},{kind="tank",shield=true})
for spec=1,2 do
 profile("ROGUE",spec,{"dps","hit expertise","agility","crit","strength","stamina"},{kind="melee"})
end
profile("ROGUE",3,{"dps","hit expertise","agility","attack","crit","strength"},{kind="melee"})
for spec=1,2 do
 profile("PRIEST",spec,{"healing","mp5","spirit","intellect","crit"},{kind="healer"})
end
profile("PRIEST",3,{"spell","crit","hit","intellect","stamina","mp5"},{kind="caster",school="shadow"})
profile("WARLOCK",1,{"spell","hit","crit","intellect","spirit","haste","stamina"},{kind="caster",school="shadow"})
profile("WARLOCK",2,{"spell","hit","intellect","crit","spirit","haste","stamina"},{kind="caster",school="shadow"})
profile("WARLOCK",3,{"spell","hit","haste","crit","spirit","intellect","stamina"},{kind="caster",schools={fire=0.5,shadow=0.5}})
profile("DRUID",1,{"intellect","spell","spirit","mp5","crit","haste"},{kind="caster",schools={nature=0.5,arcane=0.5}})
profile("DRUID",2,{"dps","hit expertise","crit","strength","agility","stamina","spirit","intellect","spell"},{kind="melee"})
profile("DRUID",3,{"intellect","healing","spirit","mp5","crit","haste"},{kind="healer"})
profile("SHAMAN",1,{"spell","crit","hit","intellect","mp5","spirit","stamina"},{kind="caster",school="nature"})
profile("SHAMAN",2,{"dps","hit expertise","crit","strength","intellect","agility","spirit","spell","stamina"},{kind="melee"})
profile("SHAMAN",3,{"healing","crit","intellect","spirit","mp5","stamina"},{kind="healer"})

function NS.GearProfile(class, spec, role)
 -- A tied/unspent/unknown tree is intentionally unscored until a tree is selected.
 local p = NS.gearProfiles[class] and NS.gearProfiles[class][spec]
 if class=="HUNTER" and spec==3 and role=="ranged" then return NS.gearProfiles.HUNTER[2] end
 return p
end

function NS.GearPriorityText(p)
 local labels={dps="Weapon DPS",hit="Hit",expertise="Expertise",crit="Crit",spell="Spell power",healing="Healing power",
  strength="Strength",agility="Agility",intellect="Intellect",stamina="Stamina",spirit="Spirit",mp5="MP5",
  haste="Haste",attack="Attack power",armor="Armor",block="Block",defense="Defense"}
 local groups={}
 for _,group in ipairs(p.order) do
  local parts={}; for key in group:gmatch("%S+") do parts[#parts+1]=labels[key] or key end
  groups[#groups+1]=table.concat(parts," / ")
 end
 return table.concat(groups," > ")
end
