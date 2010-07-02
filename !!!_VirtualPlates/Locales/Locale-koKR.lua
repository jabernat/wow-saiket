--[[****************************************************************************
  * _VirtualPlates by Saiket                                                   *
  * Locales/Locale-koKR.lua - Localized string constants (ko-KR).              *
  ****************************************************************************]]


if ( GetLocale() ~= "koKR" ) then
	return;
end


-- See http://wow.curseforge.com/addons/virtualplates/localization/koKR/
local _VirtualPlates = select( 2, ... );
_VirtualPlates.L = setmetatable( {
	CONFIG_DESC = "_VirtualPlates의 크기 변경이 가능한 이름표를 설정합니다.",
	CONFIG_LIMITS = "이름표 크기 제한",
	CONFIG_MAXSCALE = "이름표의 최대 크기 설정",
	CONFIG_MAXSCALEENABLED = "이름표의 최대 크기 설정",
	CONFIG_MAXSCALEENABLED_DESC = "대상이 매우 가까이 있을 때, 이름표가 너무 커지지 않도록 한계치를 설정합니다.",
	CONFIG_MINSCALE = "이름표의 최소 크기 설정",
	CONFIG_MINSCALE_DESC = "대상이 먼거리에 있을수록 이름표는 작게 표시되는데, 가장 작을때의 한계치를 설정합니다. 0 으로 갈수록 작아지며, 1 은 게임 기본 크기와 동일한 크기입니다.",
	CONFIG_SCALEFACTOR = "시점 축소되었을때의 이름표 크기",
	CONFIG_SCALEFACTOR_DESC = "시점이 축소되었을 때, 이름표는 이 곳에 설정된 값으로 이름표 크기를 설정합니다.",
	CONFIG_SLIDER_FORMAT = "%.2f",
	CONFIG_SLIDERYARD_FORMAT = "%dyd",
	CONFIG_TITLE = "_|cffCCCC88VirtualPlates|r",
}, { __index = _VirtualPlates.L; } );