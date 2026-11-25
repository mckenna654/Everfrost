# Development handoff

Created October 3, 2026 from the Forever Guide v0.3.1 chat deliverable. Everfrost v0.4.0 introduces the project structure and new brand. Original chat artifacts remain as historical copies.

Previously named ForeverRetHelper (Ret only), then ForeverGuide (all nine classes). Levels 1–30 were added after the beta cap increase. Source files are Profiles.lua (rotation content), Core.lua (talent/spell detection), Main.lua (UI/events/commands).

Existing validation covers all classes/specs, level boundaries, learned spell ranks, talent APIs, combat deferral, role toggles and Survival's level-30 melee transition. Run npm test for the full harness.

Known limits: interface 16001 is unverified in the actual client; some guide pages retain older wording; Arcane was previously restricted, but all 27 full guides were accessible in the October 15 audit (see addon/Everfrost/SOURCES.md). New Forever spell names rely on English names when no localization mapping exists. UI rendering and actual game API behavior need in-game verification.

Next in-game checks: confirm header and trained icons, train/respec, level through thresholds, switch role/AoE modes, cast to inspect cooldowns, drag/reload for persistence. Do not assume this is an automated rotation engine.

October 15, 2026: refreshed guide references across all 27 specs, including distinct Mage AoE, Rogue talents, Priest conditions, tank priorities and Shaman totems. Added regression coverage; no release/version change as part of this source audit.

Published v0.4.2 on October 15, 2026 as the latest GitHub release. Fixed native CurseForge TOC discovery using an excluded metadata-only root TOC. Build #362675 completed for commit 03ba40a and generated Release file #9189652 for 1.60.1; downloaded runtime files match the source. Initial file status was Processing.

October 20, 2026: v0.5.0 adds guide-based gear profiles for all 27 specs, item comparisons and native bag/Need/Greed borders. See docs/GEAR.md for explicit scoring assumptions and scope. Comparisons defer during combat and never roll or equip items. Added gear regression coverage and Node-based cross-platform packaging. In-game item APIs and visual hooks still need verification.

0.5.0 guide selector refresh (same version requested): click the title to choose Automatic, explicit Leveling (db.spec=0), or a class tree. Native tooltip-style menu, checked row, detected-tree detail, gear availability hint, outside-click/Escape dismissal and combat-deferred selection. No rotation data changed.

October 20, 2026: user requested a distinct 0.5.1 release for reliable update discovery. Same guide-selector and gear behavior as refreshed 0.5.0; synchronized version metadata and current download documentation.

October 20, 2026, v0.5.2: one-hand/off-hand candidates now search all carried bags for the best usable complete pair against an equipped two-hander. Bag entries retain physical-copy identity; loot candidates use owned companions. Final-loadout unique limits, hand/class/level restrictions, tank shields and learned Dual Wield are enforced. Tooltips name the partner and conditional combined score. Pair scoring remains an additive stat estimate, without weapon-speed or dual-wield penalty simulation. Added unit and mock UI coverage for both candidate directions, paired borders, later-bag partners, removal/loading, loot hints and combat deferral. No rotation rules changed. Version metadata is synchronized for release; actual client verification of pair hints and glows remains outstanding.

Published v0.5.2 on October 20, 2026 (5bfe11d); GitHub latest release has the installable ZIP. Native CurseForge packaging generated file #9263868 for Forever 1.60.1, with all 13 downloaded addon files matching the source after newline normalization. Initial status: Under Review. Updated the CurseForge description for weapon-pair comparisons.

October 20, 2026, unreleased follow-up: user reports no bag glows or Everfrost tooltip appendix with Elemental selected, both with the staff and with the mace/orb equipped. The staff should score higher under Elemental; added a regression for both directions. Corrected gear metadata to query IsEquippableItem instead of rejecting passive equipment through IsUsableItem. Forever's native bag source exposes separate Use and Equip actions (Gethe/wow-ui-source, forever branch, ContainerFrame.lua). Simulated tests pass. The user subsequently confirmed the test ZIP makes the unequipped staff glow. This is one in-game confirmation of that comparison, not full client validation. No new release published.

The user requested a more prominent glow and an Upgrade tooltip label after testing the eligibility fix. The new local test build adds a steady three-pixel gold outline and brighter 0.7–1 pulse, plus a clear UPGRADE heading. Native TooltipDataProcessor item post-calls (legacy SetBagItem fallback) preserve the comparison after hovered-tooltip rebuilds. OnTooltipCleared resets duplicate prevention. Added simulated coverage for rebuilding tooltips, pair/loot wording, outline cleanup and combat deferral. Supplied as a separate test ZIP; retain 0.5.2 metadata and do not publish until requested. Actual visual appearance and tooltip persistence still require user testing.

The user confirmed the brighter test ZIP is visible, then requested a dim-to-bright pulse and rarity colours. The current local build replaces the steady gold outline with synchronized alpha animations on all five layers, fading 0.18–1 over 0.7 seconds in each direction. Rarity RGB is read/cached outside combat through C_Item.GetItemQualityColor (legacy global fallback); unavailable or restricted metadata uses neutral white. Bag and loot button reuse updates the colour without restarting an already-running animation. Tests cover green/blue/purple reuse, missing/secret colour data, full-layer pulse parameters, cleanup and repaint continuity. This is still an unpublished test build at version 0.5.2.

