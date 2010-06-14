--[[****************************************************************************
  * ItemRackTitles by Saiket                                                   *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


ItemRackTitlesLocalization = setmetatable( {
	INVALID_VERSION = "ItemRackTitles: Unrecognized version of ItemRack/ItemRackOptions.  Please update ItemRackTitles.";
	INVALID_TITLE = "|cff808080N/A|r";
	MISSING_TITLE_FORMAT = "Title “%s” unavailable."; -- Title name from GetTitleName
	CLEAR_TITLE = "|cff808080(No Title)|r";

	TOOLTIP_TITLE_FORMAT = "<%s>"; -- Title name from GetTitleName

	OPTIONS_ENABLE = "Title";
	OPTIONS_ENABLE_DESC = "This determines if the title is changed when equipping the set.";
	OPTIONS_DROPDOWN = "Title";
	OPTIONS_DROPDOWN_DESC = "The title to display upon equipping this set.";
}, {
	__index = function ( self, Key )
		if ( Key ~= nil ) then
			rawset( self, Key, Key );
			return Key;
		end
	end;
} );