# In-game checklist

Simulated tests can't see the game. Before a version is tagged as a release, walk through this on
a low-level character (about 20 minutes) and record the result in `docs/HANDOFF.md` and the
changelog entry. Anything not checked ships as a beta tag (`v0.7.0-beta.1`), which CurseForge
labels as beta, or is named in the changelog as not seen.

## Every release

1. **Loads cleanly.** Log in with Lua errors shown (`/console scriptErrors 1`). No error on login,
   on opening bags, or on `/everfrost`.
2. **Panel.** The spec, level and spells are right for the character. Hover a spell: tooltip and
   hint. Switch Single / AoE. Drag the panel, `/reload`, and it is where it was left.
3. **Detection.** `/everfrost status` shows the right class, tree and talent split.
4. **Combat.** Fight something: no errors; cooldown sweeps show; changes made in combat apply after.
5. **Bags.** An upgrade in the bags has the outline, glow and green arrow, and its tooltip says
   UPGRADE with a reason. A non-upgrade has none. Equip the upgrade: the highlight goes.
6. **Settings.** All three pages open and fit; sliders and tick boxes work; the minimap button
   drags and opens settings.

## When gear code changed

7. **Quest rewards.** A quest with a choice of rewards: the best is marked, or the best seller in gold.
8. **Vendor.** An affordable upgrade is marked; one you can't afford says so in its tooltip.
9. **Empty slots.** Unequip a piece: the Gear Upgrades page counts it; no weapon shows on the panel.
10. **Group loot.** In a group, on a roll: Need pulses for an upgrade, Greed for a non-upgrade,
    and the pulse sits tidily on the round button.
11. **Armour.** Two pieces with similar stats and different armour: the tooltip mentions armour.

## Once

12. **Spell IDs.** On characters that know them, run `/everfrost spellids` and add the IDs it
    prints to `baseIDs` in `addon/Everfrost/Core.lua` (ten guide spells still match by English
    name only: see the test in `tests/check.cjs`).
13. **Past level 30.** At 31 the panel hides with one chat line; `/everfrost show` brings it back.
