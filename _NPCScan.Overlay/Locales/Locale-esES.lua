--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * Locales/Locale-esES.lua - Localized string constants (es-ES/es-MX).        *
  ****************************************************************************]]


if ( GetLocale() ~= "esES" and GetLocale() ~= "esMX" ) then
	return;
end


_NPCScanOverlayLocalization.NPCS = setmetatable( {
	[ 1140 ] = "Matriarca Tajobuche";
	[ 5842 ] = "Takk el Saltarín";
	[ 6581 ] = "Matriarca ravasaurio";
	[ 14232 ] = "Dardo";

	-- Outlands
	[ 18684 ] = "Bro'Gaz sin Clan";

	-- Northrend
	[ 32491 ] = "Protodraco Tiempo Perdido";
	[ 33776 ] = "Gondria";
	[ 35189 ] = "Skoll";
	[ 38453 ] = "Arcturis";
}, { __index = _NPCScanOverlayLocalization.NPCS; } );