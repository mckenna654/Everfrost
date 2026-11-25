# Changelog

## Unreleased

- **The HUD no longer jumps to the middle of the screen when you pick up a controller.** The controller layout has its own position, and until now it started in the middle whatever you had done with the HUD. It now starts where you put the keyboard layout.
- **Place each layout separately.** Settings → Controller has **Place keyboard HUD** and **Place controller HUD** buttons. Pick one and drag the HUD with the mouse: it stays on that layout, unlocked, until you press Done or close settings. Before this, touching the mouse switched the HUD to the keyboard layout, so the controller layout could not be moved on its own.
- **Much bolder Need and Greed marks.** The Need button gets a bright green glowing ring for an upgrade (pulsing for a clear one), and Greed a gold ring for an item you wouldn't wear. The item's icon in the roll window shows the same green border and percentage as an upgrade in your bags.
- **A talent pick you can't miss.** The next talent in the build now has a thick ice-blue outline, a pulsing glow and the word NEXT above it. The old thin gold outline looked like the game's own gold border on talents you already have points in.

## 0.10.0 — Measured stat weights and upgrade percentages

- **Measured stat weights.** Gear is now scored with numeric stat weights for your spec instead of a simple "this stat beats that one" order. Seventeen talent trees use the weights published by the [wowsims Forever simulator](https://wowsims.com/forever): Arms, Fury and Protection Warrior, all Rogue and Hunter trees, Retribution, all Priest trees, Balance, Feral (Cat and Bear), Elemental and Enhancement. They are level 60 raid values, so Everfrost adds a small allowance for Stamina and armour while levelling. No simulator publishes weights yet for Mage, Warlock, Holy and Protection Paladin, Restoration Druid or Restoration Shaman; those keep an estimate from the Icy Veins stat order, and say so.
- **A green percentage replaces the upgrade arrow.** Bag, vendor and quest-reward upgrades show how much better they are, such as `+48%`, in the icon's corner. An item for an empty slot says `NEW`.
- **Your own stat weights.** Settings → Gear & Loot → Stat weights (or `/everfrost weights`) lists the value of every stat for your spec, says where the numbers come from, and lets you change them. Changes save per character and per spec; Reset to defaults undoes them.
- Off-hand weapons are scored at the off-hand's own value where the simulator gives one (about a fifth of a main hand's for Fury). Hit, Crit, Haste, Dodge and Parry are valued per 1%, as items show them. Block value and block chance are separate stats. Feral's Bear focuses now count weapon DPS, which the simulator finds valuable in both forms.
- Tooltips name the source of the weights in use.

Simulated-client tests and the Lua lint pass. None of this has been seen in game.

## 0.9.0 — Rotation HUD and November guides

- **A rotation HUD replaces the reference panel.** A fixed NOW icon shows the spell to press. Where Forever offers it, this is Blizzard's own rotation assistant, which sees cooldowns, resources and procs that addons can't. Otherwise it is the highest guide spell the game says is ready. Up to six upcoming spells slide towards it in guide priority order, labelled as a priority rather than a promise. There are four layouts: Guitar Hero, Classic, Minimal and Tank. It shows in combat only by default, with a preview for placing it, and it lets clicks through in combat.
- **Automatic single target, cleave and AoE.** Everfrost estimates engaged enemies from enemy nameplates and switches at 2 and 3 by default, adjustable per spec. It steps down only after 1.5 seconds and shows the estimate as `~3`, or `?` when the game won't share it. AUTO, ST, CLV and AOE can be chosen by clicking the HUD's mode text, with slash commands or with key bindings; a manual choice stays until changed.
- **Controller and keyboard layouts.** The HUD follows the game's input style (gamepad mode, Steam Deck, ConsolePort). With a controller it uses larger icons placed above the gamepad bars. Each layout keeps its own position and size, and switching needs no reload.
- **Defensive and utility row.** Interrupts, taunts and defensive cooldowns you've learned show apart from the damage track, on by default for tanks. They show as available, never as urgent; big cooldowns are marked situational.
- **Missing-buff reminders.** Out of combat, a missing Righteous Fury, seal, stance or shield buff shows as a small reminder.
- **Settings reorganised** into Rotation, HUD, Controller, Detection, Gear & Loot and Talents.
- **Gear marks reworked.** One scoring engine now drives bags, loot rolls, quest rewards and vendors, and sorts items into clear upgrade, minor upgrade, sidegrade, better for another focus or tree, not usable, or downgrade. Upgrades get a thin green border instead of the pulsing glow, and loot rolls get a faint ring. A sidegrade is no longer marked Need. Protection Paladin and Warrior can choose **Balanced Tank** (default), **Tank Survivability**, **Tank Threat** or **Solo Levelling**; Feral can choose a cat or bear focus. A two-hander is compared with your weapon and shield together, so tanks aren't told to drop their shield. The best quest reward is labelled **Recommended**, with notes such as "Best for tanking" when another role would choose differently. Procs and Use effects are named, never given a made-up score.
- **Talent highlights fixed.** The outline goes on the next build point you can actually take. Prerequisites, points needed in the tree and level are respected, and the tooltip says why a build pick is locked. It adapts when you leave the build, and highlights no longer double up when the window is reopened.
- **All 27 rotations re-read from Icy Veins** (24 November 2026), from the new rotation pages added in November. Every tree changed. For Protection Paladin, Holy Shield is added, Judgement is used as often as possible, and Exorcism is for Undead or Demon packs only. Spells that wait for a proc stay out of the NOW spot unless Blizzard's assistant picks them. See SOURCES.md for each class.
- Your settings carry over. A saved AoE choice becomes a manual AoE mode, and the panel's position and size become the keyboard layout's.

