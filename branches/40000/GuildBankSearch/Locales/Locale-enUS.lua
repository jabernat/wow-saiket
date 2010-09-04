--[[****************************************************************************
  * GuildBankSearch by Saiket, originally by Harros                            *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


-- See http://wow.curseforge.com/addons/guild-bank-search/localization/enUS/
select( 2, ... ).L = setmetatable( {
	ALL = "|cffcccccc(All)|r",
	CLEAR = "Clear",
	FILTER = "Filter",
	ITEM_CATEGORY = "Item Category",
	ITEM_LEVEL = "Item Level:",
	LEVELRANGE_SEPARATOR = "-",
	NAME = "Name:",
	QUALITY = "Quality:",
	REQUIRED_LEVEL = "Required Level:",
	SLOT = "Slot:",
	SUB_TYPE = "Sub-Type:",
	TITLE = "GuildBank|cffccccccSearch|r",
	TYPE = "Type:",
}, {
	__index = function ( self, Key )
		if ( Key ~= nil ) then
			rawset( self, Key, Key );
			return Key;
		end
	end;
} );