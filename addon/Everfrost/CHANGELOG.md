# Changelog

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
