--[[****************************************************************************
  * Juggler by Saiket                                                          *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


select( 2, ... ).L = setmetatable( {
	BAR_DONE = "Done!";
	BUTTON_TITLE = "|cff888888Torch|r Juggler";
	BUTTON_DESC = "To throw torches, spin your mousewheel over the spot you want them to land at.";
	DISABLED = "Disabled";
	ENABLED = "Enabled";
	ERROR_COMBAT = "Not usable in combat!";
	PRINT_FORMAT = "|cffCCCC88Juggler|r: %s";
	TIMER_FORMAT = "%.2f|cff888888s|r";
}, {
	__index = function ( self, Key )
		if ( Key ~= nil ) then
			rawset( self, Key, Key );
			return Key;
		end
	end;
} );


SLASH_JUGGLER1 = "/juggler";
SLASH_JUGGLER2 = "/juggle";