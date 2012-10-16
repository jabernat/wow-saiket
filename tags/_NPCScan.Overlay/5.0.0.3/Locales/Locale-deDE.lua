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
		[ 18684 ] = "Bro'Gaz der Klanlose",
		[ 32491 ] = "Zeitverlorener Protodrache",
		[ 33776 ] = "Gondria",
		[ 35189 ] = "Skoll",
		[ 38453 ] = "Arcturis",
		[ 49822 ] = "Jadezahn",
		[ 49913 ] = "Lady LaLa",
		[ 50005 ] = "Poseidus",
		[ 50009 ] = "Mobus",
		[ 50050 ] = "Shok'sharak",
		[ 50051 ] = "Geisterkrabbler",
		[ 50052 ] = "Bürgi Schwarzherz",
		[ 50053 ] = "Thartuk der Verbannte",
		[ 50056 ] = "Garr",
		[ 50057 ] = "Flammenschwinge",
		[ 50058 ] = "Terrorpene",
		[ 50059 ] = "Golgarok",
		[ 50060 ] = "Terborus",
		[ 50061 ] = "Xariona",
		[ 50062 ] = "Aeonaxx",
		[ 50063 ] = "Akma'hat",
		[ 50064 ] = "Cyrus der Schwarze",
		[ 50065 ] = "Armagürtlon",
		[ 50085 ] = "Oberanführer Zornesbeben",
		[ 50086 ] = "Tarvus der Üble",
		[ 50089 ] = "Julak-Doom",
		[ 50138 ] = "Karoma",
		[ 50154 ] = "Madexx",
		[ 50159 ] = "Sambas",
		[ 50815 ] = "Skarr",
		[ 50959 ] = "Karkin",
		[ 51071 ] = "Kapitän Florence",
		[ 51079 ] = "Kapitän Faulwind",
		[ 54318 ] = "Ankha",
		[ 54319 ] = "Magria",
		[ 54320 ] = "Ban'thalos",
		[ 54321 ] = "Solix",
		[ 54322 ] = "Toth'tilac",
		[ 54323 ] = "Kirix",
		[ 54324 ] = "Flickerflamm",
		[ 54338 ] = "Anthriss",
		[ 60491 ] = "Sha des Zorns",
		[ 62346 ] = "Galleon",
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