Unreleased settings UI: added Settings.lua before Main.lua in the TOC. /everfrost (and settings/config) now opens the native-style Guide / Panel / Gear window; /everfrost show explicitly shows the reference panel. Main supplies cached class/spec/level/priority state and routes controls through existing commands/selectGuide. No rotation rules changed. A draggable minimap logo button saves minimapAngle and minimap visibility in EverfrostDB (default visible); left-click opens settings, right-click toggles the panel. /everfrost minimap on/off offers recovery when hidden. Registered a launcher using Settings.RegisterCanvasLayoutCategory/RegisterAddOnCategory, falling back to InterfaceOptions_AddCategory. Opening settings is blocked during combat; existing open guide selections defer and scan controls disable until combat ends. The settings window is Escape-dismissable and draggable. Tests cover all three entry points, controls, class changes, modern/legacy registration and absent minimap. Seven Lua source files / 14 packaged files. User confirmed the rarity-pulse test looks good; the new settings rendering, minimap behavior and native category still need actual Forever testing. Keep this as a local 0.5.2 test ZIP; do not publish until requested.

User tested the settings window and confirmed priorities display after choosing a manual spec. Requested Leveling gear inference from talent points at level 10+. Added a separate cached effective gearSpec in Main; it keeps the selected Leveling spell guide and uses the active talent group's dominant positive tree for gear. NS.DetectSpec now returns a third boolean indicating that all three point counts were read, without changing its existing tree/status contract. Ties/unspent/unavailable/partial counts leave Leveling unscored; manual trees still override. Both scoring context and settings/command priorities use the same gearSpec and its role (including Survival ranged gates). Updated guide hints and Gear heading to show the inferred spec. Added regression cases for levels 9/10, all classes, manual overrides, ties/unspent/partial/fallback data, respec, active-group changes using Forever's pointsSpent return 7/group argument 6, combat caching and Survival roles. No rotation priorities changed. Remains an unpublished 0.5.2 test ZIP; in-game talent inference still needs verification.

User requested a clear level-10 stat-priority note in settings and tooltips. Added shared gearMinLevel/gearLevelNote metadata to GearProfiles.lua. Settings Guide/Gear pages, item/panel hover tooltips, guide menu and addon Notes display the cutoff. Gear.Compare and Main now leave all gear comparisons unscored before 10, including explicit manual trees, so the note is accurate. Existing spell guides and manual guide choices still work below 10. Tests cover all levels 1–9, the level-10 boundary, manual selections and tooltip note/priority suppression. Still an unpublished 0.5.2 test ZIP.

User requested a cleaner, more native settings UI. Replaced the tooltip-style 500x450 frame and left sidebar with a 448x388 DefaultPanelTemplate, native InsetFrameTemplate and top tabs using TabSystemButtonArtTemplate. Verified these contracts against Gethe/wow-ui-source's forever SharedUIPanelTemplates.xml and Shared/TabSystem/TabSystemTemplates.lua. Use the art mixin directly with explicit OnClick/SetTabSelected; no TabSystem owner callbacks are required. Native font objects replace custom SetFont sizes. All label text is top-aligned (the old fixed-height priority label was vertically centred, causing the perceived gap). Compacted checkbox rows, shortened help text, kept the level-10 note and replaced +/- sizing with UISliderTemplateWithLabels, guarded during refresh to avoid callback loops. Tests cover native child bindings, tab state, slider limits and persistence; all existing tests pass. New template rendering still needs an actual Forever check. Packaged locally as another 0.5.2 test ZIP; no publication.

Unreleased native talent detection fix: user screenshot shows Elemental Combat 9 / Enhancement 0 / Restoration 0 while Everfrost reports Unspent. Core now prefers the active spec group's combat config, C_Traits.GetConfigInfo treeIDs, GetGroupDisplayInfoByTreeID groups and GetGroupCurrencyInfo currencyInfos[1].spent, matching Forever's native talent headers. Currency rows match by group ID, not return order; absent groups in a valid list default to zero like the headers. Invalid/secret/unready data, ambiguous trees and staged config changes remain unavailable rather than falling back to misleading specialization zeros. Legacy APIs remain fallback when the native path is absent. Added trait/config events, cached point splits in settings and /everfrost status diagnostics. Regression coverage includes the native 9/0/0 case despite zero specialization tuples, group switching, shuffled/omitted zero currency rows, pending/staged/secret data, integration with Leveling gear/manual overrides and combat deferral. Simulated checks pass; actual Forever verification of this fix is still needed. Remains local 0.5.2; no publication requested.

Native implementation reference: https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_PlayerSpells/Camelot/ClassTalents/Blizzard_ClassTalentsFrame.lua (RefreshTreeHeaders, GetFallbackConfigID, SetTab and ClassTalentTreeHeaderMixin:Setup). API definitions: https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SharedTraitsDocumentation.lua.

October 20, 2026 release consolidation requested by user: retain original 0.5.0 at 875a5f5, combine the guide-selector refresh/original 0.5.1/former 0.5.2 into a rebuilt 0.5.1 with synchronized metadata, and publish all subsequent local fixes/settings/talent detection as 0.6.0. Earlier entries above record the original sequence; the combined changelog is the current public release history. Superseded CurseForge files are to be archived, preserving the first 0.5.0. Git commit history remains intact. User explicitly authorized GitHub/CurseForge releases and description updates.

Completed consolidation/publication: 0.5.0 restored to original 875a5f5;
0.5.1 rebuilt at 093d6a4; 0.6.0 released at ab361cd and marked GitHub latest.
CurseForge automatically generated approved 1.60.1 files #9264544 (0.5.1)
and #9264545 (0.6.0), downloaded and verified against all 13/14 source files
respectively. Redundant files #9262809/#9262832/#9263868 are archived, with
the original #9262577 retained. Updated both descriptions, combined current
changelog entries and synchronized metadata. Both release test suites pass;
latest native talent detection still needs user confirmation in game.

