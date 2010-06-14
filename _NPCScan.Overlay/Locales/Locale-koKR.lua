--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * Locales/Locale-koKR.lua - Localized string constants (ko-KR).              *
  ****************************************************************************]]


if ( GetLocale() ~= "koKR" ) then
	return;
end


_NPCScanOverlayLocalization.NPCS = setmetatable( {
	--[ 1140 ] = "";
	[ 5842 ] = "껑충발 타크";
	[ 6581 ] = "우두머리 라바사우루스";
	--[ 14232 ] = "";

	-- Outlands
	[ 18684 ] = "외톨이 브로가즈";

	-- Northrend
	--[ 32491 ] = "";
	[ 33776 ] = "곤드리아";
	[ 35189 ] = "스콜";
	--[ 38453 ] = "";
}, { __index = _NPCScanOverlayLocalization.NPCS; } );