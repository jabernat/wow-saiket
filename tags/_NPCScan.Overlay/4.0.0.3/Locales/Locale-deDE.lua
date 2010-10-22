--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * Locales/Locale-deDE.lua - Localized string constants (de-DE).              *
  ****************************************************************************]]


if ( GetLocale() ~= "deDE" ) then
	return;
end


-- See http://wow.curseforge.com/addons/npcscan-overlay/localization/deDE/
local Overlay = select( 2, ... );
Overlay.L = setmetatable( {
	NPCs = setmetatable( {
		[ 1140 ] = "Scharfzahnmatriarchin",
		[ 5842 ] = "Takk der Springer",
		[ 6581 ] = "Ravasaurusmatriarchin",
		[ 14232 ] = "Pfeil",
		[ 18684 ] = "Bro'Gaz der Klanlose",
		[ 32491 ] = "Zeitverlorener Protodrache",
		[ 33776 ] = "Gondria",
		[ 35189 ] = "Skoll",
		[ 38453 ] = "Arcturis",
	}, { __index = Overlay.L.NPCs; } );

	CONFIG_ALPHA = "Alpha",
	CONFIG_DESC = "Einstellung welche Karten die Wegpfade der Mobs anzeigen. Die meisten Kartenmods werden über die Optionen der Weltkarte kontrolliert.",
	CONFIG_SHOWALL = "Immer alle Pfade anzeigen",
	CONFIG_SHOWALL_DESC = "Falls ein Mob nicht gesucht wird, wird normalerweise sein Wegpfad von der Karte entfernt. Diese Einstellung aktivieren, um stattdessen immer alle bekannten Wegpfade anzuzeigen.",
	CONFIG_TITLE = "Overlay",
	CONFIG_TITLE_STANDALONE = "_|cffCCCC88NPCScan|r.Overlay",
	MODULE_ALPHAMAP3 = "AlphaMap3 AddOn",
	MODULE_BATTLEFIELDMINIMAP = "Schlachtfeld-Minikarten-Anzeige",
	MODULE_MINIMAP = "Minikarte",
	MODULE_RANGERING_DESC = "Anmerkung: der Entfernungsradius wird nur in Gebieten angezeigt, in denen seltene Mobs gesucht werden.",
	MODULE_RANGERING_FORMAT = "%dyd Ring für ungefähren Entdeckungsradius (in Yards)",
	MODULE_WORLDMAP = "Hauptweltkarte",
	MODULE_WORLDMAP_KEY_FORMAT = "• %s",
	MODULE_WORLDMAP_TOGGLE = "NSCs",
	MODULE_WORLDMAP_TOGGLE_DESC = "_|cffCCCC88NPCScan|r.Overlays Pfade für verfolgte NSCs ein-/ausschalten.",
}, { __index = Overlay.L; } );