Local follow-up after 0.6.0 publication: added db.opacity (default 1, normalized
to 0.1–1) and /everfrost opacity 10–100, plus a live Rotation Panel slider.
Alpha is applied only to EverfrostFrame; settings, the UIParent-owned guide
menu and tooltips remain independent. The position/size reset retains opacity.
Restyled the reference panel with native BACKDROP_DIALOG_32_32 (equivalent
local fallback), gold GameFontNormal title, standard font objects, native
UIPanelButtonTemplate controls and UI-Quickslot2 spell borders. Removed the
flat class accent/chip backgrounds. Slightly increased internal padding while
retaining six columns and the compact layout. No guide rules changed.
Native backdrop verified against Gethe/wow-ui-source forever,
Interface/AddOns/Blizzard_SharedXML/Backdrop.lua. Tests cover slider limits,
invalid command/saved data, live alpha, persistence after login/redraw/reset,
combat changes and opacity isolation; existing rotation/gear tests pass.
Still local 0.6.0 metadata: no release, upload or game installation requested.
Actual new panel appearance/opacity behavior needs client verification.

User requested publication of the panel opacity/native styling follow-up.
Released as 0.6.1 at 65b955a so addon managers can discover it; synchronized
both TOCs, package.json and lockfile. GitHub latest includes the verified
installable ZIP. Automatic CurseForge package #9264703 targets Forever
1.60.1; all 14 downloaded files match source after newline normalization.
Initial status Under Review. Public description now includes the 10–100%
opacity setting and native panel appearance. No game-folder install.

Local spec-picker cleanup after 0.6.1: user requested removing redundant grey
second lines and renaming Choose a guide. Menu is now Choose a Spec with
single-line 26px rows at 28px spacing, 244px width and a normal 188px height.
Automatic includes the detected tree inline. Removed row descriptions,
divider and generic saved-choice footer; only relevant level-10/combat
notices add a 24px footer. Selected check/highlight, saved choices, dismissal
and deferred combat changes remain. npm test and addon-only build pass.
Still local 0.6.1 metadata; no publication requested for this follow-up.
Actual new menu rendering needs an in-game check.

User requested publication of the compact spec menu. Released 0.6.2 at
f23ed43 with synchronized TOCs/package/lockfile and GitHub latest ZIP.
CurseForge automatically generated #9264796 for Forever 1.60.1; all 14
downloaded addon files match source after newline normalization. Initial
status Under Review. Public description updated. No game-folder install.

October 24, 2026, v0.6.3 (Claude cloud session): code review fixes, prepared
for release at the user's request. Published on October 24, 2026: the
session's GitHub proxy denied tag pushes and tag/release API writes, so the
release was created through the user's signed-in GitHub web UI (built-in
browser). GitHub latest v0.6.3 (release 422504060), lightweight tag at
2a5c0cf (docs-only commit after 8b5047c; addon files identical). Asset
Everfrost-0.6.3.zip SHA-256 53433e769b893b92c146056c036c44c01e13cfbe5d2324490996b3120373c2f4
matches the locally built and verified archive. The CurseForge webhook
delivered the refs/tags/v0.6.3 push with HTTP 200. The CurseForge file ID,
processing/moderation status and downloaded-file check are still to do: the
built-in browser is not signed in to authors.curseforge.com.
- Gear.Score counted Attack Power twice for profiles that rank it (only
  Subtlety Rogue), so AP outscored Agility. Fixed; other melee specs keep the
  existing half-Strength AP credit (unchanged, worth a design review: rogues
  and Survival hunters arguably should follow Agility).
- Compare results now mark data-dependent unknowns with waiting=true.
  GearUI rescans on GET_ITEM_INFO_RECEIVED / ITEM_DATA_LOAD_RESULT only for
  those, ending constant full rescans for level 1-9 and untalented characters.
- Gear.Refresh skips all item reads when highlights are off.
- NS.SpellNames caches a class's localized map once every baseID resolves.
- Added .github/workflows/test.yml (luacheck globals-only via .luacheckrc,
  npm ci/test/build on Node 24) and regression tests for each change.
- Reviewed and kept: Subtlety "at 30 prefer Rupture" hint on Slice and Dice
  matches the current Icy Veins guide (Rupture beats SnD at 30).
- Not changed (needs tests that tick OnUpdate): Main.lua still refreshes
  synchronously on every spellbook/talent event; coalescing would require
  updating check.cjs to advance frames.
- The cloud session could not run npm locally (registry blocked); GitHub
  Actions ran the suite. No in-game testing of these changes.

October 24, 2026, v0.6.4: CurseForge rejected file #9305163 (v0.6.3):
"Addon does not contain a .toc file. Folder Everfrost-Source must contain a
file named Everfrost-Source.toc." Its ZIP held Everfrost-Source/CLAUDE.md,
added by the earlier Claude/Codex setup commit and missing from .pkgmeta
ignore. Fixed .pkgmeta and added a packaging regression check in check.cjs.
Released as 0.6.4 rather than moving the v0.6.3 tag. Addon code identical to
0.6.3. The GitHub v0.6.3 release remains (its ZIP is correct).
Published 0.6.4: GitHub latest v0.6.4 (fe1f0de) and CurseForge file
#9305197, Under Review, all 14 files verified against source. Next steps:
copy docs/CURSEFORGE.md into the public CurseForge description if wanted,
and in-game checks of the 0.6.3 gear changes (Subtlety upgrades, gear-off).

