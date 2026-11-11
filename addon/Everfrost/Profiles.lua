local _, NS = ...
NS.maxLevel = 60
NS.profiles = {}
NS.trees = {
 PALADIN={"Holy","Protection","Retribution"}, HUNTER={"Beast Mastery","Marksmanship","Survival"},
 MAGE={"Arcane","Fire","Frost"}, WARRIOR={"Arms","Fury","Protection"},
 ROGUE={"Assassination","Combat","Subtlety"}, PRIEST={"Discipline","Holy","Shadow"},
 WARLOCK={"Affliction","Demonology","Destruction"}, DRUID={"Balance","Feral","Restoration"},
 SHAMAN={"Elemental","Enhancement","Restoration"},
}
-- Concise adaptations of Icy Veins Forever guides. Levels 1-30 reviewed 2026-10-15; the
-- level 31-60 additions (end of this file) come from the levelling guides as of 2026-11-11.
-- Shown to players, so they can judge how current the advice is. Update with each review.
NS.guideReviewed = "Guides last checked 11 November 2026."
-- Entries are conditional reference steps, never combat-evaluated instructions.
local function S(name, hint, options)
 local t = options or {}; t.name = name; t.hint = hint; return t
end
local function P(class, index, slug, steps, note, extras)
 NS.profiles[class] = NS.profiles[class] or {}
 local p = extras or {}; p.steps=steps; p.note=note
 p.source="https://www.icy-veins.com/wow-forever/" .. slug .. "-pve-guide"
 NS.profiles[class][index]=p
end
local function base(class, steps, note)
 NS.profiles[class][0]={steps=steps,note=note,source=NS.profiles[class][1].source}
end
local paladinDamage={
 S("Seal of the Crusader","Long fight opener: Judge this, then switch to your damage seal."),
 S("Seal of Command","Slow weapon without on-hit effects: maintain this seal.",{min=20}),
 S("Seal of Righteousness","Choose for fast weapons, spell power or weapon on-hit effects."),
 S("Holy Strike","Use when ready if mana allows.",{min=6}),
 S("Judgement","Use when ready; with Command, Hammer of Justice boosts its damage. Check your seal afterward."),
 S("Holy Shock","Shockadin: use when ready if healing is covered."),
 S("Consecration","Multiple enemies; watch the mana cost.",{mode="aoe",min=20}),
 S("Exorcism","Use against Undead or Demons only."),
}
P("PALADIN",1,"holy-paladin-healer",paladinDamage,"Keep an aura and blessing active.", {healing={
 S("Flash of Light","Efficient routine healing."), S("Holy Light","Larger heal; allow for cast time and mana."),
 S("Holy Shock","Instant healing when someone is in danger."),
 S("Seal of Light","Optional group healing through its Judgement; coordinate seals."),
 S("Lay on Hands","Emergency heal; consumes your remaining mana."), S("Purify","Remove a harmful poison or disease when needed."),
}})
P("PALADIN",2,"protection-paladin-tank",{
 S("Righteous Fury","Maintain for tanking threat."),S("Seal of Fury","Maintain while tanking; Judgement taunts."),
 S("Seal of Righteousness","Damage seal before Fury is learned.",{unless="Seal of Fury"}),
 S("Consecration","Threat on groups; use only as mana permits.",{min=20}),
 S("Judgement","Recover lost aggro with Fury; otherwise damage."),S("Holy Strike","Use when ready.",{min=6}),
 S("Exorcism","Undead / Demon targets only."),
},"Use a shield; manage mana and lost aggro.")
P("PALADIN",3,"retribution-paladin-melee-dps",paladinDamage,"Keep auto-attacking. Choose one seal, not both.")
base("PALADIN",paladinDamage,"Keep a seal, blessing and aura active when learned.")
local hunter={S("Hunter's Mark","Apply before pulling."),S("Serpent Sting","Apply after your pet engages."),
 S("Aimed Shot","Use when ready.",{mode="single"}),S("Multi-Shot","Multiple targets; avoid breaking crowd control.",{mode="aoe"}),
 S("Auto Shot","Keep ranged attacks going; let mana recover."),S("Disengage","Reduce threat if you pull aggro from your pet."),S("Arcane Shot","Spend surplus mana; avoid unnecessary drinking.")}
