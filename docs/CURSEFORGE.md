# Everfrost — Spell Rotation & Gear Upgrade Guidance

**Built with new players in mind.** Everfrost started while playing alongside brand-new players and people trying WoW for the first time. It keeps basic spell rotation references and gear stat priorities close at hand while you learn your class.

A lightweight, standalone addon for **WoW Forever 1.60.1**, covering **levels 1–30, nine classes and 27 talent trees**. Written with **OpenAI Codex**. No third-party addon libraries are required.

## What's new in 0.6.0

- **Native-style settings:** type `/everfrost` or use the minimap button or the game's AddOns settings launcher. Specialization, Rotation Panel and Gear Upgrades tabs keep the controls together.
- **Clearer upgrade hints:** a prominent border fades in and out in the item's rarity colour. Tooltips show **UPGRADE**, the estimated score change and any required weapon partner. Passive equipment is no longer rejected for lacking a usable action.
- **Leveling gear guidance from level 10:** keep the general Leveling spell guide while the active talent tree with the most points determines your gear priorities. Manual specialization choices can override detection. Stat priorities and upgrade hints start at level 10; spell guides remain available from level 1.
- **Corrected Forever talent detection:** use the native talent window's trait-group totals, refresh after talent changes and show the detected split in settings. Ties, unspent points and unavailable data leave Leveling gear unscored.

## Spell reference panel

- Learned-spell-aware ability references using your trained ranks, with short hover guidance.
- Automatic class, level and talent-tree detection, plus Automatic, Leveling and manual specialization choices.
- Single-target/AoE views and supported healing, Feral and Survival role views.
- Compact, movable panel with saved position, visibility, locking and size; native cooldown sweeps where supported.

This is a **basic reference**, not a live next-cast queue or full class guide. It does not choose abilities from combat resources, target health or procs, and it never casts for you.

## Gear upgrades and Need/Greed

From level 10, standard bag items glow when their estimated guide-based stat score beats an equipped replacement. Hover for the comparison and stat order. Rings and trinkets consider both slots. Complete one-hand/off-hand combinations can compare against two-handers; pair tooltips name the partner, and **both items must be equipped** for that recommendation to apply.

Standard dungeon and raid loot-roll windows highlight **Need** for estimated upgrades and **Greed** for known non-upgrades or class-irrelevant items. Disabled choices are respected. You choose and click the roll, following your group's loot rules. Missing or restricted data stays unscored; refreshes defer during combat. Custom bag/loot replacements are not integrated.

Priorities are informed by [Icy Veins Forever guides](https://www.icy-veins.com/wow-forever/) and manually maintained. The 27 stat orders were checked on October 20, 2026. Numeric weights are Everfrost estimates, not Icy Veins simulation weights or guaranteed best-in-slot results. Weapon speed, dual-wield penalties, procs, set bonuses, enchants, sockets and hit caps are not simulated.

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

The original **0.5.0** introduced gear guidance. Consolidated **0.5.1** includes the guide selector and complete weapon-pair comparisons. **0.6.0** adds the settings window, rarity-colour pulse, clearer tooltips, level-10 guidance and native talent-detection fixes.

Lua 5.1 syntax and simulated-client regression tests pass. User testing confirmed the passive-equipment glow fix, rarity pulse and settings layout; the latest talent-detection fix and complete Forever compatibility still need in-game verification. English guidance; some Forever-specific spells depend on English spellbook names.

**MIT licensed. Third-party addon-manager distribution is enabled.** Everfrost is independent and is not affiliated with or endorsed by Blizzard, Icy Veins or OpenAI.

[GitHub source and full documentation](https://github.com/mckenna654/Everfrost) · [Latest GitHub release](https://github.com/mckenna654/Everfrost/releases/latest) · [Report an issue](https://github.com/mckenna654/Everfrost/issues) · [Gear scoring details](https://github.com/mckenna654/Everfrost/blob/main/docs/GEAR.md)