November 4, 2026, unreleased UI polish (branch claude/ui-polish): status
lines now share one format ("Elemental Shaman", "Level 18 / Auto",
"Shaman / Level 18") with single spaces and no uppercase; secondary text is
0.8 grey and footers/status 0.6 grey instead of six near-identical greys;
the level-10 note no longer repeats in item tooltips once gear is scored
(it stays in settings and in tooltips below level 10). No rotation or gear
rules changed. npm test and luacheck pass. The new text and colours still
need an in-game look. Next step: review the PR, then merge and bump the
version when releasing.

Published 0.6.5 on November 4, 2026: GitHub latest v0.6.5 (701fc5c) with the
PR #3 text and colour polish; version bumped in both TOCs, package.json,
package-lock.json, README and CHANGELOG. CurseForge generated Release file
#9430703 for 1.60.1 (Processing when last checked); its 14 addon files match
the tag. The public CurseForge description is updated from docs/CURSEFORGE.md.
Next steps: confirm the file gets approved, and check the new header text and
greys in game.

November 5, 2026, released as 0.6.6 (PR #4, branch claude/armour-tie-breaker): the user's
screenshot showed Warrior's Girdle (50 armor, mail) marked "No useful stats" for
Retribution against Ragged Leather Belt (18 armor). Armor is unweighted for
non-tank profiles and the stat gate returned before any comparison. User chose
armor as a tie-breaker rather than a scored stat. Gear.Compare now lets armor
pieces and shields through that gate; more armor with no loss on score is an
upgrade (result.armorOnly, tooltip states the gain, score line omitted). A
candidate with no useful stats can only replace another such item, so Stamina
cannot stand in for lost Strength. This also means Need highlights on group loot
for these items. Weapons and two-hander pairs are unchanged. The stamina-only
wording ("No useful stats" although Stamina is listed for Retribution) remains
for items that do not gain armor. Also added a steady green up arrow on bag
upgrades using the native bags-greenarrow atlas (Forever ContainerFrame.xml);
roll buttons keep the glow only. npm test and the build pass; luacheck was not
run on this PC (CI runs it and passed). Before release, the user reported that
everything works in game. Original test notes, for reference: check the arrow's
position and visibility against the glow, the belt tooltip, and that
RESISTANCE0_NAME really reports armor in Forever, since the tie-break depends on
it. Public descriptions and CHANGELOG were updated in the 0.6.6 release commit.

Published 0.6.6 on November 5, 2026: GitHub latest v0.6.6 (a053c22) with PR #4.
See docs/RELEASING.md for the checksum and webhook delivery. CurseForge generated
Release file #9450295 for 1.60.1; its 14 addon files match the tag. The author
console shows it with the same status as approved files. The public description
is updated from docs/CURSEFORGE.md. Next step: confirm v0.6.6 is the main file on
the public CurseForge page.

November 5, 2026, unreleased review fixes (branch claude/review-fixes), from a
full-project code review checked against Gethe/wow-ui-source's forever branch:
- Loot rolls: Need/Greed highlights now find Forever's buttons inside
  LootButtonContainer (previously never found there), and hiding the UI no
  longer cancels a live roll; only the loot events end one.
- Bags: the ContainerFrameItemButtonMixin.Initialize hook now reads Forever's
  (containerFrame, bag, slot) arguments. It was treating the frame as the bag
  and untracking the button. Reused buttons keep one set of script hooks.
- Scoring: Attack Power uses half the higher of Strength or Agility, plain
  wands count for Priests, Mages and Warlocks, and Unique-Equipped category -1
  limits duplicates.
- Survival's role button is hidden until level 30 with Strider Kick.
- Glow pulses keep running through bag changes outside combat. Item data stays
  cached between rescans (/everfrost refresh and Rescan bags clear it), and the
  full bag-button walk only runs after login, addon load or combat.
- UI copy and docs use Australian spelling: Specialisation, Levelling, Armour,
  Defence. Game spell names and API names are unchanged; `/everfrost spec
  leveling` still works alongside `levelling`.
- build.cjs now fails if the packaged README's version is wrong.
npm test, luacheck and npm run build pass. None of this has been seen in game.
Screenshots still show the old US spellings. Not fixed from the review's
left-overs: duplicated first/public helpers, scripts/build.ps1, no .nvmrc.
Next steps: test a real group-loot roll in game (this is the first time the
Need/Greed glow should reach Forever's buttons), then release when wanted.
docs/CURSEFORGE.md uses the new spellings but the public page has not changed.

Published 0.6.7 on November 5, 2026: PR #5 merged, GitHub latest v0.6.7
(29a4d87), CurseForge Release file #9451760 for 1.60.1 (Processing when last
checked; contents match the tag), public description updated. Not checked in
game. Next steps: confirm the file gets approved, try a real group-loot roll in
game (the first real test of the Need/Greed highlights on Forever), and retake
the README screenshots that still show US spellings.

November 5, 2026, unreleased early-game gear help (branch claude/early-gear-help):
- Below level 10, NS.GearProfile returns a per-class starter list
  (NS.gearStarter in GearProfiles.lua), so bag, loot, quest and merchant hints
  work from level 1. The lists are Everfrost estimates, not guide rankings;
  worth comparing with the Icy Veins levelling sections.
- Quest choices (QuestInfo_Display hook) mark the best upgrade, or the highest
  sell value in gold with no arrow. Merchants (MerchantFrame_Update hook) mark
  affordable upgrades on the buy tab. Both were written from the Mainline
  QuestInfo.lua and MerchantFrame.lua in Gethe/wow-ui-source's forever branch.
- Tooltips add a plain-word reason (result.why); starter tooltips hide the score.
- Empty armour slot counts on the Gear Upgrades page; panel caption for no weapon.
npm test and luacheck pass with a simulated client. None of this has been seen
in game, including glow placement on quest and merchant buttons, and the Gear
Upgrades page layout. Next steps: test at low level (quest reward screen, a
vendor, empty slots), then review and merge. At release, add the CHANGELOG entry
and What's new in docs/CURSEFORGE.md; its body already describes these features.

Published 0.6.8 on November 5, 2026: PR #6 merged, GitHub latest v0.6.8
(10cdca0), CurseForge Release file #9452825 for 1.60.1 (Processing when last
checked; contents match the tag), public description updated. Released at the
user's go-ahead without an in-game test on record. Next steps: confirm the file
gets approved; on a low-level character check a quest reward screen, a vendor,
the Gear Upgrades page layout and a real group-loot roll; compare the starter
lists with the Icy Veins levelling sections; retake the README screenshots.

