# Development handoff

Created October 3, 2026 from the Forever Guide v0.3.1 chat deliverable. Everfrost v0.4.0 introduces the project structure and new brand. Original chat artifacts remain as historical copies.

Previously named ForeverRetHelper (Ret only), then ForeverGuide (all nine classes). Levels 1–30 were added after the beta cap increase. Source files are Profiles.lua (rotation content), Core.lua (talent/spell detection), Main.lua (UI/events/commands).

Existing validation covers all classes/specs, level boundaries, learned spell ranks, talent APIs, combat deferral, role toggles and Survival's level-30 melee transition. Run npm test for the full harness.

Known limits: interface 16001 is unverified in the actual client; some guide pages retain older wording; Arcane was previously restricted, but all 27 full guides were accessible in the October 15 audit (see addon/Everfrost/SOURCES.md). New Forever spell names rely on English names when no localization mapping exists. UI rendering and actual game API behavior need in-game verification.

Next in-game checks: confirm header and trained icons, train/respec, level through thresholds, switch role/AoE modes, cast to inspect cooldowns, drag/reload for persistence. Do not assume this is an automated rotation engine.

October 15, 2026: refreshed guide references across all 27 specs, including distinct Mage AoE, Rogue talents, Priest conditions, tank priorities and Shaman totems. Added regression coverage; no release/version change as part of this source audit.

Published v0.4.2 on October 15, 2026 as the latest GitHub release. Fixed native CurseForge TOC discovery using an excluded metadata-only root TOC. Build #362675 completed for commit 03ba40a and generated Release file #9189652 for 1.60.1; downloaded runtime files match the source. Initial file status was Processing.
