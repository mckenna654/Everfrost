-- Luacheck settings for the Everfrost WoW Forever addon (Lua 5.1).
-- Only global-variable warnings are checked: they catch misspelt names and
-- accidental globals without failing on style. Add new WoW API names here.
std = "lua51"
only = { "1" }
exclude_files = { "node_modules", "dist" }

-- Globals the addon writes.
globals = {
  "EverfrostDB",
  "SlashCmdList",
  "SLASH_EVERFROST1", "SLASH_EVERFROST2", "SLASH_EVERFROST3",
  "UISpecialFrames",
}

-- WoW Forever client API the addon reads.
read_globals = {
  "BACKDROP_DIALOG_32_32",
  "C_ClassTalents", "C_Container", "C_Item", "C_SpecializationInfo",
  "C_Spell", "C_SpellBook", "C_Traits",
  "ContainerFrameCombinedBags", "ContainerFrameItemButtonMixin",
  "CreateFrame", "Enum", "GameTooltip",
  "GetActiveTalentGroup", "GetContainerItemLink", "GetContainerNumSlots",
  "GetCursorPosition", "GetInventoryItemLink",
  "GetLootRollItemInfo", "GetLootRollItemLink",
  "GetSpecialization", "GetTalentTabInfo",
  "GroupLootContainer", "InCombatLockdown", "InterfaceOptions_AddCategory",
  "IsPlayerSpell", "Minimap", "Settings", "TooltipDataProcessor",
  "UIParent", "UnitClass", "UnitLevel",
  "hooksecurefunc", "issecretvalue",
}
