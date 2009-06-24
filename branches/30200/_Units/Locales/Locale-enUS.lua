--[[****************************************************************************
  * _Units by Saiket                                                           *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


do
	local Title = "_|cffcccc88Units|r";


	_UnitsLocalization = setmetatable( {
		DEAD    = "DEAD";
		GHOST   = "GHOST";
		OFFLINE = "OFFLINE";
		FEIGN   = "FEIGN";

		STATUSMONITOR_MANA_NOT_AVAILABLE = "N/A";

		GRID_LAYOUT_GROUP = Title..": Groups";
		GRID_LAYOUT_CLASS = Title..": Classes";

		OUF_CLASSIFICATION_FORMAT = "(|cff%02x%02x%02x%s|r)"; -- R, G, B, Classification
		OUF_NAME_FORMAT = "|cff%02x%02x%02x%s|r"; -- R, G, B, Name
		OUF_SERVER_DELIMITER = "-";
	}, {
		__index = function ( self, Key )
			if ( Key ~= nil ) then
				rawset( self, Key, Key );
				return Key;
			end
		end;
	} );
end
