# Gear priorities and upgrade highlights

Everfrost gives estimated gear comparisons for levels 1–60, with talent-based stat weights from level 10. Each item gets a score: the sum of each stat it carries times that stat's weight for your spec. An upgrade shows how much higher its score is as a green percentage.

## Where the weights come from

Until November 25, 2026 every spec used rank weights: the first stat in the guide's list beat the second, and so on. Now 17 of the 27 talent trees use measured numbers.

**Simulated (17 trees).** The weights come from the [wowsims WoW Forever simulator](https://wowsims.com/forever) ([source](https://github.com/wowsims/forever), MIT licence), the open-source simulator the class communities maintain. Each spec's page ships "EP weights" measured by the simulator on a preset gear set; Everfrost copies those from `ui/specs/<class>/<spec>/presets.ts` (and `ui/specs/druid/feral_ep.ts`) at commit `d45287b` of November 24, 2026. What that means for you:

- They are **level 60** values, measured against a raid boss three levels higher, mostly on pre-raid gear. While levelling they are a guide, not a measurement: Hit in particular is valued as it is below the raid hit cap.
- The simulator weighs Hit, Crit, Haste, Expertise, Dodge and Parry per *rating point*. Forever items show them as whole percentages, so Everfrost multiplies by the simulator's rating per 1% (`ui/sim/constants/mechanics.ts`): Hit 10, Crit 14, Haste 10, Expertise 10, Dodge 12, Parry 15, Block chance 5. The table shows the result, "per 1%".
- A damage simulator values Stamina and armour at nothing. Marked `*` below is a small **Everfrost levelling allowance** for them, on that spec's own scale. Tank presets weigh both themselves.
- Stats Everfrost does not read from items are left out: Spell Piercing, Armour Penetration, physical damage bonuses, Feral Combat Skill and the school-specific hit the Retribution presets list.
- Where a spec has several presets, the one closest to levelling and dungeons is used: single-target healing for Discipline and Holy, the slow main-hand preset for Combat, Unsealed Wrath (the simulator's default) for Retribution, Turret for ranged Hunters and Melee for Survival's melee build, Pre-BiS rather than P1 for Balance.

| Tree | wowsims preset | Value of one point (heaviest first, per rating point) |
| --- | --- | --- |
| Arms Warrior | Pre-BiS Arms | Weapon DPS 16.71, Hit 50.3 per 1%, Crit 32.48 per 1%, Strength 2.2, Agility 1.76, Expertise 15.7 per 1%, Haste 12.9 per 1%, Attack power 1, Stamina 0.25*, Armour 0.02*, Off-hand DPS 0. |
| Fury Warrior | Pre-BiS Fury | Weapon DPS 12.59, Off-hand DPS 2.66, Expertise 23.5 per 1%, Crit 31.64 per 1%, Strength 2.2, Haste 17.6 per 1%, Agility 1.7, Hit 16.9 per 1%, Attack power 1, Stamina 0.25*, Armour 0.02*. |
| Protection Warrior | Pre-BiS Balanced | Expertise 23.5 per 1%, Weapon DPS 1.42, Stamina 1.15, Block value 0.76, Agility 0.66, Strength 0.62, Defence 0.53, Crit 6.02 per 1%, Dodge 3.48 per 1%, Attack power 0.27, Parry 3.9 per 1%, Haste 1.7 per 1%, Armour 0.06, Hit 0.4 per 1%. |
| Protection Warrior, Tank Threat focus | Pre-BiS Offensive | Expertise 30.7 per 1%, Weapon DPS 1.45, Stamina 1.15, Block value 0.63, Strength 0.62, Agility 0.56, Defence 0.45, Crit 6.02 per 1%, Haste 2.9 per 1%, Attack power 0.27, Dodge 2.76 per 1%, Parry 3.3 per 1%, Hit 0.6 per 1%, Armour 0.05. |
| Assassination Rogue | Assassination | Weapon DPS 8.44, Off-hand DPS 4.16, Hit 28 per 1%, Expertise 27.7 per 1%, Agility 2.06, Crit 28.28 per 1%, Haste 19.3 per 1%, Strength 1.1, Attack power 1, Stamina 0.25*, Armour 0.02*. |
| Combat Rogue | Combat Sinister | Weapon DPS 10.57, Off-hand DPS 2.93, Expertise 25.5 per 1%, Hit 24.2 per 1%, Agility 1.96, Haste 17.2 per 1%, Crit 23.8 per 1%, Strength 1.1, Attack power 1, Stamina 0.25*, Armour 0.02*. |
| Subtlety Rogue | Subtlety | Weapon DPS 10.47, Expertise 24.2 per 1%, Off-hand DPS 2.27, Hit 21.2 per 1%, Agility 1.93, Crit 22.82 per 1%, Haste 14.3 per 1%, Strength 1.1, Attack power 1, Stamina 0.25*, Armour 0.02*. |
| Beast Mastery Hunter | Turret | Weapon DPS 3.29, Hit 12.6 per 1%, Agility 1, Crit 12.18 per 1%, Haste 7.5 per 1%, Intellect 0.64, MP5 0.41, Attack power 0.34, Stamina 0.12*, Armour 0.01*. |
| Marksmanship Hunter | Turret | Weapon DPS 3.29, Hit 12.6 per 1%, Agility 1, Crit 12.18 per 1%, Haste 7.5 per 1%, Intellect 0.64, MP5 0.41, Attack power 0.34, Stamina 0.12*, Armour 0.01*. |
| Survival Hunter | Melee | Weapon DPS 4.86, Hit 24.8 per 1%, Off-hand DPS 1.18, Agility 1, Crit 14 per 1%, Haste 9.1 per 1%, Intellect 0.7, Strength 0.41, Attack power 0.37, MP5 0.23, Stamina 0.12*, Armour 0.01*. |
| Retribution Paladin | Unsealed Wrath | Weapon DPS 14.14, Hit 77.6 per 1%, Expertise 54.5 per 1%, Haste 35.3 per 1%, Crit 38.36 per 1%, Strength 2.4, Spell power 1.95, Agility 1.91, Intellect 1.48, Attack power 1, Stamina 0.25*, Armour 0.02*, MP5 0.01. School damage counts as spell power at: holy 0.82. |
| Discipline Priest | Disc Single-Target | Healing power 1, Crit 9.8 per 1%, MP5 0.4, Intellect 0.2, Haste 1.5 per 1%, Spirit 0.15, Stamina 0.1*, Armour 0.005*. |
| Holy Priest | Holy Single-Target | Healing power 1, MP5 0.6, Haste 5 per 1%, Intellect 0.35, Crit 4.2 per 1%, Spirit 0.3, Stamina 0.1*, Armour 0.005*. |
| Shadow Priest | Shadow | Hit 11.4 per 1%, Spell power 1, Crit 11.76 per 1%, Haste 7.3 per 1%, Intellect 0.24, Stamina 0.1*, Spirit 0.01, Armour 0.005*. Shadow damage counts in full. |
| Balance Druid | Pre-BiS | Hit 14.5 per 1%, Spell power 1, Haste 9.5 per 1%, Crit 10.64 per 1%, Intellect 0.2, Stamina 0.1*, Armour 0.005*. School damage counts as spell power at: arcane 0.68, nature 0.32. |
| Feral Druid | Cat | Weapon DPS 2.14, Agility 0.66, Strength 0.59, Hit 5.21 per 1%, Crit 7.08 per 1%, Expertise 4.9 per 1%, Haste 3.93 per 1%, Attack power 0.24, Stamina 0.07*, Armour 0.006*. |
| Feral Druid, Bear Balanced focus | Bear | Weapon DPS 3.09, Expertise 17.76 per 1%, Stamina 1, Defence 0.88, Hit 6.88 per 1%, Strength 0.49, Agility 0.43, Crit 5.08 per 1%, Haste 3.58 per 1%, Attack power 0.22, Armour 0.174, Dodge 1.28 per 1%. |
| Elemental Shaman | Default | Haste 12.3 per 1%, Hit 11.8 per 1%, Spell power 1, Crit 8.54 per 1%, Intellect 0.19, Stamina 0.1*, MP5 0.04, Spirit 0.02, Armour 0.005*. School damage counts as spell power at: fire 0.31, nature 0.69. |
| Enhancement Shaman | Pre-BiS | Weapon DPS 14.18, Hit 52 per 1%, Expertise 35 per 1%, Haste 28.1 per 1%, Crit 33.88 per 1%, Strength 2.2, Intellect 1.99, Agility 1.32, Spell power 1.27, Attack power 1, Stamina 0.25*, Armour 0.02*. School damage counts as spell power at: nature 0.57. |

**Estimated (10 trees).** The simulator has no weights yet for Mage (Arcane, Fire, Frost), Warlock (Affliction, Demonology, Destruction), Holy and Protection Paladin, Restoration Druid and Restoration Shaman, and no other source publishes numbers for them: Wowhead's Forever stat pages for these specs give an order only, and the Fire Mage page calls its own order speculative. For these, and for the starter lists below level 10, Everfrost still turns the Stats order of the Icy Veins Forever levelling guide into rank weights (see How scores work). **The orders were re-read on November 11, 2026**, after the guides' level 60 update; Hit keeps the place the stat pages give it where a levelling guide leaves it out as rare on early gear. Demonology splits school damage evenly between Fire and Shadow, and Destruction credits Fire in full and Shadow at half. When wowsims publishes weights for one of these trees, copy them into `GearProfiles.lua` with `sim(...)` and move its row to the table above.

| Class | Tree | Guide order used |
| --- | --- | --- |
| Paladin | Holy | Healing power > Intellect > MP5 > Crit > Haste > Spirit |
| Paladin | Protection | Stamina > Spell power > Strength > Block > Hit > Defence > Armour > Intellect > Agility |
| Mage | Arcane | Spell power > Intellect > Spirit > Crit > Hit > Stamina > MP5 |
| Mage | Fire | Spell power > Crit > Intellect > Spirit > Hit > Stamina > MP5 |
| Mage | Frost | Hit > Spell/Frost damage > Crit > Spirit > Intellect > Stamina |
| Warlock | Affliction | Spell power > Crit > Spirit > Intellect/Stamina > Hit > Haste |
| Warlock | Demonology | Spell power > Crit > Hit > Intellect/Stamina > Spirit > Haste |
| Warlock | Destruction | Spell power > Hit > Crit > Intellect/Stamina > Spirit > Haste |
| Druid | Restoration | Healing power > Intellect > Crit > Haste > Spirit > MP5 |
| Shaman | Restoration | Healing power > Crit > Intellect > Spirit > MP5 > Stamina |

Every profile records which kind it is. Tooltips and the Gear & Loot settings page say "Weights: wowsims Forever simulator (Pre-BiS Fury)", "Weights: Everfrost estimate from the Icy Veins stat order" or "Weights: your own weights".

## Your own weights

**Settings → Gear & Loot → Stat weights** (or `/everfrost weights`) lists the 21 stats Everfrost scores for the active profile: Weapon DPS, Off-hand DPS, Attack power, Strength, Agility, Stamina, Armour, Intellect, Spirit, Spell power, Healing power, MP5, Hit, Crit, Haste, Expertise, Defence, Dodge, Parry, Block value and Block chance. Each number is the value of one point as the item shows it (1% for the percentage stats). Only their sizes relative to each other matter.

- Type a number from 0 to 999 and press Enter. A comma works as the decimal point. Anything else puts the old value back; Escape abandons the edit. 0 ignores a stat.
- Changed stats are shown in gold. Typing the default back removes the change. **Reset to defaults** (or `/everfrost weights reset`) removes all of them for that profile.
- Changes save per character in `EverfrostDB.gearWeights`, keyed by profile: `WARRIOR:2` for Fury, `PALADIN:2:threat` for a scoring focus, `WARRIOR:0` for the starter list. Only the stats you changed are stored, so a later update to the defaults still reaches the rest.
- A changed profile's priority line is rebuilt from its weights, and "Better for ..." checks use your numbers for the other focuses too. Armour you weigh yourself becomes one of your stats instead of an allowance.
- Bags, loot rolls, quest rewards and vendors rescan at once (after combat, if you are in it).

The code is in `GearProfiles.lua`: `NS.SetGearWeights`, `NS.GearSetWeight`, `NS.GearResetWeights`, `NS.GearCustomised` and the row list `NS.gearWeightRows`.

Feral's default profile is Cat; Bear is a scoring focus (below). Hunter Survival uses Marksmanship's ranged weights until its melee requirements are met or when the RANGED override is selected. A healer's DAMAGE view changes rotation guidance, while gear retains that selected healer specialisation's priorities.

**Starter priorities:** below level 10 every class uses one short stat list, whatever guide is selected, because there is usually no talent tree to read. See the table below.

**Levelling gear guidance (0.6.0):** talent-based stat priorities start at level 10 for every selection, including manual specs. This rule is displayed in the Gear Upgrades and Specialisation settings, gear tooltips, guide menu, panel hover text, addon metadata and `/everfrost gear` output before level 10. Spell guides still cover levels 1–30. From level 10, the Levelling spell guide uses the active talent group's tree with the most spent points for gear scoring. The general spell priorities remain unchanged. All three tree counts must be available, with one positive winner; a tie, zero spent points or unavailable/partial point data remains unscored. An active specialisation index alone does not establish the dominant talent tree for this rule. An explicit manual spec choice overrides detection from level 10 onward. Talent metadata refreshes outside combat, including after talent changes or switching active groups; combat keeps the previous cached gear context until it ends. Settings, the guide menu, `/everfrost gear` and bag/loot comparisons use the same effective gear spec. The Gear Upgrades heading names the spec and marks a talent-inferred choice with `(talents)`.

Forever detection uses the active group's combat config, its three display groups and `C_Traits.GetGroupCurrencyInfo`. Counts are matched by group ID and ordered like the native talent headers, using the first currency's `spent` field. A group omitted from an otherwise valid currency list counts as zero, matching the native window. Missing/invalid metadata and staged respecs remain unavailable. Specialisation settings displays the cached split; `/everfrost status` adds its source. This replaces the misleading zero totals returned by the specialisation tuple in the reported level-18 Shaman case.

## Starter priorities (levels 1–9)

These are Everfrost estimates based on each class's usual stats, not rankings from a guide.

| Class | Starter order |
| --- | --- |
| Warrior | Weapon DPS > Strength > Agility > Stamina > Armour |
| Paladin | Weapon DPS > Strength > Stamina > Intellect > Armour |
| Hunter | Weapon DPS > Agility > Stamina > Intellect > Armour |
| Rogue | Weapon DPS > Agility > Strength > Stamina > Armour |
| Shaman | Weapon DPS > Intellect > Strength > Stamina > Spirit > Armour |
| Mage | Intellect > Spirit > Spell power > Stamina > Armour |
| Priest | Intellect > Spirit > Spell power > Stamina > Armour |
| Warlock | Intellect > Stamina > Spirit > Spell power > Armour |
| Druid | Intellect > Spirit > Stamina > Spell power > Armour |

## How scores work

The implementation is in `addon/Everfrost/GearProfiles.lua` and `Gear.lua`.

1. **Score** is the sum of each stat amount times its weight, where a weight is the value of one point as the item shows it. Simulated profiles carry their weights directly (table above).
2. **Estimates:** for an order of N groups, each stat in group R gets rank weight `N - R + 1`, then is scaled to the item's unit: Weapon DPS by `12` (an Everfrost heuristic so low-level weapon DPS isn't lost among the other quantities), armour by `0.1` (about 50 armour to one point of a mid-priority stat), and the percentage stats by the same rating-per-1% the simulator uses. "Block" in an order covers block value and, at five times the weight, each 1% of block chance.
3. **Attack power** uses the profile's own weight. An estimate that leaves it out uses half the higher of its Strength or Agility weight. Hunter ranged AP and general AP use the larger value rather than double counting.
4. **Spell power and schools:** general spell power and healing aliases are not counted twice. For healing, the larger of spell power or healing power receives healing credit. School-specific damage counts as spell power at the profile's share for that school: the simulator's own ratio for simulated profiles (Balance: Arcane 0.68, Nature 0.32), and for estimates the profile's school in full, with Destruction and Demonology split as described above.
5. **Ratings:** generic and appropriate spell/melee/ranged aliases use the greatest matching value once. Caps are not simulated: Hit keeps its weight past the cap.
6. The candidate must have useful stats for its class/spec to win on score. Stamina on an otherwise irrelevant caster item does not make it a Warrior damage upgrade. Item level and rarity alone never make an upgrade.
7. The score difference is turned into a verdict tier (see Verdict tiers below). Only a clear or minor upgrade counts as an upgrade; anything within 3% either way is a sidegrade.
8. **Wands:** a wand adds its DPS to the score once for Priests, Mages and Warlocks, because no guide or preset weighs it and the rotation recommends Shoot: at `1` per DPS on an estimate's scale and `0.15` on a simulated caster's. Stats normally outrank a small DPS gain. This is an Everfrost heuristic, and it is not one of the editable weights.
9. **Armour:** armour counts for every spec, on armour pieces and shields only (a weapon's armour is never credited), at the profile's armour weight per point. A profile that *ranks* Armour (the tank presets and estimates, and the starter lists) treats it as one of its stats. For every other spec it is extra credit on top of the stats: `0.1` per point for an estimate, and the levelling allowance (`0.005` to `0.02`) for a simulated profile. So a clearly better-armoured piece can win despite a small stat loss ("More armour (+300) outweighs the stats it gives up"), and a piece with far less armour can lose despite a small stat gain. The reason line says when armour decided the result. Two limits remain from 0.6.6: with equal stats, more armour is reported as "More armour, no useful stats lost"; and a candidate with no useful stats can only replace an item that also has none, and only when nothing is lost on stats, so Stamina and armour together still cannot stand in for lost Strength.
10. **Off-hand weapons:** where a preset weighs off-hand DPS separately (Fury 2.66 against 12.59 in the main hand; the Rogue trees; Survival melee), a weapon compared for the off-hand slot uses that weight, as does an off-hand a two-hander would displace. Arms is measured with a two-hander, so off-hand DPS is worth nothing to it. Estimates score both hands alike.
11. **Equip effects (tooltip):** passive effects written on the tooltip are read as stats when the client's item stats leave them out: "Equip: Increases damage and healing done by magical spells and effects by up to N" (spell power), "...healing done by spells and effects..." (healing), "...damage done by Fire spells and effects..." (that school), attack power and ranged attack power, and "Restores N mana per 5 sec". The larger of the tooltip's and the client's value is used, so nothing is counted twice. Tank and rating lines are read too: "Increased Defense +N", "...block value of your shield by N", "...chance to block/dodge/parry... by N%", and "...chance to hit / critical strike (with spells) by N%" (one point per percent). Only lines starting "Equip:" count. "Use:", "Chance on hit:" and any "Equip:" line none of these patterns read are **never given a score**: the item is marked as having an unscored effect, the tooltip says so ("Its Use effect can't be scored; judge that part yourself"), and an item whose only value is such an effect is left "Not scored" rather than called a downgrade. An equipped item's unscored effect is also mentioned when something would replace it. The wording is matched in English only.

Amounts matter: a heavier stat does not automatically beat an arbitrarily large quantity of a lighter one. The estimates are **not official Icy Veins numerical weights** or simulation results, and neither kind of weight is a guarantee of improved DPS, healing or survival: a preset's weights describe that preset's gear, talents and fight, and move as your own gear changes.

Weapon guides also value damage per hit and often slower weapons. This first gear feature uses DPS where the client exposes it and does **not** model speed, swing timing or normalized ability damage. Inspect those details manually. Weapon DPS is only credited to the role's damage weapon: ranged for ranged Hunters, melee for melee specs. Casters' weapons and Hunter melee stat sticks get stats rather than inappropriate weapon-DPS credit.

## One engine, verdict tiers

Bag marks, item tooltips, Need/Greed hints, quest rewards and merchant marks all call the same function, `NS.Gear.Compare` in `Gear.lua`; nothing scores items any other way. Each result has a `verdict`:

| Verdict | Rule | Bag / merchant mark | Need/Greed | Tooltip heading |
| --- | --- | --- | --- | --- |
| Clear upgrade | at least **+10%**, or fills a confirmed empty slot | 2-pixel green border and the gain in bright green (`+48%`) | faint green ring on Need, breathing slowly | `Clear upgrade (+14%)` |
| Minor upgrade | **+3%** to under +10% | 1-pixel softer green border and the gain in softer green (`+5%`) | steady faint green ring on Need | `Minor upgrade (+5%)` |
| Sidegrade | within 3% either way | none | none | `Sidegrade` |
| Spec-dependent | not an upgrade for you, but a clear or minor one for another focus of your spec, or another talent tree of your class | none | none | `Better for Tank Threat` / `Better for Holy` |
| Not usable | level, armour/weapon type, class gear, Dual Wield, unique limit, or (for a shield spec) a held off-hand | none | faint grey ring on Greed | `Not usable` |
| Downgrade | 3% or more worse, or no stat your spec uses | none | faint grey ring on Greed | `Downgrade (-12%)` |
| Not scored | no talent tree, missing data, or an item whose only value is an effect that cannot be scored | none | none | `Not scored` |

The percentage is the score difference divided by the replaced item's score (or the whole displaced weapon set), with a floor of 1 point so a nearly empty item does not produce silly numbers; above +200% the tooltip says "over +200%". On the item's icon the same gain is written `+48%`, `>200%` past that, and `NEW` when the slot is empty or the worn item scores under one point (`G.GainText`). The thresholds live in `NS.gearTiers` (`clear=0.10`, `minor=0.03`). They are Everfrost estimates: 3% is about one point of a mid-priority stat on a typical levelling item, below which the stat-only model is not precise enough to call a winner.

A spec-dependent check looks at your spec's other focuses first and names one of those if it would take the item; only then other talent trees. It never runs for weapon-pair comparisons.

Tooltips stay short: the heading, then one or two lines of why (the specific reason, and the stat that decided it: "Better because it has more Stamina, your top priority.", "More Stamina, but less Strength.", "Your current item has more Spell power."), then any notes (unscored effects, "Compared with the weaker of your two rings.", the pair partner, quest notes), then the active priority order named by its focus ("Tank Threat priority: Spell power > Weapon DPS > ..."). Loot-roll tooltips add `/ Need` or `/ Greed`. The raw score line and the long disclaimer are gone.

## Scoring focus

Some specs can be scored for a chosen goal. The default is the spec's profile from the tables above. A focus is either another wowsims preset (Protection Warrior's Tank Threat is the simulator's Offensive preset; Bear Balanced is its Bear preset) or an Everfrost estimate that reorders the stats for one goal. Settings sets `NS.Gear.focus` through `NS.Gear.SetFocus(key)`; an unknown or missing key uses the default. Below level 10 the starter list still applies.

| Spec | Focus (key) | Order used |
| --- | --- | --- |
| Protection Paladin | **Balanced Tank** (`balanced`, default) | guide order: Stamina > Spell power > Strength > Block > Hit > Defence > Armour > Intellect > Agility |
| Protection Paladin | Tank Survivability (`survival`) | Stamina > Armour/Defence > Block/Dodge/Parry > Agility > Strength > Spell power > Hit > Intellect |
| Protection Paladin | Tank Threat (`threat`) | Spell power (Holy) > Weapon DPS > Strength/Attack power > Hit > Stamina > Crit > Block > Defence/Armour > Intellect |
| Protection Paladin | Solo Levelling (`solo`) | Weapon DPS > Spell power > Strength/Attack power > Stamina > Crit/Hit > Intellect/MP5 > Armour > Block |
| Protection Warrior | **Balanced Tank** (`balanced`, default) | wowsims Pre-BiS Balanced |
| Protection Warrior | Tank Survivability (`survival`) | Stamina/Armour > Defence > Block/Dodge/Parry > Agility > Strength/Attack power > Weapon DPS > Hit |
| Protection Warrior | Tank Threat (`threat`) | wowsims Pre-BiS Offensive |
| Protection Warrior | Solo Levelling (`solo`) | Weapon DPS > Strength/Attack power > Crit/Agility > Hit/Expertise > Stamina > Armour |
| Feral Druid | **Cat Damage** (`damage`, default) | wowsims Cat |
| Feral Druid | Bear Balanced (`balanced`) | wowsims Bear |
| Feral Druid | Bear Survivability (`survival`) | Armour/Stamina > Defence/Dodge > Agility > Strength/Attack power > Weapon DPS > Hit |
| Feral Druid | Bear Threat (`threat`) | Weapon DPS > Strength/Attack power > Hit/Expertise > Agility/Crit > Stamina > Armour > Defence/Dodge |

Keys are shared where the idea is the same, so a saved `survival` carries from a Paladin to a Warrior tank. The simulator finds weapon DPS valuable to Feral in both forms, so every Bear profile counts it (before November 25, 2026 the Bear estimates ranked none). Bears use no shield. Every other spec has only its guide profile, and `NS.GearFocusChoices` returns nil for it. Dodge and Parry ratings are now read from item stats (`ITEM_MOD_DODGE_RATING`, `ITEM_MOD_PARRY_RATING`) and count as useful tank stats.

## Two-handers and shields

- A two-hander is always compared with the **whole set it would displace**: main hand plus off-hand. A shield's armour, block value and stats all count in that set, for every spec (armour as ranked or extra credit, as in Armour above).
- **Shield specs** (both Protection trees, every focus) never see a two-hander as an upgrade, however the numbers fall, including the Threat focus that ranks weapon DPS: the tooltip says "Protection needs a shield, so a two-hander is never an upgrade". If Retribution or Arms/Fury would take it, the verdict is "Better for Retribution" instead of a plain downgrade. A held off-hand (book, orb) or off-hand-only weapon is "Not usable" for a shield spec, with the same check for other trees.
- One-hand plus off-hand candidates against an equipped two-hander still search the bags for a legal partner (see below).

## Equipped slots and eligibility

- Single-slot equipment compares with the equipped item in that slot. Rings/trinkets compare with both slots and use the best valid replacement, which is the weaker of the two you wear (unique limits allowing); the tooltip says "Compared with the weaker of your two rings/trinkets".
- An empty slot must be confirmed by the inventory API. Unavailable metadata for an occupied slot remains unknown and never becomes a free upgrade.
- Two-handed weapons include both displaced main-hand and off-hand scores. Shield specs never take a two-hander and keep the shield slot (see Two-handers and shields).
- **Added in consolidated 0.5.1:** against an equipped two-hander, one-hand/off-hand candidates search all carried bag slots for a legal partner. The two item scores are added and compared with the displaced setup. The best valid pair for each candidate is used, so both items in an estimated upgrade can glow. The tooltip identifies the partner and warns that both items must be equipped. A loot candidate can pair with an item already carried, but never with another unowned loot candidate.
- Pair checks enforce level/class/usability, hand restrictions, learned Dual Wield, tank shields and exposed unique-equipped limits across the final loadout. A physical bag entry cannot supply both hands; two carried copies may, if eligible and not uniquely restricted. Missing partners remain unknown. Unloaded partner data prevents a non-upgrade verdict while a better pair could be unresolved; a fully known upgrade can still be shown.
- Pair scores use the existing additive item-stat estimate. A preset's weights describe one weapon layout (Fury's a dual-wield pair, Arms' a two-hander), so comparing a two-hander with a pair across layouts is rougher than comparing like with like. Weapon speed, dual-wield damage penalties and hit penalties are not simulated, so an estimated pair upgrade is not a prediction of actual damage.
- Generic one-hand weapons can compare against both hands only with Dual Wield learned. Mutilate builds require daggers. Plate (Warrior, Paladin) and mail (Hunter, Shaman) are allowed from level 40. Armour and weapon type checks use the nine classes' level-1–60 proficiency limits; shields and class relics are checked separately. The unreleased eligibility fix reads `IsEquippableItem` where available. `IsUsableItem` describes the use action and must not gate passive equipment. The equippable flag does not prove all player-specific requirements; class and level checks remain separate, and weapon-training requirements still need client verification.
- Unique-equipped categories and limits are checked when exposed by the item API. Category -1 (plain Unique-Equipped) limits copies of the same item.
- Consumables, trade goods, unsupported slots and incompatible equipment receive a non-upgrade/irrelevant result. Missing or secret metadata produces an unknown result.

## Borders, tooltips and combat

- The standard backpack and carried bag slots are scanned; banks and other characters are excluded.
- **Restrained marks (replaces the 0.5.2–0.8.0 pulsing glow).** The old look stacked an outsized additive glow, a rarity-coloured outline and a pulse on every bag upgrade and both roll buttons. Now: a clear upgrade gets a 2-pixel green border drawn just inside the slot's edge plus its gain as a bright green percentage in the icon's bottom-right corner, where a stack count would sit (equipment never stacks), in the game's outlined number font; a minor upgrade gets a 1-pixel softer green border and a softer green percentage. This replaced the native `bags-greenarrow` on November 25, 2026 at the user's request, so a mark says how much better, not only that it is better. Quest reward icons and vendor buttons show the same percentage; sidegrades, spec-dependent items, downgrades and unusable items get no mark in bags. Nothing pulses in bags, nothing is drawn past the button, and rarity no longer changes the colour (the item's own border already shows rarity). Colours and sizes are in `NS.gearMarkStyles`.
- **Need/Greed:** roll buttons are round, so they get a faint ring (the native action-button border art, at 70% for a clear upgrade, 45% for a minor one) instead of a square. Only a clear upgrade's Need ring breathes, slowly (55% to 100% over 1.6 seconds, eased). Downgrades and unusable items get a steady 30% grey ring on Greed; sidegrades and spec-dependent items get nothing. The option must be enabled and available; an unavailable Need option never turns an upgrade into a Greed hint. Nothing covers the roll buttons' icons, the item text or the tooltip.
- Each button's mark widgets (four edge textures, then a ring, percentage or label only when first needed) are created once, outside combat, and reused when bag buttons and roll frames are recycled, so no overlay is ever duplicated. Repainting the same style keeps a running pulse going.
- The talent window's next-pick highlight (`NS.Glow`) now uses the same gentle ring.
- Native item tooltip post-processing restores the Everfrost lines when the game refreshes a hovered tooltip, with a `SetBagItem` fallback on older APIs. Pair upgrades say `(equip both)` and name the required partner.
- Tooltips show the estimate, comparison, priority order and a reminder to check effects and group rules. Pair comparisons also show the required partner and combined score.
- The addon never calls a roll or equip action. It decorates existing controls; all choices remain manual.
- Item data, class/spec context and equipped comparisons refresh outside combat. Combat marks results pending and hides stale suggestions. New loot during combat waits until combat ends. No combat resources or proc values are inspected.
- Item-data events retry unresolved comparisons. Bag refreshes, equipment changes, talent/spec changes, skill changes and role changes invalidate results.
- Native bag frames, classic bag hooks and modern combined bags are supported where available. Third-party bag/loot replacements require their own integration.

`/everfrost gear` prints the active order. `/everfrost gear on` and `off` persist per character; `/everfrost refresh` requests a new scan. Hiding the rotation panel does not disable gear highlights.

## Quest rewards, merchants and empty slots

- **Quest choices:** when a quest offers two or more item choices, the clear or minor upgrade with the largest score gain gets a thin border around its icon (not its name) and a small "Recommended" word in the button's bottom-right corner. Other upgrades within 85% of its gain (`NS.gearCompetitive`) are a close call: the recommended reward's tooltip says "close call with N other reward(s)" and theirs say "Close to the recommended reward". A sidegrade is never recommended. If no choice is an upgrade, the one that sells for the most gets a thin gold border labelled "Best sell value" (gold, not an upgrade). Nothing is marked until every choice's data has loaded. The addon never picks a reward.
- **Quest choices by role:** every reward is also scored for your spec's other focuses and your class's other talent trees. When one of those would pick a different reward, that reward's tooltip says "Best for healing.", "Best for tank threat.", "Best for Retribution damage." and so on, and your recommended reward says what it is best for ("Best for tanking.", "Best for solo damage."). When every role agrees, no such lines appear.
- **Merchants:** upgrades on the current buy page get the same thin border as bags if `CanAffordMerchantItem` doesn't say no. Upgrades you can't afford have no mark, and the tooltip says so. The buyback tab is ignored. The addon never buys anything.
- **Plain-word reasons:** tooltips name the most important stat that decides a comparison, name the trade-off for a sidegrade, or say the slot is empty. Two-handers replacing a main hand and off-hand say they were compared with both.
- **Empty slots:** the Gear Upgrades page counts confirmed empty armour slots (head, shoulders, chest, waist, legs, feet, wrists, hands, back). The panel caption mentions a missing main-hand weapon. Unread equipment never counts as empty.

Combat hides these marks and they return afterwards, and `/everfrost gear off` turns them off.

## Limits and verification

Proc/on-use effects, set bonuses, enchants, sockets, weapon speed, racial bonuses, caps, profession-specific scaling and unique item interactions are not scored. A stat-only estimate can disagree with the real better item. Respect group loot rules and inspect the item's effects before rolling.

`npm test` covers eligibility, stat priorities changing the same comparison, paired slots, unique limits, weapon-pair upgrades/non-upgrades/ties, companion selection, physical-copy identity, Dual Wield and shield restrictions, complete displaced two-hand setup, partners in later bags, missing stats, asynchronous partner loading/removal, secret-value rejection, combat deferral, reused bag buttons, canceled rolls and disabled Need options. `tests/gear-verdicts.cjs` covers the tier thresholds, sidegrade and downgrade wording, unusable items, spell power, weapon DPS, rings and trinkets against the weaker slot, every focus list and order, focus changing a verdict, spec-dependent naming (own focus before another tree), armour under Survivability, Protection two-handers against main hand plus shield in every focus, shield armour counting against a Retribution two-hander, held off-hands, Feral Cat versus Bear, and rescans. `tests/gear.cjs` also covers the thin borders by tier, unmarked sidegrades, roll rings, widget reuse, unscored Use/proc/Equip effects, close quest calls, "Best for" role notes and the gold sell-value label. `npm run build` uses Node's standard library to package only the addon folder; the archive is independently checked against source bytes.

`tests/gear-verdicts.cjs` also covers where each profile's weights come from (17 simulated, 10 estimated), the rating-per-1% units, a sample of preset values, school shares, the levelling allowance, the weight-derived priority line, off-hand weights, and custom weights (saving, the customised copy, refused values, reset, per-focus changes, damaged saved data). `tests/gear.cjs` covers the percentage label (text, colour, corner, reuse, hiding in combat) and `tests/check.cjs` the stat weights page.

These are simulated tests. Whether Forever's item stats report Hit and Crit as one point per percent (the tooltip wording says percent; if the client's item stats report rating points instead, those stats would be overvalued tenfold), the expertise token, how the green percentage and the `NumberFontNormalSmall` font sit on a real bag slot, and the stat weights page's edit boxes (`InputBoxTemplate`) all need a look in game. Actual Forever item-stat tokens (including the Dodge/Parry names), native frame hooks, how the thin borders, roll rings and the quest "Recommended" label sit on real buttons (the label's corner could touch a long two-line reward name), the `GameFontNormalSmall` font object and behavior after login/training/reload still need verification in the game client. No game installation is performed by the build or tests.

API references: [Blizzard item API source](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua), [native bags](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua), [native loot rolls](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/GroupLootFrame.lua).
