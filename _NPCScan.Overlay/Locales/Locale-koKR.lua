--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * Locales/Locale-koKR.lua - Localized string constants (ko-KR).              *
  ****************************************************************************]]


if ( GetLocale() ~= "koKR" ) then
	return;
end


-- See http://wow.curseforge.com/addons/npcscan-overlay/localization/koKR/
local Overlay = select( 2, ... );
Overlay.L = setmetatable( {
	NPCs = setmetatable( {
		[ 18684 ] = "외톨이 브로가즈",
		[ 32491 ] = "잃어버린 시간의 원시비룡",
		[ 33776 ] = "곤드리아",
		[ 35189 ] = "스콜",
		[ 38453 ] = "아크튜리스",
		[ 49822 ] = "비취송곳니",
		[ 49913 ] = "여군주 라라",
		[ 50005 ] = "포세이두스",
		[ 50009 ] = "모부스",
		[ 50050 ] = "쇼크샤라크",
		[ 50051 ] = "유령게",
		[ 50052 ] = "버기 블랙하트",
		[ 50053 ] = "추방자 타르툭",
		[ 50056 ] = "가르",
		[ 50057 ] = "화염날개",
		[ 50058 ] = "공포의 화염거북",
		[ 50059 ] = "골가록",
		[ 50060 ] = "터보러스",
		[ 50061 ] = "자리오나",
		[ 50062 ] = "애오낙스",
		[ 50063 ] = "아크마하트",
		[ 50064 ] = "흑사자 사이러스",
		[ 50065 ] = "아마게딜로",
		[ 50085 ] = "대군주 우뢰폭풍",
		[ 50086 ] = "비열한 타르부스",
		[ 50089 ] = "줄락둠",
		[ 50138 ] = "카로마",
		[ 50154 ] = "매덱스",
		[ 50159 ] = "삼바스",
		[ 50815 ] = "스카르",
		[ 50959 ] = "카르킨",
		[ 51071 ] = "선장 플로렌스",
		[ 51079 ] = "선장 파울윈드",
		[ 54318 ] = "안카",
		[ 54319 ] = "마그리아",
		[ 54320 ] = "반탈로스",
		[ 54321 ] = "솔릭스",
		[ 54322 ] = "데스틸락",
		[ 54323 ] = "키릭스",
		[ 54324 ] = "화염발이",
		[ 54338 ] = "안트리스",
	}, { __index = Overlay.L.NPCs; } );

	CONFIG_ALPHA = "투명도",
	CONFIG_DESC = "맵에 희귀몹의 이동경로를 어떻게 표시할 것인지 설정할 수 있습니다. 여러 월드맵 관련 애드온에서도 사용이 가능합니다.", -- Needs review
	CONFIG_SHOWALL = "항상 모든 이동경로 표시",
	CONFIG_SHOWALL_DESC = "기본적으로 희귀몹을 탐색하지 않았을때는 경로를 표시하지 않지만, 이 옵션을 사용하면 항상 이동경로를 표시합니다.",
	CONFIG_TITLE = "이동경로 표시",
	CONFIG_TITLE_STANDALONE = "_|cffCCCC88NPCScan|r.Overlay",
	MODULE_ALPHAMAP3 = "AlphaMap3 애드온",
	MODULE_BATTLEFIELDMINIMAP = "지역 지도",
	MODULE_MINIMAP = "미니맵",
	MODULE_RANGERING_DESC = "이 링은 희귀몹이 출현하는 지역에서만 사용됩니다.",
	MODULE_RANGERING_FORMAT = "미니맵에 %dyd의 탐색거리를 나타내는 링 표시",
	MODULE_WORLDMAP = "세계 지도",
	MODULE_WORLDMAP_KEY_FORMAT = "• %s", -- Needs review
	MODULE_WORLDMAP_TOGGLE = "NPCs",
	MODULE_WORLDMAP_TOGGLE_DESC = "이 옵션을 활성화하면, 탐색하려는 NPC의 이동경로를 보여줍니다.",
}, { __index = Overlay.L; } );