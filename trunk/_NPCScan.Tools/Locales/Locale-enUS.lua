--[[****************************************************************************
  * _NPCScan.Tools by Saiket                                                   *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


_NPCScanLocalization.TOOLS = setmetatable( {
	CONFIG_TITLE = "|cff888888Tools|r";
	CONFIG_DESC = "Manage mob location data for _NPCScan.";

	CONFIG_MAPID = "MapID";
	CONFIG_ID = "ID";
	CONFIG_NAME = "Name";
	CONFIG_MODEL = "Model File Path";

	MODEL_CONTROL = "Show Model";

	OVERLAY_TITLE = select( 2, GetAddOnInfo( "_NPCScan.Tools" ) );
	OVERLAY_CONTROL = "Show Map";
}, getmetatable( _NPCScanLocalization ) );