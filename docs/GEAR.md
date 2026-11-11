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
7. A positive score difference greater than `0.01` counts as an estimated upgrade. Lower scores are non-upgrades.
8. A wand adds its DPS to the score once for Priests, Mages and Warlocks, because no guide ranks it and the rotation panel recommends Shoot. Stats normally outrank a small DPS gain. This is an Everfrost heuristic.
9. **Armour:** armour counts for every spec, on armour pieces and shields only (a weapon's armour is never credited). Each point is worth `0.1`. A profile that ranks Armour (the tanks and the starter lists) multiplies that by Armour's weight and treats it as one of its stats; for every other spec it is extra credit on top of the stats. So a clearly better-armoured piece can now win despite a small stat loss ("More armour (+132) outweighs the stats it gives up"), and a piece with far less armour can lose despite a small stat gain. The tooltip says how much of the score difference armour accounts for. Two limits remain from 0.6.6: with equal stats, more armour is reported as "More armour, no useful stats lost"; and a candidate with no useful stats can only replace an item that also has none, and only when nothing is lost on stats, so Stamina and armour together still cannot stand in for lost Strength. The `0.1` rate is an Everfrost heuristic: about 50 armour to one point of a mid-priority stat. Weapons and two-hander pair comparisons are unaffected.

Amounts matter: an earlier-ranked stat does not automatically beat an arbitrarily large quantity of a later-ranked stat. These weights are deliberately transparent and are **not official Icy Veins numerical weights**, simulation results, or guarantees of improved DPS/healing/survival.

Weapon guides also value damage per hit and often slower weapons. This first gear feature uses DPS where the client exposes it and does **not** model speed, swing timing or normalized ability damage. Inspect those details manually. Weapon DPS is only credited to the role's damage weapon: ranged for ranged Hunters, melee for melee specs. Casters' weapons and Hunter melee stat sticks get stats rather than inappropriate weapon-DPS credit.

## Equipped slots and eligibility

- Single-slot equipment compares with the equipped item in that slot. Rings/trinkets compare with both slots and use the best valid replacement.
- An empty slot must be confirmed by the inventory API. Unavailable metadata for an occupied slot remains unknown and never becomes a free upgrade.
- Two-handed weapons include both displaced main-hand and off-hand scores. Tank shield profiles reject two-handers and protect the shield slot.
- **Added in consolidated 0.5.1:** against an equipped two-hander, one-hand/off-hand candidates search all carried bag slots for a legal partner. The two item scores are added and compared with the displaced setup. The best valid pair for each candidate is used, so both items in an estimated upgrade can glow. The tooltip identifies the partner and warns that both items must be equipped. A loot candidate can pair with an item already carried, but never with another unowned loot candidate.
- Pair checks enforce level/class/usability, hand restrictions, learned Dual Wield, tank shields and exposed unique-equipped limits across the final loadout. A physical bag entry cannot supply both hands; two carried copies may, if eligible and not uniquely restricted. Missing partners remain unknown. Unloaded partner data prevents a non-upgrade verdict while a better pair could be unresolved; a fully known upgrade can still be shown.
- Pair scores use the existing additive item-stat estimate. Weapon speed, dual-wield damage penalties and hit penalties are not simulated, so an estimated pair upgrade is not a prediction of actual damage.
- Generic one-hand weapons can compare against both hands only with Dual Wield learned. Mutilate builds require daggers. Plate (Warrior, Paladin) and mail (Hunter, Shaman) are allowed from level 40. Armour and weapon type checks use the nine classes' level-1–60 proficiency limits; shields and class relics are checked separately. The unreleased eligibility fix reads `IsEquippableItem` where available. `IsUsableItem` describes the use action and must not gate passive equipment. The equippable flag does not prove all player-specific requirements; class and level checks remain separate, and weapon-training requirements still need client verification.
- Unique-equipped categories and limits are checked when exposed by the item API. Category -1 (plain Unique-Equipped) limits copies of the same item.
- Consumables, trade goods, unsupported slots and incompatible equipment receive a non-upgrade/irrelevant result. Missing or secret metadata produces an unknown result.

## Borders, tooltips and combat

- The standard backpack and carried bag slots are scanned; banks and other characters are excluded.
- Estimated bag upgrades receive a pulsing border in their rarity colour. Non-upgrades and unknown items have no added border.
- Version 0.6.0 adds a three-pixel outline and outer glow in the item's rarity colour, cached from `GetItemQualityColor` outside combat. Every layer fades from 18% to full brightness and back over 1.4 seconds. Repainting preserves the running animation; stale or disabled hints stop every layer. Unavailable/restricted rarity metadata falls back to neutral white without affecting scoring. Bag and loot-roll hints share this appearance. Upgrade tooltips start with `Everfrost: UPGRADE`; pair upgrades say `UPGRADE (equip both)` and name the required partner. Native item tooltip post-processing restores the lines when the game refreshes a hovered tooltip, with a `SetBagItem` fallback on older APIs.
- **0.6.6:** bag upgrades also show a steady green up arrow in the top-left corner, using the native `bags-greenarrow` atlas from Forever's `ContainerFrame.xml` at its own size. It appears and disappears with the glow, including in combat. Roll buttons keep the glow only.
- Armour tie-break upgrades state the armour gained in the tooltip and omit the score line.
- Standard group-loot frames use the same border on Need for upgrades or Greed for known non-upgrades/irrelevant items. The option must be enabled and available. An unavailable Need option does not turn an upgrade into a Greed recommendation.
- Tooltips show the estimate, comparison, priority order and a reminder to check effects and group rules. Pair comparisons also show the required partner and combined score.
- The addon never calls a roll or equip action. It decorates existing controls; all choices remain manual.
- Item data, class/spec context and equipped comparisons refresh outside combat. Combat marks results pending and hides stale suggestions. New loot during combat waits until combat ends. No combat resources or proc values are inspected.
- Item-data events retry unresolved comparisons. Bag refreshes, equipment changes, talent/spec changes, skill changes and role changes invalidate results.
- Native bag frames, classic bag hooks and modern combined bags are supported where available. Third-party bag/loot replacements require their own integration.

`/everfrost gear` prints the active order. `/everfrost gear on` and `off` persist per character; `/everfrost refresh` requests a new scan. Hiding the rotation panel does not disable gear highlights.

## Quest rewards, merchants and empty slots

- **Quest choices:** when a quest offers two or more item choices, the upgrade with the largest score gain gets the usual glow and green arrow. If none is an upgrade, the choice that sells for the most gets a gold glow and no arrow. Nothing is marked until every choice's data has loaded. The addon never picks a reward.
- **Merchants:** upgrades on the current buy page glow if `CanAffordMerchantItem` doesn't say no. Upgrades you can't afford have no glow, and the tooltip says so. The buyback tab is ignored. The addon never buys anything.
- **Plain-word reasons:** tooltips name the most important stat that decides a comparison, or say the slot is empty. Below level 10 the score line is hidden. Pair comparisons and two-handers replacing an off-hand show no single reason.
- **Empty slots:** the Gear Upgrades page counts confirmed empty armour slots (head, shoulders, chest, waist, legs, feet, wrists, hands, back). The panel caption mentions a missing main-hand weapon. Unread equipment never counts as empty.

Combat hides these marks and they return afterwards, and `/everfrost gear off` turns them off.

## Limits and verification

Proc/on-use effects, set bonuses, enchants, sockets, weapon speed, racial bonuses, caps, profession-specific scaling and unique item interactions are not scored. A stat-only estimate can disagree with the real better item. Respect group loot rules and inspect the item's effects before rolling.

`npm test` covers eligibility, stat priorities changing the same comparison, paired slots, unique limits, weapon-pair upgrades/non-upgrades/ties, companion selection, physical-copy identity, Dual Wield and shield restrictions, complete displaced two-hand setup, partners in later bags, missing stats, asynchronous partner loading/removal, secret-value rejection, combat deferral, reused bag buttons, canceled rolls and disabled Need options. `npm run build` uses Node's standard library to package only the addon folder; the archive is independently checked against source bytes.

These are simulated tests. Actual Forever item-stat tokens, native frame hooks, pulse rendering and behavior after login/training/reload still need verification in the game client. No game installation is performed by the build or tests.

API references: [Blizzard item API source](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua), [native bags](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua), [native loot rolls](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/GroupLootFrame.lua).
