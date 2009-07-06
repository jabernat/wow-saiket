--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


do
	_NPCScanLocalization.OVERLAY = setmetatable( {
		CONFIG_TITLE = "Overlay";
		CONFIG_DESC = "Control which maps will show mob path overlays.  Most map-modifying addons are controlled with the World Map option.";

		MODULE_BATTLEFIELDMINIMAP = "Battlefield-Minimap Popout";
		MODULE_WORLDMAP = "Main World Map Frame";
	}, getmetatable( _NPCScanLocalization ) );
end
