--[[****************************************************************************
  * _Latency by Saiket                                                         *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


_LatencyLocalization = setmetatable( {
	LOCK = "lock";
	ONCLOSE_NOTICE = "_|cffCCCC88Latency|r: To reopen the meter, use |cff808080“/latency”|r or |cff808080“/lag”|r.";
	SUBTITLE_FORMAT = "|cff808080(|r%.01fms|cff808080)";
	TITLE = "_|cffCCCC88Latency|r";
}, {
	__index = function ( self, Key )
		if ( Key ~= nil ) then
			rawset( self, Key, Key );
			return Key;
		end
	end;
} );


SLASH__LATENCY_TOGGLE1 = "/latency";
SLASH__LATENCY_TOGGLE2 = "/lag";