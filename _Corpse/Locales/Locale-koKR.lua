--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * Locales/Locale-koKR.lua - Localized string constants (ko-KR) by            *
  *   freshworks.                                                              *
  ****************************************************************************]]


if ( GetLocale() ~= "koKR" ) then
	return;
end


-- See http://wow.curseforge.com/addons/corpse/localization/koKR/
local _Corpse = select( 2, ... );
_Corpse.L = setmetatable( {
	CORPSE_PATTERN = "^([^ ]+)의 시체$",
	ENEMY_OFFLINE_PATTERN = "^([^%s%p%d%c]+)님을 찾을 수 없습니다%.$",
	FRIEND_ADDED_PATTERN = "^([^%s%p%d%c]+)님이 친구 목록에 등록되었습니다%.$",
	FRIEND_REMOVED_PATTERN = "^([^%s%p%d%c]+)님이 친구 목록에서 삭제되었습니다%.$",
}, { __index = _Corpse.L; } );