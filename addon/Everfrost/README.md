# Everfrost — v0.4.1

A compact class-aware rotation reference for WoW Forever, covering levels 1–30. Detects your class, level, dominant talent tree, and learned spell ranks. Includes all nine classes and 27 talent trees, with a general leveling profile before you spend talents.

## Install or upgrade

1. Exit WoW.
2. Remove the old `ForeverRetHelper` and `ForeverGuide` folders from your Forever client's `Interface/AddOns` directory, then extract the new `Everfrost` folder there. Keep only the new addon enabled to avoid duplicate panels.
3. Confirm the path is `Interface/AddOns/Everfrost/Everfrost.toc`, without an extra nested folder.
4. Enable **Everfrost** in the AddOns list. Log in and type `/everfrost`.

The folder, TOC, frame and saved-variable identifiers now use Everfrost. Because this is a new addon identity, previous panel settings start fresh. `/everfrost` is the primary command; `/frh` remains a compatibility alias. This package is not automatically installed. It targets interface 16001; exact compatibility with your Forever build needs an in-game check.

## Using the panel

The header shows your spec, class, level and detection status. Read icons left to right, continuing on the next row. Hover an icon for its spell tooltip and the condition for using it. Hover the header for general rotation notes. Drag the header to move the panel.

Click **SINGLE / AOE** to change encounter mode. Healing specs have a **HEAL / DAMAGE** switch, defaulting to healing. Feral has a **CAT / BEAR** switch; before Cat Form is learned it defaults to Bear, or caster spells before either form is learned. It does not automatically follow your current shapeshift form.

This is a conditional priority reference, not a live next-cast queue. The list contains openers, maintenance effects, fillers and situational abilities. It does not mean cast every icon once in order: choose one seal, use finishers with combo points, and apply the conditions shown on hover. Native cooldown sweeps appear when supported by the client. It does not evaluate combat resources, proc buffs, enemy counts, positioning or target health to choose your next button.

## Detection and coverage

- Automatic specialization uses the talent tree with the most points. A tie shows **HYBRID** and uses the general leveling profile. Zero points shows **UNSPENT**. When talent-point APIs are absent, the client specialization API is used if available.
- `/everfrost spec 1`, `2`, or `3` selects a tree manually in talent-window order. `/everfrost spec auto` restores detection. Overrides are saved per character.
- Only learned spells are shown. The spellbook supplies the trained rank and required level; reaching a level alone does not unlock a spell.
- Metadata updates after training, leveling and talent changes. Changes made during combat refresh when combat ends.
- Levels above 30 display a scope notice. Several specs share early-level priorities until their distinct abilities become available. Survival uses the ranged approach until level 30 with Strider Kick learned, then defaults to the melee guide. The RANGED / MELEE switch lets you keep the ranged view; melee also assumes the supporting Survival talents described in the source guide.
- English guidance; existing spell names use localized names where available. New Forever-specific names currently require an English spellbook.

## Commands

| Command | Action |
|---|---|
| `/everfrost` | Show panel |
| `/everfrost hide` | Hide panel |
| `/everfrost single` / `/everfrost aoe` | Encounter mode |
| `/everfrost heal` / `/everfrost damage` | Healing-spec view |
| `/everfrost cat` / `/everfrost bear` | Feral view |
| `/everfrost ranged` / `/everfrost melee` | Survival view (melee requires level 30 and Strider Kick) |
| `/everfrost spec auto` / `/everfrost spec 1` / `2` / `3` | Automatic or manual spec |
| `/everfrost lock` / `/everfrost unlock` | Lock or unlock dragging |
| `/everfrost scale 1.2` | Scale between 0.6 and 2 |
| `/everfrost reset` | Reset position and scale; show panel |
| `/everfrost refresh` | Rescan outside combat |
| `/everfrost source` | Print the selected guide URL |
| `/everfrost status` | Print detected class, tree, level and API status |

## Sources and verification

Adapted from the Icy Veins WoW Forever PvE guides, reviewed October 3, 2026. See SOURCES.md for all links. These are concise leveling adaptations of guide priorities, with general ability hints where needed, rather than complete reproductions or an automatically updated guide feed. Unofficial; not affiliated with Icy Veins or Blizzard.

Local Lua syntax and simulated-client checks passed; see VALIDATION.txt. No third-party addon libraries are required. Actual game rendering and Forever API behavior remain unverified.

For the first game check, verify the header and learned icons, train a spell and change talent points, switch encounter/role modes, then reload to check the saved position. Test on a second class. If an ability is missing, use `/everfrost refresh` outside combat. Include `/everfrost status`, your client build and any Lua error when reporting a problem.


## Level-30 update

Version 0.4.0 extends the existing panel through level 30. New learned-spell entries cover Holy Shock, Summon Hawk, Survival melee, Blast Wave, Slam, Death Wish, Hemorrhage, Prayer of Healing, Conflagrate, Soul Link, Hellfire, Insect Swarm, Shifting Power, Swiftmend and Stormstrike, among others. Abilities supplied by talents are matched from the spellbook rather than assuming you chose the guide's build. This also permits earlier access through extra talent points where available.

Some source pages still contain older level-20 sections alongside newer guidance. The addon uses the available rotation guidance and your trained spell metadata; it does not claim every guide section has been updated for 30. Exact talents, gear, weapon setup and proc conditions remain yours to check against the hover notes and linked guide.




