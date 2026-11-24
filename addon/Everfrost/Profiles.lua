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
NS.guideReviewed = "Guides last checked 24 November 2026."
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
-- 24 November 2026: Mage, Priest and Warlock re-read from Icy Veins' rotation pages (added
-- 4 November; Frost 9 Nov, Shadow 17 Nov, Affliction 16 Nov). The rotation HUD reads these lists as
-- priorities, so fillers sit below the spells they wait for. proc=true marks a step that depends on
-- something the addon can't see in combat (a proc, a debuff running out, your mana): it is never
-- NOW on the guide's word alone, but shows in the upcoming list with its hint.
local function P2(t) t.proc=true; return t end
do
 local single,aoe="single","aoe"
 NS.profiles.MAGE[1].steps=mageSteps({
  S("Pyroblast","Open with it; then cast at three stacks of Heating Up.",P2({mode=single})),
  S("Fire Blast","Use when ready until Heating Up reaches three stacks.",{mode=single}),
  S("Arcane Wrath","Use when ready.",{mode=single}),
  S("Arcane Missiles","When Missile Barrage is active; an early filler before that.",P2({mode=single})),
  S("Arcane Blast","Filler; keep four stacks up.",{min=20,mode=single}),
  S("Frostbolt","Filler until Arcane Blast; pull from range to slow.",{mode=single,unless="Arcane Blast"}),
  S("Fireball","Early filler before Frostbolt is trained.",{mode=single,unless="Frostbolt"}),
 },{
  S("Flamestrike","Open with it; recast as its fire ends.",{mode=aoe}),
  S("Presence of Mind","An instant Flamestrike as the first one ends.",{mode=aoe}),
  S("Arcane Explosion","Use when ready; your main AoE.",{mode=aoe}),
  S("Frost Nova","Levelling: root the pack, then step away.",{mode=aoe}),
  S("Cone of Cold","Levelling: slow the pack when you need distance.",{mode=aoe}),
  S("Blizzard","Levelling: ranged group damage.",{mode=aoe}),
 })
 NS.profiles.MAGE[2].steps=mageSteps({
  S("Pyroblast","Open with it; then cast at three stacks of Heating Up.",P2({mode=single,min=20})),
  S("Fire Blast","Use when ready until Heating Up reaches three stacks.",{mode=single}),
  S("Scorch","Build Improved Scorch to five stacks; refresh it within 30 seconds.",P2({mode=single})),
  S("Frostfire Bolt","Main cast with the Frostfire Bolt build.",{mode=single}),
  S("Fireball","Filler: your main cast before Frostfire Bolt, and in the Combustion build.",{mode=single}),
 },{
  S("Blast Wave","Use when ready.",{mode=aoe}),
  S("Cone of Cold","Use when ready.",{mode=aoe}),
  S("Flamestrike","Open with it; recast before its fire ends after eight seconds.",{mode=aoe}),
  S("Arcane Explosion","While the others are on cooldown.",{mode=aoe}),
 })
 NS.profiles.MAGE[3].steps=mageSteps({
  S("Ice Barrier","Cast it on the pull; recast when Frigid Power has three seconds or less.",P2({mode=single})),
  S("Cone of Cold","At five Winter's Chill stacks, cast it as Frostbolt lands.",P2({mode=single})),
  S("Ice Lance","One Fingers of Frost stack left, or a frozen target with Frostbite: cast it as Frostbolt lands.",P2({mode=single})),
  S("Frostbolt","Filler; pre-cast it to pull.",{mode=single}),
  S("Fireball","Early filler until Frostbolt is trained.",{mode=single,unless="Frostbolt"}),
  S("Fire Blast","Levelling: finish a low-health enemy that isn't frozen.",{mode=single}),
 },{
  S("Ice Barrier","Solo pulls: put it up first.",P2({mode=aoe})),
  S("Cone of Cold","Use when ready.",{mode=aoe}),
  S("Cold Snap","Resets Cone of Cold for a second one.",{mode=aoe}),
  S("Blizzard","Filler.",{mode=aoe}),
  S("Frost Nova","Solo: root the pack, then move away.",{mode=aoe}),
  S("Arcane Explosion","Solo: while kiting until Frost Nova is ready.",{mode=aoe}),
 })

 NS.profiles.PRIEST[1].steps={
  S("Power Word: Shield","Before pulling; protect yourself or the tank.",P2({})),
  S("Holy Fire","Open from range, or on a priority target with Power in Light."),
  S("Mind Blast","Use when ready."),
  S("Shadow Word: Pain","Apply if the enemy will survive its damage.",P2({})),
  S("Penance","Use it if it isn't needed for healing."),
  S("Smite","Filler."),
  S("Holy Nova","AoE damage while farming; expensive for group healing.",{mode=aoe}),
  S("Shoot","Wand to finish and conserve mana."),
 }
 NS.profiles.PRIEST[2].steps={
  S("Power Word: Shield","Before pulling; protect yourself or the tank.",P2({})),
  S("Mind Blast","Use when ready."),
  S("Shadow Word: Pain","Apply if the enemy will survive its damage.",P2({})),
  S("Smite","Filler; pull from range."),
  S("Holy Nova","AoE damage while farming; expensive for group healing.",{mode=aoe}),
  S("Shoot","Wand to finish and conserve mana."),
 }
 put(own("PRIEST",1,"healing"),"Prayer of Healing",S("Holy Nova","Use on a Searing Light proc only when no one needs urgent healing."))
 NS.profiles.PRIEST[3].steps={
  S("Shadowform","Stay in it; casting a heal removes it."),
  S("Power Word: Shield","Before pulling; stops spell pushback.",P2({})),
  S("Smite","Pull from range.",{unless="Mind Flay"}),
  S("Shadow Word: Pain","Keep it on; refresh after it expires. Packs: every enemy living nine seconds or more.",P2({})),
  S("Devouring Plague","Keep it on; refresh after it expires. Packs: the lowest-health enemy.",P2({})),
  S("Mind Blast","Use when ready; pre-cast it to pull."),
  S("Shadow Word: Death","Use when ready, not at low health: a miss costs 30% of your health."),
  S("Vampiric Embrace","Keep it on the main target; it heals your group.",P2({})),
  S("Inner Focus","Use when ready, just before Mind Flay."),
  S("Mind Flay","Filler; always finish the channel."),
  S("Shoot","Wand to finish and conserve mana."),
 }

 local curses={
  S("Curse of the Elements","Your assigned curse; the default for magic damage.",P2({})),
  S("Curse of Recklessness","Alternative curse for physical damage; coordinate with your group.",P2({})),
 }
 local function list(t) local out={} for _,v in ipairs(t) do out[#out+1]=v end return out end
 local a=list(curses)
 for _,v in ipairs({
  S("Corruption","Keep it on; refresh as it expires.",P2({})),
  S("Bane of Agony","On long-lived targets; use Amplify Curse first if learned.",P2({})),
  S("Siphon Life","Keep it on; refresh as it expires.",P2({})),
  S("Life Tap","When you need mana, ideally while moving or before a refresh.",P2({})),
  S("Wrack","Filler channel; break it to refresh effects or for a Nightfall Shadow Bolt."),
  S("Drain Life","Instead of Wrack when you need health.",P2({})),
  S("Shadow Bolt","Filler until you learn Wrack; after that only when Nightfall makes it instant."),
  S("Shoot","Wand when existing damage can finish the enemy."),
  S("Drain Soul","Only to restock Soul Shards.",P2({})),
  S("Hellfire","Channel once the pack is on you; it hurts you too.",{mode=aoe,min=30}),
  S("Rain of Fire","When you can't stand in the pack.",{mode=aoe}),
 }) do a[#a+1]=v end
 NS.profiles.WARLOCK[1].steps=a
 NS.profiles.WARLOCK[2].steps={
  S("Soul Link","Maintain with your demon summoned."),
  S("Bane of Doom","When ready, if the enemy will live 60 more seconds.",P2({})),
  S("Bane of Agony","No Bane on yet and the enemy will live 24 seconds.",P2({})),
  curses[1],curses[2],
  S("Searing Pain","From 25 it brands your demon's target; reapply when the brand is used up.",P2({})),
  S("Immolate","Keep it on; land the refresh as it expires.",P2({})),
  S("Corruption","Keep it on; refresh as it expires.",P2({})),
  S("Life Tap","When you need mana.",P2({})),
  S("Shadow Bolt","Filler."),
  S("Drain Life","When you need health.",P2({})),
  S("Shoot","Wand when existing damage can finish the enemy."),
  S("Drain Soul","Only to restock Soul Shards.",P2({})),
  S("Hellfire","Channel once the pack is on you; it hurts you too.",{mode=aoe,min=30}),
  S("Rain of Fire","When you can't stand in the pack.",{mode=aoe}),
 }
 NS.profiles.WARLOCK[3].steps={
  curses[1],curses[2],
  S("Bane of Havoc","Two enemies: put it on the second; no other Bane there.",{mode=aoe}),
  S("Bane of Doom","When ready, if the enemy will live 60 more seconds.",P2({mode=single})),
  S("Bane of Agony","No Bane on yet and the enemy will live 24 seconds.",P2({mode=single})),
  S("Immolate","Keep it on; land the refresh as it expires.",P2({})),
  S("Corruption","Keep it on; refresh as it expires.",P2({})),
  S("Conflagrate","Use when ready while Immolate is on the target; before 39, near Immolate's end or to finish.",{requires="Immolate"}),
  S("Shadowburn","Only when Shadow and Flame is missing or under three seconds, or to finish for a shard.",P2({})),
  S("Incinerate","Main cast; keep Immolate on the target for its bonus."),
  S("Shadow Bolt","Pre-cast to pull; your filler until Incinerate."),
  S("Searing Pain","Levelling: a faster cast with high threat."),
  S("Life Tap","When you need mana and your health is safe.",P2({})),
  S("Shoot","Wand to save mana near the end."),
  S("Drain Soul","Only to restock Soul Shards.",P2({})),
  S("Hellfire","Channel once the pack is on you; it hurts you too.",{mode=aoe,min=30}),
  S("Rain of Fire","When you can't stand in the pack.",{mode=aoe}),
 }
end
-- 24 November 2026: Paladin, Hunter, Warrior, Rogue, Druid and Shaman re-read from Icy Veins'
-- rotation pages (added 4 November; Retribution 14 Nov, Survival 20 Nov, Fury 16 Nov,
-- Enhancement 13 Nov, Elemental 7 Nov). Same rules as the Mage, Priest and Warlock block above.
do
 local single,aoe="single","aoe"
 -- Paladin
 P("PALADIN",2,"protection-paladin-tank",{
  S("Righteous Fury","Keep it up at all times."),
  S("Seal of Fury","Keep it up while tanking; its Judgement taunts."),
  S("Seal of Righteousness","Damage seal before Seal of Fury is learned.",{unless="Seal of Fury"}),
  S("Consecration","Keep it down as much as your mana allows; vital for threat on packs.",{min=20}),
  S("Judgement","Use as often as you can; it's off the global cooldown."),
  S("Holy Shield","Use as often as you can."),
  S("Exorcism","Packs of Undead or Demons only.",{mode=aoe}),
  S("Holy Strike","Use on cooldown. With Shieldsworn it also triggers Holy Shield.",{min=6}),
 },"Use a shield. Mana is your limit and Consecration costs the most. Off-tanking, use another seal so Judgement doesn't taunt.")
 local holy=NS.profiles.PALADIN[1]
 holy.steps={
  S("Seal of Righteousness","Your damage seal when no healing is needed."),
  S("Judgement","Use on cooldown."),S("Holy Strike","Use on cooldown.",{min=6}),
  S("Consecration","Keep it down when no healing is needed.",{min=20}),
  S("Exorcism","Undead or Demons only."),
 }
 holy.healing={
  S("Oath of Light","Keep it on your tank at all times.",P2({})),
  S("Seal of Light","Use it if no other Paladin is."),
  S("Seal of Wisdom","Use instead when another Paladin covers Seal of Light."),
  S("Light's Vigil","Before group damage: cast it, then Holy Shock the same ally. Expensive.",P2({})),
  S("Flash of Light","Your main heal; the most mana-efficient."),
  S("Holy Light","Use it to spend Infusion of Light.",P2({})),
  S("Holy Shock","Instant heal when someone is in danger and there's no time to cast.",P2({})),
  S("Lay on Hands","Last resort; uses all your remaining mana."),
  S("Purify","Remove a harmful poison or disease when needed.",P2({})),
 }
 P("PALADIN",3,"retribution-paladin-melee-dps",{
  S("Seal of the Crusader","Judge it on your main target when its debuff is missing, then switch seals.",P2({})),
  S("Seal of Command","Unsealed Wrath: swap seals on Echo stacks (slow weapon: to Righteousness at three).",{min=20}),
  S("Seal of Righteousness","Shockadin: keep it up; refresh under 10 seconds when nothing else is ready."),
  S("Hammer of Wrath","Target below 20% health: use on cooldown.",{min=44}),
  S("Holy Wrath","Two or more Undead or Demons: cast right after a swing.",P2({mode=aoe})),
  S("Consecration","Use on cooldown; your most expensive spell.",{min=20}),
  S("Judgement","Use on cooldown; with Seal of Command it can trigger on-hit effects."),
  S("Holy Strike","Use on cooldown.",{min=6}),
  S("Holy Shock","Shockadin: use on cooldown."),
  S("Exorcism","Undead or Demons only: use on cooldown."),
 },"Keep auto-attacking. Unsealed Wrath swaps Command and Righteousness; Shockadin keeps Righteousness. Low on mana: Seal of Wisdom for a while and hold Consecration.")

 -- Hunter
 local mark=S("Hunter's Mark","Apply before pulling.",P2({}))
 local rapid=S("Rapid Fire","Big attack-speed cooldown; use with trinkets.")
 local hawkAspect=S("Aspect of the Hawk","Keep it up at range.")
 NS.profiles.HUNTER[1].steps={hawkAspect,mark,
  S("Bestial Wrath","Use on cooldown; your pet's big damage boost."),rapid,
  S("Serpent Sting","Keep it on the target after your pet engages.",P2({mode=single})),
  S("Summon Hawk","Keep two hawks up.",P2({})),
  S("Multi-Shot","Use on cooldown; avoid breaking crowd control.",{mode=aoe}),
  S("Explosive Trap","Place it on cooldown.",{mode=aoe}),
  S("Aimed Shot","Use on cooldown.",{mode=single}),
  S("Arcane Shot","When both hawks will last more than six more seconds.",P2({})),
  S("Immolation Trap","Drop it when the enemy is in melee range.",P2({mode=single})),
  S("Volley","Channel it when nothing else is ready.",{mode=aoe}),
  S("Auto Shot","Stand still so your Auto Shots keep going."),
 }
 NS.profiles.HUNTER[2].steps={hawkAspect,mark,rapid,
  S("Sniper Shot","Use on cooldown."),
  S("Multi-Shot","Use on cooldown.",{mode=aoe}),S("Explosive Trap","Place it on cooldown.",{mode=aoe}),
  S("Aimed Shot","Use on cooldown.",{mode=single}),
  S("Serpent Sting","Keep it on the target.",P2({mode=single})),
  S("Arcane Shot","Use on cooldown; in groups only against three or fewer enemies."),
  S("Immolation Trap","Drop it when the enemy is in melee range.",P2({mode=single})),
  S("Volley","Channel it when nothing else is ready.",{mode=aoe}),
  S("Auto Shot","Stand still so your Auto Shots keep going."),
 }
 local survival=NS.profiles.HUNTER[3]
 survival.steps={hawkAspect,mark,rapid,
  S("Serpent Sting","Don't reapply until it has fully worn off.",P2({mode=single})),
  S("Multi-Shot","Use on cooldown.",{mode=aoe}),S("Explosive Trap","Place it on cooldown.",{mode=aoe}),
  S("Aimed Shot","Use on cooldown.",{mode=single}),
  S("Arcane Shot","Use on cooldown."),
  S("Volley","Channel it when nothing else is ready.",{mode=aoe}),
  S("Auto Shot","Stand still so your Auto Shots keep going."),
 }
 survival.melee={S("Aspect of the Beast","Keep it up in melee."),mark,
  S("Rapid Fire","Your biggest cooldown; also speeds up melee. Use with trinkets."),
  S("Aimed Shot","Cast it before running into melee.",P2({mode=single})),
  S("Serpent Sting","Cast it while running in.",P2({})),
  S("Multi-Shot","Groups: fire before closing in.",P2({mode=aoe})),
  S("Immolation Trap","Place it once in melee; keep its burn on the enemy.",P2({mode=single})),
  S("Summon Hawk","Keep two hawks up if talented.",P2({})),
  S("Raptor Strike","Use on cooldown."),S("Mongoose Bite","Use on cooldown."),
  S("Explosive Trap","Groups: place it while in melee.",{mode=aoe}),
  S("Strider Kick","Use on cooldown."),
 }
 survival.note="Pet attacks first. Ranged: Aspect of the Hawk. Melee: Aspect of the Beast. Keep Improved Tracking on for the target type."

 -- Warrior
 local shout=S("Battle Shout","Keep it up for you and your group.")
 local charge=S("Charge","Open from range, outside combat.")
 local demo=S("Demoralizing Shout","Keep it up when needed and nobody else does.",P2({}))
 local rush=S("Victory Rush","Use after an eligible kill while the proc lasts.",{min=20})
 local reckless=S("Reckless Swings","Short of rage with health to spare: use it and keep attacking.",P2({}))
 local cleave=S("Cleave","Instead of Heroic Strike when a second enemy is in range.",P2({mode=aoe}))
 NS.profiles.WARRIOR[1].steps={shout,charge,
  S("Sunder Armor","Build five stacks if you're the one keeping armour down.",P2({})),demo,
  S("Thunder Clap","Keep its attack slow up when needed; hits up to four enemies.",P2({})),
  S("Rend","Keep it on your main target; don't refresh early. From 31 it sets up Overpower.",P2({})),rush,
  S("Sweeping Strikes","Two or more enemies that will live: your next five attacks also hit a second.",{mode=aoe}),
  S("Whirlwind","Three or more enemies. Needs Berserker Stance.",{mode=aoe}),
  S("Overpower","Use when a dodge or Rend proc enables it, before it expires."),
  S("Mortal Strike","Keep 30 rage for it as it comes off cooldown."),
  S("Execute","Target at 20% health or less; keep Overpower and Mortal Strike ahead of it."),
  S("Slam","Use when you can finish the cast standing still; with Improved Slam, any time.",{min=20}),
  S("Spearing Strike","Top priority against Giants, Dragonkin and mounted enemies.",P2({})),
  reckless,
  S("Hamstring","Spare rage only: fish for weapon procs and crits.",P2({})),cleave,
  S("Heroic Strike","Only with extra rage, keeping enough for higher priorities.",P2({})),
 }
 NS.profiles.WARRIOR[1].note="Use Bloodrage when you need rage, including at the start of a pull. Save rage on dying targets."
 NS.profiles.WARRIOR[2].steps={shout,charge,
  S("Sunder Armor","Build five stacks at the start if you're the one keeping armour down.",P2({})),demo,
  S("Thunder Clap","Keep its attack slow up when needed; needs Battle Stance.",P2({})),
  S("Death Wish","Save rage first and stay on the target; you take more damage."),rush,
  S("Whirlwind","Use whenever it's ready, even on one target. Needs Berserker Stance."),
  S("Bloodthirst","Keep 30 rage for it without delaying Whirlwind."),
  S("Execute","Target at 20% or less. Above 2,000 attack power, Bloodthirst goes first."),
  reckless,
  S("Berserker Rage","Use it when you need rage; save it if a Fear is coming.",P2({})),
  S("Overpower","Proc up and under 25 rage: switch to Battle Stance for it.",{mode=single}),
  S("Rend","Apply while in Battle Stance; let the old bleed finish first.",P2({mode=single})),
  S("Hamstring","Spare rage only: fish for Windfury procs and Flurry crits.",P2({mode=single})),cleave,
  S("Heroic Strike","Above 65 rage, keeping enough for Whirlwind and Bloodthirst.",P2({})),
 }
 NS.profiles.WARRIOR[2].note="Use Bloodrage when you need rage, including at the start of a pull. Queue Heroic Strike only above 65 rage."
 P("WARRIOR",3,"protection-warrior-tank",{
  S("Battle Shout","Keep it up; refresh it before the pull."),S("Defensive Stance","Tank in it once learned."),
  S("Charge","Pull outside combat in Battle Stance, then switch to Defensive Stance."),demo,
  S("Shield Block","Use on cooldown against melee hits; it's off the global cooldown."),
  S("Shield Slam","Save rage so you can use it as soon as it's ready."),
  S("Revenge","Use after blocking, dodging or parrying."),
  S("Thunder Clap","Use when ready; on packs, open with it as enemies reach you."),
  S("Rend","Apply if the bleed is missing; don't refresh early.",P2({})),
  S("Victory Rush","Use after an eligible kill.",{min=20}),
  S("Sunder Armor","Stack five after your opener, then use as filler; spread it on packs."),
  cleave,
  S("Heroic Strike","Only with spare rage, keeping enough for Shield Block and main attacks.",P2({})),
 },"Use a shield. Thunder Clap hits only four enemies: switch targets to build threat on the rest. Taunt lost enemies.")

 -- Rogue
 local expose=S("Expose Armor","Finisher: only if nothing stronger lowers its armour.",P2({}))
 local snd=S("Slice and Dice","Keep it up at all times.",P2({}))
 local rupture=S("Rupture","Keep it up if the enemy will live through it.",P2({}))
 local cold=S("Cold Blood","Pair it with a five-point Eviscerate.",P2({}))
 local evis=S("Eviscerate","At five points, once Slice and Dice and Rupture are up and Shank is cooling down.",P2({}))
 local stealth=S("Stealth","Prepare an opener outside combat.")
 local cheap=S("Cheap Shot","Stealth opener on enemies that can be stunned.")
 NS.profiles.ROGUE[1].steps={stealth,cheap,
  S("Garrote","Open with it from Stealth."),
  S("Ambush","Levelling: stealth opener with a dagger from behind."),
  expose,snd,rupture,
  S("Shank","Use on cooldown, but not when Energy is nearly full."),
  S("Mutilate","Your combo-point builder."),
  S("Backstab","Builder from behind until Mutilate.",{unless="Mutilate"}),
  S("Sinister Strike","Builder until Mutilate when you can't Backstab.",{unless="Mutilate"}),
  cold,evis,
 }
 NS.profiles.ROGUE[2].steps={stealth,cheap,
  S("Garrote","Open with it from Stealth."),
  S("Ambush","Levelling: stealth opener with a dagger from behind."),
  S("Blade Flurry","Use whenever a second enemy is close; otherwise early for the attack speed."),
  S("Adrenaline Rush","Once your opening Energy is spent and you hold threat."),
  expose,snd,rupture,
  S("Shank","Use on cooldown if it won't cap your Energy."),
  S("Riposte","Use whenever a parry makes it available."),
  S("Sinister Strike","Your combo-point builder."),
  S("Backstab","Dagger build: use instead of Sinister Strike."),
  cold,evis,
 }
 NS.profiles.ROGUE[3].steps={stealth,cheap,
  S("Ambush","Open with it from Stealth."),
  S("Rupture","At five points; keep it up at all times.",P2({min=30})),
  S("Death Mark","At five points; keep it up as much as you can.",P2({})),
  S("Slice and Dice","At five points; keep it up as much as you can.",P2({})),
  S("Shank","Use on cooldown at three combo points or fewer."),
  S("Ghostly Strike","Use on cooldown, then follow with Garrote."),
  S("Garrote","After Ghostly Strike; keep it up if the enemy will live through it.",P2({})),
  S("Premeditation","Use on cooldown unless it would overfill combo points."),
  S("Hemorrhage","Main combo-point builder."),
  S("Backstab","Builder from behind until Hemorrhage.",{unless="Hemorrhage"}),
  S("Sinister Strike","Builder until Hemorrhage when you can't Backstab.",{unless="Hemorrhage"}),
  S("Eviscerate","Before Rupture and Death Mark are learned: spend five points on it.",P2({})),
 }
 for i=1,3 do NS.profiles.ROGUE[i].note="Instant Poison on your main hand, Deadly Poison on your off hand (Instant on both until Deadly is learned). Avoid capping Energy." end

 -- Druid
 local druid=NS.profiles.DRUID
 P("DRUID",1,"balance-druid-ranged-dps",{
  S("Insect Swarm","Keep it on the target all fight; don't refresh early.",P2({})),
  S("Moonfire","Keep it up after Insect Swarm; don't refresh early.",P2({})),
  S("Starfire","Two after each Wrath; never without an Eclipse charge.",P2({mode=single})),
  S("Hurricane","Five or more enemies: channel it.",{mode=aoe,min=40}),
  S("Wrath","Open with it; with Eclipse, one Wrath then two Starfires. Not with full charges."),
 },"Keep Mark of the Wild up and Thorns on tanks. Short of mana: lean on Wrath outside Omen of Clarity.")
 druid[2].steps={
  S("Cat Form","Use for melee damage once learned.",{min=20}),
  S("Ravage","Open with it from Prowl."),
  S("Faerie Fire","Keep it on your target; on packs, only after spending combo points.",P2({})),
  S("Ferocious Bite","Five points, Rip has 4+ seconds left and 70+ Energy (35+ with Omen of Clarity).",P2({})),
  S("Shifting Power","Use when ready with about 50 Energy or less.",P2({})),
  S("Rip","At five points when it's missing, if the enemy will live through it.",P2({})),
  S("Rake","Apply when its bleed is missing and the enemy will live nine more seconds.",P2({})),
  S("Shred","Spend Omen of Clarity here; with Shredding Attacks it's also your builder."),
  S("Claw","Your builder without Shredding Attacks."),
 }
 druid[2].bear={
  S("Bear Form","Enter Bear Form."),
  S("Faerie Fire","Keep it up; on packs, swap through enemies to cover as many as you can.",P2({})),
  S("Demoralizing Roar","Keep it on nearby enemies to cut their physical damage.",P2({})),
  S("Enrage","Generate rage; temporarily reduces armour.",P2({})),
  S("Primal Bite","Use on cooldown."),
  S("Swipe","Replaces Lacerate on several enemies.",{mode=aoe}),
  S("Lacerate","Filler; refresh five stacks before they run out.",{mode=single}),
  S("Maul","At 35 rage or more.",P2({})),
 }
 druid[3].steps={
  S("Insect Swarm","Keep it on the boss.",P2({})),
  S("Moonfire","Expensive: only if your group is short on damage.",P2({})),
  S("Wrath","Cheap filler during downtime."),
 }
 druid[3].healing={
  S("Regrowth","Keep it on the tank, then on anyone badly hurt. A rank below max saves mana."),
  S("Rejuvenation","Keep it on the tank; add it to Regrowth targets under steady damage.",P2({})),
  S("Wild Growth","Whole party badly hurt; best with Omen of Clarity. Heals only that group.",P2({})),
  S("Swiftmend","Urgent heal on an ally with Rejuvenation or Regrowth.",P2({})),
  S("Tranquility","Small but mana-efficient heal for the whole party.",P2({})),
  S("Innervate","On yourself once you've used a good part of your mana.",P2({min=40})),
  S("Healing Touch","Rarely worth it; Regrowth is better.",P2({})),
 }

 -- Shaman
 local shaman=NS.profiles.SHAMAN
 shaman[1].steps={
  S("Water Shield","Keep it up in combat once learned; Lightning Shield until then."),
  S("Searing Totem","Place it last, just before pulling.",P2({mode=single})),
  S("Magma Totem","Place it last, just before pulling.",P2({mode=aoe})),
  S("Searing Totem","Before Magma Totem: place it so Fire Nova has a totem.",P2({mode=aoe,unless="Magma Totem"})),
  S("Flame Shock","Apply to the main target; refresh when it wears off.",P2({mode=single})),
  S("Lightning Mastery","Use with trinkets and racials; otherwise whenever it is ready."),
  S("Chain Lightning","Use when ready; in long single-target fights only with Clearcasting."),
  S("Fire Nova","Use on cooldown near an active fire totem.",{mode=aoe}),
  S("Flame Shock","Apply to an enemy without it; skip if mana is short.",P2({mode=aoe})),
  S("Lightning Bolt","Filler; skip it in long group fights if mana runs short."),
  S("Mana Tide Totem","Once you've spent about a fifth of your mana.",P2({})),
 }
 shaman[2].steps={
  S("Lightning Shield","Apply it before engaging."),
  S("Magma Totem","Keep it down; use Searing Totem instead when mana is short.",P2({})),
  S("Searing Totem","Fire totem until Magma Totem is learned.",P2({unless="Magma Totem"})),
  S("Fire Nova","Use on cooldown with a fire totem near the enemies.",{mode=aoe}),
  S("Flame Shock","Keep it on the target; in groups, spread it between enemies.",P2({})),
  S("Rage of the Farseer","Use with trinkets and racials, or save it for a burst."),
  S("Stormstrike","Use on cooldown."),
  S("Lightning Bolt","Pull with Rank 1. In combat, only at five Maelstrom Weapon stacks.",P2({})),
  S("Earth Shock","When Flame Shock is already up; watch your threat."),
  S("Fire Nova","Use it with a fire totem active.",P2({mode=single})),
 }
 shaman[2].note="Windfury Weapon. Totems: Strength of Earth, Magma, Mana Spring and Windfury Totem (Call of the Elements places all four)."
 local resto=own("SHAMAN",3,"healing")
 hint(resto,"Riptide","Use on cooldown on the most injured ally; Chain Heal is stronger on them.")
 hint(resto,"Mana Tide Totem","Use at about 80% mana so none of it is wasted.")
 put(resto,"Fire Nova",S("Chain Lightning","Groups: damage only when healing is covered and mana allows.",{mode=aoe}))
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
 local rows,seen={},{}
 for _,entry in ipairs(list) do
  local spell=known[entry.name]
  if spell and level>=(entry.min or 1) and (not spell.level or level>=spell.level)
   and (not entry.mode or entry.mode==mode
    -- Two enemies: the single-target list plus the AoE spells that pay off against two.
    or (mode=="cleave" and (entry.mode=="single" or NS.cleaveSpells[entry.name])))
   and (not entry.unless or not known[entry.unless])
   and (not entry.requires or known[entry.requires])
   and not seen[entry.name] then
   -- A spell listed twice (single-target and AoE wording) shows once, the first that applies.
   seen[entry.name]=true
   rows[#rows+1]={spell=spell,hint=entry.hint,key=entry.name,proc=entry.proc}
  end
 end
 return rows, profile.note, profile
end


-- What each guide spell is for, so the rotation HUD can keep buffs, defensives and utility out
-- of the damage track. Anything not listed is part of the rotation.
-- upkeep: long buffs, stances, forms and seals; shown only as a reminder when the game says it's missing.
NS.upkeep={
 ["Righteous Fury"]=true,["Seal of Fury"]=true,["Seal of Righteousness"]=true,["Seal of Command"]=true,
 ["Seal of Light"]=true,["Battle Shout"]=true,["Defensive Stance"]=true,["Lightning Shield"]=true,
 ["Water Shield"]=true,["Bear Form"]=true,["Cat Form"]=true,["Stealth"]=true,["Soul Link"]=true,["Shadowform"]=true,
 ["Seal of Wisdom"]=true,["Aspect of the Hawk"]=true,["Aspect of the Beast"]=true,
}
-- AoE steps that also pay off against two enemies. Cleave mode adds these to the single-target
-- list; a spec with none of them simply uses its single-target list for two enemies.
NS.cleaveSpells={
 ["Cleave"]=true,["Sweeping Strikes"]=true,["Blade Flurry"]=true,["Multi-Shot"]=true,["Chain Lightning"]=true,
 ["Swipe"]=true,["Consecration"]=true,["Thunder Clap"]=true,["Fire Nova"]=true,["Demoralizing Shout"]=true,
 ["Bane of Havoc"]=true,["Explosive Trap"]=true,["Holy Wrath"]=true,
}
-- Defensive and utility spells for the separate track. Shown only once learned (spellbook scan),
-- never as an instruction: Everfrost can't see how much danger you're in, so these show as
-- available, and the big cooldowns are marked situational.
-- kind: interrupt, taunt, defensive, emergency. major: a long cooldown kept for real danger.
NS.utility={
 PALADIN={{name="Hammer of Justice",kind="interrupt"},{name="Divine Protection",kind="defensive",major=true},
  {name="Blessing of Protection",kind="emergency",major=true},{name="Divine Shield",kind="emergency",major=true},
  {name="Lay on Hands",kind="emergency",major=true}},
 WARRIOR={{name="Shield Bash",kind="interrupt"},{name="Pummel",kind="interrupt"},{name="Taunt",kind="taunt"},
  {name="Mocking Blow",kind="taunt"},{name="Challenging Shout",kind="taunt",major=true},
  {name="Concussion Blow",kind="interrupt"},{name="Disarm",kind="defensive"},
  {name="Last Stand",kind="defensive",major=true},{name="Shield Wall",kind="defensive",major=true},
  {name="Intimidating Shout",kind="emergency",major=true}},
 DRUID={{name="Bash",kind="interrupt"},{name="Growl",kind="taunt"},{name="Challenging Roar",kind="taunt",major=true},
  {name="Barkskin",kind="defensive"},{name="Nature's Grasp",kind="defensive"},{name="Frenzied Regeneration",kind="defensive",major=true},
  {name="Rebirth",kind="emergency",major=true}},
 ROGUE={{name="Kick",kind="interrupt"},{name="Gouge",kind="interrupt"},{name="Blind",kind="interrupt"},{name="Evasion",kind="defensive",major=true},
  {name="Vanish",kind="emergency",major=true}},
 MAGE={{name="Counterspell",kind="interrupt"},{name="Blink",kind="defensive"},{name="Ice Block",kind="emergency",major=true}},
 PRIEST={{name="Fade",kind="defensive"},{name="Psychic Scream",kind="emergency",major=true}},
 HUNTER={{name="Feign Death",kind="defensive"},{name="Disengage",kind="defensive"}},
 WARLOCK={{name="Shadow Ward",kind="defensive"},{name="Death Coil",kind="emergency",major=true},{name="Howl of Terror",kind="emergency",major=true}},
 SHAMAN={{name="Grounding Totem",kind="interrupt"},{name="Earthbind Totem",kind="defensive"},{name="Nature's Swiftness",kind="emergency",major=true}},
}
-- Specs that tank: the defensive track is on by default for them.
NS.tankSpecs={PALADIN={[2]=true},WARRIOR={[3]=true}}
function NS.IsTank(class, spec, role)
 if role=="bear" then return true end
 return NS.tankSpecs[class] and NS.tankSpecs[class][spec] or false
end
