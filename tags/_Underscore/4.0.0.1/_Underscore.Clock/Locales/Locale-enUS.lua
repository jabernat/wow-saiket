--[[****************************************************************************
  * _Underscore.Clock by Saiket                                                *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


select( 2, ... ).L = setmetatable( {
	TIME_FORMAT = "T%02d:%02d:%02d";
}, getmetatable( _Underscore.L ) );