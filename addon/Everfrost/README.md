# Everfrost — v0.6.3

A compact class-aware rotation reference for WoW Forever, covering levels 1–30. Detects your class, level, dominant talent tree, and learned spell ranks. Includes all nine classes and 27 talent trees, with a general leveling profile before you spend talents.

## Install or upgrade

1. Exit WoW.
2. Remove the old `ForeverRetHelper` and `ForeverGuide` folders from your Forever client's `Interface/AddOns` directory, then extract the new `Everfrost` folder there. Keep only the new addon enabled to avoid duplicate panels.
3. Confirm the path is `Interface/AddOns/Everfrost/Everfrost.toc`, without an extra nested folder.
4. Enable **Everfrost** in the AddOns list. type `/everfrost` for settings or `/everfrost show` for the reference panel.

The folder, TOC, frame and saved-variable identifiers now use Everfrost. Because this is a new addon identity, previous panel settings start fresh. `/everfrost` is the primary command; `/frh` remains a compatibility alias. This package is not automatically installed. It targets interface 16001; exact compatibility with your Forever build needs an in-game check.

## Using the panel

Click the panel title or down arrow to open **Choose a Spec**, a compact menu with single-line Automatic, Leveling and specialization choices. Automatic shows the detected tree inline. The menu shows the automatically detected tree and marks your saved selection. Leveling retains the general spell guide but uses the dominant talent tree for gear from level 10 onward. Close it with Escape, the close button, or an outside click. Changes during combat apply when combat ends.

The header shows your spec, class, level and detection status. Read icons left to right, continuing on the next row. Hover an icon for its spell tooltip and the condition for using it. Hover the header for general rotation notes. Drag the header to move the panel.

Click **SINGLE / AOE** to change encounter mode. Healing specs have a **HEAL / DAMAGE** switch, defaulting to healing. Feral has a **CAT / BEAR** switch; before Cat Form is learned it defaults to Bear, or caster spells before either form is learned. It does not automatically follow your current shapeshift form.

This is a conditional priority reference, not a live next-cast queue. The list contains openers, maintenance effects, fillers and situational abilities. It does not mean cast every icon once in order: choose one seal, use finishers with combo points, and apply the conditions shown on hover. Native cooldown sweeps appear when supported by the client. It does not evaluate combat resources, proc buffs, enemy counts, positioning or target health to choose your next button.

## Detection and coverage

- Automatic specialization uses the talent tree with the most points. A tie shows **HYBRID** and uses the general leveling profile. Zero points shows **UNSPENT**. When talent-point APIs are absent, the client specialization API is used if available.
- Everfrost reads Forever's native trait-group currency totals. Specialization settings displays the cached point split; `/everfrost status` also reports the detection source. Unavailable or uncommitted talent data is not treated as zero spent points.
- `/everfrost spec 1`, `2`, or `3` selects a tree manually in talent-window order. `/everfrost spec auto` restores detection. Overrides are saved per character.
- Only learned spells are shown. The spellbook supplies the trained rank and required level; reaching a level alone does not unlock a spell.
- Metadata updates after training, leveling and talent changes. Changes made during combat refresh when combat ends.
- Levels above 30 display a scope notice. Several specs share early-level priorities until their distinct abilities become available. Survival uses the ranged approach until level 30 with Strider Kick learned, then defaults to the melee guide. The RANGED / MELEE switch lets you keep the ranged view; melee also assumes the supporting Survival talents described in the source guide.
- English guidance; existing spell names use localized names where available. New Forever-specific names currently require an English spellbook.

## Settings window

Open with `/everfrost`, `/everfrost settings`, the minimap button, or Escape → Options → AddOns → Everfrost → Open Everfrost settings. An Interface → AddOns fallback is available on older clients.

The Specialization page chooses Automatic, Leveling, a specialization, encounter mode and supported role views. Rotation Panel controls visibility, locking, size, reset and minimap visibility. Gear Upgrades controls highlights and shows stat priorities with a Rescan bags button. Preferences save per character. Guide changes still defer during combat; open the settings window outside combat. Escape closes it, and dragging the header moves it.

The compact window uses native WoW framing, inset content and top tabs. Panel size uses a 60%–200% slider. Stat text is aligned below its heading, and the level-10 notice stays visible.

Rotation Panel also offers an opacity slider from 10% to 100%, saved per character. It fades the entire reference panel while settings, guide menus and tooltips stay fully readable. `/everfrost opacity 60` sets 60%. Reset position & size keeps your opacity choice. The reference panel now uses WoW dialog textures, native fonts/buttons and quickslot icon borders.

Left-click the minimap button for settings, right-click to show/hide the panel, and drag to reposition it. `/everfrost minimap on` restores a hidden button. Actual native settings integration and rendering still need in-game testing.

