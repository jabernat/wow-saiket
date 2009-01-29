--[[****************************************************************************
  * _Misc by Saiket                                                            *
  * Localization.lua - Localized string constants (en-US).                     *
  ****************************************************************************]]


do
	local Title = "_|cffCCCC88Latency|r";
	_LatencyLocalization = setmetatable(
		{
			TITLE = Title;
			SUBTITLE_FORMAT = GRAY_FONT_COLOR_CODE.."(|r%.01fms"..GRAY_FONT_COLOR_CODE..")";
			LOCK = "lock";
			ONCLOSE_NOTICE = Title..": To reopen the meter, use \"/latency\" or \"/lag\".";
		}, {
			__index = function ( self, Key )
				rawset( self, Key, Key );
				return Key;
			end;
		} );




--------------------------------------------------------------------------------
-- Globals
----------

	BINDING_HEADER__LATENCY = Title;
	BINDING_NAME__LATENCY_TOGGLE = "Toggles "..Title;

	SLASH__LATENCY_TOGGLE1 = "/latency";
	SLASH__LATENCY_TOGGLE2 = "/lag";
end
