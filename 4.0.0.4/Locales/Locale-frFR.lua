--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * Locales/Locale-frFR.lua - Localized string constants (fr-FR).              *
  ****************************************************************************]]


if ( GetLocale() ~= "frFR" ) then
	return;
end


-- See http://wow.curseforge.com/addons/npcscan-overlay/localization/frFR/
local Overlay = select( 2, ... );
Overlay.L = setmetatable( {
	NPCs = setmetatable( {
		[ 18684 ] = "Bro'Gaz Sans-clan",
		[ 32491 ] = "Proto-drake perdu dans le temps",
		[ 33776 ] = "Gondria",
		[ 35189 ] = "Skoll",
		[ 38453 ] = "Arcturis",
	}, { __index = Overlay.L.NPCs; } );

	CONFIG_ALPHA = "Transparence",
	CONFIG_DESC = "Détermine sur quelles cartes les trajets des monstres seront ajoutés. La plupart des addons modifiant la carte se contrôlent avec les options de la carte du monde.",
	CONFIG_SHOWALL = "Toujours afficher tous les trajets",
	CONFIG_SHOWALL_DESC = "Normalement, quand un monstre n'est pas recherché, son trajet n'est pas affiché sur la carte. L'activation de ce paramètre affichera tous les trajets connus.",
	CONFIG_TITLE = "Superposition",
	CONFIG_TITLE_STANDALONE = "_|cffCCCC88NPCScan|r.Overlay",
	MODULE_ALPHAMAP3 = "AddOn AlphaMap3",
	MODULE_BATTLEFIELDMINIMAP = "Carte locale",
	MODULE_MINIMAP = "Minicarte",
	MODULE_RANGERING_DESC = "Note : le cercle de portée n'apparait que dans les zones où des rares sont recherchés.",
	MODULE_RANGERING_FORMAT = "Aff. un cercle de %dyd approximant la portée de détection",
	MODULE_WORLDMAP = "Carte du monde principale",
	MODULE_WORLDMAP_KEY_FORMAT = "• %s",
	MODULE_WORLDMAP_TOGGLE_DESC = "Si activé, affiche les trajets de _|cffCCCC88NPCScan|r.Overlay des PNJs recherchés.",
}, { __index = Overlay.L; } );