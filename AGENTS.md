# Everfrost project instructions

Everfrost is a standalone WoW Forever Lua addon. Its source of truth is addon/Everfrost, not prior chat output folders.

- Preserve the simple, compact UI and class/spec/level detection.
- Current coverage is levels 1–60, nine classes and 27 talent trees.
- Keep recommendations learned-spell-aware. Review current Icy Veins Forever guides before changing rotation rules; preserve source links.
- The rotation HUD's NOW icon is Blizzard's rotation assistant (C_AssistedCombat) where the game offers it, otherwise the highest guide priority the game says is ready. Upcoming icons are guide priorities, labelled as such, never a predicted cast sequence. Enemy counts are estimates from nameplates and say so. Never automate casts, rolls or clicks. (The user asked for this HUD in November 2026; before that Everfrost was a static reference panel.)
- Forever 1.60.1's API definitions are in Gethe/wow-ui-source, branch `forever` (Interface/AddOns/Blizzard_APIDocumentationGenerated). Check an API there before using it: the combat log is restricted, and cooldowns, threat, auras and unit identity can be secret in combat.
- Never create a frame under a game window (`CreateFrame` with a Blizzard frame or button as parent): Forever's controller navigation (Blizzard_GamepadSmartNavigation) hooks `CreateFrame` and re-scans the open window from the caller's context, which from addon code can leave the controller stuck. Draw marks with `button:CreateTexture` / `CreateFontString`. Never assign `UISpecialFrames`; only `table.insert` into it. `tests/check.cjs` enforces both.
- Cache spellbook/talent metadata outside combat. Do not compare or branch on secret combat values. Cooldown duration objects go directly to native widgets.
- Preserve Lua 5.1-compatible syntax and current addon identifiers (Everfrost, EverfrostDB, /everfrost).
- Run npm test after Lua behavior changes; npm run build packages only the addon folder into dist.
- Update the TOC and package.json versions together when releasing.
- Never claim simulated tests prove game compatibility. Actual Forever client testing is still outstanding.
- Do not install into a game folder, publish, or upload unless requested.

See README.md for setup and docs/HANDOFF.md for project history.

## Agent skills

### Issue tracker

Issues live in this repo's GitHub Issues, managed with the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five default labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human` and `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root, created when first needed. See `docs/agents/domain.md`.
