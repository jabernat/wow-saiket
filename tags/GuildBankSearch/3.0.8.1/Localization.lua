--[[****************************************************************************
  * GuildBankSearch by Saiket, originally by Harros                            *
  * Localization.lua - Localized string constants (en-US).                     *
  ****************************************************************************]]


do
	local Title = "GuildBank|cffccccccSearch"..FONT_COLOR_CODE_CLOSE;
	GuildBankSearchLocalization = setmetatable(
		{
			TITLE = Title;

			FILTER = "Filter";
			CLEAR = "Clear";

			NAME = "Name:";
			QUALITY = "Quality:";
			ITEM_LEVEL = "Item Level:";
			REQUIRED_LEVEL = "Required Level:";
			LEVELRANGE_SEPARATOR = "-";

			ITEM_CATEGORY = "Item Category";
			TYPE = "Type:";
			SUB_TYPE = "Sub-Type:";
			SLOT = "Slot:";

			ALL = "|cffcccccc(All)"..FONT_COLOR_CODE_CLOSE;
		}, {
			__index = function ( self, Key )
				rawset( self, Key, Key );
				return Key;
			end;
		} );
end
