--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * Locales/Locale-koKR.lua - Localized string constants (ko-KR).              *
  ****************************************************************************]]


if ( GetLocale() ~= "koKR" ) then
	return;
end


-- See http://wow.curseforge.com/addons/npcscan-overlay/localization/koKR/
_NPCScanOverlayLocalization = setmetatable( {
	NPCS = setmetatable( {
		[ 1140 ] = "무쇠턱 우두머리 랩터",
		[ 5842 ] = "껑충발 타크",
		[ 6581 ] = "우두머리 라바사우루스",
		[ 14232 ] = "바람뿔",
		[ 18684 ] = "외톨이 브로가즈",
		[ 32491 ] = "잃어버린 시간의 원시비룡",
		[ 33776 ] = "곤드리아",
		[ 35189 ] = "스콜",
		[ 38453 ] = "아크튜리스",
	}, { __index = _NPCScanOverlayLocalization.NPCS; } );

	CONFIG_ALPHA = "투명도",
	CONFIG_DESC = "맵에 희귀몹의 이동경로를 어떻게 표시할것인지 설정할 수 있습니다. 여러 월드맵 관련 애드온에서도 사용이 가능합니다.",
	CONFIG_SHOWALL = "항상 모든 이동경로 표시",
	CONFIG_SHOWALL_DESC = "기본적으로 희귀몹을 탐색하지 않았을때는 경로를 표시하지 않지만, 이 옵션을 사용하면 항상 이동경로를 표시합니다.",
	CONFIG_TITLE = "이동경로 표시",
	CONFIG_TITLE_STANDALONE = "_|cffCCCC88NPCScan|r.Overlay",
	CONFIG_ZONE = "지역:",
	MODULE_ALPHAMAP3 = "AlphaMap3 애드온",
	MODULE_BATTLEFIELDMINIMAP = "지역 지도",
	MODULE_MINIMAP = "미니맵",
	MODULE_RANGERING_DESC = "이 링은 희귀몹이 출현하는 지역에서만 사용됩니다.",
	MODULE_RANGERING_FORMAT = "미니맵에 %dyd의 탐색거리를 나타내는 링 표시",
	MODULE_WORLDMAP = "세계 지도",
	MODULE_WORLDMAP_KEY = "_|cffCCCC88NPCScan|r.Overlay",
	MODULE_WORLDMAP_KEY_FORMAT = "- %s",
	MODULE_WORLDMAP_TOGGLE = "_|cffCCCC88NPCScan|r.Overlay",
	MODULE_WORLDMAP_TOGGLE_DESC = "이 옵션을 활성화하면, 탐색하려는 NPC의 이동경로를 보여줍니다.",
}, { __index = _NPCScanOverlayLocalization; } );