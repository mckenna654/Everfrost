# Everfrost — Spell Rotation & Gear Upgrade Guidance

**Built with new players in mind.** Everfrost started while playing alongside brand-new players and people trying WoW for the first time. It keeps basic spell rotation references and gear stat priorities close at hand while you learn your class.

A lightweight, standalone addon for **WoW Forever 1.60.1**, covering **levels 1–60, nine classes and 27 talent trees**. Built with AI assistance. No third-party addon libraries are required.

## What's new in 0.8.0

- **Talent recommendations:** Everfrost now knows the Icy Veins levelling talent build for all 27 trees, point by point from level 10 to 60. In the talent window the talent to take next glows gold, and each talent's tooltip says how many points the build puts there and at which levels. The panel's hover text, the Specialisation settings page and `/everfrost talents` name your next talent. `/everfrost talents off` turns it off. Everfrost never spends points for you.
- **Resizable panel:** drag the corner of the rotation panel to make it bigger or smaller.

## Included from 0.7.0

- **Levels 31 to 60:** guides and gear hints now run to level 60, following Icy Veins' updated levelling guides. Each new ability shows once you've learned it.
- **Armour counts for every spec,** and plate or mail counts as wearable from level 40.
- **Equip effects count:** "Increases damage and healing done by magical spells and effects" and similar passive lines are scored (English clients).
- **Tidier upgrade highlight:** a thin outline on the slot's edge and a gentle pulse; Need and Greed buttons pulse without a box around them.
- **Key binding** to show or hide the panel, and new characters start with your panel size and opacity.
- **Smoother at login and when zoning.**

## Included from 0.6.9

- **Clearer spec menu note:** below level 10, the Choose a Spec menu now says "Full stat priorities need talents."

## Included from 0.6.8

- **Gear hints from level 1:** below level 10, each class uses a short starter stat list. These are Everfrost's own estimates, not guide rankings. Talent-based priorities still start at level 10.
- **Best quest reward:** quest screens mark the best choice, or the one that sells for the most if none is an upgrade. You still pick the reward.
- **Merchant upgrades:** vendors highlight upgrades you can afford, and tooltips say when you can't yet.
- **Plain-word tooltips:** for example, "Better because it has more Strength".
- **Empty slot reminders:** settings counts empty armour slots, and the panel mentions it if no weapon is equipped.

## Included from 0.6.7

- **Need/Greed highlights:** fixed so they reach Forever's loot-roll buttons, and hiding the UI no longer removes the highlight from an open roll.
- **Fairer gear scores:** Attack Power now counts properly for Agility specs such as Rogues, plain wands count for Priests, Mages and Warlocks, and a second copy of a Unique-Equipped item is no longer flagged as an upgrade.
- **Steadier bags:** bag buttons keep their glow when bags open, the glow keeps pulsing through bag changes, and rescans do less repeated work.
- **Tidier interface:** the Survival role button stays hidden until it can change something, and the interface uses Australian spelling.

## Included from 0.6.6

- **Armour upgrades:** more armour now counts as an upgrade when you lose no useful stats, so a plain mail belt beats a plain leather one instead of showing "No useful stats". These items also highlight **Need** on group loot. (From 0.7.0 armour counts in every comparison.)
- **Green up arrow:** bag upgrades now show a green up arrow alongside the glow.

## Included from 0.6.5

- **Tidier text:** the panel header and settings footer share one format ("Elemental Shaman", "Level 18 / Auto", "Shaman / Level 18"), help text uses two consistent greys, and the "start at level 10" note no longer repeats in item tooltips once your gear is being scored.

## Included from 0.6.4

- Brings the 0.6.3 improvements below to CurseForge. The 0.6.3 upload was rejected for a packaging mistake (an extra repository file); addon behaviour is the same.

## Included from 0.6.3

- **Subtlety Rogue gear fix:** Attack Power was counted twice and could beat Agility. Upgrades now follow the guide's order, with Agility above Attack Power.
- **Lighter background work:** bags are no longer rescanned whenever item details load for characters whose gear isn't scored yet (below level 10 or no talent tree). Turning gear highlights off now skips item reading entirely.

## Included from 0.6.2

- **Cleaner specialisation menu:** the panel title opens **Choose a Spec**, with compact single-line choices. Automatic shows the detected tree inline. Repeated descriptions and the generic saved-choice footer are removed; level-10 and combat notices appear only when relevant.

## Included from 0.6.1

- **Adjustable panel opacity:** open `/everfrost` → Rotation Panel and choose 10%–100%. Changes apply immediately and save per character. `/everfrost opacity 60` sets 60%; settings, guide menus and tooltips stay readable.
- **Native WoW styling:** the compact rotation reference now uses WoW dialog textures, gold title text, standard buttons and quickslot spell borders. Position, size and guide choices are preserved; Reset position & size retains opacity.

## Included from 0.6.0

- **Native-style settings:** type `/everfrost` or use the minimap button or the game's AddOns settings launcher. Specialisation, Rotation Panel and Gear Upgrades tabs keep the controls together.
- **Clearer upgrade hints:** a prominent border fades in and out in the item's rarity colour. Tooltips show **UPGRADE**, the estimated score change and any required weapon partner. Passive equipment is no longer rejected for lacking a usable action.
- **Levelling gear guidance from level 10:** keep the general Levelling spell guide while the active talent tree with the most points determines your gear priorities. Manual specialisation choices can override detection. Talent-based priorities start at level 10; spell guides remain available from level 1.
- **Corrected Forever talent detection:** use the native talent window's trait-group totals, refresh after talent changes and show the detected split in settings. Ties, unspent points and unavailable data leave Levelling gear unscored.

