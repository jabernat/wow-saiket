--[[****************************************************************************
  * _MiniBlobs by Saiket                                                       *
  * Locales/Locale-koKR.lua - Localized string constants (ko-KR).              *
  ****************************************************************************]]


if ( GetLocale() ~= "koKR" ) then
	return;
end


-- See http://wow.curseforge.com/addons/miniblobs/localization/koKR/
local _MiniBlobs = select( 2, ... );
_MiniBlobs.L = setmetatable( {
	Styles = setmetatable( {
		Archaeology = "붉은색", -- Needs review
		Quests = "푸른색", -- Needs review
	}, _MiniBlobs.L.Styles );
	Types = setmetatable( {
		Archaeology = "고고학", -- Needs review
		Quests = "퀘스트", -- Needs review
	}, _MiniBlobs.L.Types );

	CARBONITE_NOTICE = "미니맵 영역을 보려면 Carbonite를 해제해야합니다.", -- Needs review
	DESC = "미니맵의 발굴 지역과 퀘스트 수행 지역의 모양을 설정합니다.", -- Needs review
	PRINT_FORMAT = "_|cffCCCC88MiniBlobs|r: %s", -- Needs review
	QUALITY = "품질", -- Needs review
	QUALITY_HIGH = "성능 높게", -- Needs review
	QUALITY_LOW = "성능 낮게", -- Needs review
	ROTATE_MINIMAP_NOTICE = "미니맵 영역을 보려면 |cff808080“Rotate Minimap”|r 설정을 해제해야 합니다.", -- Needs review
	TITLE = "_|cffCCCC88MiniBlobs|r", -- Needs review
	TYPE_ALPHA = "투명도", -- Needs review
	TYPE_ENABLED_DESC = "미니맵에서 발굴 영역과 퀘스트 수행 지역을 표시 하거나 숨깁니다.", -- Needs review
	TYPE_STYLE = "스타일", -- Needs review
	TYPE_STYLE_DESC = "발굴 영역과 퀘스트 수행 지역의 스타일을 바꿉니다.", -- Needs review
}, { __index = _MiniBlobs.L; } );