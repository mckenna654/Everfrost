local _, NS = ...
function NS.Public(value) return not (issecretvalue and issecretvalue(value)) end
local function call(fn, ...)
 if type(fn)~="function" then return nil end
 local function pack(...) return {n=select("#",...),...} end
 local result=pack(pcall(fn,...))
 if not result[1] then return nil end
 local values={}; for i=2,result.n do values[i-1]=result[i] end
 return values
end
NS.Call=call
function NS.SelectTree(points)
 local best,amount,tied=0,0,false
 for i=1,3 do
  local n=points[i] or 0
  if n>amount then best,amount,tied=i,n,false elseif n==amount and n>0 then tied=true end
 end
 if tied then return 0,"Hybrid" end
 if amount==0 then return 0,"Unspent" end
 return best,"Auto"
end
function NS.DetectSpec(class)
 if not NS.trees[class] then return 0,"Unsupported" end
 local api=C_SpecializationInfo or {}
 local group=call(api.GetActiveSpecGroup or GetActiveTalentGroup)
 group=group and group[1] or 1
 local points,hasPoints={},false
 for i=1,3 do
  local data=call(api.GetSpecializationInfo,i,false,false,nil,nil,group)
  local n=data and data[7]
  if not (NS.Public(n) and type(n)=="number") then
   data=call(GetTalentTabInfo,i,false,false,group)
   if data then n=type(data[1])=="number" and data[5] or data[3] end
  end
  if NS.Public(n) and type(n)=="number" then points[i]=n; hasPoints=true end
 end
 if hasPoints then return NS.SelectTree(points) end
 local active=call(api.GetSpecialization or GetSpecialization)
 local i=active and active[1]
 if NS.Public(i) and type(i)=="number" and NS.trees[class][i] then return i,"Auto" end
 return 0,"Spec unavailable"
end
-- IDs localize names only; learned IDs and ranks are read from the spellbook.
NS.baseIDs={
 ["Curse of the Elements"]=1490,["Curse of Recklessness"]=704,
 ["Seal of the Crusader"]=21082,["Holy Shock"]=20473,["Seal of Light"]=20165,
 ["Raptor Strike"]=2973,["Mongoose Bite"]=1495,["Disengage"]=781,
 ["Blast Wave"]=11113,["Slam"]=1464,["Death Wish"]=12292,
 ["Hemorrhage"]=16511,["Rupture"]=1943,["Holy Fire"]=14914,
 ["Prayer of Healing"]=596,["Holy Nova"]=15237,["Amplify Curse"]=18288,
 ["Soul Link"]=19028,["Conflagrate"]=17962,["Hellfire"]=1949,
 ["Insect Swarm"]=5570,["Swiftmend"]=18562,["Stormstrike"]=17364,
 ["Seal of Righteousness"]=21084,["Seal of Command"]=20375,["Judgement"]=20271,
 ["Consecration"]=26573,["Exorcism"]=879,["Holy Light"]=635,["Flash of Light"]=19750,
 ["Righteous Fury"]=25780,["Lay on Hands"]=633,["Purify"]=1152,
 ["Hunter's Mark"]=1130,["Serpent Sting"]=1978,["Auto Shot"]=75,["Arcane Shot"]=3044,
 ["Aimed Shot"]=19434,["Multi-Shot"]=2643,["Fireball"]=133,["Frostbolt"]=116,
 ["Fire Blast"]=2136,["Pyroblast"]=11366,["Arcane Missiles"]=5143,["Arcane Blast"]=30451,
 ["Ice Lance"]=30455,["Frost Nova"]=122,["Flamestrike"]=2120,["Arcane Explosion"]=1449,["Shoot"]=5019,
 ["Battle Shout"]=6673,["Charge"]=100,["Demoralizing Shout"]=1160,["Rend"]=772,
 ["Victory Rush"]=34428,["Overpower"]=7384,["Sunder Armor"]=7386,["Heroic Strike"]=78,
 ["Cleave"]=845,["Revenge"]=6572,["Thunder Clap"]=6343,["Defensive Stance"]=71,
 ["Stealth"]=1784,["Ambush"]=8676,["Backstab"]=53,["Sinister Strike"]=1752,
 ["Slice and Dice"]=5171,["Eviscerate"]=2098,["Power Word: Shield"]=17,["Smite"]=585,
 ["Mind Blast"]=8092,["Shadow Word: Pain"]=589,["Mind Flay"]=15407,["Heal"]=2054,
 ["Lesser Heal"]=2050,["Renew"]=139,["Flash Heal"]=2061,["Cure Disease"]=528,["Dispel Magic"]=527,
 ["Corruption"]=172,["Immolate"]=348,["Drain Life"]=689,["Shadow Bolt"]=686,
 ["Drain Soul"]=1120,["Rain of Fire"]=5740,["Searing Pain"]=5676,["Shadowburn"]=17877,
 ["Moonfire"]=8921,["Wrath"]=5176,["Cat Form"]=768,["Bear Form"]=5487,["Claw"]=1082,
 ["Shred"]=5221,["Rip"]=1079,["Enrage"]=5229,["Swipe"]=779,["Maul"]=6807,
 ["Rejuvenation"]=774,["Healing Touch"]=5185,["Regrowth"]=8936,
 ["Searing Totem"]=3599,["Lightning Bolt"]=403,["Flame Shock"]=8050,["Earth Shock"]=8042,
 ["Lightning Shield"]=324,["Healing Wave"]=331,["Lesser Healing Wave"]=8004,["Healing Stream Totem"]=5394,
}
function NS.SpellNames(class)
 local names={}
 for _,p in pairs(NS.profiles[class] or {}) do
  for _,list in ipairs({p.steps,p.healing or {},p.bear or {},p.caster or {},p.melee or {}}) do
   for _,entry in ipairs(list) do
    names[entry.name]=entry.name
    local id=NS.baseIDs[entry.name]
    local info=id and call(C_Spell and C_Spell.GetSpellInfo,id); info=info and info[1]
    if info and NS.Public(info.name) and type(info.name)=="string" then names[info.name]=entry.name end
   end
  end
 end
 return names
