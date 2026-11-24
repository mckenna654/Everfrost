# Gear priorities and upgrade highlights

Everfrost gives estimated gear comparisons for levels 1–60, with talent-based priorities from level 10. **The orders below were re-read on November 11, 2026** from the Stats section of each levelling guide, after the guides' level 60 update; Hit, and for melee Expertise, keep the place the stat pages give them where a levelling guide leaves them out as rare on early gear. Demonology now splits school damage evenly between Fire and Shadow, and Destruction credits Fire in full and Shadow at half. (First added in 0.5.0 for levels 1–30: Stat and gearing sections of all 27 [Icy Veins Forever guides](../addon/Everfrost/SOURCES.md) were checked on October 20, 2026. Rotation rules retain their separate October 15 review. Source URLs are stored on every gear profile.)

## Stat audit

The following orders adapt the current guides. Equal-ranked stats share a group. Some guides describe beta stats rather than calibrated weights; none of these lists supplies a universal conversion between one point of two different stats.

| Class | Tree | Guide order used |
| --- | --- | --- |
| Paladin | Holy | Healing power > Intellect > MP5 > Crit > Haste > Spirit |
| Paladin | Protection | Stamina > Spell power > Strength > Block > Hit > Defence > Armour > Intellect > Agility |
| Paladin | Retribution | Weapon DPS > Hit/Expertise > Spell power > Intellect > Crit > Strength > Agility > Stamina > Spirit |
| Hunter | Beast Mastery | Weapon damage > Hit > Agility > Crit > Intellect > Spirit > Stamina |
| Hunter | Marksmanship | Weapon damage > Hit > Agility > Crit > Intellect > Spirit > Stamina |
| Hunter | Survival | Weapon damage > Hit > Agility > Crit > Intellect > Spirit > Stamina |
| Mage | Arcane | Spell power > Intellect > Spirit > Crit > Hit > Stamina > MP5 |
| Mage | Fire | Spell power > Crit > Intellect > Spirit > Hit > Stamina > MP5 |
| Mage | Frost | Hit > Spell/Frost damage > Crit > Spirit > Intellect > Stamina |
| Warrior | Arms | Weapon damage > Hit/Expertise > Agility/Crit > Strength/Attack power > Stamina |
| Warrior | Fury | Weapon damage > Hit/Expertise > Strength/Attack power > Agility/Crit > Stamina |
| Warrior | Protection | Weapon damage > Hit/Expertise > Strength/Attack power > Agility/Crit > Armour/Stamina > Defence/Block |
| Rogue | Assassination | Weapon damage > Hit/Expertise > Agility > Crit > Strength > Stamina |
| Rogue | Combat | Weapon damage > Hit/Expertise > Agility > Crit > Strength > Stamina |
| Rogue | Subtlety | Weapon damage > Hit/Expertise > Agility > Attack power > Crit > Strength |
| Priest | Discipline | Healing power > MP5 > Intellect > Spirit > Crit |
| Priest | Holy | Healing power > MP5 > Spirit > Intellect > Crit |
| Priest | Shadow | Spell power > Crit > Hit > Intellect > Spirit > Stamina > MP5 |
| Warlock | Affliction | Spell power > Crit > Spirit > Intellect/Stamina > Hit > Haste |
| Warlock | Demonology | Spell power > Crit > Hit > Intellect/Stamina > Spirit > Haste |
| Warlock | Destruction | Spell power > Hit > Crit > Intellect/Stamina > Spirit > Haste |
| Druid | Balance | Intellect > Spell power > Crit > Haste > Spirit > MP5 |
| Druid | Feral | Weapon DPS > Hit/Expertise > Crit > Agility > Strength/Attack power > Stamina |
| Druid | Restoration | Healing power > Intellect > Crit > Haste > Spirit > MP5 |
| Shaman | Elemental | Spell damage > Crit > Hit > Intellect > MP5 > Spirit > Stamina |
| Shaman | Enhancement | Weapon DPS > Hit/Expertise > Intellect > Strength > Spirit > Agility > Crit > Spell power > Stamina |
| Shaman | Restoration | Healing power > Crit > Intellect > Spirit > MP5 > Stamina |

