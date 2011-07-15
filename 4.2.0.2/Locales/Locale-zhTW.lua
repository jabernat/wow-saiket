--[[****************************************************************************
  * _MiniBlobs by Saiket                                                       *
  * Locales/Locale-zhTW.lua - Localized string constants (zh-TW).              *
  ****************************************************************************]]


if ( GetLocale() ~= "zhTW" ) then
	return;
end


-- See http://wow.curseforge.com/addons/miniblobs/localization/zhTW/
local _MiniBlobs = select( 2, ... );
_MiniBlobs.L = setmetatable( {
	Styles = setmetatable( {
		Archaeology = "紅色",
		Quests = "藍色",
	}, _MiniBlobs.L.Styles );
	Types = setmetatable( {
		Archaeology = "考古",
		Quests = "任務",
	}, _MiniBlobs.L.Types );

	CARBONITE_NOTICE = "你必須禁用Carbonite才能看到小地圖班點",
	DESC = "配置任務點與挖掘點的小地圖外觀",
	PRINT_FORMAT = "_|cffCCCC88迷你斑點|r：%s", -- Needs review
	QUALITY = "品質",
	QUALITY_DESC = [=[調整班點以及小地圖邊緣的鋸齒圓滑度。

|cffFF7F3F警告！|r 更高質量的設置可能會大大降低性能，根據你的小地圖的形狀和大小。大型非方形小地圖尤其是最慢的。]=],
	QUALITY_HIGH = "高品質",
	QUALITY_LOW = "效能",
	ROTATE_MINIMAP_NOTICE = "你必須取消|cff808080\"旋轉小地圖\"|r的設定才能看到小地圖班點。",
	TITLE = "_|cffCCCC88迷你斑點|r", -- Needs review
	TYPE_ALPHA = "透明度",
	TYPE_ENABLED_DESC = "在小地圖上顯示或隱藏這些斑點。",
	TYPE_STYLE = "樣式",
	TYPE_STYLE_DESC = "改變斑點的外觀。",
}, { __index = _MiniBlobs.L; } );