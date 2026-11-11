-- Luacheck settings for the Everfrost WoW Forever addon (Lua 5.1).
-- Every check except line length (the addon's lines are long by habit): misspelt names,
-- accidental globals, unused variables and shadowing. Add new WoW API names here.
std = "lua51"
max_line_length = false
exclude_files = { "node_modules", "dist" }

-- Globals the addon writes.
globals = {
  "EverfrostDB", "EverfrostAccountDB", "EverfrostTogglePanel",
  "BINDING_HEADER_EVERFROST", "BINDING_NAME_EVERFROST_TOGGLE",
  "SlashCmdList",
  "SLASH_EVERFROST1", "SLASH_EVERFROST2", "SLASH_EVERFROST3",
  "UISpecialFrames",
}

-- WoW Forever client API the addon reads.
read_globals = {
  "BACKDROP_DIALOG_32_32", "CanAffordMerchantItem", "GetMerchantItemLink",
  "GetQuestItemLink", "GetQuestLogItemLink", "MERCHANT_ITEMS_PER_PAGE",
  "MerchantFrame", "QuestInfoFrame", "QuestInfoRewardsFrame",
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
