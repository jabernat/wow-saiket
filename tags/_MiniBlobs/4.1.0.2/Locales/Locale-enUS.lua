--[[****************************************************************************
  * _MiniBlobs by Saiket                                                       *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


-- See http://wow.curseforge.com/addons/miniblobs/localization/enUS/
local Meta = {
	__index = function ( self, Key )
		if ( Key ~= nil ) then
			rawset( self, Key, Key );
			return Key;
		end
	end;
};
select( 2, ... ).L = setmetatable( {
	Styles = setmetatable( { -- Names of blob type rendering styles
		Archaeology = "Red",
		Quests = "Blue",
	}, Meta );
	Types = setmetatable( { -- Names of different blob types
		Archaeology = "Archaeology",
		Quests = "Quests",
	}, Meta );

	CARBONITE_NOTICE = "You must disable Carbonite to see minimap blobs.",
	DESC = "Configure the appearance of minimap digsites and quest POIs.",
	PRINT_FORMAT = "_|cffCCCC88MiniBlobs|r: %s",
	QUALITY = "Quality",
	QUALITY_DESC = [=[Adjusts the roundedness of blobs, and the jaggedness of round minimap edges.

|cffFF7F3FWARNING!|r  Higher quality settings may drastically reduce performance, depending on the shape and size of your minimap.  Large, non-square minimaps in particular are slowest.]=],
	QUALITY_HIGH = "Quality",
	QUALITY_LOW = "Performance",
	ROTATE_MINIMAP_NOTICE = "You must disable your |cff808080“Rotate Minimap”|r setting to see minimap blobs.",
	TITLE = "_|cffCCCC88MiniBlobs|r",
	TYPE_ALPHA = "Alpha",
	TYPE_ENABLED_DESC = "Shows or hides these blobs on your minimap.",
	TYPE_STYLE = "Style",
	TYPE_STYLE_DESC = "Changes the look of these blobs.",
}, Meta );