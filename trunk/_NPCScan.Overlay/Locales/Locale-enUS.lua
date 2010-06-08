--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


do
	local Title = "_|cffCCCC88NPCScan|r.Overlay";
	_NPCScanOverlayLocalization = setmetatable( {
		CONFIG_TITLE = "Overlay";
		CONFIG_TITLE_STANDALONE = Title;
		CONFIG_ENABLE = ENABLE;
		CONFIG_ALPHA = "Alpha";
		CONFIG_DESC = "Control which maps will show mob path overlays.  Most map-modifying addons are controlled with the World Map option.";
		CONFIG_ZONE = "Zone:";
		CONFIG_SHOWALL = "Always show all paths";
		CONFIG_SHOWALL_DESC = "Normally when a mob isn't being searched for, its path gets taken off the map.  Enable this setting to always show every known patrol instead.";

		MODULE_BATTLEFIELDMINIMAP = "Battlefield-Minimap Popout";
		MODULE_WORLDMAP = "Main World Map";
		MODULE_WORLDMAP_KEY = Title;
		MODULE_WORLDMAP_KEY_FORMAT = "\226\128\162 %s";
		MODULE_WORLDMAP_TOGGLE = Title;
		MODULE_WORLDMAP_TOGGLE_DESC = "If enabled, displays "..Title.."'s paths for tracked NPCs.";
		MODULE_MINIMAP = "Minimap";
		MODULE_RANGERING_FORMAT = "Show %dyd ring for approximate detection range";
		MODULE_RANGERING_DESC = "Note: The range ring only appears in zones with tracked rares.";
		MODULE_ALPHAMAP3 = "AlphaMap3 AddOn";

		NPCS = { -- Note: Don't use a metatable default; Missing keys must return nil
			[ 1140 ] = "Razormaw Matriarch";
			[ 5842 ] = "Takk the Leaper";
			[ 6581 ] = "Ravasaur Matriarch";
			[ 14232 ] = "Dart";

			-- Outlands
			[ 18684 ] = "Bro'Gaz the Clanless";

			-- Northrend
			[ 32491 ] = "Time-Lost Proto Drake";
			[ 33776 ] = "Gondria";
			[ 35189 ] = "Skoll";
			[ 38453 ] = "Arcturis";
		};
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

	SLASH__NPCSCAN_OVERLAY1 = "/npcscanoverlay";
	SLASH__NPCSCAN_OVERLAY2 = "/npcoverlay";
	SLASH__NPCSCAN_OVERLAY3 = "/overlay";
end
