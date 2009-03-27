--[[****************************************************************************
  * _Corpse by Saiket                                                          *
  * Locales/Locale-koKR.lua - Localized string constants (ko-KR) by            *
  *   freshworks.                                                              *
  ****************************************************************************]]


if ( GetLocale() == "koKR" ) then
	_CorpseLocalization = setmetatable( {
		CORPSE_PATTERN = "^([^ ]+)의 시체$"; -- Must also catch cross-realm names based on CORPSE_TOOLTIP

		FRIEND_ADDED_PATTERN = "^([^%s%p%d%c]+)님이 친구 목록에 등록되었습니다%.$"; -- Based on ERR_FRIEND_ADDED_S
		FRIEND_REMOVED_PATTERN = "^([^%s%p%d%c]+)님이 친구 목록에서 삭제되었습니다%.$"; -- Based on ERR_FRIEND_REMOVED_S

		ENEMY_OFFLINE_PATTERN = "^([^%s%p%d%c]+)님을 찾을 수 없습니다%.$"; -- Based on ERR_BAD_PLAYER_NAME_S
	}, { __index = _CorpseLocalization; } );
end
