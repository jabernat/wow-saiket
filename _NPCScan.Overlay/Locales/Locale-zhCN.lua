--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * Locales/Locale-zhCN.lua - Localized string constants (zh-CN).              *
  ****************************************************************************]]


if ( GetLocale() ~= "zhCN" ) then
	return;
end


_NPCScanOverlayLocalization.NPCS = setmetatable( {
	[ 1140 ] = "刺喉雌龙";
	[ 5842 ] = "“跳跃者”塔克";
	[ 6581 ] = "暴掠龙女王";
	[ 14232 ] = "达尔特";

	-- Outlands
	[ 18684 ] = "独行者布罗加斯";

	-- Northrend
	--[ 32491 ] = "";
	[ 33776 ] = "古德利亚";
	--[ 35189 ] = "";
	--[ 38453 ] = "";
}, { __index = _NPCScanOverlayLocalization.NPCS; } );