The Druid caster guides describe beta stats and emphasize Intellect and spell/healing power. Feral shares a base order for Cat and Bear; the guide notes that survival needs can change tank choices. Hunter Survival uses Marksmanship's ranged order until its melee requirements are met or when the RANGED override is selected. A healer's DAMAGE view changes rotation guidance, while gear retains that selected healer specialisation's priorities.

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

1. For an order of N groups, each stat in group R gets weight `N - R + 1`.
2. Score is the sum of each available stat amount times its weight. Relevant weapon DPS is scaled by `12`, an Everfrost heuristic so low-level weapon DPS isn't lost among the other quantities. Armour is scored separately (see Armour below).
3. Physical attack power uses its explicit weight when listed, or half the higher of its Strength or Agility weight. Hunter ranged AP and general AP use the larger value rather than double counting.
4. General spell power and healing aliases are not counted twice. For healing, the larger of spell power or healing power receives healing credit. School-specific damage receives credit only for the profile's school. Destruction splits Fire/Shadow credit evenly and Balance splits Nature/Arcane credit evenly; these splits are explicit approximations, not measured damage distributions. Affliction and Demonology use Shadow, Elemental uses Nature, and Paladin uses Holy.
5. Generic and appropriate spell/melee/ranged rating aliases use the greatest matching value once. Hit/crit/haste ratings are used as exposed by the client; no level-dependent conversion to percentages or caps is simulated.
6. The candidate must have useful stats for its class/spec to win on score. Stamina on an otherwise irrelevant caster item does not make it a Warrior damage upgrade. Item level and rarity alone never make an upgrade.
7. The score difference is turned into a verdict tier (see Verdict tiers below). Only a clear or minor upgrade counts as an upgrade; anything within 3% either way is a sidegrade.
8. A wand adds its DPS to the score once for Priests, Mages and Warlocks, because no guide ranks it and the rotation panel recommends Shoot. Stats normally outrank a small DPS gain. This is an Everfrost heuristic.
10. **Equip effects (tooltip):** passive effects written on the tooltip are read as stats when the client's item stats leave them out: "Equip: Increases damage and healing done by magical spells and effects by up to N" (spell power), "...healing done by spells and effects..." (healing), "...damage done by Fire spells and effects..." (that school), attack power and ranged attack power, and "Restores N mana per 5 sec". The larger of the tooltip's and the client's value is used, so nothing is counted twice. Tank and rating lines are read too: "Increased Defense +N", "...block value of your shield by N", "...chance to block/dodge/parry... by N%", and "...chance to hit / critical strike (with spells) by N%" (one point per percent, as the client's own item stats report them). Only lines starting "Equip:" count. "Use:", "Chance on hit:" and any "Equip:" line none of these patterns read are **never given a score**: the item is marked as having an unscored effect, the tooltip says so ("Its Use effect can't be scored; judge that part yourself"), and an item whose only value is such an effect is left "Not scored" rather than called a downgrade. An equipped item's unscored effect is also mentioned when something would replace it. The wording is matched in English only.
9. **Armour:** armour counts for every spec, on armour pieces and shields only (a weapon's armour is never credited). Each point is worth `0.1`. A profile that ranks Armour (the tanks and the starter lists) multiplies that by Armour's weight and treats it as one of its stats; for every other spec it is extra credit on top of the stats. So a clearly better-armoured piece can now win despite a small stat loss ("More armour (+132) outweighs the stats it gives up"), and a piece with far less armour can lose despite a small stat gain. The reason line says when armour decided the result. Two limits remain from 0.6.6: with equal stats, more armour is reported as "More armour, no useful stats lost"; and a candidate with no useful stats can only replace an item that also has none, and only when nothing is lost on stats, so Stamina and armour together still cannot stand in for lost Strength. The `0.1` rate is an Everfrost heuristic: about 50 armour to one point of a mid-priority stat. Weapons and two-hander pair comparisons are unaffected.

Amounts matter: an earlier-ranked stat does not automatically beat an arbitrarily large quantity of a later-ranked stat. These weights are deliberately transparent and are **not official Icy Veins numerical weights**, simulation results, or guarantees of improved DPS/healing/survival.

Weapon guides also value damage per hit and often slower weapons. This first gear feature uses DPS where the client exposes it and does **not** model speed, swing timing or normalized ability damage. Inspect those details manually. Weapon DPS is only credited to the role's damage weapon: ranged for ranged Hunters, melee for melee specs. Casters' weapons and Hunter melee stat sticks get stats rather than inappropriate weapon-DPS credit.

## One engine, verdict tiers

Bag marks, item tooltips, Need/Greed hints, quest rewards and merchant marks all call the same function, `NS.Gear.Compare` in `Gear.lua`; nothing scores items any other way. Each result has a `verdict`:

| Verdict | Rule | Bag / merchant mark | Need/Greed | Tooltip heading |
| --- | --- | --- | --- | --- |
| Clear upgrade | at least **+10%**, or fills a confirmed empty slot | 2-pixel green border and the native green arrow | faint green ring on Need, breathing slowly | `Clear upgrade (+14%)` |
| Minor upgrade | **+3%** to under +10% | 1-pixel softer green border, no arrow | steady faint green ring on Need | `Minor upgrade (+5%)` |
| Sidegrade | within 3% either way | none | none | `Sidegrade` |
| Spec-dependent | not an upgrade for you, but a clear or minor one for another focus of your spec, or another talent tree of your class | none | none | `Better for Tank Threat` / `Better for Holy` |
| Not usable | level, armour/weapon type, class gear, Dual Wield, unique limit, or (for a shield spec) a held off-hand | none | faint grey ring on Greed | `Not usable` |
| Downgrade | 3% or more worse, or no stat your spec uses | none | faint grey ring on Greed | `Downgrade (-12%)` |
| Not scored | no talent tree, missing data, or an item whose only value is an effect that cannot be scored | none | none | `Not scored` |

The percentage is the score difference divided by the replaced item's score (or the whole displaced weapon set), with a floor of 1 point so a nearly empty item does not produce silly numbers; above +200% the tooltip says "over +200%". The thresholds live in `NS.gearTiers` (`clear=0.10`, `minor=0.03`). They are Everfrost estimates: 3% is about one point of a mid-priority stat on a typical levelling item, below which the stat-only model is not precise enough to call a winner.

A spec-dependent check looks at your spec's other focuses first and names one of those if it would take the item; only then other talent trees. It never runs for weapon-pair comparisons.

Tooltips stay short: the heading, then one or two lines of why (the specific reason, and the stat that decided it: "Better because it has more Stamina, your top priority.", "More Stamina, but less Strength.", "Your current item has more Spell power."), then any notes (unscored effects, "Compared with the weaker of your two rings.", the pair partner, quest notes), then the active priority order named by its focus ("Tank Threat priority: Spell power > Weapon DPS > ..."). Loot-roll tooltips add `/ Need` or `/ Greed`. The raw score line and the long disclaimer are gone.

## Scoring focus

Some specs can be scored for a chosen goal. The default is always the guide order in the table above; the others reorder the same guide's stats and are Everfrost estimates, not guide rankings. Settings sets `NS.Gear.focus` through `NS.Gear.SetFocus(key)`; an unknown or missing key uses the default. Below level 10 the starter list still applies.

| Spec | Focus (key) | Order used |
| --- | --- | --- |
| Protection Paladin | **Balanced Tank** (`balanced`, default) | guide order: Stamina > Spell power > Strength > Block > Hit > Defence > Armour > Intellect > Agility |
| Protection Paladin | Tank Survivability (`survival`) | Stamina > Armour/Defence > Block/Dodge/Parry > Agility > Strength > Spell power > Hit > Intellect |
| Protection Paladin | Tank Threat (`threat`) | Spell power (Holy) > Weapon DPS > Strength/Attack power > Hit > Stamina > Crit > Block > Defence/Armour > Intellect |
| Protection Paladin | Solo Levelling (`solo`) | Weapon DPS > Spell power > Strength/Attack power > Stamina > Crit/Hit > Intellect/MP5 > Armour > Block |
| Protection Warrior | **Balanced Tank** (`balanced`, default) | guide order |
| Protection Warrior | Tank Survivability (`survival`) | Stamina/Armour > Defence > Block/Dodge/Parry > Agility > Strength/Attack power > Weapon DPS > Hit |
| Protection Warrior | Tank Threat (`threat`) | Weapon DPS > Hit/Expertise > Strength/Attack power > Crit/Agility > Stamina > Armour > Defence/Block |
| Protection Warrior | Solo Levelling (`solo`) | Weapon DPS > Strength/Attack power > Crit/Agility > Hit/Expertise > Stamina > Armour |
| Feral Druid | **Cat Damage** (`damage`, default) | guide order |
| Feral Druid | Bear Balanced (`balanced`) | Armour/Stamina > Agility > Strength/Attack power > Defence/Dodge > Hit/Expertise > Crit |
| Feral Druid | Bear Survivability (`survival`) | Armour/Stamina > Defence/Dodge > Agility > Strength/Attack power > Hit |
| Feral Druid | Bear Threat (`threat`) | Strength/Attack power > Hit/Expertise > Agility/Crit > Stamina > Armour > Defence/Dodge |

Keys are shared where the idea is the same, so a saved `survival` carries from a Paladin to a Warrior tank. Bear profiles rank no weapon DPS (forms ignore it) and use no shield. Every other spec has only its guide profile, and `NS.GearFocusChoices` returns nil for it. Dodge and Parry ratings are now read from item stats (`ITEM_MOD_DODGE_RATING`, `ITEM_MOD_PARRY_RATING`) and count as useful tank stats.

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
- Pair scores use the existing additive item-stat estimate. Weapon speed, dual-wield damage penalties and hit penalties are not simulated, so an estimated pair upgrade is not a prediction of actual damage.
- Generic one-hand weapons can compare against both hands only with Dual Wield learned. Mutilate builds require daggers. Plate (Warrior, Paladin) and mail (Hunter, Shaman) are allowed from level 40. Armour and weapon type checks use the nine classes' level-1–60 proficiency limits; shields and class relics are checked separately. The unreleased eligibility fix reads `IsEquippableItem` where available. `IsUsableItem` describes the use action and must not gate passive equipment. The equippable flag does not prove all player-specific requirements; class and level checks remain separate, and weapon-training requirements still need client verification.
- Unique-equipped categories and limits are checked when exposed by the item API. Category -1 (plain Unique-Equipped) limits copies of the same item.
- Consumables, trade goods, unsupported slots and incompatible equipment receive a non-upgrade/irrelevant result. Missing or secret metadata produces an unknown result.

## Borders, tooltips and combat

- The standard backpack and carried bag slots are scanned; banks and other characters are excluded.
- **Restrained marks (replaces the 0.5.2–0.8.0 pulsing glow).** The old look stacked an outsized additive glow, a rarity-coloured outline and a pulse on every bag upgrade and both roll buttons. Now: a clear upgrade gets a 2-pixel green border drawn just inside the slot's edge plus the native `bags-greenarrow` in the top-left corner (opposite the stack count); a minor upgrade gets a 1-pixel softer green border and no arrow; sidegrades, spec-dependent items, downgrades and unusable items get no mark in bags. Nothing pulses in bags, nothing is drawn past the button, and rarity no longer changes the colour (the item's own border already shows rarity). Colours and sizes are in `NS.gearMarkStyles`.
- **Need/Greed:** roll buttons are round, so they get a faint ring (the native action-button border art, at 70% for a clear upgrade, 45% for a minor one) instead of a square. Only a clear upgrade's Need ring breathes, slowly (55% to 100% over 1.6 seconds, eased). Downgrades and unusable items get a steady 30% grey ring on Greed; sidegrades and spec-dependent items get nothing. The option must be enabled and available; an unavailable Need option never turns an upgrade into a Greed hint. Nothing covers the roll buttons' icons, the item text or the tooltip.
- Each button's mark widgets (four edge textures, then a ring, arrow or label only when first needed) are created once, outside combat, and reused when bag buttons and roll frames are recycled, so no overlay is ever duplicated. Repainting the same style keeps a running pulse going.
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

These are simulated tests. Actual Forever item-stat tokens (including the Dodge/Parry names), native frame hooks, how the thin borders, roll rings and the quest "Recommended" label sit on real buttons (the label's corner could touch a long two-line reward name), the `GameFontNormalSmall` font object and behavior after login/training/reload still need verification in the game client. No game installation is performed by the build or tests.

API references: [Blizzard item API source](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua), [native bags](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua), [native loot rolls](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/GroupLootFrame.lua).
