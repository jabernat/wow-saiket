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

	PUSHTOTALK_BIND = "_|cffCCCC88Underscore|r.HUD.PushToTalk: Binding set to |cff808080“%s”|r.";
	PUSHTOTALK_BIND_ERROR = "_|cffCCCC88Underscore|r.HUD.PushToTalk: Error attempting to bind to |cff808080“%s”|r.";
}, getmetatable( _Underscore.L ) );


BINDING_HEADER__UNDERSCORE_HUD = "_|cffCCCC88Underscore|r.HUD";
BINDING_NAME__UNDERSCORE_HUD_PUSHTOTALK = "External Push-to-Talk Key";

SLASH__UNDERSCORE_HUD_PUSHTOTALK1 = "/ptt";
SLASH__UNDERSCORE_HUD_PUSHTOTALK3 = "/uptt";
SLASH__UNDERSCORE_HUD_PUSHTOTALK2 = "/underscoreptt";