--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * Locales/Locale-zhTW.lua - Localized string constants (zh-TW) by s8095324.  *
  *   中文翻譯：楓之語@米奈希爾                                                 *
  ****************************************************************************]]


if ( GetLocale() == "zhTW" ) then
	local Title = "_|cffCCCC88NPCScan|r.Overlay";
	_NPCScanOverlayLocalization = setmetatable( {
		CONFIG_TITLE = "路徑圖";
		CONFIG_ALPHA = "透明度";
		CONFIG_ZONE = "地區:";

		MODULE_BATTLEFIELDMINIMAP = "顯示戰場迷你地圖";
		MODULE_WORLDMAP = "主要世界地圖";
		MODULE_WORLDMAP_TOGGLE_DESC = "如果啟用, 顯示"..Title.."尚未找到之怪物的路徑圖";
		MODULE_MINIMAP = "小地圖";
		MODULE_RANGERING_FORMAT = "顯示大概 %d碼的偵測距離環";
		MODULE_RANGERING_DESC = "提示： 在有稀有怪的地圖才顯示距離環(例如主城跟冬握就不會顯示).";
		MODULE_ALPHAMAP3 = "AlphaMap3 插件";

		NPCS = setmetatable( {
			[ 1140 ] = "刺喉龍族母";
			[ 5842 ] = "『跳躍者』塔克";
			[ 6581 ] = "暴掠龍族母";
			[ 14232 ] = "達爾特";

			-- Outlands
			[ 18684 ] = "無氏族的伯卡茲";

			-- Northrend
			[ 32491 ] = "時光流逝元龍";
			[ 33776 ] = "剛卓亞";
			[ 35189 ] = "史科爾";
			[ 38453 ] = "大角";
		}, { __index = _NPCScanOverlayLocalization.NPCS; } );
	}, { __index = _NPCScanOverlayLocalization; } );
end

