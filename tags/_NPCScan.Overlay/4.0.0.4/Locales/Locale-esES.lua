--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * Locales/Locale-esES.lua - Localized string constants (es-ES/es-MX).        *
  ****************************************************************************]]


if ( GetLocale() ~= "esES" and GetLocale() ~= "esMX" ) then
	return;
end


-- See http://wow.curseforge.com/addons/npcscan-overlay/localization/esES/
local Overlay = select( 2, ... );
Overlay.L = setmetatable( {
	NPCs = setmetatable( {
		[ 18684 ] = "Bro'Gaz sin Clan",
		[ 32491 ] = "Protodraco Tiempo Perdido",
		[ 33776 ] = "Gondria",
		[ 35189 ] = "Skoll",
		[ 38453 ] = "Arcturis",
	}, { __index = Overlay.L.NPCs; } );

	CONFIG_ALPHA = "Alpha",
	CONFIG_DESC = "Controla en que mapas se mostrara la sobreposicion del camino del NPC. La mayoria de Addons de mapas se controlan con las opciones del mapa del mundo.",
	CONFIG_SHOWALL = "Mostrar siempre todos los caminos",
	CONFIG_SHOWALL_DESC = "Normalmente cuando no estas buscando un NPC, su camino se elimina del mapa, Activa esta opcion para mostrar siempre todos los caminos conocidos",
	CONFIG_TITLE = "Sobreposicion",
	CONFIG_TITLE_STANDALONE = "_|cffCCCC88NPCScan|r.Overlay",
	MODULE_ALPHAMAP3 = "AddOn AlphaMap3",
	MODULE_BATTLEFIELDMINIMAP = "Minimapa de campo de batalla",
	MODULE_MINIMAP = "Minimapa",
	MODULE_RANGERING_DESC = "Nota: el circulo de rango solo aparece en zonas donde se pueden buscar NPCs raros",
	MODULE_RANGERING_FORMAT = "Muestra un anillo de %dyd para aproximar el rango de busqueda",
	MODULE_WORLDMAP = "Mapa del mundo principal",
	MODULE_WORLDMAP_KEY_FORMAT = "• %s",
	MODULE_WORLDMAP_TOGGLE = "NPCs",
	MODULE_WORLDMAP_TOGGLE_DESC = "Activa/desactiva los caminos de los NPCs en _|cffCCCC88NPCScan|r.Overlay.",
}, { __index = Overlay.L; } );