Simulated-client tests and the full Lua lint pass. None of this has been seen in game.

## 0.8.0 — Talent recommendations and a resizable panel

- **Talent recommendations.** Everfrost now knows the Icy Veins levelling talent build for all 27 trees, point by point from level 10 to 60 (read from the guides on 11 November 2026). In the talent window the talent to take next has a gold glow, and hovering any talent says how many points the build puts there and at which levels. The panel's hover text and the Specialisation settings page name your next talent, and `/everfrost talents` lists the next few. It follows the tree you've chosen, or the one you have most points in. `/everfrost talents off` turns it off. Everfrost never spends points for you.
- **Resizable panel.** Drag the corner of the rotation panel to make it bigger or smaller (60% to 200%, the same setting as the size slider). The corner hides while the panel is locked.

Simulated-client tests pass. Not yet checked in game: in particular, whether Forever's talent window is one Everfrost can find, and whether its talent names match the guide's.

## 0.7.0 — Levels 31 to 60

Simulated-client tests pass; this version has not been checked in the game yet. Please report anything odd.

- **Levels 31 to 60.** Guides now run to level 60, following Icy Veins' updated levelling guides (read on 11 November 2026): Mortal Strike, Whirlwind, Bloodthirst, Shield Slam, Incinerate, Penance, Starfire, Chain Heal and about forty more, each shown once you've learned it. Gear hints run to 60 too, and plate (Warrior, Paladin) and mail (Hunter, Shaman) count as wearable from level 40.
- **Stat priorities re-read from the updated guides.** Seventeen of the 27 trees changed, mostly mages, warriors, warlocks and druids.
- **Equip effects count.** "Equip: Increases damage and healing done by magical spells and effects by up to 12" and similar passive lines (healing, school damage, attack power, mana per 5 seconds) are now read from the tooltip and scored. English clients only for now.
- **Key binding.** Key Bindings > AddOns > Everfrost shows or hides the panel.
- **New characters start with your look.** Panel size, opacity, lock, minimap button and gear highlights carry over from the last character you set them on. Guide choices and panel position stay per character.
- The download is two-thirds smaller (a smaller icon file).
- **Armour counts for every spec.** A better-armoured piece can now win over a small stat loss, and a much flimsier one can lose despite a small stat gain. The tooltip says when armour decided it and how much of the score it was. Before, armour only broke ties.
- **Tidier upgrade highlight.** The outline is thinner and sits exactly on the slot's edge, the glow is sized to the button, and the pulse breathes gently instead of flashing. Need and Greed buttons pulse without the square box around them.
- **Smoother at login and when zoning.** Bursts of spell and talent updates are handled once per frame instead of one full rescan each.
- A Feral druid with no form learned no longer gets a Cat/Bear button that empties the panel.
- `/everfrost spellids` lists spell IDs that would let ten guide spells work on non-English clients.
- The panel's hover text says when the guides were last checked.

Simulated-client tests and the full Lua lint pass. None of this has been seen in game yet.

## 0.6.9 — Clearer spec menu note

- Below level 10, the Choose a Spec menu now says "Full stat priorities need talents." The old note read as if gear help stopped at level 10.

No other behaviour changed. Simulated-client tests and the Lua globals check pass; the new wording still needs checking in game.

## 0.6.8 — Help for early gear

- Gear hints now work from level 1. Below level 10, each class uses a short starter stat list, because there is usually no talent tree to read yet. These lists are Everfrost estimates, not guide rankings. Talent-based priorities still start at level 10.
- Quest screens mark the best reward choice. If none is an upgrade, the one that sells for the most gets a gold mark. You still pick the reward.
- Merchants highlight upgrades on the current page once you can afford them, and the tooltip says when you can't yet.
- Tooltips explain upgrades in plain words, such as "Better because it has more Strength". Below level 10 the score line is hidden.
- The Gear Upgrades page counts empty armour slots, and the panel mentions it if no weapon is equipped.

