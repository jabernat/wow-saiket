--[[****************************************************************************
  * _Clean.HUD by Saiket                                                       *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


do
	_CleanLocalization.HUD = setmetatable( {
		DEAD    = "DEAD";
		GHOST   = "GHOST";
		OFFLINE = "OFFLINE";
		FEIGN   = "FEIGN";

		VALUE_IGNORED = "N/A";

		FLAG_AFK = CHAT_FLAG_AFK;
		FLAG_DND = CHAT_FLAG_DND;
	}, getmetatable( _CleanLocalization ) );




--------------------------------------------------------------------------------
-- Globals
----------

	BINDING_HEADER__CLEAN_HUD = "_|cffCCCC88Clean|r.HUD";
	BINDING_NAME__CLEAN_HUD_PUSHTOTALK = "External Push-to-Talk Key";
end
