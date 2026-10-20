# Changelog

## 0.5.2

- Compare carried one-hand/off-hand pairs with an equipped two-hander using combined estimated stat scores.
- Highlight estimated pair upgrades and identify the required companion in bag and loot-roll tooltips.
- Enforce usable hand combinations, learned Dual Wield, tank shields, physical-copy identity and exposed unique-equipped limits.
- Refresh pair hints after partner loading/removal and defer comparisons during combat.

Pair scoring does not simulate weapon speed, dual-wield penalties or special effects. Actual Forever client validation remains outstanding.

## 0.5.1

- Release the guide selector with a distinct version so addon managers can identify the update.
- Click the panel title or arrow to select Automatic, Leveling, or a class spec.
- Preserve saved selections, detection details, gear-scoring hints, and combat-deferred changes.
- Includes all gear upgrade borders and Need/Greed guidance from 0.5.0.

Lua 5.1 syntax and simulated-client tests pass. Actual Forever client rendering and API verification remains outstanding.

## 0.5.0

### Guide selector refresh

- Click the panel title to choose Automatic, Leveling, or a class specialization.
- Show automatic detection, the saved selection, and gear-scoring availability.
- Dismiss with Escape, an outside click, or the close button; preserve header dragging.
- Save explicit Leveling selection and defer combat changes safely.
- Refresh the existing 0.5.0 package without changing its addon version.

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
