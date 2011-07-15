--[[****************************************************************************
  * _MiniBlobs by Saiket                                                       *
  * Locales/Locale-frFR.lua - Localized string constants (fr-FR).              *
  ****************************************************************************]]


if ( GetLocale() ~= "frFR" ) then
	return;
end


-- See http://wow.curseforge.com/addons/miniblobs/localization/frFR/
local _MiniBlobs = select( 2, ... );
_MiniBlobs.L = setmetatable( {
	Styles = setmetatable( {
		Archaeology = "Rouge",
		Quests = "Bleu",
	}, _MiniBlobs.L.Styles );
	Types = setmetatable( {
		Archaeology = "Archéologie",
		Quests = "Quêtes",
	}, _MiniBlobs.L.Types );

	CARBONITE_NOTICE = "Vous devez désactiver \"Carbonite\" pour voir les tâches sur votre minicarte.",
	DESC = "Paramètre l'apparence des points d’intérêts de quêtes et des sites de fouilles.",
	PRINT_FORMAT = "_|cffCCCC88MiniBlobs|r: %s",
	QUALITY = "Qualité",
	QUALITY_DESC = "|cffFF7F3FATTENTION !|r En fonction de la forme et de la taille de votre minicarte, des paramètres de qualité plus élevés peuvent réduire considérablement les performances. Les minicartes grandes et non-carrés sont particulièrement plus lentes.",
	QUALITY_HIGH = "Qualité",
	QUALITY_LOW = "Performance",
	ROTATE_MINIMAP_NOTICE = "Vous devez désactiver la |cff808080“rotation de la minicarte”|r pour voir les tâches sur votre minicarte.",
	TITLE = "_|cffCCCC88MiniBlobs|r",
	TYPE_ALPHA = "Alpha",
	TYPE_ENABLED_DESC = "Afficher ou masquer les tâches sur votre minicarte.",
	TYPE_STYLE = "Style",
	TYPE_STYLE_DESC = "Change l'apparence des tâches.",
}, { __index = _MiniBlobs.L; } );