--[[****************************************************************************
  * ItemRackTitles by Saiket                                                   *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


do
	local LDQuo, RDQuo = "\226\128\156", "\226\128\157";


	ItemRackTitlesLocalization = setmetatable( {
		INVALID_VERSION = "ItemRackTitles: Unrecognized version of ItemRack/ItemRackOptions.  Please update ItemRackTitles.";
		INVALID_TITLE = GRAY_FONT_COLOR_CODE.."N/A"..FONT_COLOR_CODE_CLOSE;
		MISSING_TITLE_FORMAT = "Title "..LDQuo.."%s"..RDQuo.." unavailable."; -- Title name from GetTitleName
		CLEAR_TITLE = GRAY_FONT_COLOR_CODE.."(No Title)"..FONT_COLOR_CODE_CLOSE;

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
end
