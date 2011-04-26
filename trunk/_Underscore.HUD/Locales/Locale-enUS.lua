--[[****************************************************************************
  * _Underscore.HUD by Saiket                                                  *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


select( 2, ... ).L = setmetatable( {
	DEAD    = "DEAD";
	GHOST   = "GHOST";
	OFFLINE = "OFFLINE";
	FEIGN   = "FEIGN";

	VALUE_IGNORED = "N/A";
}, getmetatable( _Underscore.L ) );