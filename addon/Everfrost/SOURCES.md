# Guide sources

Icy Veins WoW Forever PvE guides, reviewed October 15, 2026. All 27 linked guides were accessible, including the full Arcane guide. This audit compares the current rotation and relevant leveling sections with the addon's learned-spell-aware references for levels 1–30. It does not reproduce gearing, professions or full talent builds.

Guide conditions remain manual hints: Everfrost does not evaluate procs, resources, enemy counts or target debuffs in combat.
- [holy paladin healer](https://www.icy-veins.com/wow-forever/holy-paladin-healer-pve-guide)
- [protection paladin tank](https://www.icy-veins.com/wow-forever/protection-paladin-tank-pve-guide)
- [retribution paladin melee dps](https://www.icy-veins.com/wow-forever/retribution-paladin-melee-dps-pve-guide)
- [beast mastery hunter ranged dps](https://www.icy-veins.com/wow-forever/beast-mastery-hunter-ranged-dps-pve-guide)
- [marksmanship hunter ranged dps](https://www.icy-veins.com/wow-forever/marksmanship-hunter-ranged-dps-pve-guide)
- [survival hunter melee dps](https://www.icy-veins.com/wow-forever/survival-hunter-melee-dps-pve-guide)
- [arcane mage ranged dps](https://www.icy-veins.com/wow-forever/arcane-mage-ranged-dps-pve-guide)
- [fire mage ranged dps](https://www.icy-veins.com/wow-forever/fire-mage-ranged-dps-pve-guide)
- [frost mage ranged dps](https://www.icy-veins.com/wow-forever/frost-mage-ranged-dps-pve-guide)
- [arms warrior melee dps](https://www.icy-veins.com/wow-forever/arms-warrior-melee-dps-pve-guide)
- [fury warrior melee dps](https://www.icy-veins.com/wow-forever/fury-warrior-melee-dps-pve-guide)
- [protection warrior tank](https://www.icy-veins.com/wow-forever/protection-warrior-tank-pve-guide)
- [assassination rogue melee dps](https://www.icy-veins.com/wow-forever/assassination-rogue-melee-dps-pve-guide)
- [combat rogue melee dps](https://www.icy-veins.com/wow-forever/combat-rogue-melee-dps-pve-guide)
- [subtlety rogue melee dps](https://www.icy-veins.com/wow-forever/subtlety-rogue-melee-dps-pve-guide)
- [discipline priest healer](https://www.icy-veins.com/wow-forever/discipline-priest-healer-pve-guide)
- [holy priest healer](https://www.icy-veins.com/wow-forever/holy-priest-healer-pve-guide)
- [shadow priest ranged dps](https://www.icy-veins.com/wow-forever/shadow-priest-ranged-dps-pve-guide)
- [affliction warlock ranged dps](https://www.icy-veins.com/wow-forever/affliction-warlock-ranged-dps-pve-guide)
- [demonology warlock ranged dps](https://www.icy-veins.com/wow-forever/demonology-warlock-ranged-dps-pve-guide)
- [destruction warlock ranged dps](https://www.icy-veins.com/wow-forever/destruction-warlock-ranged-dps-pve-guide)
- [balance druid ranged dps](https://www.icy-veins.com/wow-forever/balance-druid-ranged-dps-pve-guide)
- [feral druid melee dps and tank](https://www.icy-veins.com/wow-forever/feral-druid-melee-dps-and-tank-pve-guide)
- [restoration druid healer](https://www.icy-veins.com/wow-forever/restoration-druid-healer-pve-guide)
- [elemental shaman ranged dps](https://www.icy-veins.com/wow-forever/elemental-shaman-ranged-dps-pve-guide)
- [enhancement shaman melee dps](https://www.icy-veins.com/wow-forever/enhancement-shaman-melee-dps-pve-guide)
- [restoration shaman healer](https://www.icy-veins.com/wow-forever/restoration-shaman-healer-pve-guide)

API reference: [Blizzard UI source mirror](https://github.com/Gethe/wow-ui-source/tree/live/Interface/AddOns/Blizzard_APIDocumentationGenerated) and [Vanilla specialization compatibility wrapper](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_DeprecatedSpecialization/Deprecated_Specialization_Vanilla.lua).


## October 15 audit

All nine classes and 27 trees were checked. Changes include corrections to existing adaptations as well as information on recently updated pages; a page's update date alone does not identify when a particular recommendation changed.

| Class / trees reviewed | Result |
| --- | --- |
| Paladin: Holy, Protection, Retribution | Kept healing and tank priorities. Refined shared damage-seal selection for weapon on-hit effects and Command Judgement's stun interaction. |
| Hunter: Beast Mastery, Marksmanship, Survival | Added the ranged Disengage threat reminder. Preserved Beast Master's two-hawk mana condition and Survival's learned melee build at 30. |
| Mage: Arcane, Fire, Frost | Restored early Missiles and Frostbolt pulling after learning Blast; added stack-clearing Fire Blast. Split Arcane/Frost AoE from Fire's template. Corrected Fireball/Fire Blast ordering and clarified Frostbite versus Fingers of Frost. |
| Warrior: Arms, Fury, Protection | Corrected Fury's Rend/Overpower order. Added Protection's Charge, Rend and Shield Block; retained Arms' Slam timing and Spearing Strike conditions. Added Bloodrage preparation reminders. |
| Rogue: Assassination, Combat, Subtlety | Added Mutilate with builder fallbacks; Combat's Garrote alternative, Blade Flurry and Riposte. Clarified five-point Slice and Dice and poison preparation. Subtlety's Hemorrhage/Rupture rules still agree. |
| Priest: Discipline, Holy, Shadow | Discipline still agrees. Added Holy's conditional Searing Light/Holy Nova healing reminder; Shadow's Plague and Smite fallback before Mind Flay. |
| Warlock: Affliction, Demonology, Destruction | Added Affliction's Siphon Life; incorporated Amplify Curse in the Agony hint to preserve the compact row limit. Clarified Immolate pre-casting, Destruction's opening Bolt and shard-cap Shadowburn, plus safe Life Tap reminders. |
| Druid: Balance, Feral, Restoration | Core priorities still agree. Clarified Bear's preferred Omen of Clarity spender. |
| Shaman: Elemental, Enhancement, Restoration | Elemental and Restoration still agree. Updated Enhancement's Rank 1 pull, group shocks, threat alternative and fire-totem choices. |

### Source ambiguities and limits

- Arcane's spell explanations say 1–2 Blasts while its rotation says 2–3 before Fire Blast. The hint therefore says a short burst rather than asserting a universal stack threshold.
- Protection Warrior's priority list says Victory Rush is learned at 30, while its own utility section and the other Warrior guides say 20. The existing level-20 minimum remains, with actual learned-spell/rank checks still required.
- Frost's general explanation says to finish Frostbolt on a target freeze, but separately distinguishes Fingers of Frost as an on-cast proc requiring prompt interruption of the next cast. Hints preserve that distinction.
- Some pages retain earlier level-cap wording. Learned spells remain authoritative for availability; a guide mention never makes an unlearned ability appear.
- This is a compact reference, not an exhaustive spellbook or automatic next-cast queue. Totem preparation, resource management and some utility remain in notes/hints.
- Lua regression tests and mocked APIs do not establish Forever client compatibility. Actual client testing remains outstanding, including localization aliases and new spell icons.

## October 20 gear-priority audit

Stat/gearing sections of all 27 linked guides were rechecked for the new gear feature. Their orders are stored separately in GearProfiles.lua; rotation rules retain their October 15 review. Gear scores use Everfrost ordinal estimates, not numeric weights published by Icy Veins. Missing item data remains unscored; loot choices are manual. Full stat table, scoring formula and limitations: https://github.com/mckenna654/Everfrost/blob/main/docs/GEAR.md
