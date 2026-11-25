# Everfrost — v0.10.0

A rotation HUD and gear and talent hints for WoW Forever, covering levels 1–60, all nine classes and 27 talent trees. Everfrost detects your class, level, talent tree and learned spell ranks. It never casts, rolls, equips or clicks anything for you.

## Install or upgrade

1. Exit WoW.
2. Extract the `Everfrost` folder into your Forever client's `Interface/AddOns` directory, replacing any older copy. Remove old `ForeverRetHelper` or `ForeverGuide` folders.
3. Confirm the path is `Interface/AddOns/Everfrost/Everfrost.toc`, without an extra nested folder.
4. Enable **Everfrost** and log in. Type `/everfrost` for settings, or `/everfrost preview` to see the HUD out of combat.

Settings from earlier Everfrost versions carry over: a saved AoE choice becomes manual AoE mode, and the old panel's position and size become the keyboard layout's. The addon targets interface 16001; compatibility with your Forever build still needs an in-game check.

## The rotation HUD

- **NOW**: the large icon between two thin blue bars is the spell to press. Where the game offers it, this comes from Blizzard's own rotation assistant, which sees cooldowns, resources and procs that addons can't. Otherwise it's the highest guide spell the game says is ready.
- **Upcoming**: up to six smaller icons (three by default) in the guide's priority order, sliding towards NOW. A priority, not a promise about your next casts. Steps that wait for a proc stay here and never take NOW on the guide's word alone.
- **Defensive row** (on by default for tanks): interrupts, taunts and defensive cooldowns you've learned. Everfrost can't see how much danger you're in, so these show as available; big ones are dimmed and marked situational.
- **Missing buffs** such as Righteous Fury or a seal show as a small reminder out of combat.
- **Layouts**: Guitar Hero (default), Classic, Minimal and Tank. The HUD shows in combat only by default; in combat clicks pass through it.

### Single target, cleave and AoE

The mode text on the HUD reads `AUTO · ST ~1`. In AUTO, Everfrost estimates engaged enemies from **enemy nameplates** (turn them on) and switches to cleave at 2 and AoE at 3 by default, adjustable per spec on the Detection page. It steps up at once and steps down after 1.5 seconds. When the game won't share enough to count, it shows `?` and stays on single target. Click the mode to step through AUTO, ST, CLV and AOE; right-click returns to AUTO. A manual mode stays until you change it. Key Bindings > AddOns > Everfrost has keys for each.

### Controller and keyboard

The HUD follows the game's input style (gamepad mode, Steam Deck, ConsolePort). With a controller it gets bigger icons; each layout keeps its own position and size. Set them under Settings → Controller → Position each layout; until placed, the controller layout sits where the keyboard one is. Unlock the HUD and move or resize it while using each layout.

## Gear, loot and quests

One scoring engine marks bag upgrades (a thin green border and how much better the item is as a green percentage; fainter for minor upgrades), loot rolls (a bright glowing ring: green on Need for an upgrade, gold on Greed for something you wouldn't wear) and quest rewards (**Recommended** on the best one). Tanks and Feral can choose a scoring focus such as Balanced Tank, Survivability, Threat or Solo Levelling on the Gear & Loot page. A two-hander is compared with your weapon and shield together. Procs and Use effects are named, never given a made-up score. Below level 10, gear uses a simple starter priority for your class. Full method: https://github.com/mckenna654/Everfrost/blob/main/docs/GEAR.md

## Talents

From level 10, the next talent in the Icy Veins levelling build that you can actually take has a thick ice-blue outline, a pulsing glow and the word NEXT above it in the talent window. Its tooltip shows its place in the build, and a locked build pick says why (a prerequisite, points needed in the tree, or your level).

## Commands

| Command | Action |
|---|---|
| `/everfrost` | Open settings |
| `/everfrost show` / `hide` | Show or hide the HUD |
| `/everfrost preview` | Show the HUD out of combat to place it |
| `/everfrost mode auto` / `st` / `cleave` / `aoe` | Rotation mode |
| `/everfrost layout track` / `classic` / `minimal` / `tank` | HUD layout |
| `/everfrost input auto` / `pad` / `kbm` / `custom` | Controller or keyboard layout, or one position for both |
| `/everfrost upcoming 3` | Upcoming icons, 0–6 |
| `/everfrost utility auto` / `on` / `off` | Defensive row: tanks only, always or never |
| `/everfrost enemies` | In combat, the enemy estimate |
| `/everfrost spec auto` / `levelling` / `1` / `2` / `3` | Automatic, Levelling or manual spec |
| `/everfrost heal` / `damage` / `cat` / `bear` / `ranged` / `melee` | Role views |
| `/everfrost lock` / `unlock` | Lock or unlock dragging |
| `/everfrost scale 1.2` / `opacity 60` | Size of the current layout; opacity |
| `/everfrost reset` | Reset the current layout's position and size |
| `/everfrost gear` / `gear on` / `gear off` | Stat order; gear marks on or off |
| `/everfrost talents` / `talents on` / `talents off` | Next talents; highlights on or off |
| `/everfrost refresh` / `status` / `source` / `spellids` | Rescan; diagnostics; guide link; spell IDs to report |

## Sources

Rotations follow the Icy Veins WoW Forever rotation pages as read on 24 November 2026, with levelling-guide steps for levels 31–60 kept where the max-level pages don't cover them. See SOURCES.md for every link and change. Unofficial; not affiliated with Icy Veins or Blizzard. No third-party addon libraries are required.

Tested against a simulated client only. Please report problems with `/everfrost status`, your client build and any Lua error.
