--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * Locales/Locale-itIT.lua - Localized string constants (it-IT).              *
  ****************************************************************************]]


if ( GetLocale() ~= "itIT" ) then
	return;
end


-- See http://wow.curseforge.com/addons/npcscan-overlay/localization/itIT/
local Overlay = select( 2, ... );
Overlay.L = setmetatable( {
	NPCs = setmetatable( {
		[ 18684 ] = "Bro'Gaz lo Sporco",
		[ 32491 ] = "Proto Draco Preistorico",
		[ 33776 ] = "Gondria",
		[ 35189 ] = "Skoll",
		[ 38453 ] = "Arcturis",
		[ 49822 ] = "Grinfiagiada",
		[ 49913 ] = "Dama Ga-Ga",
		[ 50005 ] = "Poseidus",
		[ 50009 ] = "Mobus",
		[ 50050 ] = "Shok'sharak",
		[ 50051 ] = "Strisciaombre",
		[ 50052 ] = "Burgy Cuorenero",
		[ 50053 ] = "Thartuk l'Esiliato",
		[ 50056 ] = "Garr",
		[ 50057 ] = "Alafiamma",
		[ 50058 ] = "Tartafuoco",
		[ 50059 ] = "Golgarok",
		[ 50060 ] = "Terborus",
		[ 50061 ] = "Xariona",
		[ 50062 ] = "Aeonaxx",
		[ 50063 ] = "Akma'hat",
		[ 50064 ] = "Cyrus il Nero",
		[ 50065 ] = "Armagedillo",
		[ 50085 ] = "Supremo Fendifuria",
		[ 50086 ] = "Tarvus il Vile",
		[ 50089 ] = "Julak",
		[ 50138 ] = "Karoma",
		[ 50154 ] = "Madexx",
		[ 50159 ] = "Sambas",
		[ 50815 ] = "Skarr",
		[ 50959 ] = "Karkin",
		[ 51071 ] = "Capitano Florence",
		[ 51079 ] = "Capitano Ventosudicio",
		[ 54318 ] = "Ankha",
		[ 54319 ] = "Magria",
		[ 54320 ] = "Ban'thalos",
		[ 54321 ] = "Solix",
		[ 54322 ] = "Deth'tilac",
		[ 54323 ] = "Kirix",
		[ 54324 ] = "Balzafiamme",
		[ 54338 ] = "Anthriss",
		[ 60491 ] = "Sha della Rabbia",
		[ 62346 ] = "Galeone",
	}, { __index = Overlay.L.NPCs; } );

	CONFIG_ALPHA = "Alfa",
	CONFIG_DESC = "Controlla quali mappe mostreranno la sovrapposizione del percorso del mostro. La maggior parte degli addon che modificano la minimappa si configurano dalle opzioni della Mappa del Mondo.",
	CONFIG_SHOWALL = "Mostra sempre tutti i percorsi",
	CONFIG_SHOWALL_DESC = "In genere, quando un mostro non viene cercato, il suo percorso non viene mostrato sulla mappa. Attivare questa opzione per mostrare sempre il percorso conosciuto in ogni situazione.",
	CONFIG_TITLE = "Overlay",
	CONFIG_TITLE_STANDALONE = "_|cffCCCC88NPCScan|r.Overlay",
	MODULE_ALPHAMAP3 = "AddOn AlphaMap3",
	MODULE_BATTLEFIELDMINIMAP = "Minimappa del Campo di Battaglia.",
	MODULE_MINIMAP = "Minimappa",
	MODULE_RANGERING_DESC = "Nota: il cerchio della distanza appare solo nelle zone dove si possono trovare mostri rari.",
	MODULE_RANGERING_FORMAT = "Mostra un cerchio di %d metri per approssimare il raggio di ricerca.",
	MODULE_WORLDMAP = "Mappa del mondo principale",
	MODULE_WORLDMAP_KEY_FORMAT = "• %s",
	MODULE_WORLDMAP_TOGGLE = "NPCs",
	MODULE_WORLDMAP_TOGGLE_DESC = "Attiva o disattiva il percorso degli NPC su _|cffCCCC88NPCScan|r.Overlay",
}, { __index = Overlay.L; } );