November 5, 2026, unreleased: the spec menu footer below level 10 now reads "Full stat priorities need talents." at the user's request, replacing "Starter gear hints until level 10.". It is the same length, so it should fit the footer's single line; not yet seen in game.

Published 0.6.9 on November 5, 2026: PR #7 merged, GitHub latest v0.6.9 (660d5ae),
CurseForge Release file #9453332 for 1.60.1 (contents match the tag; not yet on the
public files page when last checked), public description updated. The only addon
code change is the spec menu note. Dependabot PR #2 (GitHub Actions bumps) was left
open. Next steps are unchanged from 0.6.8: check the quest, merchant, Gear Upgrades
and group-loot screens in game, compare the starter lists with the Icy Veins
levelling sections, and retake the screenshots.

November 11, 2026, unreleased, branch claude/audit-fixes (pull request open): fixes from a
whole-project audit, plus two requests from the user (armour in gear scoring, a tidier
upgrade and Need/Greed highlight).
- Armour counts for every spec at 0.1 per point on armour pieces and shields (docs/GEAR.md,
  rule 9). It replaces the 0.6.6 rule that armour only breaks ties; an item with no useful
  stats still cannot replace one that has them. The rate is an estimate to tune in game.
- Highlight: two-pixel outline flush with the slot, glow sized to the button, a slower
  eased pulse (40% to 100% over 0.9 s); roll buttons get the glow without the square.
- Spell, talent and trait events are batched into one refresh per frame (Main.lua).
- Past level 30 the panel hides once with a chat line; /everfrost show brings it back.
- Feral with no form learned has no Cat/Bear button. /everfrost spellids reports IDs for
  the ten guide spells that match by English name only. Full luacheck is on.
- VALIDATION.txt moved from the package to docs/. TOC author is mckenna654. New
  docs/INGAME_CHECKLIST.md is the release gate (docs/RELEASING.md step 0).
npm test, luacheck and npm run build pass. Nothing here has been seen in game: the
highlight's look, armour results on real items and the batching are all unverified.
Not done from the audit: splitting the two test files, a code formatter, account-wide
settings, a smaller icon, a key binding and new screenshots. The Frost Mage stat order
was checked against docs/GEAR.md and is as the guide has it. Next steps: walk the
in-game checklist with the build in dist/, tune the armour rate and the pulse if they
look wrong, add the spell IDs, then version, changelog and release.

