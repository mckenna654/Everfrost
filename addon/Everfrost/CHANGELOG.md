# Changelog

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