for i,slug in ipairs({"beast-mastery","marksmanship","survival"}) do
 P("HUNTER",i,slug.."-hunter-"..(i==3 and "melee" or "ranged").."-dps",hunter,
 "Pet attacks first when available. Maintain Aspect of the Hawk.")
end
base("HUNTER",hunter,"Keep distance; send your pet first once you can tame one.")
local function copy(list)
 local out={}; for _,entry in ipairs(list) do
  local item={}; for k,v in pairs(entry) do item[k]=v end; out[#out+1]=item
 end; return out
end
NS.profiles.HUNTER[1].steps=copy(hunter)
table.insert(NS.profiles.HUNTER[1].steps,3,S("Summon Hawk","Maintain two hawks; prioritise their mana cost."))
NS.profiles.HUNTER[1].steps[8].hint="Only at full mana with both hawks lasting over six seconds."
NS.profiles.HUNTER[3].melee={
 S("Hunter's Mark","Apply before pulling."),S("Serpent Sting","Send your pet first, then apply this."),
 S("Raptor Strike","In melee, use when ready."),S("Mongoose Bite","Use when available."),
 S("Strider Kick","Use when ready with your melee talent build."),
 S("Disengage","Reduce threat if you pull the enemy off your pet."),
}
local mageAOE={S("Flamestrike","Open on grouped enemies held by a tank.",{mode="aoe"}),
 S("Blast Wave","Group damage and slowing; use when learned.",{mode="aoe"}),
 S("Arcane Explosion","Nearby enemies; watch your threat.",{mode="aoe"})}
local function mageSteps(main, aoe)
 local t={}; for _,v in ipairs(main) do t[#t+1]=v end
 for _,v in ipairs(aoe or mageAOE) do t[#t+1]=v end
 t[#t+1]=S("Shoot","Wand to conserve mana; requires a wand.",{mode="single"}); return t
end
P("MAGE",1,"arcane-mage-ranged-dps",mageSteps({
 S("Frostbolt","Pull from range to slow; early filler before Arcane Blast.",{mode="single"}),
 S("Arcane Blast","Main filler in short bursts; avoid costly repeated casts.",{min=20,mode="single"}),
 S("Arcane Missiles","Early filler; once talented, use whenever Missile Barrage procs.",{mode="single"}),
 S("Fire Blast","Clear Blast stacks after a short burst without Missile Barrage.",{mode="single",requires="Arcane Blast"}),
 S("Fireball","Early filler before Frostbolt or Missiles is trained.",{mode="single",unless="Frostbolt"}),
},{
 S("Frost Nova","Root gathered enemies, then create distance.",{mode="aoe"}),
 S("Flamestrike","Cast on the gathered pack while you have room.",{mode="aoe"}),
 S("Arcane Explosion","Main damage on 3+ enemies; repeat on tanked packs or while kiting.",{mode="aoe"}),
 S("Cone of Cold","Slow the pack when you need distance.",{mode="aoe"}),
 S("Blizzard","Ranged group damage; can benefit from Arcane Blast charges.",{mode="aoe"}),
}),"Keep Intellect and an armour buff active.")
P("MAGE",2,"fire-mage-ranged-dps",mageSteps({
 S("Pyroblast","Open from range when learned.",{mode="single",min=20}),
 S("Fireball","Main filler; also your opener before Pyroblast.",{mode="single"}),
 S("Fire Blast","Finish a target or maintain Wake of Fire.",{mode="single"}),
}),"Maintain Intellect and armour. Solo AoE: Nova, Flamestrike, then kite with Cone of Cold / Explosion.")
P("MAGE",3,"frost-mage-ranged-dps",mageSteps({
 S("Frostbolt","Main filler; slow enemies from range.",{mode="single"}),
 S("Fireball","Early filler until Frostbolt is trained.",{unless="Frostbolt",mode="single"}),
 S("Ice Lance","Frostbite: finish Frostbolt first. Fingers of Frost: interrupt the next cast for Lance.",{mode="single"}),
 S("Fire Blast","Finish a low-health enemy that is not frozen.",{mode="single"}),
 S("Frost Nova","Root nearby enemies to create distance.",{mode="single"}),
},{
 S("Cone of Cold","3+ targets: fish for freeze procs. 5+: use when ready.",{mode="aoe"}),
 S("Ice Lance","3-4 targets: spend Fingers of Frost, then hit frozen targets until thawed.",{mode="aoe"}),
 S("Frost Nova","3-4 targets: create freezes; in groups reserve for emergencies.",{mode="aoe"}),
 S("Blizzard","5+ targets: channel between Cone of Cold casts when safe.",{mode="aoe"}),
 S("Arcane Explosion","5+ targets: use if aggro prevents safe Blizzard channels.",{mode="aoe"}),
}),"Keep distance and react to freezes; conditions are checked by you.")
base("MAGE",mageSteps({S("Fireball","Early damage filler.",{mode="single"}),S("Frostbolt","Slow enemies from range.",{mode="single"})}),"Maintain Intellect and an armour buff.")
local warrior={S("Battle Shout","Maintain before or early in a fight."),S("Charge","Open from range, outside combat."),
 S("Demoralizing Shout","Reduce incoming melee damage."),S("Rend","Apply early if the target will survive the bleed."),
 S("Victory Rush","Use after an eligible kill while the proc lasts.",{min=20}),
 S("Overpower","Use when a dodge or talent proc enables it."),S("Sunder Armor","One or two early stacks on durable targets."),
 S("Heroic Strike","Only spend excess rage; preserve rage for the next pull.",{unless="Rend"}),
 S("Cleave","Extra enemies and surplus rage only.",{mode="aoe"})}
P("WARRIOR",1,"arms-warrior-melee-dps",warrior,"Use Bloodrage between pulls when safe. Save rage on dying targets.")
local furySteps={}; for _,s in ipairs(warrior) do furySteps[#furySteps+1]=s end
furySteps[4],furySteps[5],furySteps[6]=warrior[5],warrior[4],warrior[6]
P("WARRIOR",2,"fury-warrior-melee-dps",furySteps,"Use Bloodrage between pulls when safe; avoid unnecessary Heroic Strikes.")
P("WARRIOR",3,"protection-warrior-tank",{
 S("Battle Shout","Maintain this buff."),S("Defensive Stance","Use for tanking once learned."),
 S("Charge","Pull outside combat in Battle Stance, then switch to Defensive Stance."),
 S("Revenge","Use after blocking, dodging or parrying."),
 S("Rend","Apply early on a target that will survive the bleed."),
 S("Shield Block","Maintain while tanking with a shield; enables Revenge."),
 S("Demoralizing Shout","Reduce incoming melee damage."),S("Victory Rush","Use after an eligible kill.",{min=20}),S("Sunder Armor","Build threat; stack on bosses."),
 S("Thunder Clap","Group damage and threat.",{mode="aoe"}),S("Cleave","Multiple enemies with spare rage.",{mode="aoe"}),
 S("Heroic Strike","Early filler only with spare rage.",{unless="Sunder Armor"}),
},"Use a shield. Taunt lost enemies; spread threat between targets.")
base("WARRIOR",warrior,"Keep auto-attacking to build rage; use Bloodrage between pulls when safe.")
NS.profiles.WARRIOR[1].steps=copy(warrior)
table.insert(NS.profiles.WARRIOR[1].steps,8,S("Slam","Right after a white swing when rage allows; with Improved Slam (35) at any time.",{min=20}))
table.insert(NS.profiles.WARRIOR[1].steps,9,S("Spearing Strike","Giants/Dragons: use when ready; otherwise spend excess rage."))
table.insert(NS.profiles.WARRIOR[2].steps,3,S("Death Wish","Pool rage first; damage cooldown increases damage taken."))
local rogue={S("Stealth","Prepare an opener outside combat."),S("Ambush","Stealth opener with a dagger from behind."),
 S("Backstab","Build points with a dagger from behind."),S("Sinister Strike","Build points when Backstab is unsuitable."),
 S("Slice and Dice","At five points, maintain on durable targets."),S("Eviscerate","Damage finisher; aim for five combo points.")}
for i,slug in ipairs({"assassination","combat","subtlety"}) do
 P("ROGUE",i,slug.."-rogue-melee-dps",rogue,"Apply Instant Poison to both weapons. Avoid capping energy; finishers spend combo points.")
end
base("ROGUE",rogue,"Build combo points, then finish. Positioning matters.")
NS.profiles.ROGUE[1].steps=copy(rogue)
NS.profiles.ROGUE[1].steps[3].unless="Mutilate"
NS.profiles.ROGUE[1].steps[4].unless="Mutilate"
table.insert(NS.profiles.ROGUE[1].steps,3,S("Mutilate","Preferred combo-point builder when learned."))
NS.profiles.ROGUE[2].steps=copy(rogue)
table.insert(NS.profiles.ROGUE[2].steps,3,S("Garrote","Alternative stealth opener without a dagger."))
table.insert(NS.profiles.ROGUE[2].steps,4,S("Blade Flurry","Use early for attack speed and nearby cleave; avoid crowd control."))
table.insert(NS.profiles.ROGUE[2].steps,5,S("Riposte","Use whenever a parry makes it available."))
NS.profiles.ROGUE[3].steps=copy(rogue)
NS.profiles.ROGUE[3].steps[3].unless="Hemorrhage"
NS.profiles.ROGUE[3].steps[4].unless="Hemorrhage"
table.insert(NS.profiles.ROGUE[3].steps,3,S("Hemorrhage","Preferred combo-point builder once talented."))
table.insert(NS.profiles.ROGUE[3].steps,6,S("Rupture","At 30 with the bleed build: finisher on long-lived targets.",{min=30}))
NS.profiles.ROGUE[3].steps[7].hint="Use on durable targets; at 30 prefer Rupture with the bleed build."
local priestDamage={S("Power Word: Shield","Before pulling; protect yourself or the tank."),
 S("Smite","Pull from range."),S("Mind Blast","Follow the opener."),S("Shadow Word: Pain","Apply if the enemy will survive its damage."),
 S("Shoot","Wand to finish and conserve mana.")}
local priestHeal={S("Power Word: Shield","Buy time to heal."),S("Heal","Use for moderate damage."),
 S("Lesser Heal","Use until Heal is trained.",{unless="Heal"}),S("Renew","Light damage or healing while moving."),
 S("Flash Heal","Urgent healing; expensive."),S("Prayer of Healing","Heal a heavily injured party; allow for its cast and mana cost."),
 S("Cure Disease","Remove relevant disease effects."),S("Dispel Magic","Remove a harmful magic effect when needed.")}
P("PRIEST",1,"discipline-priest-healer",priestDamage,"Keep Fortitude and Inner Fire active.",{healing=priestHeal})
P("PRIEST",2,"holy-priest-healer",priestDamage,"Conserve mana; healing takes priority in a party.",{healing=priestHeal})
local shadow=copy(priestDamage)
shadow[2].unless="Mind Flay"
shadow[3].hint="Pull with this once Mind Flay is learned."
table.insert(shadow,4,S("Devouring Plague","Use on strong enemies if mana permits; skip to conserve mana."))
table.insert(shadow,6,S("Mind Flay","Channel when mana allows; wand to finish."))
P("PRIEST",3,"shadow-priest-ranged-dps",shadow,"Keep Fortitude and Inner Fire active; conserve mana.")
base("PRIEST",priestDamage,"Shield, cast, then wand when available.")
NS.profiles.PRIEST[1].steps=copy(priestDamage)
table.insert(NS.profiles.PRIEST[1].steps,2,S("Holy Fire","Open from range, or on a priority target with Power in Light."))
NS.profiles.PRIEST[2].steps=copy(priestDamage)
table.insert(NS.profiles.PRIEST[2].steps,5,S("Holy Nova","AoE damage while farming; expensive for group healing.",{mode="aoe"}))
NS.profiles.PRIEST[2].healing=copy(priestHeal)
table.insert(NS.profiles.PRIEST[2].healing,7,S("Holy Nova","Use on a Searing Light proc only when no one needs urgent healing."))
local dots={S("Bane of Agony","Long-lived enemies; let the effect run."),S("Corruption","Maintain on targets that will live long enough."),
 S("Immolate","Pre-cast when safe; for contested tags, apply after Corruption."),S("Drain Life","Use when you need health."),
 S("Shadow Bolt","Early filler; use Nightfall procs if talented."),S("Shoot","Wand when existing damage can finish the enemy."),
 S("Drain Soul","Finish with this when you need Soul Shards."),S("Rain of Fire","Grouped enemies; watch threat and mana.",{mode="aoe"})}
P("WARLOCK",1,"affliction-warlock-ranged-dps",dots,"Send your demon first. Avoid refreshing damage effects early.")
P("WARLOCK",2,"demonology-warlock-ranged-dps",dots,"Let your demon tank; stop spending mana when damage will finish.")
P("WARLOCK",3,"destruction-warlock-ranged-dps",{
 S("Shadow Bolt","Pre-cast before Immolate; then use as direct-damage filler."),S("Immolate","Apply after the opening Shadow Bolt."),S("Searing Pain","Faster cast; generates high threat."),
 S("Shadowburn","Finish to recover the shard; at the shard cap, use when ready."),S("Shoot","Wand to save mana near the end."),
 S("Drain Soul","Finish with this when you need shards."),S("Rain of Fire","Grouped enemies; let the tank establish threat.",{mode="aoe"}),
},"Send your demon first; save mana on nearly defeated targets.")
base("WARLOCK",dots,"Send your demon first when available.")
NS.profiles.WARLOCK[1].steps=copy(dots)
table.insert(NS.profiles.WARLOCK[1].steps,2,S("Siphon Life","Apply if the target will survive at least 20 seconds."))
NS.profiles.WARLOCK[1].steps[1].hint="On long-lived targets; use Amplify Curse first if learned."
NS.profiles.WARLOCK[2].steps=copy(dots)
table.insert(NS.profiles.WARLOCK[2].steps,1,S("Soul Link","Maintain with your demon summoned."))
table.insert(NS.profiles.WARLOCK[3].steps,4,S("Conflagrate","Consumes Immolate: use near its end or to finish a target.",{requires="Immolate"}))
table.insert(NS.profiles.WARLOCK[3].steps,1,S("Bane of Havoc","Put on a secondary durable enemy; attack the other target.",{mode="aoe"}))
for i=1,3 do
 local p=NS.profiles.WARLOCK[i]
 table.insert(p.steps,1,S("Curse of the Elements","Bosses/elites: choose this curse to support magic damage."))
 table.insert(p.steps,2,S("Curse of Recklessness","Alternative curse for physical damage; coordinate with your group."))
 p.steps[#p.steps+1]=S("Hellfire","Nearby packs; damages you and causes high threat.",{mode="aoe",min=30})
 p.note=p.note.." Life Tap for mana only when health is safe; coordinate boss curses."
end
local druidDamage={S("Moonfire","Maintain on targets that will survive its damage."),
 S("Insect Swarm","Apply after Moonfire when learned."),S("Wrath","Cast between damage-over-time applications.")}
P("DRUID",1,"balance-druid-ranged-dps",druidDamage,"Maintain Mark of the Wild; roots can control extra enemies.")
P("DRUID",2,"feral-druid-melee-dps-and-tank",{
 S("Cat Form","Use for melee damage once learned.",{min=20}),
 S("Shifting Power","Use when ready below 60 Energy to avoid wasting its gain."),
 S("Shred","Build points from behind; spend Omen of Clarity here."),
 S("Claw","Build points when you cannot Shred."),S("Rip","Spend points if the enemy will survive the bleed.")},
 "Choose Cat or Bear. Apply Faerie Fire when appropriate; keep Mark and Thorns active.",{bear={
 S("Bear Form","Enter Bear Form."),S("Enrage","Generate rage; temporarily reduces armour."),
 S("Primal Bite","Main rage spender; preferred Omen of Clarity use."),S("Swipe","Multiple enemies.",{mode="aoe"}),
 S("Maul","Spend excess rage; replaces a rage-generating attack."),
},caster=druidDamage})
P("DRUID",3,"restoration-druid-healer",druidDamage,"Maintain Mark of the Wild; put Thorns on the tank.",{healing={
 S("Rejuvenation","Maintain on the tank or lightly injured allies."),S("Healing Touch","Direct healing when more is needed."),
 S("Swiftmend","Urgent heal on an ally with Rejuvenation or Regrowth."),
 S("Regrowth","Quick initial healing plus a lasting effect; watch mana."),
}})
base("DRUID",druidDamage,"Cast from range; heal between pulls.")
local elemental={S("Searing Totem","Place before pulling when learned."),S("Lightning Bolt","Pull from range; repeat as filler."),
 S("Fire Nova","Three or more enemies near an active fire totem.",{mode="aoe"}),S("Flame Shock","Apply after pulling; refresh when expired.")}
P("SHAMAN",1,"elemental-shaman-ranged-dps",elemental,"Maintain useful totems; conserve mana between pulls.")
P("SHAMAN",2,"enhancement-shaman-melee-dps",{
 S("Lightning Shield","Refresh before a fight."),S("Lightning Bolt","Pull from range with Rank 1, then melee."),
 S("Stormstrike","Use when ready; react to Improved Stormstrike resets."),
 S("Earth Shock","Consume Stormstrike's debuff; also interrupts."),S("Flame Shock","Alternate with Earth Shock in groups on durable targets."),
 S("Frost Shock","Alternative to Earth Shock if threat is a problem."),
 S("Flametongue Totem","Preferred fire totem, especially for groups."),
 S("Magma Totem","AoE alternative if mana allows.",{mode="aoe"}),
 S("Searing Totem","Early fire totem before Flametongue is learned.",{unless="Flametongue Totem"}),S("Fire Nova","Active fire totem required; spend mana carefully.",{mode="aoe"}),
},"Use Windfury Weapon and Mana Spring when learned. Prepare totems; conserve mana outside Stormstrike.")
P("SHAMAN",3,"restoration-shaman-healer",elemental,"Buff totems support your party; heal before dealing damage.",{healing={
 S("Healing Wave","Main heal; choose a rank appropriate to the damage."),S("Lesser Healing Wave","Faster heal when urgency requires it."),
 S("Healing Stream Totem","Sustained healing for your party."),
 S("Fire Nova","Group damage with an active fire totem, only when healing is covered.",{mode="aoe"}),
 S("Lightning Bolt","Deal damage only when healing is covered.")}})
base("SHAMAN",elemental,"Maintain a weapon imbue and helpful totems.")

-- Levels 31-60, from the Icy Veins Forever levelling guides as they stood on 2026-11-11.
-- Every step is still shown only once its spell is learned, so nothing here appears early.
-- Steps go in by the name they follow, not by position, so the lists above can change freely.
local function own(class, spec, field)
 local p=NS.profiles[class][spec]; field=field or "steps"
 -- Several specs share one list above; a spec gets its own copy before it is changed.
 if not p["own_"..field] then p[field]=copy(p[field]); p["own_"..field]=true end
 return p[field]
end
local function put(list, anchor, entry)
 for index,step in ipairs(list) do
  if step.name==anchor then table.insert(list,index+1,entry); return end
 end
 list[#list+1]=entry
end
local function hint(list, name, text)
 for _,step in ipairs(list) do if step.name==name then step.hint=text end end
end
local function each(class, specs, field, fn)
 for _,spec in ipairs(specs) do fn(own(class,spec,field)) end
end

-- Paladin: Hammer of Wrath at 44; Holy's Light's Vigil at 52.
each("PALADIN",{0,1,3},"steps",function(list)
 put(list,"Consecration",S("Hammer of Wrath","Enemy below 20% health: finish it, above all one that is running away.",{min=44}))
end)
put(own("PALADIN",1,"healing"),"Holy Shock",S("Light's Vigil","Put on an ally: your next Holy Shock on them resets its cooldown and heals their party. Expensive."))

-- Hunter: traps and Volley for groups; Marksmanship's Sniper Shot at 40.
each("HUNTER",{0,1,2,3},"steps",function(list)
 put(list,"Multi-Shot",S("Explosive Trap","Place it whenever it is ready.",{mode="aoe"}))
 put(list,"Explosive Trap",S("Volley","Large groups: channel it.",{mode="aoe"}))
end)
put(own("HUNTER",2),"Serpent Sting",S("Sniper Shot","With Rapid Killing active, start with this.",{mode="single"}))
do
 local melee=own("HUNTER",3,"melee")
 put(melee,"Serpent Sting",S("Arcane Shot","Fire before closing in, and again after Strider Kick takes you back to range.",{mode="single"}))
 put(melee,"Serpent Sting",S("Multi-Shot","Groups: fire before closing in, and again once back at range.",{mode="aoe"}))
 put(melee,"Mongoose Bite",S("Explosive Trap","Place it while you are in melee.",{mode="aoe"}))
 hint(melee,"Strider Kick","Use it, then move straight back to range.")
end

-- Mage: Arcane Wrath, Fire's Scorch and Frostfire Bolt, Frost's Ice Barrier.
do
 local arcane=own("MAGE",1)
 put(arcane,"Frostbolt",S("Arcane Wrath","After Frostbolt, and again after Frost Nova. A good use of Clearcasting.",{mode="single"}))
 local fire=own("MAGE",2)
 table.insert(fire,1,S("Frostfire Bolt","Open from range once learned.",{mode="single"}))
 hint(fire,"Pyroblast","Open from range before Frostfire Bolt is learned; cast again at three stacks of Heating Up.")
 hint(fire,"Fire Blast","Use when ready until Heating Up reaches three stacks.")
 put(fire,"Fire Blast",S("Scorch","Filler, and a cheap way to finish an enemy.",{mode="single"}))
 put(own("MAGE",3),"Frost Nova",S("Ice Barrier","Before a big pull. Its damage bonus ends when the barrier breaks.",{mode="aoe"}))
end

-- Warrior: the level 30 to 40 attacks each spec is built around.
do
 local arms=own("WARRIOR",1)
 put(arms,"Slam",S("Mortal Strike","Use when ready, after Rend and Overpower; keep 30 rage for it."))
 put(arms,"Cleave",S("Sweeping Strikes","Two enemies close together: your next five attacks hit both. Carry rage into the pull.",{mode="aoe"}))
 put(arms,"Sweeping Strikes",S("Whirlwind","Four or more enemies, with a tank or healer. Needs Berserker Stance.",{mode="aoe"}))
 hint(arms,"Rend","Apply early if the target will survive the bleed. From 31 it also sets up Overpower.")
 local fury=own("WARRIOR",2)
 put(fury,"Death Wish",S("Whirlwind","Use when ready, ahead of Bloodthirst. Needs Berserker Stance."))
 put(fury,"Whirlwind",S("Bloodthirst","Use while Whirlwind is on cooldown; keep 30 rage for it."))
 local protection=own("WARRIOR",3)
 put(protection,"Charge",S("Shield Slam","Use when ready. Short of rage, use Revenge first."))
 each("WARRIOR",{0,1,2},"steps",function(list)
  put(list,"Sunder Armor",S("Execute","Below 20% health: on bosses, or to stop a runner. It spends all your rage."))
  put(list,"Cleave",S("Thunder Clap","Damage and slow up to four enemies; your main group attack before Whirlwind.",{mode="aoe"}))
 end)
end

-- Rogue: Cheap Shot for every tree; Subtlety's Ghostly Strike and Shank.
each("ROGUE",{0,1,2,3},"steps",function(list)
 put(list,"Stealth",S("Cheap Shot","Stealth opener on enemies that can be stunned."))
end)
put(own("ROGUE",1),"Ambush",S("Garrote","Stealth opener for damage when a stun isn't needed."))
do
 local subtlety=own("ROGUE",3)
 put(subtlety,"Hemorrhage",S("Ghostly Strike","Use when ready. Garrote can follow it without Stealth for a few seconds."))
 put(subtlety,"Ghostly Strike",S("Shank","Use when ready."))
end

-- Priest: Discipline's Penance.
put(own("PRIEST",1),"Smite",S("Penance","Cast on the target while Holy Fire is burning on it."))
put(own("PRIEST",1,"healing"),"Power Word: Shield",S("Penance","Fast healing; the first tick is instant, so it works in an emergency."))

-- Warlock: Affliction's Wrack, Demonology's Demonic Brand, Destruction's Incinerate.
put(own("WARLOCK",1),"Drain Life",S("Wrack","Channel for damage once your Shadow effects are on the enemy. Use Drain Life instead when you need health."))
table.insert(own("WARLOCK",2),1,S("Searing Pain","From 25 it brands your demon's target, strengthening its next six attacks. Reapply when used up."))
do
 local destruction=own("WARLOCK",3)
 put(destruction,"Immolate",S("Incinerate","Main cast from 40. Keep Immolate on the target for its bonus."))
 hint(destruction,"Conflagrate","Needs Immolate. Before 39 use it near Immolate's end or to finish; after that, whenever ready.")
 hint(destruction,"Shadow Bolt","Pre-cast before Immolate; your filler until Incinerate at 40.")
end

-- Druid: Starfire and Hurricane; Cat's Ravage and Rake; Bear's Faerie Fire and Lacerate; Restoration's cooldowns.
each("DRUID",{0,1,3},"steps",function(list)
 put(list,"Wrath",S("Hurricane","Three or more enemies. Barkskin stops it being interrupted.",{mode="aoe",min=40}))
end)
put(own("DRUID",1),"Wrath",S("Starfire","With Eclipse: one Wrath, then two Starfires.",{mode="single"}))
do
 local cat=own("DRUID",2)
 put(cat,"Cat Form",S("Ravage","Open with it from Prowl."))
 put(cat,"Rip",S("Rake","Apply when its bleed is missing and the enemy will live nine more seconds."))
 hint(cat,"Shifting Power","Use when ready with under 50 Energy.")
 hint(cat,"Rip","At four or more points, if the enemy will live through the whole bleed.")
 local bear=own("DRUID",2,"bear")
 put(bear,"Enrage",S("Faerie Fire","Lowers the target's armour, so your attacks hit harder."))
 put(bear,"Primal Bite",S("Lacerate","Filler; from 40 use it while Primal Bite is on cooldown."))
 local healing=own("DRUID",3,"healing")
 put(healing,"Regrowth",S("Tranquility","Heavy damage on the whole group. Long cooldown."))
 put(healing,"Tranquility",S("Innervate","Use whenever it is ready to keep your mana up.",{min=40}))
end

-- Shaman: Chain Lightning and Lightning Mastery; Restoration's Riptide, Chain Heal and Mana Tide.
each("SHAMAN",{0,1,3},"steps",function(list)
 put(list,"Lightning Bolt",S("Chain Lightning","Several enemies: open with it, then use whenever it is ready.",{mode="aoe"}))
 table.insert(list,1,S("Water Shield","Keep it up in combat once learned; Lightning Shield until then."))
end)
put(own("SHAMAN",1),"Chain Lightning",S("Lightning Mastery","Burst for elites and big packs; otherwise use whenever it is ready."))
do
 local enhancement=own("SHAMAN",2)
 put(enhancement,"Stormstrike",S("Rage of the Farseer","Use against dangerous enemies."))
 hint(enhancement,"Lightning Bolt","Pull from range with Rank 1. At five Maelstrom Weapon stacks, cast your highest rank.")
 local healing=own("SHAMAN",3,"healing")
 table.insert(healing,1,S("Riptide","On an injured ally without it. Chain Heal is stronger on that ally."))
 put(healing,"Riptide",S("Chain Heal","Several injured allies standing close together."))
 put(healing,"Healing Stream Totem",S("Mana Tide Totem","Long cooldown: quickly restores mana to your group."))
end
for _,group in pairs(NS.profiles) do for _,p in pairs(group) do p.own_steps=nil; p.own_healing=nil; p.own_melee=nil; p.own_bear=nil end end

function NS.BuildRows(class, spec, level, known, mode, role)
 local group=NS.profiles[class]; local profile=group and group[spec or 0]
 if not profile then return {}, "Class not supported", nil end
 if level<1 or level>NS.maxLevel then return {}, "Guide supports levels 1-"..NS.maxLevel, profile end
 local list=profile.steps
 if role=="melee" and profile.melee and level>=30 then list=profile.melee end
 if role=="heal" and profile.healing then list=profile.healing end
 if class=="DRUID" and spec==2 then
  if known["Bear Form"] and (role=="bear" or not known["Cat Form"]) then list=profile.bear
  elseif not known["Cat Form"] then list=profile.caster end
 end
 local rows={}
 for _,entry in ipairs(list) do
  local spell=known[entry.name]
  if spell and level>=(entry.min or 1) and (not spell.level or level>=spell.level)
   and (not entry.mode or entry.mode==mode)
   and (not entry.unless or not known[entry.unless])
   and (not entry.requires or known[entry.requires]) then
   rows[#rows+1]={spell=spell,hint=entry.hint,key=entry.name}
  end
 end
 return rows, profile.note, profile
end