## Spell reference panel

- Learned-spell-aware ability references using your trained ranks, with short hover guidance.
- Automatic class, level and talent-tree detection, plus Automatic, Levelling and manual specialisation choices.
- Single-target/AoE views and supported healing, Feral and Survival role views.
- Compact, movable panel with saved position, visibility, locking and size; native cooldown sweeps where supported.

This is a **basic reference**, not a live next-cast queue or full class guide. It does not choose abilities from combat resources, target health or procs, and it never casts for you.

## Gear upgrades and Need/Greed

Standard bag items glow and show a green up arrow when their estimated stat score beats an equipped replacement. Below level 10 this uses a simple starter priority for your class; from level 10 it uses your talent tree and guide-based priorities. Tooltips explain why in plain words. Armour counts for every spec, and passive "Equip:" effects such as extra spell damage and healing are scored too. Hover for the comparison and stat order. Rings and trinkets consider both slots. Complete one-hand/off-hand combinations can compare against two-handers; pair tooltips name the partner, and **both items must be equipped** for that recommendation to apply.

Quest screens mark the best reward choice, or the one that sells for the most if none is an upgrade. Merchants highlight upgrades you can afford. You still choose and buy for yourself. Settings counts empty armour slots, and the panel reminds you if no weapon is equipped.

Standard dungeon and raid loot-roll windows highlight **Need** for estimated upgrades and **Greed** for known non-upgrades or class-irrelevant items. Disabled choices are respected. You choose and click the roll, following your group's loot rules. Missing or restricted data stays unscored; refreshes defer during combat. Custom bag/loot replacements are not integrated.

Priorities are informed by [Icy Veins Forever guides](https://www.icy-veins.com/wow-forever/) and manually maintained. The 27 stat orders were checked on November 11, 2026. Numeric weights are Everfrost estimates, not Icy Veins simulation weights or guaranteed best-in-slot results. Weapon speed, dual-wield penalties, procs, set bonuses, enchants, sockets and hit caps are not simulated.

## Getting started

Install through CurseForge or extract the release ZIP's `Everfrost` folder into `Interface/AddOns` while the game is closed. Keep the folder and saved-variable names as Everfrost; existing Everfrost preferences remain per character.

- `/everfrost` — open settings.
- `/everfrost show` — show the rotation reference.
- `/everfrost gear` — print the current stat order; add `on` or `off` to toggle hints.
- `/everfrost minimap on` — restore a hidden minimap button.
- `/everfrost refresh` — refresh cached metadata outside combat.
- `/everfrost status` — report class/spec/level, cached talent totals and detection source.

Left-click the minimap logo for settings, right-click to toggle the reference panel, or drag it around the minimap. Settings includes guide/role selection, a 60%–200% panel-size slider, gear controls and a bag rescan button.

## Releases and verification

The original **0.5.0** introduced gear guidance. Consolidated **0.5.1** includes the guide selector and complete weapon-pair comparisons. **0.6.0** adds the settings window, rarity-colour pulse, clearer tooltips, level-10 guidance and native talent-detection fixes. **0.6.1** adds panel opacity controls and native WoW panel styling. **0.6.2** tidies the specialisation picker into a compact single-line menu. **0.6.3** fixes Subtlety Rogue Attack Power scoring and reduces background bag scans; it reached CurseForge as **0.6.4** after a packaging fix. **0.6.5** tidies status text, grey text and repeated tooltip notes. **0.6.6** counts more armour as a tie-break and adds a green up arrow to bag upgrades. **0.6.7** fixes Need/Greed highlights on Forever's loot-roll buttons, bag tracking and several gear-score cases. **0.6.8** adds starter priorities below level 10, quest reward and merchant marks, plain-word tooltips and empty slot reminders. **0.6.9** clarifies the spec menu note below level 10.

**0.7.0** extends guides and gear hints to level 60, counts armour and Equip effects, and tidies the upgrade highlight. **0.8.0** adds talent recommendations in the talent window and a resizable panel.

Lua 5.1 syntax and simulated-client regression tests pass. User testing confirmed the passive-equipment glow fix, rarity pulse, settings layout, armour tie-break and green arrow. The 0.8.0 talent recommendations and resize corner, the 0.7.0 changes (levels 31–60, armour and Equip-effect scoring, the new highlight) and the 0.6.8 quest and merchant marks have not yet been checked in game. English guidance; some Forever-specific spells depend on English spellbook names.

**MIT licensed. Third-party addon-manager distribution is enabled.** Everfrost is independent and is not affiliated with or endorsed by Blizzard, Icy Veins or OpenAI.

[GitHub source and full documentation](https://github.com/mckenna654/Everfrost) · [Latest GitHub release](https://github.com/mckenna654/Everfrost/releases/latest) · [Report an issue](https://github.com/mckenna654/Everfrost/issues) · [Gear scoring details](https://github.com/mckenna654/Everfrost/blob/main/docs/GEAR.md)