Rotation priorities are unchanged. The addon still never picks, buys or equips anything. Simulated-client tests and the Lua globals check pass; these changes still need checking in game, especially the quest reward and merchant screens.

## 0.6.7 — Loot highlight, scoring and bag fixes

- Fix Need/Greed highlights not reaching Forever's loot-roll buttons, which sit inside a container on the roll frame. Tooltips on those buttons are fixed too.
- Hiding the UI (Alt-Z) or a cinematic no longer removes the highlight from a roll that is still open.
- Fix bag buttons losing their tracking and glow when bags opened, and stop reused buttons collecting duplicate script hooks.
- Value Attack Power by a spec's higher Strength or Agility weight, so Rogues and melee Survival Hunters no longer undervalue it.
- Plain wands now count for Priests, Mages and Warlocks. Stats still outrank a small DPS gain.
- A second copy of a Unique-Equipped item is no longer flagged as an upgrade.
- Hide the Survival role button until level 30 with Strider Kick, when it can change something.
- The upgrade glow keeps pulsing through bag changes outside combat, and rescans do far less repeated work. `/everfrost refresh` and Rescan bags still re-read everything.
- Use Australian spelling in the interface: Specialisation, Levelling, Armour and Defence. Spell names are unchanged, and `/everfrost spec leveling` still works alongside `levelling`.

Rotation priorities are unchanged apart from spelling. Simulated-client tests and the Lua globals check pass; these changes still need checking in game, especially a real group-loot roll.

## 0.6.6 — Armor upgrades and a green arrow

- Count more armor as an upgrade when you lose no useful stats. A plain mail belt now beats a plain leather belt for damage and caster specs, instead of showing "No useful stats". Armor only breaks ties: it never outweighs a stat loss.
- These items also highlight Need instead of Greed on group loot.
- Mark bag upgrades with the game's green up arrow alongside the glow. Loot-roll buttons keep the glow only.
- Tooltips for these upgrades state the armor gained instead of a score.

Simulated-client tests and the Lua globals check pass. The user reports these changes work in game.

## 0.6.5 — Text and colour polish

- Use one status-line format across the addon: the panel header now reads "Elemental Shaman" and "Level 18 / Auto" (or "Level 18 / Pending"), and the settings footer "Shaman / Level 18", with single spaces and no uppercase.
- Reduce help and footer text to two greys (secondary and muted) instead of six near-identical shades.
- Stop repeating the "start at level 10" note in item tooltips once gear is being scored. It still appears in Settings and in tooltips below level 10.

No rotation or gear rules changed. Simulated-client tests and the Lua globals check pass; the new text and colours still need an in-game look.

## 0.6.4 — CurseForge packaging fix

- Republish the 0.6.3 fixes for CurseForge. The 0.6.3 package was rejected because a repository notes file was included next to the addon; packaging now excludes it, and an automated check stops this from happening again. Addon behaviour is identical to 0.6.3.

## 0.6.3 — Gear scoring fix and lighter background work

- Fix Subtlety Rogue gear scoring: Attack Power was counted twice, so it outscored Agility and could mark worse items as upgrades. It now follows the guide's order (Agility above Attack Power).
- Stop full bag rescans every time the game loads item details for characters whose gear is never scored (below level 10, or no talent tree chosen). Rescans now happen only when a comparison is genuinely waiting for item data.
- Skip all item reading while gear highlights are turned off.
- Remember localized spell names once they have loaded instead of rebuilding them on every spellbook update.

No rotation priorities changed. Validation: simulated-client regression tests, including new checks for each fix, pass on GitHub Actions alongside a Lua globals check. Actual Forever client behaviour still needs in-game verification.

## 0.6.2 — Compact specialization picker

- Simplify the spec picker to compact single-line rows under Choose a Spec. Remove repeated descriptions and the generic saved-choice footer; keep the detected spec inline with Automatic and show only relevant level-10/combat notices.

## 0.6.1 — Panel opacity and native WoW styling

- Add a Rotation Panel opacity slider from 10% to 100%, applied immediately and saved per character. /everfrost opacity 60 sets 60%; settings, guide menus and tooltips remain fully readable.
- Restyle the compact reference panel with native WoW dialog background/border, standard game fonts and gold title text, UIPanel buttons and quickslot icon frames. Remove the flat class-colour stripe and custom mode chips.
- Preserve position, size, guide selection, learned-spell filtering and combat-deferred metadata refreshes. Reset position & size retains the chosen opacity.

## 0.6.0 — Settings, clearer upgrades and talent detection

