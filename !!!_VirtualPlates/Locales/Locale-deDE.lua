--[[****************************************************************************
  * _VirtualPlates by Saiket                                                   *
  * Locales/Locale-deDE.lua - Localized string constants (de-DE).              *
  ****************************************************************************]]


if ( GetLocale() ~= "deDE" ) then
	return;
end


-- See http://wow.curseforge.com/addons/virtualplates/localization/deDE/
local _VirtualPlates = select( 2, ... );
_VirtualPlates.L = setmetatable( {
	CONFIG_DESC = "Einstellungen der Nameplate-Skalierung durch _VirtualPlates.",
	CONFIG_LIMITS = "Nameplate Skalierungs-Limit",
	CONFIG_MAXSCALE = "Maximum",
	CONFIG_MAXSCALEENABLED = "Limitiert maximale Skalierung",
	CONFIG_MAXSCALEENABLED_DESC = "Verhindert das die Nameplates zu groß werden wenn die nah am Bildschirm sind.",
	CONFIG_MINSCALE = "Minimum",
	CONFIG_MINSCALE_DESC = "Limitiert wie klein Nameplates werden dürfen, von 0 also ohne Limit bis 1 also nicht kleiner als ihre Standard Größe.",
	CONFIG_SCALEFACTOR = "Skalierungs Faktor",
	CONFIG_SCALEFACTOR_DESC = "Nameplates in dieser Entfernung zur Kamera werden in normaler Größe dargestellt.",
	CONFIG_SLIDER_FORMAT = "%.2f",
	CONFIG_SLIDERYARD_FORMAT = "%dym",
	CONFIG_TITLE = "_|cffCCCC88VirtualPlates|r",
}, { __index = _VirtualPlates.L; } );