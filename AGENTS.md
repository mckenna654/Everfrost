# Everfrost project instructions

Everfrost is a standalone WoW Forever Lua addon. Its source of truth is addon/Everfrost, not prior chat output folders.

- Preserve the simple, compact UI and class/spec/level detection.
- Current coverage is levels 1–60, nine classes and 27 talent trees.
- Keep recommendations learned-spell-aware. Review current Icy Veins Forever guides before changing rotation rules; preserve source links.
- This addon displays reference priorities, not a combat-driven next-cast queue. Do not silently change this contract.
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
