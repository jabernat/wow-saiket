--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * Locales/Locale-zhCN.lua - Localized string constants (zh-CN).              *
  ****************************************************************************]]


if ( GetLocale() ~= "zhCN" ) then
	return;
end


-- See http://wow.curseforge.com/addons/npcscan-overlay/localization/zhCN/
local Overlay = select( 2, ... );
Overlay.L = setmetatable( {
	NPCs = setmetatable( {
		[ 18684 ] = "独行者布罗加斯",
		[ 32491 ] = "时光流逝云龙",
		[ 33776 ] = "古德利亚",
		[ 35189 ] = "逐日",
		[ 38453 ] = "大角",
	}, { __index = Overlay.L.NPCs; } );

	CONFIG_ALPHA = "透明度",
	CONFIG_DESC = "设定在哪张地图显示怪物移动路径。大部分地图插件都针对世界地图做设定。",
	CONFIG_SHOWALL = "永远显示所有路径",
	CONFIG_SHOWALL_DESC = "通常地图上不会显示非搜寻中的怪物的路径。大部分的地图插件都针对世界地图做设定。",
	CONFIG_TITLE = "路径图",
	CONFIG_TITLE_STANDALONE = "_|cffCCCC88NPCScan|r.Overlay",
	MODULE_ALPHAMAP3 = "AlphaMap3 插件",
	MODULE_BATTLEFIELDMINIMAP = "显示战场迷你地图",
	MODULE_MINIMAP = "小地图",
	MODULE_RANGERING_DESC = "提示：在有稀有怪的地图上才显示距离环（因此在主城与冬拥湖不会显示）。",
	MODULE_RANGERING_FORMAT = "显示大概 %d码的侦测距离环",
	MODULE_WORLDMAP = "主要世界地图",
	MODULE_WORLDMAP_KEY_FORMAT = "• %s",
	MODULE_WORLDMAP_TOGGLE = "NPCs",
	MODULE_WORLDMAP_TOGGLE_DESC = "如果开启，显示_|cffCCCC88NPCScan|r.Overlay已知怪物路径的路径图。",
}, { __index = Overlay.L; } );