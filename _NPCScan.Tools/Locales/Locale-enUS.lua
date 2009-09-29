--[[****************************************************************************
  * _NPCScan.Tools by Saiket                                                   *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


do
	_NPCScanLocalization.TOOLS = setmetatable( {
		CONFIG_TITLE = "|cff888888Tools|r";
		CONFIG_DESC = "Manage mob location data for _NPCScan.";

		CONFIG_MAPID = "MapID";
		CONFIG_ID = "ID";
		CONFIG_NAME = "Name";

		OVERLAY_TITLE = select( 2, GetAddOnInfo( "_NPCScan.Tools" ) );
	}, getmetatable( _NPCScanLocalization ) );
end
