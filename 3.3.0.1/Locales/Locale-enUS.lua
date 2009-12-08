--[[****************************************************************************
  * _Latency by Saiket                                                         *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


do
	local Title = "_|cffCCCC88Latency|r";
	local LDQuo, RDQuo = GRAY_FONT_COLOR_CODE.."\226\128\156", "\226\128\157|r";


	_LatencyLocalization = setmetatable( {
		TITLE = Title;
		SUBTITLE_FORMAT = GRAY_FONT_COLOR_CODE.."(|r%.01fms"..GRAY_FONT_COLOR_CODE..")";
		LOCK = "lock";
		ONCLOSE_NOTICE = Title..": To reopen the meter, use "..LDQuo.."/latency"..RDQuo.." or "..LDQuo.."/lag"..RDQuo..".";
	}, {
		__index = function ( self, Key )
			if ( Key ~= nil ) then
				rawset( self, Key, Key );
				return Key;
			end
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