end
function NS.ScanSpells(class)
 if InCombatLockdown() then return nil,"Waiting for combat to end" end
 local api=C_SpellBook or {}
 if not (api.GetNumSpellBookSkillLines and api.GetSpellBookSkillLineInfo and api.GetSpellBookItemInfo) then return nil,"Spellbook API unavailable" end
 local names,known=NS.SpellNames(class),{}
 local count=call(api.GetNumSpellBookSkillLines)
 if not count or type(count[1])~="number" then return nil,"Spellbook not ready" end
 local bank=Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
 if not bank then return nil,"Spellbook bank unavailable" end
 for tab=1,count[1] do
  local line=call(api.GetSpellBookSkillLineInfo,tab); line=line and line[1]
  if line and line.itemIndexOffset and line.numSpellBookItems then
   for slot=line.itemIndexOffset+1,line.itemIndexOffset+line.numSpellBookItems do
    local item=call(api.GetSpellBookItemInfo,slot,bank); item=item and item[1]
    if item and NS.Public(item.spellID) and NS.Public(item.name) and item.spellID
     and NS.Public(item.isPassive) and NS.Public(item.isOffSpec) and not item.isPassive and not item.isOffSpec then
     local key=names[item.name]
     local learned=call(api.IsSpellKnown or IsPlayerSpell,item.spellID,bank); learned=learned and learned[1]
     if key and NS.Public(learned) and learned then
      local required=call(api.GetSpellBookItemLevelLearned,slot,bank); required=required and required[1]
      if not NS.Public(required) or type(required)~="number" then required=0 end
      local rank=NS.Public(item.subName) and type(item.subName)=="string" and tonumber(item.subName:match("(%d+)")) or 0
      local old=known[key]
      if not old or required>old.level or (required==old.level and rank>old.rank) then
       known[key]={id=item.spellID,name=item.name,icon=item.iconID,level=required,rank=rank}
      end
     end
    end
   end
  end
 end
 return known
end

