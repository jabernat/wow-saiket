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
		[ 49822 ] = "Colmillo de Jade",
		[ 49913 ] = "Lady LaLa",
		[ 50005 ] = "Poseidus",
		[ 50009 ] = "Mobus",
		[ 50050 ] = "Shok'sharak",
		[ 50051 ] = "Reptafantasmas",
		[ 50052 ] = "Burgy Corazón Negro",
		[ 50053 ] = "Thartuk el Exiliado",
		[ 50056 ] = "Garr",
		[ 50057 ] = "Alardiente",
		[ 50058 ] = "Terrorpín",
		[ 50059 ] = "Golgarok",
		[ 50060 ] = "Terborus",
		[ 50061 ] = "Xariona",
		[ 50062 ] = "Aeonaxx",
		[ 50063 ] = "Akma'hat",
		[ 50064 ] = "Cyrus el Oscuro",
		[ 50065 ] = "Armagedillo",
		[ 50085 ] = "Señor supremo Hiendefuria",
		[ 50086 ] = "Tarvus el Vil",
		[ 50089 ] = "Julak Fatalidad",
		[ 50138 ] = "Karoma",
		[ 50154 ] = "Madexx",
		[ 50159 ] = "Sambas",
		[ 51071 ] = "Capitán Florence",
		[ 51079 ] = "Capitán Vientinfecto",
		[ 62346 ] = "Galeón", -- Needs review
	}, { __index = Overlay.L.NPCs; } );

	CONFIG_ALPHA = "Alfa",
	CONFIG_DESC = "Controla en qué mapas se mostrará la sobreposición del camino del NPC. La mayoria de addons de mapas se controlan con las opciones del mapa del mundo.",
	CONFIG_SHOWALL = "Mostrar siempre todos los caminos",
	CONFIG_SHOWALL_DESC = "Normalmente cuando no estás buscando un NPC, su camino se elimina del mapa, Activa esta opción para mostrar siempre todos los caminos conocidos.",
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