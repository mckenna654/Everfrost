# In-game checklist

Simulated tests can't see the game. Before a version is tagged as a release, walk through this on
a low-level character (about 20 minutes) and record the result in `docs/HANDOFF.md` and the
changelog entry. Anything not checked ships as a beta tag (`v0.7.0-beta.1`), which CurseForge
labels as beta, or is named in the changelog as not seen.

## Every release

1. **Loads cleanly.** Log in with Lua errors shown (`/console scriptErrors 1`). No error on login,
   on opening bags, or on `/everfrost`.
2. **HUD.** `/everfrost preview`: the spells are right for the character. Hover a spell: tooltip and
   hint. Unlock, drag the HUD, `/reload`, and it is where it was left.
3. **Detection.** `/everfrost status` shows the right class, tree and talent split.
4. **Combat.** Fight something: no errors; cooldown sweeps show; changes made in combat apply after.
5. **Bags.** An upgrade in the bags has a thin green border and a green percentage (see item 26),
   and its tooltip says Clear or Minor upgrade with a reason. A non-upgrade has none. Equip the upgrade: the highlight goes.
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
    prints to `baseIDs` in `addon/Everfrost/Core.lua` (seventeen guide spells still match by English
    name only: see the test in `tests/check.cjs`).
13. **Levels 31–60.** On a higher-level character, the new abilities show once learned and plate or mail counts as wearable from 40.
14. **Key bindings and new characters.** Key Bindings > AddOns > Everfrost: show/hide the HUD, step through modes, and AUTO/ST/CLV/AOE each work. A new character starts with the size, opacity and HUD layout last used on another.
15. **Talent window.** Open talents (N) with a point to spend.
    - One talent is impossible to miss: a thick ice-blue outline, a pulsing ice-blue glow around
      it and the word NEXT above it, clearly different from the game's gold border on talents
      you already have points in. NEXT doesn't hide a neighbouring talent or its rank number.
      It is the next point of the Icy Veins build you can actually take. The icon and its rank number stay clear, and the game's own
      tooltip and clicks work as normal. `/everfrost talents` names the same talent.
    - Hover it: Everfrost lines say how many points the build puts there, at which levels, and
      "Your next point goes here" with its build pick number. Hover a talent you have finished,
      one outside the build, and a locked one: they say "Done", "not in the build" and why it is
      locked (a prerequisite, points needed in the tree, or a level).
    - Stage a point (click it, don't apply yet): the outline moves to the next pick within a
      moment. Undo or apply, close and reopen the window a few times: still one outline, never a
      thicker or doubled one.
    - With no points to spend, nothing glows; the summary says when the next point comes.
    - Switch to the other spec tab (dual spec): no outline there. `/everfrost talents off` clears
      it; `on` brings it back.
    - Spend a point off the build, or reset talents: the outline goes to the build's next point
      you can take, and if that is locked the tooltip on the suggested talent says why.
    If nothing shows, note the talent window's frame name (`/fstack`) and one talent's exact name.
16. **Resize.** Unlocked, drag the HUD's bottom-right corner: it grows and shrinks from the top-left, stays
    put after `/reload`, and the settings slider shows the same size. No corner while locked.

## Rotation HUD (first time, then whenever Combat.lua, HUD.lua or Main.lua change)

Use a Protection Paladin in a dungeon if possible, with `/console scriptErrors 1` and **enemy
nameplates on** (Interface > Names, or V).

17. **Out of combat.** The HUD is hidden, unless a buff is missing: without Righteous Fury or a
    seal, a small reminder icon shows. `/everfrost preview` shows the whole HUD; again hides it.
18. **NOW.** Pull something. A large icon between two thin blue bars; it changes as you play, with
    a soft pulse. `/everfrost status` ends with "Blizzard assistant: available" or the game's
    reason it isn't. Hover the HUD out of combat: the tooltip says where NOW comes from. Note
    whether NOW matches the spell the game's own Assisted Highlight would light up.
19. **Upcoming.** Three smaller icons to the right, sliding left when the first one becomes NOW. A
    spell you can't afford turns bluish grey; cooldown sweeps show on all icons. No Lua errors
    during a long fight.
20. **Automatic mode.** Pull one enemy: `AUTO · ST ~1`. Pull a pack of three or more: `AUTO · AOE
    ~3` within about a second, and Consecration moves up. Kill all but one: back to ST about 1.5
    seconds later, not instantly flickering. `/everfrost enemies` in combat prints the estimate.
    If it shows `?`, note it: the game isn't sharing nameplate data in that place (boss fights,
    dungeons) and Everfrost stays on single target.
21. **Manual mode.** Click the mode text: AUTO, ST, CLV, AOE in turn; it stays through several
    pulls. Right-click: back to AUTO. The key bindings do the same.
22. **Defensive row.** Below the track (Protection): Hammer of Justice, Divine Protection and the
    others you've learned, with cooldown sweeps; the big ones dimmed. Nothing flashes or nags.
    Tank layout always shows it; `/everfrost utility off` hides it in other layouts.
23. **Layouts.** Settings > HUD: Guitar Hero, Classic, Minimal and Tank all show the same NOW
    spell; Minimal has two upcoming icons.
24. **Controller.** With gamepad mode on (or Steam Deck / ConsolePort): pick up the controller and
    use it. Within a second the HUD moves above the gamepad bars and grows (60 px NOW). Touch the
    mouse briefly: it doesn't flicker back. Use the keyboard properly: it returns to its own
    position and size. Move the HUD in each layout; both positions survive `/reload`.
25. **Clicks.** In combat, clicking or right-click-dragging through the HUD still turns the camera
    and selects enemies behind it. The mode text stays clickable.
26. **Upgrade percentage.** A bag upgrade shows a green number such as `+48%` in the icon's
    bottom-right corner, readable against a busy icon and not clipped; a minor upgrade's is softer.
    An item for an empty slot says `NEW`. No arrow. The same on vendor buttons and quest reward
    icons. The tooltip's percentage matches the icon's.
27. **Hit and Crit units.** Find an item with "Improves your chance to hit by 1%" (or crit). Its
    tooltip verdict should treat that 1% as roughly 10 to 50 points of your main stat, not as one
    point and not as hundreds. If it looks wildly off, note the item: the client may report these
    stats differently from the tooltip.
28. **Stat weights page.** Settings > Gear & Loot > Stat weights (or `/everfrost weights`): 21
    stats in three columns, none overlapping or cut off; the source line names wowsims or says
    estimate. Type a new Stamina value and press Enter: the label turns gold, bag marks change,
    and the Gear & Loot page says "your own weights". Escape abandons an edit. Reset to defaults
    restores it. `/reload`: a saved change is still there.
29. **Need and Greed.** On a group loot roll for an upgrade, the Need button has a bright green
    glowing ring (pulsing for a clear upgrade) that you notice at once, and the item's icon in the
    roll window shows a green border and percentage. For an item you wouldn't wear, Greed has a
    steady gold ring. The rings sit around the buttons and don't spill over the item's name.