November 11, 2026, later, same branch and pull request (#8): level 60 support and the rest
of the audit's small items, at the user's request.
- Icy Veins blocks plain fetches (HTTP 403), so the guides were read in the user's Chrome.
  All 27 were updated for the November 4 launch (level cap 60). The Rotation, Stats and
  Milestones sections of each levelling guide and each stat page's table were read; what
  was added and left out is in addon/Everfrost/SOURCES.md (last section).
- NS.maxLevel is 60. The 31-60 steps are at the end of Profiles.lua, added by name
  (put/own helpers) rather than by index. Slam shows from 20. Longest list is 15 icons.
- Gear: 17 of 27 stat orders changed (docs/GEAR.md table); plate and mail from level 40.
- Bindings.xml adds a show/hide key binding; EverfrostAccountDB (SavedVariables) carries
  panel size, opacity, lock, minimap and gear switches to new characters; Icon.tga is
  64x64 (was 256x256).
- Seven new guide spells have no ID (17 in all); run /everfrost spellids in game.
npm test, luacheck and npm run build pass. Nothing has been seen in game. The new spell
names and IDs come from the guides and standard IDs, not from the Forever client, so a
name the client spells differently would simply never show: check a level 40+ character.
Not done: splitting the test files, a code formatter and new screenshots.

November 11, 2026, later still (same pull request): at the user's request, passive "Equip:"
tooltip effects are read into gear scores (Gear.lua G.EquipEffects, via C_TooltipInfo.GetHyperlink;
docs/GEAR.md rule 10). English wording only. Unverified in game: whether Forever has
C_TooltipInfo, and the exact wording of its Equip lines. If an item with such a line still
scores without it, hover it and report the line's exact text.

Published 0.7.0 beta 1 on November 11, 2026 at the user's request ("merge and update it
all on github and curseforge"): PR #8 merged, branch deleted, GitHub pre-release
v0.7.0-beta.1 (c2c3088) with the ZIP. Tagged as a beta, not a release, because nothing in
it has been seen in game; GitHub "latest" and CurseForge's Release channel stay on 0.6.9.
The CurseForge webhook returned 200; the file itself is unconfirmed (docs/RELEASING.md).
Next steps: the user checks the file in the CurseForge author console; walks
docs/INGAME_CHECKLIST.md (include a level 40+ character); sends /everfrost spellids
output. Then promote: tag v0.7.0, mark it latest, update the CurseForge description from
docs/CURSEFORGE.md, and set the README's download link and status row to 0.7.0.

Published 0.7.0 on November 11, 2026 at the user's request ("update and push to github and
curseforge now"), without an in-game test: GitHub latest v0.7.0 (06c590c). The CurseForge
webhook returned 200 for the tag, but the file was not yet on the public page and the
author console was signed out, so the file and the public description are unconfirmed
(docs/RELEASING.md). Next steps: in the CurseForge author console, check the v0.7.0 file
is a Release for 1.60.1 and paste docs/CURSEFORGE.md into the description; walk
docs/INGAME_CHECKLIST.md; retake the screenshots.

CurseForge confirmed on November 11, 2026: v0.7.0 is a Release for 1.60.1 and Under
Review (the beta file is Approved); the public description and summary are updated for
0.7.0. Next steps: confirm v0.7.0 gets approved; walk docs/INGAME_CHECKLIST.md; retake
the screenshots.

November 11, 2026: the v0.7.0-beta.1 pre-release and tag were deleted from GitHub and the beta
file archived on CurseForge, at the user's request. Only v0.7.0 remains. The user prefers plain
version names like the earlier releases; don't publish beta-tagged versions unless he asks.

November 11, 2026, unreleased, branch claude/talents-resize (pull request open): talent
recommendations and a resizable panel, at the user's request.
- Talents: scripts/talent-data.py holds the 27 Icy Veins levelling builds (one letter per
  point, level 10 to 60) and each class's talent names, read in the user's Chrome, and writes
  addon/Everfrost/TalentData.lua. Talents.lua reads taken ranks (C_Traits nodes, else
  GetTalentInfo), finds the next pick, glows that button in the talent window and adds tooltip
  lines. The window's buttons are found through EnumerateAllTalentButtons on PlayerSpellsFrame
  .TalentsFrame, ClassTalentFrame(.TalentsTab), PlayerTalentFrame or TalentFrame, or as
  PlayerTalentFrameTalentN. None of that has been seen on the Forever client: if nothing shows,
  the frame name and node API are the first things to check.
- Resize: a grip in the panel's corner scales it about its top-left (db.scale, 0.6 to 2).
npm test, luacheck and npm run build pass. Nothing seen in game. Not released; version still 0.7.0.

Published 0.8.0 on November 11, 2026 at the user's request, without an in-game test: PR #9
merged, GitHub latest v0.8.0 (1ad850c), CurseForge Release file for 1.60.1 (Processing when
checked), public description updated. Next steps: confirm the file is approved; in game,
check the talent window's gold glow and tooltip lines, /everfrost talents, and the resize
corner (docs/INGAME_CHECKLIST.md items 15 and 16). When chaining a merge with branch
deletion, check the merge succeeded first.

November 24, 2026, unreleased, branch claude/rotation-hud (uncommitted at the user's request:
"Do not commit, publish, or push changes ... unless explicitly instructed"): the user's
"complete UI/UX and rotation engine overhaul" brief.
- Forever facts used (Gethe/wow-ui-source branch `forever`, 1.60.1.71037): the combat log is
  restricted; spell cooldowns, threat, auras and unit identity can be secret in combat;
  C_AssistedCombat (GetNextCastSpell, IsAvailable) exists and drives Blizzard's own action-bar
  highlight; C_InputInterfaceStyle.GetCurrentStyle and INPUT_DEVICE_INTERFACE_TRANSITION report
  keyboard or gamepad; C_Spell.IsSpellUsable returns plain booleans.
- Rotation HUD replaces the panel (Combat.lua engine, enemy estimate, modes and input; HUD.lua
  drawing; Main.lua wiring). NOW = Blizzard's assistant if available, else the first guide spell
  the game says is ready. Upcoming = guide order. Upkeep spells (NS.upkeep) only as reminders when
  the game says the buff is missing (out of combat). Utility row from NS.utility, never "urgent".
  Four layouts, one engine. Combat-only by default; click-through in combat.
- AUTO mode: nameplate estimate (alive, attackable, in combat, not pets/totems, on threat list
  where readable; group fallback), thresholds per spec (db.hud.thresholds["PALADIN2"]), step down
  after db.hud.grace (1.5 s), unseen enemies kept db.hud.stale (5 s). Secret -> "?" and single.
  Cleave = single list + NS.cleaveSpells.
- Input: game input style with 0.75 s debounce; keyboard layout keeps db.point/x/y and db.scale,
  controller layout uses db.hud.pad and db.hud.padScale.
- Saved variables: EverfrostDB.version=2, EverfrostDB.hud (see hudDefaults in Main.lua); db.aoe
  migrates to hud.mode "aoe" and is removed. Gear focus per spec: db.gearFocus["PALADIN2"].
- Settings: six tabs (Rotation, HUD, Controller, Detection, Gear & Loot, Talents).
- Gear (helper agent): one engine with verdict tiers (clear >=10%, minor >=3%), tank focus profiles,
  two-hander vs weapon+shield, thin borders, quest "Recommended". See docs/GEAR.md.
- Talents (helper agent): next legal build pick, prerequisites/row gates/level, reasons, one
  overlay per button. See docs/INGAME_CHECKLIST.md item 15.
- Not done: no new Protection Paladin rotation rules (Icy Veins refused automated reading; the
  11 November guide data stands, so Holy Shield isn't in the track). Profile import/export doesn't
  exist and wasn't added. No screenshots.
npm test (check, gear, gear-verdicts, talents, hud), luacheck and npm run build pass. Nothing seen
in game. Next: the user commits/merges when ready; walk docs/INGAME_CHECKLIST.md items 15 and
17-25 on the Protection Paladin; report /everfrost status (says whether Blizzard's assistant is
available) and whether the enemy count shows numbers or "?" in dungeons.

November 24, 2026, later (same branch, still uncommitted): all 27 Icy Veins rotation pages were
read in the user's Chrome (Claude in Chrome; Icy Veins refuses plain fetches) and every tree's
list rebuilt at the end of Profiles.lua. New `proc` flag on steps: never NOW from the guide alone.
BuildRows shows a spell once even if listed for single and AoE. ~45 spell IDs added from Icy
Veins' Forever spell links (Penance changed to 402174); only Sniper Shot is still English-only.
Details and ambiguities: addon/Everfrost/SOURCES.md, "November 24 review". Not done: stat
priorities and talent builds weren't re-read. Check in game: `/everfrost spellids` on a few
classes to confirm the new IDs resolve.

Published 0.9.0 on November 24, 2026 at the user's request ("merge and update github and
curseforge including release notes"), without an in-game test: PR #10 merged (3a4133e), branch
deleted, GitHub latest v0.9.0 with Everfrost-0.9.0.zip and notes from the changelog. The webhook
returned 200; CurseForge built file 9784693 (Everfrost-Source-v0.9.0.zip) as a Release for 1.60.1,
Under Review when checked, with the changelog as its notes. The CurseForge description
(docs/CURSEFORGE.md) and summary were updated in the author console. The CurseForge ZIP itself was
not downloaded and inspected. Next: confirm approval; walk docs/INGAME_CHECKLIST.md items 15 and
17-25 on the Protection Paladin; `/everfrost spellids` to confirm the new IDs; new screenshots.

November 24, 2026: replaced the README screenshots with 0.9.0 captures taken in the user's Forever client (level-35 Protection Paladin): all six settings tabs, the rotation HUD out of combat with its hover tooltip, gear upgrade and "better for another tree" tooltips, and the talent-build tooltip. Images are cropped from WoW's own full-resolution screenshots, with player names cropped out; the 0.8.0 images stay in docs/assets/screenshots in case anything links to them. Seen in game while capturing, not yet fixed: on the Rotation tab, the "NOW from Blizzard's rotation assistant" checkbox label wraps into the line below it, and that line shows the raw client reason `WRONG_WORLD_STATE_EXPRESSION` ("Not available here: …"). The rotation assistant may simply be unavailable in Forever; the message should be friendlier and the layout needs more room. Combat behaviour of the HUD was not checked.

November 24, 2026, later: at the user's request, removed the six October 20 screenshots (gear-upgrade-settings, gear-upgrade-tooltip, rotation-panel-settings, rotation-panel, specialization-settings, spell-guidance-tooltip) from docs/assets/screenshots. Nothing in the repo or the release notes linked to them; they remain in git history and at the old release tags. Only the v0.9 captures are left.
The same six were deleted from the CurseForge gallery in the author console (Media tab), leaving the 11 v0.9 images. CurseForge showed "There was an error when deleting the image" during the bulk delete, but the console listed only the 11 afterwards. The public gallery page still listed two of the old ones (Gear Upgrades settings, Rotation Panel settings) a few minutes later, which looks like a cached page: recheck it.

November 25, 2026, branch `claude/stat-weights` (PR open, not merged, not released; version still 0.9.0). The user asked for three things: a reliable source of numeric stat weights per spec "instead of just using A is better than B", a green percentage like Pawn's in place of the upgrade arrow (they sent a screenshot of an icon reading +48%), and a settings menu to customise the weights.
- Source: the wowsims WoW Forever simulator (wowsims.com/forever, github.com/wowsims/forever, MIT), per-spec EP presets at commit d45287b. It covers 17 of the 27 trees plus Protection Warrior's Offensive preset (used for Tank Threat) and Bear (Bear Balanced). Nothing publishes numbers for Mage, Warlock, Holy/Protection Paladin, Restoration Druid or Restoration Shaman (Wowhead's Forever pages, read in Chrome, give orders only), so those ten keep rank-weight estimates and are labelled as estimates. Pawn's defaults and a few small addons were found and not used. Details: addon/Everfrost/SOURCES.md "November 25" and docs/GEAR.md.
- Engine: a weight is now the value of one point as the item shows it. Simulator weights are per rating point, so percentage stats are multiplied by rating per 1% (Hit 10, Crit 14, Haste 10, Expertise 10, Dodge 12, Parry 15, Block 5). Estimates bake in the old x12 for weapon DPS and 0.1 for armour, and now scale percentage stats the same way. Simulated damage and healing profiles get a small Everfrost allowance for Stamina and armour (my judgement, not the simulator's; the numbers are in GearProfiles.lua). Off-hand weapons use the preset's off-hand DPS weight. Block value and block chance are separate stats. The Bear estimate focuses now rank weapon DPS, because the simulator values it in both forms. The tier comparison has a 1e-9 tolerance now that weights are decimals.
- UI: bag, vendor and quest-icon upgrades show `+48%` / `>200%` / `NEW` in the bottom-right corner; the arrow is gone. Settings > Gear & Loot has a "Stat weights" button opening a 21-stat page (no tab of its own) with edit boxes, gold for changed stats, Reset and Back. `/everfrost weights` and `/everfrost weights reset`. Saved per character in `EverfrostDB.gearWeights[profile id]`, only the changed stats.
- Verified: npm test (check, gear, gear-verdicts with 1225 checks, talents, hud), luacheck and npm run build. Nothing seen in game.
- Unverified, in docs/INGAME_CHECKLIST.md items 26-28: how the percentage sits on a real bag slot and whether `NumberFontNormalSmall` exists in Forever (falls back to GameFontNormalSmall); whether the client's item stats report Hit/Crit as one point per percent as the tooltip wording does (if they report rating points, those stats are overvalued tenfold); the expertise token; the `InputBoxTemplate` edit boxes and the page's three-column fit.
- Judgement calls the user has not confirmed: showing the percentage on minor upgrades as well as clear ones; using level 60 raid weights for levelling characters (stated in the README and on the page); which preset each tree uses (single-target healing, Combat Sinister, Unsealed Wrath, Turret for BM/MM, Balance Pre-BiS).
- docs/CURSEFORGE.md already describes the new behaviour. Do not paste it into the CurseForge description until this is released.
- Next: the user tests the build (dist/Everfrost-0.9.0.zip from this branch) and says whether to merge and release (0.10.0 would fit: TOCs, package.json, lockfile, changelog heading). Recheck wowsims for new presets (Mage and Warlock especially) before releasing. Not done: a Pawn-string import box, per-level weights, raid-healing presets as a focus for Priests.

Published 0.10.0 on November 25, 2026 at the user's request ("merge and release"), without an in-game test: PR #11 merged (5ea44bc), branch deleted, annotated tag v0.10.0, GitHub latest with Everfrost-0.10.0.zip and notes from the changelog. CurseForge built v0.10.0 as a Release for 1.60.1 (Under Review when checked) and its description now matches docs/CURSEFORGE.md. The CurseForge ZIP was not downloaded and inspected. The public gallery now shows the 11 v0.9 images only (the two stale October ones from the earlier clean-up are gone). Next: confirm approval; walk docs/INGAME_CHECKLIST.md items 26-28 (percentage label, Hit/Crit units, stat weights page); new screenshots showing the percentage and the stat weights page; watch wowsims for Mage, Warlock and healer presets.

November 25, 2026, branch `claude/controller-position` (PR open, not merged or released). The user reported that in combat the HUD moves to the centre of the screen, ignoring where they put it, and asked whether that is a setting or an error. The game is not installed on this Mac, so their saved settings could not be read. From the code, the only thing that repositions the HUD in combat is the switch to the controller layout (`applyPosition` runs on input changes), whose position is saved separately and defaulted to the centre (0,-120). Dragging needs the mouse, which puts the HUD back on the keyboard layout, so the position a controller player sets is saved to the keyboard layout and the controller layout stays at its default. Change: a controller layout with no saved position now uses the keyboard layout's saved position, converted for the difference in scale; with neither saved it keeps its own default. `/everfrost reset` in the controller layout therefore follows the keyboard position again. Not confirmed with the user: that they play with a controller (or gamepad mode); if they don't, the layout is switching for another reason and `/everfrost status` in combat (it prints "Layout: pad" or "kbm") is the thing to ask for. Workaround in 0.10.0: Settings > Controller > One position. npm test and luacheck pass; nothing seen in game.

November 25, 2026, same branch `claude/controller-position` (PR #12, still not merged or released). The user asked for the talent choice and the Need/Greed marks to be "way more evident. It's quite faint." Their 0.9.0 talent screenshot shows why the talent mark was lost: Forever's own window draws a gold border on every talent with points in it, and Everfrost's highlight was a 2-pixel gold outline that faded to 35%. Now: a solid 3-pixel ice-blue outline (my choice of colour, to differ from gold; not confirmed with the user), the action-button border art drawn twice as a pulsing glow (100% to 40%, 0.7 s) and the word NEXT on a dark strip above the button. Need/Greed: the ring is drawn twice for thickness; clear upgrade bright green at 100% pulsing 50-100% over 0.7 s, minor upgrade steady at 85%, Greed a steady gold ring at 85% (was 30% grey); the roll frame's `IconFrame`, where it exists, gets the bag-style border and percentage. This reverses the 0.9.0 "restrained marks" decision for rolls only; bag marks are unchanged. npm test and luacheck pass. Nothing seen in game: whether the glow art reads well at these sizes, whether NEXT overlaps a neighbouring talent or a prerequisite arrow, and whether Forever's roll frame has `IconFrame` are in docs/INGAME_CHECKLIST.md items 15 and 29.

November 25, 2026, same branch and PR #12 (not merged or released). The user then asked: "have the kbm and controller rotation window have their own position settings but stop the controller window from always centering." The fallback above stops the centring. The missing piece was a way to give the controller layout its own position at all: dragging needs the mouse, and mouse input switches the HUD to the keyboard layout first. Settings > Controller now has "Position each layout": Place keyboard HUD, Place controller HUD and Done. `NS.Input.placing` ("kbm", "pad" or nil, never saved) overrides `layoutKey()`, so position, size and icon sizes all follow the layout being placed whatever device is in use; the HUD is movable while placing even if locked; closing settings or Done clears it. "One position" mode has no controller layout to place. Tests in tests/hud.cjs. Not seen in game: docs/INGAME_CHECKLIST.md item 30, including whether the reworked Controller page fits.

Published 0.10.1 on November 25, 2026 at the user's request ("merge and push release"), without an in-game test: PR #12 merged (0965b91), branch deleted, annotated tag v0.10.1, GitHub latest with Everfrost-0.10.1.zip and notes from the changelog. CurseForge built v0.10.1 as a Release for 1.60.1 (Processing when checked; v0.10.0 is Approved) and its description matches docs/CURSEFORGE.md. The CurseForge ZIP was not downloaded and inspected. Next: confirm approval; walk docs/INGAME_CHECKLIST.md items 15 and 26-30 (talent highlight, upgrade percentage, Hit/Crit units, stat weights page, roll rings, placing each layout); ask whether the ice-blue talent colour and the roll ring strength are right; new screenshots.