- Add a compact native-style settings window with Specialization, Rotation Panel and Gear Upgrades tabs. Open it with /everfrost, /everfrost settings, /everfrost config, the minimap button or the game's AddOns settings launcher.
- Add a draggable minimap logo: left-click opens settings, right-click toggles the rotation panel. Save guide, role, encounter, panel and minimap preferences per character; adjust panel size with a 60%–200% slider.
- Fix passive gear being rejected as unusable. Give estimated upgrades a brighter outline and synchronized dim-to-bright pulse in the item's rarity colour.
- Add a clear UPGRADE heading in item tooltips, preserve it through native tooltip refreshes and retain companion requirements for weapon-pair upgrades.
- Start stat priorities and gear hints at level 10, with a clear notice in settings and tooltips. Spell reference guides still cover levels 1–30.
- Keep Leveling's general spell guide while using the active talent group's dominant tree for gear from level 10. Manual spec choices override detection; tied, unspent or unavailable talents leave Leveling gear unscored.
- Fix Forever talent detection to read the same trait-group currency totals as the native talent window, rather than specialization fields that can incorrectly return zero. Refresh after talent/config changes outside combat.
- Show the detected point split in Specialization settings, such as Elemental (9 / 0 / 0), and include cached totals and their source in /everfrost status.

Includes all 0.5.1 features: guide selection, complete weapon-pair comparisons and standard bag/Need/Greed guidance. No rotation priorities were changed in this release; Everfrost remains a learned-spell-aware reference panel, not a combat-driven next-cast queue.

Validation: all seven Lua files pass Lua 5.1 parsing; rotation, native trait detection, settings, combat deferral, gear, tooltip and glow regressions pass in the simulated client. The addon-only ZIP is verified against all 14 source files. The user confirmed the passive-equipment fix, rarity pulse and settings layout in game; the latest talent-detection fix and complete Forever compatibility still need client verification.

## 0.5.1 — Guide selection and complete weapon comparisons

- Click the rotation panel title to choose Automatic, Leveling or a class specialization. See the detected tree, saved selection and gear-scoring availability.
- Dismiss the selector with Escape, an outside click or its close button. Changes during combat apply after combat ends.
- Compare carried one-hand/off-hand pairs against an equipped two-hander using their combined estimated stat scores.
- Highlight estimated pair upgrades in bags and apply the same comparison to standard Need/Greed hints. Tooltips name the required partner; equip both items for the comparison to apply.
- Respect class, level, hand, shield, learned Dual Wield, physical-copy identity and exposed unique-equipped restrictions. Incomplete or unresolved pairs remain unscored.
- Refresh after partner removal or item-data loading; defer comparisons during combat.

This consolidated release combines the second 0.5.0 package, the original 0.5.1 and the former 0.5.2. The first 0.5.0 remains the original gear-guidance release. All earlier rotation references, 27 gear profiles and Need/Greed guidance are included.

Validation: Lua 5.1 syntax, simulated-client regression checks and addon-only archive verification passed. Complete Forever client compatibility remains unverified. Gear scores are estimates; weapon speed, dual-wield penalties, procs and other special effects are not simulated.

## 0.5.0

- Add guide-based gear priorities for all nine classes and 27 talent trees, checked October 20, 2026.
- Highlight estimated bag upgrades with a pulsing gold border.
- Highlight Need for estimated loot upgrades or Greed for known non-upgrades and class-irrelevant items.
- Add score/stat-order tooltips and `/everfrost gear on` / `off` controls.
- Handle paired slots, two-hand comparisons, shield builds, item requirements, asynchronous data and combat deferral.
- Add gear regression tests and cross-platform addon-only ZIP packaging.

Gear scores are estimates; special effects, weapon speed and hit caps are not modeled. Actual Forever client API and visual testing remains outstanding.

## 0.4.2

- Review all 27 Icy Veins Forever guides on October 15, 2026.
- Update Mage single-target and spec-specific AoE guidance.
- Add missing Rogue, Priest, Warlock and Protection Warrior abilities.
- Refine Hunter threat reminders, Paladin seals, Fury priorities and Shaman totems.
- Preserve learned-spell filtering and manual reference conditions.
- Document source ambiguities and add regression coverage.

Lua 5.1 syntax and simulated-client tests pass. Actual Forever client testing
remains outstanding.

## 0.4.1

- Show the Everfrost logo in the in-game AddOns list.
- Configure CurseForge packaging for tagged commits.
- Include the MIT license in addon packages.

## 0.4.0

- Introduce the Everfrost name and standalone project structure.
- Include levels 1–30, nine classes, 27 talent trees, and nine baseline profiles.
- Provide learned-spell-aware reference priorities, role and encounter controls,
  saved panel settings, and native cooldown sweeps when available.

Lua syntax and simulated-client regression tests pass for 0.4.0. Actual Forever
client compatibility, rendering, and persistence remain unverified.