## Commands

| Command | Action |
|---|---|
| `/everfrost` / `/everfrost settings` / `/everfrost config` | Open settings |
| `/everfrost show` | Show reference panel |
| `/everfrost minimap on` / `/everfrost minimap off` | Show or hide minimap button |
| `/everfrost hide` | Hide panel |
| `/everfrost single` / `/everfrost aoe` | Encounter mode |
| `/everfrost heal` / `/everfrost damage` | Healing-spec view |
| `/everfrost cat` / `/everfrost bear` | Feral view |
| `/everfrost ranged` / `/everfrost melee` | Survival view (melee requires level 30 and Strider Kick) |
| `/everfrost spec leveling` / `/everfrost spec 0` | General leveling guide |
| `/everfrost spec auto` / `/everfrost spec 1` / `2` / `3` | Automatic or manual spec |
| `/everfrost lock` / `/everfrost unlock` | Lock or unlock dragging |
| `/everfrost scale 1.2` | Scale between 0.6 and 2 |
| `/everfrost opacity 60` | Panel opacity from 10% to 100% |
| `/everfrost reset` | Reset position and scale; show panel |
| `/everfrost refresh` | Rescan outside combat |
| `/everfrost source` | Print the selected guide URL |
| `/everfrost status` | Print detected class, tree, level and API status |

## Sources and verification

Adapted from the Icy Veins WoW Forever PvE guides, reviewed October 15, 2026. See SOURCES.md for all links. These are concise leveling adaptations of guide priorities, with general ability hints where needed, rather than complete reproductions or an automatically updated guide feed. Unofficial; not affiliated with Icy Veins or Blizzard.

Local Lua syntax and simulated-client checks passed; see VALIDATION.txt. No third-party addon libraries are required. Actual game rendering and Forever API behavior remain unverified.

For the first game check, verify the header and learned icons, train a spell and change talent points, switch encounter/role modes, then reload to check the saved position. Test on a second class. If an ability is missing, use `/everfrost refresh` outside combat. Include `/everfrost status`, your client build and any Lua error when reporting a problem.


## Level-30 update

Version 0.4.0 extends the existing panel through level 30. New learned-spell entries cover Holy Shock, Summon Hawk, Survival melee, Blast Wave, Slam, Death Wish, Hemorrhage, Prayer of Healing, Conflagrate, Soul Link, Hellfire, Insect Swarm, Shifting Power, Swiftmend and Stormstrike, among others. Abilities supplied by talents are matched from the spellbook rather than assuming you chose the guide's build. This also permits earlier access through extra talent points where available.

Some source pages still contain older level-20 sections alongside newer guidance. The addon uses the available rotation guidance and your trained spell metadata; it does not claim every guide section has been updated for 30. Exact talents, gear, weapon setup and proc conditions remain yours to check against the hover notes and linked guide.





## Gear upgrades and Need/Greed highlights

Enabled by default for levels 10–30. Standard bag items get a pulsing border in the item's rarity colour when their estimated score beats an equipped replacement. Standard loot-roll windows highlight Need for estimated upgrades and Greed for known non-upgrades or irrelevant items. Disabled choices are respected, and you click the roll yourself. Hover for the score difference and stat order.

Use `/everfrost gear` to show the selected priorities, or `/everfrost gear on` / `off` to toggle the feature. **Stat priorities and gear upgrade hints start at level 10** including for manual spec choices. This note is also displayed in settings, gear tooltips and panel hover text. Leveling uses the tree with the most talent points in the active talent group from level 10 onward. All three tree counts must be available. The settings Gear Upgrades page identifies the inferred spec; ties, unspent talents or unavailable data stay unscored. From level 10, manual spec choices override detection. A healer's DAMAGE view still uses healing gear priorities. Survival uses ranged priorities before its melee requirements are met or when RANGED is selected.

Complete weapon comparisons: one-hand weapons and off-hands can compare together against an equipped two-hander. Everfrost searches your carried bags for each item's best usable partner and highlights estimated pair upgrades. The tooltip names the partner: equip both items for the comparison to apply. Loot candidates use carried partners too. Shields, held off-hands and learned Dual Wield are supported. Missing partners or unresolved pair data remain unscored.

Stat orders were checked against all 27 linked Icy Veins Forever guides on October 20, 2026. Everfrost converts those orders into approximate weights; it is not a simulator. Procs, set bonuses, weapon speed, dual-wield damage penalties, sockets, enchants, hit caps and other special effects are not modeled. Check the tooltip and your group's loot rules. Missing/restricted item data is also unscored. During combat, comparisons wait for combat to end. Custom bag and loot-window replacements are not integrated.

Written with OpenAI Codex. Full scoring method: https://github.com/mckenna654/Everfrost/blob/main/docs/GEAR.md
