--[[****************************************************************************
  * _NPCScan.Tools by Saiket                                                   *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


select( 2, ... ).L = setmetatable( {
	CONFIG_TITLE = "|cff888888Tools|r";
	CONFIG_DESC = "Manage mob location data for _NPCScan.";

	CONFIG_MAPID = "MapID";
	CONFIG_ID = "ID";
	CONFIG_NAME = "Name";
	CONFIG_DISPLAYID = "DisplayID";

	MODEL_CONTROL = "Show Model";

	OVERLAY_TITLE = "_|cffCCCC88NPCScan|r.|cff888888Tools|r";
	OVERLAY_CONTROL = "Show Map";

	DATASOURCE_FORMAT = "[%d] %s"; -- NpcID, NpcName
}, getmetatable( _NPCScanLocalization ) );