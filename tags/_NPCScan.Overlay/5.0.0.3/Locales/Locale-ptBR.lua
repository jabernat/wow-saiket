--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * Locales/Locale-ptBR.lua - Localized string constants (pt-BR/pt-PT).        *
  ****************************************************************************]]


if ( GetLocale() ~= "ptBR" and GetLocale() ~= "ptPT" ) then
	return;
end


-- See http://wow.curseforge.com/addons/npcscan-overlay/localization/ptBR/
local Overlay = select( 2, ... );
Overlay.L = setmetatable( {
	NPCs = setmetatable( {
		[ 18684 ] = "Bro'Gaz the Clanless", -- Needs review
		[ 32491 ] = "Protodraco do Tempo Perdido",
		[ 33776 ] = "Gondria", -- Needs review
		[ 35189 ] = "Skoll", -- Needs review
		[ 38453 ] = "Arcturis", -- Needs review
		[ 49822 ] = "Jadefang", -- Needs review
		[ 49913 ] = "Lady LaLa", -- Needs review
		[ 50005 ] = "Poseidus", -- Needs review
		[ 50009 ] = "Mobus", -- Needs review
		[ 50050 ] = "Shok'sharak", -- Needs review
		[ 50051 ] = "Ghostcrawler", -- Needs review
		[ 50052 ] = "Burgy Blackheart", -- Needs review
		[ 50053 ] = "Thartuk the Exile", -- Needs review
		[ 50056 ] = "Garr", -- Needs review
		[ 50057 ] = "Blazewing", -- Needs review
		[ 50058 ] = "Terrorpene", -- Needs review
		[ 50059 ] = "Golgarok", -- Needs review
		[ 50060 ] = "Terborus", -- Needs review
		[ 50061 ] = "Xariona", -- Needs review
		[ 50062 ] = "Aeonaxx", -- Needs review
		[ 50063 ] = "Akma'hat", -- Needs review
		[ 50064 ] = "Cyrus the Black", -- Needs review
		[ 50065 ] = "Armagedillo", -- Needs review
		[ 50085 ] = "Overlord Sunderfury", -- Needs review
		[ 50086 ] = "Tarvus the Vile", -- Needs review
		[ 50089 ] = "Julak-Doom", -- Needs review
		[ 50138 ] = "Karoma", -- Needs review
		[ 50154 ] = "Madexx", -- Needs review
		[ 50159 ] = "Sambas", -- Needs review
		[ 50815 ] = "Skarr", -- Needs review
		[ 50959 ] = "Karkin", -- Needs review
		[ 51071 ] = "Captain Florence", -- Needs review
		[ 51079 ] = "Captain Foulwind", -- Needs review
		[ 54318 ] = "Ankha", -- Needs review
		[ 54319 ] = "Magria", -- Needs review
		[ 54320 ] = "Ban'thalos", -- Needs review
		[ 54321 ] = "Solix", -- Needs review
		[ 54322 ] = "Deth'tilac", -- Needs review
		[ 54323 ] = "Kirix", -- Needs review
		[ 54324 ] = "Skitterflame", -- Needs review
		[ 54338 ] = "Anthriss", -- Needs review
		[ 60491 ] = "Sha da Raiva", -- Needs review
		[ 62346 ] = "Gailleon", -- Needs review
		[ 64403 ] = "Alani", -- Needs review
	}, { __index = Overlay.L.NPCs; } );

	CONFIG_ALPHA = "Alfa",
	CONFIG_DESC = "Controla qual mapas mostrarão sobreposição do caminho de unidades. A maioria dos addons que modifica mapas são controlados com a opção de Mapa Mundi.",
	CONFIG_SHOWALL = "Sempre mostrar todos os caminhos",
	CONFIG_SHOWALL_DESC = "Normalmente, quando uma unidade não está sendo buscada, seu caminho é tirado do mapa. Habilite esta opção para sempre mostrar todas as rotas conhecidas.",
	CONFIG_TITLE = "Sobreposição",
	CONFIG_TITLE_STANDALONE = "_|cffCCCC88NPCScan|r.Overlay (Sobreposição)",
	MODULE_ALPHAMAP3 = "AddOn AlphaMap3",
	MODULE_BATTLEFIELDMINIMAP = "Mapa de Batalha",
	MODULE_MINIMAP = "Mini Mapa",
	MODULE_RANGERING_DESC = "Nota: O anel de distância só aparece em zonas com buscas por unidades raras.",
	MODULE_RANGERING_FORMAT = "Mostrar anel de %d jardas para distância de detecção aproximada.",
	MODULE_WORLDMAP = "Mapa Mundi",
	MODULE_WORLDMAP_KEY_FORMAT = "• %s",
	MODULE_WORLDMAP_TOGGLE = "PNJs",
	MODULE_WORLDMAP_TOGGLE_DESC = "Habilita/Desabilita a sobreposição de caminhos do _|cffCCCC88NPCScan|r.Overlay para os PNJs procurados.",
}, { __index = Overlay.L; } );